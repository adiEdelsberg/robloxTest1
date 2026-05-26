local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local NPC               = require(ServerStorage:WaitForChild("NPCModule"))
local BoundaryService   = require(ServerStorage:WaitForChild("WorldBoundaryService"))

local BOUNDS = { minX = -64, maxX = 64, minZ = 1096, maxZ = 1224 }
local gameEvents  = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits   = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")

local tennisRemaining = Instance.new("NumberValue")
tennisRemaining.Name = "TennisPlayersRemaining"
tennisRemaining.Parent = gameEvents

local tennisTotal = Instance.new("NumberValue")
tennisTotal.Name = "TennisPlayersTotal"
tennisTotal.Parent = gameEvents

local NEEDED = Balance.StageTargets.Tennis
local JUMPS_NEEDED = Balance.StageCarpets.JumpsNeeded
local defeatsThisArea = 0
local jumpsThisArea = 0
local gateOpen = false
local aliveSet = {}

local NEON = Enum.Material.Neon
local C90  = CFrame.Angles(0, 0, math.rad(90))
local HT   = 1.3

-- Court layout constants
local TZC = 1160   -- center Z of tennis world
local C1X = -32    -- court 1 center X
local C2X =  32    -- court 2 center X
local COURT_HALF_D = 47  -- half-depth of court along Z

-- ============================================================
-- ROLE DEFINITIONS  (name, bodyColor, stats, accessories)
-- ============================================================

-- 4 combat NPCs counted toward gate progress
local COMBAT_NPCS = {
	{
		name = "Champion Pro", bodyColor = "Bright orange", headColor = "Nougat", rarity = "Epic",
		maxHp = 14, moneyPerHit = 220, moneyOnDefeat = 1400,
		minSpeed = 36, maxSpeed = 54, minJump = 130, maxJump = 180, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			{ cyl = true, size = Vector3.new(0.35, 4.1, 4.1), color = "Bright yellow", mat = NEON, cf = CFrame.new(0, HT + 0.18, 0) * C90 },
			{ ball = true, size = Vector3.new(1.5, 1.5, 1.5), color = "Lime green", parent = "Right Arm", cf = CFrame.new(0.25, -1.2, -0.7), mat = NEON, trans = 0.05 },
		},
	},
	{
		name = "Topspin", bodyColor = "Hot pink", headColor = "Nougat", rarity = "Rare",
		maxHp = 9, minSpeed = 32, maxSpeed = 48, minJump = 95, maxJump = 140, jumpChance = 0.55, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			{ cyl = true, size = Vector3.new(0.18, 3.4, 3.4), color = "Hot pink", mat = NEON, trans = 0.12, cf = CFrame.new(0, 1.95, 0) * C90 },
		},
	},
	{
		name = "Ace", bodyColor = "Lime green", headColor = "Nougat", rarity = "Rare",
		maxHp = 8, minSpeed = 30, maxSpeed = 44, minJump = 95, maxJump = 135, jumpChance = 0.55, minJumpWait = 1, maxJumpWait = 4,
		accessories = {
			{ size = Vector3.new(2.5, 0.22, 1.05), color = "Institutional white", parent = "Torso", cf = CFrame.new(0, 0.42, -0.58), mat = NEON, trans = 0.1 },
			{ cyl = true, size = Vector3.new(0.16, 2.8, 2.0), color = "Really black", parent = "Right Arm", cf = CFrame.new(0.3, -1.05, -0.8) * C90 },
		},
	},
	{
		name = "Doubles", bodyColor = "Cyan", headColor = "Nougat", rarity = "Common",
		maxHp = 8, minSpeed = 29, maxSpeed = 43, minJump = 90, maxJump = 130, jumpChance = 0.5, minJumpWait = 1, maxJumpWait = 4,
		accessories = {
			{ size = Vector3.new(1.1, 0.16, 1.6), color = "Really black", parent = "Left Arm", cf = CFrame.new(0, -0.75, -0.65), mat = NEON, trans = 0.08 },
			{ size = Vector3.new(1.1, 0.16, 1.6), color = "Really black", parent = "Right Arm", cf = CFrame.new(0, -0.75, -0.65), mat = NEON, trans = 0.08 },
		},
	},
}

