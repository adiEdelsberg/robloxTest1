local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isConsole     = UserInputService.GamepadEnabled and not UserInputService.MouseEnabled

local events    = ReplicatedStorage:WaitForChild("SpinWheelEvents")
local spinResult = events:WaitForChild("SpinResult")

local function showPopup(prize, message)
	local existing = playerGui:FindFirstChild("SpinResultGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name           = "SpinResultGui"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent         = playerGui

	local accentColor = prize and BrickColor.new(prize.color).Color
		or Color3.fromRGB(220, 60, 60)

	local frame = Instance.new("Frame")
	frame.AnchorPoint      = Vector2.new(0.5, 0.5)
	frame.Size             = UDim2.new(0, 0, 0, 0)   -- animates in
	frame.Position         = UDim2.new(0.5, 0, 0.35, 0)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	frame.BorderSizePixel  = 0
	frame.Parent           = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent       = frame

	-- Accent strip at top
	local strip = Instance.new("Frame")
	strip.Size            = UDim2.new(1, 0, 0, 8)
	strip.BackgroundColor3 = accentColor
	strip.BorderSizePixel = 0
	strip.ZIndex          = 2
	strip.Parent          = frame
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 16)
	sc.Parent       = strip

	local function label(text, size, pos, color, font, zindex)
		local lbl = Instance.new("TextLabel")
		lbl.Size                   = size
		lbl.Position               = pos
		lbl.BackgroundTransparency = 1
		lbl.Text                   = text
		lbl.TextColor3             = color or Color3.new(1, 1, 1)
		lbl.Font                   = font or Enum.Font.GothamBold
		lbl.TextScaled             = true
		lbl.TextStrokeTransparency = 0
		lbl.ZIndex                 = zindex or 3
		lbl.Parent                 = frame
		return lbl
	end

	if prize then
		label("YOU WON!",
			UDim2.new(1, -20, 0, 36),
			UDim2.new(0, 10, 0, 18),
			Color3.new(1, 1, 1))

		local iconBack = Instance.new("Frame")
		iconBack.Size = UDim2.new(0, 58, 0, 50)
		iconBack.Position = UDim2.new(0.5, -29, 0, 55)
		iconBack.BackgroundColor3 = prize.iconColor or accentColor
		iconBack.BorderSizePixel = 0
		iconBack.ZIndex = 4
		iconBack.Parent = frame
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 11)
		iconCorner.Parent = iconBack

		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = Color3.new(1, 1, 1)
		iconStroke.Thickness = 2
		iconStroke.Transparency = 0.45
		iconStroke.Parent = iconBack

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(1, -6, 1, -6)
		iconLabel.Position = UDim2.new(0, 3, 0, 3)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.GothamBlack
		iconLabel.TextScaled = true
		iconLabel.TextColor3 = Color3.fromRGB(10, 10, 12)
		iconLabel.TextStrokeTransparency = 1
		iconLabel.Text = prize.icon or "WIN"
		iconLabel.ZIndex = 5
		iconLabel.Parent = iconBack

		local prizeLbl = label(prize.name,
			UDim2.new(1, -20, 0, 52),
			UDim2.new(0, 10, 0, 104),
			accentColor)
		prizeLbl.TextStrokeTransparency = 0.5

		label(message,
			UDim2.new(1, -20, 0, 28),
			UDim2.new(0, 10, 0, 155),
			Color3.fromRGB(200, 200, 200),
			Enum.Font.Gotham)

		label("Closing in 4 seconds...",
			UDim2.new(1, -20, 0, 20),
			UDim2.new(0, 10, 0, 192),
			Color3.fromRGB(120, 120, 120),
			Enum.Font.Gotham)

		frame.Size = UDim2.new(0, 380, 0, 224)
	else
		-- Cooldown / error message
		label("SPIN WHEEL",
			UDim2.new(1, -20, 0, 32),
			UDim2.new(0, 10, 0, 18),
			Color3.fromRGB(220, 180, 60))

		label(message or "Try again later!",
			UDim2.new(1, -20, 0, 36),
			UDim2.new(0, 10, 0, 60),
			Color3.fromRGB(220, 100, 100))

		frame.Size = UDim2.new(0, 340, 0, 120)
	end

	-- Animate in (pop from center)
	local targetSize = frame.Size
	frame.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(frame,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = targetSize }
	):Play()

	local closeDelay = prize and 4.5 or 3.0
	task.delay(closeDelay, function()
		if not gui or not gui.Parent then return end
		TweenService:Create(frame,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Size = UDim2.new(0, 0, 0, 0) }
		):Play()
		task.delay(0.3, function()
			gui:Destroy()
		end)
	end)
