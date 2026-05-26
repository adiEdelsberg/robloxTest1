-- Galactic Bridge (z=270->385) and Galactic Zone (z=385->525)

local G = 1  -- ground Y

local folder = Instance.new("Folder")
folder.Name   = "GalacticZone"
folder.Parent = workspace

local PI = math.pi

local function p(name, sz, pos, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name         = name
	part.Size         = sz
	part.Position     = pos
	part.BrickColor   = BrickColor.new(color)
	part.Material     = mat or Enum.Material.SmoothPlastic
	part.Anchored     = true
	part.CanCollide   = not noCollide
	part.CastShadow   = false
	part.TopSurface   = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = trans or 0
	part.Parent       = folder
	return part
end

local function pcf(name, sz, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name         = name
	part.Size         = sz
	part.CFrame       = cf
	part.BrickColor   = BrickColor.new(color)
	part.Material     = mat or Enum.Material.SmoothPlastic
	part.Anchored     = true
	part.CanCollide   = not noCollide
	part.CastShadow   = false
	part.TopSurface   = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = trans or 0
	part.Parent       = folder
	return part
end

local function ball(name, pos, sz, color, mat, trans)
	local part = Instance.new("Part")
	part.Name = name; part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(sz, sz, sz); part.Position = pos
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or Enum.Material.Neon
	part.Anchored = true; part.CanCollide = false; part.CastShadow = false
	part.Transparency = trans or 0; part.Parent = folder
	return part
end

-- ==============================================
-- GALACTIC BRIDGE   z = 270 -> 385
-- ==============================================
local BZ1, BZ2 = 270, 385
local BZC  = (BZ1 + BZ2) / 2   -- 327.5
local BLen = BZ2 - BZ1          -- 115

-- Walkway: solid black floor
p("BridgeFloor", Vector3.new(10, 0.5, BLen), Vector3.new(0, G + 0.25, BZC), "Really black")

-- Wider visible connector so the Pizza -> Galactic route is clear.
p("PizzaGalacticBridgeDeck", Vector3.new(22, 0.65, BLen + 6), Vector3.new(0, G + 0.58, BZC), "Dark stone grey", Enum.Material.DiamondPlate)
p("PizzaGalacticBridgeCenter", Vector3.new(12, 0.16, BLen - 8), Vector3.new(0, G + 0.98, BZC), "Bright violet", Enum.Material.Neon, 0.48, true)
for bz = BZ1 + 6, BZ2 - 6, 9 do
	p("PizzaGalacticBridgeStripe", Vector3.new(18, 0.18, 0.8), Vector3.new(0, G + 1.08, bz), (bz % 18 == 0) and "Cyan" or "Magenta", Enum.Material.Neon, 0.18, true)
end
for _, x in { -11.2, 11.2 } do
	p("PizzaGalacticBridgeRailTop", Vector3.new(0.45, 0.45, BLen + 4), Vector3.new(x, G + 4.8, BZC), "Cyan", Enum.Material.Neon, 0.08, true)
	p("PizzaGalacticBridgeRailMid", Vector3.new(0.35, 0.35, BLen + 4), Vector3.new(x, G + 2.65, BZC), "Magenta", Enum.Material.Neon, 0.18, true)
	for bz = BZ1 + 5, BZ2 - 5, 11 do
		p("PizzaGalacticBridgePost", Vector3.new(0.6, 4.5, 0.6), Vector3.new(x, G + 2.35, bz), "Really black", Enum.Material.Metal)
	end
end
for _, z in { 272, 385 } do
	p("PizzaGalacticLandingPad", Vector3.new(28, 0.5, 8), Vector3.new(0, G + 0.72, z), "Really black", Enum.Material.DiamondPlate)
	p("PizzaGalacticLandingGlow", Vector3.new(20, 0.14, 3.5), Vector3.new(0, G + 1.04, z), "Cyan", Enum.Material.Neon, 0.35, true)
end

-- Neon edge strips every 7 studs, alternating cyan / magenta
do
	local cols = { "Cyan", "Magenta" }
	local i = 0
	for bz = BZ1, BZ2 - 1, 7 do
		i += 1
		p("Strip", Vector3.new(10, 0.12, 0.5),
			Vector3.new(0, G + 0.52, bz), cols[(i % 2) + 1], Enum.Material.Neon, 0, true)
	end
end

-- Continuous neon rails both sides
p("RailLT",  Vector3.new(0.3, 0.3, BLen), Vector3.new(-5.3, G + 4.5, BZC), "Cyan",    Enum.Material.Neon, 0,   true)
p("RailRT",  Vector3.new(0.3, 0.3, BLen), Vector3.new( 5.3, G + 4.5, BZC), "Cyan",    Enum.Material.Neon, 0,   true)
p("RailLB",  Vector3.new(0.3, 0.3, BLen), Vector3.new(-5.3, G + 2,   BZC), "Magenta", Enum.Material.Neon, 0.3, true)
p("RailRB",  Vector3.new(0.3, 0.3, BLen), Vector3.new( 5.3, G + 2,   BZC), "Magenta", Enum.Material.Neon, 0.3, true)

-- Vertical posts connecting rails to floor
for pz = BZ1 + 5, BZ2 - 5, 11 do
	p("PostL", Vector3.new(0.3, 4.5, 0.3), Vector3.new(-5.3, G + 2.25, pz), "Dark indigo", Enum.Material.Neon, 0, true)
	p("PostR", Vector3.new(0.3, 4.5, 0.3), Vector3.new( 5.3, G + 2.25, pz), "Dark indigo", Enum.Material.Neon, 0, true)
end

-- Portal arch frames (rectangular gate shape, every ~23 studs)
for _, az in { 271, 294, 317, 340, 363, 385 } do
	p("ArchL",   Vector3.new(0.9, 18, 0.9),   Vector3.new(-6,   G + 9,    az), "Dark indigo", Enum.Material.Neon)
	p("ArchR",   Vector3.new(0.9, 18, 0.9),   Vector3.new( 6,   G + 9,    az), "Dark indigo", Enum.Material.Neon)
	p("ArchTop", Vector3.new(13.8, 0.9, 0.9), Vector3.new( 0,   G + 18.4, az), "Cyan",        Enum.Material.Neon)
	p("ArchGlow",Vector3.new(12,   0.4, 0.4), Vector3.new( 0,   G + 17.5, az), "Magenta",     Enum.Material.Neon, 0.35, true)
end

-- Entry sign on pizza side (z=270)
local bridgeSign = p("BridgeSign", Vector3.new(14, 4, 0.4), Vector3.new(0, G + 21, 270), "Dark indigo", Enum.Material.Neon, 0.2, true)
local bsBg = Instance.new("BillboardGui")
bsBg.Size = UDim2.new(0, 300, 0, 80); bsBg.StudsOffset = Vector3.new(0, 0, 0); bsBg.Parent = bridgeSign
local bsLbl = Instance.new("TextLabel")
bsLbl.Size = UDim2.new(1, 0, 1, 0); bsLbl.BackgroundTransparency = 1
bsLbl.Text = "GALACTIC BRIDGE"
bsLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
bsLbl.Font = Enum.Font.GothamBold; bsLbl.TextScaled = true
bsLbl.TextStrokeTransparency = 0; bsLbl.Parent = bsBg

-- Floating stars alongside bridge
math.randomseed(12345)
for i = 1, 55 do
	local side  = (i % 2 == 0) and 1 or -1
	local x     = side * math.random(9, 28)
	local y     = math.random(2, 22)
	local bz    = math.random(BZ1, BZ2)
	local s     = math.random(2, 9) * 0.12
	local cols  = { "White", "Cyan", "Magenta", "Bright violet" }
	ball("Star", Vector3.new(x, y, bz), s, cols[(i % 4) + 1], Enum.Material.Neon, math.random(0, 25) / 100)
end

-- Side void panels removed so the galactic area blends with the map instead of sitting in a black box.

-- ==============================================
-- GALACTIC ZONE   z = 385 -> 525
-- ==============================================
local GZ1, GZ2 = 385, 525
local GZC  = (GZ1 + GZ2) / 2   -- 455
local GHW  = 70                  -- half-width  (x = -70 to 70)

-- Deep space floor, kept visible without the old black void border.
p("GalacticFloor", Vector3.new(GHW * 2, 2, GZ2 - GZ1), Vector3.new(0, 0, GZC), "Dark indigo")

-- Neon grid overlay
local gStep = 14
for xi = -GHW, GHW, gStep do
	p("GridZ", Vector3.new(0.2, 0.1, GZ2 - GZ1), Vector3.new(xi, G + 0.06, GZC), "Cyan", Enum.Material.Neon, 0.25, true)
end
for zi = GZ1, GZ2, gStep do
	p("GridX", Vector3.new(GHW * 2, 0.1, 0.2), Vector3.new(0, G + 0.06, zi), "Cyan", Enum.Material.Neon, 0.25, true)
end

-- Perimeter neon walls (semi-transparent glow barriers)
local wallH = 9
local BG    = 6  -- bridge gap half-width (bridge is x=-5 to +5, arch posts at ±6)
local CW    = 130 -- invisible containment wall height (galactic NPCs jump up to ~102 studs)

-- North wall: split around bridge entrance (x=-6 to +6 open)
p("WallNL", Vector3.new(GHW - BG, wallH, 0.6), Vector3.new(-(GHW + BG) / 2, G + wallH / 2, GZ1), "Dark indigo", Enum.Material.Neon, 0.5)
p("WallNR", Vector3.new(GHW - BG, wallH, 0.6), Vector3.new( (GHW + BG) / 2, G + wallH / 2, GZ1), "Dark indigo", Enum.Material.Neon, 0.5)
-- South wall: noCollide so players can exit to jungle bridge; gate at z=524 controls access
p("WallS", Vector3.new(GHW * 2, wallH, 0.6), Vector3.new(0,     G + wallH / 2, GZ2), "Dark indigo", Enum.Material.Neon, 0.5, true)
p("WallE", Vector3.new(0.6, wallH, GZ2 - GZ1), Vector3.new( GHW, G + wallH / 2, GZC), "Dark indigo", Enum.Material.Neon, 0.5)
p("WallW", Vector3.new(0.6, wallH, GZ2 - GZ1), Vector3.new(-GHW, G + wallH / 2, GZC), "Dark indigo", Enum.Material.Neon, 0.5)

-- Invisible containment walls (CW studs tall — high enough to block 102-stud galactic jumps)
-- East / West
p("ContainE", Vector3.new(0.5, CW, GZ2 - GZ1), Vector3.new( GHW, G + CW / 2, GZC), "Really black", Enum.Material.SmoothPlastic, 1)
p("ContainW", Vector3.new(0.5, CW, GZ2 - GZ1), Vector3.new(-GHW, G + CW / 2, GZC), "Really black", Enum.Material.SmoothPlastic, 1)
-- North: split for bridge (same gap as visible wall)
p("ContainNL", Vector3.new(GHW - BG, CW, 0.5), Vector3.new(-(GHW + BG) / 2, G + CW / 2, GZ1), "Really black", Enum.Material.SmoothPlastic, 1)
p("ContainNR", Vector3.new(GHW - BG, CW, 0.5), Vector3.new( (GHW + BG) / 2, G + CW / 2, GZ1), "Really black", Enum.Material.SmoothPlastic, 1)
-- South: split around gate gap (gate is 14 studs wide = ±7); keeps players' path open
p("ContainSL", Vector3.new(GHW - 7, CW, 0.5), Vector3.new(-(GHW + 7) / 2, G + CW / 2, GZ2), "Really black", Enum.Material.SmoothPlastic, 1)
p("ContainSR", Vector3.new(GHW - 7, CW, 0.5), Vector3.new( (GHW + 7) / 2, G + CW / 2, GZ2), "Really black", Enum.Material.SmoothPlastic, 1)

-- Kill zones outside galactic area
-- (removed)

-- ---- Giant Planet ----
ball("Planet", Vector3.new(0, 58, GZC), 62, "Bright violet", Enum.Material.Neon, 0.08)
-- Rings (cylinders rotated sideways)
pcf("Ring1", Vector3.new(0.7, 95, 95),
	CFrame.new(0, 58, GZC) * CFrame.Angles(math.rad(18), 0, math.rad(90)),
	"Cyan", Enum.Material.Neon, 0.22, true)
pcf("Ring2", Vector3.new(0.4, 110, 110),
	CFrame.new(0, 58, GZC) * CFrame.Angles(math.rad(30), 0, math.rad(90)),
	"Magenta", Enum.Material.Neon, 0.42, true)

-- ---- Crystal Towers ----
local function crystal(x, z, h, col)
	p("Crystal", Vector3.new(2.5, h, 2.5), Vector3.new(x, G + h / 2, z), col, Enum.Material.Neon, 0.1)
	ball("CrystalTip", Vector3.new(x, G + h + 1.8, z), 3.5, col, Enum.Material.Neon, 0.15)
end

crystal(-62, GZ1 + 18, 26, "Cyan")
crystal( 62, GZ1 + 18, 20, "Magenta")
crystal(-62, GZ2 - 18, 22, "Magenta")
crystal( 62, GZ2 - 18, 28, "Cyan")
crystal(-32, GZC,      18, "Bright violet")
crystal( 32, GZC,      16, "Cyan")

-- ---- Space Station (NE quadrant) ----
local SX, SZ = 32, GZ1 + 52
p("StationBase",  Vector3.new(22, 1.5, 22), Vector3.new(SX, G + 0.75, SZ), "Dark stone grey", Enum.Material.Metal)
p("StationBody",  Vector3.new(14, 14, 14), Vector3.new(SX, G + 1.5 + 7, SZ), "Dark stone grey", Enum.Material.Metal)
p("PanelN", Vector3.new(14.3, 5, 0.2), Vector3.new(SX,     G + 9, SZ - 7), "Cyan",    Enum.Material.Neon, 0.3, true)
p("PanelS", Vector3.new(14.3, 5, 0.2), Vector3.new(SX,     G + 9, SZ + 7), "Magenta", Enum.Material.Neon, 0.3, true)
p("PanelE", Vector3.new(0.2, 5, 14.3), Vector3.new(SX + 7, G + 9, SZ),     "Cyan",    Enum.Material.Neon, 0.3, true)
p("PanelW", Vector3.new(0.2, 5, 14.3), Vector3.new(SX - 7, G + 9, SZ),     "Magenta", Enum.Material.Neon, 0.3, true)
p("Antenna", Vector3.new(0.6, 18, 0.6), Vector3.new(SX, G + 1.5 + 14 + 9, SZ), "Medium stone grey", Enum.Material.Metal, 0, true)
ball("AntTip", Vector3.new(SX, G + 1.5 + 14 + 18 + 1, SZ), 2.5, "Bright red", Enum.Material.Neon)
p("WingL", Vector3.new(24, 0.4, 5), Vector3.new(SX - 19, G + 16, SZ), "Dark stone grey", Enum.Material.Metal)
p("WingR", Vector3.new(24, 0.4, 5), Vector3.new(SX + 19, G + 16, SZ), "Dark stone grey", Enum.Material.Metal)
p("SolarL", Vector3.new(22, 0.2, 9), Vector3.new(SX - 19, G + 16.1, SZ), "Dark blue", Enum.Material.Neon, 0.4, true)
p("SolarR", Vector3.new(22, 0.2, 9), Vector3.new(SX + 19, G + 16.1, SZ), "Dark blue", Enum.Material.Neon, 0.4, true)

-- ---- Nebula clouds ----
for _, nb in {
	{  52, 20, GZ1 + 48, "Bright violet", 0.72 },
	{ -52, 16, GZC + 18, "Cyan",          0.77 },
	{  18, 38, GZ2 - 44, "Magenta",       0.80 },
} do
	ball("Nebula", Vector3.new(nb[1], nb[2], nb[3]), 38, nb[4], Enum.Material.Neon, nb[5])
end

-- ---- Asteroids ----
local astCols = { "Dark stone grey", "Medium stone grey", "Dark indigo" }
math.randomseed(99991)
for i = 1, 22 do
	local ax = (i % 2 == 0 and 1 or -1) * math.random(16, 62)
	local ay = math.random(6, 40)
	local az = math.random(GZ1 + 12, GZ2 - 12)
	local as = math.random(4, 14)
	local ast = Instance.new("Part")
	ast.Name = "Asteroid"; ast.Shape = Enum.PartType.Ball
	ast.Size = Vector3.new(as, as * 0.65, as * 0.8)
	ast.Position = Vector3.new(ax, ay, az)
	ast.Anchored = true; ast.CanCollide = false; ast.CastShadow = false
	ast.Material = Enum.Material.SmoothPlastic
	ast.BrickColor = BrickColor.new(astCols[(i % 3) + 1])
	ast.Parent = folder
end

-- ---- Star field ----
local starCols = { "White", "Cyan", "Magenta", "Bright violet", "Bright yellow" }
math.randomseed(77773)
for i = 1, 130 do
	local x = math.random(-66, 66)
	local y = math.random(4, 75)
	local z = math.random(GZ1, GZ2)
	local s = math.random(1, 7) * 0.15
	ball("Star", Vector3.new(x, y, z), s, starCols[(i % 5) + 1], Enum.Material.Neon, math.random(0, 30) / 100)
end

-- ---- Entrance sign ----
local gzsign = p("GZSign", Vector3.new(24, 5, 0.5), Vector3.new(0, G + 14, GZ1 + 1), "Dark indigo", Enum.Material.Neon, 0.2, true)
local gzBg = Instance.new("BillboardGui")
gzBg.Size = UDim2.new(0, 480, 0, 100); gzBg.StudsOffset = Vector3.new(0, 0, 0); gzBg.Parent = gzsign
local gzLbl = Instance.new("TextLabel")
gzLbl.Size = UDim2.new(1, 0, 1, 0); gzLbl.BackgroundTransparency = 1
gzLbl.Text = "GALACTIC ZONE"
gzLbl.TextColor3 = Color3.fromRGB(180, 0, 255)
gzLbl.Font = Enum.Font.GothamBold; gzLbl.TextScaled = true
gzLbl.TextStrokeTransparency = 0; gzLbl.Parent = gzBg

print("[GalacticZone] Built successfully!")
