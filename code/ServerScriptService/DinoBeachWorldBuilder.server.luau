-- Dino Beach catch world, placed to the right of Dinosaur Park.
-- Dinosaur Park: x=1270..1546. Dino Beach: x=1622..1898. Connector crosses x=1546->1622.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "DinoBeachWorld"
folder.Parent = workspace

local SMP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal
local SAND = Enum.Material.Sand
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
local X1, X2 = 1622, 1898
local Z1, Z2 = 1540, 1860
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local DOOR_Z = 1700
local DOOR_HALF = 18
local FH, CW = 9, 44

p("DinoBeachConnectorFloor", Vector3.new(76, 0.45, 22), Vector3.new(1584, G + 0.23, DOOR_Z), "Dark stone grey", DPLATE)
p("DinoBeachConnectorGlow", Vector3.new(72, 0.1, 18), Vector3.new(1584, G + 0.5, DOOR_Z), "Bright yellow", NEON, 0.68, true)
for _, z in { DOOR_Z - 11, DOOR_Z + 11 } do
	p("DinoBeachConnectorRail", Vector3.new(76, 0.35, 0.35), Vector3.new(1584, G + 3.2, z), "Cyan", NEON, 0.18)
end

p("BeachSand", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Brick yellow", SAND)
p("BeachMainPath", Vector3.new(X2 - X1 - 34, 0.15, 24), Vector3.new(XC, G + 0.2, DOOR_Z), "Light orange", SMP, 0.08, true)
p("BeachPathGlow", Vector3.new(X2 - X1 - 52, 0.08, 12), Vector3.new(XC, G + 0.38, DOOR_Z), "Cyan", NEON, 0.78, true)

-- Ocean edge and waves.
p("OceanWater", Vector3.new(X2 - X1 - 24, 0.35, 76), Vector3.new(XC, G + 0.42, Z1 + 46), "Bright blue", NEON, 0.45, true)
p("DeepOcean", Vector3.new(X2 - X1 - 42, 0.3, 44), Vector3.new(XC, G + 0.58, Z1 + 31), "Cyan", NEON, 0.58, true)
for i = 0, 8 do
	local z = Z1 + 74 + i * 8
	p("WaveFoam", Vector3.new(X2 - X1 - 54, 0.1, 1.1), Vector3.new(XC, G + 0.85, z), "Institutional white", NEON, 0.32, true)
end

p("WallLeftN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright yellow", NEON, 0.35)
p("WallLeftS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright yellow", NEON, 0.35)
p("ContainLeftN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainLeftS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallRightN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright yellow", NEON, 0.35)
p("WallRightS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright yellow", NEON, 0.35)
p("ContainRightN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainRightS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallNorth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z1), "Cyan", NEON, 0.35)
p("WallSouth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z2), "Bright yellow", NEON, 0.35)
p("ContainNorth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z1), "Really black", SMP, 1)
p("ContainSouth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z2), "Really black", SMP, 1)

-- Beach props.
for i = 0, 9 do
	local x = X1 + 32 + i * 28
	local z = Z2 - 44 - (i % 2) * 28
	p("BeachTowel", Vector3.new(16, 0.18, 8), Vector3.new(x, G + 0.85, z), i % 2 == 0 and "Hot pink" or "Cyan", SMP, 0.04, true)
	p("UmbrellaPole", Vector3.new(0.55, 8, 0.55), Vector3.new(x + 8, G + 4.6, z - 7), "Really black", METAL)
	cylinder("UmbrellaCanopy", Vector3.new(0.75, 14, 14), CFrame.new(x + 8, G + 9.1, z - 7) * C90Z, i % 2 == 0 and "Bright yellow" or "Bright orange", NEON, 0.12, true)
end

for _, pos in { { X1 + 48, ZC + 30 }, { X1 + 92, Z2 - 88 }, { XC + 34, ZC + 54 }, { X2 - 72, Z2 - 72 }, { X2 - 58, ZC - 22 } } do
	ball("BeachDinoEgg", Vector3.new(pos[1], G + 3.0, pos[2]), 6.8, "Institutional white", SMP, 0, false)
	ball("BeachEggSpot", Vector3.new(pos[1] + 1.1, G + 5.5, pos[2] - 1.8), 1.25, "Cyan", NEON, 0.08, true)
end

for _, pos in { { X1 + 55, Z1 + 112 }, { XC - 12, Z2 - 38 }, { X2 - 60, Z1 + 114 }, { X2 - 36, Z2 - 38 } } do
	p("PalmTrunk", Vector3.new(2.6, 17, 2.6), Vector3.new(pos[1], G + 8.5, pos[2]), "Reddish brown", SMP)
	for leaf = 0, 5 do
		local leafPart = p("PalmLeaf", Vector3.new(3, 0.5, 17), Vector3.new(pos[1], G + 17.8, pos[2]), "Bright green", NEON, 0.2, true)
		leafPart.CFrame = CFrame.new(pos[1], G + 17.8, pos[2]) * CFrame.Angles(0, math.rad(leaf * 60), math.rad(10))
	end
end

for _, pos in { { X1 + 128, Z1 + 104 }, { XC + 88, ZC - 18 }, { X2 - 112, Z2 - 104 } } do
	cylinder("Surfboard", Vector3.new(0.45, 6, 22), CFrame.new(pos[1], G + 1.1, pos[2]) * C90Z, "Hot pink", NEON, 0.14, true)
	p("SurfboardStripe", Vector3.new(14, 0.12, 1.4), Vector3.new(pos[1], G + 1.46, pos[2]), "Cyan", NEON, 0.08, true)
	ball("Shell", Vector3.new(pos[1] + 13, G + 1.4, pos[2] + 9), 2.2, "Institutional white", SMP, 0.05, true)
end

for i = 0, 6 do
	local x = X1 + 38 + i * 34
	local z = Z1 + 92 + (i % 3) * 26
	ball("BeachRock", Vector3.new(x, G + 2.5, z), 5 + (i % 3), "Dark stone grey", ROCK, 0.04, false)
end

print("[DinoBeachWorld] Built dinosaur beach catch world.")
