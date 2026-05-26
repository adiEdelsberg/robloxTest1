local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local NPC = require(ServerStorage:WaitForChild("NPCModule"))
local BoundaryService = require(ServerStorage:WaitForChild("WorldBoundaryService"))
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")
local activeWorldName = gameEvents:FindFirstChild("ActiveWorldName") or Instance.new("StringValue")
activeWorldName.Name = "ActiveWorldName"
activeWorldName.Value = activeWorldName.Value or ""
activeWorldName.Parent = gameEvents

local activeWorldState = gameEvents:FindFirstChild("ActiveWorldState") or Instance.new("StringValue")
activeWorldState.Name = "ActiveWorldState"
activeWorldState.Value = activeWorldState.Value ~= "" and activeWorldState.Value or "Idle"
activeWorldState.Parent = gameEvents

local oldFolder = workspace:FindFirstChild("WorldReentryRespawn")
if oldFolder then
	oldFolder:Destroy()
end

-- Disabled: WorldRunDoors.server.luau is the single owner of level starts,
-- scoring, target reset, and completion launches. Keeping this legacy loop
-- active can complete the same run through shared StageHits and cause stacked launches.
if true then return end

local folder = Instance.new("Folder")
folder.Name = "WorldReentryRespawn"
folder.Parent = workspace

local activeByWorld = {}
local modelToWorld = {}
local cooldown = {}
local insideByPlayer = {}
local reentryGate = {}
local exitedSinceCleared = {} -- [worldName] = true once all players have left after completion

