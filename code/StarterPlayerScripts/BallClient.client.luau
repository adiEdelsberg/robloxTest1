local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isConsole     = UserInputService.GamepadEnabled and not UserInputService.MouseEnabled

local SAFE_TOP = GuiService:GetGuiInset().Y + (isConsole and 20 or 0)

local eventsFolder = ReplicatedStorage:WaitForChild("BallEvents")
local pickupEvent = eventsFolder:WaitForChild("PickupBall")
local throwEvent = eventsFolder:WaitForChild("ThrowBall")

local heldBall = nil
local isCharging = false
local chargePower = 0       -- 0..1
local chargeInput = nil     -- the InputObject that started the charge
local PICKUP_RANGE = 10
local TRAJ_DOTS = 16
local PHASE1_FRAC = 0.6     -- 60% of dots drawn in straight phase

-- Per-ball throw profiles (must mirror BallGame.server.luau throw tables)
local THROW_DEFS = {
	Normal     = { minSpeed=30,  maxSpeed=152, straightBase=0.38, straightRange=0.22, dropVelY=-32, chargeTime=1.8,  barColor=Color3.fromRGB(255,200,0)   },
	Split      = { minSpeed=32,  maxSpeed=140, straightBase=0.22, straightRange=0.16, dropVelY=-42, chargeTime=1.6,  barColor=Color3.fromRGB(255,160,20)  },
	Heavy      = { minSpeed=18,  maxSpeed=108, straightBase=0.60, straightRange=0.30, dropVelY=-70, chargeTime=2.6,  barColor=Color3.fromRGB(180,80,255)  },
	Speed      = { minSpeed=58,  maxSpeed=248, straightBase=0.72, straightRange=0.34, dropVelY=-18, chargeTime=1.15, barColor=Color3.fromRGB(0,220,255)   },
	SplitChild = { minSpeed=72,  maxSpeed=92,  straightBase=0.18, straightRange=0.08, dropVelY=-40, chargeTime=1.0,  barColor=Color3.fromRGB(255,220,80)  },
	DinoBlast  = { minSpeed=150, maxSpeed=340, straightBase=0.82, straightRange=0.16, dropVelY=-10, chargeTime=1.2,  barColor=Color3.fromRGB(255,60,0)    },
}
local DEFAULT_THROW = THROW_DEFS.Normal

local function getThrowDef()
	local ballType = heldBall and heldBall:GetAttribute("BallType") or "Normal"
	return THROW_DEFS[ballType] or DEFAULT_THROW
end
local VERSION = "v7.98"
local IS_DEBUG_MODE = Balance.ActiveMode == "debug" or Balance.ActiveMode == "fallback-debug"
local COMPLETION_AIR_CONTROL_SPEED = 46
local completionAirUntil = 0
local completionAirControlSpeed = COMPLETION_AIR_CONTROL_SPEED

local function clampSkyDescentToBounds()
	if not player:GetAttribute("SkyDescentBoundsActive") then return false end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local minX = tonumber(player:GetAttribute("SkyDescentMinX")) or -math.huge
	local maxX = tonumber(player:GetAttribute("SkyDescentMaxX")) or math.huge
	local minZ = tonumber(player:GetAttribute("SkyDescentMinZ")) or -math.huge
	local maxZ = tonumber(player:GetAttribute("SkyDescentMaxZ")) or math.huge
	local pos = hrp.Position
	local x = math.clamp(pos.X, minX + 4, maxX - 4)
	local z = math.clamp(pos.Z, minZ + 4, maxZ - 4)
	if x == pos.X and z == pos.Z then return false end

	hrp.CFrame = CFrame.new(x, pos.Y, z) * (hrp.CFrame - pos)
	local velocity = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(
		x ~= pos.X and 0 or velocity.X,
		velocity.Y,
		z ~= pos.Z and 0 or velocity.Z
	)
	return true
end

local function startCompletionSkyLaunch(duration, upwardVelocity, airControlSpeed)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp then return end

	completionAirUntil = os.clock() + math.max(0.5, tonumber(duration) or 3)
	completionAirControlSpeed = tonumber(airControlSpeed) or COMPLETION_AIR_CONTROL_SPEED
	player:SetAttribute("CompletionAirLaunchActive", true)

	if humanoid then
		humanoid.Sit = false
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	local launchY = math.max(tonumber(upwardVelocity) or 320, hrp.AssemblyLinearVelocity.Y + 260)
	local velocity = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, launchY, velocity.Z)
end

RunService.RenderStepped:Connect(function()
	clampSkyDescentToBounds()

	if os.clock() >= completionAirUntil then
		if player:GetAttribute("CompletionAirLaunchActive") then
			player:SetAttribute("CompletionAirLaunchActive", false)
		end
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude <= 0.05 then return end

	local velocity = hrp.AssemblyLinearVelocity
	local desired = moveDir.Unit * completionAirControlSpeed
	hrp.AssemblyLinearVelocity = Vector3.new(desired.X, velocity.Y, desired.Z)
end)

-- =============================================
-- HUD
-- =============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BallHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

-- Version label (debug only — hidden in prod)
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 110, 0, 32)
versionLabel.Position = UDim2.new(1, -118, 0, 44)
versionLabel.BackgroundColor3 = Color3.new(0, 0, 0)
versionLabel.BackgroundTransparency = 0.3
versionLabel.BorderSizePixel = 0
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextSize = 16
versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
versionLabel.TextStrokeTransparency = 0.5
versionLabel.Text = VERSION
versionLabel.Visible = IS_DEBUG_MODE
versionLabel.Parent = screenGui
Instance.new("UICorner", versionLabel).CornerRadius = UDim.new(0, 6)

local debugModeLabel = Instance.new("TextLabel")
debugModeLabel.Size = UDim2.new(0, 86, 0, 32)
debugModeLabel.Position = UDim2.new(1, -212, 0, 44)
debugModeLabel.BackgroundColor3 = Color3.fromRGB(255, 190, 35)
debugModeLabel.BackgroundTransparency = 0.08
debugModeLabel.BorderSizePixel = 0
debugModeLabel.Font = Enum.Font.GothamBlack
debugModeLabel.TextSize = 14
debugModeLabel.TextColor3 = Color3.fromRGB(30, 22, 0)
debugModeLabel.TextStrokeTransparency = 1
debugModeLabel.Text = "DEBUG"
debugModeLabel.Visible = IS_DEBUG_MODE
debugModeLabel.Parent = screenGui
Instance.new("UICorner", debugModeLabel).CornerRadius = UDim.new(0, 6)

local debugMoveSpeed = (Balance.Movement and Balance.Movement.WalkSpeeds and Balance.Movement.WalkSpeeds[0]) or 16
local debugJumpPower = (Balance.Movement and Balance.Movement.JumpPowers and Balance.Movement.JumpPowers[0]) or 50
local debugMinSpeed = 8
local debugMaxSpeed = 200
local debugMinJump = 20
local debugMaxJump = 260

local debugControls = Instance.new("Frame")
debugControls.Size = UDim2.new(0, 206, 0, 32)
debugControls.Position = UDim2.new(1, -426, 0, 44)
debugControls.BackgroundTransparency = 1
debugControls.Visible = IS_DEBUG_MODE
debugControls.Parent = screenGui

local debugMinus = Instance.new("TextButton")
debugMinus.Size = UDim2.new(0, 34, 0, 32)
debugMinus.Position = UDim2.new(0, 0, 0, 0)
debugMinus.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
debugMinus.BackgroundTransparency = 0.05
debugMinus.BorderSizePixel = 0
debugMinus.Font = Enum.Font.GothamBlack
debugMinus.Text = "-"
debugMinus.TextSize = 22
debugMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
debugMinus.Visible = IS_DEBUG_MODE
debugMinus.Parent = debugControls
Instance.new("UICorner", debugMinus).CornerRadius = UDim.new(0, 6)

local debugMoveLabel = Instance.new("TextLabel")
debugMoveLabel.Size = UDim2.new(0, 130, 0, 32)
debugMoveLabel.Position = UDim2.new(0, 38, 0, 0)
debugMoveLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
debugMoveLabel.BackgroundTransparency = 0.28
debugMoveLabel.BorderSizePixel = 0
debugMoveLabel.Font = Enum.Font.GothamBold
debugMoveLabel.TextSize = 12
debugMoveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
debugMoveLabel.TextStrokeTransparency = 0.6
debugMoveLabel.Visible = IS_DEBUG_MODE
debugMoveLabel.Parent = debugControls
Instance.new("UICorner", debugMoveLabel).CornerRadius = UDim.new(0, 6)

local debugPlus = Instance.new("TextButton")
debugPlus.Size = UDim2.new(0, 34, 0, 32)
debugPlus.Position = UDim2.new(0, 172, 0, 0)
debugPlus.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
debugPlus.BackgroundTransparency = 0.05
debugPlus.BorderSizePixel = 0
debugPlus.Font = Enum.Font.GothamBlack
debugPlus.Text = "+"
debugPlus.TextSize = 22
debugPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
debugPlus.Visible = IS_DEBUG_MODE
debugPlus.Parent = debugControls
Instance.new("UICorner", debugPlus).CornerRadius = UDim.new(0, 6)

local function applyDebugMovement()
	debugMoveLabel.Text = string.format("SPD %d  JMP %d", debugMoveSpeed, debugJumpPower)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.WalkSpeed = debugMoveSpeed
	pcall(function()
		humanoid.UseJumpPower = true
	end)
	humanoid.JumpPower = debugJumpPower
end

local function changeDebugMovement(direction)
	debugMoveSpeed = math.clamp(debugMoveSpeed + direction * 4, debugMinSpeed, debugMaxSpeed)
	debugJumpPower = math.clamp(debugJumpPower + direction * 10, debugMinJump, debugMaxJump)
	applyDebugMovement()
end

if IS_DEBUG_MODE then
	debugMinus.Activated:Connect(function()
		changeDebugMovement(-1)
	end)
	debugPlus.Activated:Connect(function()
		changeDebugMovement(1)
	end)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		applyDebugMovement()
	end)
	applyDebugMovement()
end

-- ---- Stage counter (top-centre) ----
local stagePanel = Instance.new("Frame")
stagePanel.Name = "StagePanel"
stagePanel.AnchorPoint = Vector2.new(0.5, 0)
stagePanel.Size = UDim2.new(0.92, 0, 0, 104)
stagePanel.Position = UDim2.new(0.5, 0, 0, SAFE_TOP + 12)
stagePanel.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
stagePanel.BackgroundTransparency = 0.75
stagePanel.BorderSizePixel = 0
stagePanel.ZIndex = 5
stagePanel.Parent = screenGui
Instance.new("UICorner", stagePanel).CornerRadius = UDim.new(0, 10)

local stagePanelSize = Instance.new("UISizeConstraint")
stagePanelSize.MinSize = Vector2.new(320, 104)
stagePanelSize.MaxSize = Vector2.new(410, 104)
stagePanelSize.Parent = stagePanel

local stagePanelStroke = Instance.new("UIStroke")
stagePanelStroke.Color = Color3.fromRGB(120, 190, 255)
stagePanelStroke.Thickness = 1.5
stagePanelStroke.Transparency = 1
stagePanelStroke.Parent = stagePanel

local stagePanelGradient = Instance.new("UIGradient")
stagePanelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 18, 32)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 8, 12)),
})
stagePanelGradient.Rotation = 90
stagePanelGradient.Transparency = NumberSequence.new(1)
stagePanelGradient.Parent = stagePanel

local stageLabel = Instance.new("TextLabel")
stageLabel.Size = UDim2.new(1, -106, 0, 22)
stageLabel.Position = UDim2.new(0, 12, 0, 36)
stageLabel.Visible = false
stageLabel.BackgroundTransparency = 1
stageLabel.Font = Enum.Font.GothamBlack
stageLabel.TextSize = 14
stageLabel.TextColor3 = Color3.new(1, 1, 1)
stageLabel.TextStrokeTransparency = 0.45
stageLabel.Text = "LOADING..."
stageLabel.RichText = true
stageLabel.ZIndex = 6
stageLabel.TextXAlignment = Enum.TextXAlignment.Left
stageLabel.Parent = stagePanel

