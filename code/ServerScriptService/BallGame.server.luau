local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local CashService       = require(script.Parent:WaitForChild("CashService"))

local MONEY_PER_HIT = Balance.Ball.MoneyPerPlayerHit

local eventsFolder = ReplicatedStorage:FindFirstChild("BallEvents")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "BallEvents"
	eventsFolder.Parent = ReplicatedStorage
end

local function getRemoteEvent(name)
	local event = eventsFolder:FindFirstChild(name)
	if event and not event:IsA("RemoteEvent") then
		event:Destroy()
		event = nil
	end
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = eventsFolder
	end
	return event
end

local pickupEvent = getRemoteEvent("PickupBall")
local throwEvent = getRemoteEvent("ThrowBall")

local heldBalls              = {}
local activeThrowConnections = {}
local activeThrowCleanupConnections = {}
local showMoneyPopup
local PLAYGROUND_BALL_MIN_COUNT = 10
local PLAYGROUND_BALL_BOUNDS = { minX = -56, maxX = 56, minZ = -56, maxZ = 56 }
local VALID_TARGET_HIT_SECONDS = 8
local PLAYGROUND_REFILL_POSITIONS = {
	-- Spread around the carnival layout
	{ pos = Vector3.new(-20, 3, -40), type = "Normal" },  -- near big tent
	{ pos = Vector3.new( 20, 3, -40), type = "Normal" },  -- near ferris wheel
	{ pos = Vector3.new(-48, 3, -10), type = "Normal" },  -- west side
	{ pos = Vector3.new( 48, 3, -10), type = "Normal" },  -- east game stalls
	{ pos = Vector3.new(  0, 3,  20), type = "Normal" },  -- carousel area
	{ pos = Vector3.new(-35, 3,  40), type = "Normal" },  -- bounce castle area
	{ pos = Vector3.new( 35, 3,  40), type = "Normal" },  -- food stands area
	{ pos = Vector3.new(-50, 3,  25), type = "Normal" },  -- far west
	{ pos = Vector3.new( 50, 3, -40), type = "Normal" },  -- far north-east
	{ pos = Vector3.new(  0, 3, -50), type = "Normal" },  -- south entrance
}