local WORLDS = {
	{ name = "Playground",        order = 1,  type = "humanoid",    value = "BrainrotsRemaining",          total = "BrainrotsTotal",          target = Balance.StageTargets.Playground,    count = 8,  axis = "Z", x = 0,    z = 61,   bounds = { minX = -59,  maxX = 59,   minZ = -59,  maxZ = 59   }, color = "Bright red" },
	{ name = "Pizza",             order = 2,  type = "humanoid",    value = "PizzaBrainrotsRemaining",     total = "PizzaBrainrotsTotal",     target = Balance.StageTargets.Pizza,         count = 8,  axis = "Z", x = 0,    z = 130,  bounds = { minX = -72,  maxX = 72,   minZ = 132,  maxZ = 268  }, color = "Bright orange" },
	{ name = "Galactic",          order = 3,  type = "humanoid",    value = "GalacticBrainrotsRemaining",  total = "GalacticBrainrotsTotal",  target = Balance.StageTargets.Galactic,      count = 9,  axis = "Z", x = 0,    z = 385,  bounds = { minX = -70,  maxX = 70,   minZ = 385,  maxZ = 525  }, color = "Bright violet" },
	{ name = "Jungle",            order = 4,  type = "humanoid",    value = "JungleAnimalsRemaining",      total = "JungleAnimalsTotal",      target = Balance.StageTargets.Jungle,        count = 9,  axis = "Z", x = 0,    z = 640,  bounds = { minX = -70,  maxX = 70,   minZ = 640,  maxZ = 780  }, color = "Bright green" },
	{ name = "Sports",            order = 5,  type = "humanoid",    value = "SportsPlayersRemaining",      total = "SportsPlayersTotal",      target = Balance.StageTargets.Sports,        count = 8,  axis = "Z", x = 0,    z = 860,  bounds = { minX = -82,  maxX = 82,   minZ = 860,  maxZ = 1020 }, color = "Bright yellow" },
	{ name = "Tennis",            order = 6,  type = "humanoid",    value = "TennisPlayersRemaining",      total = "TennisPlayersTotal",      target = Balance.StageTargets.Tennis,        count = 10, axis = "Z", x = 0,    z = 1090, bounds = { minX = -70,  maxX = 70,   minZ = 1090, maxZ = 1230 }, color = "Lime green" },
	{ name = "Game Station",      order = 7,  type = "humanoid",    value = "GameStationBotsRemaining",    total = "GameStationBotsTotal",    target = Balance.StageTargets.GameStation,   count = 7,  axis = "Z", x = 0,    z = 1300, bounds = { minX = -78,  maxX = 78,   minZ = 1300, maxZ = 1460 }, color = "Cyan" },
	{ name = "Coffee Shop",       order = 8,  type = "flying",      value = "CoffeeBaristasRemaining",     total = "CoffeeBaristasTotal",     target = Balance.StageTargets.CoffeeShop,   count = 12, axis = "Z", x = 0,    z = 1540, bounds = { minX = -140, maxX = 140,  minZ = 1540, maxZ = 1860 }, color = "Bright orange" },
	{ name = "Burger House",      order = 9,  type = "flying",      value = "BurgerCooksRemaining",        total = "BurgerCooksTotal",        target = Balance.StageTargets.BurgerHouse,  count = 12, axis = "X", x = 214,  z = 1700, bounds = { minX = 214,  maxX = 490,  minZ = 1540, maxZ = 1860 }, color = "Bright yellow" },
	{ name = "New Pizza",         order = 10, type = "flying",      value = "NewPizzaChefsRemaining",      total = "NewPizzaChefsTotal",      target = Balance.StageTargets.NewPizzaPlace, count = 12, axis = "X", x = 566,  z = 1700, bounds = { minX = 566,  maxX = 842,  minZ = 1540, maxZ = 1860 }, color = "Bright red" },
	{ name = "Swimming Pool",     order = 11, type = "flying",      value = "PoolBirdsRemaining",          total = "PoolBirdsTotal",          target = Balance.StageTargets.SwimmingPool, count = 12, axis = "X", x = 918,  z = 1700, bounds = { minX = 918,  maxX = 1194, minZ = 1540, maxZ = 1860 }, color = "Cyan" },
	{ name = "Dinosaur Park",     order = 12, type = "groundDino",  value = "DinosaurDinosRemaining",      total = "DinosaurDinosTotal",      target = Balance.StageTargets.DinosaurPark, count = 10, axis = "X", x = 1270, z = 1700, bounds = { minX = 1270, maxX = 1546, minZ = 1540, maxZ = 1860 }, color = "Bright green" },
	{ name = "Dino Beach",        order = 13, type = "groundDino",  value = "DinoBeachDinosRemaining",     total = "DinoBeachDinosTotal",     target = Balance.StageTargets.DinoBeach,    count = 10, axis = "X", x = 1622, z = 1700, bounds = { minX = 1622, maxX = 1898, minZ = 1540, maxZ = 1860 }, color = "Bright yellow" },
	{ name = "Flying Dino Forest",order = 14, type = "flyingDino",  value = "FlyingDinoForestDinosRemaining", total = "FlyingDinoForestDinosTotal", target = Balance.StageTargets.FlyingDinoForest, count = 10, axis = "X", x = 1974, z = 1700, bounds = { minX = 1974, maxX = 2250, minZ = 1540, maxZ = 1860 }, color = "Bright green" },
	{ name = "Cherry Grove",      order = 15, type = "cherries",    value = "GiantDinoCherriesRemaining",  total = "GiantDinoCherriesTotal",  target = Balance.StageTargets.CherryGrove,  count = 6,  axis = "X", x = 2308, z = 1700, bounds = { minX = 2308, maxX = 2620, minZ = 1380, maxZ = 2020 }, color = "Really red" },
	{ name = "Galactic Orchard",  order = 16, type = "galacticFruit", value = "GalacticFruitsRemaining",   total = "GalacticFruitsTotal",     target = Balance.StageTargets.GalacticOrchard, count = 8, axis = "X", x = 2660, z = 1700, bounds = { minX = 2660, maxX = 2980, minZ = 1380, maxZ = 2020 }, color = "Cyan" },
}

local worldByName = {}
for _, world in WORLDS do
	world.order = WorldOrder.getOrder(world.name) or world.order
	worldByName[world.name] = world
end
table.sort(WORLDS, function(a, b)
	return (a.order or 9999) < (b.order or 9999)
end)
worldByName["New Pizza Place"] = worldByName["New Pizza"]

local function getValue(name)
	return gameEvents:FindFirstChild(name)
end

