-- WorldManager.server.luau
-- Per-player world tracking: no doors, personal stopwatch, 1-second sky launch to next level.

local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local Balance        = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local WorldOrder     = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local gameEvents  = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits   = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")

-- Legacy shared-state values kept so leaderboard/scoreboard scripts don't break
local activeWorldName = gameEvents:FindFirstChild("ActiveWorldName") or Instance.new("StringValue")
activeWorldName.Name  = "ActiveWorldName"
activeWorldName.Value = ""
activeWorldName.Parent = gameEvents

local activeWorldState = gameEvents:FindFirstChild("ActiveWorldState") or Instance.new("StringValue")
activeWorldState.Name  = "ActiveWorldState"
activeWorldState.Value = "Idle"
activeWorldState.Parent = gameEvents

-- BindableEvent: NPC scripts listen here to respawn on world restart
local worldRestartSignal = gameEvents:FindFirstChild("WorldRestartSignal") or Instance.new("BindableEvent")
worldRestartSignal.Name   = "WorldRestartSignal"
worldRestartSignal.Parent = gameEvents

-- BindableEvent: NPC scripts fire this when a player scores a personal hit
local playerScored = gameEvents:FindFirstChild("PlayerScored") or Instance.new("BindableEvent")
playerScored.Name   = "PlayerScored"
playerScored.Parent = gameEvents

local forceDinoDismount = gameEvents:FindFirstChild("ForceDinoDismount") or Instance.new("BindableEvent")
forceDinoDismount.Name = "ForceDinoDismount"
forceDinoDismount.Parent = gameEvents

local function getRemoteEvent(name)
	local event = gameEvents:FindFirstChild(name)
	if event and not event:IsA("RemoteEvent") then
		event:Destroy()
		event = nil
	end
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = gameEvents
	end
	return event
end

-- RemoteEvent: per-player HUD updates
-- Payload shapes:
--   "Enter"    worldName, remaining, total
--   "Progress" remaining, total
--   "Complete" worldName
--   "Launch" duration, upwardVelocity, airControlSpeed
--   "Countdown" secondsLeft  (fires every second during 1s launch window)
--   "Exit"     (player left world without completing)
local worldHudEvent = getRemoteEvent("WorldHud")
local stageRewardEvent = getRemoteEvent("StageReward")
local RESPAWN_AT_LAST_VISITED_WORLD = Balance.Gameplay and Balance.Gameplay.RespawnAtLastVisitedWorld == true

-- Legacy events kept so old client scripts don't error on WaitForChild
local _graceEvent = getRemoteEvent("LevelGraceCountdown")

local _bubbleEvent = getRemoteEvent("BubbleEvent")

-- ── World definitions ─────────────────────────────────────────────────────────

