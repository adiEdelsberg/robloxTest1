-- Swimming Pool bird-catching world, placed to the right of New Pizza.
-- New Pizza world: x=566..842. Pool world: x=918..1194. Connector crosses x=842->918.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "SwimmingPoolWorld"
folder.Parent = workspace

local SMP = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal
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
local X1, X2 = 918, 1194
local Z1, Z2 = 1540, 1860
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local DOOR_Z = 1700
local DOOR_HALF = 18
local FH, CW = 8, 40

p("PoolConnectorFloor", Vector3.new(76, 0.45, 22), Vector3.new(880, G + 0.23, DOOR_Z), "Dark stone grey", DPLATE)
p("PoolConnectorGlow", Vector3.new(72, 0.1, 18), Vector3.new(880, G + 0.5, DOOR_Z), "Cyan", NEON, 0.68, true)
for _, z in { DOOR_Z - 11, DOOR_Z + 11 } do
	p("PoolConnectorRail", Vector3.new(76, 0.35, 0.35), Vector3.new(880, G + 3.2, z), "Bright blue", NEON, 0.18)
end

p("PoolDeck", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Institutional white", DPLATE)
p("PoolWater", Vector3.new(214, 0.34, 196), Vector3.new(XC, G + 0.42, ZC + 6), "Cyan", NEON, 0.34, true)
p("PoolDeepWater", Vector3.new(190, 0.3, 168), Vector3.new(XC, G + 0.58, ZC + 6), "Bright blue", NEON, 0.52, true)

for x = X1 + 26, X2 - 26, 24 do
	p("PoolLaneLine", Vector3.new(0.35, 0.16, 168), Vector3.new(x, G + 0.82, ZC + 6), "Institutional white", NEON, 0.15, true)
end
for z = Z1 + 34, Z2 - 26, 28 do
	p("PoolDeckStripe", Vector3.new(X2 - X1 - 18, 0.08, 0.25), Vector3.new(XC, G + 1.08, z), "Cyan", NEON, 0.65, true)
end

p("WallLeftN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Cyan", NEON, 0.35)
p("WallLeftS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Cyan", NEON, 0.35)
p("ContainLeftN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainLeftS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallRightN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Cyan", NEON, 0.35)
p("WallRightS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Cyan", NEON, 0.35)
p("ContainRightN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainRightS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallNorth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z1), "Cyan", NEON, 0.35)
p("WallSouth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z2), "Cyan", NEON, 0.35)
p("ContainNorth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z1), "Really black", SMP, 1)
p("ContainSouth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z2), "Really black", SMP, 1)

for i = 0, 6 do
	local x = X1 + 36 + i * 34
	p("DivingBlock", Vector3.new(12, 3, 9), Vector3.new(x, G + 2.1, Z1 + 32), "Institutional white", SMP)
	p("DivingBlockTop", Vector3.new(10, 0.22, 7), Vector3.new(x, G + 3.75, Z1 + 32), "Bright blue", NEON, 0.18, true)
end

for _, pos in { { X1 + 46, Z2 - 46 }, { X2 - 46, Z2 - 46 }, { X1 + 48, Z1 + 88 }, { X2 - 48, Z1 + 88 }, { XC, ZC + 76 } } do
	cylinder("PoolFloatRing", Vector3.new(1.2, 18, 18), CFrame.new(pos[1], G + 3.6, pos[2]) * C90Z, "Hot pink", NEON, 0.16, true)
	ball("BubbleCluster", Vector3.new(pos[1], G + 9.5, pos[2]), 4.2, "Cyan", NEON, 0.42, true)
end

for i = 0, 9 do
	local x = X1 + 28 + i * 26
	p("PoolChair", Vector3.new(14, 1.2, 5), Vector3.new(x, G + 1.5, Z2 - 26), i % 2 == 0 and "Bright blue" or "Cyan", SMP)
	p("PoolUmbrellaPole", Vector3.new(0.5, 8, 0.5), Vector3.new(x, G + 4.6, Z2 - 40), "Really black", METAL)
	cylinder("PoolUmbrella", Vector3.new(0.7, 13, 13), CFrame.new(x, G + 9, Z2 - 40) * C90Z, i % 2 == 0 and "Hot pink" or "Bright yellow", NEON, 0.12, true)
end

print("[SwimmingPoolWorld] Built swimming pool bird-catching world.")