local function clearWorld(world)
	local active = activeByWorld[world.name]
	if not active then return end
	for item in active do
		modelToWorld[item] = nil
		if item.Parent then item:Destroy() end
	end
	activeByWorld[world.name] = nil
end

local function destroyReentryGate(world)
	local gp = reentryGate[world.name]
	if gp and gp.Parent then gp:Destroy() end
	reentryGate[world.name] = nil
end

local function createReentryGate(world)
	destroyReentryGate(world)
	-- WorldRunDoors owns the visible/colliding doors. Re-entry only respawns targets.
end

local function openReentryGate(world)
	local gp = reentryGate[world.name]
	if not gp or not gp.Parent then return end
	reentryGate[world.name] = nil
	TweenService:Create(gp,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = gp.CFrame + Vector3.new(0, 16, 0), Transparency = 1 }
	):Play()
	task.delay(1.3, function()
		if gp.Parent then gp:Destroy() end
	end)
end

local function clearReentryWorld(world)
	destroyReentryGate(world)
	clearWorld(world)
	-- Reset remaining to 0 so worldWasCleared stays true after cleanup,
	-- and mark that the player has exited so re-entry can trigger again.
	local remaining = getValue(world.value)
	if remaining then remaining.Value = 0 end
	exitedSinceCleared[world.name] = true
end

local function addActive(world, item)
	activeByWorld[world.name] = activeByWorld[world.name] or {}
	activeByWorld[world.name][item] = true
	modelToWorld[item] = world
end

local function pruneActiveWorld(world)
	local active = activeByWorld[world.name]
	if not active then return nil end
	local hasLiveItem = false
	for item in active do
		if item.Parent then
			hasLiveItem = true
		else
			active[item] = nil
			modelToWorld[item] = nil
		end
	end
	if not hasLiveItem then
		activeByWorld[world.name] = nil
		return nil
	end
	return active
end

local function randomPoint(bounds)
	return math.random(bounds.minX, bounds.maxX), math.random(bounds.minZ, bounds.maxZ)
end

local function setCounters(world)
	local remaining = getValue(world.value)
	local total = getValue(world.total)
	if total then total.Value = world.count end
	if remaining then remaining.Value = world.count end
	stageNeeded.Value = math.max(1, world.target or 1)
	stageHits.Value = 0
end

local function rewardCash(player, amount)
	local stats = player and player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	if cash then cash.Value += amount end
end

local function completeWorldRun(world)
	local remaining = getValue(world.value)
	if remaining then remaining.Value = 0 end
	openReentryGate(world)
end

local function decrementWorld(world, item, catcher)
	local active = activeByWorld[world.name]
	if not active or not active[item] then return end
	if activeWorldName.Value == world.name and activeWorldState.Value ~= "Running" then return end
	active[item] = nil
	modelToWorld[item] = nil
	if catcher then
		rewardCash(catcher, math.max(60, world.order * 22))
	end
	for _, object in item:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanTouch = false
			TweenService:Create(object, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.24, function()
		if item.Parent then item:Destroy() end
	end)
	if activeWorldName.Value == world.name and activeWorldState.Value == "Running" then
		stageHits.Value = math.min(stageNeeded.Value, stageHits.Value + 1)
		if stageHits.Value >= stageNeeded.Value then
			completeWorldRun(world)
			return
		end
	end
	if next(active) == nil then
		completeWorldRun(world)
	end
end

local function spawnHumanoids(world)
	for index = 1, world.count do
		local x, z = randomPoint(world.bounds)
		local data = {
			name = world.name .. " Return NPC " .. index,
			bodyColor = world.color,
			headColor = "Nougat",
			maxHp = 8 + math.floor(index / 3),
			minSpeed = 18,
			maxSpeed = 34,
			minJump = 55,
			maxJump = 95,
			jumpChance = 0.25,
			minJumpWait = 2,
			maxJumpWait = 5,
			spawnX = x,
			spawnZ = z,
		}
		local model, humanoid = NPC.createNPC(data)
		addActive(world, model)
		NPC.startWander(model, humanoid, data, world.bounds)
	end
end

local function makePart(parent, name, size, cf, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = true
	p.CastShadow = false
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function attachCatch(model, part, world)
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			decrementWorld(world, model, player)
		end
	end)
