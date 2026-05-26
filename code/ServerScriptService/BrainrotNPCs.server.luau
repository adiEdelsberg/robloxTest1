local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage    = game:GetService("ServerStorage")
local Players          = game:GetService("Players")
local Balance          = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local NPC              = require(ServerStorage:WaitForChild("NPCModule"))

-- ---- Shared state in ReplicatedStorage ----
local gameEvents = Instance.new("Folder")
gameEvents.Name = "GameEvents"
gameEvents.Parent = ReplicatedStorage

local brainrotsRemaining = Instance.new("NumberValue")
brainrotsRemaining.Name = "BrainrotsRemaining"
brainrotsRemaining.Parent = gameEvents

local brainrotsTotal = Instance.new("NumberValue")
brainrotsTotal.Name = "BrainrotsTotal"
brainrotsTotal.Parent = gameEvents

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "GateOpenNotify"
notifyEvent.Parent = gameEvents

local stageHits = Instance.new("NumberValue")
stageHits.Name = "StageHits"
stageHits.Value = 0
stageHits.Parent = gameEvents

local stageNeeded = Instance.new("NumberValue")
stageNeeded.Name = "StageNeeded"
stageNeeded.Value = Balance.StageTargets.Playground
stageNeeded.Parent = gameEvents

-- ---- NPC definitions ----
local BOUNDS = { minX = -52, maxX = 52, minZ = -52, maxZ = 52 }

local C90 = CFrame.Angles(0, 0, math.rad(90))
local HT  = 1.3

local BRAINROTS = {
	-- 1. Skibidi Toilet – classic blue helmet, slow wanderer
	{
		name = "Skibidi", bodyColor = "Bright blue",
		minSpeed = 5, maxSpeed = 10, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 5, maxJumpWait = 12,
		accessories = {
			{ cyl=true, size=Vector3.new(2.0, 2.0, 2.0), color="White", cf=CFrame.new(0, HT+1.0, 0)*C90 },
			{ cyl=true, size=Vector3.new(0.22, 2.4, 2.4), color="White", cf=CFrame.new(0, HT+2.2, 0)*C90 },
		},
	},
	-- 2. Sigma – red blazer, fast and aggressive
	{
		name = "Sigma", bodyColor = "Bright red",
		minSpeed = 14, maxSpeed = 22, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 4, maxJumpWait = 8,
		accessories = {
			{ size=Vector3.new(2.6, 0.35, 0.12), color="Really black", cf=CFrame.new(0, 0.15, -HT) },
			{ size=Vector3.new(2.6, 0.35, 0.12), color="Really black", cf=CFrame.new(0, -0.3, -HT) },
		},
	},
	-- 3. Gyatt – hot pink, wide & very slow
	{
		name = "Gyatt", bodyColor = "Hot pink",
		minSpeed = 3, maxSpeed = 7, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 6, maxJumpWait = 14,
		accessories = {
			{ size=Vector3.new(1.8, 0.8, 0.3), color="Hot pink", cf=CFrame.new(0, HT+0.2, -HT+0.3) },
			{ size=Vector3.new(1.2, 0.5, 0.3), color="Magenta", cf=CFrame.new(0, HT+0.8, -HT+0.3) },
		},
	},
	-- 4. Rizz Lord – golden crown, bouncy jumper!
	{
		name = "Rizz Lord", bodyColor = "Bright yellow",
		minSpeed = 10, maxSpeed = 18, minJump = 55, maxJump = 75, jumpChance = 0.45, minJumpWait = 2, maxJumpWait = 5,
		accessories = {
			{ cyl=true, size=Vector3.new(0.35, 3.0, 3.0), color="Bright yellow", cf=CFrame.new(0, HT+0.17, 0)*C90 },
			{ size=Vector3.new(2.2, 0.6, 0.6), color="Bright orange", cf=CFrame.new(0, HT+0.55, 0) },
		},
	},
	-- 5. Fanum Tax – orange hoodie vibes, medium
	{
		name = "Fanum", bodyColor = "Bright orange",
		minSpeed = 9, maxSpeed = 16, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 4, maxJumpWait = 10,
		accessories = {
			{ cyl=true, size=Vector3.new(0.8, 2.4, 2.4), color="Bright orange", cf=CFrame.new(0, HT+0.4, 0)*C90 },
			{ size=Vector3.new(1.8, 0.2, 0.8), color="Dark orange", cf=CFrame.new(0, HT+0.07, -HT-0.35) },
		},
	},
	-- 6. Ohio – purple chaos, erratic jumper!
	{
		name = "Ohio", bodyColor = "Bright violet",
		minSpeed = 7, maxSpeed = 14, minJump = 48, maxJump = 68, jumpChance = 0.55, minJumpWait = 2, maxJumpWait = 4,
		accessories = {
			{ cyl=true, size=Vector3.new(1.4, 0.55, 0.55), color="Bright red", cf=CFrame.new(-0.7, HT+0.8, 0)*C90 },
			{ cyl=true, size=Vector3.new(1.4, 0.55, 0.55), color="Bright red", cf=CFrame.new( 0.7, HT+0.8, 0)*C90 },
			{ size=Vector3.new(1.5, 0.3, 0.3), color="Bright violet", cf=CFrame.new(0, HT+1.3, 0) },
		},
	},
	-- 7. NPC Bot – grey robotic, very slow, predictable
	{
		name = "NPC", bodyColor = "Medium stone grey",
		minSpeed = 3, maxSpeed = 6, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 8, maxJumpWait = 18,
		accessories = {
			{ size=Vector3.new(2.0, 0.75, 0.12), color="Medium stone grey", cf=CFrame.new(0, 0.3, -HT) },
			{ size=Vector3.new(0.6, 0.6, 0.6), color="Cyan", cf=CFrame.new(0, HT+0.3, -HT) },
		},
	},
	-- 8. Hawk Tuah – vivid green, fast & bouncy jumper!
	{
		name = "Hawk Tuah", bodyColor = "Lime green",
		minSpeed = 15, maxSpeed = 24, minJump = 52, maxJump = 70, jumpChance = 0.35, minJumpWait = 3, maxJumpWait = 6,
		accessories = {
			{ cyl=true, size=Vector3.new(0.26, 4.0, 4.0), color="Lime green", cf=CFrame.new(0, HT+0.13, 0)*C90 },
			{ cyl=true, size=Vector3.new(0.8, 2.5, 2.5), color="Bright green", cf=CFrame.new(0, HT+0.4, 0)*C90 },
		},
	},
	-- 9. Looksmaxx – tan model, mirror disk, medium
	{
		name = "Looksmaxx", bodyColor = "Tan",
		minSpeed = 8, maxSpeed = 15, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 5, maxJumpWait = 11,
		accessories = {
			{ cyl=true, size=Vector3.new(0.25, 2.9, 2.9), color="White", cf=CFrame.new(0, -0.25, 0)*C90 },
			{ size=Vector3.new(0.4, 2.5, 2.5), color="Pearl", cf=CFrame.new(0, -0.25, 0) },
		},
	},
	-- 10. Mogging – dark blue, medium, confident stride
	{
		name = "Mogging", bodyColor = "Medium blue",
		minSpeed = 12, maxSpeed = 20, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 4, maxJumpWait = 9,
		accessories = {
			{ cyl=true, size=Vector3.new(0.3, 3.2, 3.2), color="Medium blue", cf=CFrame.new(0, HT+0.15, 0)*C90 },
			{ size=Vector3.new(2.0, 0.25, 2.0), color="Bright blue", cf=CFrame.new(0, HT+0.15, 0) },
		},
	},
	-- 11. Delulu – dreamy pink, slow drifter
	{
		name = "Delulu", bodyColor = "Pink",
		minSpeed = 4, maxSpeed = 9, minJump = 40, maxJump = 55, jumpChance = 0.0, minJumpWait = 6, maxJumpWait = 14,
		accessories = {
			{ size=Vector3.new(3.0, 0.4, 0.4), color="Pink", cf=CFrame.new(0, HT+0.5, 0) },
			{ size=Vector3.new(3.0, 0.4, 0.4), color="Magenta", cf=CFrame.new(0, HT+0.9, 0) },
			{ cyl=true, size=Vector3.new(0.2, 2.6, 2.6), color="Pink", cf=CFrame.new(0, HT+1.1, 0)*C90 },
		},
	},
	-- 12. No Cap – white cap, medium speed, erratic jumper!
	{
		name = "No Cap", bodyColor = "White",
		minSpeed = 11, maxSpeed = 19, minJump = 50, maxJump = 72, jumpChance = 0.4, minJumpWait = 2, maxJumpWait = 5,
		accessories = {
			{ cyl=true, size=Vector3.new(0.5, 2.8, 2.8), color="Really black", cf=CFrame.new(0, HT+0.25, 0)*C90 },
			{ size=Vector3.new(2.5, 0.45, 2.5), color="Really black", cf=CFrame.new(0, HT+0.5, 0) },
		},
	},
}

