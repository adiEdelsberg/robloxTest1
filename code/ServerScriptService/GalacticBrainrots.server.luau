local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local NPC               = require(ServerStorage:WaitForChild("NPCModule"))

local BOUNDS = { minX = -65, maxX = 65, minZ = 388, maxZ = 522 }

-- Add galactic values to GameEvents (created by BrainrotNPCs)
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")

local stageHits   = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")

local galacticRemaining = Instance.new("NumberValue")
galacticRemaining.Name   = "GalacticBrainrotsRemaining"
galacticRemaining.Parent = gameEvents

local galacticTotal = Instance.new("NumberValue")
galacticTotal.Name   = "GalacticBrainrotsTotal"
galacticTotal.Parent = gameEvents

local NEEDED        = Balance.StageTargets.Galactic
local JUMPS_NEEDED  = Balance.StageCarpets.JumpsNeeded
local defeatsThisArea = 0
local jumpsThisArea  = 0

local C90  = CFrame.Angles(0, 0, math.rad(90))
local HT   = 1.3   -- head ball radius
local NEON = Enum.Material.Neon

-- Tier 3: very fast, very high jumps, nearly constant jumping
local GALACTIC_BRAINROTS = {
	{
		name = "Nebula", bodyColor = "Bright violet", headColor = "Light stone grey",
		minSpeed = 28, maxSpeed = 41, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Violet neon halo floating above head
			{ cyl=true, size=Vector3.new(0.22,4.0,4.0), color="Bright violet", mat=NEON, trans=0.1, cf=CFrame.new(0,2.2,0)*C90 },
		},
	},
	{
		name = "Void", bodyColor = "Really black", headColor = "Medium stone grey",
		minSpeed = 24, maxSpeed = 37, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Dark ring at head equator
			{ cyl=true, size=Vector3.new(0.32,3.6,3.6), color="Dark stone grey", mat=NEON, cf=CFrame.new(0,0,0)*C90 },
		},
	},
	{
		name = "Cosmo", bodyColor = "Cyan", headColor = "Light stone grey",
		minSpeed = 30, maxSpeed = 45, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Transparent cyan space helmet dome
			{ ball=true, size=Vector3.new(3.1,3.1,3.1), color="Cyan", mat=NEON, trans=0.65, cf=CFrame.new(0,0.1,0) },
		},
	},
	{
		name = "Astro", bodyColor = "Medium blue", headColor = "Light stone grey",
		minSpeed = 27, maxSpeed = 40, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Blue visor across face
			{ size=Vector3.new(2.5,0.55,0.14), color="Medium blue", mat=NEON, trans=0.3, cf=CFrame.new(0,0.15,-HT) },
		},
	},
	{
		name = "Starboy", bodyColor = "Bright yellow", headColor = "Nougat",
		minSpeed = 34, maxSpeed = 49, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Yellow neon crown ring + center spike
			{ cyl=true, size=Vector3.new(0.35,2.9,2.9), color="Bright yellow", mat=NEON, cf=CFrame.new(0,HT+0.18,0)*C90 },
			{ cyl=true, size=Vector3.new(1.3,0.45,0.45), color="Bright yellow", mat=NEON, cf=CFrame.new(0,HT+0.35+0.65,0)*C90 },
		},
	},
	{
		name = "Galaxy", bodyColor = "Bright violet", headColor = "Light stone grey",
		minSpeed = 26, maxSpeed = 39, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Tilted hot-pink neon ring
			{ cyl=true, size=Vector3.new(0.28,3.9,3.9), color="Hot pink", mat=NEON, trans=0.15,
			  cf=CFrame.new(0,1.9,0)*CFrame.Angles(0.45,0,math.rad(90)) },
		},
	},
	{
		name = "Quantum", bodyColor = "Hot pink", headColor = "Light stone grey",
		minSpeed = 32, maxSpeed = 47, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Glowing pink orb floating above head
			{ ball=true, size=Vector3.new(1.7,1.7,1.7), color="Hot pink", mat=NEON, trans=0.1, cf=CFrame.new(0,3.2,0) },
		},
	},
	{
		name = "Photon", bodyColor = "Bright yellow", headColor = "Light stone grey",
		minSpeed = 38, maxSpeed = 53, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Two small yellow neon wings on back (welded to Torso)
			{ size=Vector3.new(0.2,1.9,1.0), color="Bright yellow", mat=NEON, parent="Torso",
			  cf=CFrame.new(-1.2,0.4,0.9)*CFrame.Angles(0, 0.45, 0.35) },
			{ size=Vector3.new(0.2,1.9,1.0), color="Bright yellow", mat=NEON, parent="Torso",
			  cf=CFrame.new( 1.2,0.4,0.9)*CFrame.Angles(0,-0.45,-0.35) },
		},
	},
	{
		name = "Comet", bodyColor = "White", headColor = "Light stone grey",
		minSpeed = 29, maxSpeed = 44, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- White neon comet tail trailing behind head
			{ size=Vector3.new(0.35,0.35,2.8), color="White", mat=NEON, trans=0.25, cf=CFrame.new(0,0,HT+1.4) },
		},
	},
	{
		name = "Pulsar", bodyColor = "Hot pink", headColor = "Light stone grey",
		minSpeed = 31, maxSpeed = 46, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Hot-pink equatorial ring (perpendicular to the other rings)
			{ cyl=true, size=Vector3.new(0.3,3.3,3.3), color="Hot pink", mat=NEON, cf=CFrame.new(0,0,0)*C90 },
		},
	},
	{
		name = "Nova", bodyColor = "Bright orange", headColor = "Nougat",
		minSpeed = 25, maxSpeed = 38, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Orange sunburst ring crown
			{ cyl=true, size=Vector3.new(0.22,3.6,3.6), color="Bright orange", mat=NEON, cf=CFrame.new(0,HT+0.11,0)*C90 },
		},
	},
	{
		name = "Meteor", bodyColor = "Medium stone grey", headColor = "Light stone grey",
		minSpeed = 33, maxSpeed = 48, minJump = 150, maxJump = 200, jumpChance = 0.75, minJumpWait = 1, maxJumpWait = 3,
		accessories = {
			-- Grey boulder on shoulder (welded to Torso)
			{ ball=true, size=Vector3.new(2.3,2.3,2.3), color="Dark stone grey", parent="Torso",
			  cf=CFrame.new(1.4,0.7,0.6) },
		},
	},
}

