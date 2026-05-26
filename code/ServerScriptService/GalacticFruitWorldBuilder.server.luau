local G = 1

local folder = Instance.new("Folder")
folder.Name = "GalacticFruitWorld"
folder.Parent = workspace

local SMP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local GRASS = Enum.Material.Grass
local WOOD = Enum.Material.Wood
local DPLATE = Enum.Material.DiamondPlate

local function p(name, size, pos, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or SMP
	part.Transparency = trans or 0
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function ball(name, pos, size, color, mat, trans, noCollide)
	local part = p(name, Vector3.new(size, size, size), pos, color, mat, trans, noCollide)
	part.Shape = Enum.PartType.Ball
	return part
end

local function cylinder(name, size, cf, color, mat, trans, noCollide)
	local part = p(name, size, cf.Position, color, mat, trans, noCollide)
	part.Shape = Enum.PartType.Cylinder
	part.CFrame = cf
	return part
end

local C90Z = CFrame.Angles(0, 0, math.rad(90))
local X1, X2 = 2660, 2980
local Z1, Z2 = 1380, 2020
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local DOOR_Z = 1700
local FH, CW = 14, 60
local DOOR_HALF = 18
local WN_Z  = (DOOR_Z - DOOR_HALF) - Z1          -- north-wall Z size
local WS_Z  = Z2 - (DOOR_Z + DOOR_HALF)           -- south-wall Z size
local WNC_Z = (Z1 + DOOR_Z - DOOR_HALF) / 2       -- north-wall center Z
local WSC_Z = (Z2 + DOOR_Z + DOOR_HALF) / 2       -- south-wall center Z

p("GalacticFruitConnectorFloor", Vector3.new(40, 0.45, 22), Vector3.new(2640, G + 0.23, DOOR_Z), "Dark stone grey", DPLATE)
p("GalacticFruitConnectorGlow", Vector3.new(36, 0.1, 18), Vector3.new(2640, G + 0.5, DOOR_Z), "Cyan", NEON, 0.6, true)

p("GalacticFruitGround", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Black", GRASS)
p("GalacticFruitNebulaFloor", Vector3.new(X2 - X1 - 26, 0.12, Z2 - Z1 - 26), Vector3.new(XC, G + 0.18, ZC), "Royal purple", NEON, 0.88, true)
p("GalacticFruitRoad", Vector3.new(X2 - X1 - 36, 0.18, 28), Vector3.new(XC, G + 0.3, DOOR_Z), "Really black", SMP, 0.02, true)
p("GalacticFruitRoadGlow", Vector3.new(X2 - X1 - 60, 0.08, 12), Vector3.new(XC, G + 0.48, DOOR_Z), "Cyan", NEON, 0.7, true)

p("GalacticFruitWallWestN", Vector3.new(0.6, FH, WN_Z), Vector3.new(X1, G + FH / 2, WNC_Z), "Cyan", NEON, 0.35)
p("GalacticFruitWallWestS", Vector3.new(0.6, FH, WS_Z), Vector3.new(X1, G + FH / 2, WSC_Z), "Cyan", NEON, 0.35)
p("GalacticFruitWallEastN", Vector3.new(0.6, FH, WN_Z), Vector3.new(X2, G + FH / 2, WNC_Z), "Hot pink", NEON, 0.35)
p("GalacticFruitWallEastS", Vector3.new(0.6, FH, WS_Z), Vector3.new(X2, G + FH / 2, WSC_Z), "Hot pink", NEON, 0.35)
p("GalacticFruitWallNorth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z1), "Bright violet", NEON, 0.35)
p("GalacticFruitWallSouth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z2), "Bright violet", NEON, 0.35)
p("GalacticFruitContainNorth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z1), "Really black", SMP, 1)
p("GalacticFruitContainSouth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z2), "Really black", SMP, 1)
p("GalacticFruitContainWestN", Vector3.new(0.5, CW, WN_Z), Vector3.new(X1, G + CW / 2, WNC_Z), "Really black", SMP, 1)
p("GalacticFruitContainWestS", Vector3.new(0.5, CW, WS_Z), Vector3.new(X1, G + CW / 2, WSC_Z), "Really black", SMP, 1)
p("GalacticFruitContainEastN", Vector3.new(0.5, CW, WN_Z), Vector3.new(X2, G + CW / 2, WNC_Z), "Really black", SMP, 1)
p("GalacticFruitContainEastS", Vector3.new(0.5, CW, WS_Z), Vector3.new(X2, G + CW / 2, WSC_Z), "Really black", SMP, 1)

-- Colors match dino fruitColor: Cyan (Nebula Sprout, short trees h<100),
-- Hot pink (Starfire Strider, medium trees h=106-116), New Yeller (Galaxy Titan, tall h>=126)
local TREES = {
	{ x = 2710, z = 1415, h = 92,  c = 34, color = "Cyan"       }, -- short, NW
	{ x = 2930, z = 1460, h = 96,  c = 36, color = "Cyan"       }, -- short, NE
	{ x = 2748, z = 1618, h = 106, c = 38, color = "Hot pink"   }, -- medium, W-mid
	{ x = 2906, z = 1710, h = 112, c = 40, color = "Hot pink"   }, -- medium, E-mid
	{ x = 2762, z = 1808, h = 116, c = 42, color = "Hot pink"   }, -- medium, W-mid-S
	{ x = 2718, z = 1908, h = 126, c = 45, color = "New Yeller" }, -- tall, SW
	{ x = 2948, z = 1952, h = 132, c = 46, color = "New Yeller" }, -- tall, SE
	{ x = 2836, z = 1992, h = 148, c = 52, color = "New Yeller" }, -- tall, S-center
}

for index, tree in TREES do
	p("GalacticTreeTrunk", Vector3.new(9, tree.h, 9), Vector3.new(tree.x, G + tree.h / 2, tree.z), "Really black", WOOD)
	cylinder("GalacticTreeRootRing", Vector3.new(1.2, 30, 30), CFrame.new(tree.x, G + 1.1, tree.z) * C90Z, tree.color, NEON, 0.24, true)
	for ring = 1, 4 do
		cylinder("GalacticTreeEnergyBand", Vector3.new(0.7, 11 + ring * 2, 11 + ring * 2), CFrame.new(tree.x, G + ring * tree.h / 5, tree.z) * C90Z, tree.color, NEON, 0.28, true)
	end
	ball("GalacticTreeCanopy", Vector3.new(tree.x, G + tree.h + tree.c * 0.32, tree.z), tree.c, "Dark indigo", GRASS, 0.02, false)
	ball("GalacticTreeAura", Vector3.new(tree.x, G + tree.h + tree.c * 0.42, tree.z), tree.c + 5, tree.color, NEON, 0.78, true)
	local a = math.rad(index * 53)
	ball("GalacticFruitMarker", Vector3.new(tree.x + math.cos(a) * 12, G + tree.h + 4, tree.z + math.sin(a) * 12), 7, tree.color, NEON, 0.68, true)
end

for i = 1, 22 do
	local x = X1 + 20 + (i % 7) * 42
	local z = Z1 + 28 + math.floor(i / 7) * 92
	ball("NebulaRock", Vector3.new(x, G + 2.8, z), 4 + (i % 3), i % 2 == 0 and "Cyan" or "Hot pink", NEON, 0.42, true)
end

print("[GalacticFruitWorld] Built galactic fruit orchard.")