local WORLDS = {
	{ name = "Playground",        value = "BrainrotsRemaining",              total = "BrainrotsTotal",                   target = Balance.StageTargets.Playground,
	  bounds = { minX = -59,   maxX = 59,   minZ = -59,   maxZ = 59   } },
	{ name = "Empty World 1",    value = "EmptyWorld1NPCsRemaining",        total = "EmptyWorld1NPCsTotal",             target = Balance.StageTargets.EmptyWorld1,
	  bounds = { minX = -900,  maxX = -200, minZ = 1420,  maxZ = 1980 } },
	{ name = "Storm Dome",       value = "EmptyWorld2NPCsRemaining",        total = "EmptyWorld2NPCsTotal",             target = Balance.StageTargets.EmptyWorld2,
	  bounds = { minX = -1670, maxX = -970, minZ = 1420,  maxZ = 1980 } },
	{ name = "Volt Abyss",      value = "EmptyWorld3NPCsRemaining",        total = "EmptyWorld3NPCsTotal",             target = Balance.StageTargets.EmptyWorld3,
	  bounds = { minX = -2440, maxX = -1740, minZ = 1420, maxZ = 1980 } },
	{ name = "Neon Rift",       value = "EmptyWorld4NPCsRemaining",        total = "EmptyWorld4NPCsTotal",             target = Balance.StageTargets.EmptyWorld4,
	  bounds = { minX = -3210, maxX = -2510, minZ = 1420, maxZ = 1980 } },
	{ name = "Pizza",             value = "PizzaBrainrotsRemaining",         total = "PizzaBrainrotsTotal",              target = Balance.StageTargets.Pizza,
	  bounds = { minX = -72,   maxX = 72,   minZ = 132,   maxZ = 268  } },
	{ name = "Galactic",          value = "GalacticBrainrotsRemaining",      total = "GalacticBrainrotsTotal",           target = Balance.StageTargets.Galactic,
	  bounds = { minX = -70,   maxX = 70,   minZ = 385,   maxZ = 525  } },
	{ name = "Jungle",            value = "JungleAnimalsRemaining",          total = "JungleAnimalsTotal",               target = Balance.StageTargets.Jungle,
	  bounds = { minX = -70,   maxX = 70,   minZ = 640,   maxZ = 780  } },
	{ name = "Sports",            value = "SportsPlayersRemaining",          total = "SportsPlayersTotal",               target = Balance.StageTargets.Sports,
	  bounds = { minX = -82,   maxX = 82,   minZ = 860,   maxZ = 1020 } },
	{ name = "Tennis",            value = "TennisPlayersRemaining",          total = "TennisPlayersTotal",               target = Balance.StageTargets.Tennis,
	  bounds = { minX = -70,   maxX = 70,   minZ = 1090,  maxZ = 1230 } },
	{ name = "Game Station",      value = "GameStationBotsRemaining",        total = "GameStationBotsTotal",             target = Balance.StageTargets.GameStation,
	  bounds = { minX = -78,   maxX = 78,   minZ = 1300,  maxZ = 1460 } },
	{ name = "Coffee Shop",       value = "CoffeeBaristasRemaining",         total = "CoffeeBaristasTotal",              target = Balance.StageTargets.CoffeeShop,
	  bounds = { minX = -140,  maxX = 140,  minZ = 1540,  maxZ = 1860 } },
	{ name = "Burger House",      value = "BurgerCooksRemaining",            total = "BurgerCooksTotal",                 target = Balance.StageTargets.BurgerHouse,
	  bounds = { minX = 214,   maxX = 490,  minZ = 1540,  maxZ = 1860 } },
	{ name = "New Pizza Place",   value = "NewPizzaChefsRemaining",          total = "NewPizzaChefsTotal",               target = Balance.StageTargets.NewPizzaPlace,
	  bounds = { minX = 566,   maxX = 842,  minZ = 1540,  maxZ = 1860 } },
	{ name = "Swimming Pool",     value = "PoolBirdsRemaining",              total = "PoolBirdsTotal",                   target = Balance.StageTargets.SwimmingPool,
	  bounds = { minX = 918,   maxX = 1194, minZ = 1540,  maxZ = 1860 } },
	{ name = "Dinosaur Park",     value = "DinosaurDinosRemaining",          total = "DinosaurDinosTotal",               target = Balance.StageTargets.DinosaurPark,
	  bounds = { minX = 1270,  maxX = 1546, minZ = 1540,  maxZ = 1860 } },
	{ name = "Dino Beach",        value = "DinoBeachDinosRemaining",         total = "DinoBeachDinosTotal",              target = Balance.StageTargets.DinoBeach,
	  bounds = { minX = 1622,  maxX = 1898, minZ = 1540,  maxZ = 1860 } },
	{ name = "Flying Dino Forest",value = "FlyingDinoForestDinosRemaining",  total = "FlyingDinoForestDinosTotal",       target = Balance.StageTargets.FlyingDinoForest,
	  bounds = { minX = 1974,  maxX = 2250, minZ = 1540,  maxZ = 1860 } },
	{ name = "Cherry Grove",      value = "GiantDinoCherriesRemaining",      total = "GiantDinoCherriesTotal",           target = Balance.StageTargets.CherryGrove,
	  bounds = { minX = 2308,  maxX = 2620, minZ = 1380,  maxZ = 2020 } },
	{ name = "Galactic Orchard",  value = "GalacticFruitsRemaining",         total = "GalacticFruitsTotal",              target = Balance.StageTargets.GalacticOrchard,
	  bounds = { minX = 2660,  maxX = 2980, minZ = 1380,  maxZ = 2020 } },
	{ name = "Sky Vault",         value = "SkyVaultRemaining",               total = "SkyVaultTotal",                     target = Balance.StageTargets.SkyVault,
	  bounds = { minX = -3534, maxX = -3466, minZ = 1666, maxZ = 1734 } },
	{ name = "Storm Tower",      value = "StormTowerRemaining",             total = "StormTowerTotal",                   target = Balance.StageTargets.StormTower,
	  bounds = { minX = -3762, maxX = -3558, minZ = 1604, maxZ = 1796 } },
	{ name = "Frost Basin",      value = "FrostBasinRemaining",             total = "FrostBasinTotal",                   target = 1,
	  bounds = { minX = -2924, maxX = -2796, minZ = 2136, maxZ = 2264 } },
	{ name = "Ember Hold",       value = "EmberHoldRemaining",              total = "EmberHoldTotal",                    target = 1,
	  bounds = { minX = -2924, maxX = -2796, minZ = 2486, maxZ = 2614 } },
	{ name = "Nova Spire",       value = "NovaSpireRemaining",              total = "NovaSpireTotal",                    target = 1,
	  bounds = { minX = -2924, maxX = -2796, minZ = 2836, maxZ = 2964 } },
	{ name = "Prism Peak",      value = "PrismPeakRemaining",    total = "PrismPeakTotal",    target = 1,
	  bounds = { minX = -2919, maxX = -2801, minZ = 3141, maxZ = 3259 } },
	{ name = "Magma Core",      value = "MagmaCoreRemaining",    total = "MagmaCoreTotal",    target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 3431, maxZ = 3569 } },
	{ name = "Storm Circuit",   value = "StormCircuitRemaining", total = "StormCircuitTotal", target = 1,
	  bounds = { minX = -2934, maxX = -2786, minZ = 3771, maxZ = 3889 } },
	{ name = "Shadow Vault",    value = "ShadowVaultRemaining",  total = "ShadowVaultTotal",  target = 1,
	  bounds = { minX = -2924, maxX = -2796, minZ = 4066, maxZ = 4194 } },
	{ name = "Apex Nexus",      value = "ApexNexusRemaining",    total = "ApexNexusTotal",    target = 1,
	  bounds = { minX = -2944, maxX = -2776, minZ = 4366, maxZ = 4534 } },
	{ name = "Cloud Drift",    value = "CloudDriftRemaining",   total = "CloudDriftTotal",   target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 4691, maxZ = 4829 } },
	{ name = "Coral Reef",     value = "CoralReefRemaining",    total = "CoralReefTotal",    target = 1,
	  bounds = { minX = -2924, maxX = -2796, minZ = 4996, maxZ = 5124 } },
	{ name = "Bubble Bounce",  value = "BubbleBounceRemaining", total = "BubbleBounceTotal", target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 5271, maxZ = 5409 } },
	{ name = "Zen Garden",      value = "ZenGardenRemaining",       total = "ZenGardenTotal",       target = 1,
	  bounds = { minX = -2924, maxX = -2796, minZ = 5556, maxZ = 5684 } },
	{ name = "Crystal Spires", value = "CrystalSpiresRemaining",   total = "CrystalSpiresTotal",   target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 5831, maxZ = 5969 } },
	{ name = "Neon Triangle",  value = "NeonTriangleRemaining",    total = "NeonTriangleTotal",    target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 6116, maxZ = 6254 } },
	{ name = "Wide Canyon",    value = "WideCanyonRemaining",      total = "WideCanyonTotal",      target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 6401, maxZ = 6539 } },
	{ name = "Narrow Pass",    value = "NarrowPassRemaining",      total = "NarrowPassTotal",      target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 6686, maxZ = 6824 } },
	{ name = "Diamond Gate",   value = "DiamondGateRemaining",     total = "DiamondGateTotal",     target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 6971, maxZ = 7109 } },
	{ name = "Hourglass Vault",value = "HourglassVaultRemaining",  total = "HourglassVaultTotal",  target = 1,
	  bounds = { minX = -2929, maxX = -2791, minZ = 7256, maxZ = 7394 } },
	{ name = "Movement Lab",   value = "MovementLabRemaining",     total = "MovementLabTotal",      target = 1,
	  bounds = { minX = -2934, maxX = -2786, minZ = 7540, maxZ = 7680 } },
	{ name = "Fight Arena",    value = "FightArenaRemaining",       total = "FightArenaTotal",        target = 1,
	  bounds = { minX = -2990, maxX = -2730, minZ = 7990, maxZ = 8210 } },
	{ name = "Empty World 43", value = "EmptyWorld43Remaining",      total = "EmptyWorld43Total",       target = 4,
	  bounds = { minX = -2934, maxX = -2786, minZ = 8340, maxZ = 8480 } },
}

