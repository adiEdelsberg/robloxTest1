-- Metal Galactic Tennis World
-- Sports world ends at z=1020. Tennis bridge: z=1020->1090. Tennis world: z=1090->1230.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "TennisWorld"
folder.Parent = workspace

local SMP    = Enum.Material.SmoothPlastic
local NEON   = Enum.Material.Neon
local METAL  = Enum.Material.Metal
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
-- TENNIS BRIDGE
-- ==============================================
local BZ1, BZ2 = 1020, 1090
local BZC = (BZ1 + BZ2) / 2
local BLEN = BZ2 - BZ1

p("TennisBridgeFloor", Vector3.new(12, 0.45, BLEN), Vector3.new(0, G + 0.23, BZC), "Dark stone grey", DPLATE)
for bz = BZ1 + 5, BZ2 - 5, 10 do
	p("BridgeGlow", Vector3.new(10, 0.1, 0.35), Vector3.new(0, G + 0.5, bz), "Cyan", NEON, 0.4, true)
end
for _, x in { -6.2, 6.2 } do
	local rf = p("BridgeFence", Vector3.new(0.35, 4.2, BLEN), Vector3.new(x, G + 2.1, BZC), "Cyan",       NEON, 0.25)
	for bz = BZ1 + 6, BZ2 - 6, 9 do
		p("BridgePost", Vector3.new(0.35, 4.2, 0.35), Vector3.new(x, G + 2.1, bz), "Really black", METAL)
	end
end

local arch = p("TennisArchSign", Vector3.new(30, 4.6, 0.5), Vector3.new(0, G + 12, BZ2), "Really black", SMP, 0, true)
sign(arch, "PLASMA COURTS", Color3.fromRGB(80, 220, 255))
p("TennisArchL", Vector3.new(1, 12, 1), Vector3.new(-8, G + 6, BZ2), "Dark stone grey", METAL)
p("TennisArchR", Vector3.new(1, 12, 1), Vector3.new(8, G + 6, BZ2),  "Dark stone grey", METAL)
local archTop = p("TennisArchTop", Vector3.new(18, 0.9, 0.9), Vector3.new(0, G + 12.4, BZ2), "Cyan", NEON, 0.1)

-- ==============================================
-- TENNIS WORLD
-- ==============================================
local TZ1, TZ2 = 1090, 1230
local TZC = (TZ1 + TZ2) / 2
local HW = 72

-- Ground: dark metal diamond plate
p("TennisGround", Vector3.new(HW * 2, 2, TZ2 - TZ1), Vector3.new(0, 0, TZC), "Really black", DPLATE)

-- Neon floor grid
for xi = -HW, HW, 14 do
	local gp = p("GridZ", Vector3.new(0.14, 0.06, TZ2-TZ1), Vector3.new(xi, G+0.09, TZC), "Cyan",    NEON, 0.6, true)
end
for zi = TZ1, TZ2, 14 do
	local gp = p("GridX", Vector3.new(HW*2,  0.06, 0.14),   Vector3.new(0, G+0.1, zi),    "Hot pink", NEON, 0.65, true)
end

local CW = 30
local FH = 5
for _, x in { -HW, HW } do
	local fw = p("FenceSide",   Vector3.new(0.5, FH, TZ2 - TZ1), Vector3.new(x, G + FH / 2, TZC), "Cyan",       NEON, 0.25)
	local cn = p("ContainSide", Vector3.new(0.5, CW, TZ2 - TZ1), Vector3.new(x, G + CW / 2, TZC), "Really black", SMP, 1)
