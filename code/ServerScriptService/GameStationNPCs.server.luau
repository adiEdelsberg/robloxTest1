local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local NPC               = require(ServerStorage:WaitForChild("NPCModule"))

local BOUNDS = { minX = -68, maxX = 68, minZ = 1308, maxZ = 1452 }
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")

local stationRemaining = Instance.new("NumberValue")
stationRemaining.Name = "GameStationBotsRemaining"
stationRemaining.Parent = gameEvents

local stationTotal = Instance.new("NumberValue")
stationTotal.Name = "GameStationBotsTotal"
stationTotal.Parent = gameEvents

local NEEDED = Balance.StageTargets.GameStation
local defeatsThisArea = 0
local aliveSet = {}
local gateOpen = false

local NEON = Enum.Material.Neon
local C90 = CFrame.Angles(0, 0, math.rad(90))
local HT = 1.3

local function openGate() end

local BOTS = {
	{ name = "Button Bot", bodyColor = "Bright blue", headColor = "Institutional white", maxHp = 10, minSpeed = 30, maxSpeed = 44, minJump = 100, maxJump = 145, jumpChance = 0.55, minJumpWait = 1, maxJumpWait = 4 },
	{ name = "Pixel Runner", bodyColor = "Cyan", headColor = "Light stone grey", maxHp = 10, minSpeed = 38, maxSpeed = 58, minJump = 90, maxJump = 130, jumpChance = 0.45, minJumpWait = 1, maxJumpWait = 3 },
	{ name = "D-Pad Droid", bodyColor = "Really black", headColor = "Medium stone grey", maxHp = 11, minSpeed = 26, maxSpeed = 40, minJump = 95, maxJump = 135, jumpChance = 0.45, minJumpWait = 2, maxJumpWait = 4 },
	{ name = "Arcade Ace", bodyColor = "Hot pink", headColor = "Nougat", maxHp = 10, minSpeed = 32, maxSpeed = 48, minJump = 110, maxJump = 155, jumpChance = 0.65, minJumpWait = 1, maxJumpWait = 3 },
	{ name = "Combo King", bodyColor = "Bright yellow", headColor = "Nougat", maxHp = 12, minSpeed = 34, maxSpeed = 50, minJump = 120, maxJump = 165, jumpChance = 0.7, minJumpWait = 1, maxJumpWait = 3 },
	{ name = "Neon Gamer", bodyColor = "Bright violet", headColor = "Light stone grey", maxHp = 10, minSpeed = 30, maxSpeed = 46, minJump = 105, maxJump = 150, jumpChance = 0.6, minJumpWait = 1, maxJumpWait = 4 },
	{ name = "Console Boss", bodyColor = "Really red", headColor = "Bright yellow", maxHp = 16, moneyPerHit = 260, moneyOnDefeat = 1800, minSpeed = 36, maxSpeed = 54, minJump = 130, maxJump = 185, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2 },
}

for _, bot in BOTS do
	bot.accessories = bot.accessories or {
		{ cyl = true, size = Vector3.new(0.28, 3.3, 3.3), color = bot.bodyColor, mat = NEON, trans = 0.12, cf = CFrame.new(0, HT + 0.14, 0) * C90 },
		{ size = Vector3.new(2.5, 0.26, 1.05), color = "Cyan", parent = "Torso", cf = CFrame.new(0, 0.42, -0.58), mat = NEON, trans = 0.12 },
	}
end

stationTotal.Value = #BOTS
stationRemaining.Value = #BOTS

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

local function improveBotLook(model, data)
	attachPart(model, "Head", "LeftEye", Vector3.new(0.42, 0.42, 0.16), "Cyan", CFrame.new(-0.48, 0.35, -1.18), NEON, Enum.PartType.Ball, 0.08)
	attachPart(model, "Head", "RightEye", Vector3.new(0.42, 0.42, 0.16), "Hot pink", CFrame.new(0.48, 0.35, -1.18), NEON, Enum.PartType.Ball, 0.08)
	attachPart(model, "Head", "Visor", Vector3.new(2.35, 0.34, 0.12), "Really black", CFrame.new(0, 0.2, -1.32), nil, nil, 0.05)
	attachPart(model, "Torso", "PowerCore", Vector3.new(0.9, 0.9, 0.2), data.bodyColor, CFrame.new(0, 0.1, -0.85), NEON, Enum.PartType.Ball, 0.08)
	attachPart(model, "Left Arm", "LeftPad", Vector3.new(1.1, 0.28, 0.8), "Really black", CFrame.new(0, -0.8, -0.38), nil, nil, 0.05)
	attachPart(model, "Right Arm", "RightPad", Vector3.new(1.1, 0.28, 0.8), "Really black", CFrame.new(0, -0.8, -0.38), nil, nil, 0.05)
end

local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

NPC.OnNPCDefeated:Connect(function(model, player)
	if not aliveSet[model] then return end
	aliveSet[model] = nil
	stationRemaining.Value -= 1
	defeatsThisArea += 1
	if not gateOpen then stageHits.Value = defeatsThisArea end
	if player and playerScored then playerScored:Fire(player, "Game Station") end
	if defeatsThisArea >= NEEDED or stationRemaining.Value <= 0 then
		openGate()
	end
end)

local function spawnGameStationNPCs()
	stageNeeded.Value = NEEDED
	stageHits.Value = 0
	math.randomseed(tick() + 6123)
	for _, data in BOTS do
		data.spawnX = math.random(BOUNDS.minX + 5, BOUNDS.maxX - 5)
		data.spawnZ = math.random(BOUNDS.minZ + 6, BOUNDS.maxZ - 6)
		local model, humanoid = NPC.createNPC(data)
		aliveSet[model] = true
		improveBotLook(model, data)
		NPC.startWander(model, humanoid, data, BOUNDS)
	end
end

task.spawn(spawnGameStationNPCs)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Game Station" then return end
		for model in aliveSet do
			aliveSet[model] = nil
			if model.Parent then model:Destroy() end
		end
		defeatsThisArea = 0
		gateOpen = false
		stationRemaining.Value = #BOTS
		spawnGameStationNPCs()
	end)
end)
