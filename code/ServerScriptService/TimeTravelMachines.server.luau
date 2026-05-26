local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local skyDescent = require(script.Parent:WaitForChild("SkyDescent"))
local SafeLevelSpawn = require(script.Parent:WaitForChild("SafeLevelSpawn"))
local STAGE_LAUNCH_DESCENT_SECONDS = 1
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local G = 1
local IS_PROD = Balance.ActiveMode == "prod"

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)

local folder = Instance.new("Folder")
folder.Name = "TimeTravelMachines"
folder.Parent = workspace

local DESTINATIONS = {
	{
		name = "Playground",    order = 1,  spawn = CFrame.new(0, 7, 0),
		color = "Bright blue",    labelColor = Color3.fromRGB(80, 170, 255),
		ownRemaining = "BrainrotsRemaining",               ownTotal = "BrainrotsTotal",
		unlocks = {},             completes = {},
	},
	{
		name = "Empty World 1", order = 17, spawn = CFrame.new(-550, 8, 1700),
		color = "Really red",     labelColor = Color3.fromRGB(255, 80, 80),
		ownRemaining = "EmptyWorld1NPCsRemaining",          ownTotal = "EmptyWorld1NPCsTotal",
		unlocks = { "BridgeGate" },
		completes = { "BrainrotsRemaining" },
	},
	{
		name = "Storm Dome",    order = 18, spawn = CFrame.new(-1320, 8, 1700),
		color = "New Yeller",     labelColor = Color3.fromRGB(255, 220, 30),
		ownRemaining = "EmptyWorld2NPCsRemaining",          ownTotal = "EmptyWorld2NPCsTotal",
		unlocks = { "BridgeGate" },
		completes = { "BrainrotsRemaining" },
	},
	{
		name = "Volt Abyss",    order = 19, spawn = CFrame.new(-2090, 8, 1580),
		color = "Hot pink",       labelColor = Color3.fromRGB(255, 80, 180),
		ownRemaining = "EmptyWorld3NPCsRemaining",          ownTotal = "EmptyWorld3NPCsTotal",
		unlocks = { "BridgeGate" },
		completes = { "BrainrotsRemaining" },
	},
	{
		name = "Neon Rift",    order = 20, spawn = CFrame.new(-2860, 8, 1700),
		color = "Cyan",           labelColor = Color3.fromRGB(0, 220, 255),
		ownRemaining = "EmptyWorld4NPCsRemaining",          ownTotal = "EmptyWorld4NPCsTotal",
		unlocks = { "BridgeGate" },
		completes = { "BrainrotsRemaining" },
	},
	{
		name = "Sky Vault",    order = 21, spawn = CFrame.new(-3500, 8, 1700),
		color = "Bright yellow",  labelColor = Color3.fromRGB(255, 215, 0),
		ownRemaining = "SkyVaultRemaining",                 ownTotal = "SkyVaultTotal",
		unlocks = { "BridgeGate" },
		completes = { "BrainrotsRemaining" },
	},
	{
		name = "Pizza",         order = 5,  spawn = CFrame.new(0, 7, 142),
		color = "Bright orange",  labelColor = Color3.fromRGB(255, 150, 55),
		ownRemaining = "PizzaBrainrotsRemaining",          ownTotal = "PizzaBrainrotsTotal",
		unlocks = { "BridgeGate" },
		completes = { "BrainrotsRemaining" },
	},
	{
		name = "Galactic",      order = 3,  spawn = CFrame.new(0, 8, 398),
		color = "Bright violet",  labelColor = Color3.fromRGB(190, 90, 255),
		ownRemaining = "GalacticBrainrotsRemaining",       ownTotal = "GalacticBrainrotsTotal",
		unlocks = { "BridgeGate", "PizzaGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining" },
	},
	{
		name = "Jungle",        order = 4,  spawn = CFrame.new(0, 8, 652),
		color = "Bright green",   labelColor = Color3.fromRGB(100, 255, 110),
		ownRemaining = "JungleAnimalsRemaining",           ownTotal = "JungleAnimalsTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining" },
	},
	{
		name = "Sports",        order = 5,  spawn = CFrame.new(0, 8, 872),
		color = "Bright yellow",  labelColor = Color3.fromRGB(255, 220, 70),
		ownRemaining = "SportsPlayersRemaining",           ownTotal = "SportsPlayersTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining" },
	},
	{
		name = "Tennis",        order = 6,  spawn = CFrame.new(0, 8, 1102),
		color = "Lime green",     labelColor = Color3.fromRGB(150, 255, 85),
		ownRemaining = "TennisPlayersRemaining",           ownTotal = "TennisPlayersTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining" },
	},
	{
		name = "Game Station",  order = 7,  spawn = CFrame.new(0, 8, 1312),
		color = "Cyan",           labelColor = Color3.fromRGB(80, 220, 255),
		ownRemaining = "GameStationBotsRemaining",         ownTotal = "GameStationBotsTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining" },
	},
	{
		name = "Coffee Shop",   order = 8,  spawn = CFrame.new(0, 8, 1558),
		color = "Bright orange",  labelColor = Color3.fromRGB(255, 190, 80),
		ownRemaining = "CoffeeBaristasRemaining",          ownTotal = "CoffeeBaristasTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining" },
	},
	{
		name = "Burger House",  order = 9,  spawn = CFrame.new(224, 8, 1700),
		color = "Bright yellow",  labelColor = Color3.fromRGB(255, 225, 70),
		ownRemaining = "BurgerCooksRemaining",             ownTotal = "BurgerCooksTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining" },
	},
	{
		name = "New Pizza",     order = 10, spawn = CFrame.new(590, 8, 1700),
		color = "Bright red",     labelColor = Color3.fromRGB(255, 120, 80),
		ownRemaining = "NewPizzaChefsRemaining",           ownTotal = "NewPizzaChefsTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate", "BurgerGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining", "BurgerCooksRemaining" },
	},
	{
		name = "Swimming Pool", order = 11, spawn = CFrame.new(918, 8, 1700),
		color = "Cyan",           labelColor = Color3.fromRGB(80, 220, 255),
		ownRemaining = "PoolBirdsRemaining",               ownTotal = "PoolBirdsTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate", "BurgerGate", "NewPizzaGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining", "BurgerCooksRemaining", "NewPizzaChefsRemaining" },
	},
	{
		name = "Dinosaur Park", order = 12, spawn = CFrame.new(1270, 8, 1700),
		color = "Bright green",   labelColor = Color3.fromRGB(100, 255, 110),
		ownRemaining = "DinosaurDinosRemaining",           ownTotal = "DinosaurDinosTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate", "BurgerGate", "NewPizzaGate", "PoolGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining", "BurgerCooksRemaining", "NewPizzaChefsRemaining", "PoolBirdsRemaining" },
	},
	{
		name = "Dino Beach",    order = 13, spawn = CFrame.new(1622, 8, 1700),
		color = "Bright yellow",  labelColor = Color3.fromRGB(255, 230, 90),
		ownRemaining = "DinoBeachDinosRemaining",          ownTotal = "DinoBeachDinosTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate", "BurgerGate", "NewPizzaGate", "PoolGate", "DinosaurGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining", "BurgerCooksRemaining", "NewPizzaChefsRemaining", "PoolBirdsRemaining", "DinosaurDinosRemaining" },
	},
	{
		name = "Flying Dino Forest", order = 14, spawn = CFrame.new(1974, 8, 1700),
		color = "Bright green",   labelColor = Color3.fromRGB(100, 255, 110),
		ownRemaining = "FlyingDinoForestDinosRemaining",  ownTotal = "FlyingDinoForestDinosTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate", "BurgerGate", "NewPizzaGate", "PoolGate", "DinosaurGate", "DinoBeachGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining", "BurgerCooksRemaining", "NewPizzaChefsRemaining", "PoolBirdsRemaining", "DinosaurDinosRemaining", "DinoBeachDinosRemaining" },
	},
	{
		name = "Cherry Grove",  order = 15, spawn = CFrame.new(2326, 8, 1700),
		color = "Really red",     labelColor = Color3.fromRGB(255, 80, 80),
		ownRemaining = "GiantDinoCherriesRemaining",       ownTotal = "GiantDinoCherriesTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate", "BurgerGate", "NewPizzaGate", "PoolGate", "DinosaurGate", "DinoBeachGate", "FlyingDinoForestGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining", "BurgerCooksRemaining", "NewPizzaChefsRemaining", "PoolBirdsRemaining", "DinosaurDinosRemaining", "DinoBeachDinosRemaining", "FlyingDinoForestDinosRemaining" },
	},
	{
		name = "Galactic Orchard", order = 16, spawn = CFrame.new(2678, 8, 1700),
		color = "Cyan",           labelColor = Color3.fromRGB(80, 240, 255),
		ownRemaining = "GalacticFruitsRemaining",          ownTotal = "GalacticFruitsTotal",
		unlocks = { "BridgeGate", "PizzaGate", "GalacticGate", "JungleGate", "SportsGate", "TennisGate", "GameStationGate", "CoffeeGate", "BurgerGate", "NewPizzaGate", "PoolGate", "DinosaurGate", "DinoBeachGate", "FlyingDinoForestGate", "GiantDinoCherryGate" },
		completes = { "BrainrotsRemaining", "PizzaBrainrotsRemaining", "GalacticBrainrotsRemaining", "JungleAnimalsRemaining", "SportsPlayersRemaining", "TennisPlayersRemaining", "GameStationBotsRemaining", "CoffeeBaristasRemaining", "BurgerCooksRemaining", "NewPizzaChefsRemaining", "PoolBirdsRemaining", "DinosaurDinosRemaining", "DinoBeachDinosRemaining", "FlyingDinoForestDinosRemaining", "GiantDinoCherriesRemaining" },
	},
}