local TOTAL = #BRAINROTS
brainrotsTotal.Value     = TOTAL
brainrotsRemaining.Value = TOTAL

local aliveSet = {}
local gateOpen = false
local defeatsThisArea = 0
local DEFEATS_NEEDED = Balance.StageTargets.Playground

local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local function openGate() end

NPC.OnNPCDefeated:Connect(function(model, player)
	if not aliveSet[model] then return end
	aliveSet[model] = nil
	if brainrotsRemaining.Value > 0 then
		brainrotsRemaining.Value -= 1
	end
	if player and playerScored then playerScored:Fire(player, "Playground") end
	defeatsThisArea += 1
	if not gateOpen then stageHits.Value = defeatsThisArea end
	if not gateOpen and defeatsThisArea >= DEFEATS_NEEDED then
		openGate()
	end
end)

local function spawnAllBrainrots()
	math.randomseed(tick())
	for _, data in BRAINROTS do
		data.rarity = data.rarity or "Common"
		local model, humanoid = NPC.createNPC(data)
		aliveSet[model] = true
		NPC.startWander(model, humanoid, data, BOUNDS)
	end
end

-- ---- Spawn brainrots ----
spawnAllBrainrots()

-- ---- World restart listener ----
task.spawn(function()
	local signal = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Playground" then return end
		for model in aliveSet do
			aliveSet[model] = nil
			if model.Parent then model:Destroy() end
		end
		defeatsThisArea = 0
		gateOpen = false
		brainrotsRemaining.Value = TOTAL
		spawnAllBrainrots()
	end)
end)
