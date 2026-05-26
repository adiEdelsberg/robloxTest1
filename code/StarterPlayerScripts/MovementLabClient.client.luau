-- MovementLabClient.client.luau
-- Plays movement animations triggered by the Movement Lab pads.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Debris            = game:GetService("Debris")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer

local ANIM_IDS = {
	wave   = "rbxassetid://507770239",
	point  = "rbxassetid://507770453",
	cheer  = "rbxassetid://507770677",
	laugh  = "rbxassetid://507770818",
	dance  = "rbxassetid://507771019",
	dance2 = "rbxassetid://507776043",
	dance3 = "rbxassetid://507777268",
}

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
if not gameEvents then return end
local animEvent = gameEvents:WaitForChild("MovementLabAnim", 30)
if not animEvent then return end

local currentTrack = nil


-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Stop all animator tracks and disable Animate script so Motor6D tweens work
local function freezeAnims(char)
	local animScript = char:FindFirstChild("Animate")
	if animScript then animScript.Disabled = true end
	local hum      = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, t in animator:GetPlayingAnimationTracks() do
			t:Stop(0)
		end
	end
	return animScript
end

local function thawAnims(animScript)
	if animScript then animScript.Disabled = false end
end

-- Find a Motor6D by name anywhere in the character
local function findMotor(char, name)
	for _, v in char:GetDescendants() do
		if v:IsA("Motor6D") and v.Name == name then return v end
	end
end

local function tweenMotor(motor, target, t)
	TweenService:Create(motor, TweenInfo.new(t, Enum.EasingStyle.Sine), { C0 = target }):Play()
	task.wait(t)
end

-- ── SALUTE ────────────────────────────────────────────────────────────────────
local function doSalute()
	local char = player.Character
	if not char then return end
	-- R15: RightShoulder lives in RightUpperArm; R6: in Torso
	local motor = findMotor(char, "RightShoulder") or findMotor(char, "Right Shoulder")
	if not motor then return end

	local orig   = motor.C0
	local raised = orig * CFrame.Angles(-math.rad(115), 0, math.rad(20))
	local as     = freezeAnims(char)
	tweenMotor(motor, raised, 0.25)
	task.wait(1.5)
	tweenMotor(motor, orig, 0.25)
	thawAnims(as)
end

-- ── SHRUG ─────────────────────────────────────────────────────────────────────
local function doShrug()
	local char = player.Character
	if not char then return end
	local lMotor = findMotor(char, "LeftShoulder")  or findMotor(char, "Left Shoulder")
	local rMotor = findMotor(char, "RightShoulder") or findMotor(char, "Right Shoulder")
	if not lMotor or not rMotor then return end

	local lOrig = lMotor.C0
	local rOrig = rMotor.C0
	local lUp   = lOrig * CFrame.Angles(-math.rad(70), 0,  math.rad(35))
	local rUp   = rOrig * CFrame.Angles(-math.rad(70), 0, -math.rad(35))

	local as = freezeAnims(char)
	TweenService:Create(lMotor, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { C0 = lUp }):Play()
	TweenService:Create(rMotor, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { C0 = rUp }):Play()
	task.wait(1.0)
	TweenService:Create(lMotor, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { C0 = lOrig }):Play()
	TweenService:Create(rMotor, TweenInfo.new(0.2, Enum.EasingStyle.Sine), { C0 = rOrig }):Play()
	task.wait(0.2)
	thawAnims(as)
end

-- ── MARCH ─────────────────────────────────────────────────────────────────────
local marchRunning = false

local function doMarch()
	if marchRunning then marchRunning = false return end
	marchRunning = true

	local char = player.Character
	if not char then marchRunning = false return end

	local lLeg = findMotor(char, "LeftHip")  or findMotor(char, "Left Hip")
	local rLeg = findMotor(char, "RightHip") or findMotor(char, "Right Hip")
	if not lLeg or not rLeg then marchRunning = false return end

	local lOrig   = lLeg.C0
	local rOrig   = rLeg.C0
	local LIFT    = -math.rad(55)
	local STEP    = 0.25
	local deadline = tick() + 4
	local as      = freezeAnims(char)

	while marchRunning and tick() < deadline do
		-- lift left
		TweenService:Create(lLeg, TweenInfo.new(STEP, Enum.EasingStyle.Sine), { C0 = lOrig * CFrame.Angles(LIFT, 0, 0) }):Play()
		task.wait(STEP)
		TweenService:Create(lLeg, TweenInfo.new(STEP, Enum.EasingStyle.Sine), { C0 = lOrig }):Play()
		task.wait(STEP)
		if not marchRunning then break end
		-- lift right
		TweenService:Create(rLeg, TweenInfo.new(STEP, Enum.EasingStyle.Sine), { C0 = rOrig * CFrame.Angles(LIFT, 0, 0) }):Play()
		task.wait(STEP)
		TweenService:Create(rLeg, TweenInfo.new(STEP, Enum.EasingStyle.Sine), { C0 = rOrig }):Play()
		task.wait(STEP)
	end

	thawAnims(as)
	marchRunning = false
