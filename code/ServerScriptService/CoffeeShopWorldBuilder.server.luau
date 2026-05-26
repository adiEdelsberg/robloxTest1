-- NEBULA BREW — Cosmic Coffee Shop World
-- Game Station ends at z=1460. Bridge: z=1460->1540. Coffee world: z=1540->1860 (320 studs, 2x Game Station).
-- Width: HW=156 (312 studs total, 2x Game Station's 156).

local G = 1

local folder = Instance.new("Folder")
folder.Name = "CoffeeShopWorld"
folder.Parent = workspace

local SMP    = Enum.Material.SmoothPlastic
local NEON   = Enum.Material.Neon
local METAL  = Enum.Material.Metal
local DPLATE = Enum.Material.DiamondPlate
local WOOD   = Enum.Material.SmoothPlastic  -- metal galactic: no real wood

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
	gui.Size = UDim2.new(0, 620, 0, 120)
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

-- ============================================================
-- BRIDGE  z=1460→1540
-- ============================================================
local BZ1, BZ2 = 1460, 1540
local BZC = (BZ1 + BZ2) / 2
p("CoffeeBridgeFloor", Vector3.new(14, 0.45, BZ2 - BZ1), Vector3.new(0, G + 0.23, BZC), "Dark stone grey", DPLATE)
for bz = BZ1 + 5, BZ2 - 5, 10 do
	local col = (math.floor(bz / 10) % 2 == 0) and "Bright orange" or "Cyan"
	p("BridgeGlow", Vector3.new(12, 0.12, 0.4), Vector3.new(0, G + 0.52, bz), col, NEON, 0.2, true)
end
for _, x in { -7.3, 7.3 } do
	p("BridgeRail", Vector3.new(0.35, 0.35, BZ2 - BZ1), Vector3.new(x, G + 3.5, BZC), "Bright orange", NEON, 0.15)
	for bz = BZ1 + 6, BZ2 - 6, 10 do
		p("BridgePost", Vector3.new(0.5, 3.5, 0.5), Vector3.new(x, G + 1.75, bz), "Really black", METAL)
	end
end

-- Entry arch. Door signage is handled by DoorSigns.server.luau so the road stays clear.
p("CoffeeArchL", Vector3.new(1.2, 16, 1.2), Vector3.new(-12, G + 8, BZ2), "Really black", METAL)
p("CoffeeArchR", Vector3.new(1.2, 16, 1.2), Vector3.new(12, G + 8, BZ2), "Really black", METAL)
p("CoffeeArchTop", Vector3.new(26, 1.2, 1.2), Vector3.new(0, G + 16, BZ2), "Bright orange", NEON, 0.12)
-- Steam wisps on arch
for i = -1, 1 do
	cylinder("ArchSteam", Vector3.new(0.4, 8, 0.4),
		CFrame.new(i * 5, G + 22, BZ2) * C90X, "Institutional white", NEON, 0.55, true)
end

-- ============================================================
-- MAIN WORLD  z=1540→1860
-- ============================================================
local WZ1, WZ2 = 1540, 1860
local WZC = (WZ1 + WZ2) / 2
local HW = 156  -- half-width → 312 studs total

-- Ground: dark diamond plate with warm coffee-orange neon grid
p("CoffeeFloor", Vector3.new(HW * 2, 2, WZ2 - WZ1), Vector3.new(0, 0, WZC), "Really black", DPLATE)

for x = -HW, HW, 16 do
	p("GridZ", Vector3.new(0.2, 0.08, WZ2 - WZ1), Vector3.new(x, G + 0.08, WZC), "Bright orange", NEON, 0.55, true)
end
for z = WZ1, WZ2, 16 do
	p("GridX", Vector3.new(HW * 2, 0.08, 0.2), Vector3.new(0, G + 0.09, z), "Cyan", NEON, 0.6, true)
end

-- Boundary walls + invisible containment
local FH, CW = 8, 40
local SIDE_DOOR_Z = 1700
local SIDE_DOOR_HALF = 18
p("WallSideL_N", Vector3.new(0.6, FH, (SIDE_DOOR_Z - SIDE_DOOR_HALF) - WZ1), Vector3.new(-HW, G + FH / 2, (WZ1 + SIDE_DOOR_Z - SIDE_DOOR_HALF) / 2), "Bright orange", NEON, 0.45)
p("WallSideL_S", Vector3.new(0.6, FH, WZ2 - (SIDE_DOOR_Z + SIDE_DOOR_HALF)), Vector3.new(-HW, G + FH / 2, (WZ2 + SIDE_DOOR_Z + SIDE_DOOR_HALF) / 2), "Bright orange", NEON, 0.45)
p("ContainSideL_N", Vector3.new(0.5, CW, (SIDE_DOOR_Z - SIDE_DOOR_HALF) - WZ1), Vector3.new(-HW, G + CW / 2, (WZ1 + SIDE_DOOR_Z - SIDE_DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainSideL_S", Vector3.new(0.5, CW, WZ2 - (SIDE_DOOR_Z + SIDE_DOOR_HALF)), Vector3.new(-HW, G + CW / 2, (WZ2 + SIDE_DOOR_Z + SIDE_DOOR_HALF) / 2), "Really black", SMP, 1)
p("WallSideR_N", Vector3.new(0.6, FH, (SIDE_DOOR_Z - SIDE_DOOR_HALF) - WZ1), Vector3.new(HW, G + FH / 2, (WZ1 + SIDE_DOOR_Z - SIDE_DOOR_HALF) / 2), "Bright orange", NEON, 0.45)
p("WallSideR_S", Vector3.new(0.6, FH, WZ2 - (SIDE_DOOR_Z + SIDE_DOOR_HALF)), Vector3.new(HW, G + FH / 2, (WZ2 + SIDE_DOOR_Z + SIDE_DOOR_HALF) / 2), "Bright orange", NEON, 0.45)
p("ContainSideR_N", Vector3.new(0.5, CW, (SIDE_DOOR_Z - SIDE_DOOR_HALF) - WZ1), Vector3.new(HW, G + CW / 2, (WZ1 + SIDE_DOOR_Z - SIDE_DOOR_HALF) / 2), "Really black", SMP, 1)
p("ContainSideR_S", Vector3.new(0.5, CW, WZ2 - (SIDE_DOOR_Z + SIDE_DOOR_HALF)), Vector3.new(HW, G + CW / 2, (WZ2 + SIDE_DOOR_Z + SIDE_DOOR_HALF) / 2), "Really black", SMP, 1)
p("BurgerConnectorFloor", Vector3.new(40, 0.45, 22), Vector3.new(HW + 20, G + 0.23, SIDE_DOOR_Z), "Dark stone grey", DPLATE)
p("BurgerConnectorGlow", Vector3.new(36, 0.1, 18), Vector3.new(HW + 20, G + 0.5, SIDE_DOOR_Z), "Bright orange", NEON, 0.72, true)
for _, z in { SIDE_DOOR_Z - 11, SIDE_DOOR_Z + 11 } do
	p("BurgerConnectorRail", Vector3.new(40, 0.35, 0.35), Vector3.new(HW + 20, G + 3.2, z), "Cyan", NEON, 0.18)
end
p("WallNorthL",   Vector3.new(HW - 8, FH, 0.6), Vector3.new(-(HW + 8) / 2, G + FH / 2, WZ1), "Bright orange", NEON, 0.45)
p("WallNorthR",   Vector3.new(HW - 8, FH, 0.6), Vector3.new((HW + 8) / 2,  G + FH / 2, WZ1), "Bright orange", NEON, 0.45)
p("WallSouthL",   Vector3.new(HW - 8, FH, 0.6), Vector3.new(-(HW + 8) / 2, G + FH / 2, WZ2), "Bright orange", NEON, 0.45)
p("WallSouthR",   Vector3.new(HW - 8, FH, 0.6), Vector3.new((HW + 8) / 2,  G + FH / 2, WZ2), "Bright orange", NEON, 0.45)
p("ContainNorthL",Vector3.new(HW - 8, CW, 0.5), Vector3.new(-(HW + 8) / 2, G + CW / 2, WZ1), "Really black", SMP, 1)
p("ContainNorthR",Vector3.new(HW - 8, CW, 0.5), Vector3.new((HW + 8) / 2,  G + CW / 2, WZ1), "Really black", SMP, 1)
p("ContainSouthL",Vector3.new(HW - 8, CW, 0.5), Vector3.new(-(HW + 8) / 2, G + CW / 2, WZ2), "Really black", SMP, 1)
p("ContainSouthR",Vector3.new(HW - 8, CW, 0.5), Vector3.new((HW + 8) / 2,  G + CW / 2, WZ2), "Really black", SMP, 1)

-- ============================================================
-- GIANT CENTRAL COFFEE CUP  (hero prop, center of world)
-- ============================================================
local CCX, CCZ = 0, WZC
-- Saucer
cylinder("CupSaucer",   Vector3.new(4, 54, 54),  CFrame.new(CCX, G + 2.2, CCZ) * C90Z, "Dark stone grey", DPLATE)
cylinder("SaucerGlow",  Vector3.new(4.2, 56, 56), CFrame.new(CCX, G + 0.3, CCZ) * C90Z, "Bright orange", NEON, 0.72, true)
-- Cup body (truncated cylinder — approximate with stacked rings)
cylinder("CupBody",     Vector3.new(28, 40, 40),  CFrame.new(CCX, G + 16, CCZ) * C90Z, "Dark stone grey", DPLATE)
cylinder("CupBodyInner",Vector3.new(29, 36, 36),  CFrame.new(CCX, G + 17, CCZ) * C90Z, "Really black", DPLATE)
-- Cup rim
cylinder("CupRim",      Vector3.new(4,  43, 43),  CFrame.new(CCX, G + 30.5, CCZ) * C90Z, "Smoky grey", METAL)
cylinder("CupRimGlow",  Vector3.new(4.5, 44, 44), CFrame.new(CCX, G + 30.5, CCZ) * C90Z, "Bright orange", NEON, 0.6, true)
-- Coffee surface (inside cup)
cylinder("CoffeeSurface",Vector3.new(2, 34, 34), CFrame.new(CCX, G + 30, CCZ) * C90Z, "Reddish brown", SMP, 0.1)
cylinder("CoffeeGlow",   Vector3.new(2.5, 32, 32), CFrame.new(CCX, G + 30.1, CCZ) * C90Z, "Bright orange", NEON, 0.55, true)
-- Handle
pcf("CupHandle", Vector3.new(1.8, 18, 10),
	CFrame.new(CCX + 22, G + 17, CCZ) * CFrame.Angles(0, 0, math.rad(15)), "Dark stone grey", DPLATE)
p("CupHandleGlow", Vector3.new(0.5, 18, 0.5), Vector3.new(CCX + 27, G + 17, CCZ), "Bright orange", NEON, 0.3, true)
-- Steam columns rising from cup
for i, sx in { -8, 0, 8 } do
	cylinder("Steam" .. i, Vector3.new(1.2, 24 + i * 4, 1.2),
		CFrame.new(CCX + sx, G + 45 + i * 2, CCZ) * C90X, "Institutional white", NEON, 0.45, true)
	ball("SteamPuff" .. i, Vector3.new(CCX + sx, G + 58 + i * 3, CCZ), 5 + i, "Institutional white", NEON, 0.55, true)
end
-- Logo on cup
local cupSign = p("CupLogoPanel", Vector3.new(0.4, 14, 18), Vector3.new(CCX - 20.1, G + 17, CCZ), "Really black", SMP, 0, true)
sign(cupSign, "NEBULA\nBREW", Color3.fromRGB(255, 180, 60))

-- ============================================================
-- MAIN BAR / COUNTER  (north side, z ≈ WZ1+50)
-- ============================================================
local BAR_Z = WZ1 + 55
local BAR_W = 100
-- Counter base
p("BarBase",    Vector3.new(BAR_W, 5, 8),  Vector3.new(0, G + 2.5,  BAR_Z), "Dark stone grey", DPLATE)
p("BarTop",     Vector3.new(BAR_W, 0.5, 9), Vector3.new(0, G + 5.25, BAR_Z), "Smoky grey",      DPLATE)
p("BarFront",   Vector3.new(BAR_W, 0.2, 8), Vector3.new(0, G + 5.4,  BAR_Z), "Bright orange",   NEON, 0.3, true)
-- Under-counter glow strip
p("BarUnderGlow", Vector3.new(BAR_W - 2, 0.15, 7), Vector3.new(0, G + 0.15, BAR_Z), "Cyan", NEON, 0.45, true)

-- Espresso machines (6 along the bar)
for i = 0, 5 do
	local mx = -45 + i * 18
	p("EspressoBase",  Vector3.new(7, 7, 5),   Vector3.new(mx, G + 8.5,  BAR_Z - 2), "Dark stone grey", DPLATE)
	p("EspressoPanel", Vector3.new(5, 5, 0.4), Vector3.new(mx, G + 9,    BAR_Z - 4.7), "Really black",   SMP)
	p("EspressoScreen",Vector3.new(3.5, 3, 0.3),Vector3.new(mx, G + 9.5,  BAR_Z - 4.9), "Cyan",          NEON, 0.35, true)
	cylinder("EspressoHead", Vector3.new(0.6, 4.5, 4.5), CFrame.new(mx, G + 6.8, BAR_Z) * C90Z, "Smoky grey", METAL)
	-- Steam nozzle
	cylinder("EspressoNozzle", Vector3.new(0.3, 2, 2), CFrame.new(mx + 2.5, G + 7.5, BAR_Z - 1.5) * C90Z, "Really black", METAL)
	cylinder("EspressoSteam",  Vector3.new(0.5, 4, 4), CFrame.new(mx + 2.5, G + 10, BAR_Z - 1.5) * C90X, "Institutional white", NEON, 0.6, true)
	-- Cup on counter
	cylinder("BarCup" .. i, Vector3.new(1.2, 3.5, 3.5), CFrame.new(mx - 1.5, G + 6.1, BAR_Z - 0.5) * C90Z, "Institutional white", SMP)
end

-- Bar stools (8 facing the counter)
for i = 0, 7 do
	local sx = -52 + i * 15
	cylinder("StoolSeat", Vector3.new(0.6, 7, 7), CFrame.new(sx, G + 6.5, BAR_Z + 8) * C90Z, "Dark stone grey", DPLATE)
	p("StoolPole",        Vector3.new(0.7, 6, 0.7),  Vector3.new(sx, G + 3, BAR_Z + 8),  "Really black",    METAL)
	cylinder("StoolGlow", Vector3.new(0.5, 7.5, 7.5), CFrame.new(sx, G + 6.5, BAR_Z + 8) * C90Z, "Bright orange", NEON, 0.7, true)
end

-- ============================================================
-- BEAN SILOS  (west side)
-- ============================================================
for i, sx in { -130, -110, -90 } do
	local sz = WZ1 + 80 + (i - 1) * 30
	cylinder("SiloBody",  Vector3.new(26, 24, 24), CFrame.new(sx, G + 13, sz) * C90Z, "Dark stone grey", DPLATE)
	cylinder("SiloTop",   Vector3.new(10, 22, 22), CFrame.new(sx, G + 27, sz) * C90Z, "Smoky grey", METAL)
	ball("SiloOrb",       Vector3.new(sx, G + 33, sz), 8, "Bright orange", NEON, 0.3, true)
	cylinder("SiloGlow",  Vector3.new(26.5, 25, 25), CFrame.new(sx, G + 13, sz) * C90Z, "Bright orange", NEON, 0.8, true)
	-- Pipe connecting to ground
	p("SiloPipe",   Vector3.new(1.5, 9, 1.5),   Vector3.new(sx + 10, G + 4.5,  sz), "Really black", METAL)
	p("SilePipeGlow",Vector3.new(0.6, 9, 0.6), Vector3.new(sx + 10, G + 4.5,  sz), "Bright orange", NEON, 0.4, true)
end

-- ============================================================
-- ROASTING STATION  (east side, large structure)
-- ============================================================
local RX, RZ = 110, WZ1 + 100
p("RoasterBase",    Vector3.new(30, 1, 20), Vector3.new(RX, G + 0.5, RZ), "Dark stone grey", DPLATE)
p("RoasterDrum",    Vector3.new(16, 14, 16), Vector3.new(RX, G + 8, RZ), "Dark stone grey", DPLATE)
cylinder("RoasterBand1",Vector3.new(2, 18, 18), CFrame.new(RX, G + 6, RZ) * C90Z, "Smoky grey", METAL)
cylinder("RoasterBand2",Vector3.new(2, 18, 18), CFrame.new(RX, G + 12, RZ) * C90Z, "Smoky grey", METAL)
cylinder("RoasterGlow", Vector3.new(16.5, 18, 18), CFrame.new(RX, G + 8, RZ) * C90Z, "Bright orange", NEON, 0.72, true)
-- Exhaust chimney
p("RoasterChimney", Vector3.new(3, 18, 3), Vector3.new(RX + 6, G + 25, RZ - 4), "Really black", METAL)
cylinder("RoasterExhaust", Vector3.new(1.2, 5, 5), CFrame.new(RX + 6, G + 35, RZ - 4) * C90X, "Bright orange", NEON, 0.4, true)
ball("ExhaustPuff", Vector3.new(RX + 6, G + 42, RZ - 4), 7, "Institutional white", NEON, 0.55, true)
-- Control panel
p("RoasterPanel", Vector3.new(8, 6, 0.5), Vector3.new(RX - 8, G + 8, RZ - 8.3), "Really black", SMP)
p("RoasterScreen", Vector3.new(5, 3.5, 0.3), Vector3.new(RX - 8, G + 9, RZ - 8.5), "Cyan", NEON, 0.3, true)

-- ============================================================
-- SEATING ZONES  (scattered tables across the floor)
-- ============================================================
local tablePositions = {
	{-60, WZC - 80}, {-30, WZC - 80}, {0, WZC - 80}, {30, WZC - 80}, {60, WZC - 80},
	{-75, WZC - 40}, {-45, WZC - 40}, {-15, WZC - 40}, {15, WZC - 40}, {45, WZC - 40}, {75, WZC - 40},
	{-60, WZC},      {-30, WZC},      {0, WZC + 20},   {30, WZC},     {60, WZC},
	{-70, WZC + 60}, {-35, WZC + 60}, {0, WZC + 60},  {35, WZC + 60}, {70, WZC + 60},
	{-55, WZC + 110},{-20, WZC + 110},{20, WZC + 110}, {55, WZC + 110},
}

for ti, pos in tablePositions do
	local tx, tz = pos[1], pos[2]
	local isRound = (ti % 3 ~= 0)
	local accent = (ti % 4 == 0) and "Hot pink" or "Bright orange"

	if isRound then
		-- Round table
		cylinder("TableTop" .. ti, Vector3.new(0.5, 10, 10), CFrame.new(tx, G + 3.8, tz) * C90Z, "Dark stone grey", DPLATE)
		cylinder("TableGlow" .. ti, Vector3.new(0.6, 10.5, 10.5), CFrame.new(tx, G + 3.85, tz) * C90Z, accent, NEON, 0.65, true)
		p("TableLeg" .. ti, Vector3.new(0.7, 3.5, 0.7), Vector3.new(tx, G + 1.75, tz), "Really black", METAL)
	else
		-- Square table
		p("TableTop" .. ti, Vector3.new(10, 0.5, 10), Vector3.new(tx, G + 3.75, tz), "Dark stone grey", DPLATE)
		p("TableGlow" .. ti, Vector3.new(10.5, 0.3, 10.5), Vector3.new(tx, G + 3.6, tz), accent, NEON, 0.65, true)
		for _, lx in { -4, 4 } do
			for _, lz in { -4, 4 } do
				p("Leg" .. ti, Vector3.new(0.6, 3.5, 0.6), Vector3.new(tx + lx, G + 1.75, tz + lz), "Really black", METAL)
			end
		end
	end

	-- Chairs (4 around each table)
	for ci, cd in { {0, -7}, {0, 7}, {-7, 0}, {7, 0} } do
		local cx2, cz2 = tx + cd[1], tz + cd[2]
		cylinder("Chair" .. ti .. ci, Vector3.new(0.4, 5.5, 5.5), CFrame.new(cx2, G + 3.2, cz2) * C90Z, "Smoky grey", DPLATE)
		p("ChairPole" .. ti .. ci, Vector3.new(0.5, 3, 0.5), Vector3.new(cx2, G + 1.5, cz2), "Really black", METAL)
		cylinder("ChairGlow" .. ti .. ci, Vector3.new(0.5, 5.8, 5.8), CFrame.new(cx2, G + 3.2, cz2) * C90Z, accent, NEON, 0.8, true)
	end

	-- Cup on table
	cylinder("Cup" .. ti, Vector3.new(0.8, 2.8, 2.8), CFrame.new(tx, G + 4.3, tz) * C90Z, "Institutional white", SMP)
	cylinder("CoffeeInCup" .. ti, Vector3.new(0.3, 2, 2), CFrame.new(tx, G + 4.65, tz) * C90Z, "Reddish brown", SMP, 0.15)
end

-- ============================================================
-- DISPLAY MENU BOARDS  (large screens on north wall area)
-- ============================================================
for mi, mx in { -70, 0, 70 } do
	local mz = WZ1 + 65
	local board = p("MenuBoard" .. mi, Vector3.new(40, 18, 0.6), Vector3.new(mx, G + 14, mz), "Really black", SMP)
	local menuText = (mi == 1) and "ESPRESSO  •  LATTE" or (mi == 2) and "NEBULA BREW\nCOSMIC COFFEE" or "CAPPUCCINO  •  MOCHA"
	sign(board, menuText, Color3.fromRGB(255, 180, 60))
	p("MenuGlow" .. mi, Vector3.new(38, 16, 0.3), Vector3.new(mx, G + 14, mz + 0.45), "Bright orange", NEON, 0.78, true)
	-- Support brackets
	p("MenuBracketL" .. mi, Vector3.new(1, 14, 2.5), Vector3.new(mx - 19, G + 8, mz + 1.5), "Dark stone grey", METAL)
	p("MenuBracketR" .. mi, Vector3.new(1, 14, 2.5), Vector3.new(mx + 19, G + 8, mz + 1.5), "Dark stone grey", METAL)
end

-- ============================================================
-- NEON LIGHT STRIPS along ceiling level (poles + strips)
-- ============================================================
for _, x in { -140, -100, -60, -20, 20, 60, 100, 140 } do
	for z = WZ1 + 20, WZ2 - 20, 60 do
		p("LightPole", Vector3.new(0.7, 20, 0.7), Vector3.new(x, G + 10, z), "Really black", METAL)
		local col = (math.floor(x / 10) % 2 == 0) and "Bright orange" or "Cyan"
		p("LightBloom", Vector3.new(6, 1.5, 1.5), Vector3.new(x, G + 20.5, z), col, NEON, 0.15, true)
	end
end

-- Ceiling strip lights running Z-direction along the center and sides
for _, lx in { -80, 0, 80 } do
	p("CeilingStrip", Vector3.new(0.3, 0.5, WZ2 - WZ1 - 20), Vector3.new(lx, G + 22, WZC), "Bright orange", NEON, 0.35, true)
end

-- ============================================================
-- DECORATIVE COFFEE BEAN ORB CLUSTERS  (floating ambient props)
-- ============================================================
local orbPositions = {
	{-120, WZC - 100, 8}, {120, WZC - 80, 9}, {-85, WZC + 50, 7},
	{85, WZC + 80, 8},  {-50, WZC + 130, 6}, {50, WZC - 120, 7},
	{130, WZC + 100, 9},{-130, WZC + 110, 8},{10, WZC + 150, 7},
	{-10, WZC - 140, 6},{70, WZC - 60, 8},  {-70, WZC + 40, 9},
}
for oi, op in orbPositions do
	local col = (oi % 3 == 0) and "Cyan" or (oi % 3 == 1) and "Bright orange" or "Institutional white"
	ball("CoffeeOrb" .. oi, Vector3.new(op[1], G + op[3], op[2]), 4 + (oi % 3), col, NEON, 0.3, true)
end

-- ============================================================
-- INDOOR CRYSTAL SPIRE DECOR  (corners and side areas)
-- ============================================================
local spirePositions = {
	{-148, WZ1 + 30}, {148, WZ1 + 30}, {-148, WZ2 - 30}, {148, WZ2 - 30},
	{-148, WZC - 60}, {148, WZC - 60}, {-148, WZC + 60}, {148, WZC + 60},
	{-148, WZ1 + 120}, {148, WZ1 + 120}, {-148, WZ2 - 120}, {148, WZ2 - 120},
}
for si, sp in spirePositions do
	local sx, sz = sp[1], sp[2]
	p("SpireBase" .. si, Vector3.new(2.5, 14, 2.5), Vector3.new(sx, G + 7, sz), "Really black", METAL)
	ball("SpireOrb" .. si, Vector3.new(sx, G + 17, sz), 5, "Bright orange", NEON, 0.22, true)
	ball("SpireOrbInner" .. si, Vector3.new(sx, G + 17, sz), 3, "Cyan", NEON, 0.4, true)
end

-- ============================================================
-- TAKEAWAY COUNTER  (south end, z ≈ WZ2-50)
-- ============================================================
local TC_Z = WZ2 - 55
p("TakeawayBase", Vector3.new(60, 4, 7), Vector3.new(0, G + 2, TC_Z), "Dark stone grey", DPLATE)
p("TakeawayTop",  Vector3.new(60, 0.5, 8), Vector3.new(0, G + 4.25, TC_Z), "Smoky grey", DPLATE)
p("TakeawayGlow", Vector3.new(60, 0.2, 8), Vector3.new(0, G + 4.45, TC_Z), "Bright orange", NEON, 0.3, true)
-- Paper bag props on counter
for bi = -4, 4 do
	if bi ~= 0 then
		p("Bag" .. bi, Vector3.new(3, 5, 2.5), Vector3.new(bi * 6, G + 7, TC_Z - 0.5), "Institutional white", SMP)
		p("BagLabel" .. bi, Vector3.new(2.5, 3, 0.3), Vector3.new(bi * 6, G + 7.5, TC_Z - 1.8), "Bright orange", NEON, 0.25, true)
	end
end
-- Takeaway sign
local takeSign = p("TakeawaySign", Vector3.new(36, 5, 0.5), Vector3.new(0, G + 12, TC_Z - 4.5), "Really black", SMP, 0, true)
sign(takeSign, "TO GO ☕", Color3.fromRGB(255, 200, 80))

print("[CoffeeShopWorld] NEBULA BREW built successfully!")
