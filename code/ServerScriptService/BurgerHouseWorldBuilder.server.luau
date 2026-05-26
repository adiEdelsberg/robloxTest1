-- Burger House sits parallel to Coffee Shop on the right side.
-- Coffee world: x=-156..156, z=1540..1860. Bridge crosses x=140->214.
-- Burger world: x=214..490, z=1540..1860.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "BurgerHouseWorld"
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

local function sign(part, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 22
	gui.LightInfluence = 0
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -18, 1, -10)
	label.Position = UDim2.new(0, 9, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end

local C90Z = CFrame.Angles(0, 0, math.rad(90))
local C90X = CFrame.Angles(math.rad(90), 0, 0)

local X1, X2 = 214, 490
local Z1, Z2 = 1540, 1860
local XC, ZC = (X1 + X2) / 2, (Z1 + Z2) / 2
local HW = (X2 - X1) / 2
local DOOR_Z = 1700
local DOOR_HALF = 18

p("BurgerFloor", Vector3.new(X2 - X1, 2, Z2 - Z1), Vector3.new(XC, 0, ZC), "Really black", DPLATE)

for x = X1, X2, 16 do
	p("BurgerGridZ", Vector3.new(0.2, 0.08, Z2 - Z1), Vector3.new(x, G + 0.08, ZC), "Bright yellow", NEON, 0.58, true)
end
for z = Z1, Z2, 16 do
	p("BurgerGridX", Vector3.new(X2 - X1, 0.08, 0.2), Vector3.new(XC, G + 0.09, z), "Bright red", NEON, 0.62, true)
end

local FH, CW = 8, 40
p("WallLeftN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright yellow", NEON, 0.45)
p("WallLeftS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright yellow", NEON, 0.45)
p("ContainLeftN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X1, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainLeftS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X1, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallRightN", Vector3.new(0.6, FH, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + FH / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Bright yellow", NEON, 0.45)
p("WallRightS", Vector3.new(0.6, FH, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + FH / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Bright yellow", NEON, 0.45)
p("ContainRightN", Vector3.new(0.5, CW, (DOOR_Z - DOOR_HALF) - Z1), Vector3.new(X2, G + CW / 2, (Z1 + DOOR_Z - DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainRightS", Vector3.new(0.5, CW, Z2 - (DOOR_Z + DOOR_HALF)), Vector3.new(X2, G + CW / 2, (Z2 + DOOR_Z + DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallNorth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z1), "Bright yellow", NEON, 0.45)
p("WallSouth", Vector3.new(X2 - X1, FH, 0.6), Vector3.new(XC, G + FH / 2, Z2), "Bright yellow", NEON, 0.45)
p("ContainNorth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z1), "Really black", SMP, 1)
p("ContainSouth", Vector3.new(X2 - X1, CW, 0.5), Vector3.new(XC, G + CW / 2, Z2), "Really black", SMP, 1)

local entry = p("BurgerEntrySign", Vector3.new(42, 6, 0.5), Vector3.new(X1 + 1.5, G + 16, DOOR_Z), "Really black", SMP, 0, true)
entry.CFrame = CFrame.new(X1 + 1.5, G + 16, DOOR_Z) * CFrame.Angles(0, math.rad(90), 0)
sign(entry, "BURGER HOUSE", Color3.fromRGB(255, 220, 70))
p("EntryGlowTop", Vector3.new(1, 1, 30), Vector3.new(X1 + 1, G + 18.8, DOOR_Z), "Bright red", NEON, 0.15, true)

-- Giant burger centerpiece.
local BX, BZ = XC, ZC
cylinder("BottomBun", Vector3.new(7, 54, 54), CFrame.new(BX, G + 4, BZ) * C90Z, "Brick yellow", SMP)
cylinder("Patty", Vector3.new(5, 50, 50), CFrame.new(BX, G + 9, BZ) * C90Z, "Brown", SMP)
cylinder("Cheese", Vector3.new(2, 55, 55), CFrame.new(BX, G + 12.4, BZ) * C90Z, "Bright yellow", NEON, 0.2, true)
cylinder("Tomato", Vector3.new(3, 52, 52), CFrame.new(BX, G + 15.2, BZ) * C90Z, "Bright red", SMP)
cylinder("Lettuce", Vector3.new(2, 58, 58), CFrame.new(BX, G + 18.2, BZ) * C90Z, "Bright green", NEON, 0.35, true)
cylinder("TopBun", Vector3.new(10, 52, 52), CFrame.new(BX, G + 23.5, BZ) * C90Z, "Brick yellow", SMP)
for i = 0, 13 do
	local a = math.rad(i * 360 / 14)
	ball("SesameSeed", Vector3.new(BX + math.cos(a) * 17, G + 29, BZ + math.sin(a) * 17), 1.3, "Institutional white", SMP, 0, true)
end

-- Counters and kitchen lines.
local counterZ = Z1 + 42
p("BurgerCounter", Vector3.new(120, 5, 9), Vector3.new(XC, G + 2.5, counterZ), "Dark stone grey", DPLATE)
p("CounterTop", Vector3.new(122, 0.5, 10), Vector3.new(XC, G + 5.25, counterZ), "Smoky grey", DPLATE)
p("CounterGlow", Vector3.new(118, 0.16, 8), Vector3.new(XC, G + 5.55, counterZ - 0.4), "Bright yellow", NEON, 0.34, true)
for i = 0, 5 do
	local gx = X1 + 36 + i * 24
	p("GrillBase", Vector3.new(13, 4, 8), Vector3.new(gx, G + 2, counterZ + 16), "Dark stone grey", DPLATE)
	p("GrillHeat", Vector3.new(11, 0.18, 6), Vector3.new(gx, G + 4.1, counterZ + 16), "Bright red", NEON, 0.28, true)
	cylinder("BurgerPattyProp", Vector3.new(1, 5.5, 5.5), CFrame.new(gx, G + 4.7, counterZ + 16) * C90Z, "Brown", SMP, 0.04)
end

-- Tables.
for row = 0, 3 do
	for col = 0, 4 do
		local tx = X1 + 48 + col * 52
		local tz = Z1 + 105 + row * 48
		cylinder("BurgerTable", Vector3.new(0.7, 10, 10), CFrame.new(tx, G + 3.8, tz) * C90Z, "Dark stone grey", DPLATE)
		cylinder("TableTrim", Vector3.new(0.8, 10.7, 10.7), CFrame.new(tx, G + 3.9, tz) * C90Z, (row + col) % 2 == 0 and "Bright yellow" or "Bright red", NEON, 0.68, true)
		p("TablePole", Vector3.new(0.7, 3.5, 0.7), Vector3.new(tx, G + 1.75, tz), "Really black", METAL)
		for _, off in { { -8, 0 }, { 8, 0 }, { 0, -8 }, { 0, 8 } } do
			cylinder("BurgerSeat", Vector3.new(0.45, 5.2, 5.2), CFrame.new(tx + off[1], G + 3.1, tz + off[2]) * C90Z, "Smoky grey", DPLATE)
		end
	end
end

-- Fries, soda towers, and neon burger props.
for _, pos in { { X1 + 34, Z2 - 42 }, { X2 - 34, Z2 - 42 }, { X1 + 45, Z1 + 86 }, { X2 - 45, Z1 + 86 } } do
	local fx, fz = pos[1], pos[2]
	p("FriesBox", Vector3.new(14, 12, 8), Vector3.new(fx, G + 6, fz), "Bright red", SMP)
	for i = -2, 2 do
		p("FryStick", Vector3.new(1.4, 16 + math.abs(i) * 2, 1.4), Vector3.new(fx + i * 2.2, G + 17, fz), "Bright yellow", NEON, 0.15, true)
	end
end
for _, sx in { X1 + 26, X2 - 26 } do
	cylinder("SodaCup", Vector3.new(18, 15, 15), CFrame.new(sx, G + 9, ZC) * C90Z, "Cyan", NEON, 0.25)
	cylinder("SodaStraw", Vector3.new(0.7, 22, 0.7), CFrame.new(sx + 4, G + 24, ZC) * C90X, "Institutional white", NEON, 0.08, true)
end

print("[BurgerHouseWorld] Built parallel Burger House successfully!")