end

-- ── JUMP FLIP (180° X, hold while airborne, then upright) ────────────────────
local function doJumpSpin360()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Capture facing direction (yaw only) so flip is relative to where player looks
	local _, yaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
	local facingCF  = CFrame.Angles(0, yaw, 0)

	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bg.P         = 3e5
	bg.D         = 400
	bg.CFrame    = facingCF
	bg.Parent    = hrp

	local steps    = 16
	local interval = 0.03
	for i = 1, steps do
		task.wait(interval)
		if not hrp.Parent then bg:Destroy() return end
		bg.CFrame = facingCF * CFrame.Angles((i / steps) * math.pi * 2, 0, 0)
	end

	bg:Destroy()
end

-- ── SPIN X / Y ───────────────────────────────────────────────────────────────
local function doSpinAxis(axis)  -- axis: "x" or "y"
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local steps = 30
	for i = 1, steps do
		task.wait(0.05)
		if not hrp.Parent then return end
		local angle = (i / steps) * math.pi * 2
		-- Use current position each frame so physics (e.g. jump arc) still moves the character
		if axis == "x" then
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(angle, 0, 0)
		else
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, angle, 0)
		end
	end
	if hrp.Parent then
		hrp.CFrame = CFrame.new(hrp.Position)
	end
end

-- ── SPIN (all axes) ───────────────────────────────────────────────────────────
local function doSpin()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Sequence of spins: { axisX, axisY, axisZ, steps, stepInterval }
	local sequence = {
		{ 0,            math.rad(15), 0,            24, 0.04 },  -- Y spin (360°)
		{ math.rad(15), 0,            0,            24, 0.04 },  -- X spin (360°)
		{ 0,            0,            math.rad(15), 24, 0.04 },  -- Z spin (360°)
		{ math.rad(8),  math.rad(8),  math.rad(8),  36, 0.04 },  -- all axes combined
	}

	for _, seg in ipairs(sequence) do
		local rx, ry, rz, steps, interval = seg[1], seg[2], seg[3], seg[4], seg[5]
		for i = 1, steps do
			task.wait(interval)
			if not hrp.Parent then return end
			hrp.CFrame = hrp.CFrame * CFrame.Angles(rx, ry, rz)
		end
		task.wait(0.1)
	end

	-- Snap upright at the end
	if hrp.Parent then
		local pos = hrp.Position
		hrp.CFrame = CFrame.new(pos)
	end
end

-- ── Event handler ─────────────────────────────────────────────────────────────
-- ── DOUBLE FLIP (Z key, high launch + 720° X) ────────────────────────────────
local function doDoubleFlip(direction)  -- direction: 1 = forward, -1 = back
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Launch high
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(0, 160, 0)
	bv.MaxForce = Vector3.new(0, math.huge, 0)
	bv.P        = math.huge
	bv.Parent   = hrp
	Debris:AddItem(bv, 0.25)

	-- Capture facing direction before launch
	local _, yaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
	local facingCF  = CFrame.Angles(0, yaw, 0)

	-- BodyGyro handles rotation only — movement still works
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bg.P         = 3e5
	bg.D         = 400
	bg.CFrame    = facingCF
	bg.Parent    = hrp

	task.wait(0.2)  -- let the launch kick in

	-- Double flip: 720°
	local steps    = 28
	local interval = 0.04
	for i = 1, steps do
		task.wait(interval)
		if not hrp.Parent then bg:Destroy() return end
		bg.CFrame = facingCF * CFrame.Angles((i / steps) * math.pi * 4 * direction, 0, 0)
	end

	bg:Destroy()
end

-- Spin wheel world bounds (WX=78, WZ=-735, generous radius)
local function isAtSpinWheelWorld(char)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local p = hrp.Position
	return math.abs(p.X - 78) <= 150 and math.abs(p.Z - (-735)) <= 150
end

-- Hook jump flip for current and future characters
local function hookJumpFlip(char)
	local hum = char:WaitForChild("Humanoid")
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping and isAtSpinWheelWorld(char) then
			task.spawn(doJumpSpin360)
		end
	end)