local byName     = {}
local byOrder    = {}
local nextWorld  = {}   -- nextWorld[worldName] = world (or nil for last)
for i, w in WORLDS do
	w.order = WorldOrder.getOrder(w.name) or i
end
table.sort(WORLDS, function(a, b)
	return (a.order or 9999) < (b.order or 9999)
end)
local orderedProgression = {}
for i, w in WORLDS do
	byName[w.name] = w
	if w.order then
		byOrder[w.order] = w
	end
	local mappedWorld = WorldOrder.getWorld(w.name)
	if not (mappedWorld and mappedWorld.optional) then
		table.insert(orderedProgression, w)
	end
end
for i, w in orderedProgression do
	if i < #orderedProgression then
		nextWorld[w.name] = orderedProgression[i + 1]
	end
end

local function getNextWorldFor(world)
	local mappedNextName = WorldOrder.getName((world.order or 0) + 1)
	if mappedNextName and byName[mappedNextName] then
		return byName[mappedNextName]
	end
	return nextWorld[world.name]
end

-- ── Per-player state ──────────────────────────────────────────────────────────

-- playerWorldState[player] = { world=world, entryTime=os.clock() } or nil
local playerWorldState  = {}
-- Players currently in the 1-second launch countdown (do not re-trigger completion)
local playerCompleting  = {}
local playerCompletionToken = {}
local characterConnections = {}
local worldSleeping = {}
local worldCompletedAt = {}

local COMPLETION_COUNTDOWN_SECONDS = 1
local COMPLETION_LAUNCH_VELOCITY = 320
local COMPLETION_AIR_CONTROL_SPEED = 46
local COMPLETION_DESCENT_SECONDS = 1
local STARTER_RETURN_CF = WorldOrder.getStarterRespawnCFrame()

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function isInside(player, world)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local pos = hrp.Position
	local b   = world.bounds
	return pos.X >= b.minX and pos.X <= b.maxX and pos.Z >= b.minZ and pos.Z <= b.maxZ
end

local function getWorldCenter(world)
	local b = world.bounds
	if world.name == "New Pizza Place" then
		return Vector3.new(590, 4, 1700)
	end
	return Vector3.new((b.minX + b.maxX) / 2, 4, (b.minZ + b.maxZ) / 2)
end

-- Per-world spawn offsets relative to each world's geometric center.
-- Only override worlds with known large structures at their center.
local WORLD_SPAWN_OFFSET = {
	Playground = { dx = 0, dz = -38 },  -- carousel at center; shift south to open area
	["Burger House"] = { dx = -128, dz = 0 }, -- avoid giant burger, soda prop, and left wall when auto-launching in
}

local WORLD_FIXED_SPAWN = {
	["Volt Abyss"] = Vector3.new(-2090, 8, 1580),
	["Frost Basin"] = Vector3.new(-2860, 8, 2162),
	["Nova Spire"] = Vector3.new(-2860, 8, 2862),
}

local function getValue(world)
	local v = gameEvents:FindFirstChild(world.value)
	return v and v:IsA("NumberValue") and v or nil
end

local function getTotal(world)
	local v = gameEvents:FindFirstChild(world.total)
	return v and v:IsA("NumberValue") and v or nil
end

-- Returns list of players currently inside a world
local function playersInWorld(world)
	local list = {}
	for player, state in playerWorldState do
		if state.world == world then
			table.insert(list, player)
		end
	end
	return list
end

local TARGET_PART_NAMES = {
	BirdBody = true,
	BirdCatchHitbox = true,
	BrainrotHitbox = true,
	DinoBody = true,
	DinoCatchHitbox = true,
	DinoHead = true,
	FlyingDinoBody = true,
	ReturnCatchHitbox = true,
}