end
p("FenceNorthL", Vector3.new(HW - 7, FH, 0.5), Vector3.new(-(HW + 7) / 2, G + FH / 2, TZ1), "Cyan", NEON, 0.25)
p("FenceNorthR", Vector3.new(HW - 7, FH, 0.5), Vector3.new((HW + 7) / 2, G + FH / 2,  TZ1), "Cyan", NEON, 0.25)
p("FenceSouthL", Vector3.new(HW - 7, FH, 0.5), Vector3.new(-(HW + 7) / 2, G + FH / 2, TZ2), "Cyan", NEON, 0.25)
p("FenceSouthR", Vector3.new(HW - 7, FH, 0.5), Vector3.new((HW + 7) / 2, G + FH / 2,  TZ2), "Cyan", NEON, 0.25)
p("ContainNorthL", Vector3.new(HW - 7, CW, 0.5), Vector3.new(-(HW + 7) / 2, G + CW / 2, TZ1), "Really black", SMP, 1)
p("ContainNorthR", Vector3.new(HW - 7, CW, 0.5), Vector3.new((HW + 7) / 2, G + CW / 2,  TZ1), "Really black", SMP, 1)
p("ContainSouthL", Vector3.new(HW - 7, CW, 0.5), Vector3.new(-(HW + 7) / 2, G + CW / 2, TZ2), "Really black", SMP, 1)
p("ContainSouthR", Vector3.new(HW - 7, CW, 0.5), Vector3.new((HW + 7) / 2, G + CW / 2,  TZ2), "Really black", SMP, 1)

-- Two plasma tennis courts
local function plasmaCourt(cx, cz, accentNeon)
	local W, D = 48, 94
	-- Court surface: dark carbon
	p("CourtBase",  Vector3.new(W, 0.22, D), Vector3.new(cx, G + 0.12, cz), "Dark indigo", DPLATE)
	local ic = p("InnerCourt", Vector3.new(W - 8, 0.08, D - 12), Vector3.new(cx, G + 0.28, cz), accentNeon, NEON, 0.45, true)
	-- Lines in cyan neon
	p("BaselineN",   Vector3.new(W, 0.08, 0.35), Vector3.new(cx, G + 0.36, cz - D / 2), "Cyan", NEON, 0.1, true)
	p("BaselineS",   Vector3.new(W, 0.08, 0.35), Vector3.new(cx, G + 0.36, cz + D / 2), "Cyan", NEON, 0.1, true)
	p("SidelineW",   Vector3.new(0.35, 0.08, D),  Vector3.new(cx - W / 2, G + 0.36, cz), "Cyan", NEON, 0.1, true)
	p("SidelineE",   Vector3.new(0.35, 0.08, D),  Vector3.new(cx + W / 2, G + 0.36, cz), "Cyan", NEON, 0.1, true)
	p("SinglesW",    Vector3.new(0.3, 0.08, D),   Vector3.new(cx - 15, G + 0.38, cz), "Cyan", NEON, 0.15, true)
	p("SinglesE",    Vector3.new(0.3, 0.08, D),   Vector3.new(cx + 15, G + 0.38, cz), "Cyan", NEON, 0.15, true)
	p("ServiceLineN",Vector3.new(30, 0.08, 0.35), Vector3.new(cx, G + 0.38, cz - 17), "Hot pink", NEON, 0.15, true)
	p("ServiceLineS",Vector3.new(30, 0.08, 0.35), Vector3.new(cx, G + 0.38, cz + 17), "Hot pink", NEON, 0.15, true)
	p("CenterService",Vector3.new(0.35, 0.08, 34),Vector3.new(cx, G + 0.39, cz), "Hot pink", NEON, 0.15, true)

	local nt = p("NetTop",   Vector3.new(W + 3, 0.22, 0.22), Vector3.new(cx, G + 3.2, cz), "Cyan", NEON, 0.1, true)
	local np = p("NetPanel", Vector3.new(W + 3, 3, 0.16),    Vector3.new(cx, G + 1.7, cz), "Really black", SMP, 0.45, true)
	for x = -W / 2, W / 2, 4 do
		p("NetCord", Vector3.new(0.05, 2.8, 0.05), Vector3.new(cx + x, G + 1.7, cz), "Cyan", NEON, 0.35, true)
	end
	p("NetPostL", Vector3.new(0.45, 4, 0.45), Vector3.new(cx - W / 2 - 2, G + 2, cz), "Really black", METAL)
	p("NetPostR", Vector3.new(0.45, 4, 0.45), Vector3.new(cx + W / 2 + 2, G + 2, cz), "Really black", METAL)