-- Ambient / role NPCs (no combat, no gate contribution)
local AMBIENT_NPCS = {
	-- Referees (2)
	{
		role = "referee",
		name = "Referee", bodyColor = "White", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 8, maxSpeed = 12, minJump = 50, maxJump = 60, jumpChance = 0,
		accessories = {
			{ size = Vector3.new(2.5, 0.22, 1.05), color = "Black", parent = "Torso", cf = CFrame.new(0, 0.42, -0.58) },
		},
		spawnX = -62, spawnZ = TZC,
	},
	{
		role = "referee",
		name = "Referee2", bodyColor = "White", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 8, maxSpeed = 12, minJump = 50, maxJump = 60, jumpChance = 0,
		accessories = {
			{ size = Vector3.new(2.5, 0.22, 1.05), color = "Black", parent = "Torso", cf = CFrame.new(0, 0.42, -0.58) },
		},
		spawnX = 62, spawnZ = TZC,
	},
	-- Ball boys (4, one per court corner)
	{
		role = "ballboy",
		name = "BallBoy1", bodyColor = "Bright yellow", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 28, maxSpeed = 36, minJump = 70, maxJump = 90, jumpChance = 0.1,
		accessories = {},
		spawnX = C1X - 20, spawnZ = TZC - COURT_HALF_D,
		courtCX = C1X, courtSide = -1,
	},
	{
		role = "ballboy",
		name = "BallBoy2", bodyColor = "Bright yellow", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 28, maxSpeed = 36, minJump = 70, maxJump = 90, jumpChance = 0.1,
		accessories = {},
		spawnX = C1X + 20, spawnZ = TZC + COURT_HALF_D,
		courtCX = C1X, courtSide = 1,
	},
	{
		role = "ballboy",
		name = "BallBoy3", bodyColor = "Bright yellow", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 28, maxSpeed = 36, minJump = 70, maxJump = 90, jumpChance = 0.1,
		accessories = {},
		spawnX = C2X - 20, spawnZ = TZC - COURT_HALF_D,
		courtCX = C2X, courtSide = -1,
	},
	{
		role = "ballboy",
		name = "BallBoy4", bodyColor = "Bright yellow", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 28, maxSpeed = 36, minJump = 70, maxJump = 90, jumpChance = 0.1,
		accessories = {},
		spawnX = C2X + 20, spawnZ = TZC + COURT_HALF_D,
		courtCX = C2X, courtSide = 1,
	},
	-- Crowd spectators (6)
	{
		role = "crowd",
		name = "Fan1", bodyColor = "Bright red", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 6, maxSpeed = 10, minJump = 40, maxJump = 60, jumpChance = 0,
		accessories = {},
		spawnX = -66, spawnZ = TZC - 30,
	},
	{
		role = "crowd",
		name = "Fan2", bodyColor = "Bright blue", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 6, maxSpeed = 10, minJump = 40, maxJump = 60, jumpChance = 0,
		accessories = {},
		spawnX = -66, spawnZ = TZC + 10,
	},
	{
		role = "crowd",
		name = "Fan3", bodyColor = "Lime green", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 6, maxSpeed = 10, minJump = 40, maxJump = 60, jumpChance = 0,
		accessories = {},
		spawnX = 66, spawnZ = TZC - 20,
	},
	{
		role = "crowd",
		name = "Fan4", bodyColor = "Bright orange", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 6, maxSpeed = 10, minJump = 40, maxJump = 60, jumpChance = 0,
		accessories = {},
		spawnX = 66, spawnZ = TZC + 25,
	},
	{
		role = "crowd",
		name = "Kid1", bodyColor = "Bright violet", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 10, maxSpeed = 16, minJump = 60, maxJump = 80, jumpChance = 0.05,
		accessories = {},
		spawnX = -66, spawnZ = TZC - 55,
	},
	{
		role = "crowd",
		name = "Kid2", bodyColor = "Hot pink", headColor = "Nougat", rarity = "Common",
		maxHp = 1, minSpeed = 10, maxSpeed = 16, minJump = 60, maxJump = 80, jumpChance = 0.05,
		accessories = {},
		spawnX = 66, spawnZ = TZC + 50,
	},
}