local stageCountLabel = Instance.new("TextLabel")
stageCountLabel.Size = UDim2.new(0, 82, 0, 22)
stageCountLabel.Position = UDim2.new(1, -94, 0, 8)
stageCountLabel.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
stageCountLabel.BackgroundTransparency = 0.05
stageCountLabel.BorderSizePixel = 0
stageCountLabel.Font = Enum.Font.GothamBlack
stageCountLabel.TextSize = 14
stageCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
stageCountLabel.TextStrokeTransparency = 0.55
stageCountLabel.Text = "0 / 1"
stageCountLabel.ZIndex = 6
stageCountLabel.Parent = stagePanel
Instance.new("UICorner", stageCountLabel).CornerRadius = UDim.new(0, 7)

local stageCountStroke = Instance.new("UIStroke")
stageCountStroke.Color = Color3.fromRGB(255, 255, 255)
stageCountStroke.Thickness = 1
stageCountStroke.Transparency = 0.6
stageCountStroke.Parent = stageCountLabel

local stageTimerLabel = Instance.new("TextLabel")
stageTimerLabel.Size = UDim2.new(0, 82, 0, 20)
stageTimerLabel.Position = UDim2.new(1, -94, 0, 34)
stageTimerLabel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
stageTimerLabel.BackgroundTransparency = 0.08
stageTimerLabel.BorderSizePixel = 0
stageTimerLabel.Font = Enum.Font.GothamBlack
stageTimerLabel.TextSize = 13
stageTimerLabel.TextColor3 = Color3.fromRGB(230, 245, 255)
stageTimerLabel.TextStrokeTransparency = 0.65
stageTimerLabel.Text = "0:00"
stageTimerLabel.Visible = false
stageTimerLabel.ZIndex = 6
stageTimerLabel.Parent = stagePanel
Instance.new("UICorner", stageTimerLabel).CornerRadius = UDim.new(0, 7)

local stageTimerStroke = Instance.new("UIStroke")
stageTimerStroke.Color = Color3.fromRGB(120, 190, 255)
stageTimerStroke.Thickness = 1
stageTimerStroke.Transparency = 0.55
stageTimerStroke.Parent = stageTimerLabel

local objectiveLabel = Instance.new("TextLabel")
objectiveLabel.Size = UDim2.new(1, -122, 0, 22)
objectiveLabel.Position = UDim2.new(0, 20, 0, 8)
objectiveLabel.BackgroundTransparency = 1
objectiveLabel.Font = Enum.Font.GothamMedium
objectiveLabel.TextSize = 12
objectiveLabel.TextColor3 = Color3.fromRGB(230, 235, 255)
objectiveLabel.TextStrokeTransparency = 0.65
objectiveLabel.Text = "Complete the current objective."
objectiveLabel.TextWrapped = true
objectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
objectiveLabel.ZIndex = 9
objectiveLabel.Parent = stagePanel

local stageBarBg = Instance.new("Frame")
stageBarBg.Size = UDim2.new(1, -114, 0, 22)
stageBarBg.Position = UDim2.new(0, 12, 0, 8)
stageBarBg.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
stageBarBg.BorderSizePixel = 0
stageBarBg.ZIndex = 6
stageBarBg.Parent = stagePanel
Instance.new("UICorner", stageBarBg).CornerRadius = UDim.new(0, 8)

local stageBarStroke = Instance.new("UIStroke")
stageBarStroke.Color = Color3.fromRGB(255, 255, 255)
stageBarStroke.Thickness = 1
stageBarStroke.Transparency = 0.68
stageBarStroke.Parent = stageBarBg

local stageBarFill = Instance.new("Frame")
stageBarFill.Size = UDim2.new(0, 0, 1, 0)
stageBarFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
stageBarFill.BorderSizePixel = 0
stageBarFill.ZIndex = 7
stageBarFill.Parent = stageBarBg
Instance.new("UICorner", stageBarFill).CornerRadius = UDim.new(0, 8)

local stageBarGradient = Instance.new("UIGradient")
stageBarGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 220, 255)),
})
stageBarGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.22),
	NumberSequenceKeypoint.new(1, 0),
})
stageBarGradient.Parent = stageBarFill

local stageBarShine = Instance.new("Frame")
stageBarShine.Size = UDim2.new(1, 0, 0.34, 0)
stageBarShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
stageBarShine.BackgroundTransparency = 0.72
stageBarShine.BorderSizePixel = 0
stageBarShine.ZIndex = 8
stageBarShine.Parent = stageBarFill
Instance.new("UICorner", stageBarShine).CornerRadius = UDim.new(0, 8)

local stagePopup = Instance.new("Frame")
stagePopup.AnchorPoint = Vector2.new(0.5, 0)
stagePopup.Size = isTouchDevice and UDim2.new(0.78, 0, 0, 58) or UDim2.new(0, 390, 0, 82)
stagePopup.Position = isTouchDevice and UDim2.new(0.5, 0, 0, SAFE_TOP + 4) or UDim2.new(0.5, 0, 0, SAFE_TOP + 14)
stagePopup.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
stagePopup.BackgroundTransparency = 0.08
stagePopup.BorderSizePixel = 0
stagePopup.Visible = false
stagePopup.ZIndex = 20
stagePopup.Parent = screenGui
Instance.new("UICorner", stagePopup).CornerRadius = UDim.new(0, 10)

local stagePopupStroke = Instance.new("UIStroke")
stagePopupStroke.Color = Color3.fromRGB(255, 230, 90)
stagePopupStroke.Thickness = 2
stagePopupStroke.Transparency = 0.15
stagePopupStroke.Parent = stagePopup

local stagePopupTitle = Instance.new("TextLabel")
stagePopupTitle.Size = isTouchDevice and UDim2.new(1, -12, 0, 24) or UDim2.new(1, -20, 0, 34)
stagePopupTitle.Position = isTouchDevice and UDim2.new(0, 6, 0, 4) or UDim2.new(0, 10, 0, 8)
stagePopupTitle.BackgroundTransparency = 1
stagePopupTitle.Font = Enum.Font.GothamBlack
stagePopupTitle.TextScaled = true
stagePopupTitle.TextColor3 = Color3.fromRGB(255, 235, 120)
stagePopupTitle.TextStrokeTransparency = 0.45
stagePopupTitle.Text = "STAGE COMPLETE!"
stagePopupTitle.ZIndex = 21
stagePopupTitle.Parent = stagePopup

local stagePopupSub = Instance.new("TextLabel")
stagePopupSub.Size = isTouchDevice and UDim2.new(1, -12, 0, 18) or UDim2.new(1, -20, 0, 24)
stagePopupSub.Position = isTouchDevice and UDim2.new(0, 6, 0, 30) or UDim2.new(0, 10, 0, 42)
stagePopupSub.BackgroundTransparency = 1
stagePopupSub.Font = Enum.Font.GothamBold
stagePopupSub.TextScaled = true
stagePopupSub.TextColor3 = Color3.new(1, 1, 1)
stagePopupSub.TextStrokeTransparency = 0.6
stagePopupSub.Text = ""
stagePopupSub.ZIndex = 21
stagePopupSub.Parent = stagePopup

local rewardToast = Instance.new("Frame")
rewardToast.AnchorPoint = Vector2.new(0.5, 0)
rewardToast.Size = isTouchDevice and UDim2.new(0.78, 0, 0, 42) or UDim2.new(0, 430, 0, 54)
rewardToast.Position = isTouchDevice and UDim2.new(0.5, 0, 0, SAFE_TOP + 68) or UDim2.new(0.5, 0, 0, SAFE_TOP + 102)
rewardToast.BackgroundColor3 = Color3.fromRGB(18, 14, 8)
rewardToast.BackgroundTransparency = 0.08
rewardToast.BorderSizePixel = 0
rewardToast.Visible = false
rewardToast.ZIndex = 24
rewardToast.Parent = screenGui
Instance.new("UICorner", rewardToast).CornerRadius = UDim.new(0, 10)

local rewardToastStroke = Instance.new("UIStroke")
rewardToastStroke.Color = Color3.fromRGB(255, 214, 80)
rewardToastStroke.Thickness = 2
rewardToastStroke.Transparency = 0.1
rewardToastStroke.Parent = rewardToast

local rewardToastText = Instance.new("TextLabel")
rewardToastText.Size = UDim2.new(1, -20, 1, 0)
rewardToastText.Position = UDim2.new(0, 10, 0, 0)
rewardToastText.BackgroundTransparency = 1
rewardToastText.Font = Enum.Font.GothamBlack
rewardToastText.TextScaled = true
rewardToastText.TextColor3 = Color3.fromRGB(255, 235, 130)
rewardToastText.TextStrokeTransparency = 0.45
rewardToastText.ZIndex = 25
rewardToastText.Text = ""
rewardToastText.Parent = rewardToast

local popupToken = 0
local stagePopupCountdownActive = false
local stageRunStartTime = nil
local stageCountdownActive = false

local BRIDGE_Z_HALF_WIDTH = 13
local BRIDGE_X_HALF_WIDTH = 27
local BRIDGE_MARGIN = 2
local Z_BRIDGES = {
	{ x = 0, z1 = 59, z2 = 132 },
	{ x = 0, z1 = 268, z2 = 385 },
	{ x = 0, z1 = 525, z2 = 640 },
	{ x = 0, z1 = 780, z2 = 860 },
	{ x = 0, z1 = 1020, z2 = 1090 },
	{ x = 0, z1 = 1231, z2 = 1300 },
	{ x = 0, z1 = 1460, z2 = 1540 },
	{ x = -2860, z1 = 1373, z2 = 1420 },
	{ x = -2860, z1 = 1976, z2 = 2142 },
	{ x = -2860, z1 = 2266, z2 = 2486 },
	{ x = -2860, z1 = 2616, z2 = 2836 },
	{ x = -2860, z1 = 2964, z2 = 3141 },
	{ x = -2860, z1 = 3259, z2 = 3431 },
	{ x = -2860, z1 = 3569, z2 = 3771 },
	{ x = -2860, z1 = 3889, z2 = 4066 },
	{ x = -2860, z1 = 4194, z2 = 4366 },
	{ x = -2860, z1 = 4534, z2 = 4691 },
	{ x = -2860, z1 = 4829, z2 = 4996 },
	{ x = -2860, z1 = 5124, z2 = 5271 },
	{ x = -2860, z1 = 5409, z2 = 5556 },
	{ x = -2860, z1 = 5684, z2 = 5831 },
	{ x = -2860, z1 = 5969, z2 = 6116 },
	{ x = -2860, z1 = 6254, z2 = 6401 },
	{ x = -2860, z1 = 6539, z2 = 6686 },
	{ x = -2860, z1 = 6824, z2 = 6971 },
	{ x = -2860, z1 = 7109, z2 = 7256 },
	{ x = -2860, z1 = 7394, z2 = 7540 },
	{ x = -2860, z1 = 7680, z2 = 7990 },
	{ x = -2860, z1 = 8210, z2 = 8340 },
}
local X_BRIDGES = {
	{ z = 0, x1 = -122, x2 = -59 },
	{ z = 1700, x1 = -200, x2 = -140 },
	{ z = 1700, x1 = 140, x2 = 214 },
	{ z = 1700, x1 = 490, x2 = 566 },
	{ z = 1700, x1 = 842, x2 = 918 },
	{ z = 1700, x1 = 1194, x2 = 1270 },
	{ z = 1700, x1 = 1546, x2 = 1622 },
	{ z = 1700, x1 = 1898, x2 = 1974 },
	{ z = 1700, x1 = 2250, x2 = 2308 },
	{ z = 1700, x1 = 2596, x2 = 2684 },
	{ z = 1700, x1 = 2980, x2 = 3027 },
	{ z = 1700, x1 = -970, x2 = -900 },
	{ z = 1700, x1 = -1740, x2 = -1670 },
	{ z = 1700, x1 = -2510, x2 = -2440 },
	{ z = 1700, x1 = -3466, x2 = -3210 },
	{ z = 1700, x1 = -3570, x2 = -3530 },
}