local LOOSE_TARGET_NAMES = {
	CherryLeaf = true,
	CherryRing = true,
	CherryStem = true,
	DinoCherry = true,
	GalacticFruit = true,
	GalacticFruitLeaf = true,
	GalacticFruitRing = true,
	GalacticFruitStem = true,
}

local WORLD_EFFECT_CLASSES = {
	Beam = true,
	Fire = true,
	ParticleEmitter = true,
	Smoke = true,
	Sparkles = true,
	Trail = true,
}

local function isPointInsideWorld(world, position)
	local b = world.bounds
	return position.X >= b.minX and position.X <= b.maxX and position.Z >= b.minZ and position.Z <= b.maxZ
end

local function getObjectPosition(object)
	if object:IsA("BasePart") then
		return object.Position
	end
	if object:IsA("Attachment") and object.Parent and object.Parent:IsA("BasePart") then
		return object.WorldPosition
	end
	local model = object:FindFirstAncestorOfClass("Model")
	if model and not Players:GetPlayerFromCharacter(model) then
		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if ok then
			return pivot.Position
		end
	end
	local part = object:FindFirstAncestorWhichIsA("BasePart")
	return part and part.Position or nil
end

local function isTargetModel(model)
	if Players:GetPlayerFromCharacter(model) then return false end
	if model:FindFirstChildOfClass("Humanoid") then return true end
	local lowerName = model.Name:lower()
	if lowerName:find("bird") or lowerName:find("dino") or lowerName:find("bot") or lowerName:find("npc") then
		return true
	end
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") and TARGET_PART_NAMES[object.Name] then
			return true
		end
	end
	return false
end

local function silenceWorld(world)
	for _, object in workspace:GetDescendants() do
		if object:IsA("Sound") then
			local position = getObjectPosition(object)
			if position and isPointInsideWorld(world, position) then
				object:Stop()
				object:Destroy()
			end
		elseif WORLD_EFFECT_CLASSES[object.ClassName] then
			local position = getObjectPosition(object)
			if position and isPointInsideWorld(world, position) then
				if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
					object.Enabled = false
				end
				object:Destroy()
			end
		end
	end
end

local function clearWorldTargets(world)
	for _, object in workspace:GetDescendants() do
		if object:IsA("Model") and isTargetModel(object) then
			local ok, pivot = pcall(function()
				return object:GetPivot()
			end)
			if ok and isPointInsideWorld(world, pivot.Position) then
				object:Destroy()
			end
		elseif object:IsA("BasePart") and (LOOSE_TARGET_NAMES[object.Name] or object:GetAttribute("FruitColor") ~= nil) and isPointInsideWorld(world, object.Position) then
			object:Destroy()
		end
	end
end

local function sleepWorld(world)
	if worldSleeping[world.name] then return end
	worldSleeping[world.name] = true
	silenceWorld(world)
	clearWorldTargets(world)
	silenceWorld(world)
	if activeWorldName.Value == world.name and #playersInWorld(world) == 0 then
		activeWorldState.Value = "Idle"
		stageHits.Value = 0
	end
end

local function wakeWorld(world)
	if not worldSleeping[world.name] then return end
	worldSleeping[world.name] = nil
	worldCompletedAt[world.name] = nil
	worldRestartSignal:Fire(world.name)
	stageNeeded.Value = math.max(1, world.target or 1)
	stageHits.Value = 0
end

-- ── World completion (per-player) ─────────────────────────────────────────────

-- Finds the safest floor-level spawn position in a world.
-- Tests a 3×3 grid of candidates and picks whichever raycasts to the lowest Y
-- (= actual floor, not the top of a structure). Falls back to world center +10.
local _safeSpawnParams  -- lazily created so barrierFolder exists first
local function getSafeSpawnPosition(world)
	local configuredRespawn = WorldOrder.getRespawnCFrame(world.order or world.name)
	if configuredRespawn then
		return configuredRespawn.Position
	end

	local fixedSpawn = WORLD_FIXED_SPAWN[world.name]
	if fixedSpawn then
		return fixedSpawn
	end

	if not _safeSpawnParams then
		_safeSpawnParams = RaycastParams.new()
		_safeSpawnParams.FilterType = Enum.RaycastFilterType.Exclude
		_safeSpawnParams.FilterDescendantsInstances = { barrierFolder }
	end

	local b   = world.bounds
	local cx  = (b.minX + b.maxX) / 2
	local cz  = (b.minZ + b.maxZ) / 2

	-- Apply per-world relative offset to avoid known central obstacles
	local ov = WORLD_SPAWN_OFFSET[world.name]
	if ov then
		cx = cx + (ov.dx or 0)
		cz = cz + (ov.dz or 0)
	end

	-- 3×3 grid of candidate positions, 16 studs apart, clamped inside world bounds
	local STEP = 16
	local margin = 10
	local bestX, bestZ, bestHitY = cx, cz, nil

	for dxi = -1, 1 do
		for dzi = -1, 1 do
			local tx = math.clamp(cx + dxi * STEP, b.minX + margin, b.maxX - margin)
			local tz = math.clamp(cz + dzi * STEP, b.minZ + margin, b.maxZ - margin)
			local origin = Vector3.new(tx, 350, tz)
			local result = workspace:Raycast(origin, Vector3.new(0, -500, 0), _safeSpawnParams)
			if result then
				local hitY = result.Position.Y
				-- Prefer whichever candidate hits the lowest surface (= real floor, not a rooftop)
				if bestHitY == nil or hitY < bestHitY then
					bestHitY = hitY
					bestX    = tx
					bestZ    = tz
				end
			end
		end
	end

	local spawnY = (bestHitY or 1) + 5
	return Vector3.new(bestX, spawnY, bestZ)
