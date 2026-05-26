local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local NPC               = require(ServerStorage:WaitForChild("NPCModule"))

local BOUNDS = { minX = -74, maxX = 74, minZ = 866, maxZ = 1014 }
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")

local sportsRemaining = Instance.new("NumberValue")
sportsRemaining.Name = "SportsPlayersRemaining"
sportsRemaining.Parent = gameEvents

local sportsTotal = Instance.new("NumberValue")
sportsTotal.Name = "SportsPlayersTotal"
sportsTotal.Parent = gameEvents

local NEEDED = Balance.StageTargets.Sports
local JUMPS_NEEDED = Balance.StageCarpets.JumpsNeeded
local defeatsThisArea = 0
local jumpsThisArea = 0
local gateOpen = false
local aliveSet = {}

local NEON = Enum.Material.Neon
local C90 = CFrame.Angles(0, 0, math.rad(90))
local HT = 1.3

local SPORTS_NPCS = {
	{
		name = "Dunker", bodyColor = "Bright orange", headColor = "Nougat",
		maxHp = 7, minSpeed = 24, maxSpeed = 36, minJump = 105, maxJump = 150, jumpChance = 0.7, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			{ size = Vector3.new(2.3, 0.28, 1.1), color = "Bright blue", parent = "Torso", cf = CFrame.new(0, 0.45, -0.55), mat = NEON, trans = 0.15 },
			{ ball = true, size = Vector3.new(1.4, 1.4, 1.4), color = "Bright orange", parent = "Right Arm", cf = CFrame.new(0.1, -1.15, -0.6) },
		},
	},
	{
		name = "Striker", bodyColor = "Bright green", headColor = "Nougat",
		maxHp = 7, minSpeed = 30, maxSpeed = 44, minJump = 80, maxJump = 125, jumpChance = 0.45, minJumpWait = 2, maxJumpWait = 4,
		accessories = {
			{ size = Vector3.new(2.2, 0.22, 1.1), color = "White", parent = "Torso", cf = CFrame.new(0, 0.45, -0.55), mat = NEON, trans = 0.08 },
			{ ball = true, size = Vector3.new(1.15, 1.15, 1.15), color = "Institutional white", parent = "Right Leg", cf = CFrame.new(0.45, -1.05, -0.85) },
		},
	},
	{
		name = "Goalie", bodyColor = "Bright yellow", headColor = "Nougat",
		maxHp = 8, minSpeed = 20, maxSpeed = 32, minJump = 100, maxJump = 145, jumpChance = 0.55, minJumpWait = 1, maxJumpWait = 4,
		accessories = {
			{ size = Vector3.new(1.7, 0.2, 1.0), color = "Really black", parent = "Left Arm", cf = CFrame.new(0, -0.35, -0.5), trans = 0.05 },
			{ size = Vector3.new(1.7, 0.2, 1.0), color = "Really black", parent = "Right Arm", cf = CFrame.new(0, -0.35, -0.5), trans = 0.05 },
		},
	},
	{
		name = "Referee", bodyColor = "Really black", headColor = "Nougat",
		maxHp = 7, minSpeed = 25, maxSpeed = 38, minJump = 75, maxJump = 110, jumpChance = 0.35, minJumpWait = 2, maxJumpWait = 5,
		accessories = {
			{ size = Vector3.new(2.25, 0.22, 1.05), color = "Institutional white", parent = "Torso", cf = CFrame.new(0, 0.35, -0.58) },
			{ size = Vector3.new(0.25, 2.5, 0.2), color = "Institutional white", parent = "Torso", cf = CFrame.new(-0.55, 0, -0.7) },
			{ size = Vector3.new(0.25, 2.5, 0.2), color = "Institutional white", parent = "Torso", cf = CFrame.new(0.55, 0, -0.7) },
		},
	},
	{
		name = "Mascot", bodyColor = "Hot pink", headColor = "Bright yellow",
		maxHp = 9, minSpeed = 28, maxSpeed = 42, minJump = 120, maxJump = 170, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			{ cyl = true, size = Vector3.new(0.32, 3.2, 3.2), color = "Bright yellow", mat = NEON, cf = CFrame.new(0, HT + 0.16, 0) * C90 },
			{ size = Vector3.new(2.8, 0.3, 1.2), color = "Cyan", parent = "Torso", cf = CFrame.new(0, 0.5, -0.55), mat = NEON, trans = 0.18 },
		},
	},
	{
		name = "Sprinter", bodyColor = "Cyan", headColor = "Nougat",
		maxHp = 7, minSpeed = 38, maxSpeed = 56, minJump = 90, maxJump = 130, jumpChance = 0.5, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			{ size = Vector3.new(1.8, 0.18, 0.55), color = "Bright yellow", parent = "Left Leg", cf = CFrame.new(0, -1.15, -0.35), mat = NEON, trans = 0.08 },
			{ size = Vector3.new(1.8, 0.18, 0.55), color = "Bright yellow", parent = "Right Leg", cf = CFrame.new(0, -1.15, -0.35), mat = NEON, trans = 0.08 },
		},
	},
	{
		name = "Hoopster", bodyColor = "Bright blue", headColor = "Nougat",
		maxHp = 8, minSpeed = 28, maxSpeed = 40, minJump = 120, maxJump = 165, jumpChance = 0.65, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			{ cyl = true, size = Vector3.new(0.2, 3.4, 3.4), color = "Really red", mat = NEON, trans = 0.12, cf = CFrame.new(0, 2.15, 0) * C90 },
		},
	},
	{
		name = "Champion", bodyColor = "Bright yellow", headColor = "Nougat",
		maxHp = 12, moneyPerHit = 180, moneyOnDefeat = 1100,
		minSpeed = 34, maxSpeed = 50, minJump = 130, maxJump = 180, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			{ cyl = true, size = Vector3.new(0.35, 3.8, 3.8), color = "Bright yellow", mat = NEON, cf = CFrame.new(0, HT + 0.18, 0) * C90 },
			{ size = Vector3.new(3, 0.35, 1.2), color = "Really red", parent = "Torso", cf = CFrame.new(0, 0.5, -0.55), mat = NEON, trans = 0.12 },
		},
	},
}

