-- Metal Galactic Sports World
-- Sports bridge: z=780->860. Sports world: z=860->1020.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "SportsWorld"
folder.Parent = workspace

local SMP    = Enum.Material.SmoothPlastic
local NEON   = Enum.Material.Neon
local METAL  = Enum.Material.Metal
local DPLATE = Enum.Material.DiamondPlate
local CONCRETE = Enum.Material.DiamondPlate  -- replaced with DiamondPlate throughout

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

local function pcf(name, size, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
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
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 520, 0, 100)
	gui.StudsOffset = Vector3.new(0, 0, 0)
	gui.AlwaysOnTop = false
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
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

-- ==============================================
-- SPORTS BRIDGE
-- ==============================================
local BZ1, BZ2 = 780, 860
local BZC = (BZ1 + BZ2) / 2
local BLEN = BZ2 - BZ1

p("SportsBridgeFloor", Vector3.new(12, 0.5, BLEN), Vector3.new(0, G + 0.25, BZC), "Dark stone grey", DPLATE)
for bz = BZ1 + 4, BZ2 - 4, 8 do
	p("BridgeStripe", Vector3.new(10, 0.12, 0.35), Vector3.new(0, G + 0.56, bz), "Cyan", NEON, 0.45, true)
end
for _, x in { -6.3, 6.3 } do
	local r1 = p("BridgeRailTop", Vector3.new(0.35, 0.35, BLEN), Vector3.new(x, G + 3.8, BZC), "Cyan",    NEON, 0.15)
	local r2 = p("BridgeRailMid", Vector3.new(0.25, 0.25, BLEN), Vector3.new(x, G + 2.1, BZC), "Hot pink", NEON, 0.2)
	for bz = BZ1 + 5, BZ2 - 5, 10 do
		p("BridgePost", Vector3.new(0.45, 3.8, 0.45), Vector3.new(x, G + 1.9, bz), "Really black", METAL)
	end
end

local arch = p("SportsArchSign", Vector3.new(34, 5, 0.5), Vector3.new(0, G + 13, BZ2), "Really black", SMP, 0, true)
sign(arch, "SPORTS WORLD", Color3.fromRGB(80, 220, 255))
p("SportsArchL", Vector3.new(1.1, 13, 1.1), Vector3.new(-9, G + 6.5, BZ2), "Really black", METAL)
p("SportsArchR", Vector3.new(1.1, 13, 1.1), Vector3.new(9, G + 6.5, BZ2),  "Really black", METAL)
local archTop = p("SportsArchTop", Vector3.new(20, 1, 1), Vector3.new(0, G + 13, BZ2), "Cyan", NEON, 0.1)

-- ==============================================
-- SPORTS WORLD GROUND  – dark metal diamond plate
-- ==============================================
local SZ1, SZ2 = 860, 1020
local SZC = (SZ1 + SZ2) / 2
local HW = 82

p("SportsFieldBase", Vector3.new(HW * 2, 2, SZ2 - SZ1), Vector3.new(0, 0, SZC), "Really black", DPLATE)
p("CenterWalk", Vector3.new(8, 0.15, SZ2 - SZ1), Vector3.new(0, G + 0.08, SZC), "Smoky grey", DPLATE, 0, true)

-- Neon grid on floor
for xi = -HW, HW, 16 do
	local gp = p("GridZ", Vector3.new(0.14, 0.06, SZ2-SZ1), Vector3.new(xi, G+0.09, SZC), "Cyan",    NEON, 0.6, true)
end
for zi = SZ1, SZ2, 16 do
	local gp = p("GridX", Vector3.new(HW*2,  0.06, 0.14),  Vector3.new(0, G+0.1, zi),     "Hot pink", NEON, 0.65, true)
end