end

local function getRespawnWorldForPlayer(player)
	if RESPAWN_AT_LAST_VISITED_WORLD then
		local lastOrder = tonumber(player:GetAttribute("LastVisitedWorldOrder"))
		if lastOrder and byOrder[lastOrder] then
			return byOrder[lastOrder]
		end
		local lastName = player:GetAttribute("LastVisitedWorldName")
		if type(lastName) == "string" and byName[lastName] then
			return byName[lastName]
		end
	end
	return WORLDS[1]
end

local function getPlayerRespawnCFrame(player)
	local configuredRespawn = WorldOrder.getConfiguredPlayerRespawnCFrame()
	if configuredRespawn then
		return configuredRespawn
	end

	local respawnWorld = getRespawnWorldForPlayer(player)
	return CFrame.new(getSafeSpawnPosition(respawnWorld))
end

local skyDescent = require(script.Parent:WaitForChild("SkyDescent"))

local function teleportToNextWorld(player, nw)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	skyDescent(hrp, CFrame.new(getSafeSpawnPosition(nw)), nw.bounds, COMPLETION_DESCENT_SECONDS)
end

local function teleportToStarterRoom(player)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	player:SetAttribute("InLandingWorld", true)
	player:SetAttribute("CompletionAirLaunchActive", false)
	player:SetAttribute("SkyDescentBoundsActive", false)
	hrp.CFrame = STARTER_RETURN_CF
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end

local function getStat(player, name)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	local value = stats:FindFirstChild(name)
	if not value then
		value = Instance.new("IntValue")
		value.Name = name
		value.Value = 0
		value.Parent = stats
	end
	return value
end

local function awardStageRewards(player, world)
	if not player:GetAttribute("DataLoaded") then
		local started = os.clock()
		while player.Parent and not player:GetAttribute("DataLoaded") and os.clock() - started < 5 do
			task.wait(0.1)
		end
	end
	local requiredHits = math.max(0, math.floor(world.target or stageNeeded.Value or 0))
	local crownsAwarded = math.floor(requiredHits / 10)
	local crowns   = getStat(player, "Crowns")
	local trophies = getStat(player, "Trophies")

	-- +1 per-level crown and total win counter
	local order = WorldOrder.getOrder(world.name)
	if order then
		local key = "LevelCrown_" .. tostring(order)
		player:SetAttribute(key, (player:GetAttribute(key) or 0) + 1)
		crownsAwarded += 1
	end

	-- Trophy every 5 total level wins
	local totalWins = (player:GetAttribute("TotalLevelWins") or 0) + 1
	player:SetAttribute("TotalLevelWins", totalWins)
	local trophiesAwarded = (totalWins % 5 == 0) and 1 or 0

	crowns.Value   += crownsAwarded
	trophies.Value += trophiesAwarded
	stageRewardEvent:FireClient(player, world.name, crownsAwarded, trophiesAwarded, crowns.Value, trophies.Value)
end

local function launchPlayerForCompletion(player, duration)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp then return end

	hrp.Anchored = false
	hrp.AssemblyAngularVelocity = Vector3.zero
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.AutoRotate = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	local currentVelocity = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, COMPLETION_LAUNCH_VELOCITY, currentVelocity.Z)
	player:SetAttribute("CompletionAirLaunchActive", true)

	local started = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not player.Parent or not hrp.Parent then
			if conn then conn:Disconnect() end
			if player.Parent then
				player:SetAttribute("CompletionAirLaunchActive", false)
			end
			return
		end

		if os.clock() - started >= duration then
			if conn then conn:Disconnect() end
			if player.Parent then
				player:SetAttribute("CompletionAirLaunchActive", false)
			end
			return
		end

		local moveDir = humanoid and humanoid.MoveDirection or Vector3.zero
		if moveDir.Magnitude > 0.05 then
			local velocity = hrp.AssemblyLinearVelocity
			local desired = moveDir.Unit * COMPLETION_AIR_CONTROL_SPEED
			hrp.AssemblyLinearVelocity = Vector3.new(desired.X, velocity.Y, desired.Z)
		end
	end)
end