end

spinResult.OnClientEvent:Connect(showPopup)

-- =============================================
-- SKATEBOARD HUD ICON  (under shop button)
-- =============================================
local skateGui = Instance.new("ScreenGui")
skateGui.Name          = "SkateHUD"
skateGui.ResetOnSpawn  = false
skateGui.IgnoreGuiInset = true
skateGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
skateGui.DisplayOrder  = 40
skateGui.Parent        = playerGui

local isTouchDevice = UserInputService.TouchEnabled

local function connectButtonPress(button, callback)
	local lastPress = 0
	local function fire()
		local now = os.clock()
		if now - lastPress < 0.28 then return end
		lastPress = now
		callback()
	end

	button.Activated:Connect(fire)
	button.MouseButton1Click:Connect(fire)
	button.TouchTap:Connect(fire)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			fire()
		end
	end)
end

local skateBtn = Instance.new("TextButton")
skateBtn.AnchorPoint          = Vector2.new(0, 0)
skateBtn.Size                 = isTouchDevice and UDim2.new(0, 68, 0, 48) or UDim2.new(0, 62, 0, 36)
skateBtn.Position             = UDim2.new(0, 130, 0, 62)   -- top-left, right of shop btn with gap
skateBtn.BackgroundColor3     = Color3.fromRGB(18, 18, 18)
skateBtn.BackgroundTransparency = 0.18
skateBtn.BorderSizePixel      = 0
skateBtn.Text                 = ""
skateBtn.Visible              = false
skateBtn.Active               = true
skateBtn.AutoButtonColor      = true
skateBtn.Selectable           = true
skateBtn.ZIndex               = 10
skateBtn.Parent               = skateGui
Instance.new("UICorner", skateBtn).CornerRadius = UDim.new(0, 18)

local skateStroke = Instance.new("UIStroke")
skateStroke.Color       = Color3.fromRGB(255, 150, 45)
skateStroke.Thickness   = 2.5
skateStroke.Transparency = 0.15
skateStroke.Parent      = skateBtn

-- Board emoji
local skateEmoji = Instance.new("TextLabel")
skateEmoji.Size                  = UDim2.new(1, 0, 0, 46)
skateEmoji.Position              = UDim2.new(0, 0, 0, 6)
skateEmoji.BackgroundTransparency = 1
skateEmoji.Text                  = "🛹"
skateEmoji.TextScaled            = true
skateEmoji.Font                  = Enum.Font.GothamBold
skateEmoji.TextColor3            = Color3.new(1, 1, 1)
skateEmoji.ZIndex                = 11
skateEmoji.Parent                = skateBtn
skateEmoji.Text                  = "SK8"
skateEmoji.Size                  = UDim2.new(1, 0, 1, 0)
skateEmoji.Position              = UDim2.new(0, 0, 0, 0)

-- Arrow label: ▼ when mounted (tap to dismount), ▲ when dismounted (tap to mount)
local skateArrow = Instance.new("TextLabel")
skateArrow.Size                  = UDim2.new(0, 0, 0, 0)  -- hidden; state shown by timer label
skateArrow.Position              = UDim2.new(0, 0, 1, 0)
skateArrow.BackgroundTransparency = 1
skateArrow.Text                  = "▼"
skateArrow.TextScaled            = true
skateArrow.Font                  = Enum.Font.GothamBold
skateArrow.TextColor3            = Color3.fromRGB(255, 150, 45)
skateArrow.ZIndex                = 11
skateArrow.Parent                = skateBtn
skateArrow.Text                  = "DOWN"