local FH = 6
local CW = 34
for _, x in { -HW, HW } do
	local fw = p("FenceSide",   Vector3.new(0.5, FH, SZ2 - SZ1), Vector3.new(x, G + FH / 2, SZC), "Really black", METAL, 0.25)
	local cn = p("ContainSide", Vector3.new(0.5, CW, SZ2 - SZ1), Vector3.new(x, G + CW / 2, SZC), "Really black", SMP,   1)
	-- Neon fence glow
	local fg = p("FenceGlow", Vector3.new(0.2, FH, SZ2-SZ1), Vector3.new(x, G+FH/2, SZC), "Cyan", NEON, 0.4)
end
p("FenceNorthL", Vector3.new(HW - 7, FH, 0.5), Vector3.new(-(HW + 7) / 2, G + FH / 2, SZ1), "Really black", METAL, 0.25)
p("FenceNorthR", Vector3.new(HW - 7, FH, 0.5), Vector3.new((HW + 7) / 2, G + FH / 2,  SZ1), "Really black", METAL, 0.25)
p("FenceSouthL", Vector3.new(HW - 7, FH, 0.5), Vector3.new(-(HW + 7) / 2, G + FH / 2, SZ2), "Really black", METAL, 0.25)
p("FenceSouthR", Vector3.new(HW - 7, FH, 0.5), Vector3.new((HW + 7) / 2, G + FH / 2,  SZ2), "Really black", METAL, 0.25)
p("ContainNorthL", Vector3.new(HW - 7, CW, 0.5), Vector3.new(-(HW + 7) / 2, G + CW / 2, SZ1), "Really black", SMP, 1)
p("ContainNorthR", Vector3.new(HW - 7, CW, 0.5), Vector3.new((HW + 7) / 2, G + CW / 2,  SZ1), "Really black", SMP, 1)
p("ContainSouthL", Vector3.new(HW - 7, CW, 0.5), Vector3.new(-(HW + 7) / 2, G + CW / 2, SZ2), "Really black", SMP, 1)
p("ContainSouthR", Vector3.new(HW - 7, CW, 0.5), Vector3.new((HW + 7) / 2, G + CW / 2,  SZ2), "Really black", SMP, 1)

-- ==============================================
-- HOLO BASKETBALL COURT
-- ==============================================
local BCX, BCZ = -42, 930
local BW, BD = 66, 104

-- Court surface: dark carbon fiber style
p("BasketCourt", Vector3.new(BW, 0.25, BD), Vector3.new(BCX, G + 0.13, BCZ), "Dark stone grey", DPLATE)
-- Court lines in cyan neon
p("BasketCenterLine", Vector3.new(BW, 0.08, 0.45), Vector3.new(BCX, G + 0.3, BCZ), "Cyan", NEON, 0.15, true)
p("BasketSidelineN",  Vector3.new(BW, 0.08, 0.45), Vector3.new(BCX, G + 0.3, BCZ - BD / 2), "Cyan", NEON, 0.15, true)
p("BasketSidelineS",  Vector3.new(BW, 0.08, 0.45), Vector3.new(BCX, G + 0.3, BCZ + BD / 2), "Cyan", NEON, 0.15, true)
p("BasketLineW", Vector3.new(0.45, 0.08, BD), Vector3.new(BCX - BW / 2, G + 0.3, BCZ), "Cyan", NEON, 0.15, true)
p("BasketLineE", Vector3.new(0.45, 0.08, BD), Vector3.new(BCX + BW / 2, G + 0.3, BCZ), "Cyan", NEON, 0.15, true)
for _, z in { BCZ - 31, BCZ + 31 } do
	p("FreeThrowBox", Vector3.new(24, 0.08, 0.45), Vector3.new(BCX, G + 0.32, z), "Cyan", NEON, 0.2, true)
	local pa = p("PaintArea", Vector3.new(24, 0.1, 24), Vector3.new(BCX, G + 0.22, z + (z < BCZ and -12 or 12)), "Dark indigo", NEON, 0.55, true)
end
cylinder("BasketCenterCircle", Vector3.new(0.12, 18, 18), CFrame.new(BCX, G + 0.35, BCZ) * C90Z, "Cyan", NEON, 0.2, true)