local function onPlayerCompleteWorld(player, world)
	if playerCompleting[player] then return end
	local activeToken = playerCompletionToken[player]
	local worldToken = world.name .. ":" .. tostring(worldCompletedAt[world.name] or "")
	if activeToken == worldToken then return end
	playerCompletionToken[player] = worldToken
	playerCompleting[player] = true

	awardStageRewards(player, world)
	worldHudEvent:FireClient(player, "Complete", world.name)

	local nw = getNextWorldFor(world)
	if not nw then
		local currentOrder = player:GetAttribute("CheckpointOrder") or 1
		if (world.order or currentOrder) > currentOrder then
			player:SetAttribute("CheckpointOrder", world.order)
			player:SetAttribute("CheckpointName", world.name)
		end

		playerWorldState[player] = nil
		player:SetAttribute("PersonalHits", 0)
		player:SetAttribute("PersonalTarget", 0)
		worldHudEvent:FireClient(player, "GameComplete")
		task.wait(1.5)
		if player.Parent then
			teleportToStarterRoom(player)
			worldHudEvent:FireClient(player, "Exit")
		end
		if #playersInWorld(world) == 0 then
			sleepWorld(world)
		end
		playerCompleting[player] = nil
		return
	end

	player:SetAttribute("CompletionAirLaunchActive", true)
	forceDinoDismount:Fire(player)

	-- Launch upward during the short countdown, then teleport to the next stage.
	worldHudEvent:FireClient(player, "Launch", COMPLETION_COUNTDOWN_SECONDS, COMPLETION_LAUNCH_VELOCITY, COMPLETION_AIR_CONTROL_SPEED)
	launchPlayerForCompletion(player, COMPLETION_COUNTDOWN_SECONDS)
	for i = COMPLETION_COUNTDOWN_SECONDS, 1, -1 do
		worldHudEvent:FireClient(player, "Countdown", i)
		task.wait(1)
	end

	-- Check player is still alive/in game
	if not player.Parent then
		playerCompleting[player] = nil
		return
	end
	local nw = getNextWorldFor(world)
	if nw then
		local currentOrder = player:GetAttribute("CheckpointOrder") or 1
		if (nw.order or currentOrder) > currentOrder then
			player:SetAttribute("CheckpointOrder", nw.order)
			player:SetAttribute("CheckpointName", nw.name)
		end
		playerWorldState[player] = nil
		player:SetAttribute("PersonalHits", 0)
		player:SetAttribute("PersonalTarget", 0)
		teleportToNextWorld(player, nw)
		task.delay(COMPLETION_DESCENT_SECONDS + 0.5, function()
			if player.Parent then
				playerCompleting[player] = nil
			end
		end)
		-- The Heartbeat will detect the world change and fire "Enter" for the new world
	else
		local currentOrder = player:GetAttribute("CheckpointOrder") or 1
		if (world.order or currentOrder) > currentOrder then
			player:SetAttribute("CheckpointOrder", world.order)
			player:SetAttribute("CheckpointName", world.name)
		end
		-- Last world — just celebrate, no next level
		worldHudEvent:FireClient(player, "GameComplete")
		playerCompleting[player] = nil
	end
end

-- ── World NPC completion watcher ──────────────────────────────────────────────

-- worldCompletedAt[worldName] = true while NPCs are 0 (prevents double-fire)

local function onWorldNPCsDepleted(world)
	if worldCompletedAt[world.name] then return end
	worldCompletedAt[world.name] = true

	-- Update legacy shared state
	activeWorldName.Value  = world.name
	activeWorldState.Value = "Complete"
	stageNeeded.Value = math.max(1, world.target or 1)
	stageHits.Value = stageNeeded.Value

	-- For each player currently in this world, run their personal completion flow
	for _, player in playersInWorld(world) do
		task.spawn(onPlayerCompleteWorld, player, world)
	end

	if #playersInWorld(world) == 0 then
		sleepWorld(world)
	end
end

-- Per-player scoring: NPC scripts fire PlayerScored with (player, worldName)
playerScored.Event:Connect(function(player, worldName)
	if player:GetAttribute("SkyDescentBoundsActive") then return end
	local state = playerWorldState[player]
	if not state or state.world.name ~= worldName then return end
	if playerCompleting[player] then return end
	state.hits = (state.hits or 0) + 1
	local target = state.world.target or 1
	player:SetAttribute("PersonalHits", state.hits)
	player:SetAttribute("PersonalTarget", target)
	if state.hits >= target then
		task.spawn(onPlayerCompleteWorld, player, state.world)
	end
end)

-- ── Heartbeat: detect world transitions ───────────────────────────────────────

local prevWorldByPlayer = {}  -- prevWorldByPlayer[player] = world or nil

RunService.Heartbeat:Connect(function()
	for _, player in Players:GetPlayers() do
		if playerCompleting[player] then continue end
		if player:GetAttribute("SkyDescentBoundsActive") then continue end

		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")

		local currentWorld = nil
		if hrp then
			local pos = hrp.Position
			for _, world in WORLDS do
				local b = world.bounds
				if pos.X >= b.minX and pos.X <= b.maxX and pos.Z >= b.minZ and pos.Z <= b.maxZ then
					currentWorld = world
					break
				end
			end
		end

		local prevWorld = prevWorldByPlayer[player]
		if currentWorld == prevWorld then continue end
		prevWorldByPlayer[player] = currentWorld

		-- Left previous world
		if prevWorld and prevWorld ~= currentWorld then
			local state = playerWorldState[player]
			if state and state.world == prevWorld then
				playerWorldState[player] = nil
			end
			if #playersInWorld(prevWorld) == 0 then
				sleepWorld(prevWorld)
			end
			worldHudEvent:FireClient(player, "Exit")
		end

		-- Entered new world
		if currentWorld then
			player:SetAttribute("LastVisitedWorldOrder", currentWorld.order or 1)
			player:SetAttribute("LastVisitedWorldName", currentWorld.name)
			if RESPAWN_AT_LAST_VISITED_WORLD then
				player:SetAttribute("UseStarterRespawn", false)
				player:SetAttribute("InLandingWorld", false)
			end
			wakeWorld(currentWorld)
			local target = currentWorld.target or 1
			playerCompletionToken[player] = nil
			playerWorldState[player] = { world = currentWorld, hits = 0 }
			player:SetAttribute("PersonalHits", 0)
			player:SetAttribute("PersonalTarget", target)

			local remVal = getValue(currentWorld)
			local totVal = getTotal(currentWorld)
			local rem    = remVal and remVal.Value or 0
			local tot    = totVal and totVal.Value or 0

			worldHudEvent:FireClient(player, "Enter", currentWorld.name, rem, tot)

			-- Update legacy shared state to the world with the most players
			activeWorldName.Value  = currentWorld.name
			activeWorldState.Value = "Running"
			stageNeeded.Value = math.max(1, currentWorld.target or 1)
			stageHits.Value = math.clamp(tot - rem, 0, stageNeeded.Value)

			-- Restart NPCs if the world was already completed (rem == 0) so player has a fresh run
			if rem <= 0 and not worldCompletedAt[currentWorld.name] then
				worldRestartSignal:Fire(currentWorld.name)
				if totVal and totVal.Value > 0 then
					if remVal then remVal.Value = totVal.Value end
				end
				stageHits.Value = 0
				worldCompletedAt[currentWorld.name] = nil
			end
		end
	end
end)