end

player.CharacterAdded:Connect(hookJumpFlip)
if player.Character then hookJumpFlip(player.Character) end

-- C key hover: launch up, tilt to face-down, WASD moves in air
local hoverBody = nil
local hoverGyro = nil
local hoverConn = nil

local HOVER_HEIGHT = 45
local HOVER_SPEED  = 28

local function toggleHover()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if hoverBody then
		hoverBody:Destroy()    hoverBody = nil
		hoverGyro:Destroy()    hoverGyro = nil
		hoverConn:Disconnect() hoverConn = nil
		return
	end

	local _, yaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
	local facingCF  = CFrame.Angles(0, yaw, 0)

	-- Lock Y at hover height; X/Z driven by loop below
	local bp = Instance.new("BodyPosition")
	bp.Position = Vector3.new(hrp.Position.X, hrp.Position.Y + HOVER_HEIGHT, hrp.Position.Z)
	bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bp.P        = 8e4
	bp.D        = 800
	bp.Parent   = hrp
	hoverBody   = bp

	-- Gyro: smoothly tilts from 0 to -90° then holds face-down
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bg.P         = 3e5
	bg.D         = 400
	bg.CFrame    = facingCF
	bg.Parent    = hrp
	hoverGyro    = bg

	-- Flip into face-down: fast start, eases to a stop at -90°
	task.spawn(function()
		local steps = 20
		for i = 1, steps do
			task.wait(0.025)
			if not hoverGyro or not hoverGyro.Parent then return end
			-- ease-out: fast at start, slow near end
			local t = i / steps
			local eased = 1 - (1 - t) ^ 3
			bg.CFrame = facingCF * CFrame.Angles(-eased * math.pi / 2, 0, 0)
		end
	end)

	-- WASD: move bp target relative to camera while hovering
	local cam = workspace.CurrentCamera
	hoverConn = RunService.Heartbeat:Connect(function(dt)
		if not hoverBody or not hrp.Parent then return end
		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0,  1) end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new( 1, 0, 0) end
		if move.Magnitude > 0 then
			local flat  = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
			local camCF = CFrame.new(Vector3.zero, flat)
			local world = camCF:VectorToWorldSpace(move.Unit) * HOVER_SPEED * dt
			bp.Position = bp.Position + Vector3.new(world.X, 0, world.Z)
		end
	end)
end

-- Clear hover on respawn
player.CharacterAdded:Connect(function()
	if hoverConn then hoverConn:Disconnect() hoverConn = nil end
	hoverBody = nil
	hoverGyro = nil
end)

-- Z = forward double flip, X = back double flip, C = hover toggle (spin wheel world only)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not isAtSpinWheelWorld(player.Character) then return end
	if input.KeyCode == Enum.KeyCode.Z then
		task.spawn(doDoubleFlip, 1)
	elseif input.KeyCode == Enum.KeyCode.X then
		task.spawn(doDoubleFlip, -1)
	elseif input.KeyCode == Enum.KeyCode.C then
		toggleHover()
	end
end)

-- ── FIGHT ARENA JUMP = DOUBLE FLIP  (World 42) ───────────────────────────────
local function isInFightArena(char)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local p = hrp.Position
	return math.abs(p.X - (-2860)) <= 115 and math.abs(p.Z - 8100) <= 115
end

local arenaFlipCooldown = false

UserInputService.JumpRequest:Connect(function()
	local char = player.Character
	if not isInFightArena(char) then return end
	if arenaFlipCooldown then return end
	arenaFlipCooldown = true
	task.spawn(doDoubleFlip, -1)
	task.delay(2, function() arenaFlipCooldown = false end)
end)

animEvent.OnClientEvent:Connect(function(action)
	if action == "march"     then task.spawn(doMarch)    return end
	if action == "spin"      then task.spawn(doSpin)     return end
	if action == "spinx"     then task.spawn(function() doSpinAxis("x") end) return end
	if action == "spiny"     then task.spawn(function() doSpinAxis("y") end) return end
	if action == "salute"    then task.spawn(doSalute)   return end
	if action == "shrug"     then task.spawn(doShrug)    return end
	if action == "jumpflip"  then task.spawn(doJumpSpin360) return end

	local char = player.Character
	if not char then return end
	local hum      = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then return end

	local id = ANIM_IDS[action]
	if not id then return end

	if currentTrack and currentTrack.IsPlaying then currentTrack:Stop(0.2) end

	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.15)
	currentTrack = track

	task.delay(5, function()
		if track.IsPlaying then track:Stop(0.3) end
	end)
end)
