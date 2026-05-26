-- SafetyWorldFloors
-- Invisible collision floors under every playable world bounds so players cannot
-- fall through art gaps, bridge seams, or decorative floor edges.

local oldFolder = workspace:FindFirstChild("SafetyWorldFloors")
if oldFolder then
	oldFolder:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = "SafetyWorldFloors"
folder.Parent = workspace

local FLOORS = {
	{ name = "Playground", minX = -59, maxX = 59, minZ = -59, maxZ = 59, topY = 0.45 },
	{ name = "EmptyWorld1", minX = -900, maxX = -200, minZ = 1420, maxZ = 1980, topY = 1 },
	{ name = "StormDome", minX = -1670, maxX = -970, minZ = 1420, maxZ = 1980, topY = 1 },
	{ name = "VoltAbyss", minX = -2440, maxX = -1740, minZ = 1420, maxZ = 1980, topY = 1 },
	{ name = "NeonRift", minX = -3210, maxX = -2510, minZ = 1420, maxZ = 1980, topY = 1 },
	{ name = "SkyVault", minX = -3534, maxX = -3466, minZ = 1666, maxZ = 1734, topY = 1 },
	{ name = "Pizza", minX = -72, maxX = 72, minZ = 132, maxZ = 268, topY = 1 },
	{ name = "Galactic", minX = -70, maxX = 70, minZ = 385, maxZ = 525, topY = 1 },
	{ name = "Jungle", minX = -70, maxX = 70, minZ = 640, maxZ = 780, topY = 1 },
	{ name = "Sports", minX = -82, maxX = 82, minZ = 860, maxZ = 1020, topY = 1 },
	{ name = "Tennis", minX = -70, maxX = 70, minZ = 1090, maxZ = 1230, topY = 1 },
	{ name = "GameStation", minX = -78, maxX = 78, minZ = 1300, maxZ = 1460, topY = 1 },
	{ name = "CoffeeShop", minX = -140, maxX = 140, minZ = 1540, maxZ = 1860, topY = 1 },
	{ name = "BurgerHouse", minX = 214, maxX = 490, minZ = 1540, maxZ = 1860, topY = 1 },
	{ name = "NewPizza", minX = 566, maxX = 842, minZ = 1540, maxZ = 1860, topY = 1 },
	{ name = "SwimmingPool", minX = 918, maxX = 1194, minZ = 1540, maxZ = 1860, topY = 1 },
	{ name = "DinosaurPark", minX = 1270, maxX = 1546, minZ = 1540, maxZ = 1860, topY = 1 },
	{ name = "DinoBeach", minX = 1622, maxX = 1898, minZ = 1540, maxZ = 1860, topY = 1 },
	{ name = "FlyingDinoForest", minX = 1974, maxX = 2250, minZ = 1540, maxZ = 1860, topY = 1 },
	{ name = "CherryGrove", minX = 2308, maxX = 2620, minZ = 1380, maxZ = 2020, topY = 1 },
	{ name = "GalacticOrchard", minX = 2654, maxX = 2988, minZ = 1374, maxZ = 2026, topY = 1 },
}

local function addSafetyFloor(data)
	local thickness = 2
	local width = data.maxX - data.minX
	local depth = data.maxZ - data.minZ
	local centerX = (data.minX + data.maxX) / 2
	local centerZ = (data.minZ + data.maxZ) / 2

	local floor = Instance.new("Part")
	floor.Name = data.name .. "SafetyFloor"
	floor.Size = Vector3.new(width, thickness, depth)
	floor.Position = Vector3.new(centerX, data.topY - thickness / 2, centerZ)
	floor.Anchored = true
	floor.CanCollide = true
	floor.CanTouch = false
	floor.CastShadow = false
	floor.Transparency = 1
	floor.Material = Enum.Material.SmoothPlastic
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = folder
end

for _, data in FLOORS do
	addSafetyFloor(data)
end

print("[SafetyWorldFloors] Invisible safety floors installed for all worlds.")