local skateTimer = Instance.new("TextLabel")
skateTimer.Size                   = UDim2.new(0, 62, 0, 28)
skateTimer.Position               = UDim2.new(0, 130, 0, 106)  -- below skate btn
skateTimer.BackgroundColor3       = Color3.fromRGB(18, 18, 18)
skateTimer.BackgroundTransparency = 0.18
skateTimer.BorderSizePixel        = 0
skateTimer.Font                   = Enum.Font.GothamBold
skateTimer.TextSize               = 15
skateTimer.TextColor3             = Color3.fromRGB(255, 225, 90)
skateTimer.TextStrokeTransparency = 0.7
skateTimer.Text                   = "3:00"
skateTimer.Visible                = false
skateTimer.ZIndex                 = 10
skateTimer.Parent                 = skateGui
Instance.new("UICorner", skateTimer).CornerRadius = UDim.new(0, 8)

local skateTimerStroke = Instance.new("UIStroke")
skateTimerStroke.Color = Color3.fromRGB(255, 150, 45)
skateTimerStroke.Thickness = 2
skateTimerStroke.Transparency = 0.2
skateTimerStroke.Parent = skateTimer

local isMounted = true

local function updateSkateIcon(mounted)
	isMounted = mounted
	if mounted then
		skateArrow.Text   = "▼"
		skateStroke.Color = Color3.fromRGB(255, 150, 45)
		skateBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	else
		skateArrow.Text   = "▲"
		skateStroke.Color = Color3.fromRGB(120, 120, 120)
		skateBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	end
end

local originalUpdateSkateIcon = updateSkateIcon
updateSkateIcon = function(mounted)
	originalUpdateSkateIcon(mounted)
	skateArrow.Text = mounted and "DOWN" or "UP"
end

local skateToggle = events:WaitForChild("SkateboardToggle")
local skateStateEvt = events:WaitForChild("SkateboardState")

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds or 0))
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", minutes, secs)
end

local function refreshSkateHud()
	local hasSkateboard = player:GetAttribute("HasSkateboard") == true
	skateBtn.Visible = hasSkateboard
	skateTimer.Visible = hasSkateboard
	skateTimer.Text = formatTime(player:GetAttribute("SkateboardTimeRemaining") or 0)
end

local lastSkateToggle = 0
local function requestSkateToggle()
	local now = os.clock()
	if now - lastSkateToggle < 0.35 then return end
	lastSkateToggle = now
	skateToggle:FireServer()
end
connectButtonPress(skateBtn, requestSkateToggle)

-- Console: L1 toggles skateboard
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.ButtonL1 then
		local hasSkateboard = player:GetAttribute("HasSkateboard") == true
		if hasSkateboard then requestSkateToggle() end
	end
end)

-- Show icon whenever player gains the skateboard attribute
local function checkSkateAttribute()
	refreshSkateHud()
end
player:GetAttributeChangedSignal("HasSkateboard"):Connect(checkSkateAttribute)
player:GetAttributeChangedSignal("SkateboardTimeRemaining"):Connect(refreshSkateHud)
checkSkateAttribute()

-- Leg animation freeze/unfreeze while skateboard is mounted
local skateEquipped = events:WaitForChild("SkateboardEquipped")

local animFreezeConn = nil  -- holds the AnimationPlayed connection so we can disconnect on dismount

local function freezeLegs()
	-- Disconnect any previous freeze connection first
	if animFreezeConn then
		animFreezeConn:Disconnect()
		animFreezeConn = nil
	end

	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then return end

	-- Stop any already-playing walk/run tracks
	for _, track in animator:GetPlayingAnimationTracks() do
		local n = track.Name:lower()
		if n:find("walk") or n:find("run") then
			track:Stop(0)
		end
	end

	-- Stop future walk/run tracks the moment they play, and keep the connection
	animFreezeConn = animator.AnimationPlayed:Connect(function(track)
		local n = track.Name:lower()
		if n:find("walk") or n:find("run") then
			track:Stop(0)
		end
	end)
end

local function unfreezeLegs()
	if animFreezeConn then
		animFreezeConn:Disconnect()
		animFreezeConn = nil
	end
end

skateEquipped.OnClientEvent:Connect(function()
	task.defer(freezeLegs)
end)

skateStateEvt.OnClientEvent:Connect(function(mounted)
	updateSkateIcon(mounted)
	if mounted then
		task.defer(freezeLegs)
	else
		unfreezeLegs()
	end
end)
