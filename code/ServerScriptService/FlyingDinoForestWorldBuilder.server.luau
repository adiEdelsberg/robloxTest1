-- Flying Dino Forest, placed to the right of Dino Beach.
-- Dino Beach: x=1622..1898. Flying Dino Forest: x=1974..2250. Connector crosses x=1898->1974.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "FlyingDinoForestWorld"
folder.Parent = workspace

local SMP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal
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
local X1, X2 = 1974, 2250
local Z1, Z2 = 1540, 1860
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local DOOR_Z = 1700
local DOOR_HALF = 18
local FH, CW = 11, 48

p("FlyingDinoForestConnectorFloor", Vector3.new(76, 0.45, 22), Vector3.new(1936, G + 0.23, DOOR_Z), "Dark stone grey", DPLATE)
p("FlyingDinoForestConnectorGlow", Vector3.new(72, 0.1, 18), Vector3.new(1936, G + 0.5, DOOR_Z), "Bright green", NEON, 0.66, true)
for _, z in { DOOR_Z - 11, DOOR_Z + 11 } do
	p("FlyingDinoForestConnectorRail", Vector3.new(76, 0.35, 0.35), Vector3.new(1936, G + 3.2, z), "Royal purple", NEON, 0.18)
end

p("ForestGround", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Earth green", GRASS)
p("ForestRoad", Vector3.new(X2 - X1 - 36, 0.18, 26), Vector3.new(XC, G + 0.2, DOOR_Z), "Reddish brown", SMP, 0.04, true)
p("ForestRoadGlow", Vector3.new(X2 - X1 - 58, 0.08, 12), Vector3.new(XC, G + 0.38, DOOR_Z), "Bright green", NEON, 0.8, true)

p("WallLeftN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright green", NEON, 0.35)
p("WallLeftS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright green", NEON, 0.35)
p("ContainLeftN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainLeftS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallRightN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright green", NEON, 0.35)
p("WallRightS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright green", NEON, 0.35)
p("ContainRightN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainRightS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallNorth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z1), "Bright green", NEON, 0.35)
p("WallSouth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z2), "Bright green", NEON, 0.35)
p("ContainNorth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z1), "Really black", SMP, 1)
p("ContainSouth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z2), "Really black", SMP, 1)

-- Tall forest canopy.
for i = 0, 17 do
	local x = X1 + 28 + (i % 6) * 50
	local z = i < 6 and Z1 + 34 or (i < 12 and Z2 - 34 or Z1 + 102 + (i % 3) * 58)
	p("AncientTreeTrunk", Vector3.new(4.5, 28, 4.5), Vector3.new(x, G + 14, z), "Reddish brown", WOOD)
	ball("AncientTreeCanopy", Vector3.new(x, G + 31, z), 18, "Bright green", GRASS, 0.04, false)
	ball("AncientTreeCanopyGlow", Vector3.new(x, G + 31.5, z), 20, "Lime green", NEON, 0.72, true)
end

-- Perches, nests, glowing mushrooms and forest stones.
for _, pos in { { X1 + 58, ZC - 64 }, { XC - 36, ZC + 66 }, { XC + 64, ZC - 28 }, { X2 - 58, ZC + 56 }, { X2 - 72, Z1 + 82 } } do
	p("FlyingDinoPerch", Vector3.new(26, 1.1, 5), Vector3.new(pos[1], G + 18, pos[2]), "Reddish brown", WOOD)
	cylinder("NestRing", Vector3.new(1.4, 18, 18), CFrame.new(pos[1], G + 20, pos[2]) * C90Z, "Brown", WOOD, 0.04, true)
	ball("NestEgg", Vector3.new(pos[1] - 3, G + 21.4, pos[2]), 3, "Institutional white", SMP, 0.02, true)
	ball("NestEgg", Vector3.new(pos[1] + 3, G + 21.4, pos[2] + 2), 3, "Cyan", NEON, 0.22, true)
end

for i = 0, 13 do
	local x = X1 + 34 + (i % 7) * 40
	local z = Z1 + 84 + math.floor(i / 7) * 168 + (i % 2) * 18
	p("GlowMushroomStem", Vector3.new(2.4, 4.6, 2.4), Vector3.new(x, G + 2.3, z), "Institutional white", SMP)
	ball("GlowMushroomCap", Vector3.new(x, G + 5.1, z), 6.2, i % 2 == 0 and "Royal purple" or "Hot pink", NEON, 0.16, true)
end

for i = 0, 9 do
	local x = X1 + 48 + i * 26
	local z = ZC + ((i % 2 == 0) and -76 or 82)
	ball("MossRock", Vector3.new(x, G + 2.6, z), 5 + (i % 3), "Dark stone grey", ROCK, 0.04, false)
	ball("MossGlow", Vector3.new(x, G + 5.5, z), 3.5, "Bright green", NEON, 0.54, true)
end

print("[FlyingDinoForestWorld] Built flying dinosaur forest world.")