local function hoop(z, dir)
	p("HoopPole",   Vector3.new(0.7, 12, 0.7), Vector3.new(BCX, G + 6, z),          "Really black", METAL)
	p("Backboard",  Vector3.new(16, 9, 0.45),  Vector3.new(BCX, G + 11, z + dir * 1.2), "Dark stone grey", DPLATE, 0.1)
	local bsq = p("BackboardSq", Vector3.new(6, 4, 0.5), Vector3.new(BCX, G + 10.5, z + dir * 0.9), "Cyan", NEON, 0.2, true)
	cylinder("Rim", Vector3.new(0.28, 5, 5), CFrame.new(BCX, G + 8.7, z + dir * 3) * C90X, "Hot pink", NEON, 0, true)
	for x = -2, 2, 1 do
		p("NetCord", Vector3.new(0.08, 3, 0.08), Vector3.new(BCX + x, G + 7.2, z + dir * 3), "Cyan", NEON, 0.35, true)
	end
end
hoop(BCZ - BD / 2 + 4, 1)
hoop(BCZ + BD / 2 - 4, -1)

-- Decor balls: neon energy spheres instead of basketballs
for _, pos in { {BCX - 15, BCZ - 15}, {BCX + 16, BCZ + 18}, {BCX, BCZ} } do
	local b = ball("DecorOrb", Vector3.new(pos[1], G + 1.25, pos[2]), 2.4, "Hot pink", NEON, 0.1, false)
	cylinder("OrbRing", Vector3.new(0.05, 2.6, 2.6), CFrame.new(pos[1], G + 1.25, pos[2]) * C90Z, "Cyan", NEON, 0.3, true)
end

-- ==============================================
-- NEON SOCCER COURT
-- ==============================================
local SCX, SCZ = 44, 930
local SW, SD = 70, 118

-- Court surface: dark metal
p("SoccerPitch", Vector3.new(SW, 0.22, SD), Vector3.new(SCX, G + 0.12, SCZ), "Dark stone grey", DPLATE)
-- Alternating neon stripe zones (subtle)
for i = 0, 6 do
	local col = (i % 2 == 0) and "Dark stone grey" or "Smoky grey"
	local mat = (i % 2 == 0) and DPLATE or METAL
	p("FieldStripe", Vector3.new(SW, 0.04, SD / 7), Vector3.new(SCX, G + 0.26, SCZ - SD / 2 + SD / 14 + i * SD / 7), col, mat, 0.05, true)
end
-- Lines in cyan neon
p("SoccerMidLine", Vector3.new(SW, 0.08, 0.4), Vector3.new(SCX, G + 0.36, SCZ), "Cyan", NEON, 0.1, true)
p("SoccerNLine",   Vector3.new(SW, 0.08, 0.4), Vector3.new(SCX, G + 0.36, SCZ - SD / 2), "Cyan", NEON, 0.1, true)
p("SoccerSLine",   Vector3.new(SW, 0.08, 0.4), Vector3.new(SCX, G + 0.36, SCZ + SD / 2), "Cyan", NEON, 0.1, true)
p("SoccerWLine",   Vector3.new(0.4, 0.08, SD),  Vector3.new(SCX - SW / 2, G + 0.36, SCZ), "Cyan", NEON, 0.1, true)
p("SoccerELine",   Vector3.new(0.4, 0.08, SD),  Vector3.new(SCX + SW / 2, G + 0.36, SCZ), "Cyan", NEON, 0.1, true)
cylinder("SoccerCenterCircle", Vector3.new(0.1, 20, 20), CFrame.new(SCX, G + 0.4, SCZ) * C90Z, "Cyan", NEON, 0.2, true)
p("PenaltyN", Vector3.new(38, 0.08, 0.4), Vector3.new(SCX, G + 0.4, SCZ - SD / 2 + 21), "Hot pink", NEON, 0.15, true)
p("PenaltyS", Vector3.new(38, 0.08, 0.4), Vector3.new(SCX, G + 0.4, SCZ + SD / 2 - 21), "Hot pink", NEON, 0.15, true)