local function isInStarterWorld()
	return player:GetAttribute("InLandingWorld") == true
end

local function isOnBridge()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local pos = hrp.Position
	for _, bridge in Z_BRIDGES do
		local minZ = math.min(bridge.z1, bridge.z2) - BRIDGE_MARGIN
		local maxZ = math.max(bridge.z1, bridge.z2) + BRIDGE_MARGIN
		if math.abs(pos.X - bridge.x) <= BRIDGE_Z_HALF_WIDTH and pos.Z >= minZ and pos.Z <= maxZ then
			return true
		end
	end
	for _, bridge in X_BRIDGES do
		local minX = math.min(bridge.x1, bridge.x2) - BRIDGE_MARGIN
		local maxX = math.max(bridge.x1, bridge.x2) + BRIDGE_MARGIN
		if pos.X >= minX and pos.X <= maxX and math.abs(pos.Z - bridge.z) <= BRIDGE_X_HALF_WIDTH then
			return true
		end
	end
	return false
end

local function setStagePanelVisible(visible)
	stagePanel.Visible = visible and not isInStarterWorld() and not isOnBridge()
end

local function hideStarterScoreboard()
	if not isInStarterWorld() then return end
	stagePanel.Visible = false
	stagePopup.Visible = false
	stageTimerLabel.Visible = false
	local grace = screenGui:FindFirstChild("GraceBanner")
	if grace then
		grace.Visible = false
	end
end

player:GetAttributeChangedSignal("InLandingWorld"):Connect(hideStarterScoreboard)
hideStarterScoreboard()

local function formatStageTime(seconds)
	seconds = math.max(0, tonumber(seconds) or 0)
	local minutes = math.floor(seconds / 60)
	local whole = math.floor(seconds % 60)
	return string.format("%d:%02d", minutes, whole)
end

local function burstFireworks(color)
	local sound = Instance.new("Sound")
	sound.Name = "StageClearSound"
	sound.SoundId = "rbxassetid://12222253"
	sound.Volume = 0.9
	sound.PlaybackSpeed = 1.05
	sound.Parent = screenGui
	sound:Play()
	task.delay(2, function()
		if sound.Parent then sound:Destroy() end
	end)

	for i = 1, 8 do
		local spark = Instance.new("Frame")
		spark.Name = "StageFirework"
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.Size = UDim2.new(0, 9, 0, 9)
		spark.Position = UDim2.new(0.5, math.random(-170, 170), 0, math.random(72, 180))
		spark.BackgroundColor3 = (i % 3 == 0) and Color3.fromRGB(255, 235, 120) or color
		spark.BorderSizePixel = 0
		spark.Parent = screenGui
		Instance.new("UICorner", spark).CornerRadius = UDim.new(1, 0)

		for ray = 1, 8 do
			local piece = Instance.new("Frame")
			piece.Name = "StageFireworkRay"
			piece.AnchorPoint = Vector2.new(0.5, 0.5)
			piece.Size = UDim2.new(0, 6, 0, 18)
			piece.Position = spark.Position
			piece.Rotation = ray * 45
			piece.BackgroundColor3 = spark.BackgroundColor3
			piece.BorderSizePixel = 0
			piece.Parent = screenGui
			Instance.new("UICorner", piece).CornerRadius = UDim.new(0, 4)

			local angle = math.rad(ray * 45)
			local distance = math.random(35, 72)
			TweenService:Create(piece, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = piece.Position + UDim2.new(0, math.cos(angle) * distance, 0, math.sin(angle) * distance),
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 2, 0, 10),
			}):Play()
			task.delay(0.62, function()
				if piece.Parent then piece:Destroy() end
			end)
		end

		TweenService:Create(spark, TweenInfo.new(0.35), {
			Size = UDim2.new(0, 2, 0, 2),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.7, function()
			if spark.Parent then spark:Destroy() end
		end)
	end
end

local function playScoreboardFinishEffect(color)
	stageBarFill.Size = UDim2.new(1, 0, 1, 0)
	stageBarFill.BackgroundColor3 = color
	stageBarShine.BackgroundTransparency = 0.18
	stagePanelStroke.Thickness = 3
	stageCountLabel.Size = UDim2.new(0, 92, 0, 32)
	stageCountLabel.Position = UDim2.new(1, -99, 0, 5)

	TweenService:Create(stageBarShine, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.72,
	}):Play()
	TweenService:Create(stagePanelStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Thickness = 1.5,
	}):Play()
	TweenService:Create(stageCountLabel, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 82, 0, 28),
		Position = UDim2.new(1, -94, 0, 7),
	}):Play()
end

local rewardToastToken = 0
local function showRewardToast(worldName, crownsAwarded, trophiesAwarded)
	rewardToastToken += 1
	local token = rewardToastToken
	local crownsWon = tonumber(crownsAwarded) or 0
	local trophiesWon = tonumber(trophiesAwarded) or 0
	local rewardParts = {}
	if crownsWon >= 1 then
		table.insert(rewardParts, string.format("+%d Crowns", crownsWon))
	end
	if trophiesWon >= 1 then
		table.insert(rewardParts, string.format("+%d Trophy", trophiesWon))
	end
	local rewardText = #rewardParts > 0 and table.concat(rewardParts, "  ") or "Stage cleared"
	rewardToast.Visible = true
	rewardToast.BackgroundTransparency = 0.08
	rewardToastText.TextTransparency = 0
	rewardToastText.TextStrokeTransparency = 0.45
	rewardToastText.Text = string.format(
		"%s cleared  %s",
		tostring(worldName or "Stage"),
		rewardText
	)
	rewardToast.Size = UDim2.new(0, 390, 0, 46)
	TweenService:Create(rewardToast, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 430, 0, 54),
	}):Play()
	task.delay(4, function()
		if token ~= rewardToastToken then return end
		TweenService:Create(rewardToast, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(rewardToastText, TweenInfo.new(0.35), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.4)
		if token == rewardToastToken then
			rewardToast.Visible = false
		end
	end)
end

local function showStageComplete(name, nextName, color)
	if isInStarterWorld() then
		hideStarterScoreboard()
		return
	end
	popupToken += 1
	stagePopupCountdownActive = true
	stageCountdownActive = true
	burstFireworks(color)
	playScoreboardFinishEffect(color)
	stageLabel.Text = WorldOrder.formatCanonical(name) .. " COMPLETE!"
	objectiveLabel.Text = (nextName == "All stages complete") and nextName or (WorldOrder.formatCanonical(nextName) .. " is open.")
	setStagePanelVisible(true)
	stagePanelStroke.Color = color
	stageTimerStroke.Color = color
	stageTimerLabel.TextColor3 = color
	stageTimerLabel.Visible = false
	stageTimerLabel.Text = ""
	stageCountLabel.Text = "1s"
	stageCountLabel.BackgroundColor3 = Color3.fromRGB(18, 90, 38)
	stageCountStroke.Color = Color3.fromRGB(120, 255, 150)
	stagePopup.Visible = false
end

local function setStageCompleteCountdown(secondsLeft)
	if isInStarterWorld() then
		hideStarterScoreboard()
		return
	end
	stagePopupCountdownActive = true
	stageCountdownActive = true
	setStagePanelVisible(true)
	local seconds = math.max(0, math.ceil(tonumber(secondsLeft) or 0))
	stageTimerLabel.Visible = false
	stageTimerLabel.Text = ""
	stageCountLabel.Text = tostring(seconds) .. "s"
	stageCountLabel.BackgroundColor3 = seconds <= 3 and Color3.fromRGB(110, 44, 24) or Color3.fromRGB(18, 90, 38)
	stageCountStroke.Color = seconds <= 3 and Color3.fromRGB(255, 170, 90) or Color3.fromRGB(120, 255, 150)
end

local function hideStageComplete()
	popupToken += 1
	stagePopupCountdownActive = false
	stageCountdownActive = false
	stagePopup.Visible = false
	setStagePanelVisible(true)
	stagePopup.Size = UDim2.new(0, 390, 0, 82)
	stagePopup.BackgroundTransparency = 0.08
	stagePopupTitle.TextTransparency = 0
	stagePopupSub.TextTransparency = 0
	stageTimerLabel.TextColor3 = Color3.fromRGB(230, 245, 255)
	stageTimerLabel.Visible = false
	stageTimerStroke.Color = Color3.fromRGB(120, 190, 255)
	stageBarShine.BackgroundTransparency = 0.72
	stagePanelStroke.Thickness = 1.5
	stageCountLabel.Size = UDim2.new(0, 82, 0, 28)
	stageCountLabel.Position = UDim2.new(1, -94, 0, 7)
end

task.spawn(function()
	local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end
	local worldHudEvent = gameEvents:WaitForChild("WorldHud", 30)
	if not worldHudEvent then return end
	local stageRewardEvent = gameEvents:WaitForChild("StageReward", 30)
	if stageRewardEvent then
		stageRewardEvent.OnClientEvent:Connect(showRewardToast)
	end

	worldHudEvent.OnClientEvent:Connect(function(eventType, a, b, c)
		if isInStarterWorld() then
			hideStarterScoreboard()
			return
		end
		if eventType == "Complete" then
			if not stagePopup.Visible then
				showStageComplete(tostring(a or "Level"), "Next level", Color3.fromRGB(100, 255, 160))
			end
			stageRunStartTime = nil
			stageCountdownActive = true
			stagePopupCountdownActive = true
			stageTimerLabel.Visible = false
			stageTimerLabel.Text = ""
			stageCountLabel.Text = "1s"
			if b then
				objectiveLabel.Text = "Cleared in " .. formatStageTime(b) .. ". Next level opens soon."
			end
		elseif eventType == "Countdown" then
			setStageCompleteCountdown(a)
		elseif eventType == "Launch" then
			startCompletionSkyLaunch(a, b, c)
		elseif eventType == "Enter" or eventType == "Exit" then
			stageRunStartTime = eventType == "Enter" and os.clock() or nil
			hideStageComplete()
		elseif eventType == "GameComplete" then
			stagePopupCountdownActive = false
			stageCountdownActive = true
			stageLabel.Text = "ALL STAGES COMPLETE!"
			objectiveLabel.Text = "You cleared every stage."
			stageTimerLabel.Visible = false
			stageTimerLabel.Text = ""
			stageCountLabel.Text = "DONE"
		end
	end)
end)

-- ── Grace-period countdown banner ─────────────────────────────────────────────
-- Shown below the stage popup when a level finishes and the exit door is open.
RunService.Heartbeat:Connect(function()
	if isInStarterWorld() then
		hideStarterScoreboard()
		return
	end
	if isOnBridge() then
		stagePanel.Visible = false
		return
	elseif stageRunStartTime or stageCountdownActive or stagePopupCountdownActive then
		setStagePanelVisible(true)
	end
	if stageRunStartTime and not stageCountdownActive then
		stageTimerLabel.Visible = false
	end
end)

local graceBanner = Instance.new("Frame")
graceBanner.Name = "GraceBanner"
graceBanner.AnchorPoint = Vector2.new(0.5, 0)
graceBanner.Size = UDim2.new(0, 360, 0, 46)
graceBanner.Position = UDim2.new(0.5, 0, 0, SAFE_TOP + 104)   -- just below stagePopup
graceBanner.BackgroundColor3 = Color3.fromRGB(10, 30, 10)
graceBanner.BackgroundTransparency = 0.12
graceBanner.BorderSizePixel = 0
graceBanner.Visible = false
graceBanner.ZIndex = 22
graceBanner.Parent = screenGui
Instance.new("UICorner", graceBanner).CornerRadius = UDim.new(0, 10)
local graceStroke = Instance.new("UIStroke")
graceStroke.Color = Color3.fromRGB(80, 255, 120)
graceStroke.Thickness = 2
graceStroke.Transparency = 0.1
graceStroke.Parent = graceBanner

local graceIcon = Instance.new("TextLabel")
graceIcon.Size = UDim2.new(0, 36, 1, 0)
graceIcon.Position = UDim2.new(0, 8, 0, 0)
graceIcon.BackgroundTransparency = 1
graceIcon.Text = "🚪"
graceIcon.TextScaled = true
graceIcon.Font = Enum.Font.GothamBlack
graceIcon.TextColor3 = Color3.new(1, 1, 1)
graceIcon.ZIndex = 23
graceIcon.Parent = graceBanner

local graceLabel = Instance.new("TextLabel")
graceLabel.Size = UDim2.new(1, -54, 1, 0)
graceLabel.Position = UDim2.new(0, 48, 0, 0)
graceLabel.BackgroundTransparency = 1
graceLabel.Text = "EXIT OPEN — 30s"
graceLabel.TextScaled = true
graceLabel.Font = Enum.Font.GothamBlack
graceLabel.TextColor3 = Color3.fromRGB(100, 255, 130)
graceLabel.TextStrokeTransparency = 0.5
graceLabel.ZIndex = 23
graceLabel.Parent = graceBanner

-- Bar showing remaining time
local graceBarBg = Instance.new("Frame")
graceBarBg.Size = UDim2.new(0.88, 0, 0, 5)
graceBarBg.Position = UDim2.new(0.06, 0, 1, -7)
graceBarBg.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
graceBarBg.BorderSizePixel = 0
graceBarBg.ZIndex = 23
graceBarBg.Parent = graceBanner
Instance.new("UICorner", graceBarBg).CornerRadius = UDim.new(1, 0)

local graceBarFill = Instance.new("Frame")
graceBarFill.Size = UDim2.new(1, 0, 1, 0)
graceBarFill.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
graceBarFill.BorderSizePixel = 0
graceBarFill.ZIndex = 24
graceBarFill.Parent = graceBarBg
Instance.new("UICorner", graceBarFill).CornerRadius = UDim.new(1, 0)

local graceEndTime = 0
local graceTotal   = 30

task.spawn(function()
	local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end
	local graceEvent = gameEvents:WaitForChild("LevelGraceCountdown", 30)
	if not graceEvent then return end

	graceEvent.OnClientEvent:Connect(function(worldName, seconds)
		graceEndTime = os.clock() + seconds
		graceTotal   = seconds
		graceBanner.Visible = true

		-- Animate the banner in
		TweenService:Create(graceBanner, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 380, 0, 50),
		}):Play()

		-- Countdown loop
		local myEnd = graceEndTime
		while os.clock() < myEnd do
			local remaining = math.max(0, myEnd - os.clock())
			local secs = math.ceil(remaining)
			local frac = remaining / graceTotal

			graceLabel.Text = "EXIT OPEN — " .. secs .. "s"
			-- Shift color from green → yellow → red as time runs out
			if frac > 0.5 then
				graceLabel.TextColor3 = Color3.fromRGB(100, 255, 130)
				graceStroke.Color    = Color3.fromRGB(80, 255, 120)
			elseif frac > 0.2 then
				graceLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
				graceStroke.Color    = Color3.fromRGB(255, 210, 60)
			else
				graceLabel.TextColor3 = Color3.fromRGB(255, 100, 80)
				graceStroke.Color    = Color3.fromRGB(255, 80, 60)
			end
			graceBarFill.Size = UDim2.new(math.max(0, frac), 0, 1, 0)

			task.wait(0.1)
			if graceEndTime ~= myEnd then return end  -- a new grace event fired; this loop obsolete
		end

		-- Time's up
		graceLabel.Text = "DOORS CLOSED"
		graceLabel.TextColor3 = Color3.fromRGB(255, 80, 60)
		graceBarFill.Size = UDim2.new(0, 0, 1, 0)
		task.wait(1.4)
		if graceEndTime == myEnd then
			TweenService:Create(graceBanner, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			task.wait(0.3)
			graceBanner.Visible = false
			graceBanner.BackgroundTransparency = 0.12
			graceBanner.Size = UDim2.new(0, 360, 0, 46)
		end
	end)
end)