local GATE_Z = {
	BridgeGate = 61,
	PizzaGate = 272,
	GalacticGate = 524,
	JungleGate = 781,
	SportsGate = 1021,
	TennisGate = 1231,
	GameStationGate = 1460,
}

for _, destination in DESTINATIONS do
	destination.order = WorldOrder.getOrder(destination.name) or destination.order
	destination.displayName = WorldOrder.formatCanonical(destination.name)
end
for _, destination in DESTINATIONS do
	local completes = {}
	for _, previous in DESTINATIONS do
		if previous.ownRemaining and previous.order < destination.order then
			table.insert(completes, previous.ownRemaining)
		end
	end
	destination.completes = completes
end

local function p(name, size, pos, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local function cylinder(name, size, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local function addLabel(parent, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 210, 0, 76)
	gui.StudsOffset = Vector3.new(0, 4.6, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end

local function forceOpenGate(gateName)
	local gate = workspace:FindFirstChild(gateName)
	if gate and gate:IsA("BasePart") then
		gate.CanCollide = false
		gate.Transparency = 1
		gate:Destroy()
	end

	for _, object in workspace:GetChildren() do
		if object:IsA("BasePart") and object.Name:find("GateBlocker") then
			local gatePrefix = gateName:gsub("Gate", "")
			local isRelated = object.Name:find(gatePrefix) ~= nil
			local gateZ = GATE_Z[gateName]
			local closeEnough = gateZ and math.abs(object.Position.Z - gateZ) < 4
			if isRelated or closeEnough then
				object.CanCollide = false
				object:Destroy()
			end
		end
	end
end

local function completePreviousStages(destination)
	local gameEvents = ReplicatedStorage:FindFirstChild("GameEvents")
	if not gameEvents then return end

	for _, valueName in destination.completes do
		local value = gameEvents:FindFirstChild(valueName)
		if value and value:IsA("NumberValue") then
			value.Value = 0
		end
	end

	local stageHits = gameEvents:FindFirstChild("StageHits")
	if stageHits and stageHits:IsA("NumberValue") then
		stageHits.Value = 0
	end
end

local function sendPlayer(player, destination)
	local currentOrder = player:GetAttribute("CheckpointOrder") or 1
	if IS_PROD and destination.order > currentOrder then
		return
	end

	if not IS_PROD then
		completePreviousStages(destination)

		if destination.order > currentOrder then
			player:SetAttribute("CheckpointOrder", destination.order)
			player:SetAttribute("CheckpointName", destination.name)
		end
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then
		-- Face +Z for main-path stages, +X for bird-world stages (order 9+)
		local facingCF = destination.order >= 9
			and CFrame.Angles(0, -math.pi / 2, 0)
			or  CFrame.Angles(0, math.pi, 0)
		local safeSpawn = SafeLevelSpawn.getCFrame(destination.order, destination.name, destination.spawn)
		skyDescent(hrp, safeSpawn * facingCF, SafeLevelSpawn.getBounds(destination.order, destination.name), STAGE_LAUNCH_DESCENT_SECONDS)
	end
end

-- Outside area behind the playground, connected by a tunnel through the north fence.
task.spawn(function()
	task.wait(1)
	local corridorWhitelist = {
		TunnelFloor = true,
		TunnelGlow = true,
		TunnelLeftWall = true,
		TunnelRightWall = true,
		TunnelRoof = true,
		TunnelRib = true,
		TunnelRibL = true,
		TunnelRibR = true,
	}
	for _, object in workspace:GetDescendants() do
		if object:IsA("BasePart") then
			local pos = object.Position
			local inTunnelPath = math.abs(pos.X) <= 6 and pos.Z <= -52 and pos.Z >= -112 and pos.Y <= 12
			local isTunnelPart = object:IsDescendantOf(folder) and corridorWhitelist[object.Name]
			local nearTunnel = math.abs(pos.X) <= 8 and math.abs(pos.Z + 59) <= 3 and pos.Y <= 6
			local crossesTunnel = math.abs(pos.Z + 59) <= 1 and object.Size.X >= 20 and object.Position.Y <= 6
			if (nearTunnel or crossesTunnel or inTunnelPath) and not isTunnelPart then
				object.CanCollide = false
				object.Transparency = math.max(object.Transparency, 0.65)
			end
		end
	end
end)

p("TunnelFloor", Vector3.new(14, 0.4, 54), Vector3.new(0, G + 0.2, -78), "Medium stone grey", Enum.Material.Concrete)
p("TunnelGlow", Vector3.new(11, 0.12, 49), Vector3.new(0, G + 0.48, -78), "Cyan", Enum.Material.Neon, 0.78, true)
p("TunnelLeftWall", Vector3.new(0.6, 7, 54), Vector3.new(-7, G + 3.5, -78), "Really black", Enum.Material.Metal, 0.12)
p("TunnelRightWall", Vector3.new(0.6, 7, 54), Vector3.new(7, G + 3.5, -78), "Really black", Enum.Material.Metal, 0.12)
p("TunnelRoof", Vector3.new(14, 0.6, 54), Vector3.new(0, G + 7.2, -78), "Really black", Enum.Material.Metal, 0.18)
for z = -56, -100, -11 do
	p("TunnelRib", Vector3.new(15, 0.5, 0.5), Vector3.new(0, G + 7.6, z), "Cyan", Enum.Material.Neon, 0.12, true)
	p("TunnelRibL", Vector3.new(0.45, 7.2, 0.45), Vector3.new(-7.3, G + 3.6, z), "Cyan", Enum.Material.Neon, 0.2, true)
	p("TunnelRibR", Vector3.new(0.45, 7.2, 0.45), Vector3.new(7.3, G + 3.6, z), "Cyan", Enum.Material.Neon, 0.2, true)
end

local HUB_X = 0
local HUB_Z1 = -425
local HUB_Z2 = -105
local HUB_ZC = (HUB_Z1 + HUB_Z2) / 2
local HUB_W = 312
local HUB_D = HUB_Z2 - HUB_Z1

p("TimeTravelFloor", Vector3.new(HUB_W, 0.45, HUB_D), Vector3.new(HUB_X, G + 0.12, HUB_ZC), "Really black", Enum.Material.Metal)
p("TimeTravelGlow", Vector3.new(HUB_W - 12, 0.12, HUB_D - 12), Vector3.new(HUB_X, G + 0.42, HUB_ZC), "Cyan", Enum.Material.Neon, 0.82, true)

p("TimeTravelBackWall", Vector3.new(HUB_W, 28, 0.6), Vector3.new(HUB_X, G + 14, HUB_Z1), "Really black", Enum.Material.Metal, 0.12)
p("TimeTravelLeftWall", Vector3.new(0.6, 28, HUB_D), Vector3.new(-HUB_W / 2, G + 14, HUB_ZC), "Really black", Enum.Material.Metal, 0.12)
p("TimeTravelRightWall", Vector3.new(0.6, 28, HUB_D), Vector3.new(HUB_W / 2, G + 14, HUB_ZC), "Really black", Enum.Material.Metal, 0.12)

for z = HUB_Z1 + 18, HUB_Z2 - 18, 16 do
	p("TimeTravelFloorStripe", Vector3.new(HUB_W - 18, 0.08, 0.35), Vector3.new(HUB_X, G + 0.55, z), "Bright blue", Enum.Material.Neon, 0.7, true)
end
for x = -140, 140, 20 do
	p("TimeTravelBackBeam", Vector3.new(0.45, 27, 0.45), Vector3.new(x, G + 13.5, HUB_Z1 + 0.4), "Cyan", Enum.Material.Neon, 0.32, true)
end
for z = HUB_Z1 + 24, HUB_Z2 - 12, 28 do
	p("LeftWallBeam", Vector3.new(0.45, 27, 0.45), Vector3.new(-HUB_W / 2 + 0.4, G + 13.5, z), "Cyan", Enum.Material.Neon, 0.34, true)
	p("RightWallBeam", Vector3.new(0.45, 27, 0.45), Vector3.new(HUB_W / 2 - 0.4, G + 13.5, z), "Cyan", Enum.Material.Neon, 0.34, true)
end

local title = p("TimeTravelSign", Vector3.new(70, 4.5, 0.5), Vector3.new(0, G + 12, HUB_Z1 + 3), "Really black", Enum.Material.SmoothPlastic, 0, true)
addLabel(title, "TIME TRAVEL MACHINES", Color3.fromRGB(80, 220, 255))

-- Front wall with doorway gap matching the tunnel entrance (14 studs wide)
do
	local doorHalfW = 8
	local doorH     = 8   -- matches tunnel roof height
	local wallH     = 28
	local sideW     = HUB_W / 2 - doorHalfW  -- 148
	p("TimeTravelFrontWallL",   Vector3.new(sideW, wallH, 0.6),          Vector3.new(-(doorHalfW + sideW/2), G + wallH/2, HUB_Z2),          "Really black", Enum.Material.Metal, 0.12)
	p("TimeTravelFrontWallR",   Vector3.new(sideW, wallH, 0.6),          Vector3.new(  doorHalfW + sideW/2,  G + wallH/2, HUB_Z2),          "Really black", Enum.Material.Metal, 0.12)
	p("TimeTravelFrontWallTop", Vector3.new(doorHalfW*2, wallH-doorH, 0.6), Vector3.new(0, G + doorH + (wallH-doorH)/2, HUB_Z2),            "Really black", Enum.Material.Metal, 0.12)
	-- Doorway glow trim
	p("TimeTravelDoorGlowL",    Vector3.new(0.3, doorH, 0.3),            Vector3.new(-doorHalfW, G + doorH/2, HUB_Z2),                      "Cyan", Enum.Material.Neon, 0.15, true)
	p("TimeTravelDoorGlowR",    Vector3.new(0.3, doorH, 0.3),            Vector3.new( doorHalfW, G + doorH/2, HUB_Z2),                      "Cyan", Enum.Material.Neon, 0.15, true)
	p("TimeTravelDoorGlowTop",  Vector3.new(doorHalfW*2, 0.3, 0.3),      Vector3.new(0, G + doorH, HUB_Z2),                                 "Cyan", Enum.Material.Neon, 0.15, true)
end

local COLS = 5
local COL_SPACING = 56
local ROW_SPACING = 74

for index, destination in DESTINATIONS do
	local row        = math.floor((index - 1) / COLS)
	local col        = (index - 1) % COLS
	local x          = -math.floor(COLS / 2) * COL_SPACING + col * COL_SPACING  -- -112, -56, 0, 56, 112
	local z          = -382 + row * ROW_SPACING
	local floorY     = G

	-- ── Travel machine (teleport only) ──────────────────────────────────────
	local base = cylinder("MachineBase", Vector3.new(0.5, 9, 9), CFrame.new(x, floorY + 0.35, z) * CFrame.Angles(0, 0, math.rad(90)), destination.color, Enum.Material.Neon, 0.18, true)
	local ring = cylinder("TimeRing",    Vector3.new(0.35, 8.2, 8.2), CFrame.new(x, floorY + 4.7, z) * CFrame.Angles(math.rad(90), 0, 0), destination.color, Enum.Material.Neon, 0.08, true)
	local core = p("TimeCore",           Vector3.new(4.2, 6.8, 0.5), Vector3.new(x, floorY + 4.6, z), "Really black", Enum.Material.SmoothPlastic, 0.08, true)
	local glow = p("TimePortalGlow",     Vector3.new(3.3, 5.8, 0.25), Vector3.new(x, floorY + 4.6, z - 0.35), destination.color, Enum.Material.Neon, 0.38, true)

	addLabel(core, "LVL " .. destination.order .. "\n" .. (destination.displayName or destination.name), destination.labelColor)

	local travelPrompt = Instance.new("ProximityPrompt")
	travelPrompt.ActionText = "Travel"
	travelPrompt.ObjectText = destination.displayName or destination.name
	travelPrompt.KeyboardKeyCode = Enum.KeyCode.E
	travelPrompt.MaxActivationDistance = 10
	travelPrompt.RequiresLineOfSight = false
	travelPrompt.Parent = core
	travelPrompt:SetAttribute("DestinationOrder", destination.order)

	local travelDebounce = {}
	travelPrompt.Triggered:Connect(function(player)
		local now = os.clock()
		if travelDebounce[player] and now - travelDebounce[player] < 1 then return end
		travelDebounce[player] = now
		sendPlayer(player, destination)
	end)

	local pad = p("TravelPad", Vector3.new(9, 0.2, 7), Vector3.new(x, floorY + 0.55, z + 6), destination.color, Enum.Material.Neon, 0.35, true)
	local padSel = Instance.new("SelectionBox")
	padSel.Adornee = pad
	padSel.Color3 = destination.labelColor
	padSel.LineThickness = 0.08
	padSel.SurfaceTransparency = 0.82
	padSel.Parent = pad

	base.Name = destination.name:gsub("%s+", "") .. "MachineBase"
	ring.Name = destination.name:gsub("%s+", "") .. "TimeRing"
	glow.Name = destination.name:gsub("%s+", "") .. "TimePortalGlow"

	for _, obj in { base, ring, core, glow, pad } do
		obj:SetAttribute("TimeMachinePart", true)
		obj:SetAttribute("DestinationOrder", destination.order)
	end
	if false then

	-- ── Launch machine (restart level + teleport) ────────────────────────────
	-- Sits at z-9 (behind the travel machine, deeper in the hub).
	-- Only visible for levels the player has reached (same visibility rule as travel machines).
	local lx, lz = x, z - 9

	local launchPillar = cylinder(
		destination.name:gsub("%s+","") .. "LaunchPillar",
		Vector3.new(0.4, 7, 7),
		CFrame.new(lx, floorY + 0.3, lz) * CFrame.Angles(0, 0, math.rad(90)),
		"Bright green", Enum.Material.Neon, 0.22, true)

	local launchCore = p(
		destination.name:gsub("%s+","") .. "LaunchCore",
		Vector3.new(3.5, 5.5, 0.5),
		Vector3.new(lx, floorY + 3.8, lz),
		"Really black", Enum.Material.SmoothPlastic, 0.08, true)

	local launchGlow = p(
		destination.name:gsub("%s+","") .. "LaunchGlow",
		Vector3.new(2.8, 4.6, 0.2),
		Vector3.new(lx, floorY + 3.8, lz - 0.3),
		"Bright green", Enum.Material.Neon, 0.42, true)

	local launchRing = cylinder(
		destination.name:gsub("%s+","") .. "LaunchRing",
		Vector3.new(0.28, 6.5, 6.5),
		CFrame.new(lx, floorY + 3.9, lz) * CFrame.Angles(math.rad(90), 0, 0),
		"Bright green", Enum.Material.Neon, 0.12, true)

	addLabel(launchCore, "▶ " .. (destination.displayName or destination.name), Color3.fromRGB(100, 255, 120))

	local launchPad = p(
		destination.name:gsub("%s+","") .. "LaunchPad",
		Vector3.new(7, 0.2, 5),
		Vector3.new(lx, floorY + 0.55, lz - 4),
		"Bright green", Enum.Material.Neon, 0.4, true)
	local launchSel = Instance.new("SelectionBox")
	launchSel.Adornee = launchPad
	launchSel.Color3 = Color3.fromRGB(100, 255, 120)
	launchSel.LineThickness = 0.08
	launchSel.SurfaceTransparency = 0.82
	launchSel.Parent = launchPad

	local launchPrompt = Instance.new("ProximityPrompt")
	launchPrompt.ActionText = "Launch Level"
	launchPrompt.ObjectText = "▶ " .. (destination.displayName or destination.name)
	launchPrompt.KeyboardKeyCode = Enum.KeyCode.F
	launchPrompt.MaxActivationDistance = 10
	launchPrompt.RequiresLineOfSight = false
	launchPrompt.Parent = launchCore
	launchPrompt:SetAttribute("DestinationOrder", destination.order)

	local launchDebounce = {}
	launchPrompt.Triggered:Connect(function(player)
		local now = os.clock()
		if launchDebounce[player] and now - launchDebounce[player] < 2 then return end
		launchDebounce[player] = now

		-- Reset this level's NPC count so enemies respawn
		if gameEvents then
			local remVal = gameEvents:FindFirstChild(destination.ownRemaining)
			local totVal = gameEvents:FindFirstChild(destination.ownTotal)
			if remVal and totVal and totVal.Value > 0 then
				remVal.Value = totVal.Value
			end
		end

		-- Teleport player to the level
		sendPlayer(player, destination)
	end)

	for _, obj in { launchPillar, launchCore, launchGlow, launchRing, launchPad } do
		obj:SetAttribute("LaunchMachinePart", true)
		obj:SetAttribute("DestinationOrder", destination.order)
	end
	end
end

--[[
local MACHINE_X = 0
local MACHINE_Z = -274
local MACHINE_Y = G

local mainBase = cylinder("MegaTimeMachineBase", Vector3.new(1.2, 42, 42), CFrame.new(MACHINE_X, MACHINE_Y + 0.65, MACHINE_Z) * CFrame.Angles(0, 0, math.rad(90)), "Really black", Enum.Material.Metal, 0.02, false)
local launcherDeck = cylinder("LevelPassLauncherCircle", Vector3.new(0.8, 145, 145), CFrame.new(MACHINE_X, MACHINE_Y + 0.72, MACHINE_Z + 17) * CFrame.Angles(0, 0, math.rad(90)), "Dark stone grey", Enum.Material.Metal, 0.04, false)
local launcherGlow = cylinder("LevelPassLauncherGlow", Vector3.new(0.25, 132, 132), CFrame.new(MACHINE_X, MACHINE_Y + 1.15, MACHINE_Z + 17) * CFrame.Angles(0, 0, math.rad(90)), "Cyan", Enum.Material.Neon, 0.78, true)
local outerRing = cylinder("MegaTimeMachineOuterRing", Vector3.new(1.4, 34, 34), CFrame.new(MACHINE_X, MACHINE_Y + 15.5, MACHINE_Z) * CFrame.Angles(math.rad(90), 0, 0), "Cyan", Enum.Material.Neon, 0.12, true)
local innerRing = cylinder("MegaTimeMachineInnerRing", Vector3.new(0.8, 25, 25), CFrame.new(MACHINE_X, MACHINE_Y + 15.5, MACHINE_Z - 0.2) * CFrame.Angles(math.rad(90), 0, 0), "Bright violet", Enum.Material.Neon, 0.3, true)
local portal = p("MegaTimePortal", Vector3.new(21, 21, 0.65), Vector3.new(MACHINE_X, MACHINE_Y + 15.5, MACHINE_Z - 0.65), "Bright blue", Enum.Material.ForceField, 0.42, true)
local core = p("MegaTimeMachineCore", Vector3.new(9, 9, 1.2), Vector3.new(MACHINE_X, MACHINE_Y + 15.5, MACHINE_Z - 1.1), "Institutional white", Enum.Material.Neon, 0.18, true)
local launchPad = cylinder("MegaTimeLaunchPad", Vector3.new(0.35, 30, 30), CFrame.new(MACHINE_X, MACHINE_Y + 1.55, MACHINE_Z + 17) * CFrame.Angles(0, 0, math.rad(90)), "Bright blue", Enum.Material.Neon, 0.66, true)

for _, obj in { mainBase, launcherDeck, launcherGlow, outerRing, innerRing, portal, core, launchPad } do
	obj:SetAttribute("TimeMachineSharedPart", true)
end

addLabel(core, "LEVEL PASS LAUNCHER\nCOMPLETED LEVELS ONLY", Color3.fromRGB(120, 240, 255))

for i = 1, 20 do
	local angle = math.rad(i * 18)
	local x = MACHINE_X + math.sin(angle) * 17
	local y = MACHINE_Y + 15.5 + math.cos(angle) * 17
	local bulb = p("MegaTimeRimBulb", Vector3.new(1.2, 1.2, 1.2), Vector3.new(x, y, MACHINE_Z - 1.4), i % 2 == 0 and "Bright yellow" or "Hot pink", Enum.Material.Neon, 0.08, true)
	bulb.Shape = Enum.PartType.Ball
end

for x = -52, 52, 26 do
	p("MegaTimeSupport", Vector3.new(1.1, 24, 1.1), Vector3.new(x, MACHINE_Y + 12, MACHINE_Z + 5), "Dark stone grey", Enum.Material.Metal, 0.02, false)
	p("MegaTimeSupportGlow", Vector3.new(0.35, 23, 0.35), Vector3.new(x, MACHINE_Y + 12, MACHINE_Z + 4.35), "Cyan", Enum.Material.Neon, 0.2, true)
end

local travelDebounce = {}
local function addDestinationButton(index, destination)
	local angle = math.rad(-90 + ((index - 1) / #DESTINATIONS) * 360)
	local radius = 56
	local x = MACHINE_X + math.cos(angle) * radius
	local z = MACHINE_Z + 17 + math.sin(angle) * radius
	local button = cylinder(destination.name:gsub("%s+", "") .. "LevelPassSpot", Vector3.new(0.55, 11.5, 11.5), CFrame.new(x, MACHINE_Y + 2.15, z) * CFrame.Angles(0, 0, math.rad(90)), destination.color, Enum.Material.Neon, 0.12, true)
	button:SetAttribute("TimeMachinePart", true)
	button:SetAttribute("DestinationOrder", destination.order)

	local cap = cylinder(destination.name:gsub("%s+", "") .. "LevelPassButton", Vector3.new(0.7, 7.6, 7.6), CFrame.new(x, MACHINE_Y + 2.95, z) * CFrame.Angles(0, 0, math.rad(90)), "Institutional white", Enum.Material.Neon, 0.08, true)
	cap:SetAttribute("TimeMachinePart", true)
	cap:SetAttribute("DestinationOrder", destination.order)

	local screen = p(destination.name:gsub("%s+", "") .. "LevelPassNamePlate", Vector3.new(12.5, 0.2, 6.8), Vector3.new(x, MACHINE_Y + 3.45, z), "Really black", Enum.Material.SmoothPlastic, 0.04, true)
	screen:SetAttribute("TimeMachinePart", true)
	screen:SetAttribute("DestinationOrder", destination.order)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 34
	gui.Parent = screen
	gui:SetAttribute("DestinationOrder", destination.order)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 1, -8)
	label.Position = UDim2.new(0, 4, 0, 4)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = destination.labelColor
	label.TextStrokeTransparency = 0.25
	label.Text = tostring(destination.order) .. "\n" .. destination.name
	label.Parent = gui

	local floatingName = Instance.new("BillboardGui")
	floatingName.Name = destination.name:gsub("%s+", "") .. "FloatingName"
	floatingName.Size = UDim2.new(0, 170, 0, 46)
	floatingName.StudsOffset = Vector3.new(0, 5.4, 0)
	floatingName.AlwaysOnTop = false
	floatingName.Parent = button
	floatingName:SetAttribute("DestinationOrder", destination.order)

	local floatingText = Instance.new("TextLabel")
	floatingText.Size = UDim2.new(1, 0, 1, 0)
	floatingText.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
	floatingText.BackgroundTransparency = 0.18
	floatingText.BorderSizePixel = 0
	floatingText.Font = Enum.Font.GothamBlack
	floatingText.TextScaled = true
	floatingText.TextColor3 = destination.labelColor
	floatingText.TextStrokeTransparency = 0.2
	floatingText.Text = "LEVEL " .. tostring(destination.order) .. "\n" .. destination.name
	floatingText.Parent = floatingName
	Instance.new("UICorner", floatingText).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke")
	stroke.Color = destination.labelColor
	stroke.Thickness = 2
	stroke.Transparency = 0.15
	stroke.Parent = floatingText

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Launch"
	prompt.ObjectText = destination.displayName or destination.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = button
	prompt:SetAttribute("DestinationOrder", destination.order)

	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		if travelDebounce[player] and now - travelDebounce[player] < 1 then return end
		travelDebounce[player] = now
		sendPlayer(player, destination)
	end)
end

for index, destination in DESTINATIONS do
	addDestinationButton(index, destination)
end

Players.PlayerRemoving:Connect(function(player)
	travelDebounce[player] = nil
end)

print("[TimeTravelMachines] Built one big portal machine successfully!")
]]

print("[TimeTravelMachines] Built successfully!")