-- ── Broadcast NPC progress to players in the same world ──────────────────────

task.spawn(function()
	task.wait(3)
	for _, world in WORLDS do
		if #playersInWorld(world) == 0 then
			sleepWorld(world)
		end
	end
end)

local function broadcastProgress(world)
	local remVal = getValue(world)
	local totVal = getTotal(world)
	local rem    = remVal and remVal.Value or 0
	local tot    = totVal and totVal.Value or 0
	for _, player in playersInWorld(world) do
		worldHudEvent:FireClient(player, "Progress", rem, tot)
	end
end

for _, world in WORLDS do
	local capturedWorld = world
	task.spawn(function()
		local value = gameEvents:WaitForChild(world.value, 40)
		if not value or not value:IsA("NumberValue") then return end
		value.Changed:Connect(function()
			broadcastProgress(capturedWorld)
		end)
	end)
end

-- ── Invisible barrier walls around every world ───────────────────────────────

local barrierFolder = workspace:FindFirstChild("WorldBarriers")
if not barrierFolder then
	barrierFolder = Instance.new("Folder")
	barrierFolder.Name = "WorldBarriers"
	barrierFolder.Parent = workspace
else
	barrierFolder:ClearAllChildren()
end

local WALL_HEIGHT     = 1200  -- tall enough to contain the finish launch and sky descent
local WALL_THICKNESS  = 8
local WALL_Y_CENTER   = WALL_HEIGHT / 2  -- pivot at ground level
local DOOR_HALF_WIDTH  = 11
local SIDE_DOOR_HALF_WIDTH = 25
local DOOR_FRAME_HEIGHT = 16

local BARRIER_OPENINGS = {
	Playground = {
		south = { center = 0, half = DOOR_HALF_WIDTH },
		west = { center = 0, half = 16 },
	},
	["Empty World 1"] = {
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Storm Dome"] = {
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Volt Abyss"] = {
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Neon Rift"] = {
		east  = { center = 1700,  half = SIDE_DOOR_HALF_WIDTH },
		west  = { center = 1700,  half = SIDE_DOOR_HALF_WIDTH },
		north = { center = -2860, half = 42 },
		south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Sky Vault"] = {
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Storm Tower"] = {
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	Pizza = {
		north = { center = 0, half = DOOR_HALF_WIDTH },
		south = { center = 0, half = DOOR_HALF_WIDTH },
	},
	Galactic = {
		north = { center = 0, half = DOOR_HALF_WIDTH },
		south = { center = 0, half = DOOR_HALF_WIDTH },
	},
	Jungle = {
		north = { center = 0, half = DOOR_HALF_WIDTH },
		south = { center = 0, half = DOOR_HALF_WIDTH },
	},
	Sports = {
		north = { center = 0, half = DOOR_HALF_WIDTH },
		south = { center = 0, half = DOOR_HALF_WIDTH },
	},
	Tennis = {
		north = { center = 0, half = DOOR_HALF_WIDTH },
		south = { center = 0, half = DOOR_HALF_WIDTH },
	},
	["Game Station"] = {
		north = { center = 0, half = DOOR_HALF_WIDTH },
		south = { center = 0, half = DOOR_HALF_WIDTH },
	},
	["Coffee Shop"] = {
		north = { center = 0, half = DOOR_HALF_WIDTH },
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Burger House"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["New Pizza Place"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Swimming Pool"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Dinosaur Park"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Dino Beach"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Flying Dino Forest"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Cherry Grove"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Galactic Orchard"] = {
		west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH },
		east = { center = 1700, half = 42 },
	},
	["Frost Basin"] = {
		north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH },
		south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH },
	},
	["Ember Hold"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Nova Spire"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Prism Peak"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Magma Core"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Storm Circuit"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Shadow Vault"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Apex Nexus"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Cloud Drift"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Coral Reef"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Bubble Bounce"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Zen Garden"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Crystal Spires"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Neon Triangle"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Wide Canyon"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Narrow Pass"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Diamond Gate"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Hourglass Vault"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Movement Lab"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Fight Arena"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
		south = { center = -2860, half = DOOR_HALF_WIDTH },
	},
	["Empty World 43"] = {
		north = { center = -2860, half = DOOR_HALF_WIDTH },
	},
}

