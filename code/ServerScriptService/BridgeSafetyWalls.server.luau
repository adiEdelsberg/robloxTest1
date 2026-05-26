-- BridgeSafetyWalls.server.luau
-- Adds tall transparent side walls to every bridge/connector so players cannot fall
-- off bridges while moving, launching, or descending between worlds.

local GROUND_Y = 1
local WALL_HEIGHT = 1200
local WALL_THICKNESS = 1.2
local Z_BRIDGE_WIDTH = 24
local X_BRIDGE_WIDTH = 52

local folder = workspace:FindFirstChild("BridgeSafetyWalls")
if folder then
	folder:Destroy()
end

folder = Instance.new("Folder")
folder.Name = "BridgeSafetyWalls"
folder.Parent = workspace

local zBridges = {
	{ name = "PlaygroundPizza",   x = 0, z1 = 59,   z2 = 132  },
	{ name = "PizzaGalactic",     x = 0, z1 = 268,  z2 = 385  },
	{ name = "GalacticJungle",    x = 0, z1 = 525,  z2 = 640  },
	{ name = "JungleSports",      x = 0, z1 = 780,  z2 = 860  },
	{ name = "SportsTennis",      x = 0, z1 = 1020, z2 = 1090 },
	{ name = "TennisGameStation", x = 0, z1 = 1231, z2 = 1300 },
	{ name = "GameStationCoffee", x = 0, z1 = 1460, z2 = 1540 },
	{ name = "NeonRiftFrostBasin", x = -2860, z1 = 1976, z2 = 2142 },
	{ name = "FrostBasinEmberHold", x = -2860, z1 = 2266, z2 = 2486 },
	{ name = "EmberHoldNovaSpire", x = -2860, z1 = 2616, z2 = 2836 },
	{ name = "NovaSpirePrismPeak", x = -2860, z1 = 2964, z2 = 3141 },
	{ name = "PrismPeakMagmaCore", x = -2860, z1 = 3259, z2 = 3431 },
	{ name = "MagmaCoreStormCircuit", x = -2860, z1 = 3569, z2 = 3771 },
	{ name = "StormCircuitShadowVault", x = -2860, z1 = 3889, z2 = 4066 },
	{ name = "ShadowVaultApexNexus", x = -2860, z1 = 4194, z2 = 4366 },
	{ name = "ApexNexusCloudDrift", x = -2860, z1 = 4534, z2 = 4691 },
	{ name = "CloudDriftCoralReef", x = -2860, z1 = 4829, z2 = 4996 },
	{ name = "CoralReefBubbleBounce", x = -2860, z1 = 5124, z2 = 5271 },
	{ name = "BubbleBounceZenGarden", x = -2860, z1 = 5409, z2 = 5556 },
	{ name = "ZenGardenCrystalSpires", x = -2860, z1 = 5684, z2 = 5831 },
	{ name = "CrystalSpiresNeonTri", x = -2860, z1 = 5969, z2 = 6116 },
	{ name = "NeonTriWideCanyon", x = -2860, z1 = 6254, z2 = 6401 },
	{ name = "WideCanyonNarrowPass", x = -2860, z1 = 6539, z2 = 6686 },
	{ name = "NarrowPassDiamondGate", x = -2860, z1 = 6824, z2 = 6971 },
	{ name = "DiamondGateHourglass", x = -2860, z1 = 7109, z2 = 7256 },
	{ name = "HourglassMovementLab", x = -2860, z1 = 7394, z2 = 7540 },
	{ name = "MovementLabFightArena", x = -2860, z1 = 7680, z2 = 7990 },
	{ name = "FightArenaEmpty43", x = -2860, z1 = 8210, z2 = 8340 },
}

local xBridges = {
	{ name = "CoffeeEmpty",    z = 1700, x1 = -200,  x2 = -140 },
	{ name = "CoffeeBurger",   z = 1700, x1 = 140,   x2 = 214  },
	{ name = "BurgerNewPizza", z = 1700, x1 = 490,   x2 = 566  },
	{ name = "NewPizzaPool",   z = 1700, x1 = 842,   x2 = 918  },
	{ name = "PoolDinoPark",   z = 1700, x1 = 1194,  x2 = 1270 },
	{ name = "DinoParkBeach",  z = 1700, x1 = 1546,  x2 = 1622 },
	{ name = "BeachForest",    z = 1700, x1 = 1898,  x2 = 1974 },
	{ name = "ForestCherry",   z = 1700, x1 = 2250,  x2 = 2308 },
	{ name = "CherryOrchard",  z = 1700, x1 = 2596,  x2 = 2684 },
	{ name = "EmptyStorm",     z = 1700, x1 = -970,  x2 = -900 },
	{ name = "StormVolt",      z = 1700, x1 = -1740, x2 = -1670 },
	{ name = "VoltNeon",       z = 1700, x1 = -2510, x2 = -2440 },
	{ name = "NeonSkyVault",   z = 1700, x1 = -3466, x2 = -3210 },
	{ name = "SkyVaultStormTower", z = 1700, x1 = -3570, x2 = -3530 },
}

local function part(name, size, pos)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.ForceField
	p.BrickColor = BrickColor.new("Cyan")
	p.Transparency = 0.72
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function addZBridgeWalls(bridge)
	local z1 = math.min(bridge.z1, bridge.z2)
	local z2 = math.max(bridge.z1, bridge.z2)
	local length = z2 - z1
	local midZ = (z1 + z2) / 2
	local y = GROUND_Y + WALL_HEIGHT / 2
	local halfWidth = Z_BRIDGE_WIDTH / 2

	for _, side in { -1, 1 } do
		local wall = part(
			bridge.name .. (side < 0 and "_LeftSafetyWall" or "_RightSafetyWall"),
			Vector3.new(WALL_THICKNESS, WALL_HEIGHT, length),
			Vector3.new((bridge.x or 0) + side * halfWidth, y, midZ)
		)
		wall:SetAttribute("BridgeName", bridge.name)
	end
end

local function addXBridgeWalls(bridge)
	local x1 = math.min(bridge.x1, bridge.x2)
	local x2 = math.max(bridge.x1, bridge.x2)
	local length = x2 - x1
	local midX = (x1 + x2) / 2
	local y = GROUND_Y + WALL_HEIGHT / 2
	local halfWidth = X_BRIDGE_WIDTH / 2

	for _, side in { -1, 1 } do
		local wall = part(
			bridge.name .. (side < 0 and "_LeftSafetyWall" or "_RightSafetyWall"),
			Vector3.new(length, WALL_HEIGHT, WALL_THICKNESS),
			Vector3.new(midX, y, (bridge.z or 1700) + side * halfWidth)
		)
		wall:SetAttribute("BridgeName", bridge.name)
	end
end

for _, bridge in zBridges do
	addZBridgeWalls(bridge)
end

for _, bridge in xBridges do
	addXBridgeWalls(bridge)
end

print("[BridgeSafetyWalls] Tall bridge safety walls built.")