task.spawn(function()
	local gameEvents  = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end
	local brainRem    = gameEvents:WaitForChild("BrainrotsRemaining", 10)
	local emptyRem    = gameEvents:WaitForChild("EmptyWorld1NPCsRemaining", 15)
	local emptyW2Rem  = gameEvents:WaitForChild("EmptyWorld2NPCsRemaining", 15)
	local emptyW3Rem  = gameEvents:WaitForChild("EmptyWorld3NPCsRemaining", 15)
	local emptyW4Rem  = gameEvents:WaitForChild("EmptyWorld4NPCsRemaining", 15)
	local pizzaRem    = gameEvents:WaitForChild("PizzaBrainrotsRemaining", 15)
	local galacticRem = gameEvents:WaitForChild("GalacticBrainrotsRemaining", 15)
	local jungleRem   = gameEvents:WaitForChild("JungleAnimalsRemaining", 20)
	local sportsRem   = gameEvents:WaitForChild("SportsPlayersRemaining", 20)
	local tennisRem   = gameEvents:WaitForChild("TennisPlayersRemaining", 20)
	local stationRem  = gameEvents:WaitForChild("GameStationBotsRemaining", 20)
	local coffeeRem   = gameEvents:WaitForChild("CoffeeBaristasRemaining", 25)
	local burgerRem   = gameEvents:WaitForChild("BurgerCooksRemaining", 25)
	local newPizzaRem = gameEvents:WaitForChild("NewPizzaChefsRemaining", 25)
	local poolRem     = gameEvents:WaitForChild("PoolBirdsRemaining", 25)
	local dinoRem     = gameEvents:WaitForChild("DinosaurDinosRemaining", 25)
	local beachRem    = gameEvents:WaitForChild("DinoBeachDinosRemaining", 25)
	local forestRem   = gameEvents:WaitForChild("FlyingDinoForestDinosRemaining", 25)
	local cherryRem   = gameEvents:WaitForChild("GiantDinoCherriesRemaining", 25)
	local orchardRem  = gameEvents:WaitForChild("GalacticFruitsRemaining", 25)
	local skyVaultRem   = gameEvents:WaitForChild("SkyVaultRemaining", 25)
	local stormTowerRem = gameEvents:WaitForChild("StormTowerRemaining", 25)
	local frostRem      = gameEvents:WaitForChild("FrostBasinRemaining", 25)
	local emberRem      = gameEvents:WaitForChild("EmberHoldRemaining", 25)
	local novaRem       = gameEvents:WaitForChild("NovaSpireRemaining", 25)
	local magmaRem      = gameEvents:WaitForChild("MagmaCoreRemaining", 25)
	local stormCircuitRem = gameEvents:WaitForChild("StormCircuitRemaining", 25)
	local shadowVaultRem  = gameEvents:WaitForChild("ShadowVaultRemaining", 25)
	local apexNexusRem    = gameEvents:WaitForChild("ApexNexusRemaining", 25)
	local cloudDriftRem   = gameEvents:WaitForChild("CloudDriftRemaining", 25)
	local coralReefRem    = gameEvents:WaitForChild("CoralReefRemaining", 25)
	local bubbleBounceRem = gameEvents:WaitForChild("BubbleBounceRemaining", 25)
	local zenGardenRem    = gameEvents:WaitForChild("ZenGardenRemaining", 25)
	local crystalSpiresRem = gameEvents:WaitForChild("CrystalSpiresRemaining", 25)
	local neonTriangleRem  = gameEvents:WaitForChild("NeonTriangleRemaining", 25)
	local wideCanyonRem    = gameEvents:WaitForChild("WideCanyonRemaining", 25)
	local narrowPassRem    = gameEvents:WaitForChild("NarrowPassRemaining", 25)
	local diamondGateRem   = gameEvents:WaitForChild("DiamondGateRemaining", 25)
	local hourglassVaultRem = gameEvents:WaitForChild("HourglassVaultRemaining", 25)
	local movementLabRem = gameEvents:WaitForChild("MovementLabRemaining", 25)
	local fightArenaRem = gameEvents:WaitForChild("FightArenaRemaining", 25)
	local emptyWorld43Rem = gameEvents:WaitForChild("EmptyWorld43Remaining", 25)
	local brainTotal    = gameEvents:FindFirstChild("BrainrotsTotal")
	local emptyTotal    = gameEvents:FindFirstChild("EmptyWorld1NPCsTotal")
	local emptyW2Total  = gameEvents:FindFirstChild("EmptyWorld2NPCsTotal")
	local emptyW3Total  = gameEvents:FindFirstChild("EmptyWorld3NPCsTotal")
	local emptyW4Total  = gameEvents:FindFirstChild("EmptyWorld4NPCsTotal")
	local pizzaTotal    = gameEvents:FindFirstChild("PizzaBrainrotsTotal")
	local galacticTotal = gameEvents:FindFirstChild("GalacticBrainrotsTotal")
	local jungleTotal   = gameEvents:FindFirstChild("JungleAnimalsTotal")
	local sportsTotal   = gameEvents:FindFirstChild("SportsPlayersTotal")
	local tennisTotal   = gameEvents:FindFirstChild("TennisPlayersTotal")
	local stationTotal  = gameEvents:FindFirstChild("GameStationBotsTotal")
	local coffeeTotal   = gameEvents:FindFirstChild("CoffeeBaristasTotal")
	local burgerTotal   = gameEvents:FindFirstChild("BurgerCooksTotal")
	local newPizzaTotal = gameEvents:FindFirstChild("NewPizzaChefsTotal")
	local poolTotal     = gameEvents:FindFirstChild("PoolBirdsTotal")
	local dinoTotal     = gameEvents:FindFirstChild("DinosaurDinosTotal")
	local beachTotal    = gameEvents:FindFirstChild("DinoBeachDinosTotal")
	local forestTotal   = gameEvents:FindFirstChild("FlyingDinoForestDinosTotal")
	local cherryTotal   = gameEvents:FindFirstChild("GiantDinoCherriesTotal")
	local orchardTotal  = gameEvents:FindFirstChild("GalacticFruitsTotal")
	local skyVaultTotal   = gameEvents:FindFirstChild("SkyVaultTotal")
	local stormTowerTotal = gameEvents:FindFirstChild("StormTowerTotal")
	local frostTotal      = gameEvents:FindFirstChild("FrostBasinTotal")
	local emberTotal      = gameEvents:FindFirstChild("EmberHoldTotal")
	local novaTotal       = gameEvents:FindFirstChild("NovaSpireTotal")
	local magmaTotal      = gameEvents:FindFirstChild("MagmaCoreTotal")
	local stormCircuitTotal = gameEvents:FindFirstChild("StormCircuitTotal")
	local shadowVaultTotal  = gameEvents:FindFirstChild("ShadowVaultTotal")
	local apexNexusTotal    = gameEvents:FindFirstChild("ApexNexusTotal")
	local cloudDriftTotal   = gameEvents:FindFirstChild("CloudDriftTotal")
	local coralReefTotal    = gameEvents:FindFirstChild("CoralReefTotal")
	local bubbleBounceTotal = gameEvents:FindFirstChild("BubbleBounceTotal")
	local zenGardenTotal    = gameEvents:FindFirstChild("ZenGardenTotal")
	local crystalSpiresTotal = gameEvents:FindFirstChild("CrystalSpiresTotal")
	local neonTriangleTotal  = gameEvents:FindFirstChild("NeonTriangleTotal")
	local wideCanyonTotal    = gameEvents:FindFirstChild("WideCanyonTotal")
	local narrowPassTotal    = gameEvents:FindFirstChild("NarrowPassTotal")
	local diamondGateTotal   = gameEvents:FindFirstChild("DiamondGateTotal")
	local hourglassVaultTotal = gameEvents:FindFirstChild("HourglassVaultTotal")
	local movementLabTotal = gameEvents:FindFirstChild("MovementLabTotal")
	local fightArenaTotal = gameEvents:FindFirstChild("FightArenaTotal")
	local emptyWorld43Total = gameEvents:FindFirstChild("EmptyWorld43Total")
	local stageHits   = gameEvents:WaitForChild("StageHits", 10)
	local stageNeeded = gameEvents:WaitForChild("StageNeeded", 10)
	local activeWorld = gameEvents:WaitForChild("ActiveWorldName", 10)
	local activeState = gameEvents:WaitForChild("ActiveWorldState", 10)
	if not brainRem or not emptyRem or not emptyW2Rem or not emptyW3Rem or not emptyW4Rem or not pizzaRem or not galacticRem or not stageHits or not stageNeeded then return end

	local stageDefs = {
		{ names = { "Playground" }, rem = brainRem, total = brainTotal, target = Balance.StageTargets.Playground, title = "GALACTIC ROBOTS", action = "DEFEATED", objective = "Pick up balls and throw them at galactic robots.", color = Color3.fromRGB(220, 50, 50) },
		{ names = { "Empty World 1", "Dino Ball Sky", "Dino Ball World" }, rem = emptyRem, total = emptyTotal, target = Balance.StageTargets.EmptyWorld1, title = "HIT THE SMALL DINO", action = "DEFEATED", objective = "Hit dinos with fireballs — only the smallest counts!", color = Color3.fromRGB(255, 80, 80) },
		{ names = { "Storm Dome", "Empty World 2", "EmptyWorld2", "StormDome" }, rem = emptyW2Rem, total = emptyW2Total, target = Balance.StageTargets.EmptyWorld2, title = "HIT THE SMALL DINO", action = "DEFEATED", objective = "Hit jumping dinos with fireballs — only the smallest counts!", color = Color3.fromRGB(255, 220, 30) },
		{ names = { "Volt Abyss", "Empty World 3", "EmptyWorld3", "VoltAbyss" }, rem = emptyW3Rem, total = emptyW3Total, target = Balance.StageTargets.EmptyWorld3, title = "HIT THE SMALL DINO", action = "DEFEATED", objective = "Hit flying dinos with fireballs — only the smallest counts!", color = Color3.fromRGB(255, 80, 180) },
		{ names = { "Neon Rift", "Empty World 4", "EmptyWorld4", "NeonRift" }, rem = emptyW4Rem, total = emptyW4Total, target = Balance.StageTargets.EmptyWorld4, title = "COLOR SQUARE JUMP", action = "SCORED", objective = "Jump on your blinking colored square before it resets!", color = Color3.fromRGB(0, 220, 255) },
		{ names = { "Pizza" }, rem = pizzaRem, total = pizzaTotal, target = Balance.StageTargets.Pizza, title = "PIZZA", action = "DEFEATED", objective = "Use split balls to defeat pizza enemies.", color = Color3.fromRGB(255, 130, 0) },
		{ names = { "Galactic" }, rem = galacticRem, total = galacticTotal, target = Balance.StageTargets.Galactic, title = "GALACTIC", action = "DEFEATED", objective = "Throw heavy balls at galactic enemies.", color = Color3.fromRGB(100, 0, 180) },
		{ names = { "Jungle" }, rem = jungleRem, total = jungleTotal, target = Balance.StageTargets.Jungle, title = "JUNGLE", action = "DEFEATED", objective = "Hit the jungle animals with balls.", color = Color3.fromRGB(50, 180, 50) },
		{ names = { "Sports" }, rem = sportsRem, total = sportsTotal, target = Balance.StageTargets.Sports, title = "SPORTS", action = "DEFEATED", objective = "Defeat the sports players with balls.", color = Color3.fromRGB(255, 210, 60) },
		{ names = { "Tennis" }, rem = tennisRem, total = tennisTotal, target = Balance.StageTargets.Tennis, title = "TENNIS", action = "DEFEATED", objective = "Defeat tennis players using the court balls.", color = Color3.fromRGB(150, 255, 85) },
		{ names = { "Game Station" }, rem = stationRem, total = stationTotal, target = Balance.StageTargets.GameStation, title = "GAME STATION", action = "DEFEATED", objective = "Defeat the game station bots.", color = Color3.fromRGB(80, 220, 255) },
		{ names = { "Coffee Shop" }, rem = coffeeRem, total = coffeeTotal, target = Balance.StageTargets.CoffeeShop, title = "COFFEE BIRDS", action = "CAUGHT", objective = "Hold the net and touch birds to catch them.", color = Color3.fromRGB(255, 180, 60) },
		{ names = { "Burger House" }, rem = burgerRem, total = burgerTotal, target = Balance.StageTargets.BurgerHouse, title = "BURGER BIRDS", action = "CAUGHT", objective = "Catch burger birds with your net.", color = Color3.fromRGB(255, 220, 70) },
		{ names = { "New Pizza Place", "New Pizza" }, rem = newPizzaRem, total = newPizzaTotal, target = Balance.StageTargets.NewPizzaPlace, title = "NEW PIZZA BIRDS", action = "CAUGHT", objective = "Catch the flying pizza birds.", color = Color3.fromRGB(255, 120, 80) },
		{ names = { "Swimming Pool" }, rem = poolRem, total = poolTotal, target = Balance.StageTargets.SwimmingPool, title = "POOL BIRDS", action = "CAUGHT", objective = "Catch pool birds above the water area.", color = Color3.fromRGB(80, 220, 255) },
		{ names = { "Dinosaur Park" }, rem = dinoRem, total = dinoTotal, target = Balance.StageTargets.DinosaurPark, title = "DINOSAURS", action = "CAUGHT", objective = "Catch dinosaurs by touching them with the net.", color = Color3.fromRGB(100, 255, 110) },
		{ names = { "Dino Beach" }, rem = beachRem, total = beachTotal, target = Balance.StageTargets.DinoBeach, title = "BEACH DINOS", action = "CAUGHT", objective = "Catch beach dinosaurs with the net.", color = Color3.fromRGB(255, 230, 90) },
		{ names = { "Flying Dino Forest" }, rem = forestRem, total = forestTotal, target = Balance.StageTargets.FlyingDinoForest, title = "FLYING DINOS", action = "CAUGHT", objective = "Catch flying dinos in the forest sky.", color = Color3.fromRGB(100, 255, 110) },
		{ names = { "Cherry Grove" }, rem = cherryRem, total = cherryTotal, target = Balance.StageTargets.CherryGrove, title = "CHERRIES", action = "EATEN", objective = "Ride a dino and use its head to eat cherries.", color = Color3.fromRGB(255, 80, 80) },
		{ names = { "Galactic Orchard" }, rem = orchardRem, total = orchardTotal, target = Balance.StageTargets.GalacticOrchard, title = "GALACTIC FRUIT", action = "CAPTURED", objective = "Ride the upgraded dino and capture galactic fruit.", color = Color3.fromRGB(80, 240, 255) },
		{ names = { "Sky Vault", "SkyVault" }, rem = skyVaultRem, total = skyVaultTotal, target = Balance.StageTargets.SkyVault, title = "REACH THE TOP", action = "REACHED TOP", objective = "Use jump pads to reach the golden finish platform!", color = Color3.fromRGB(255, 215, 0) },
		{ names = { "Storm Tower", "StormTower" }, rem = stormTowerRem, total = stormTowerTotal, target = Balance.StageTargets.StormTower, title = "REACH THE STORM", action = "REACHED TOP", objective = "Climb the massive tower using jump pads — enter and exit through wall holes!", color = Color3.fromRGB(100, 200, 255) },
		{ names = { "Frost Basin", "FrostBasin" }, rem = frostRem, total = frostTotal, target = Balance.StageTargets.FrostBasin or 1, title = "FROST BASIN", action = "CLEARED", objective = "Use the icy jumpers to reach the finish.", color = Color3.fromRGB(140, 230, 255) },
		{ names = { "Ember Hold", "EmberHold" }, rem = emberRem, total = emberTotal, target = Balance.StageTargets.EmberHold or 1, title = "EMBER HOLD", action = "CLEARED", objective = "Use the ember jumpers to reach the finish.", color = Color3.fromRGB(255, 120, 45) },
		{ names = { "Nova Spire", "NovaSpire" }, rem = novaRem, total = novaTotal, target = Balance.StageTargets.NovaSpire or 1, title = "NOVA SPIRE", action = "CLEARED", objective = "Use the jumpers to reach the top finish platform.", color = Color3.fromRGB(190, 120, 255) },
		{ names = { "Magma Core", "MagmaCore" }, rem = magmaRem, total = magmaTotal, target = Balance.StageTargets.MagmaCore or 1, title = "MAGMA CORE", action = "CLEARED", objective = "Use lava helpers to reach the diamond top.", color = Color3.fromRGB(255, 100, 35) },
		{ names = { "Storm Circuit", "StormCircuit" }, rem = stormCircuitRem, total = stormCircuitTotal, target = Balance.StageTargets.StormCircuit or 1, title = "STORM CIRCUIT", action = "CLEARED", objective = "Ride electric helpers through the narrow circuit.", color = Color3.fromRGB(80, 220, 255) },
		{ names = { "Shadow Vault", "ShadowVault" }, rem = shadowVaultRem, total = shadowVaultTotal, target = Balance.StageTargets.ShadowVault or 1, title = "SHADOW VAULT", action = "CLEARED", objective = "Climb the triangle vault using glowing pads.", color = Color3.fromRGB(170, 90, 255) },
		{ names = { "Apex Nexus", "ApexNexus" }, rem = apexNexusRem, total = apexNexusTotal, target = Balance.StageTargets.ApexNexus or 1, title = "APEX NEXUS", action = "CLEARED", objective = "Bounce through the hex hub to the beacon.", color = Color3.fromRGB(255, 220, 80) },
		{ names = { "Cloud Drift", "CloudDrift" }, rem = cloudDriftRem, total = cloudDriftTotal, target = Balance.StageTargets.CloudDrift or 1, title = "CLOUD DRIFT", action = "CLEARED", objective = "Use soft cloud helpers to float upward.", color = Color3.fromRGB(220, 245, 255) },
		{ names = { "Coral Reef", "CoralReef" }, rem = coralReefRem, total = coralReefTotal, target = Balance.StageTargets.CoralReef or 1, title = "CORAL REEF", action = "CLEARED", objective = "Hop across reef helpers to the top ring.", color = Color3.fromRGB(80, 190, 255) },
		{ names = { "Bubble Bounce", "BubbleBounce" }, rem = bubbleBounceRem, total = bubbleBounceTotal, target = Balance.StageTargets.BubbleBounce or 1, title = "BUBBLE BOUNCE", action = "CLEARED", objective = "Bounce through the octagon bubble room.", color = Color3.fromRGB(110, 255, 240) },
		{ names = { "Zen Garden", "ZenGarden" }, rem = zenGardenRem, total = zenGardenTotal, target = Balance.StageTargets.ZenGarden or 1, title = "ZEN GARDEN", action = "CLEARED", objective = "Follow the calm helper pads to the final top.", color = Color3.fromRGB(150, 255, 110) },
		{ names = { "Crystal Spires", "CrystalSpires" }, rem = crystalSpiresRem, total = crystalSpiresTotal, target = Balance.StageTargets.CrystalSpires or 1, title = "CRYSTAL SPIRES", action = "CLEARED", objective = "Climb the jagged crystal jumpers to the finish.", color = Color3.fromRGB(90, 245, 255) },
		{ names = { "Neon Triangle", "NeonTriangle" }, rem = neonTriangleRem, total = neonTriangleTotal, target = Balance.StageTargets.NeonTriangle or 1, title = "NEON TRIANGLE", action = "CLEARED", objective = "Use angled neon helpers to reach the top.", color = Color3.fromRGB(255, 80, 220) },
		{ names = { "Wide Canyon", "WideCanyon" }, rem = wideCanyonRem, total = wideCanyonTotal, target = Balance.StageTargets.WideCanyon or 1, title = "WIDE CANYON", action = "CLEARED", objective = "Cross the zigzag canyon pads upward.", color = Color3.fromRGB(255, 150, 50) },
		{ names = { "Narrow Pass", "NarrowPass" }, rem = narrowPassRem, total = narrowPassTotal, target = Balance.StageTargets.NarrowPass or 1, title = "NARROW PASS", action = "CLEARED", objective = "Recover with side pads and climb the pinched route.", color = Color3.fromRGB(110, 255, 90) },
		{ names = { "Diamond Gate", "DiamondGate" }, rem = diamondGateRem, total = diamondGateTotal, target = Balance.StageTargets.DiamondGate or 1, title = "DIAMOND GATE", action = "CLEARED", objective = "Ride the kite-shaped launch path to the beacon.", color = Color3.fromRGB(255, 230, 70) },
		{ names = { "Hourglass Vault", "HourglassVault" }, rem = hourglassVaultRem, total = hourglassVaultTotal, target = Balance.StageTargets.HourglassVault or 1, title = "HOURGLASS VAULT", action = "CLEARED", objective = "Use the bowtie vault helpers to reach Movement Lab.", color = Color3.fromRGB(210, 110, 255) },
		{ names = { "Movement Lab", "MovementLab" }, rem = movementLabRem, total = movementLabTotal, target = Balance.StageTargets.MovementLab or 1, title = "MOVEMENT LAB", action = "CLEARED", objective = "Master the movement pads to reach Fight Arena.", color = Color3.fromRGB(60, 180, 255) },
		{ names = { "Fight Arena", "FightArena" }, rem = fightArenaRem, total = fightArenaTotal, target = Balance.StageTargets.FightArena or 1, title = "FIGHT ARENA", action = "CLEARED", objective = "Jump on the gladiator head to clear the arena.", color = Color3.fromRGB(255, 70, 70) },
		{ names = { "Empty World 43", "EmptyWorld43" }, rem = emptyWorld43Rem, total = emptyWorld43Total, target = Balance.StageTargets.EmptyWorld43 or 4, title = "EMPTY WORLD 43", action = "DEFEATED", objective = "Hit the three small NPCs and the big boss with balls.", color = Color3.fromRGB(120, 255, 60) },
	}

	local function findStageByName(name)
		for _, def in stageDefs do
			for _, stageName in def.names do
				if stageName == name then
					return def
				end
			end
		end
		return nil
	end

	local function firstUnfinishedStage()
		for _, def in stageDefs do
			if def.rem and def.rem.Value > 0 then
				return def
			end
		end
		return nil
	end

	local function refreshStage()
		if isInStarterWorld() then
			hideStarterScoreboard()
			return
		end
		if stageCountdownActive then return end
		local activeName = activeWorld and activeWorld.Value or ""
		local isRunning = activeState and activeState.Value == "Running"
		local def = isRunning and findStageByName(activeName) or firstUnfinishedStage()
		if not def then
			stageLabel.Text = "ALL STAGES COMPLETE!"
			objectiveLabel.Text = "You cleared every stage."
			stageLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
			stageCountLabel.Text = "DONE"
			stageCountLabel.BackgroundColor3 = Color3.fromRGB(20, 90, 40)
			stageBarFill.Size = UDim2.new(1, 0, 1, 0)
			stageBarFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
			stagePanelStroke.Color = Color3.fromRGB(80, 255, 120)
			return
		end

		local needed = math.max(1, def.target or stageNeeded.Value or 1)
		local hits
		local personalHits   = player:GetAttribute("PersonalHits")
		local personalTarget = player:GetAttribute("PersonalTarget")
		if personalHits ~= nil and personalTarget ~= nil and personalTarget > 0 then
			needed = personalTarget
			hits   = math.clamp(personalHits, 0, needed)
		else
			local total = def.total and def.total.Value or 0
			local remaining = def.rem and def.rem.Value or total
			if def.rem and def.total and total > 0 then
				hits = total - remaining
			else
				hits = stageHits.Value
			end
		end
		hits = math.clamp(hits, 0, needed)
		local left = math.max(0, needed - hits)
		local ratio  = math.min(1, hits / needed)

		local function scoreText(title, action)
			local leftColor = left <= 0 and "#50ff50" or "#ffffff"
			return string.format(
				"%s LEFT <font color=\"%s\">%d</font>",
				title,
				leftColor,
				left
			)
		end

		local function setStage(title, action, objective, color)
			stageLabel.Text = scoreText(title, action)
			objectiveLabel.Text = objective
			stageBarFill.BackgroundColor3 = color
			stagePanelStroke.Color = color
			stageCountLabel.Text = string.format("%d / %d", hits, needed)
			stageCountLabel.BackgroundColor3 = left <= 0 and Color3.fromRGB(18, 90, 38) or Color3.fromRGB(18, 24, 36)
			stageCountStroke.Color = left <= 0 and Color3.fromRGB(120, 255, 150) or color
		end

		local order = WorldOrder.getOrder(def.names[1])
		local numberedTitle = order and string.format("%02d  %s", order, def.title) or def.title
		setStage(numberedTitle, def.action, def.objective, def.color)
		stageLabel.TextColor3 = Color3.new(1, 1, 1)
		stageBarFill.Size = UDim2.new(ratio, 0, 1, 0)
	end

	refreshStage()
	stageHits.Changed:Connect(refreshStage)
	stageNeeded.Changed:Connect(refreshStage)
	player:GetAttributeChangedSignal("PersonalHits"):Connect(refreshStage)
	player:GetAttributeChangedSignal("PersonalTarget"):Connect(refreshStage)
	if activeWorld then activeWorld.Changed:Connect(refreshStage) end
	if activeState then
		activeState.Changed:Connect(function(newState)
			if newState == "Running" then
				hideStageComplete()
			end
			refreshStage()
		end)
	end
	brainRem.Changed:Connect(refreshStage)
	emptyRem.Changed:Connect(refreshStage)
	if emptyW2Rem then emptyW2Rem.Changed:Connect(refreshStage) end
	if emptyW3Rem then emptyW3Rem.Changed:Connect(refreshStage) end
	if emptyW4Rem then emptyW4Rem.Changed:Connect(refreshStage) end
	pizzaRem.Changed:Connect(refreshStage)
	galacticRem.Changed:Connect(refreshStage)
	if jungleRem then jungleRem.Changed:Connect(refreshStage) end
	if sportsRem then sportsRem.Changed:Connect(refreshStage) end
	if tennisRem then tennisRem.Changed:Connect(refreshStage) end
	if stationRem then stationRem.Changed:Connect(refreshStage) end
	if coffeeRem then coffeeRem.Changed:Connect(refreshStage) end
	if burgerRem then burgerRem.Changed:Connect(refreshStage) end
	if newPizzaRem then newPizzaRem.Changed:Connect(refreshStage) end
	if poolRem then poolRem.Changed:Connect(refreshStage) end
	if dinoRem then dinoRem.Changed:Connect(refreshStage) end
	if beachRem then beachRem.Changed:Connect(refreshStage) end
	if forestRem then forestRem.Changed:Connect(refreshStage) end
	if cherryRem then cherryRem.Changed:Connect(refreshStage) end
	if orchardRem then orchardRem.Changed:Connect(refreshStage) end
	if skyVaultRem   then skyVaultRem.Changed:Connect(refreshStage)   end
	if stormTowerRem then stormTowerRem.Changed:Connect(refreshStage) end
	if frostRem then frostRem.Changed:Connect(refreshStage) end
	if emberRem then emberRem.Changed:Connect(refreshStage) end
	if novaRem then novaRem.Changed:Connect(refreshStage) end
	if magmaRem then magmaRem.Changed:Connect(refreshStage) end
	if stormCircuitRem then stormCircuitRem.Changed:Connect(refreshStage) end
	if shadowVaultRem then shadowVaultRem.Changed:Connect(refreshStage) end
	if apexNexusRem then apexNexusRem.Changed:Connect(refreshStage) end
	if cloudDriftRem then cloudDriftRem.Changed:Connect(refreshStage) end
	if coralReefRem then coralReefRem.Changed:Connect(refreshStage) end
	if bubbleBounceRem then bubbleBounceRem.Changed:Connect(refreshStage) end
	if zenGardenRem then zenGardenRem.Changed:Connect(refreshStage) end
	if crystalSpiresRem then crystalSpiresRem.Changed:Connect(refreshStage) end
	if neonTriangleRem then neonTriangleRem.Changed:Connect(refreshStage) end
	if wideCanyonRem then wideCanyonRem.Changed:Connect(refreshStage) end
	if narrowPassRem then narrowPassRem.Changed:Connect(refreshStage) end
	if diamondGateRem then diamondGateRem.Changed:Connect(refreshStage) end
	if hourglassVaultRem then hourglassVaultRem.Changed:Connect(refreshStage) end

	local trackers = {
		{ value = brainRem, name = "Playground", nextName = "Pizza", color = Color3.fromRGB(220, 50, 50), last = brainRem.Value },
		{ value = pizzaRem, name = "Pizza", nextName = "Galactic", color = Color3.fromRGB(255, 130, 0), last = pizzaRem.Value },
		{ value = galacticRem, name = "Galactic", nextName = "Jungle", color = Color3.fromRGB(180, 80, 255), last = galacticRem.Value },
		{ value = jungleRem, name = "Jungle", nextName = "Sports", color = Color3.fromRGB(80, 220, 80), last = jungleRem and jungleRem.Value or 0 },
		{ value = sportsRem, name = "Sports", nextName = "Tennis", color = Color3.fromRGB(255, 210, 60), last = sportsRem and sportsRem.Value or 0 },
		{ value = tennisRem, name = "Tennis", nextName = "Game Station", color = Color3.fromRGB(150, 255, 85), last = tennisRem and tennisRem.Value or 0 },
		{ value = stationRem, name = "Game Station", nextName = "Coffee Shop", color = Color3.fromRGB(80, 220, 255), last = stationRem and stationRem.Value or 0 },
		{ value = coffeeRem, name = "Coffee Shop", nextName = "Burger House", color = Color3.fromRGB(255, 180, 60), last = coffeeRem and coffeeRem.Value or 0 },
		{ value = burgerRem, name = "Burger House", nextName = "New Pizza Place", color = Color3.fromRGB(255, 220, 70), last = burgerRem and burgerRem.Value or 0 },
		{ value = newPizzaRem, name = "New Pizza Place", nextName = "Swimming Pool", color = Color3.fromRGB(255, 120, 80), last = newPizzaRem and newPizzaRem.Value or 0 },
		{ value = poolRem, name = "Swimming Pool", nextName = "Dinosaur Park", color = Color3.fromRGB(80, 220, 255), last = poolRem and poolRem.Value or 0 },
		{ value = dinoRem, name = "Dinosaur Park", nextName = "Dino Beach", color = Color3.fromRGB(100, 255, 110), last = dinoRem and dinoRem.Value or 0 },
		{ value = beachRem, name = "Dino Beach", nextName = "Flying Dino Forest", color = Color3.fromRGB(255, 230, 90), last = beachRem and beachRem.Value or 0 },
		{ value = forestRem, name = "Flying Dino Forest", nextName = "Cherry Grove", color = Color3.fromRGB(100, 255, 110), last = forestRem and forestRem.Value or 0 },
		{ value = cherryRem, name = "Cherry Grove", nextName = "Galactic Orchard", color = Color3.fromRGB(255, 80, 80), last = cherryRem and cherryRem.Value or 0 },
		{ value = orchardRem, name = "Galactic Orchard", nextName = "Empty World 1", color = Color3.fromRGB(80, 240, 255), last = orchardRem and orchardRem.Value or 0 },
		{ value = emptyRem, name = "Empty World 1", nextName = "Storm Dome", color = Color3.fromRGB(255, 80, 80), last = emptyRem.Value },
		{ value = emptyW2Rem, name = "Storm Dome", nextName = "Volt Abyss", color = Color3.fromRGB(255, 220, 30), last = emptyW2Rem and emptyW2Rem.Value or 0 },
		{ value = emptyW3Rem, name = "Volt Abyss", nextName = "Neon Rift", color = Color3.fromRGB(255, 80, 180), last = emptyW3Rem and emptyW3Rem.Value or 0 },
		{ value = emptyW4Rem, name = "Neon Rift", nextName = "Sky Vault", color = Color3.fromRGB(0, 220, 255), last = emptyW4Rem and emptyW4Rem.Value or 0 },
		{ value = skyVaultRem,   name = "Sky Vault",    nextName = "Storm Tower",         color = Color3.fromRGB(255, 215, 0),   last = skyVaultRem and skyVaultRem.Value or 0 },
		{ value = stormTowerRem, name = "Storm Tower",  nextName = "Frost Basin",          color = Color3.fromRGB(100, 200, 255), last = stormTowerRem and stormTowerRem.Value or 0 },
		{ value = frostRem,      name = "Frost Basin",  nextName = "Ember Hold",           color = Color3.fromRGB(140, 230, 255), last = frostRem and frostRem.Value or 0 },
		{ value = emberRem,      name = "Ember Hold",   nextName = "Nova Spire",           color = Color3.fromRGB(255, 120, 45),  last = emberRem and emberRem.Value or 0 },
		{ value = novaRem,       name = "Nova Spire",   nextName = "Prism Peak",           color = Color3.fromRGB(190, 120, 255), last = novaRem and novaRem.Value or 0 },
		{ value = magmaRem,      name = "Magma Core",   nextName = "Storm Circuit",        color = Color3.fromRGB(255, 100, 35),  last = magmaRem and magmaRem.Value or 0 },
		{ value = stormCircuitRem, name = "Storm Circuit", nextName = "Shadow Vault",      color = Color3.fromRGB(80, 220, 255),  last = stormCircuitRem and stormCircuitRem.Value or 0 },
		{ value = shadowVaultRem,  name = "Shadow Vault",  nextName = "Apex Nexus",        color = Color3.fromRGB(170, 90, 255),  last = shadowVaultRem and shadowVaultRem.Value or 0 },
		{ value = apexNexusRem,    name = "Apex Nexus",    nextName = "Cloud Drift",       color = Color3.fromRGB(255, 220, 80),  last = apexNexusRem and apexNexusRem.Value or 0 },
		{ value = cloudDriftRem,   name = "Cloud Drift",   nextName = "Coral Reef",        color = Color3.fromRGB(220, 245, 255), last = cloudDriftRem and cloudDriftRem.Value or 0 },
		{ value = coralReefRem,    name = "Coral Reef",    nextName = "Bubble Bounce",     color = Color3.fromRGB(80, 190, 255),  last = coralReefRem and coralReefRem.Value or 0 },
		{ value = bubbleBounceRem, name = "Bubble Bounce", nextName = "Zen Garden",        color = Color3.fromRGB(110, 255, 240), last = bubbleBounceRem and bubbleBounceRem.Value or 0 },
		{ value = zenGardenRem,    name = "Zen Garden",    nextName = "Crystal Spires",    color = Color3.fromRGB(150, 255, 110), last = zenGardenRem and zenGardenRem.Value or 0 },
		{ value = crystalSpiresRem, name = "Crystal Spires", nextName = "Neon Triangle",   color = Color3.fromRGB(90, 245, 255),  last = crystalSpiresRem and crystalSpiresRem.Value or 0 },
		{ value = neonTriangleRem,  name = "Neon Triangle",  nextName = "Wide Canyon",     color = Color3.fromRGB(255, 80, 220),  last = neonTriangleRem and neonTriangleRem.Value or 0 },
		{ value = wideCanyonRem,    name = "Wide Canyon",    nextName = "Narrow Pass",     color = Color3.fromRGB(255, 150, 50),  last = wideCanyonRem and wideCanyonRem.Value or 0 },
		{ value = narrowPassRem,    name = "Narrow Pass",    nextName = "Diamond Gate",    color = Color3.fromRGB(110, 255, 90),  last = narrowPassRem and narrowPassRem.Value or 0 },
		{ value = diamondGateRem,   name = "Diamond Gate",   nextName = "Hourglass Vault", color = Color3.fromRGB(255, 230, 70),  last = diamondGateRem and diamondGateRem.Value or 0 },
		{ value = hourglassVaultRem, name = "Hourglass Vault", nextName = "Movement Lab", color = Color3.fromRGB(210, 110, 255), last = hourglassVaultRem and hourglassVaultRem.Value or 0 },
		{ value = movementLabRem, name = "Movement Lab", nextName = "Fight Arena", color = Color3.fromRGB(60, 180, 255), last = movementLabRem and movementLabRem.Value or 0 },
		{ value = fightArenaRem, name = "Fight Arena", nextName = "Empty World 43", color = Color3.fromRGB(255, 70, 70), last = fightArenaRem and fightArenaRem.Value or 0 },
		{ value = emptyWorld43Rem, name = "Empty World 43", nextName = "All stages complete", color = Color3.fromRGB(120, 255, 60), last = emptyWorld43Rem and emptyWorld43Rem.Value or 0 },
	}
	for _, tracker in trackers do
		if tracker.value then
			tracker.value.Changed:Connect(function(newValue)
				-- WorldHud "Complete" is the single owner of stage-complete popups.
				-- Counter changes can happen during NPC cleanup/restart and used to show extra completions.
				tracker.last = newValue
			end)
		end
	end
end)

