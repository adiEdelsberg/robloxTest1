-- Giant Dino Cherry Grove, placed to the right of Flying Dino Forest.
-- Flying Dino Forest: x=1974..2250. Cherry Grove: x=2308..2620. Connector crosses x=2250->2308.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "GiantDinoCherryWorld"
folder.Parent = workspace

local SMP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local GRASS = Enum.Material.Grass
local WOOD = Enum.Material.Wood
local ROCK = Enum.Material.Slate
local DPLATE = Enum.Material.DiamondPlate

local function p(name, size, pos, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or SMP
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
	part.Material = mat or SMP
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local function ball(name, pos, size, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Position = pos
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or SMP
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local C90Z = CFrame.Angles(0, 0, math.rad(90))
local X1, X2 = 2308, 2620
local Z1, Z2 = 1380, 2020
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local DOOR_Z = 1700
local DOOR_HALF = 18
local FH, CW = 12, 50

p("CherryGroveConnectorFloor", Vector3.new(58, 0.45, 22), Vector3.new(2279, G + 0.23, DOOR_Z), "Dark stone grey", DPLATE)
p("CherryGroveConnectorGlow", Vector3.new(54, 0.1, 18), Vector3.new(2279, G + 0.5, DOOR_Z), "Really red", NEON, 0.66, true)
for _, z in { DOOR_Z - 11, DOOR_Z + 11 } do
	p("CherryGroveConnectorRail", Vector3.new(58, 0.35, 0.35), Vector3.new(2279, G + 3.2, z), "Bright green", NEON, 0.18)
end

p("CherryGroveGround", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Earth green", GRASS)
p("CherryGroveRoad", Vector3.new(X2 - X1 - 36, 0.18, 28), Vector3.new(XC, G + 0.2, DOOR_Z), "Reddish brown", SMP, 0.04, true)
p("CherryGroveRoadGlow", Vector3.new(X2 - X1 - 58, 0.08, 12), Vector3.new(XC, G + 0.38, DOOR_Z), "Really red", NEON, 0.82, true)

p("WallLeftN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really red", NEON, 0.35)
p("WallLeftS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really red", NEON, 0.35)
p("ContainLeftN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainLeftS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallRightN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really red", NEON, 0.35)
p("WallRightS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really red", NEON, 0.35)
p("ContainRightN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainRightS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallNorth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z1), "Bright green", NEON, 0.35)
p("WallSouth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z2), "Bright green", NEON, 0.35)
p("ContainNorth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z1), "Really black", SMP, 1)
p("ContainSouth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z2), "Really black", SMP, 1)

-- Three cherry tree sizes. Small dinos reach small trees, medium dinos reach medium trees,
-- and the giant dino reaches the tallest crowns.
-- dinoColor: tier 1 = Cyan (Sproutback Junior), tier 2 = Hot pink (Berryhorn Elder), tier 3 = New Yeller (Cherry Titan)
local TIER_COLOR = { "Cyan", "Hot pink", "New Yeller" }

local TREE_POSITIONS = {
	{ x = 2348, z = 1428, tier = 1, trunk = 30, canopy = 18, cherryY = 34 }, -- tier 1, NW
	{ x = 2572, z = 1510, tier = 1, trunk = 32, canopy = 19, cherryY = 36 }, -- tier 1, NE
	{ x = 2390, z = 1660, tier = 2, trunk = 50, canopy = 25, cherryY = 54 }, -- tier 2, W-mid
	{ x = 2558, z = 1768, tier = 2, trunk = 54, canopy = 26, cherryY = 58 }, -- tier 2, E-mid
	{ x = 2362, z = 1896, tier = 3, trunk = 76, canopy = 33, cherryY = 78 }, -- tier 3, SW
	{ x = 2556, z = 1974, tier = 3, trunk = 82, canopy = 35, cherryY = 84 }, -- tier 3, SE
}

for index, tree in TREE_POSITIONS do
	local x, z = tree.x, tree.z
	local col = TIER_COLOR[tree.tier]
	local trunkWidth = 5 + tree.tier * 1.8
	p("CherryTreeTier" .. tree.tier .. "Trunk", Vector3.new(trunkWidth, tree.trunk, trunkWidth), Vector3.new(x, G + tree.trunk / 2, z), "Reddish brown", WOOD)
	cylinder("TreeRootRing", Vector3.new(1.2, 18 + tree.tier * 5, 18 + tree.tier * 5), CFrame.new(x, G + 1.1, z) * C90Z, col, NEON, 0.22)
	ball("CherryTreeTier" .. tree.tier .. "Canopy", Vector3.new(x, G + tree.trunk + tree.canopy * 0.35, z), tree.canopy, tree.tier == 1 and "Bright green" or tree.tier == 2 and "Earth green" or "Forest green", GRASS, 0.03, false)
	ball("CherryTreeTier" .. tree.tier .. "CanopyGlow", Vector3.new(x, G + tree.trunk + tree.canopy * 0.45, z), tree.canopy + 3, col, NEON, 0.7, true)
	local markerAngle = math.rad(index * 47)
	ball("CherryTargetGlowMarker", Vector3.new(x + math.cos(markerAngle) * 9, tree.cherryY, z + math.sin(markerAngle) * 9), 5.6 + tree.tier * 0.4, col, NEON, 0.58, true)
end

-- Climbing platforms and grove props.
for _, pos in { { 2350, 1640 }, { 2480, 1558 }, { 2600, 1840 }, { 2326, 1815 }, { 2560, 1700 } } do
	ball("GroveBoulder", Vector3.new(pos[1], G + 3.2, pos[2]), 6, "Dark stone grey", ROCK, 0.03, false)
	ball("MossGlow", Vector3.new(pos[1], G + 6.8, pos[2]), 3.5, "Bright green", NEON, 0.54, true)
end

for i = 0, 10 do
	local x = X1 + 32 + i * 25
	local z = Z1 + 70 + (i % 3) * 86
	p("GroundLeafPatch", Vector3.new(16, 0.08, 10), Vector3.new(x, G + 0.7, z), i % 2 == 0 and "Bright green" or "Earth green", GRASS, 0.15, true)
end

print("[GiantDinoCherryWorld] Built giant dino cherry grove.")
