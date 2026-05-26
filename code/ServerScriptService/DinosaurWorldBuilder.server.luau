-- Dinosaur Park catch world, placed to the right of Swimming Pool.
-- Swimming Pool world: x=918..1194. Dinosaur Park: x=1270..1546. Connector crosses x=1194->1270.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "DinosaurWorld"
folder.Parent = workspace

local SMP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal
local ROCK = Enum.Material.Slate
local GRASS = Enum.Material.Grass
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
local X1, X2 = 1270, 1546
local Z1, Z2 = 1540, 1860
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local DOOR_Z = 1700
local DOOR_HALF = 18
local FH, CW = 10, 44

p("DinoConnectorFloor", Vector3.new(76, 0.45, 22), Vector3.new(1232, G + 0.23, DOOR_Z), "Dark stone grey", DPLATE)
p("DinoConnectorGlow", Vector3.new(72, 0.1, 18), Vector3.new(1232, G + 0.5, DOOR_Z), "Bright green", NEON, 0.68, true)
for _, z in { DOOR_Z - 11, DOOR_Z + 11 } do
	p("DinoConnectorRail", Vector3.new(76, 0.35, 0.35), Vector3.new(1232, G + 3.2, z), "Bright orange", NEON, 0.18)
end

p("DinoGround", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Earth green", GRASS)
p("DinoMudPath", Vector3.new(X2 - X1 - 34, 0.18, 28), Vector3.new(XC, G + 0.18, DOOR_Z), "Reddish brown", SMP, 0.05, true)
p("DinoAmberGlow", Vector3.new(X2 - X1 - 52, 0.08, 16), Vector3.new(XC, G + 0.38, DOOR_Z), "Bright orange", NEON, 0.75, true)

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

-- Volcano and lava garden.
cylinder("VolcanoBase", Vector3.new(42, 70, 70), CFrame.new(X2 - 54, G + 18, Z1 + 58) * C90Z, "Dark stone grey", ROCK)
cylinder("VolcanoMouth", Vector3.new(4, 34, 34), CFrame.new(X2 - 54, G + 38, Z1 + 58) * C90Z, "Really black", SMP, 0.04, true)
ball("VolcanoLava", Vector3.new(X2 - 54, G + 41, Z1 + 58), 24, "Bright orange", NEON, 0.25, true)
for i = 0, 8 do
	local a = math.rad(i * 40)
	local x = X2 - 54 + math.cos(a) * (26 + (i % 2) * 9)
	local z = Z1 + 58 + math.sin(a) * (24 + (i % 3) * 6)
	p("LavaCrack", Vector3.new(18, 0.12, 1.2), Vector3.new(x, G + 0.65, z), "Bright orange", NEON, 0.18, true)
end

-- Dinosaur eggs, bones, trees, and amber crystals.
for _, pos in { { X1 + 52, Z1 + 52 }, { X1 + 76, Z2 - 50 }, { XC - 18, Z2 - 70 }, { X2 - 76, Z2 - 54 }, { XC + 12, Z1 + 88 } } do
	ball("DinoEgg", Vector3.new(pos[1], G + 3.2, pos[2]), 7.4, "Institutional white", SMP, 0, false)
	ball("DinoEggSpot", Vector3.new(pos[1] + 1.4, G + 6.1, pos[2] - 2.2), 1.4, "Bright green", NEON, 0.1, true)
end

for i = 0, 11 do
	local x = X1 + 32 + (i % 6) * 46
	local z = i < 6 and Z1 + 30 or Z2 - 30
	p("DinoPalmTrunk", Vector3.new(2.8, 18, 2.8), Vector3.new(x, G + 9, z), "Reddish brown", SMP)
	for leaf = 0, 4 do
		local leafPart = p("DinoPalmLeaf", Vector3.new(3, 0.55, 16), Vector3.new(x, G + 18.7, z), "Bright green", NEON, 0.18, true)
		leafPart.CFrame = CFrame.new(x, G + 18.7, z) * CFrame.Angles(0, math.rad(leaf * 72), math.rad(8))
	end
end

for _, pos in { { X1 + 68, ZC + 40 }, { XC + 56, ZC - 54 }, { X2 - 92, ZC + 52 } } do
	cylinder("BoneSpine", Vector3.new(1, 28, 1), CFrame.new(pos[1], G + 1.8, pos[2]) * C90Z, "Institutional white", SMP, 0.02, true)
	for rib = -3, 3 do
		p("BoneRib", Vector3.new(0.8, 7, 0.8), Vector3.new(pos[1] + rib * 4, G + 3.8, pos[2]), "Institutional white", SMP, 0.02, true)
	end
end

for _, pos in { { X1 + 46, ZC - 76 }, { XC, ZC + 74 }, { X2 - 44, ZC - 18 }, { X1 + 118, ZC + 18 } } do
	ball("AmberCrystal", Vector3.new(pos[1], G + 5.5, pos[2]), 8, "Bright orange", NEON, 0.25, true)
	p("AmberBase", Vector3.new(13, 1.2, 13), Vector3.new(pos[1], G + 0.8, pos[2]), "Dark stone grey", ROCK)
end

print("[DinosaurWorld] Built dinosaur catch world.")