-- Hint label
local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0, 320, 0, 42)
hintLabel.Position = UDim2.new(0.5, -160, 0.87, 0)
hintLabel.BackgroundTransparency = 0.4
hintLabel.BackgroundColor3 = Color3.new(0, 0, 0)
hintLabel.TextColor3 = Color3.new(1, 1, 1)
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 17
hintLabel.Text = ""
hintLabel.Visible = false
hintLabel.Parent = screenGui
Instance.new("UICorner", hintLabel).CornerRadius = UDim.new(0, 8)

-- Power bar container
local powerContainer = Instance.new("Frame")
powerContainer.Size = UDim2.new(0, 320, 0, 46)
powerContainer.Position = UDim2.new(0.5, -160, 0.79, 0)
powerContainer.BackgroundTransparency = 1
powerContainer.Visible = false
powerContainer.Parent = screenGui

local powerLabel = Instance.new("TextLabel")
powerLabel.Size = UDim2.new(1, 0, 0, 18)
powerLabel.BackgroundTransparency = 1
powerLabel.Text = "POWER"
powerLabel.TextColor3 = Color3.new(1, 1, 1)
powerLabel.Font = Enum.Font.GothamBold
powerLabel.TextSize = 14
powerLabel.TextXAlignment = Enum.TextXAlignment.Center
powerLabel.TextStrokeTransparency = 0
powerLabel.Parent = powerContainer

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, 0, 0, 24)
barBg.Position = UDim2.new(0, 0, 0, 20)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
barBg.BorderSizePixel = 0
barBg.Parent = powerContainer
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 6)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 6)