local TOTAL = #GALACTIC_BRAINROTS
galacticTotal.Value     = TOTAL
galacticRemaining.Value = TOTAL

local aliveSet = {}
local gateOpen = false

local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local function openGate() end

-- Connect listeners FIRST
NPC.OnNPCDefeated:Connect(function(model, player)
	if not aliveSet[model] then return end
	aliveSet[model] = nil

	galacticRemaining.Value = galacticRemaining.Value - 1
	defeatsThisArea += 1
	if not gateOpen then stageHits.Value = defeatsThisArea end
	if player and playerScored then playerScored:Fire(player, "Galactic") end

	if defeatsThisArea >= NEEDED or galacticRemaining.Value <= 0 then
		openGate()
	end
end)

local function spawnGalacticBrainrots()
	stageNeeded.Value = NEEDED
	math.randomseed(tick() + 1999)
	for _, data in GALACTIC_BRAINROTS do
		data.maxHp = data.maxHp or 3
		data.rarity = data.rarity or "Epic"
		data.spawnX = math.random(-60, 60)
		data.spawnZ = math.random(392, 518)
		local model, humanoid = NPC.createNPC(data)
		aliveSet[model] = true
		NPC.startWander(model, humanoid, data, BOUNDS)
	end
end

task.spawn(spawnGalacticBrainrots)

-- ---- World restart listener ----
task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Galactic" then return end
		for model in aliveSet do
			aliveSet[model] = nil
			if model.Parent then model:Destroy() end
		end
		defeatsThisArea = 0
		jumpsThisArea = 0
		gateOpen = false
		galacticRemaining.Value = TOTAL
		spawnGalacticBrainrots()
	end)
end)
