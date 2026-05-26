local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local NPC               = require(ServerStorage:WaitForChild("NPCModule"))

local BOUNDS = { minX = -60, maxX = 60, minZ = 135, maxZ = 265 }

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")

local stageHits   = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")

local pizzaRemaining = Instance.new("NumberValue")
pizzaRemaining.Name   = "PizzaBrainrotsRemaining"
pizzaRemaining.Parent = gameEvents

local pizzaTotal = Instance.new("NumberValue")
pizzaTotal.Name   = "PizzaBrainrotsTotal"
pizzaTotal.Parent = gameEvents

local notifyEvent = gameEvents:FindFirstChild("GateOpenNotify") or Instance.new("RemoteEvent")
if not notifyEvent.Parent then
	notifyEvent.Name   = "GateOpenNotify"
	notifyEvent.Parent = gameEvents
end

local C90 = CFrame.Angles(0, 0, math.rad(90))
local HT  = 1.3

local PIZZA_BRAINROTS = {
	{
		name = "Chef Boy", bodyColor = "White", headColor = "Nougat",
		minSpeed = 10, maxSpeed = 16, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(0.38,2.6,2.6), color="White", cf=CFrame.new(0,HT+0.19,0)*C90 },
			{ cyl=true, size=Vector3.new(2.8,2.0,2.0), color="White",  cf=CFrame.new(0,HT+0.38+1.4,0)*C90 },
		},
	},
	{
		name = "Pepperoni", bodyColor = "Bright red", headColor = "Nougat",
		minSpeed = 13, maxSpeed = 20, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(0.5,2.9,2.9), color="Bright red", cf=CFrame.new(0,HT+0.25,0)*C90 },
		},
	},
	{
		name = "Mozzarella", bodyColor = "White", headColor = "Nougat",
		minSpeed = 8, maxSpeed = 14, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ size=Vector3.new(1.6,0.75,0.3), color="White", cf=CFrame.new(0,HT+0.1,-HT+0.4) },
		},
	},
	{
		name = "Sauce Boss", bodyColor = "Bright orange", headColor = "Nougat",
		minSpeed = 15, maxSpeed = 22, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(0.5,2.7,2.7), color="Bright orange", cf=CFrame.new(0,0.3,0)*C90 },
		},
	},
	{
		name = "Crust Lord", bodyColor = "Tan", headColor = "Nougat",
		minSpeed = 9, maxSpeed = 15, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(0.28,3.9,3.9), color="Reddish brown", cf=CFrame.new(0,HT+0.14,0)*C90 },
			{ cyl=true, size=Vector3.new(0.75,2.2,2.2), color="Reddish brown", cf=CFrame.new(0,HT+0.28+0.38,0)*C90 },
		},
	},
	{
		name = "Pineapple", bodyColor = "Bright yellow", headColor = "Nougat",
		minSpeed = 18, maxSpeed = 26, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(2.0,0.5,0.5), color="Bright yellow", cf=CFrame.new(0,   HT+1.0, 0)*C90 },
			{ cyl=true, size=Vector3.new(1.6,0.4,0.4), color="Bright yellow", cf=CFrame.new(-0.6,HT+0.8, 0)*C90 },
			{ cyl=true, size=Vector3.new(1.6,0.4,0.4), color="Bright yellow", cf=CFrame.new( 0.6,HT+0.8, 0)*C90 },
		},
	},
	{
		name = "Calzone", bodyColor = "Bright red", headColor = "Nougat",
		minSpeed = 12, maxSpeed = 19, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ size=Vector3.new(2.3,0.45,0.1), color="Bright red", cf=CFrame.new(0,0.2,-HT)*CFrame.Angles(0,0,0.4) },
		},
	},
	{
		name = "Marinara", bodyColor = "Bright orange", headColor = "Nougat",
		minSpeed = 14, maxSpeed = 21, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(1.7,2.05,2.05), color="Bright red", cf=CFrame.new(0,HT+0.85,0)*C90 },
		},
	},
	{
		name = "Funghi", bodyColor = "Tan", headColor = "Nougat",
		minSpeed = 11, maxSpeed = 17, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(0.38,4.0,4.0), color="Reddish brown", cf=CFrame.new(0,HT+0.19,0)*C90 },
		},
	},
	{
		name = "Anchovie", bodyColor = "Medium blue", headColor = "Nougat",
		minSpeed = 16, maxSpeed = 24, minJump = 68, maxJump = 85, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(0.22,3.1,3.1), color="Medium blue", cf=CFrame.new(0,HT+0.11,0)*C90 },
			{ cyl=true, size=Vector3.new(0.55,2.6,2.6), color="Medium blue", cf=CFrame.new(0,HT+0.22+0.28,0)*C90 },
		},
	},
}

local TOTAL = #PIZZA_BRAINROTS
local DEFEATS_NEEDED = Balance.StageTargets.Pizza

pizzaTotal.Value     = DEFEATS_NEEDED
pizzaRemaining.Value = DEFEATS_NEEDED

local aliveSet = {}
local defeatsThisArea = 0

local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

NPC.OnNPCDefeated:Connect(function(model, player)
	if not aliveSet[model] then return end
	aliveSet[model] = nil
	defeatsThisArea += 1
	stageHits.Value = defeatsThisArea
	if pizzaRemaining.Value > 0 then
		pizzaRemaining.Value -= 1
	end
	if player and playerScored then playerScored:Fire(player, "Pizza") end
end)

local function spawnPizzaBrainrots()
	stageNeeded.Value = DEFEATS_NEEDED
	math.randomseed(tick() + 999)
	for _, data in PIZZA_BRAINROTS do
		data.maxHp = data.maxHp or 2
		data.rarity = data.rarity or "Rare"
		data.spawnX = math.random(-55, 55)
		data.spawnZ = math.random(140, 260)
		local model, humanoid = NPC.createNPC(data)
		aliveSet[model] = true
		NPC.startWander(model, humanoid, data, BOUNDS)
	end
end

task.spawn(spawnPizzaBrainrots)

-- ---- World restart listener ----
task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Pizza" then return end
		for model in aliveSet do
			aliveSet[model] = nil
			if model.Parent then model:Destroy() end
		end
		defeatsThisArea = 0
		pizzaRemaining.Value = DEFEATS_NEEDED
		spawnPizzaBrainrots()
	end)
end)