-- Shine strip on bar
local shine = Instance.new("Frame")
shine.Size = UDim2.new(1, 0, 0.4, 0)
shine.BackgroundColor3 = Color3.new(1, 1, 1)
shine.BackgroundTransparency = 0.75
shine.BorderSizePixel = 0
shine.ZIndex = 2
shine.Parent = barFill
Instance.new("UICorner", shine).CornerRadius = UDim.new(0, 4)

-- =============================================
-- MOBILE THROW BUTTON  (touch devices only)
-- =============================================
local throwBtn = nil
local throwBtnInput = nil   -- tracks the finger holding the button

if isTouchDevice then
	throwBtn = Instance.new("TextButton")
	throwBtn.Name = "ThrowBtn"
	throwBtn.Size = UDim2.new(0, 75, 0, 75)
	-- Position: same height as jump button, directly to its left
	throwBtn.Position = UDim2.new(1, -185, 1, -70)
	throwBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	throwBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
	throwBtn.BackgroundTransparency = 0.18
	throwBtn.BorderSizePixel = 0
	throwBtn.Text = ""
	throwBtn.ZIndex = 10
	throwBtn.Visible = false
	throwBtn.Parent = screenGui
	Instance.new("UICorner", throwBtn).CornerRadius = UDim.new(1, 0)

	local throwBtnStroke = Instance.new("UIStroke")
	throwBtnStroke.Color = Color3.fromRGB(140, 80, 255)
	throwBtnStroke.Thickness = 2.5
	throwBtnStroke.Transparency = 0.1
	throwBtnStroke.Parent = throwBtn

	-- Icon label (ball + arrow icon via text)
	local throwBtnIcon = Instance.new("TextLabel")
	throwBtnIcon.Size = UDim2.new(1, 0, 0.56, 0)
	throwBtnIcon.Position = UDim2.new(0, 0, 0.06, 0)
	throwBtnIcon.BackgroundTransparency = 1
	throwBtnIcon.Text = "🏐"
	throwBtnIcon.TextScaled = true
	throwBtnIcon.Font = Enum.Font.GothamBlack
	throwBtnIcon.TextColor3 = Color3.new(1, 1, 1)
	throwBtnIcon.ZIndex = 11
	throwBtnIcon.Parent = throwBtn

	local throwBtnLabel = Instance.new("TextLabel")
	throwBtnLabel.Name = "ThrowBtnLabel"
	throwBtnLabel.Size = UDim2.new(1, 0, 0.32, 0)
	throwBtnLabel.Position = UDim2.new(0, 0, 0.64, 0)
	throwBtnLabel.BackgroundTransparency = 1
	throwBtnLabel.Text = "THROW"
	throwBtnLabel.TextScaled = true
	throwBtnLabel.Font = Enum.Font.GothamBlack
	throwBtnLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
	throwBtnLabel.ZIndex = 11
	throwBtnLabel.Parent = throwBtn

	-- Wire up input: finger down = pickup (if no ball) or start charge (if holding ball)
	throwBtn.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then return end
		if isCharging then return end
		if not heldBall then
			tryPickup()
			-- If we just picked up, immediately show the hold-to-throw hint
			if heldBall then
				applyBallHint(heldBall, false)
			end
		else
			isCharging = true
			chargePower = 0
			chargeInput = input
			throwBtnInput = input
			applyBallHint(heldBall, true)
		end
	end)

	-- Finger lifted = throw if charging
	throwBtn.InputEnded:Connect(function(input)
		if input == throwBtnInput and isCharging then
			throwBtnInput = nil
			doThrow()
		end
	end)