end

local function spawnFlying(world, dinoStyle)
	for index = 1, world.count do
		local x, z = randomPoint(world.bounds)
		local y = 16 + ((index - 1) % 6) * 9
		local model = Instance.new("Model")
		model.Name = world.name .. (dinoStyle and " Flying Dino " or " Bird ") .. index
		model.Parent = folder
		local cf = CFrame.new(x, y, z)
		local body = makePart(model, dinoStyle and "FlyingDinoBody" or "BirdBody", Vector3.new(7, 3.5, 4.5), cf, world.color, Enum.PartType.Ball)
		makePart(model, "Head", Vector3.new(3, 2.4, 2.4), cf * CFrame.new(4.4, 1.2, 0), world.color, Enum.PartType.Ball)
		makePart(model, "Snout", Vector3.new(2.2, 0.9, 1.3), cf * CFrame.new(6.2, 1.05, 0), "Bright yellow")
		makePart(model, "LeftWing", Vector3.new(0.5, 0.22, 10), cf * CFrame.new(0, 0, -5.2), "Cyan")
		makePart(model, "RightWing", Vector3.new(0.5, 0.22, 10), cf * CFrame.new(0, 0, 5.2), "Cyan")
		local hitbox = makePart(model, "ReturnCatchHitbox", Vector3.new(11, 7, 13), cf, world.color)
		hitbox.Transparency = 1
		model.PrimaryPart = body
		addActive(world, model)
		BoundaryService.bindModel(model, world.bounds, { margin = 7, minY = 8, maxY = 112 })
		attachCatch(model, body, world)
		attachCatch(model, hitbox, world)
		task.spawn(function()
			while activeByWorld[world.name] and activeByWorld[world.name][model] and model.Parent do
				local value = Instance.new("CFrameValue")
				value.Value = model:GetPivot()
				local conn = value.Changed:Connect(function(cf2)
					if model.Parent then model:PivotTo(cf2) end
				end)
				local tx, tz = randomPoint(world.bounds)
				local target = CFrame.new(tx, 14 + math.random() * 80, tz)
				local tween = TweenService:Create(value, TweenInfo.new(math.random(35, 70) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = target })
				tween:Play()
				tween.Completed:Wait()
				conn:Disconnect()
				value:Destroy()
			end
		end)
	end
end

local function spawnGroundDinos(world)
	for index = 1, world.count do
		local x, z = randomPoint(world.bounds)
		local model = Instance.new("Model")
		model.Name = world.name .. " Return Dino " .. index
		model.Parent = folder
		local cf = CFrame.new(x, 5, z)
		local body = makePart(model, "DinoBody", Vector3.new(9, 4.5, 5), cf, world.color, Enum.PartType.Ball)
		makePart(model, "DinoHead", Vector3.new(4, 3, 3), cf * CFrame.new(6, 2.6, 0), world.color, Enum.PartType.Ball)
		makePart(model, "Tail", Vector3.new(6, 1.2, 1.2), cf * CFrame.new(-6, 0.5, 0), world.color)
		local hitbox = makePart(model, "ReturnCatchHitbox", Vector3.new(12, 8, 8), cf * CFrame.new(1, 0, 0), world.color)
		hitbox.Transparency = 1
		model.PrimaryPart = body
		addActive(world, model)
		BoundaryService.bindModel(model, world.bounds, { margin = 8, minY = 4, maxY = 24 })
		attachCatch(model, body, world)
		attachCatch(model, hitbox, world)
		task.spawn(function()
			while activeByWorld[world.name] and activeByWorld[world.name][model] and model.Parent do
				local value = Instance.new("CFrameValue")
				value.Value = model:GetPivot()
				local conn = value.Changed:Connect(function(cf2)
					if model.Parent then model:PivotTo(cf2) end
				end)
				local tx, tz = randomPoint(world.bounds)
				local target = CFrame.new(tx, 5, tz)
				local tween = TweenService:Create(value, TweenInfo.new(math.random(30, 55) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = target })
				tween:Play()
				tween.Completed:Wait()
				conn:Disconnect()
				value:Destroy()
				task.wait(0.1)
			end
		end)
	end