-- =============================================
-- BALL TYPE DEFINITIONS
-- =============================================
local BALL_DEFS = {
	Normal = {
		size      = 2,
		mat       = Enum.Material.SmoothPlastic,
		colors    = {
			BrickColor.new("Bright red"),    BrickColor.new("Bright blue"),
			BrickColor.new("Bright green"),  BrickColor.new("Bright yellow"),
			BrickColor.new("Bright orange"), BrickColor.new("Hot pink"),
		},
		label      = "[E] Pick Up",
		labelColor = Color3.new(1, 1, 1),
		damage     = 1,
		phys       = PhysicalProperties.new(0.5, 0.3, 0.7, 0, 0),
		-- Balanced: medium arc, medium speed
		throw = { minSpeed=30, maxSpeed=152, straightBase=0.38, straightRange=0.22, dropVelY=-32, spin=18, trailLife=0.28, upwardDrift=1 },
	},
	Split = {
		size      = 2.4,
		mat       = Enum.Material.Neon,
		colors    = {
			BrickColor.new("Bright orange"),
			BrickColor.new("Dark orange"),
			BrickColor.new("Bright yellow"),
		},
		label      = "SPLIT [E]",
		labelColor = Color3.fromRGB(255, 200, 60),
		damage     = 2,
		splits     = true,
		phys       = PhysicalProperties.new(0.5, 0.3, 0.7, 0, 0),
		-- Short arc, drops fast, tumbles — split drama happens on impact
		throw = { minSpeed=32, maxSpeed=140, straightBase=0.22, straightRange=0.16, dropVelY=-42, spin=32, trailLife=0.20, upwardDrift=0.5 },
	},
	Heavy = {
		size      = 3.0,
		mat       = Enum.Material.SmoothPlastic,
		colors    = {
			BrickColor.new("Dark indigo"),
			BrickColor.new("Bright violet"),
			BrickColor.new("Hot pink"),
		},
		label      = "HEAVY [E]",
		labelColor = Color3.fromRGB(180, 100, 255),
		damage     = 2,
		phys       = PhysicalProperties.new(1.5, 0.2, 0.3, 0, 0),
		-- Slow wind-up, dead flat for a long time, then CRASHES down hard
		throw = { minSpeed=18, maxSpeed=108, straightBase=0.60, straightRange=0.30, dropVelY=-70, spin=7, trailLife=0.12, upwardDrift=0.2, chargeTimeMult=1.4 },
	},
	Speed = {
		size      = 1.4,
		mat       = Enum.Material.Neon,
		colors    = {
			BrickColor.new("Cyan"),
			BrickColor.new("Bright blue"),
			BrickColor.new("White"),
		},
		label      = "SPEED [E]",
		labelColor = Color3.fromRGB(0, 220, 255),
		damage     = 1,
		phys       = PhysicalProperties.new(0.1, 0.3, 0.8, 0, 0),
		-- Rocket: charges fast, blasts in a near-flat line, barely drops
		throw = { minSpeed=58, maxSpeed=248, straightBase=0.72, straightRange=0.34, dropVelY=-18, spin=50, trailLife=0.55, upwardDrift=0.4, chargeTimeMult=0.65 },
	},
	SplitChild = {
		size      = 1.5,
		mat       = Enum.Material.Neon,
		colors    = { BrickColor.new("Bright yellow"), BrickColor.new("Bright orange") },
		label      = "SPLIT CHILD",
		labelColor = Color3.fromRGB(255, 200, 60),
		damage     = 2,
		phys       = PhysicalProperties.new(0.5, 0.3, 0.7, 0, 0),
		-- Fast mini-ball, drops quickly, wild spin
		throw = { minSpeed=72, maxSpeed=92, straightBase=0.18, straightRange=0.08, dropVelY=-40, spin=40, trailLife=0.18, upwardDrift=0.6 },
	},
	Fireball = {
		size      = 4.5,
		mat       = Enum.Material.Neon,
		colors    = {
			BrickColor.new("Bright orange"),
			BrickColor.new("Really red"),
			BrickColor.new("New Yeller"),
		},
		label      = "🔥 FIREBALL [E]",
		labelColor = Color3.fromRGB(255, 140, 20),
		damage     = 3,
		phys       = PhysicalProperties.new(0.6, 0.2, 0.5, 0, 0),
		throw = { minSpeed=120, maxSpeed=280, straightBase=0.72, straightRange=0.20, dropVelY=-14, spin=8, trailLife=0.55, upwardDrift=1.8 },
	},
	-- Exclusive to the big dino sky arenas (EmptyWorld1 / Storm Dome)
	DinoBlast = {
		size      = 7,
		mat       = Enum.Material.Neon,
		colors    = {
			BrickColor.new("Really red"),
			BrickColor.new("Bright orange"),
			BrickColor.new("Deep orange"),
		},
		label      = "💥 DINO BLAST [E]",
		labelColor = Color3.fromRGB(255, 60, 0),
		damage     = 3,
		phys       = PhysicalProperties.new(0.7, 0.1, 0.4, 0, 0),
		throw = { minSpeed=150, maxSpeed=340, straightBase=0.82, straightRange=0.16, dropVelY=-10, spin=5, trailLife=0.70, upwardDrift=2.2 },
	},
}

-- =============================================
-- SPAWN POSITIONS WITH TYPE ASSIGNMENTS
-- =============================================
-- Starting balls removed; all ball access is via dispenser machines.
local spawnData = {}


