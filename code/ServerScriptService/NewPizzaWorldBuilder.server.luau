-- New Pizza Place sits to the right of Burger House, parallel to Coffee/Burger.
-- Burger world: x=214..490. New pizza world: x=566..842. Connector crosses x=490->566.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "NewPizzaWorld"
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
local C90X = CFrame.Angles(math.rad(90), 0, 0)

local X1, X2 = 566, 842
local Z1, Z2 = 1540, 1860
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local DOOR_Z = 1700
local DOOR_HALF = 18

-- Connector from Burger House finish gate into new pizza place.
p("NewPizzaConnectorFloor", Vector3.new(76, 0.45, 22), Vector3.new(528, G + 0.23, DOOR_Z), "Dark stone grey", DPLATE)
p("NewPizzaConnectorGlow", Vector3.new(72, 0.1, 18), Vector3.new(528, G + 0.5, DOOR_Z), "Bright orange", NEON, 0.72, true)
for _, z in { DOOR_Z - 11, DOOR_Z + 11 } do
	p("NewPizzaConnectorRail", Vector3.new(76, 0.35, 0.35), Vector3.new(528, G + 3.2, z), "Bright red", NEON, 0.18)
end

p("NewPizzaFloor", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Really black", DPLATE)

for x = X1, X2, 16 do
	p("PizzaGridZ", Vector3.new(0.2, 0.08, Z2 - Z1), Vector3.new(x, G + 0.08, ZC), "Bright red", NEON, 0.58, true)
end
for z = Z1, Z2, 16 do
	p("PizzaGridX", Vector3.new(X2 - X1, 0.08, 0.2), Vector3.new(XC, G + 0.09, z), "Bright orange", NEON, 0.62, true)
end

local FH, CW = 8, 40
p("WallLeftN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright red", NEON, 0.45)
p("WallLeftS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright red", NEON, 0.45)
p("ContainLeftN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainLeftS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallRightN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright red", NEON, 0.45)
p("WallRightS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright red", NEON, 0.45)
p("ContainRightN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainRightS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallNorth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z1), "Bright red", NEON, 0.45)
p("WallSouth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z2), "Bright red", NEON, 0.45)
p("ContainNorth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z1), "Really black", SMP, 1)
p("ContainSouth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z2), "Really black", SMP, 1)

-- Giant pizza centerpiece.
cylinder("MegaPizzaCrust", Vector3.new(3.5, 76, 76), CFrame.new(XC, G + 3.2, ZC) * C90Z, "Brick yellow", SMP)
cylinder("MegaPizzaSauce", Vector3.new(3.8, 68, 68), CFrame.new(XC, G + 3.45, ZC) * C90Z, "Really red", SMP, 0.02)
cylinder("MegaPizzaCheese", Vector3.new(4.1, 62, 62), CFrame.new(XC, G + 3.7, ZC) * C90Z, "Bright yellow", NEON, 0.18, true)
for i = 0, 17 do
	local a = math.rad(i * 360 / 18)
	local r = 12 + (i % 3) * 7
	ball("Pepperoni", Vector3.new(XC + math.cos(a) * r, G + 6, ZC + math.sin(a) * r), 4.2, "Really red", SMP, 0, true)
end
for i = 0, 9 do
	local a = math.rad(i * 36)
	p("CheeseRay", Vector3.new(2.2, 0.24, 26), Vector3.new(XC + math.cos(a) * 12, G + 6.2, ZC + math.sin(a) * 12), "New Yeller", NEON, 0.3, true)
end

-- Ovens and counters.
local ovenZ = Z1 + 48
p("PizzaCounter", Vector3.new(130, 5, 9), Vector3.new(XC, G + 2.5, ovenZ), "Dark stone grey", DPLATE)
p("PizzaCounterGlow", Vector3.new(126, 0.18, 8), Vector3.new(XC, G + 5.45, ovenZ), "Bright orange", NEON, 0.32, true)
for i = 0, 5 do
	local ox = X1 + 38 + i * 24
	p("OvenBody", Vector3.new(15, 13, 10), Vector3.new(ox, G + 6.5, ovenZ + 20), "Dark stone grey", DPLATE)
	p("OvenMouth", Vector3.new(11, 6, 0.6), Vector3.new(ox, G + 6.4, ovenZ + 14.7), "Really black", SMP)
	p("OvenFire", Vector3.new(9, 4, 0.35), Vector3.new(ox, G + 5.8, ovenZ + 14.3), "Bright orange", NEON, 0.22, true)
end

-- Booths and pizza tables.
for row = 0, 3 do
	for col = 0, 4 do
		local tx = X1 + 48 + col * 52
		local tz = Z1 + 110 + row * 48
		cylinder("PizzaTable", Vector3.new(0.7, 10, 10), CFrame.new(tx, G + 3.8, tz) * C90Z, "Dark stone grey", DPLATE)
		cylinder("PizzaTableGlow", Vector3.new(0.8, 10.7, 10.7), CFrame.new(tx, G + 3.9, tz) * C90Z, (row + col) % 2 == 0 and "Bright red" or "Bright orange", NEON, 0.68, true)
		p("PizzaTablePole", Vector3.new(0.7, 3.5, 0.7), Vector3.new(tx, G + 1.75, tz), "Really black", METAL)
		cylinder("MiniPizza", Vector3.new(0.35, 5.2, 5.2), CFrame.new(tx, G + 4.35, tz) * C90Z, "Bright yellow", NEON, 0.25, true)
	end
end

-- Floating sauce orbs.
for _, pos in { { X1 + 36, Z2 - 42 }, { X2 - 36, Z2 - 42 }, { X1 + 42, Z1 + 90 }, { X2 - 42, Z1 + 90 }, { XC, Z2 - 52 } } do
	ball("SauceOrb", Vector3.new(pos[1], G + 12, pos[2]), 7, "Really red", NEON, 0.25, true)
	cylinder("SteamTrail", Vector3.new(0.8, 12, 0.8), CFrame.new(pos[1], G + 22, pos[2]) * C90X, "Bright orange", NEON, 0.58, true)
end

print("[NewPizzaWorld] Built new Pizza Place after Burger House.")
