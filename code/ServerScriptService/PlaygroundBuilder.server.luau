local workspace = game:GetService("Workspace")

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

local folder = Instance.new("Folder")
folder.Name = "Playground"
folder.Parent = workspace

local G = 1

local SMP   = Enum.Material.SmoothPlastic
local NEON  = Enum.Material.Neon
local METAL = Enum.Material.Metal
local WOOD  = Enum.Material.Wood
local FABRIC= Enum.Material.Fabric

local function newPart(name, size, pos, color, mat)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.BrickColor = BrickColor.new(color)
	p.Material = mat or SMP
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function newPartCF(name, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.Material = mat or SMP
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function newWedge(name, size, cf, color, mat)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.Material = mat or SMP
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function pole(x, z, h, w, color, mat)
	return newPart("Pole", Vector3.new(w, h, w), Vector3.new(x, G + h / 2, z), color, mat or METAL)
end

local function beamX(x, y, z, len, w, color, mat)
	return newPart("Beam", Vector3.new(len, w, w), Vector3.new(x, y, z), color, mat or METAL)
end

local function beamZ(x, y, z, len, w, color, mat)
	return newPart("Beam", Vector3.new(w, w, len), Vector3.new(x, y, z), color, mat or METAL)
end

-- =============================================
-- GROUND  – bright checkerboard carnival floor
-- =============================================
-- Main checkerboard tiles
local tileColors = { "Hot pink", "Bright violet", "Cyan", "Lime green", "Bright yellow" }
local tileSize = 14
local ci = 0
for xi = -55, 55, tileSize do
	for zi = -55, 55, tileSize do
		ci += 1
		local c = tileColors[((ci - 1) % #tileColors) + 1]
		local p = newPart("Tile", Vector3.new(tileSize, 1, tileSize),
			Vector3.new(xi + tileSize/2 - 1, 0, zi + tileSize/2 - 1), c, SMP)
		p.Transparency = 0.0
	end
end

-- White grout lines between tiles
for xi = -55, 55, tileSize do
	local g = newPart("GroutZ", Vector3.new(0.4, 0.15, 112), Vector3.new(xi, G + 0.12, 0), "White", NEON)
	g.Transparency = 0.5
	g.CanCollide = false
end
for zi = -55, 55, tileSize do
	local g = newPart("GroutX", Vector3.new(112, 0.15, 0.4), Vector3.new(0, G + 0.12, zi), "White", NEON)
	g.Transparency = 0.5
	g.CanCollide = false
end

-- Center star burst
local starColors = { "Bright yellow", "Bright orange", "Hot pink", "Cyan", "Lime green" }
for i = 0, 7 do
	local angle = math.rad(i * 45)
	local ray = newPartCF("StarRay", Vector3.new(1.5, 0.2, 48),
		CFrame.new(0, G + 0.11, 0) * CFrame.Angles(0, angle, 0),
		starColors[(i % #starColors) + 1], NEON)
	ray.Transparency = 0.35
	ray.CanCollide = false
end

-- =============================================
-- PERIMETER  – colorful carnival fence with flags
-- =============================================
local fenceColors = { "Bright red", "Bright yellow", "Bright blue", "Lime green", "Hot pink" }
local fH = 5
for i = -55, 55, 8 do
	local ci2 = math.floor((i + 55) / 8) + 1
	local fc = fenceColors[((ci2 - 1) % #fenceColors) + 1]
	pole(i, -59, fH, 1.2, fc, WOOD)
	pole(i,  59, fH, 1.2, fc, WOOD)
	pole(-59, i, fH, 1.2, fc, WOOD)
	pole( 59, i, fH, 1.2, fc, WOOD)
end

-- Colorful top rail
for _, z in {-59, 59} do
	local r = beamX(0, G + fH, z, 122, 0.6, "Bright yellow", WOOD)
	r.Transparency = 0
	local r2 = beamX(0, G + fH * 0.55, z, 122, 0.45, "Bright red", WOOD)
	r2.Transparency = 0
end
for _, x in {-59, 59} do
	local r = beamZ(x, G + fH, 0, 122, 0.6, "Bright yellow", WOOD)
	r.Transparency = 0
	local r2 = beamZ(x, G + fH * 0.55, 0, 122, 0.45, "Bright red", WOOD)
	r2.Transparency = 0
end

-- Pennant flags on perimeter
local flagColors = { "Hot pink", "Bright orange", "Cyan", "Lime green", "Bright yellow" }
for _, z in {-59, 59} do
	for fi, xi in {-48, -32, -16, 0, 16, 32, 48} do
		local fc = flagColors[((fi - 1) % #flagColors) + 1]
		local flag = newPartCF("Flag", Vector3.new(3, 2, 0.15),
			CFrame.new(xi, G + fH + 1.2, z), fc, FABRIC)
		flag.Transparency = 0.15
	end
end

-- =============================================
-- BIG TOP TENT  (north-west) – red/white stripes
-- =============================================
local function buildBigTent(ox, oz)
	-- Tent poles
	pole(ox, oz, 14, 1.5, "Bright red", WOOD)
	for i = 0, 5 do
		local a = math.rad(i * 60)
		pole(ox + math.sin(a) * 10, oz + math.cos(a) * 10, 9, 1, "Bright red", WOOD)
	end
	-- Roof panels (alternating red/white)
	for i = 0, 5 do
		local a1 = math.rad(i * 60)
		local a2 = math.rad((i + 1) * 60)
		local midA = (a1 + a2) / 2
		local roofColor = (i % 2 == 0) and "Bright red" or "White"
		local panel = newPartCF("TentRoof", Vector3.new(10.5, 0.5, 6),
			CFrame.new(ox + math.sin(midA) * 5.5, G + 11.5, oz + math.cos(midA) * 5.5)
			* CFrame.Angles(0, midA, -math.rad(25)),
			roofColor, FABRIC)
		panel.Transparency = 0.1
	end
	-- Top cone cap
	newWedge("TentTop", Vector3.new(2, 4, 2),
		CFrame.new(ox, G + 15, oz), "Bright red", FABRIC)
	-- Entrance arch
	pole(ox - 5, oz + 10, 8, 0.8, "Bright yellow", WOOD)
	pole(ox + 5, oz + 10, 8, 0.8, "Bright yellow", WOOD)
	local arch = beamX(ox, G + 8.4, oz + 10, 11.5, 0.6, "Bright yellow", WOOD)
	arch.Transparency = 0
	local sign = newPart("TentSign", Vector3.new(8, 2, 0.4),
		Vector3.new(ox, G + 9.8, oz + 10), "Bright orange", SMP)
	sign.Transparency = 0
end
buildBigTent(-35, -30)

-- =============================================
-- CAROUSEL  (center) – spinning platform base
-- =============================================
local function buildCarousel(ox, oz)
	-- Platform base
	local disk = Instance.new("Part")
	disk.Name = "CarouselBase"
	disk.Shape = Enum.PartType.Cylinder
	disk.Size = Vector3.new(1.2, 16, 16)
	disk.CFrame = CFrame.new(ox, G + 0.6, oz) * CFrame.Angles(0, 0, math.rad(90))
	disk.BrickColor = BrickColor.new("Bright red")
	disk.Material = WOOD
	disk.Anchored = true
	disk.Parent = folder

	-- Center pole
	pole(ox, oz, 14, 1.2, "Bright yellow", WOOD)

	-- Roof
	local roof = Instance.new("Part")
	roof.Name = "CarouselRoof"
	roof.Shape = Enum.PartType.Cylinder
	roof.Size = Vector3.new(0.8, 18, 18)
	roof.CFrame = CFrame.new(ox, G + 14.4, oz) * CFrame.Angles(0, 0, math.rad(90))
	roof.BrickColor = BrickColor.new("Hot pink")
	roof.Material = FABRIC
	roof.Anchored = true
	roof.Transparency = 0.1
	roof.Parent = folder

	-- Striped roof wedges
	for i = 0, 5 do
		local a = math.rad(i * 60 + 30)
		local roofStripe = newPartCF("CarouselStripe", Vector3.new(0.6, 9, 0.6),
			CFrame.new(ox + math.sin(a) * 7, G + 14.3, oz + math.cos(a) * 7),
			"White", SMP)
		roofStripe.Transparency = 0.2
	end

	-- Horses (static posts)
	local horseColors = { "Bright blue", "Hot pink", "Lime green", "Bright orange", "Cyan", "Bright violet" }
	for i = 0, 5 do
		local a = math.rad(i * 60)
		local hx = ox + math.sin(a) * 6
		local hz = oz + math.cos(a) * 6
		pole(hx, hz, 8, 0.35, "White", WOOD)
		-- Horse body
		newPart("HorseBody", Vector3.new(2, 1.4, 3.5),
			Vector3.new(hx, G + 2.5, hz), horseColors[i + 1], SMP)
		newPart("HorseHead", Vector3.new(1.3, 1.8, 1.3),
			Vector3.new(hx, G + 3.8, hz - 1.5), horseColors[i + 1], SMP)
	end
end
buildCarousel(0, 0)

-- =============================================
-- GAME STALLS  (east side) – colorful booths
-- =============================================
local function buildStall(ox, oz, accentColor)
	-- Back wall
	newPart("StallBack", Vector3.new(8, 6, 0.5), Vector3.new(ox, G + 3, oz - 3), "White", WOOD)
	-- Side walls
	newPart("StallSideL", Vector3.new(0.5, 6, 6), Vector3.new(ox - 4, G + 3, oz), "White", WOOD)
	newPart("StallSideR", Vector3.new(0.5, 6, 6), Vector3.new(ox + 4, G + 3, oz), "White", WOOD)
	-- Counter
	newPart("StallCounter", Vector3.new(8, 0.5, 2.5), Vector3.new(ox, G + 2.5, oz + 1.5), accentColor, WOOD)
	-- Roof canopy
	newPartCF("Canopy", Vector3.new(9, 0.5, 6),
		CFrame.new(ox, G + 6.3, oz) * CFrame.Angles(math.rad(-10), 0, 0), accentColor, FABRIC).Transparency = 0.1
	-- Striped awning
	for i = -3, 3, 1.5 do
		local stripe = newPart("AwningStripe", Vector3.new(1.3, 0.4, 6.2),
			Vector3.new(ox + i, G + 6.5, oz), "White", FABRIC)
		stripe.Transparency = 0.2
	end
	-- Prize display balls
	for i = -2, 2 do
		local ball = newPart("PrizeBall", Vector3.new(0.9, 0.9, 0.9),
			Vector3.new(ox + i * 1.5, G + 3.6, oz - 2.5),
			(i % 2 == 0) and accentColor or "White", NEON)
		ball.Shape = Enum.PartType.Ball
		ball.Transparency = 0.15
	end
end
buildStall(46, -20, "Hot pink")
buildStall(46,   5, "Cyan")
buildStall(46,  30, "Bright orange")

-- =============================================
-- BALLOON ARCH  (south entrance area)
-- =============================================
local balloonColors = { "Bright red", "Bright blue", "Bright yellow", "Lime green", "Hot pink", "Cyan", "Bright orange" }
local function balloon(x, y, z, size, color)
	local b = newPart("Balloon", Vector3.new(size, size, size), Vector3.new(x, y, z), color, NEON)
	b.Shape = Enum.PartType.Ball
	b.Transparency = 0.2
	b.CanCollide = false
end

-- Arch over south path
for i = 0, 8 do
	local t = i / 8
	local arcX = -20 + t * 40
	local arcY = G + 4 + math.sin(t * math.pi) * 8
	local arcZ = -50
	balloon(arcX, arcY, arcZ, 2.5 - math.abs(t - 0.5), balloonColors[(i % #balloonColors) + 1])
end

-- Balloon clusters at key points
local clusterPositions = { {-42, -42}, {42, -42}, {-42, 42}, {42, 42} }
for _, cp in clusterPositions do
	for j = 1, 5 do
		local bx = cp[1] + math.random(-3, 3)
		local bz = cp[2] + math.random(-3, 3)
		local by = G + 6 + math.random(0, 4)
		balloon(bx, by, bz, 1.5 + math.random() * 1.5, balloonColors[(j % #balloonColors) + 1])
		-- String
		newPart("BalloonString", Vector3.new(0.1, 3, 0.1), Vector3.new(bx, G + 3, bz), "White", NEON)
	end
end

-- =============================================
-- BOUNCE CASTLE  (south-west) – inflatable look
-- =============================================
local function buildBounceCastle(ox, oz)
	-- Floor
	newPart("BCFloor", Vector3.new(14, 1.5, 14), Vector3.new(ox, G + 0.75, oz), "Bright orange", SMP)
	-- Side walls (puffy look with rounded ends)
	newPart("BCWallN", Vector3.new(14, 5, 2), Vector3.new(ox, G + 3.5, oz - 6), "Hot pink", SMP)
	newPart("BCWallS", Vector3.new(14, 5, 2), Vector3.new(ox, G + 3.5, oz + 6), "Hot pink", SMP)
	newPart("BCWallW", Vector3.new(2, 5, 10), Vector3.new(ox - 6, G + 3.5, oz), "Bright violet", SMP)
	newPart("BCWallE", Vector3.new(2, 5, 10), Vector3.new(ox + 6, G + 3.5, oz), "Bright violet", SMP)
	-- Puffy roof
	newPart("BCRoof", Vector3.new(14, 2.5, 14), Vector3.new(ox, G + 7.25, oz), "Bright yellow", SMP)
	-- Turrets
	for _, xo in {-6, 6} do
		for _, zo in {-6, 6} do
			local turret = Instance.new("Part")
			turret.Name = "BCTurret"
			turret.Shape = Enum.PartType.Cylinder
			turret.Size = Vector3.new(5, 4, 4)
			turret.CFrame = CFrame.new(ox + xo, G + 5.5, oz + zo) * CFrame.Angles(0, 0, math.rad(90))
			turret.BrickColor = BrickColor.new("Lime green")
			turret.Material = SMP
			turret.Anchored = true
			turret.Parent = folder
		end
	end
	-- Entrance ramp
	newWedge("BCRamp", Vector3.new(4, 1.5, 3),
		CFrame.new(ox, G + 0.75, oz + 7.5), "Bright orange", SMP)
	-- Stars on walls
	for _, xo in {-4, 0, 4} do
		local star = newPart("BCStar", Vector3.new(1.5, 1.5, 0.3),
			Vector3.new(ox + xo, G + 4, oz - 6.2), "Bright yellow", NEON)
		star.Transparency = 0.1
	end
end
buildBounceCastle(-38, 32)

-- =============================================
-- FERRIS WHEEL FRAME  (north-east)
-- =============================================
local function buildFerrisWheel(ox, oz)
	-- Support legs (A-frame)
	for _, xo in {-6, 6} do
		newPartCF("FWLegL", Vector3.new(1.2, 16, 1.2),
			CFrame.new(ox + xo, G + 7.5, oz - 2) * CFrame.Angles(0, 0, math.rad(xo > 0 and -10 or 10)),
			"Bright red", METAL)
		newPartCF("FWLegR", Vector3.new(1.2, 16, 1.2),
			CFrame.new(ox + xo, G + 7.5, oz + 2) * CFrame.Angles(0, 0, math.rad(xo > 0 and -10 or 10)),
			"Bright red", METAL)
	end
	-- Axle
	local axle = Instance.new("Part")
	axle.Name = "FWAxle"
	axle.Shape = Enum.PartType.Cylinder
	axle.Size = Vector3.new(6, 1.5, 1.5)
	axle.CFrame = CFrame.new(ox, G + 15.5, oz)
	axle.BrickColor = BrickColor.new("Bright yellow")
	axle.Material = METAL
	axle.Anchored = true
	axle.Parent = folder

	-- Wheel ring (8 spokes + rim arcs)
	local wheelRadius = 12
	for i = 0, 7 do
		local a = math.rad(i * 45)
		-- Spoke
		newPartCF("FWSpoke", Vector3.new(0.5, wheelRadius * 2, 0.5),
			CFrame.new(ox, G + 15.5, oz) * CFrame.Angles(0, 0, a),
			"White", METAL)
		-- Gondola
		local gx = ox + math.sin(a) * wheelRadius
		local gy = G + 15.5 + math.cos(a) * wheelRadius
		local gondolaColors = { "Hot pink", "Cyan", "Bright yellow", "Lime green",
								"Bright orange", "Bright violet", "Bright red", "Bright blue" }
		newPart("Gondola", Vector3.new(2.5, 2, 2),
			Vector3.new(gx, gy, oz), gondolaColors[i + 1], SMP)
	end
end
buildFerrisWheel(38, -32)

-- =============================================
-- FOOD STANDS  (south-east)
-- =============================================
local function buildFoodCart(ox, oz, label, color)
	newPart("CartBase", Vector3.new(5, 4, 3), Vector3.new(ox, G + 2, oz), color, WOOD)
	newPart("CartTop", Vector3.new(5.5, 0.4, 3.5), Vector3.new(ox, G + 4.2, oz), "White", SMP)
	local umbrella = Instance.new("Part")
	umbrella.Name = "CartUmbrella"
	umbrella.Shape = Enum.PartType.Cylinder
	umbrella.Size = Vector3.new(0.3, 9, 9)
	umbrella.CFrame = CFrame.new(ox, G + 6.5, oz) * CFrame.Angles(0, 0, math.rad(90))
	umbrella.BrickColor = BrickColor.new(color)
	umbrella.Material = FABRIC
	umbrella.Anchored = true
	umbrella.Transparency = 0.15
	umbrella.Parent = folder
	pole(ox, oz, 7, 0.4, "White", METAL)
end
buildFoodCart(30, 45, "Cotton Candy", "Hot pink")
buildFoodCart(44, 45, "Lemonade", "Bright yellow")
buildFoodCart(16, 45, "Popcorn", "Bright orange")

-- =============================================
-- BALL PITS  (two corners — no collision)
-- =============================================
local function buildBallPit(ox, oz, w, d, color)
	newPart("BPitWallN", Vector3.new(w, 2, 0.6), Vector3.new(ox, G + 1, oz - d/2), "White", WOOD)
	newPart("BPitWallS", Vector3.new(w, 2, 0.6), Vector3.new(ox, G + 1, oz + d/2), "White", WOOD)
	newPart("BPitWallW", Vector3.new(0.6, 2, d), Vector3.new(ox - w/2, G + 1, oz), "White", WOOD)
	newPart("BPitWallE", Vector3.new(0.6, 2, d), Vector3.new(ox + w/2, G + 1, oz), "White", WOOD)
	newPart("BPitFloor", Vector3.new(w, 0.5, d), Vector3.new(ox, G + 0.25, oz), color, SMP)
	-- Colorful balls in pit
	local pitBallColors = { "Bright red", "Bright blue", "Lime green", "Hot pink", "Bright yellow", "Cyan" }
	math.randomseed(ox * 100 + oz)
	for _ = 1, 18 do
		local bx = ox + math.random(-1, 1) * (w/2 - 1.5)
		local bz = oz + math.random(-1, 1) * (d/2 - 1.5)
		local b = newPart("PitBall", Vector3.new(1.2, 1.2, 1.2),
			Vector3.new(bx, G + 1.3, bz),
			pitBallColors[math.random(#pitBallColors)], NEON)
		b.Shape = Enum.PartType.Ball
		b.Transparency = 0.2
		b.CanCollide = false
	end
end
buildBallPit(-40, 32, 12, 10, "Lime green")

-- =============================================
-- NEON SIGN ARCH at entrance (south, Z~54)
-- =============================================
pole(-12, 54, 12, 1.2, "Bright red", WOOD)
pole( 12, 54, 12, 1.2, "Bright red", WOOD)
local archBeam = beamX(0, G + 12.6, 54, 25, 1.5, "Bright yellow", WOOD)
archBeam.Transparency = 0
-- "PLAYGROUND" text implied by neon panels
for i, c in { "Hot pink", "Cyan", "Bright yellow", "Lime green", "Hot pink" } do
	local panel = newPart("SignPanel", Vector3.new(4, 2.5, 0.4),
		Vector3.new(-10 + (i-1) * 5, G + 14.5, 54), c, NEON)
	panel.Transparency = 0.1
end

-- =============================================
-- SCATTERED DECORATIVE STARS  (floor level)
-- =============================================
local starPositions = {
	{-25, -15}, {20, -30}, {-10, 20}, {35, 10}, {-45, 5},
	{10, -50}, {-30, 40}, {50, -15}, {-5, 35}, {25, 25},
}
for _, sp in starPositions do
	local starGlow = newPart("FloorStar", Vector3.new(3, 0.15, 3),
		Vector3.new(sp[1], G + 0.17, sp[2]), "Bright yellow", NEON)
	starGlow.Transparency = 0.35
	starGlow.CanCollide = false
end

print("[Playground] Carnival theme built successfully!")