-- =============================================
-- HELPERS
-- =============================================
local function createBall(position, ballType)
	local def   = BALL_DEFS[ballType] or BALL_DEFS.Normal
	local color = def.colors[math.random(1, #def.colors)]

	local ball = Instance.new("Part")
	ball.Name     = "Ball"
	ball.Shape    = Enum.PartType.Ball
	ball.Size     = Vector3.new(def.size, def.size, def.size)
	ball.Position = position
	ball.BrickColor = color
	ball.Material = def.mat
	ball.CustomPhysicalProperties = def.phys
	ball:SetAttribute("BallType", ballType)
	ball:SetAttribute("IsThrown", false)
	ball:SetAttribute("ThrowTime", nil)
	ball.Parent   = workspace

	local tag    = Instance.new("BoolValue")
	tag.Name     = "IsPickable"
	tag.Parent   = ball

	local bb      = Instance.new("BillboardGui")
	bb.Name       = "PickupHint"
	bb.Size       = UDim2.new(0, 130, 0, 34)
	bb.StudsOffset = Vector3.new(0, def.size + 0.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent     = ball

	local lbl     = Instance.new("TextLabel")
	lbl.Size      = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text      = def.label
	lbl.TextColor3 = def.labelColor
	lbl.TextStrokeTransparency = 0
	lbl.Font      = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.Parent    = bb

	return ball
end

local function markBallThrown(ball)
	if not ball or not ball:IsA("BasePart") then return end
	ball:SetAttribute("IsThrown", true)
	ball:SetAttribute("ThrowTime", os.clock())
end

local function clearThrownState(ball)
	if not ball or not ball:IsA("BasePart") then return end
	ball:SetAttribute("IsThrown", false)
	ball:SetAttribute("ThrowTime", nil)
end

local function clearThrowConnection(ball)
	local conn = activeThrowConnections[ball]
	if conn then
		conn:Disconnect()
		activeThrowConnections[ball] = nil
	end
	local cleanupConn = activeThrowCleanupConnections[ball]
	if cleanupConn then
		cleanupConn:Disconnect()
		activeThrowCleanupConnections[ball] = nil
	end
end

local function connectPlayerHitPayout(ball, player)
	clearThrowConnection(ball)
	local hitCooldown = {}
	activeThrowCleanupConnections[ball] = ball.Destroying:Connect(function()
		heldBalls[ball] = nil
		clearThrowConnection(ball)
	end)
	activeThrowConnections[ball] = ball.Touched:Connect(function(hit)
		local victimChar = hit.Parent
		if not victimChar then return end
		local victimPlayer = Players:GetPlayerFromCharacter(victimChar)
		if not victimPlayer then return end
		if victimPlayer == player then return end
		if hitCooldown[victimPlayer] then return end
		hitCooldown[victimPlayer] = true

		local thrower = Players:FindFirstChild(player.Name)
		if not thrower then return end
		local cash = CashService.getCash(thrower)
		if not cash then return end

		cash.Value += MONEY_PER_HIT
		showMoneyPopup(victimChar, MONEY_PER_HIT)
	end)
end

local function makeSpreadBall(sourceBall, velocity, offset)
	local ball = sourceBall:Clone()
	ball:ClearAllChildren()
	ball.Name = "Ball"
	ball.CFrame = sourceBall.CFrame * CFrame.new(offset, 0, 0)
	ball.CanCollide = true
	ball:SetAttribute("ThrowerName", sourceBall:GetAttribute("ThrowerName"))
	ball:SetAttribute("Damage", sourceBall:GetAttribute("Damage") or 1)
	markBallThrown(ball)
	ball.Parent = workspace
	ball.AssemblyLinearVelocity = velocity
	task.delay(8, function()
		clearThrowConnection(ball)
		if ball.Parent then ball:Destroy() end
	end)
	return ball
end

-- Split mechanic: ball hits something → destroyed → 2 child balls fly perpendicular
local function setupSplitOnHit(ball, player)
	local splitDone = false
	local conn
	conn = ball.Touched:Connect(function(hit)
		if splitDone then return end
		if player.Character and hit:IsDescendantOf(player.Character) then return end
		if hit.Name == "Ball" then return end
		if ball.AssemblyLinearVelocity.Magnitude < 8 then return end

		splitDone = true
		conn:Disconnect()

		local vel = ball.AssemblyLinearVelocity
		local dir = vel.Magnitude > 0.01 and vel.Unit or Vector3.new(0, -1, 0)

		local side = dir:Cross(Vector3.new(0, 1, 0))
		if side.Magnitude < 0.01 then side = dir:Cross(Vector3.new(1, 0, 0)) end
		side = side.Unit

		local childSpeed   = math.max(70, vel.Magnitude * 0.95)
		local spread       = 0.35
		local throwerName  = ball:GetAttribute("ThrowerName")
		local dmg          = math.max(ball:GetAttribute("Damage") or 1, 2)
		local spawnCf      = ball.CFrame

		-- Destroy original ball next frame
		task.defer(function()
			clearThrowConnection(ball)
			if ball.Parent then ball:Destroy() end
		end)

		local function makeChild(sideDir, color)
			local child = Instance.new("Part")
			child.Name     = "Ball"
			child.Shape    = Enum.PartType.Ball
			child.Size     = Vector3.new(1.5, 1.5, 1.5)
			child.BrickColor = BrickColor.new(color)
			child.Material = Enum.Material.Neon
			child.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.3, 0.7, 0, 0)
			child.CFrame   = spawnCf + sideDir * 1.9 + dir * 1.4
			child:SetAttribute("ThrowerName", throwerName)
			child:SetAttribute("Damage", dmg)
			child:SetAttribute("BallType", "SplitChild")
			markBallThrown(child)
			child.CanCollide = true
			child.Parent   = workspace
			child.AssemblyLinearVelocity = (dir + sideDir * spread + Vector3.new(0, 0.18, 0)).Unit * childSpeed
			child.AssemblyAngularVelocity = sideDir * 18
			connectPlayerHitPayout(child, player)
			task.delay(5, function()
				clearThrowConnection(child)
				if child.Parent then child:Destroy() end
			end)
		end

		makeChild( side, "Bright yellow")
		makeChild(-side, "Bright orange")
	end)
end

-- =============================================
-- SPAWN INITIAL BALLS
-- =============================================
for _, sd in spawnData do
	createBall(sd.pos, sd.type)
end

task.spawn(function()
	local refillIndex = 1
	while true do
		task.wait(5)
		local count = 0
		for _, obj in workspace:GetChildren() do
			if obj.Name ~= "Ball" or not obj:IsA("BasePart") or not obj:FindFirstChild("IsPickable") then
				continue
			end
			local pos = obj.Position
			if pos.X >= PLAYGROUND_BALL_BOUNDS.minX and pos.X <= PLAYGROUND_BALL_BOUNDS.maxX
				and pos.Z >= PLAYGROUND_BALL_BOUNDS.minZ and pos.Z <= PLAYGROUND_BALL_BOUNDS.maxZ
				and pos.Y > -20 then
				count += 1
			end
		end

		while count < PLAYGROUND_BALL_MIN_COUNT do
			local data = PLAYGROUND_REFILL_POSITIONS[refillIndex]
			refillIndex = (refillIndex % #PLAYGROUND_REFILL_POSITIONS) + 1
			createBall(data.pos, data.type)
			count += 1
		end
	end
end)

-- =============================================
-- PICKUP
-- =============================================
pickupEvent.OnServerEvent:Connect(function(player, ball)
	if not ball or not ball:IsA("BasePart") then return end
	if not ball:FindFirstChild("IsPickable") then return end
	if heldBalls[ball] then return end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local rangeBonus = (player:GetAttribute("PickupBonus") or 0) * 5
	if (ball.Position - hrp.Position).Magnitude > 12 + rangeBonus then return end

	local hint = ball:FindFirstChild("PickupHint")
	if hint then hint.Enabled = false end
	clearThrowConnection(ball)
	ball:SetAttribute("ThrowerName", nil)
	clearThrownState(ball)

	-- Position ball above the player's hands (slightly in front and elevated)
	ball.CFrame    = hrp.CFrame * CFrame.new(0, 3, -2.5)
	ball.CanCollide = false
	heldBalls[ball] = player

	local weld    = Instance.new("WeldConstraint")
	weld.Name     = "BallWeld"
	weld.Part0    = hrp
	weld.Part1    = ball
	weld.Parent   = ball
end)

-- =============================================
-- MONEY POPUP
-- =============================================
function showMoneyPopup(character, amount)
	local head = character:FindFirstChild("Head")
	if not head then return end
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 100, 0, 36)
	bg.StudsOffset = Vector3.new(0, 2.5, 0)
	bg.AlwaysOnTop = true
	bg.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. amount
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bg
	TweenService:Create(bg, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = Vector3.new(0, 6, 0) }):Play()
	task.delay(0.5, function()
		if label.Parent then
			TweenService:Create(label, TweenInfo.new(0.7),
				{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
	task.delay(1.4, function() if bg.Parent then bg:Destroy() end end)
end

-- =============================================
-- THROW
-- =============================================
throwEvent.OnServerEvent:Connect(function(player, direction, power)
	if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.001 then return end
	if typeof(power) ~= "number" then power = 1 end

	local ball = nil
	for b, p in heldBalls do
		if p == player then ball = b; break end
	end
	if not ball then return end

	local ballType = ball:GetAttribute("BallType") or "Normal"
	local def      = BALL_DEFS[ballType] or BALL_DEFS.Normal

	ball:SetAttribute("ThrowerName", player.Name)
	ball:SetAttribute("Damage", def.damage)
	markBallThrown(ball)

	local weld = ball:FindFirstChild("BallWeld")
	if weld then weld:Destroy() end

	heldBalls[ball] = nil
	ball.CanCollide  = true

	local hint = ball:FindFirstChild("PickupHint")
	if hint then hint.Enabled = true end

	local clampedPower = math.clamp(power or 1, 0, 1)
	local td = def.throw or { minSpeed=30, maxSpeed=152, straightBase=0.38, straightRange=0.22, dropVelY=-32, spin=18, trailLife=0.28, upwardDrift=1 }

	local speed       = td.minSpeed + clampedPower * (td.maxSpeed - td.minSpeed)
	local straightTime = td.straightBase + clampedPower * td.straightRange

	-- Horizontal direction only — vertical handled by two-phase throw
	local horizDir = Vector3.new(direction.X, 0, direction.Z)
	if horizDir.Magnitude < 0.001 then horizDir = Vector3.new(0, 0, 1) end
	horizDir = horizDir.Unit

	-- Phase 1: fly straight
	local bv = Instance.new("BodyVelocity")
	bv.Velocity  = horizDir * speed + Vector3.new(0, td.upwardDrift or 2, 0)
	bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent    = ball

	-- Spin: perpendicular axis rotation — more spin = more visual motion in flight
	local spinAxis = horizDir:Cross(Vector3.new(0, 1, 0))
	if spinAxis.Magnitude < 0.001 then spinAxis = Vector3.new(1, 0, 0) end
	ball.AssemblyAngularVelocity = spinAxis.Unit * (td.spin or 18)

	-- Phase 2: release into per-type drop
	task.delay(straightTime, function()
		if not ball.Parent then return end
		bv:Destroy()
		ball.AssemblyLinearVelocity = horizDir * speed * 0.88 + Vector3.new(0, td.dropVelY or -18, 0)
	end)

	-- Trail: length and style differ per ball type
	if (td.trailLife or 0) > 0 then
		local att0 = Instance.new("Attachment")
		att0.Position = Vector3.new(0,  def.size * 0.35, 0)
		att0.Parent   = ball
		local att1 = Instance.new("Attachment")
		att1.Position = Vector3.new(0, -def.size * 0.35, 0)
		att1.Parent   = ball
		local trail = Instance.new("Trail")
		trail.Attachment0  = att0
		trail.Attachment1  = att1
		trail.Lifetime     = td.trailLife
		trail.MinLength    = 0
		trail.FaceCamera   = true
		trail.Color        = ColorSequence.new({
			ColorSequenceKeypoint.new(0, ball.BrickColor.Color),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		})
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.WidthScale   = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		trail.Parent = ball
	end

	connectPlayerHitPayout(ball, player)

	-- Split mechanic (only for Split type, not children)
	if def.splits then
		setupSplitOnHit(ball, player)
	end

	task.delay(VALID_TARGET_HIT_SECONDS, function()
		clearThrowConnection(ball)
		clearThrownState(ball)
	end)

	-- BallSpread upgrade
	if (player:GetAttribute("BallSpread") or 0) > 0 and ballType ~= "SplitChild" then
		local side = horizDir:Cross(Vector3.new(0, 1, 0))
		if side.Magnitude < 0.001 then side = Vector3.new(1, 0, 0) else side = side.Unit end
		local spreadSpeed = speed * 0.88   -- spread balls slightly slower than main
		local leftBall  = makeSpreadBall(ball, (horizDir - side * 0.18).Unit * spreadSpeed, -2.2)
		local rightBall = makeSpreadBall(ball, (horizDir + side * 0.18).Unit * spreadSpeed,  2.2)
		connectPlayerHitPayout(leftBall,  player)
		connectPlayerHitPayout(rightBall, player)
	end
end)

-- =============================================
-- CLEANUP ON DISCONNECT
-- =============================================
Players.PlayerRemoving:Connect(function(player)
	for ball, p in heldBalls do
		if p == player then
			local weld = ball:FindFirstChild("BallWeld")
			if weld then weld:Destroy() end
			clearThrowConnection(ball)
			clearThrownState(ball)
			heldBalls[ball] = nil
			ball.CanCollide  = true
			local hint = ball:FindFirstChild("PickupHint")
			if hint then hint.Enabled = true end
		end
	end
end)