sportsTotal.Value = #SPORTS_NPCS
sportsRemaining.Value = #SPORTS_NPCS

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

local function improveSportsLook(model, data)
	attachPart(model, "Head", "LeftEyeWhite", Vector3.new(0.42, 0.42, 0.16), "White", CFrame.new(-0.48, 0.35, -1.18), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "RightEyeWhite", Vector3.new(0.42, 0.42, 0.16), "White", CFrame.new(0.48, 0.35, -1.18), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "LeftPupil", Vector3.new(0.18, 0.18, 0.1), "Really black", CFrame.new(-0.48, 0.35, -1.32), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "RightPupil", Vector3.new(0.18, 0.18, 0.1), "Really black", CFrame.new(0.48, 0.35, -1.32), nil, Enum.PartType.Ball)
	attachPart(model, "Head", "Smile", Vector3.new(0.72, 0.12, 0.1), "Really black", CFrame.new(0, -0.35, -1.34))
	attachPart(model, "Head", "Headband", Vector3.new(2.6, 0.24, 2.6), data.bodyColor, CFrame.new(0, 0.72, 0), NEON, Enum.PartType.Cylinder, 0.18)
	if data.name == "Goalie" then
		attachPart(model, "Torso", "ChestPad", Vector3.new(2.6, 2.1, 0.25), "Really black", CFrame.new(0, 0.15, -0.7), nil, nil, 0.05)
	elseif data.name == "Champion" then
		attachPart(model, "Torso", "Trophy", Vector3.new(1.1, 1.6, 0.7), "Bright yellow", CFrame.new(0, 1.55, -0.95), NEON, nil, 0.06)
	end
end

local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local function openGate() end

NPC.OnNPCDefeated:Connect(function(model, player)
	if not aliveSet[model] then return end
	aliveSet[model] = nil
	sportsRemaining.Value -= 1
	defeatsThisArea += 1
	if not gateOpen then stageHits.Value = defeatsThisArea end
	if player and playerScored then playerScored:Fire(player, "Sports") end
	if defeatsThisArea >= NEEDED or sportsRemaining.Value <= 0 then
		openGate()
	end
end)

local function spawnSportsNPCs()
	stageNeeded.Value = NEEDED
	math.randomseed(tick() + 4111)
	for _, data in SPORTS_NPCS do
		data.spawnX = math.random(BOUNDS.minX + 6, BOUNDS.maxX - 6)
		data.spawnZ = math.random(BOUNDS.minZ + 8, BOUNDS.maxZ - 8)
		local model, humanoid = NPC.createNPC(data)
		aliveSet[model] = true
		improveSportsLook(model, data)
		NPC.startWander(model, humanoid, data, BOUNDS)
	end
end

task.spawn(spawnSportsNPCs)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Sports" then return end
		for model in aliveSet do
			aliveSet[model] = nil
			if model.Parent then model:Destroy() end
		end
		defeatsThisArea = 0
		jumpsThisArea = 0
		gateOpen = false
		sportsRemaining.Value = #SPORTS_NPCS
		spawnSportsNPCs()
	end)
end)