end

-- =============================================
-- TRAJECTORY DOTS  (world-space, local only)
-- =============================================
local trajDots = {}
local PHASE1_COUNT = math.floor(TRAJ_DOTS * PHASE1_FRAC)
for i = 1, TRAJ_DOTS do
	local dot = Instance.new("Part")
	dot.Name = "TrajDot"
	dot.Shape = Enum.PartType.Ball
	-- Straight-phase dots: lime green, larger; drop-phase dots: yellow→orange, smaller
	local isPhase1 = i <= PHASE1_COUNT
	local phFrac = isPhase1
		and (i / PHASE1_COUNT)
		or  ((i - PHASE1_COUNT) / (TRAJ_DOTS - PHASE1_COUNT))
	local sz = isPhase1 and (0.58 - phFrac * 0.18) or (0.40 - phFrac * 0.18)
	dot.Size = Vector3.new(sz, sz, sz)
	dot.Anchored = true
	dot.CanCollide = false
	dot.CastShadow = false
	dot.Material = Enum.Material.Neon
	if isPhase1 then
		dot.BrickColor = BrickColor.new("Lime green")
	elseif phFrac < 0.5 then
		dot.BrickColor = BrickColor.new("Bright yellow")
	else
		dot.BrickColor = BrickColor.new("Bright orange")
	end
	dot.Transparency = isPhase1 and (0.05 + phFrac * 0.4) or (0.3 + phFrac * 0.55)
	dot.CFrame = CFrame.new(0, -2000, 0)
	dot.Parent = workspace
	trajDots[i] = dot
end

-- Landing disc (outer ring + inner center)
local aimDisc = Instance.new("Part")
aimDisc.Name = "AimDisc"
aimDisc.Shape = Enum.PartType.Cylinder
aimDisc.Size = Vector3.new(0.12, 5.5, 5.5)
aimDisc.Anchored = true
aimDisc.CanCollide = false
aimDisc.CastShadow = false
aimDisc.BrickColor = BrickColor.new("Bright red")
aimDisc.Material = Enum.Material.Neon
aimDisc.Transparency = 0.28
aimDisc.CFrame = CFrame.new(0, -2000, 0)
aimDisc.Parent = workspace

