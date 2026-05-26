-- Crystal Depths Bridge (z=525->640) and Crystal Depths Zone (z=640->780)
-- Metal Galactic theme: dark metal floors, neon crystal formations, energy vines

local G = 1  -- ground Y

math.randomseed(31415)

local folder = Instance.new("Folder")
folder.Name   = "JungleZone"
folder.Parent = workspace

local SMP    = Enum.Material.SmoothPlastic
local NEON   = Enum.Material.Neon
local METAL  = Enum.Material.Metal
local DPLATE = Enum.Material.DiamondPlate
local SLATE  = Enum.Material.Metal  -- repurposed

local C90Z = CFrame.Angles(0, 0, math.rad(90))
local C90X = CFrame.Angles(math.rad(90), 0, 0)

local function p(name, sz, pos, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name          = name
	part.Size          = sz
	part.Position      = pos
	part.BrickColor    = BrickColor.new(color)
	part.Material      = mat or SMP
	part.Anchored      = true
	part.CanCollide    = not noCollide
	part.CastShadow    = false
	part.TopSurface    = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency  = trans or 0
	part.Parent        = folder
	return part
end

local function pcf(name, sz, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name          = name
	part.Size          = sz
	part.CFrame        = cf
	part.BrickColor    = BrickColor.new(color)
	part.Material      = mat or SMP
	part.Anchored      = true
	part.CanCollide    = not noCollide
	part.CastShadow    = false
	part.TopSurface    = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency  = trans or 0
	part.Parent        = folder
	return part
end

local function cylinder(name, sz, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name         = name
	part.Shape        = Enum.PartType.Cylinder
	part.Size         = sz
	part.CFrame       = cf
	part.BrickColor   = BrickColor.new(color)
	part.Material     = mat or SMP
	part.Anchored     = true
	part.CanCollide   = not noCollide
	part.CastShadow   = false
	part.Transparency = trans or 0
	part.Parent       = folder
	return part
end

local function ball(name, pos, sz, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name        = name
	part.Shape       = Enum.PartType.Ball
	part.Size        = Vector3.new(sz, sz, sz)
	part.Position    = pos
	part.BrickColor  = BrickColor.new(color)
	part.Material    = mat or SMP
	part.Anchored    = true
	part.CanCollide  = not noCollide
	part.CastShadow  = false
	part.Transparency = trans or 0
	part.Parent      = folder
	return part
end

-- ==============================================
-- CRYSTAL DEPTHS BRIDGE   z = 525 -> 640
-- ==============================================
local BZ1, BZ2 = 525, 640
local BZC  = (BZ1 + BZ2) / 2
local BLen = BZ2 - BZ1

-- Metal grating base
p("BridgeBase", Vector3.new(10, 0.4, BLen), Vector3.new(0, G + 0.2, BZC), "Dark stone grey", DPLATE)
for bz = BZ1 + 2, BZ2 - 2, 2.5 do
	p("Plank", Vector3.new(9.6, 0.25, 2), Vector3.new(0, G + 0.45, bz), "Smoky grey", DPLATE, 0, true)
end

-- Neon energy railings (replaced rope)
for _, vx in { -5.3, 5.3 } do
	local r1 = p("RailTop", Vector3.new(0.35, 0.35, BLen), Vector3.new(vx, G + 4.2, BZC), "Cyan",    NEON, 0.15, true)
	local r2 = p("RailMid", Vector3.new(0.35, 0.35, BLen), Vector3.new(vx, G + 2.3, BZC), "Cyan",    NEON, 0.2,  true)
	local r3 = p("RailBot", Vector3.new(0.35, 0.35, BLen), Vector3.new(vx, G + 1.1, BZC), "Hot pink", NEON, 0.25, true)
end

-- Metal support poles
for pz = BZ1 + 5, BZ2 - 5, 10 do
	p("PoleL", Vector3.new(0.65, 4.8, 0.65), Vector3.new(-5.3, G + 2.4, pz), "Dark stone grey", METAL, 0, true)
	p("PoleR", Vector3.new(0.65, 4.8, 0.65), Vector3.new( 5.3, G + 2.4, pz), "Dark stone grey", METAL, 0, true)
end

-- Energy cable strands (replaced vines)
for _, vx in { -3, 0, 3 } do
	for vz = BZ1 + 8, BZ2 - 8, 10 do
		local vlen = 4 + math.random(0, 3)
		local ec = cylinder("EnergyCable", Vector3.new(0.13, vlen, 0.13),
			CFrame.new(vx, G + 3.5, vz) * C90X, "Cyan", NEON, 0.2, true)
	end
end

-- Neon floor glow patches
for i = 1, 6 do
	local mz = BZ1 + 18 + i * 16
	local gp = p("FloorGlow", Vector3.new(1.5, 0.1, 1.2), Vector3.new(math.random(-3, 3), G + 0.46, mz), "Hot pink", NEON, 0.4, true)
end

-- Arch at galactic entry (z=525) – dark metal arch with neon
p("ArchL525", Vector3.new(1.2, 12, 1.2), Vector3.new(-6.5, G + 6,    525), "Dark stone grey", METAL)
p("ArchR525", Vector3.new(1.2, 12, 1.2), Vector3.new( 6.5, G + 6,    525), "Dark stone grey", METAL)
local at1 = p("ArchT525", Vector3.new(15, 1, 0.8), Vector3.new(0, G + 12.5, 525), "Cyan", NEON)
at1.Transparency = 0.15
for vx = -5, 5, 2 do
	local vlen = 2.5 + math.abs(math.sin(vx * 0.5)) * 2
	cylinder("AV525", Vector3.new(0.14, vlen, 0.14),
		CFrame.new(vx, G + 12.5 - vlen * 0.5, 525) * C90X, "Cyan", NEON, 0.3, true)
end

-- Arch at zone entry (z=640) – larger, more neon
p("ArchL640", Vector3.new(1.6, 16, 1.6), Vector3.new(-7.5, G + 8,    640), "Dark stone grey", METAL)
p("ArchR640", Vector3.new(1.6, 16, 1.6), Vector3.new( 7.5, G + 8,    640), "Dark stone grey", METAL)
local at2 = p("ArchT640", Vector3.new(17, 1.2, 0.8), Vector3.new(0, G + 16.6, 640), "Hot pink", NEON)
at2.Transparency = 0.1
for vx = -6.5, 6.5, 1.2 do
	local vlen = 3.5 + math.sin(vx * 0.55) * 2 + 2
	cylinder("AV640", Vector3.new(0.18, vlen, 0.18),
		CFrame.new(vx, G + 16.6 - vlen * 0.5, 640) * C90X, "Cyan", NEON, 0.25, true)
end
for _, px in { -7.5, 7.5 } do
	cylinder("PostCable", Vector3.new(0.45, 14, 0.45),
		CFrame.new(px + 0.9, G + 8, 640) * C90Z, "Hot pink", NEON, 0.15, true)
end

-- ==============================================
-- CRYSTAL DEPTHS ZONE   z = 640 -> 780
-- ==============================================
local JZ1, JZ2 = 640, 780
local JZC  = (JZ1 + JZ2) / 2
local JHW  = 70

-- ---- GROUND – dark metal floor ----
p("CrystalFloor",  Vector3.new(JHW * 2, 3, JZ2 - JZ1), Vector3.new(0, -1, JZC), "Really black", DPLATE)
p("FloorSurface",  Vector3.new(JHW * 2, 0.3, JZ2 - JZ1), Vector3.new(0, G + 0.15, JZC), "Dark stone grey", DPLATE)

-- Neon floor grid
for xi = -JHW, JHW, 14 do
	local gp = p("GridZ2", Vector3.new(0.14, 0.06, JZ2-JZ1), Vector3.new(xi, G+0.22, JZC), "Cyan", NEON, 0.6, true)
end
for zi = JZ1, JZ2, 14 do
	local gp = p("GridX2", Vector3.new(JHW*2, 0.06, 0.14), Vector3.new(0, G+0.23, zi), "Hot pink", NEON, 0.65, true)
end

-- Crystal energy patches (replaced leaf piles)
local crystalPiles = {
	{-32, 652}, { 18, 658}, {-55, 667}, { 46, 682}, {-14, 694},
	{ 58, 708}, {-46, 725}, { 24, 740}, {-60, 756}, { 52, 770},
}
for _, lp in crystalPiles do
	local ls = 3 + math.random(0, 3)
	local cr = p("CrystalPatch", Vector3.new(ls, 0.18, ls - 1), Vector3.new(lp[1], G + 0.42, lp[2]), "Cyan", NEON, 0.5, true)
end

-- Metal stepping plates through the middle
for pz = JZ1 + 8, JZ2 - 8, 5 do
	local pw = 2.5 + math.random(0, 1)
	local po = (math.random(0, 2) - 1) * 2
	p("MetalPlate", Vector3.new(pw, 0.2, pw - 0.4), Vector3.new(po, G + 0.22, pz), "Smoky grey", DPLATE, 0)
end

-- ---- CRYSTAL TOWERS (replaced trees) ----
local function crystalTower(x, z, h, thick, col1, col2)
	thick = thick or 2
	col1  = col1 or "Cyan"
	col2  = col2 or "Hot pink"
	-- Dark metal trunk
	p("CTrunk",     Vector3.new(thick, h, thick),           Vector3.new(x, G + h/2, z),  "Dark stone grey", METAL)
	p("CTrunkBase", Vector3.new(thick + 2, 0.8, thick + 2), Vector3.new(x, G + 0.4, z),  "Smoky grey", METAL, 0, true)
	-- Neon crystal orbs at top
	ball("COrb1", Vector3.new(x,        G + h + 2,   z),        12,  col1, NEON, 0.22, true)
	ball("COrb2", Vector3.new(x + 2.5,  G + h,       z - 2),     8,  col2, NEON, 0.28, true)
	ball("COrb3", Vector3.new(x - 2,    G + h + 1,   z + 2.5),   7,  col1, NEON, 0.3,  true)
	ball("COrbTop",Vector3.new(x + 0.5, G + h + 5.5, z - 0.5),   5,  col2, NEON, 0.15, true)
	-- Energy cable strands draping down
	for i = 1, 3 do
		local mx = x + math.random(-4, 4)
		local mz = z + math.random(-4, 4)
		local mlen = 4 + math.random(0, 3)
		cylinder("TowerCable", Vector3.new(0.1, mlen, 0.1),
			CFrame.new(mx, G + h - mlen * 0.5, mz) * C90X, "Cyan", NEON, 0.35, true)
	end
end

local function megaCrystalTower(x, z)
	local h = 28
	p("MCTrunk",   Vector3.new(5.5, h,   5.5), Vector3.new(x,       G + h/2,      z),    "Dark stone grey", METAL)
	p("MCRoot1",   Vector3.new(3.5, 0.9, 10),  Vector3.new(x + 3.5, G + 0.45,     z),    "Smoky grey", METAL, 0, true)
	p("MCRoot2",   Vector3.new(10,  0.9, 3.5), Vector3.new(x,       G + 0.45, z - 3),    "Smoky grey", METAL, 0, true)
	p("MCRoot3",   Vector3.new(4,   0.9, 10),  Vector3.new(x - 4,   G + 0.45, z + 2.5),  "Smoky grey", METAL, 0, true)
	-- Energy branches
	local b1 = p("MCBranch1", Vector3.new(1.5, 0.9, 10),  Vector3.new(x + 6, G + h * 0.6, z),   "Cyan", NEON, 0, true)
	local b2 = p("MCBranch2", Vector3.new(10,  0.9, 1.5), Vector3.new(x,     G + h * 0.7, z-5),  "Hot pink", NEON, 0, true)
	-- Giant crystal canopy orbs
	ball("MCO1", Vector3.new(x,     G + h + 4,  z),     20, "Cyan",     NEON, 0.2,  true)
	ball("MCO2", Vector3.new(x + 7, G + h + 1,  z - 2), 15, "Hot pink", NEON, 0.25, true)
	ball("MCO3", Vector3.new(x - 5, G + h + 2,  z + 5), 12, "Cyan",     NEON, 0.25, true)
	ball("MCO4", Vector3.new(x + 2, G + h + 10, z + 2), 10, "White",    NEON, 0.1,  true)
	ball("MCO5", Vector3.new(x - 3, G + h + 8,  z - 3),  8, "Bright violet", NEON, 0.15, true)
	-- Heavy energy cables from canopy
	for vi = 1, 8 do
		local vx2  = x + math.random(-10, 10)
		local vz2  = z + math.random(-10, 10)
		local vlen = 10 + math.random(0, 8)
		cylinder("MegaCable", Vector3.new(0.2, vlen, 0.2),
			CFrame.new(vx2, G + h - vlen * 0.5, vz2) * C90X, "Cyan", NEON, 0.2, true)
	end
end

local function crystalPillar(x, z, h)
	h = h or 16
	p("CPillar", Vector3.new(1.3, h, 1.3), Vector3.new(x, G + h/2, z), "Dark stone grey", METAL)
	for ang = 0, 300, 60 do
		local rad = math.rad(ang)
		local fdx = math.cos(rad) * 4
		local fdz = math.sin(rad) * 4
		local shard = pcf("CrystalShard", Vector3.new(0.3, 0.3, 7),
			CFrame.new(x + fdx * 0.6, G + h + 1.2, z + fdz * 0.6)
			* CFrame.Angles(0, -rad, math.rad(-22)), "Cyan", NEON, 0.25, true)
	end
	ball("CPillarOrb1", Vector3.new(x + 1.2, G + h - 0.5, z + 1),   1.2, "Hot pink", NEON, 0.15, true)
	ball("CPillarOrb2", Vector3.new(x - 0.8, G + h - 1,   z - 1.2), 1.2, "Cyan",    NEON, 0.15, true)
	ball("CPillarOrb3", Vector3.new(x,       G + h - 0.8, z + 1.5), 1.0, "White",   NEON, 0.1,  true)
end

megaCrystalTower(-42, 718)

crystalTower(-52, 652, 16, 2.5, "Cyan",     "Hot pink")
crystalTower( 42, 660, 19, 3,   "Hot pink",  "Cyan")
crystalTower(-30, 675, 14, 2,   "Bright violet", "Cyan")
crystalTower( 58, 688, 18, 2.5, "Cyan",     "Hot pink")
crystalTower(-58, 702, 15, 2,   "Hot pink",  "Bright violet")
crystalTower( 35, 716, 20, 3,   "Cyan",     "Hot pink")
crystalTower(-52, 730, 17, 2.5, "Bright violet", "Cyan")
crystalTower( 56, 742, 14, 2,   "Cyan",     "Hot pink")
crystalTower(-28, 758, 18, 2,   "Hot pink",  "Cyan")
crystalTower( 48, 768, 16, 2.5, "Cyan",     "Bright violet")
crystalTower(-56, 776, 14, 2,   "Bright violet", "Hot pink")

crystalPillar(-18, 655, 14)
crystalPillar( 63, 712, 17)
crystalPillar(-10, 768, 15)

-- ---- DARK CRYSTAL TEMPLE ----
local TX, TZ = -34, 688

p("Platform",  Vector3.new(22, 2,   18),  Vector3.new(TX,      G + 1,     TZ),        "Dark stone grey", METAL)
p("Step1",     Vector3.new(25, 0.8, 2.5), Vector3.new(TX,      G + 0.4,   TZ - 10.25),"Dark stone grey", METAL)
p("Step2",     Vector3.new(25, 0.8, 2.5), Vector3.new(TX,      G + 1.2,   TZ - 7.75), "Dark stone grey", METAL)

for _, cx in { TX - 9, TX + 9 } do
	for _, cz in { TZ - 6, TZ + 6 } do
		p("Column",    Vector3.new(1.8, 11, 1.8), Vector3.new(cx, G + 6.5,  cz), "Smoky grey",      METAL)
		p("ColCapTop", Vector3.new(3,   0.7, 3),  Vector3.new(cx, G + 12.4, cz), "Dark stone grey", METAL)
		p("ColCapBot", Vector3.new(3,   0.5, 3),  Vector3.new(cx, G + 2.25, cz), "Dark stone grey", METAL)
		-- Neon column glow lines
		local cg = p("ColGlow", Vector3.new(0.2, 10, 0.2), Vector3.new(cx, G+6.5, cz), "Cyan", NEON, 0.25, true)
	end
end

local l1 = p("Lintel1", Vector3.new(20, 0.8, 2), Vector3.new(TX, G + 13, TZ - 6), "Dark stone grey", METAL)
local l2 = p("Lintel2", Vector3.new(10, 0.8, 2), Vector3.new(TX - 5, G + 13, TZ + 6), "Dark stone grey", METAL)
-- Neon lintel glow
local lg = p("LintelGlow", Vector3.new(20, 0.3, 0.3), Vector3.new(TX, G+13.5, TZ-6), "Cyan", NEON, 0.2, true)

p("ColWall",    Vector3.new(1, 9,  14), Vector3.new(TX + 11, G + 5.5,  TZ),     "Dark stone grey", METAL)
p("ColWallTop", Vector3.new(1, 3,   6), Vector3.new(TX + 11, G + 11.5, TZ + 4), "Dark stone grey", METAL)

-- Energy floor on platform
local pf = p("TemplatEnergy", Vector3.new(22, 0.12, 18), Vector3.new(TX, G + 2.06, TZ), "Cyan", NEON, 0.55, true)
-- Neon crystal nodes on columns
for _, cx in { TX - 9, TX + 9 } do
	for _, cz in { TZ - 6, TZ + 6 } do
		ball("ColNode", Vector3.new(cx, G + 7.5, cz), 1.5, "Cyan", NEON, 0.2, true)
	end
end

-- Energy cables on collapsed wall
for wz = TZ - 5, TZ + 5, 2.5 do
	local wvlen = 4 + math.random(0, 3)
	cylinder("TWallCable", Vector3.new(0.12, wvlen, 0.12),
		CFrame.new(TX + 11.5, G + 5 - wvlen * 0.5, wz) * C90X, "Cyan", NEON, 0.3, true)
end

-- Crystal idol / statue
p("CrystalIdol",     Vector3.new(1.5, 4, 1.5), Vector3.new(TX - 2, G + 3,   TZ), "Dark stone grey", METAL)
ball("IdolHead", Vector3.new(TX - 2, G + 5.5, TZ), 2.2, "Cyan", NEON, 0.2, false)

-- Scattered energy rubble
for _, rs in { {TX + 8, TZ + 10}, {TX - 7, TZ + 12}, {TX + 12, TZ - 4},
               {TX - 12, TZ - 3}, {TX + 10, TZ + 2},  {TX - 9,  TZ + 8} } do
	local rsz = 1.2 + math.random(0, 2) * 0.8
	p("CrystalRubble", Vector3.new(rsz, rsz * 0.65, rsz + 0.5), Vector3.new(rs[1], G + rsz * 0.3, rs[2]), "Dark stone grey", METAL)
end

-- Secondary dark wall
p("WallA", Vector3.new(0.9, 9,  14),  Vector3.new(52,   G + 5.5, 742), "Dark stone grey", METAL)
p("WallB", Vector3.new(14,  9,  0.9), Vector3.new(45.5, G + 5.5, 749), "Dark stone grey", METAL)
p("WallC", Vector3.new(0.9, 5,  6),   Vector3.new(52,   G + 3.5, 752), "Dark stone grey", METAL)
-- Wall neon glow strip
local wg = p("WallGlow", Vector3.new(0.3, 7, 8), Vector3.new(51.8, G + 4.5, 742), "Cyan", NEON, 0.35, true)
for wz = 737, 747, 2.5 do
	local wvlen = 3 + math.random(0, 3)
	cylinder("WCable", Vector3.new(0.12, wvlen, 0.12),
		CFrame.new(51.5, G + 5 - wvlen * 0.5, wz) * C90X, "Hot pink", NEON, 0.3, true)
end

-- ---- ENERGY CASCADE + CRYSTAL CLIFF ----
p("Cliff",       Vector3.new(20, 24, 5),  Vector3.new(18, G + 12,    748), "Dark stone grey", METAL)
p("CliffTop",    Vector3.new(20, 1.5, 5), Vector3.new(18, G + 24.75, 748), "Smoky grey",      METAL)
p("CliffLedge",  Vector3.new(16, 1,   3), Vector3.new(18, G + 12,    745.5),"Smoky grey",     METAL)
-- Neon cliff energy streams
local cf1 = p("CascadeGlow1", Vector3.new(6, 4, 0.6), Vector3.new(12, G + 9,  746.2), "Cyan",    NEON, 0.4, true)
local cf2 = p("CascadeGlow2", Vector3.new(4, 2, 0.6), Vector3.new(23, G + 15, 746.2), "Hot pink", NEON, 0.45, true)
local cf3 = p("CascadeGlow3", Vector3.new(5, 3, 0.6), Vector3.new(17, G + 19, 746.2), "Cyan",    NEON, 0.4, true)

-- Energy cascade streams
p("Cascade1", Vector3.new(2.5, 24, 0.6), Vector3.new(16, G + 12, 746.3), "Cyan",    NEON, 0.25, true)
p("Cascade2", Vector3.new(2,   20, 0.6), Vector3.new(20, G + 10, 746.3), "Hot pink", NEON, 0.3,  true)
-- Splash mist at base
for mi = 1, 6 do
	ball("Mist", Vector3.new(14 + mi * 1.2, G + 1.2 + mi * 0.2, 748 + mi * 0.3), 1.8 + mi * 0.2, "Cyan", NEON, 0.7, true)
end
-- Energy pool
p("EnergyPool",   Vector3.new(16, 0.4,  14), Vector3.new(18, G + 0.2, 758), "Cyan",        NEON, 0.3)
p("PoolRim",      Vector3.new(18, 0.5,  16), Vector3.new(18, G + 0.1, 758), "Dark stone grey", METAL)
for _, rpos in { {10, 754}, {26, 754}, {10, 763}, {26, 763}, {11, 758}, {25, 758} } do
	ball("PoolCrystal", Vector3.new(rpos[1], G + 0.8, rpos[2]), 2, "Dark stone grey", METAL, 0)
end
-- Neon lily equivalents (energy nodes)
for _, lp in { {14, 755}, {21, 758}, {17, 762}, {22, 754}, {15, 760} } do
	local ep = p("EnergyNode", Vector3.new(2.5, 0.15, 2.5), Vector3.new(lp[1], G + 0.42, lp[2]), "Cyan", NEON, 0.4, true)
	ball("NodeOrb", Vector3.new(lp[1] + 0.3, G + 0.72, lp[2] + 0.2), 0.7, "Hot pink", NEON, 0.1, true)
end

-- ---- CRYSTAL PILLAR CLUSTERS (replaced bamboo) ----
local crystalGroups = {
	{-26, 648}, {-22, 650}, {-30, 649},
	{  4, 698}, {  8, 696}, {  0, 700},
	{ 30, 748}, { 26, 750}, { 34, 747},
	{-48, 668}, {-44, 670},
	{ 64, 720}, { 62, 725},
}
for _, bg in crystalGroups do
	local bx, bz = bg[1], bg[2]
	local bh = 9 + math.random(0, 4)
	cylinder("CrystalStem", Vector3.new(0.28, bh, 0.28),
		CFrame.new(bx, G + bh / 2, bz) * C90Z, "Dark stone grey", METAL, 0, true)
	-- Crystal node joints
	for jy = 2, bh - 1, 2.2 do
		local jn = cylinder("CrystalJoint", Vector3.new(0.38, 0.22, 0.38),
			CFrame.new(bx, G + jy, bz) * C90Z, "Cyan", NEON, 0.3, true)
	end
	-- Energy orb at top
	ball("CrystalTop", Vector3.new(bx, G + bh + 1, bz), 1.5, "Cyan", NEON, 0.2, true)
end

-- ---- ENERGY CRYSTAL FORMATIONS (replaced mushrooms) ----
local function energyCrystal(x, z, sz, col)
	sz = sz or 1
	col = col or "Cyan"
	cylinder("CStem", Vector3.new(sz * 0.5, sz * 1.3, sz * 0.5),
		CFrame.new(x, G + sz * 0.65, z) * C90Z, "Dark stone grey", METAL, 0, true)
	ball("CCap", Vector3.new(x, G + sz * 1.5, z), sz * 2, col, NEON, 0.15, true)
	ball("CSpot", Vector3.new(x + sz * 0.4, G + sz * 1.8, z + sz * 0.2), sz * 0.4, "White", NEON, 0.1, true)
end

energyCrystal(-21,   681, 1.2, "Cyan")
energyCrystal(-22.5, 682, 0.8, "Hot pink")
energyCrystal(-19,   679, 1.0, "Bright violet")

energyCrystal( 40,   700, 1.3, "Hot pink")
energyCrystal( 41.5, 701, 0.9, "Cyan")
energyCrystal( 38.5, 699, 0.7, "Bright violet")

energyCrystal(-46,   755, 1.1, "Cyan")
energyCrystal(-47.5, 756, 0.8, "Hot pink")
energyCrystal(-44,   754, 1.0, "Cyan")

-- Larger glowing crystal nodes
local function megaCrystal(x, z, sz, col)
	sz = sz or 1.4
	cylinder("GCS", Vector3.new(sz * 0.5, sz * 1.4, sz * 0.5),
		CFrame.new(x, G + sz * 0.7, z) * C90Z, "Smoky grey", METAL, 0, true)
	ball("GCC", Vector3.new(x, G + sz * 1.6, z), sz * 2.2, col, NEON, 0.1, true)
end
megaCrystal( 30, 725, 1.5, "Cyan")
megaCrystal(-12, 760, 1.3, "Bright violet")

-- ---- NEON ENERGY NODES (replaced flowers) ----
local energyColors = { "Hot pink", "Cyan", "Bright violet", "Hot pink", "White", "Cyan" }
local energySpots = {
	{-42, 660}, {-26, 661}, { 32, 665}, { 56, 672}, {-12, 673},
	{ 16, 682}, {-52, 695}, { 41, 695}, { 62, 700}, {-22, 710},
	{ 26, 720}, {-64, 732}, { 46, 735}, {-36, 748}, { 12, 748},
	{ 64, 752}, {-22, 760}, { 36, 763}, {-56, 770}, { 22, 773},
}
for i, fs in energySpots do
	local col  = energyColors[(i - 1) % #energyColors + 1]
	local col2 = energyColors[i % #energyColors + 1]
	ball("ENode",  Vector3.new(fs[1],                          G + 0.65, fs[2]),                          0.9, col,  NEON, 0.1, true)
	ball("ENode2", Vector3.new(fs[1] + math.random(-2, 2), G + 0.55, fs[2] + math.random(-2, 2)), 0.7, col2, NEON, 0.15, true)
	cylinder("ENodeStem", Vector3.new(0.1, 0.75, 0.1),
		CFrame.new(fs[1], G + 0.38, fs[2]) * C90Z, "Dark stone grey", METAL, 0, true)
end

-- ---- ENERGY CABLES (replaced hanging vines) ----
for _, vx in { -64, -48, -30, -14, 10, 28, 44, 60 } do
	for vz = JZ1 + 10, JZ2 - 10, 18 do
		local vlen = 12 + math.random(0, 10)
		cylinder("HCable", Vector3.new(0.12, vlen, 0.12),
			CFrame.new(vx, G + vlen * 0.5 + 2, vz) * C90X, "Cyan", NEON, 0.3, true)
	end
end
-- Thick energy cable bundles near big towers
for _, vpos in { {-40, 712}, {-44, 726}, {-50, 720}, {44, 658}, {40, 664} } do
	cylinder("ThickCable", Vector3.new(0.45, 16, 0.45),
		CFrame.new(vpos[1] + 2, G + 9, vpos[2]) * C90X, "Hot pink", NEON, 0.15, true)
end

-- ---- CRYSTAL ROCK FORMATIONS ----
local function crystalRocks(x, z)
	ball("CRock1", Vector3.new(x,       G + 1.5, z),       3.5, "Dark stone grey", METAL, 0)
	ball("CRock2", Vector3.new(x + 2.5, G + 1,   z + 1.5), 2.5, "Smoky grey",      METAL, 0)
	ball("CRock3", Vector3.new(x - 1.5, G + 0.8, z - 2),   2,   "Dark stone grey", METAL, 0)
	-- Crystal node on top of rock
	ball("CRockNode", Vector3.new(x, G + 3.4, z), 1.0, "Cyan", NEON, 0.2, true)
end

crystalRocks(-5,  660)
crystalRocks(30,  706)
crystalRocks(-26, 736)
crystalRocks(62,  658)

-- ---- FALLEN METAL LOG ----
p("MetalLog",  Vector3.new(16, 2, 2), Vector3.new(26, G + 1, 662), "Dark stone grey", METAL)
p("LogSurface",Vector3.new(16, 0.2, 2.2), Vector3.new(26, G + 2.1, 662), "Smoky grey", DPLATE, 0, true)
-- Crystal nodes on log
for li = 0, 2 do
	cylinder("LogCStem", Vector3.new(0.4, 0.8, 0.4),
		CFrame.new(18 + li * 4, G + 2.1, 662) * C90Z, "Dark stone grey", METAL, 0, true)
	ball("LogCCap", Vector3.new(18 + li * 4, G + 2.8, 662), 1.1, "Cyan", NEON, 0.15, true)
end

-- ---- GLOWING CRYSTAL CLUSTERS (atmosphere) ----
for _, gs in {
	{-38, 652, "Cyan"}, { 60, 695, "Hot pink"}, {-22, 715, "Cyan"},
	{ 44, 722, "Hot pink"}, {-54, 740, "Cyan"}, { 20, 762, "Bright violet"},
} do
	ball("GCrysA", Vector3.new(gs[1],     G + 1.0, gs[2]),     1.8, gs[3], NEON, 0.45, true)
	ball("GCrysB", Vector3.new(gs[1] + 1, G + 0.7, gs[2] + 1), 1.2, gs[3], NEON, 0.55, true)
end

-- ==============================================
-- PERIMETER FENCE (dark metal + neon cables)
-- ==============================================
local FH = 4

local function fencePostsZ(x, z1, z2)
	for iz = z1, z2, 7 do
		p("FPost", Vector3.new(0.5, FH, 0.5), Vector3.new(x, G + FH / 2, iz), "Dark stone grey", METAL)
	end
	local zLen = z2 - z1
	local r1 = p("FRailL", Vector3.new(0.3, 0.3, zLen), Vector3.new(x, G + 1.2, (z1 + z2) / 2), "Cyan",    NEON)
	r1.Transparency = 0.25
	local r2 = p("FRailH", Vector3.new(0.3, 0.3, zLen), Vector3.new(x, G + 3.0, (z1 + z2) / 2), "Hot pink", NEON)
	r2.Transparency = 0.25
end

local function fencePostsX(z, x1, x2)
	for ix = x1, x2, 7 do
		p("FPost", Vector3.new(0.5, FH, 0.5), Vector3.new(ix, G + FH / 2, z), "Dark stone grey", METAL)
	end
	local xLen = x2 - x1
	local r1 = p("FRailL", Vector3.new(xLen, 0.3, 0.3), Vector3.new((x1 + x2) / 2, G + 1.2, z), "Cyan",    NEON)
	r1.Transparency = 0.25
	local r2 = p("FRailH", Vector3.new(xLen, 0.3, 0.3), Vector3.new((x1 + x2) / 2, G + 3.0, z), "Hot pink", NEON)
	r2.Transparency = 0.25
end

fencePostsZ( JHW, JZ1, JZ2)
fencePostsZ(-JHW, JZ1, JZ2)
fencePostsX(JZ1, -JHW, -6)
fencePostsX(JZ1,  6,  JHW)
fencePostsX(JZ2, -JHW, JHW)

-- Entrance sign
local jsign = p("JZSign", Vector3.new(24, 5, 0.5), Vector3.new(0, G + 18, JZ1 + 1), "Really black", SMP, 0, true)
local jzBg = Instance.new("BillboardGui")
jzBg.Size = UDim2.new(0, 480, 0, 100)
jzBg.StudsOffset = Vector3.new(0, 0, 0)
jzBg.Parent = jsign
local jzLbl = Instance.new("TextLabel")
jzLbl.Size = UDim2.new(1, 0, 1, 0)
jzLbl.BackgroundTransparency = 1
jzLbl.Text = "CRYSTAL DEPTHS"
jzLbl.TextColor3 = Color3.fromRGB(80, 220, 255)
jzLbl.Font = Enum.Font.GothamBold
jzLbl.TextScaled = true
jzLbl.TextStrokeTransparency = 0
jzLbl.Parent = jzBg

print("[JungleZone] Metal Galactic (Crystal Depths) theme built successfully!")