tennisTotal.Value = #COMBAT_NPCS
tennisRemaining.Value = #COMBAT_NPCS

-- ============================================================
-- PART ATTACHMENT UTILITY
-- ============================================================
local function attachPart(model, parentPartName, name, size, color, cf, material, shape, transparency)
	local parentPart = model:FindFirstChild(parentPartName)
	if not parentPart then return end
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.BrickColor = BrickColor.new(color)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = false
	part.CastShadow = false
	if shape then part.Shape = shape end
	part.CFrame = parentPart.CFrame * cf
	part.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parentPart
	weld.Part1 = part
	weld.Parent = part
end

local function improveTennisLook(model, data)
	attachPart(model, "Head", "LeftEyeWhite",  Vector3.new(0.42, 0.42, 0.16), "White",        CFrame.new(-0.48, 0.35, -1.18), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "RightEyeWhite", Vector3.new(0.42, 0.42, 0.16), "White",        CFrame.new(0.48,  0.35, -1.18), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "LeftPupil",     Vector3.new(0.18, 0.18, 0.1),  "Really black", CFrame.new(-0.48, 0.35, -1.32), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "RightPupil",    Vector3.new(0.18, 0.18, 0.1),  "Really black", CFrame.new(0.48,  0.35, -1.32), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "Visor",         Vector3.new(2.9, 0.22, 1.1),   data.bodyColor,  CFrame.new(0, 0.75, -0.55), NEON, nil, 0.15)
	attachPart(model, "Torso", "ShirtStripe",  Vector3.new(2.4, 0.24, 1.12),  "Institutional white", CFrame.new(0, 0.35, -0.58), nil, nil, 0.05)
	if data.name == "Champion Pro" then
		attachPart(model, "Torso", "GoldMedal", Vector3.new(0.9, 0.9, 0.2), "Bright yellow", CFrame.new(0, 0.25, -0.9), NEON, Enum.PartType.Ball, 0.08)
	end
end

-- ============================================================
-- GATE LOGIC
-- ============================================================
local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local function openGate() end

NPC.OnNPCDefeated:Connect(function(model, player)
	if not aliveSet[model] then return end
	aliveSet[model] = nil
	tennisRemaining.Value -= 1
	defeatsThisArea += 1
	if not gateOpen then stageHits.Value = defeatsThisArea end
	if player and playerScored then playerScored:Fire(player, "Tennis") end
	if defeatsThisArea >= NEEDED or tennisRemaining.Value <= 0 then
		openGate()
	end
end)

-- ============================================================
-- ROLE MOVEMENT LOOPS
-- ============================================================

-- Court player: baseline to net back-and-forth on their half of their court.
local function startCourtPlayerLoop(model, humanoid, courtCX, courtCZ, side)
	-- side: -1 = north half, 1 = south half
	local baselineZ = courtCZ + side * COURT_HALF_D * 0.85
	local netZ      = courtCZ + side * 8
	local halfW     = 18  -- lateral range

	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			-- Move to random baseline position
			local bx = courtCX + math.random(-halfW, halfW)
			humanoid:MoveTo(Vector3.new(bx, 1, baselineZ))
			humanoid.MoveToFinished:Wait()
			task.wait(math.random() * 0.8 + 0.2)

			-- Occasionally rush the net
			if math.random() < 0.35 then
				local nx = courtCX + math.random(-10, 10)
				humanoid:MoveTo(Vector3.new(nx, 1, netZ))
				humanoid.MoveToFinished:Wait()
				task.wait(math.random() * 0.6 + 0.3)
				-- retreat back
				humanoid:MoveTo(Vector3.new(bx, 1, baselineZ))
				humanoid.MoveToFinished:Wait()
			end

			-- Lateral slide along baseline
			local slide = courtCX + math.random(-halfW, halfW)
			humanoid:MoveTo(Vector3.new(slide, 1, baselineZ + math.random(-6, 6)))
			humanoid.MoveToFinished:Wait()
			task.wait(math.random() * 0.4)
		end
	end)
end