local aimDiscCenter = Instance.new("Part")
aimDiscCenter.Name = "AimDiscCenter"
aimDiscCenter.Shape = Enum.PartType.Cylinder
aimDiscCenter.Size = Vector3.new(0.14, 1.8, 1.8)
aimDiscCenter.Anchored = true
aimDiscCenter.CanCollide = false
aimDiscCenter.CastShadow = false
aimDiscCenter.BrickColor = BrickColor.new("White")
aimDiscCenter.Material = Enum.Material.Neon
aimDiscCenter.Transparency = 0.15
aimDiscCenter.CFrame = CFrame.new(0, -2000, 0)
aimDiscCenter.Parent = workspace

-- =============================================
-- HELPERS
-- =============================================
local function getNearestBall()
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local rangeBonus = (player:GetAttribute("PickupBonus") or 0) * 5
	local nearest, nearestDist = nil, PICKUP_RANGE + rangeBonus
	for _, obj in workspace:GetChildren() do
		if obj.Name == "Ball" and obj:FindFirstChild("IsPickable") then
			local dist = (obj.Position - hrp.Position).Magnitude
			if dist < nearestDist then
				nearest = obj
				nearestDist = dist
			end
		end
	end
	return nearest
end

local function hideAim()
	for _, dot in trajDots do
		dot.CFrame = CFrame.new(0, -2000, 0)
	end
	aimDisc.CFrame = CFrame.new(0, -2000, 0)
	aimDiscCenter.CFrame = CFrame.new(0, -2000, 0)
	powerContainer.Visible = false
end

-- Two-phase arc: straight for PHASE1_FRAC of dots, then gravity drop.
-- td = throw def from THROW_DEFS; defaults to Normal if nil.
local function updateArc(startPos, horizVel, power, td)
	td = td or DEFAULT_THROW
	local g = workspace.Gravity
	local straightTime = td.straightBase + power * td.straightRange
	local dropVelY     = td.dropVelY
	local upward       = td.upwardDrift or 2

	-- Phase 1: nearly flat
	local p1DotStep = straightTime / PHASE1_COUNT
	local phase1EndPos = startPos
	for i = 1, PHASE1_COUNT do
		local t = i * p1DotStep
		local y = startPos.Y + upward * t - (upward / (straightTime * 0.5)) * t * t
		y = math.max(startPos.Y - 0.5, y)
		local pos = Vector3.new(
			startPos.X + horizVel.X * t,
			y,
			startPos.Z + horizVel.Z * t
		)
		if pos.Y >= 1 then
			trajDots[i].Position = pos
			phase1EndPos = pos
		else
			trajDots[i].CFrame = CFrame.new(0, -2000, 0)
		end
	end

	-- Phase 2: drop
	local p2DotStep = 0.13
	for j = 1, TRAJ_DOTS - PHASE1_COUNT do
		local t = j * p2DotStep
		local y = phase1EndPos.Y + dropVelY * t - 0.5 * g * t * t
		local idx = PHASE1_COUNT + j
		if y >= 1 then
			trajDots[idx].Position = Vector3.new(
				phase1EndPos.X + horizVel.X * t,
				y,
				phase1EndPos.Z + horizVel.Z * t
			)
		else
			trajDots[idx].CFrame = CFrame.new(0, -2000, 0)
		end
	end

	-- Landing disc
	local landPos = nil
	for step = 1, 500 do
		local t = step * 0.02
		local y = phase1EndPos.Y + dropVelY * t - 0.5 * g * t * t
		if y <= 1 then
			landPos = Vector3.new(
				phase1EndPos.X + horizVel.X * t,
				1.08,
				phase1EndPos.Z + horizVel.Z * t
			)
			break
		end
	end
	-- Disc color matches ball-type bar color
	local discColor = td.barColor or Color3.fromRGB(255, 80, 80)
	aimDisc.BrickColor   = BrickColor.new(discColor)
	local discCf = landPos
		and CFrame.new(landPos) * CFrame.Angles(0, 0, math.rad(90))
		or  CFrame.new(0, -2000, 0)
	aimDisc.CFrame       = discCf
	aimDiscCenter.CFrame = discCf
end

-- =============================================
-- INPUT
-- =============================================
local BALL_TYPE_HINTS = {
	Split      = { text = "SPLIT BALL  -  Hold to Charge",  color = Color3.fromRGB(255, 200, 60)  },
	Heavy      = { text = "HEAVY BALL  -  Hold to Charge",  color = Color3.fromRGB(200, 120, 255) },
	Speed      = { text = "SPEED BALL  -  Hold to Charge",  color = Color3.fromRGB(0,   220, 255) },
	SplitChild = { text = "SPLIT BALL  -  Hold to Charge",  color = Color3.fromRGB(255, 200, 60)  },
	DinoBlast  = { text = "DINO BLAST  -  Hold to Charge",  color = Color3.fromRGB(255,  60,  0)  },
}

local function applyBallHint(ball, charging)
	local ballType = ball and ball:GetAttribute("BallType")
	local info = ballType and BALL_TYPE_HINTS[ballType]
	if charging then
		local releaseHint = isConsole and "Release [R2] to Throw!" or isTouchDevice and "Release to Throw!" or "Release to Throw!"
		hintLabel.Text = releaseHint
		hintLabel.TextColor3 = Color3.new(1, 1, 1)
	elseif info then
		local suffix = isConsole and "  [X] Grab  [R2] Throw" or isTouchDevice and "  Tap to Grab & Throw" or "  Hold to Charge"
		hintLabel.Text = info.text:gsub("Hold to Charge", ""):gsub("  -  $", "") .. suffix
		hintLabel.TextColor3 = info.color
	else
		if isConsole then
			hintLabel.Text = "[X] Pick Up Ball"
		elseif isTouchDevice then
			hintLabel.Text = "Tap Ball to Pick Up"
		else
			hintLabel.Text = "Hold [Click] or [E] to Charge"
		end
		hintLabel.TextColor3 = Color3.new(1, 1, 1)
	end
end

local function tryPickup()
	if heldBall then return end
	local ball = getNearestBall()
	if ball then
		pickupEvent:FireServer(ball)
		heldBall = ball
		applyBallHint(ball, false)
		hintLabel.Visible = true
	end
end

local function doThrow()
	if not heldBall then return end
	local power = math.max(0.05, chargePower)
	throwEvent:FireServer(camera.CFrame.LookVector, power)
	heldBall = nil
	isCharging = false
	chargePower = 0
	chargeInput = nil
	powerLabel.Text = "POWER"   -- reset label
	hideAim()
	hintLabel.Visible = false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isCharging then return end
	local isE     = input.KeyCode == Enum.KeyCode.E
	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
	local isTouch = input.UserInputType == Enum.UserInputType.Touch
	-- Console: X (ButtonX) to pick up; R2 (ButtonR2) to charge/throw
	local isGamepadPickup = input.KeyCode == Enum.KeyCode.ButtonX
	local isGamepadCharge = input.KeyCode == Enum.KeyCode.ButtonR2

	if (isE or isTouch or isGamepadPickup) and not heldBall then
		tryPickup()
	elseif isGamepadPickup and heldBall and not isCharging then
		-- On gamepad: X also starts charge if already holding
		isCharging = true
		chargePower = 0
		chargeInput = input
		applyBallHint(heldBall, true)
	elseif (isE or isClick) and heldBall and not isCharging then
		isCharging = true
		chargePower = 0
		chargeInput = input
		applyBallHint(heldBall, true)
	elseif isGamepadCharge and heldBall and not isCharging then
		isCharging = true
		chargePower = 0
		chargeInput = input
		applyBallHint(heldBall, true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == chargeInput and isCharging then
		doThrow()
	end
end)

-- =============================================
-- FRAME LOOP
-- =============================================
RunService.Heartbeat:Connect(function(dt)
	if isCharging and heldBall then
		local td = getThrowDef()
		local ballType = heldBall:GetAttribute("BallType") or "Normal"
		powerLabel.Text = ballType:upper() .. " THROW"
		chargePower = math.min(1, chargePower + dt / td.chargeTime)

		-- Power bar — base color comes from ball type
		powerContainer.Visible = true
		barFill.Size = UDim2.new(chargePower, 0, 1, 0)
		-- Interpolate from ball-type color toward red as power increases
		local baseH, baseS, baseV = Color3.toHSV(td.barColor)
		local chargeH = baseH * (1 - chargePower * 0.85)   -- shift hue toward red
		barFill.BackgroundColor3 = Color3.fromHSV(chargeH, baseS, baseV)

		-- Full-power pulse
		if chargePower >= 1 then
			local pulse = 0.5 + 0.5 * math.sin(tick() * 10)
			barFill.BackgroundColor3 = Color3.fromRGB(255, math.floor(pulse * 60), 0)
		end

		-- Trajectory arc using per-ball profile
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local startPos = hrp.Position + Vector3.new(0, 3, 0)
			local speed = td.minSpeed + chargePower * (td.maxSpeed - td.minSpeed)
			local look = camera.CFrame.LookVector
			local horizLook = Vector3.new(look.X, 0, look.Z)
			if horizLook.Magnitude > 0.001 then horizLook = horizLook.Unit end
			updateArc(startPos, horizLook * speed, chargePower, td)
		end

		-- Throw button: pulse stroke to indicate charging
		if throwBtn then
			throwBtn.Visible = true
			local pulse = 0.5 + 0.5 * math.sin(tick() * 8)
			local throwBtnStrokeRef = throwBtn:FindFirstChildOfClass("UIStroke")
			if throwBtnStrokeRef then
				throwBtnStrokeRef.Color = Color3.fromRGB(255, math.floor(pulse * 120), math.floor(pulse * 220))
			end
			local lbl = throwBtn:FindFirstChild("ThrowBtnLabel")
			if lbl then lbl.Text = "RELEASE!" end
		end
	else
		hideAim()
		if not heldBall then
			local ball = getNearestBall()
			if ball then
				local ballType = ball:GetAttribute("BallType")
				local info = ballType and BALL_TYPE_HINTS[ballType]
				local prefix = isConsole and "[X] " or isTouchDevice and "" or "[E] "
				if info then
					hintLabel.Text = prefix .. (ballType == "SplitChild" and "SPLIT" or ballType:upper()) .. " BALL"
					hintLabel.TextColor3 = info.color
				else
					hintLabel.Text = isConsole and "[X] Pick Up" or isTouchDevice and "Tap to Pick Up" or "[E] Pick Up"
					hintLabel.TextColor3 = Color3.new(1, 1, 1)
				end
				hintLabel.Visible = true
				-- Show throw button as "pick up" prompt on touch
				if throwBtn then
					throwBtn.Visible = true
					local throwBtnStrokeRef = throwBtn:FindFirstChildOfClass("UIStroke")
					if throwBtnStrokeRef then
						throwBtnStrokeRef.Color = Color3.fromRGB(140, 80, 255)
					end
					local lbl = throwBtn:FindFirstChild("ThrowBtnLabel")
					if lbl then lbl.Text = "GRAB" end
				end
			else
				hintLabel.Visible = false
				if throwBtn then
					-- Show throw button only when holding a ball
					throwBtn.Visible = heldBall ~= nil
				end
			end
		else
			-- Holding ball but not charging: show throw button prompting to hold
			if throwBtn then
				throwBtn.Visible = true
				local throwBtnStrokeRef = throwBtn:FindFirstChildOfClass("UIStroke")
				if throwBtnStrokeRef then
					throwBtnStrokeRef.Color = Color3.fromRGB(140, 80, 255)
				end
				local lbl = throwBtn:FindFirstChild("ThrowBtnLabel")
				if lbl then lbl.Text = "THROW" end
			end
		end
	end
end)

-- =============================================
-- RESPAWN
-- =============================================
player.CharacterAdded:Connect(function()
	heldBall = nil
	isCharging = false
	chargePower = 0
	chargeInput = nil
	throwBtnInput = nil
	completionAirUntil = 0
	player:SetAttribute("SkyDescentBoundsActive", false)
	player:SetAttribute("CompletionAirLaunchActive", false)
	hideAim()
	hintLabel.Visible = false
	if throwBtn then throwBtn.Visible = false end
end)