end

local function spawnCherries(world)
	local positions = {
		Vector3.new(2348, 34, 1428),
		Vector3.new(2572, 36, 1510),
		Vector3.new(2390, 54, 1660),
		Vector3.new(2558, 58, 1768),
		Vector3.new(2362, 78, 1896),
		Vector3.new(2556, 84, 1974),
	}
	for index = 1, world.count do
		local cherry = makePart(folder, "DinoCherry", Vector3.new(4.8, 4.8, 4.8), CFrame.new(positions[index]), "Really red", Enum.PartType.Ball)
		addActive(world, cherry)
		cherry.Touched:Connect(function(hit)
			if hit.Name ~= "GiantDinoHead" then return end
			-- Find which player is riding the dino that touched this cherry
			local dinoModel = hit.Parent
			local rider = nil
			if dinoModel then
				for _, player in Players:GetPlayers() do
					if player:GetAttribute("RidingGiantDino") and player.Character then
						local hrp = player.Character:FindFirstChild("HumanoidRootPart")
						if hrp and (hrp.Position - dinoModel:GetPivot().Position).Magnitude < 60 then
							rider = player
							break
						end
					end
				end
			end
			decrementWorld(world, cherry, rider)
		end)
	end
end

local function spawnGalacticFruit(world)
	local positions = {
		{ Vector3.new(2710, 40, 1415), "Cyan"       },
		{ Vector3.new(2930, 38, 1460), "Cyan"       },
		{ Vector3.new(2748, 62, 1618), "Hot pink"   },
		{ Vector3.new(2906, 66, 1710), "Hot pink"   },
		{ Vector3.new(2762, 70, 1808), "Hot pink"   },
		{ Vector3.new(2718, 90, 1908), "New Yeller" },
		{ Vector3.new(2948, 96, 1952), "New Yeller" },
		{ Vector3.new(2836, 104, 1992), "New Yeller" },
	}
	for index = 1, world.count do
		local fruit = makePart(folder, "GalacticFruit", Vector3.new(7.5, 7.5, 7.5), CFrame.new(positions[index][1]), positions[index][2], Enum.PartType.Ball)
		addActive(world, fruit)
		fruit.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				decrementWorld(world, fruit, player)
			elseif hit.Name == "GiantDinoHead" and hit.Parent then
				local dinoModel = hit.Parent
				for _, p in Players:GetPlayers() do
					if p:GetAttribute("RidingGiantDino") and p.Character then
						local hrp = p.Character:FindFirstChild("HumanoidRootPart")
						if hrp and (hrp.Position - dinoModel:GetPivot().Position).Magnitude < 60 then
							decrementWorld(world, fruit, p)
							break
						end
					end
				end
			end
		end)
	end
end

local function respawnWorld(world)
	exitedSinceCleared[world.name] = nil
	clearWorld(world)
	createReentryGate(world)
	setCounters(world)
	if world.type == "humanoid" then
		spawnHumanoids(world)
	elseif world.type == "flying" then
		spawnFlying(world, false)
	elseif world.type == "flyingDino" then
		spawnFlying(world, true)
	elseif world.type == "groundDino" then
		spawnGroundDinos(world)
	elseif world.type == "cherries" then
		spawnCherries(world)
	elseif world.type == "galacticFruit" then
		spawnGalacticFruit(world)
	end
end

local function hasActiveWorld(world)
	return pruneActiveWorld(world) ~= nil
end

local function worldWasCleared(world)
	local remaining = getValue(world.value)
	local total = getValue(world.total)
	-- A world is "clearable" for re-entry only if its counter dropped below the initial total
	-- (i.e. at least one NPC was defeated). If remaining >= total the world is fresh/unplayed.
	if not remaining then return false end
	if total and remaining.Value > 0 and remaining.Value >= total.Value then return false end
	return true
end

local function tryRespawnActiveWorld()
	if activeWorldState.Value ~= "Running" then return end
	local world = worldByName[activeWorldName.Value]
	if not world or hasActiveWorld(world) then return end
	if not worldWasCleared(world) then return end
	if not exitedSinceCleared[world.name] then return end
	cooldown[world.name] = os.clock()
	respawnWorld(world)