local function goal(z, dir)
	p("GoalBarTop", Vector3.new(20, 0.45, 0.45), Vector3.new(SCX, G + 7, z), "Smoky grey",      METAL)
	p("GoalPostL",  Vector3.new(0.45, 7, 0.45), Vector3.new(SCX - 10, G + 3.5, z), "Smoky grey", METAL)
	p("GoalPostR",  Vector3.new(0.45, 7, 0.45), Vector3.new(SCX + 10, G + 3.5, z), "Smoky grey", METAL)
	-- Neon goal glow
	local gg = p("GoalGlow", Vector3.new(20, 0.2, 0.2), Vector3.new(SCX, G+7.3, z), "Cyan", NEON, 0.15, true)
	for x = -9, 9, 3 do
		p("GoalNetV", Vector3.new(0.08, 6.5, 0.08), Vector3.new(SCX + x, G + 3.3, z + dir * 3), "Cyan", NEON, 0.5, true)
	end
	for y = 2, 6, 2 do
		p("GoalNetH", Vector3.new(19, 0.08, 0.08), Vector3.new(SCX, G + y, z + dir * 3), "Cyan", NEON, 0.5, true)
	end
end
goal(SCZ - SD / 2 + 1.5, 1)
goal(SCZ + SD / 2 - 1.5, -1)

-- Decor energy balls
for _, pos in { {SCX, SCZ}, {SCX - 18, SCZ + 25}, {SCX + 19, SCZ - 28} } do
	ball("EnergyBall", Vector3.new(pos[1], G + 1.1, pos[2]), 2.2, "Bright violet", NEON, 0.1, false)
	ball("EnergySpot", Vector3.new(pos[1], G + 1.45, pos[2] - 0.75), 0.55, "Cyan", NEON, 0.1, true)
	ball("EnergySpot", Vector3.new(pos[1] + 0.75, G + 1.2, pos[2] + 0.35), 0.45, "Hot pink", NEON, 0.1, true)
	ball("EnergySpot", Vector3.new(pos[1] - 0.75, G + 1.2, pos[2] + 0.35), 0.45, "Hot pink", NEON, 0.1, true)
end

-- Stadium – neon flood lights
for _, x in { -72, 72 } do
	for z = SZ1 + 22, SZ2 - 22, 22 do
		p("LightPole",  Vector3.new(0.7, 18, 0.7), Vector3.new(x, G + 9, z),       "Really black", METAL)
		local fl = p("FloodLight", Vector3.new(5, 2, 1), Vector3.new(x, G + 18.8, z), "Cyan", NEON, 0.12, true)
	end
end

-- Bleachers – dark metal
for _, x in { -62, 62 } do
	for z = SZ1 + 28, SZ2 - 28, 18 do
		p("BleacherStep", Vector3.new(18, 0.8, 5), Vector3.new(x, G + 0.4, z), "Dark stone grey", DPLATE)
		p("BleacherSeat", Vector3.new(18, 0.4, 4), Vector3.new(x, G + 2.0, z + 1.5), "Dark indigo", SMP)
		local bs = p("BleacherBack", Vector3.new(18, 2, 0.4), Vector3.new(x, G + 3.0, z + 3.4), "Dark indigo", SMP)
		-- Seat glow strip
		local sg = p("SeatGlow", Vector3.new(18, 0.1, 0.2), Vector3.new(x, G+2.25, z+1.5), "Cyan", NEON, 0.4, true)
	end
end

local courtSign = p("CourtSign", Vector3.new(40, 4.5, 0.5), Vector3.new(0, G + 11, SZ1 + 5), "Really black", SMP, 0, true)
sign(courtSign, "HOLO SPORTS ARENA", Color3.fromRGB(80, 220, 255))

print("[SportsWorld] Metal Galactic (Holo Sports Arena) theme built successfully!")