end

plasmaCourt(-32, TZC, "Cyan")
plasmaCourt(32,  TZC, "Hot pink")

-- Plasma rackets and energy balls
local function plasmaRacket(x, z, rot)
	cylinder("RacketHead",   Vector3.new(0.18, 5.2, 3.7), CFrame.new(x, G + 0.75, z) * CFrame.Angles(0, rot, math.rad(90)), "Cyan",    NEON, 0.15, true)
	pcf("RacketHandle", Vector3.new(0.55, 0.25, 4.4), CFrame.new(x, G + 0.55, z + math.cos(rot) * 3.2) * CFrame.Angles(0, rot, 0), "Dark stone grey", METAL, 0, true)
end
plasmaRacket(-58, TZC - 34, math.rad(20))
plasmaRacket(58,  TZC + 32, math.rad(-28))
plasmaRacket(-8,  TZC + 45, math.rad(65))

-- Energy tennis balls (bright violet neon)
for _, pos in { {-48, TZC - 22}, {-20, TZC + 18}, {18, TZC - 24}, {48, TZC + 20}, {0, TZC} } do
	ball("PlasmaBall", Vector3.new(pos[1], G + 0.85, pos[2]), 1.4, "Bright violet", NEON, 0.05, false)
end

-- Umpire chairs – dark metal throne style
for _, x in { -62, 62 } do
	p("UmpireChairBase", Vector3.new(5, 0.5, 5), Vector3.new(x, G + 0.25, TZC), "Really black",    METAL)
	p("UmpireChairPost", Vector3.new(0.7, 6, 0.7), Vector3.new(x, G + 3, TZC),  "Really black",    METAL)
	p("UmpireChairSeat", Vector3.new(4.5, 0.5, 4), Vector3.new(x, G + 6.2, TZC),"Dark stone grey", DPLATE)
	local cb = p("UmpireChairBack", Vector3.new(4.5, 3, 0.35), Vector3.new(x, G + 7.6, TZC + 1.8), "Dark stone grey", DPLATE)
	-- Chair neon accent
	local ca = p("ChairGlow", Vector3.new(4.5, 0.15, 4), Vector3.new(x, G+6.45, TZC), "Cyan", NEON, 0.3, true)
end

-- Benches – dark metal
for _, z in { TZ1 + 24, TZ2 - 24 } do
	for _, x in { -42, 0, 42 } do
		p("BenchSeat", Vector3.new(14, 0.4, 3), Vector3.new(x, G + 1.4, z), "Dark stone grey", DPLATE)
		p("BenchBack", Vector3.new(14, 2.4, 0.35), Vector3.new(x, G + 2.7, z + 1.4), "Dark stone grey", METAL)
		local bg = p("BenchGlow", Vector3.new(14, 0.1, 0.2), Vector3.new(x, G+1.65, z), "Cyan", NEON, 0.4, true)
	end
end

-- Neon light poles
for _, x in { -66, 66 } do
	for z = TZ1 + 22, TZ2 - 22, 24 do
		p("LightPole",  Vector3.new(0.6, 16, 0.6), Vector3.new(x, G + 8, z), "Really black", METAL)
		local cl = p("CourtLight", Vector3.new(4, 1.6, 1), Vector3.new(x, G + 16.6, z), "Cyan", NEON, 0.12, true)
	end
end

local courtSign = p("TennisCourtSign", Vector3.new(34, 4.5, 0.5), Vector3.new(0, G + 10, TZ1 + 5), "Really black", SMP, 0, true)
sign(courtSign, "PLASMA COURTS", Color3.fromRGB(80, 220, 255))

print("[TennisWorld] Metal Galactic (Plasma Courts) theme built successfully!")