end

local function isPlayerInsideWorld(player, world)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local pos = hrp.Position
	local bounds = world.bounds
	local margin = 3
	return pos.X >= bounds.minX - margin
		and pos.X <= bounds.maxX + margin
		and pos.Z >= bounds.minZ - margin
		and pos.Z <= bounds.maxZ + margin
end

local function canReenterWorld(player, world)
	if (player:GetAttribute("CheckpointOrder") or 0) < world.order then return false end
	local remaining = getValue(world.value)
	local total = getValue(world.total)
	if not remaining then return false end
	if remaining.Value > 0 and total and remaining.Value >= total.Value then return false end
	local now = os.clock()
	return not cooldown[world.name] or now - cooldown[world.name] >= 0.75
end

NPC.OnNPCDefeated:Connect(function(model)
	local world = modelToWorld[model]
	if not world then return end
	local pivot = model:GetPivot()
	local nearest, nearestDist = nil, 28
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = (hrp.Position - pivot.Position).Magnitude
			if d < nearestDist then nearest, nearestDist = player, d end
		end
	end
	decrementWorld(world, model, nearest)
end)

local function buildTrigger(world)
	local trigger = Instance.new("Part")
	trigger.Name = world.name:gsub("%s+", "") .. "ReentryTrigger"
	trigger.Size = world.axis == "X" and Vector3.new(5, 12, 28) or Vector3.new(28, 12, 5)
	trigger.CFrame = CFrame.new(world.x, 7, world.z)
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.Transparency = 1
	trigger.Parent = folder
	trigger.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then return end
		if hasActiveWorld(world) then return end
		if not insideByPlayer[player] or insideByPlayer[player][world.name] then return end
		if not exitedSinceCleared[world.name] then return end
		if not canReenterWorld(player, world) then return end
		cooldown[world.name] = os.clock()
		respawnWorld(world)
	end)
end

for _, world in WORLDS do
	buildTrigger(world)
end

activeWorldName.Changed:Connect(function()
	task.defer(tryRespawnActiveWorld)
end)
activeWorldState.Changed:Connect(function()
	task.defer(tryRespawnActiveWorld)
end)

local function anyPlayerInsideWorld(world)
	for _, player in Players:GetPlayers() do
		if isPlayerInsideWorld(player, world) then return true end
	end
	return false
end

RunService.Heartbeat:Connect(function()
	for _, player in Players:GetPlayers() do
		insideByPlayer[player] = insideByPlayer[player] or {}
		for _, world in WORLDS do
			local wasInside = insideByPlayer[player][world.name] == true
			local isInside = isPlayerInsideWorld(player, world)
			insideByPlayer[player][world.name] = isInside

			if wasInside and not isInside then
				-- Player just left this world
				if hasActiveWorld(world) then
					if not anyPlayerInsideWorld(world) then
						clearReentryWorld(world)
						cooldown[world.name] = os.clock()
					end
				elseif worldWasCleared(world) and not anyPlayerInsideWorld(world) then
					-- No re-entry NPCs, but world was cleared — player exited after completing
					exitedSinceCleared[world.name] = true
				end
			elseif isInside and not hasActiveWorld(world) and activeWorldName.Value == world.name and activeWorldState.Value == "Running" and worldWasCleared(world) and exitedSinceCleared[world.name] then
				cooldown[world.name] = os.clock()
				respawnWorld(world)
			elseif isInside and not wasInside and not hasActiveWorld(world) and exitedSinceCleared[world.name] and canReenterWorld(player, world) then
				cooldown[world.name] = os.clock()
				respawnWorld(world)
			end
		end
	end

	tryRespawnActiveWorld()

	-- Safety net: clear any active world with no players inside
	for _, world in WORLDS do
		if not hasActiveWorld(world) then continue end
		if not anyPlayerInsideWorld(world) then
			clearReentryWorld(world)
			cooldown[world.name] = os.clock()
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	insideByPlayer[player] = nil
end)

print("[WorldReentryRespawn] Re-entry NPC respawn triggers ready.")