local function buildWorldBarriers(world)
	local b = world.bounds

	local function makeBarrier(size, pos)
		local p = Instance.new("Part")
		p.Name         = world.name:gsub("%s+", "") .. "Barrier"
		p.Size         = size
		p.CFrame       = CFrame.new(pos)
		p.Anchored     = true
		p.CanCollide   = true
		p.Transparency = 1
		p.CastShadow   = false
		p.CanTouch     = false
		p.Parent       = barrierFolder
	end

	local function addSegmentedWall(minA, maxA, fixed, axis, opening)
		local function addSegment(fromA, toA, segmentHeight, segmentY)
			local length = toA - fromA
			if length <= 0 then return end
			local centerA = (fromA + toA) / 2
			segmentHeight = segmentHeight or WALL_HEIGHT
			segmentY = segmentY or WALL_Y_CENTER
			if axis == "X" then
				makeBarrier(Vector3.new(length, segmentHeight, WALL_THICKNESS), Vector3.new(centerA, segmentY, fixed))
			else
				makeBarrier(Vector3.new(WALL_THICKNESS, segmentHeight, length), Vector3.new(fixed, segmentY, centerA))
			end
		end

		if not opening then
			addSegment(minA, maxA)
			return
		end

		local gapMin = math.max(minA, opening.center - opening.half)
		local gapMax = math.min(maxA, opening.center + opening.half)
		addSegment(minA, gapMin)
		addSegment(gapMax, maxA)
		local topHeight = math.max(0, WALL_HEIGHT - DOOR_FRAME_HEIGHT)
		if topHeight > 0 then
			addSegment(gapMin, gapMax, topHeight, DOOR_FRAME_HEIGHT + topHeight / 2)
		end
	end

	local openings = BARRIER_OPENINGS[world.name] or {}
	addSegmentedWall(b.minX - WALL_THICKNESS / 2, b.maxX + WALL_THICKNESS / 2, b.maxZ + WALL_THICKNESS / 2, "X", openings.south)
	addSegmentedWall(b.minX - WALL_THICKNESS / 2, b.maxX + WALL_THICKNESS / 2, b.minZ - WALL_THICKNESS / 2, "X", openings.north)
	addSegmentedWall(b.minZ - WALL_THICKNESS / 2, b.maxZ + WALL_THICKNESS / 2, b.maxX + WALL_THICKNESS / 2, "Z", openings.east)
	addSegmentedWall(b.minZ - WALL_THICKNESS / 2, b.maxZ + WALL_THICKNESS / 2, b.minX - WALL_THICKNESS / 2, "Z", openings.west)
end

for _, world in WORLDS do
	buildWorldBarriers(world)
end

-- ── Teleport new players into the first world on join ─────────────────────────

Players.PlayerAdded:Connect(function(player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end
	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.wait(0.5)   -- let physics settle
		if player:GetAttribute("InLandingWorld") and not WorldOrder.getConfiguredPlayerRespawnCFrame() then return end
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			hrp.CFrame = getPlayerRespawnCFrame(player)
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	end)
end)

-- ── Continuously destroy legacy gate Parts created by NPC scripts ─────────────

-- Only match legacy gate Part names that NPC scripts used to create.
-- Do NOT match "Blocker"/"JumpPad" — WorldJumpBlockers uses "...JumpBlocker" names.
local LEGACY_GATE_NAMES = {
	BridgeGate = true, BridgeGateBlocker = true,
	PizzaGate = true, PizzaGateBlocker = true,
	GalacticGate = true, GateBlocker = true, JumpPad = true,
	JungleGate = true,
	SportsGate = true, SportsGateBlocker = true, SportsJumpPad = true,
	TennisGate = true, TennisGateBlocker = true, TennisJumpPad = true,
	GameStationGate = true, GameStationGateBlocker = true,
	CoffeeGate = true, CoffeeGateBlocker = true,
	BurgerGate = true, BurgerGateBlocker = true,
	NewPizzaGate = true, NewPizzaGateBlocker = true,
	PoolGate = true, PoolGateBlocker = true,
	DinosaurGate = true, DinosaurGateBlocker = true,
	DinoBeachGate = true, DinoBeachGateBlocker = true,
	FlyingDinoForestGate = true, FlyingDinoForestGateBlocker = true,
	GiantDinoCherryGate = true, GiantDinoCherryGateBlocker = true,
	GalacticFruitGate = true, GalacticFruitGateBlocker = true,
	SkyVaultGate = true, SkyVaultGateBlocker = true,
	StormTowerGate = true, StormTowerGateBlocker = true,
	FrostBasinGate = true, FrostBasinGateBlocker = true,
	EmberHoldGate = true, EmberHoldGateBlocker = true,
	NovaSpireGate = true, NovaSpireGateBlocker = true,
	PrismPeakGate = true, PrismPeakGateBlocker = true,
	MagmaCoreGate = true, MagmaCoreGateBlocker = true,
	StormCircuitGate = true, StormCircuitGateBlocker = true,
	ShadowVaultGate = true, ShadowVaultGateBlocker = true,
	ApexNexusGate = true, ApexNexusGateBlocker = true,
	CloudDriftGate = true, CloudDriftGateBlocker = true,
	CoralReefGate = true, CoralReefGateBlocker = true,
	BubbleBounceGate = true, BubbleBounceGateBlocker = true,
	ZenGardenGate = true, ZenGardenGateBlocker = true,
	SouthDoorBlock = true, NorthDoorBlock = true, EastDoorBlock = true, WestDoorBlock = true,
	DoorBlock = true, DoorBlocker = true,
}

local function isGatePart(obj)
	return obj:IsA("BasePart") and LEGACY_GATE_NAMES[obj.Name] == true
end

-- Destroy any that already exist (NPC scripts run before us)
task.spawn(function()
	task.wait(1)
	for _, obj in workspace:GetDescendants() do
		if isGatePart(obj) then obj:Destroy() end
	end
end)

-- Destroy new ones the instant they're parented to workspace
workspace.DescendantAdded:Connect(function(obj)
	if isGatePart(obj) then
		task.defer(function()
			if obj.Parent then obj:Destroy() end
		end)
	end
end)

-- ── Player cleanup ────────────────────────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
	local state = playerWorldState[player]
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end
	playerWorldState[player]  = nil
	playerCompleting[player]  = nil
	prevWorldByPlayer[player] = nil
	if state and #playersInWorld(state.world) == 0 then
		sleepWorld(state.world)
	end
end)

print("[WorldManager] Per-player world tracking ready — no doors.")