-- Referee: stays near umpire chair at x=±62, slow pacing ±3 studs, occasional 180 turn.
local function startRefereeLoop(model, humanoid, chairX, chairZ)
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local dx = math.random(-3, 3)
			local dz = math.random(-3, 3)
			humanoid:MoveTo(Vector3.new(chairX + dx, 1, chairZ + dz))
			humanoid.MoveToFinished:Wait()
			task.wait(math.random(3, 7))
		end
	end)
end

-- Ball boy: sprints between corner and net area of their court, picks up imaginary balls.
local function startBallBoyLoop(model, humanoid, courtCX, side)
	local cornerZ = TZC + side * COURT_HALF_D
	local netZ    = TZC + side * 12
	local cornerX = courtCX + math.random(-22, 22)

	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			-- Sprint to corner
			humanoid:MoveTo(Vector3.new(courtCX + math.random(-22, 22), 1, cornerZ))
			humanoid.MoveToFinished:Wait()
			task.wait(math.random() * 1.2 + 0.3)
			-- Sprint to net to return ball
			humanoid:MoveTo(Vector3.new(courtCX + math.random(-8, 8), 1, netZ))
			humanoid.MoveToFinished:Wait()
			task.wait(math.random() * 0.8 + 0.2)
			-- Scurry sideways
			humanoid:MoveTo(Vector3.new(courtCX + math.random(-24, 24), 1, TZC + side * (COURT_HALF_D - math.random(5, 15))))
			humanoid.MoveToFinished:Wait()
			task.wait(math.random() * 0.5)
		end
	end)
end

-- Crowd: slow shuffle within bleacher area (x=±66±4, z=TZC±55), long pauses.
local function startCrowdLoop(model, humanoid, baseX, baseZ)
	local range = 10
	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local tx = baseX + math.random(-range, range) * 0.5
			local tz = baseZ + math.random(-range, range)
			-- clamp inside world
			tx = math.clamp(tx, BOUNDS.minX + 2, BOUNDS.maxX - 2)
			tz = math.clamp(tz, BOUNDS.minZ + 2, BOUNDS.maxZ - 2)
			humanoid:MoveTo(Vector3.new(tx, 1, tz))
			task.wait(math.random(3, 9))
		end
	end)
end

local function spawnTennisNPCs()
	stageNeeded.Value = NEEDED
	stageHits.Value = 0
	math.randomseed(tick() + 5123)
	local courtAssignments = {
		{ courtCX = C1X, side = -1 },
		{ courtCX = C1X, side =  1 },
		{ courtCX = C2X, side = -1 },
		{ courtCX = C2X, side =  1 },
	}
	for i, data in COMBAT_NPCS do
		local ca = courtAssignments[i]
		local spawnZ = TZC + ca.side * (COURT_HALF_D * 0.7)
		data.spawnX = ca.courtCX
		data.spawnZ = spawnZ
		data.rarity = data.rarity or "Rare"
		local model, humanoid = NPC.createNPC(data)
		aliveSet[model] = true
		BoundaryService.bindModel(model, BOUNDS, { margin = 5, minY = 0.5, maxY = 60 })
		improveTennisLook(model, data)
		startCourtPlayerLoop(model, humanoid, ca.courtCX, TZC, ca.side)
	end
	for _, data in AMBIENT_NPCS do
		data.rarity = data.rarity or "Common"
		local model, humanoid = NPC.createNPC(data)
		BoundaryService.bindModel(model, BOUNDS, { margin = 5, minY = 0.5, maxY = 60 })
		improveTennisLook(model, data)
		if data.role == "referee" then
			startRefereeLoop(model, humanoid, data.spawnX, data.spawnZ)
		elseif data.role == "ballboy" then
			startBallBoyLoop(model, humanoid, data.courtCX, data.courtSide)
		elseif data.role == "crowd" then
			startCrowdLoop(model, humanoid, data.spawnX, data.spawnZ)
		end
	end
end

-- ============================================================
task.spawn(spawnTennisNPCs)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Tennis" then return end
		for model in aliveSet do
			aliveSet[model] = nil
			if model.Parent then model:Destroy() end
		end
		defeatsThisArea = 0
		jumpsThisArea = 0
		gateOpen = false
		tennisRemaining.Value = #COMBAT_NPCS
		spawnTennisNPCs()
	end)
end)
