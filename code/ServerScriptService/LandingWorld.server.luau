local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = workspace:FindFirstChild("LandingWorld")
if not folder then
	folder = Instance.new("Folder")
	folder.Name   = "LandingWorld"
	folder.Parent = workspace
else
	folder:ClearAllChildren()
end

local landingEvent = ReplicatedStorage:FindFirstChild("LandingWorldEvent")
if landingEvent and not landingEvent:IsA("RemoteEvent") then
	landingEvent:Destroy(); landingEvent = nil
end
if not landingEvent then
	landingEvent        = Instance.new("RemoteEvent")
	landingEvent.Name   = "LandingWorldEvent"
	landingEvent.Parent = ReplicatedStorage
end

-- ── Fixed coordinates ─────────────────────────────────────────────────────────
-- Start/respawn beside the spinning wheel stairs on the starter island.
local START_CF        = CFrame.new(43, 88, -735) * CFrame.Angles(0, math.rad(90), 0)
local PLAYGROUND_CF   = CFrame.new(0, 7, 0)
local TIME_MACHINE_CF = CFrame.new(0, 7, -112)
local BY              = 82     -- island top surface Y
local CZ              = -760   -- island center Z
local playerStartTimes = {}

-- ── Material aliases ──────────────────────────────────────────────────────────
local SMP  = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local CONC = Enum.Material.Concrete
local METAL = Enum.Material.Metal
local WD   = Enum.Material.Wood
local DP   = Enum.Material.DiamondPlate
local BRICK = Enum.Material.Brick

-- ── Part factories ────────────────────────────────────────────────────────────
local function p(name, size, cf, color, mat, transp, noCol)
	local pt = Instance.new("Part")
	pt.Name          = name
	pt.Size          = size
	pt.CFrame        = type(cf) == "vector" and CFrame.new(cf) or cf
	pt.BrickColor    = BrickColor.new(color)
	pt.Material      = mat or SMP
	pt.Transparency  = transp or 0
	pt.Anchored      = true
	pt.CanCollide    = noCol ~= true
	pt.CastShadow    = false
	pt.TopSurface    = Enum.SurfaceType.Smooth
	pt.BottomSurface = Enum.SurfaceType.Smooth
	pt.Parent        = folder
	return pt
end

local function pos(x, y, z) return CFrame.new(x, y, z) end

local function cyl(name, size, cf, color, mat, transp, noCol)
	local pt = p(name, size, cf, color, mat, transp, noCol)
	pt.Shape = Enum.PartType.Cylinder
	return pt
end

local function sph(name, r, x, y, z, color, mat, transp)
	local pt = p(name, Vector3.new(r, r, r), pos(x, y, z), color, mat, transp, true)
	pt.Shape = Enum.PartType.Ball
	return pt
end

local function glow(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Color      = color
	l.Brightness = brightness or 2
	l.Range      = range or 30
	l.Parent     = parent
end

local function billboard(parent, text, textColor, size, offset)
	local bg  = Instance.new("BillboardGui")
	bg.Size        = size   or UDim2.new(0, 300, 0, 80)
	bg.StudsOffset = offset or Vector3.new(0, 4, 0)
	bg.AlwaysOnTop = false
	bg.Parent      = parent
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = text
	lbl.TextColor3             = textColor or Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0
	lbl.Font                   = Enum.Font.GothamBlack
	lbl.TextScaled             = true
	lbl.Parent                 = bg
	return lbl
end

local function addPrompt(part, action, obj, cb)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText            = action
	pr.ObjectText            = obj
	pr.KeyboardKeyCode       = Enum.KeyCode.E
	pr.MaxActivationDistance = 14
	pr.RequiresLineOfSight   = false
	pr.Parent                = part
	local db = {}
	pr.Triggered:Connect(function(player)
		local now = os.clock()
		if db[player] and now - db[player] < 1 then return end
		db[player] = now
		cb(player)
	end)
end

local function setPlayerCF(player, cf)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = cf
	hrp.AssemblyLinearVelocity = Vector3.zero
end

local function fireEvent(player, kind, payload)
	landingEvent:FireClient(player, kind, payload)
end

local function exitLanding(player, dest)
	player:SetAttribute("InLandingWorld", false)
	player:SetAttribute("LandingWorldCompleted", true)
	fireEvent(player, "Finish", playerStartTimes[player] and os.clock() - playerStartTimes[player] or 0)
	setPlayerCF(player, dest)
end

-- ════════════════════════════════════════════════════════════════════════════
--  THE CLOCKWORK KEEP
--  Theme: Steampunk floating rock island.
--  Players spawn on the Grand Clocktower observation deck (Y=94, facing south).
--  West  → Adventure Steam Dock  (green neon, valve-gate to Playground)
--  East  → Clockwork Time Gate   (brass/gold,  gear-gate to Time Machines)
--  North → Boiler House          (industrial furnace block)
--  South → Cobblestone forecourt with compass rose, south bridge arch
--  Above → Tethered Hot Air Balloon
-- ════════════════════════════════════════════════════════════════════════════

local GY   = BY + 1         -- ground floor Y (top of island surface)
local IRON = "Dark stone grey"
local BRASS= "Bright yellow"
local COPPER="Reddish brown"
local STONE= "Medium stone grey"
local DSTONE="Dark stone grey"
local BRICK_C="Bright red"

-- ── Helper: decorative gear wheel (vertical, facing Z) ───────────────────────
local function gear(cx, cy, cz, radius, thick, color, nTeeth, rotY)
	rotY = rotY or 0
	cyl("GearDisc", Vector3.new(thick, radius*2, radius*2),
		pos(cx, cy, cz) * CFrame.Angles(0, rotY, math.rad(90)), color, METAL)
	-- Hub
	cyl("GearHub", Vector3.new(thick+1, radius*0.4, radius*0.4),
		pos(cx, cy, cz) * CFrame.Angles(0, rotY, math.rad(90)), BRASS, METAL)
	-- Teeth around rim
	for i = 0, nTeeth - 1 do
		local a   = math.rad(i * 360 / nTeeth) + rotY
		local ty  = cy + math.sin(a) * (radius + 1.8)
		local tz  = cz + math.cos(a) * (radius + 1.8)
		p("GearTooth", Vector3.new(thick - 0.4, 2.8, 2.2),
			pos(cx, ty, tz), color, METAL)
	end
end

-- ── Helper: brass lamp post ───────────────────────────────────────────────────
local function lampPost(lx, ly, lz)
	p("LampPost", Vector3.new(1.2, 14, 1.2), pos(lx, ly + 7, lz), COPPER, METAL)
	p("LampArm",  Vector3.new(5, 0.8, 0.8),  pos(lx + 2.5, ly + 14, lz), COPPER, METAL)
	local lb = sph("LampBulb", 2.8, lx + 5, ly + 14, lz, BRASS, NEON, 0.08)
	glow(lb, Color3.fromRGB(255, 220, 100), 2.5, 26)
end

-- ── Helper: riveted iron beam ─────────────────────────────────────────────────
local function ibeam(x1, y, z1, x2, z2, thick)
	local dx   = x2 - x1
	local dz   = z2 - z1
	local len  = math.sqrt(dx * dx + dz * dz)
	local ang  = math.atan2(dx, dz)
	p("IBeam", Vector3.new(thick, thick * 0.6, len),
		pos((x1+x2)/2, y, (z1+z2)/2) * CFrame.Angles(0, ang, 0), IRON, METAL)
end

-- ════════════════ ISLAND BASE ════════════════════════════════════════════════
-- Layered floating rock silhouette
p("RockBase1", Vector3.new(270, 8, 200), pos(0, BY - 5,  CZ), "Dark stone grey", CONC)
p("RockBase2", Vector3.new(246, 5, 178), pos(0, BY - 0.5,CZ), STONE, CONC)
p("RockRim",   Vector3.new(250, 1, 182), pos(0, BY + 2.5,CZ), STONE, CONC)

-- Iron grating on top of island (two overlapping panels with a gap for the wood planks)
p("GratingW",  Vector3.new(118, 0.6, 178), pos(-65, GY + 0.3, CZ), IRON, DP)
p("GratingE",  Vector3.new(118, 0.6, 178), pos( 65, GY + 0.3, CZ), IRON, DP)
-- Wooden plank strip down the center (the main walkway)
p("PlankPath", Vector3.new(24, 0.6, 178), pos(0, GY + 0.3, CZ), COPPER, WD)
-- Plank cross-strips at regular intervals
for zi = CZ - 82, CZ + 82, 20 do
	p("Plank", Vector3.new(110, 0.55, 3.5), pos(0, GY + 0.35, zi), COPPER, WD)
end

-- Rock edge "teeth" for organic look
for _, e in {
	{-130, CZ-82, 36, 20}, { 130, CZ-82, 32, 18}, {-130, CZ+82, 28, 16},
	{ 130, CZ+82, 34, 19}, {-120, CZ,    24, 14}, { 120, CZ,    26, 15},
	{  -55, CZ-95, 20, 12}, {   55, CZ-95, 22, 13}, {0, CZ-98, 30, 17},
} do
	sph("RockEdge", e[3], e[1], BY - 6, e[2], DSTONE, CONC, 0)
	sph("RockEdge", e[4], e[1]+math.random(-6,6), BY-12, e[2]+math.random(-6,6), STONE, CONC, 0)
end

-- Invisible containment walls
p("CntN", Vector3.new(255, 350, 0.5), pos(0, 175, CZ-97), "Really black", SMP, 1)
p("CntS", Vector3.new(255, 350, 0.5), pos(0, 175, CZ+97), "Really black", SMP, 1)
p("CntE", Vector3.new(0.5, 350, 198), pos( 128, 175, CZ), "Really black", SMP, 1)
p("CntW", Vector3.new(0.5, 350, 198), pos(-128, 175, CZ), "Really black", SMP, 1)

-- ════════════════ GRAND CLOCKTOWER (spawn) ════════════════════════════════════
-- Player spawns at (0, 94, CZ) = BY+12. Tower built around that point.
local TX, TZ = 0, CZ

-- Lower tower body (below observation deck, BY → BY+12)
p("TowerBase4", Vector3.new(26, 1, 26), pos(TX, GY,       TZ), DSTONE, CONC)  -- plinth
p("TowerLow",   Vector3.new(18, 12, 18), pos(TX, GY + 6,  TZ), STONE, CONC)
-- Buttresses at base corners
for _, bc in {{-10, -10},{10, -10},{-10, 10},{10, 10}} do
	p("Buttress", Vector3.new(4, 12, 4), pos(TX + bc[1], GY + 6, TZ + bc[2]), DSTONE, CONC)
end
-- Corner iron trim strips on lower tower
for _, bx in {-9, 9} do
	for _, bz in {-9, 9} do
		p("TowerTrim", Vector3.new(0.6, 14, 0.6), pos(TX + bx, GY + 7, TZ + bz), IRON, METAL)
	end
end

-- Observation deck at Y=BY+12=94 — wide overhang with iron railing
p("ObsDeck",  Vector3.new(28, 1.2, 28), pos(TX, BY + 12.6, TZ), STONE, CONC)
p("ObsDecor", Vector3.new(30, 0.4, 30), pos(TX, BY + 13.4, TZ), BRASS, METAL)
-- Railing around observation deck (4 sides + corner posts)
for _, r in {
	{Vector3.new(28, 3.5, 0.8), pos(TX,        BY+15.5, TZ-14.5)},
	{Vector3.new(28, 3.5, 0.8), pos(TX,        BY+15.5, TZ+14.5)},
	{Vector3.new(0.8, 3.5, 28), pos(TX - 14.5, BY+15.5, TZ)},
	{Vector3.new(0.8, 3.5, 28), pos(TX + 14.5, BY+15.5, TZ)},
} do
	p("Rail", r[1], r[2], IRON, METAL)
end
for _, cp in {{-14.5,-14.5},{14.5,-14.5},{-14.5,14.5},{14.5,14.5}} do
	local post = p("RailPost", Vector3.new(1.5, 5, 1.5), pos(TX+cp[1], BY+16, TZ+cp[2]), BRASS, METAL)
	sph("PostTop", 1.8, TX+cp[1], BY+19, TZ+cp[2], BRASS, NEON, 0.05)
end

-- Upper tower body (above obs deck, BY+13 → BY+52)
p("TowerMid",  Vector3.new(14, 28, 14), pos(TX, BY + 27, TZ), STONE, CONC)
p("TowerUpper",Vector3.new(12, 12, 12), pos(TX, BY + 46, TZ), DSTONE, CONC)
-- Iron corner columns on upper tower
for _, bc in {{-7,-7},{7,-7},{-7,7},{7,7}} do
	p("UpperCol", Vector3.new(1.2, 40, 1.2), pos(TX+bc[1], BY+27, TZ+bc[2]), IRON, METAL)
end
-- Horizontal iron band rings every 10 studs
for ry = BY+18, BY+52, 10 do
	p("TowerBand", Vector3.new(16, 0.8, 16), pos(TX, ry, TZ), BRASS, METAL)
end

-- Clock faces (BillboardGui on a thin sign part facing each cardinal direction)
local clockFaces = {
	{pos(TX,       BY+34, TZ-7.1), 0},
	{pos(TX,       BY+34, TZ+7.1), math.rad(180)},
	{pos(TX - 7.1, BY+34, TZ),     math.rad(-90)},
	{pos(TX + 7.1, BY+34, TZ),     math.rad(90)},
}
for _, cf2 in clockFaces do
	local face = p("ClockFace", Vector3.new(0.3, 12, 12),
		cf2[1] * CFrame.Angles(0, cf2[2], 0), DSTONE, SMP)
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 240, 0, 240)
	bb.StudsOffset = Vector3.new(0, 0, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = face
	local bg2 = Instance.new("Frame")
	bg2.Size = UDim2.new(1, 0, 1, 0)
	bg2.BackgroundColor3 = Color3.fromRGB(12, 10, 6)
	bg2.Parent = bb
	local rim = Instance.new("UIStroke")
	rim.Color     = Color3.fromRGB(200, 160, 40)
	rim.Thickness = 8
	rim.Parent    = bg2
	local lbl2 = Instance.new("TextLabel")
	lbl2.Size               = UDim2.new(1,0,1,0)
	lbl2.BackgroundTransparency = 1
	lbl2.Text               = "🕐"
	lbl2.TextScaled         = true
	lbl2.Font               = Enum.Font.GothamBlack
	lbl2.TextColor3         = Color3.fromRGB(220, 175, 50)
	lbl2.Parent             = bg2
end

local keepSign = p("ClockTowerKeepSign", Vector3.new(38, 8, 0.8),
	pos(TX, BY + 42, TZ + 15.3), IRON, METAL, 0, true)
p("ClockTowerKeepSignGlowTop", Vector3.new(40, 0.35, 1), pos(TX, BY + 46.3, TZ + 15.75), BRASS, NEON, 0.12, true)
p("ClockTowerKeepSignGlowBottom", Vector3.new(40, 0.35, 1), pos(TX, BY + 37.7, TZ + 15.75), BRASS, NEON, 0.18, true)
for _, faceId in {Enum.NormalId.Front, Enum.NormalId.Back} do
	local gui = Instance.new("SurfaceGui")
	gui.Face = faceId
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 26
	gui.LightInfluence = 0
	gui.Parent = keepSign

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(12, 9, 5)
	bg.BackgroundTransparency = 0.04
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 210, 60)
	stroke.Thickness = 5
	stroke.Parent = bg

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0.68, 0)
	title.Position = UDim2.new(0, 8, 0.03, 0)
	title.BackgroundTransparency = 1
	title.Text = "THE CLOCKWORK KEEP"
	title.TextColor3 = Color3.fromRGB(255, 218, 80)
	title.TextStrokeTransparency = 0.15
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = bg

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -16, 0.24, 0)
	sub.Position = UDim2.new(0, 8, 0.72, 0)
	sub.BackgroundTransparency = 1
	sub.Text = "START  -  TIME MACHINES  -  SPIN WHEEL"
	sub.TextColor3 = Color3.fromRGB(220, 230, 255)
	sub.TextStrokeTransparency = 0.45
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.Parent = bg
end

-- Battlement / merlons on tower top
for i = 0, 7 do
	local a  = math.rad(i * 45)
	local mx = TX + math.sin(a) * 6.5
	local mz = TZ + math.cos(a) * 6.5
	p("Merlon", Vector3.new(3.5, 5, 3.5), pos(mx, BY + 53, mz), DSTONE, CONC)
end

-- Spire
p("Spire1", Vector3.new(5, 14, 5),   pos(TX, BY + 59, TZ), DSTONE, CONC)
p("Spire2", Vector3.new(3, 10, 3),   pos(TX, BY + 69, TZ), IRON,   METAL)
p("Spire3", Vector3.new(1.5, 6, 1.5),pos(TX, BY + 76, TZ), BRASS,  METAL)
local spireTop = sph("SpireTop", 3, TX, BY + 80, TZ, BRASS, NEON, 0.05)
glow(spireTop, Color3.fromRGB(255, 210, 60), 4, 55)

-- Decorative large gears mounted on tower sides
gear(TX - 8.5, BY + 28, TZ,     8, 2.4, IRON, 10, 0)
gear(TX + 8.5, BY + 28, TZ,     8, 2.4, BRASS, 10, math.rad(15))
gear(TX,       BY + 28, TZ - 8.5, 7, 2.2, COPPER, 9, math.rad(8))

-- ════════════════ COBBLESTONE FORECOURT (south plaza) ════════════════════════
local plazaZ = CZ + 40
-- Cobblestone surface
p("Plaza",     Vector3.new(80, 0.6, 56), pos(0, GY + 0.3, plazaZ), STONE, CONC)
-- Cobble grid lines
for xi = -40, 40, 10 do
	p("CobbV", Vector3.new(0.3, 0.7, 56), pos(xi, GY + 0.65, plazaZ), DSTONE, CONC, 0, true)
end
for zi = plazaZ - 28, plazaZ + 28, 10 do
	p("CobbH", Vector3.new(80, 0.7, 0.3), pos(0, GY + 0.65, zi), DSTONE, CONC, 0, true)
end

-- Compass rose on plaza floor (neon direction lines)
local roseZ = plazaZ + 8
for ri = 0, 7 do
	local ra  = math.rad(ri * 45)
	local col = ri % 2 == 0 and "Bright red" or BRASS
	p("RoseLine", Vector3.new(0.35, 0.18, 22),
		pos(0, GY + 0.38, roseZ) * CFrame.Angles(0, ra, 0), col, NEON, 0.2, true)
end
sph("RoseCenter", 3, 0, GY + 0.3, roseZ, BRASS, NEON, 0.05)
-- Cardinal direction labels
for _, rd in {{"N", 0, -12}, {"S", 0, 12}, {"E", 12, 0}, {"W", -12, 0}} do
	local pt = p("RoseLabel", Vector3.new(0.1,0.1,0.1), pos(rd[2], GY+1, roseZ+rd[3]), BRASS, NEON, 1, true)
	billboard(pt, rd[1], Color3.fromRGB(255, 210, 60), UDim2.new(0,50,0,50), Vector3.new(0,0,0))
end

-- Plaza lamp posts (4 corners)
for _, lp in {{-35, plazaZ-22}, {35, plazaZ-22}, {-35, plazaZ+22}, {35, plazaZ+22}} do
	lampPost(lp[1], GY, lp[2])
end

-- Benches (rough stone + plank seat)
for _, bn in {{-28, plazaZ-10, 0}, {28, plazaZ-10, math.rad(180)}, {-28, plazaZ+26, 0}, {28, plazaZ+26, math.rad(180)}} do
	p("BenchSeat", Vector3.new(8, 0.8, 2),    pos(bn[1], GY+0.7, bn[2]) * CFrame.Angles(0,bn[3],0), COPPER, WD)
	p("BenchBack", Vector3.new(8, 1.5, 0.5),  pos(bn[1], GY+1.5, bn[2]) * CFrame.Angles(0,bn[3],0), DSTONE, CONC)
	p("BenchLeg1", Vector3.new(1.2, 1.8, 1.8),pos(bn[1]-3.2, GY+0.2, bn[2]) * CFrame.Angles(0,bn[3],0), IRON, METAL)
	p("BenchLeg2", Vector3.new(1.2, 1.8, 1.8),pos(bn[1]+3.2, GY+0.2, bn[2]) * CFrame.Angles(0,bn[3],0), IRON, METAL)
end

-- Big live trophy wall near the starter plaza.
local rewardWall = p("CrownsTrophiesWall", Vector3.new(70, 32, 2.2), pos(0, GY + 16, plazaZ - 29), IRON, METAL, 1, true)
p("CrownsTrophiesWallTrimTop", Vector3.new(74, 1.2, 2.8), pos(0, GY + 32.8, plazaZ - 28.8), BRASS, NEON, 1, true)
p("CrownsTrophiesWallTrimBottom", Vector3.new(74, 1.2, 2.8), pos(0, GY - 0.8, plazaZ - 28.8), BRASS, NEON, 1, true)
for _, wx in {-37, 37} do
	p("CrownsTrophiesWallPost", Vector3.new(2.5, 36, 3), pos(wx, GY + 16, plazaZ - 28.8), BRASS, METAL, 1, true)
end

local wallGui = Instance.new("SurfaceGui")
wallGui.Enabled = false
wallGui.Face = Enum.NormalId.South
wallGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
wallGui.PixelsPerStud = 18
wallGui.Parent = rewardWall

local wallBg = Instance.new("Frame")
wallBg.Size = UDim2.new(1, 0, 1, 0)
wallBg.BackgroundColor3 = Color3.fromRGB(10, 9, 8)
wallBg.BackgroundTransparency = 0.06
wallBg.Parent = wallGui

local wallTitle = Instance.new("TextLabel")
wallTitle.Size = UDim2.new(1, -24, 0, 86)
wallTitle.Position = UDim2.new(0, 12, 0, 8)
wallTitle.BackgroundTransparency = 1
wallTitle.Font = Enum.Font.GothamBlack
wallTitle.TextScaled = true
wallTitle.TextColor3 = Color3.fromRGB(255, 220, 70)
wallTitle.TextStrokeTransparency = 0.1
wallTitle.Text = "CROWNS & TROPHIES"
wallTitle.Parent = wallBg

local wallList = Instance.new("TextLabel")
wallList.Size = UDim2.new(1, -40, 1, -110)
wallList.Position = UDim2.new(0, 20, 0, 98)
wallList.BackgroundTransparency = 1
wallList.Font = Enum.Font.GothamBold
wallList.TextScaled = true
wallList.TextWrapped = true
wallList.TextXAlignment = Enum.TextXAlignment.Left
wallList.TextYAlignment = Enum.TextYAlignment.Top
wallList.TextColor3 = Color3.fromRGB(245, 245, 255)
wallList.TextStrokeTransparency = 0.35
wallList.Parent = wallBg

local function updateRewardWall()
	local rows = {}
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("leaderstats")
		local crowns = stats and stats:FindFirstChild("Crowns")
		local trophies = stats and stats:FindFirstChild("Trophies")
		table.insert(rows, {
			name = player.DisplayName or player.Name,
			crowns = crowns and crowns.Value or 0,
			trophies = trophies and trophies.Value or 0,
		})
	end
	table.sort(rows, function(a, b)
		if a.trophies == b.trophies then
			return a.crowns > b.crowns
		end
		return a.trophies > b.trophies
	end)
	if #rows == 0 then
		wallList.Text = "Finish stages to earn Crowns and Trophies."
		return
	end
	local lines = {}
	for i, row in ipairs(rows) do
		if i > 8 then break end
		table.insert(lines, string.format("%d. %s    Crowns: %d    Trophies: %d", i, row.name, row.crowns, row.trophies))
	end
	wallList.Text = table.concat(lines, "\n")
end

local function watchRewardStats(player)
	local function wire()
		local stats = player:FindFirstChild("leaderstats")
		if not stats then return end
		for _, statName in {"Crowns", "Trophies"} do
			local stat = stats:FindFirstChild(statName)
			if stat then
				stat.Changed:Connect(updateRewardWall)
			end
		end
		stats.ChildAdded:Connect(function(child)
			if child.Name == "Crowns" or child.Name == "Trophies" then
				child.Changed:Connect(updateRewardWall)
				updateRewardWall()
			end
		end)
		updateRewardWall()
	end
	player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then task.defer(wire) end
	end)
	task.defer(wire)
end

for _, player in Players:GetPlayers() do
	watchRewardStats(player)
end
Players.PlayerAdded:Connect(watchRewardStats)
Players.PlayerRemoving:Connect(function()
	task.defer(updateRewardWall)
end)
updateRewardWall()

-- Grand South Arch (entrance gate from the clouds)
local archZ = CZ + 88
p("ArchL",    Vector3.new(5, 46, 5),    pos(-24, GY + 23, archZ), DSTONE, CONC)
p("ArchR",    Vector3.new(5, 46, 5),    pos( 24, GY + 23, archZ), DSTONE, CONC)
p("ArchTop",  Vector3.new(53, 5, 5),    pos(  0, GY + 47, archZ), DSTONE, CONC)
p("ArchGrate",Vector3.new(51, 3, 3),    pos(  0, GY + 49.5, archZ), IRON, DP)
p("ArchNeon", Vector3.new(55, 0.4, 0.4),pos(  0, GY + 51.5, archZ), BRASS, NEON, 0.1, true)
-- Arch column caps + iron rings
for _, ax in {-24, 24} do
	p("ArchCap",  Vector3.new(7, 2.5, 7),   pos(ax, GY + 47, archZ), DSTONE, CONC)
	p("ArchPlinth",Vector3.new(7, 2.5, 7),  pos(ax, GY + 1,  archZ), DSTONE, CONC)
	cyl("ArchRing", Vector3.new(1, 8, 8),
		pos(ax, GY + 14, archZ) * CFrame.Angles(math.rad(90),0,0), IRON, METAL, 0.1, true)
	cyl("ArchRing", Vector3.new(1, 8, 8),
		pos(ax, GY + 32, archZ) * CFrame.Angles(math.rad(90),0,0), IRON, METAL, 0.1, true)
end
-- "THE CLOCKWORK KEEP" sign on arch
local archSign = p("ArchSignPt", Vector3.new(0.1,0.1,0.1), pos(0, GY + 56, archZ), BRASS, NEON, 1, true)
billboard(archSign, "⚙  THE CLOCKWORK KEEP  ⚙",
	Color3.fromRGB(255, 210, 60), UDim2.new(0, 560, 0, 76), Vector3.new(0,0,0))

-- ════════════════ BOILER HOUSE (north, behind tower) ═════════════════════════
local BHX, BHZ = 0, CZ - 72
local BHW, BHD, BHH = 46, 32, 22
-- Brick building
p("BHFloor", Vector3.new(BHW, 1, BHD),           pos(BHX, GY - 0.5, BHZ), DSTONE, CONC)
p("BHWallN", Vector3.new(BHW, BHH, 1.5),          pos(BHX, GY+BHH/2, BHZ-BHD/2), BRICK_C, BRICK)
p("BHWallS", Vector3.new(BHW, BHH, 1.5),          pos(BHX, GY+BHH/2, BHZ+BHD/2), BRICK_C, BRICK)
p("BHWallE", Vector3.new(1.5, BHH, BHD+3),        pos(BHX+BHW/2, GY+BHH/2, BHZ), BRICK_C, BRICK)
p("BHWallW", Vector3.new(1.5, BHH, BHD+3),        pos(BHX-BHW/2, GY+BHH/2, BHZ), BRICK_C, BRICK)
-- Iron roof
p("BHRoof",  Vector3.new(BHW+2, 1.5, BHD+2),      pos(BHX, GY+BHH+0.75, BHZ), IRON, DP)
-- Arched window openings (east/west faces, decorative neon)
for _, wz in {BHZ - 8, BHZ + 8} do
	p("BHWinE", Vector3.new(0.5, 8, 7), pos(BHX+BHW/2, GY+6, wz), "Bright orange", NEON, 0.72, true)
	p("BHWinW", Vector3.new(0.5, 8, 7), pos(BHX-BHW/2, GY+6, wz), "Bright orange", NEON, 0.72, true)
end
-- Chimneys (3 large stacks)
for _, cx2 in {-14, 0, 14} do
	local chH = 28 + math.abs(cx2) * 0.3
	p("Chimney", Vector3.new(5, chH, 5), pos(BHX + cx2, GY + BHH + chH/2, BHZ - 4), DSTONE, BRICK)
	p("ChimneyRim",Vector3.new(6, 1.5, 6), pos(BHX + cx2, GY + BHH + chH + 0.75, BHZ - 4), IRON, METAL)
	-- Steam/smoke neon column from chimney top
	local steamY = GY + BHH + chH + 2
	p("Steam", Vector3.new(3.5, 12, 3.5), pos(BHX + cx2, steamY + 6, BHZ - 4),
		"Institutional white", NEON, 0.7, true)
	p("Steam2", Vector3.new(5, 8, 5), pos(BHX + cx2, steamY + 14, BHZ - 4),
		"Institutional white", NEON, 0.82, true)
	glow(p("SteamGl", Vector3.new(0.1,0.1,0.1), pos(BHX+cx2, steamY+2, BHZ-4), "White", NEON, 1, true),
		Color3.fromRGB(220, 230, 255), 2, 22)
end
-- Boiler door (south face of boiler house)
p("BHDoor",  Vector3.new(8, 10, 0.5), pos(BHX, GY + 6, BHZ + BHD/2 + 0.3), IRON, METAL)
p("BHDoorGl",Vector3.new(6, 8, 0.4),  pos(BHX, GY + 6, BHZ + BHD/2 + 0.6), "Bright orange", NEON, 0.35, true)
glow(p("BHFireGl",Vector3.new(0.1,0.1,0.1),pos(BHX, GY+6, BHZ+BHD/2+1), "Bright orange", NEON, 1, true),
	Color3.fromRGB(255, 140, 30), 4, 40)
-- "BOILER HOUSE" sign
billboard(p("BHSign",Vector3.new(0.1,0.1,0.1),pos(BHX, GY+BHH+4, BHZ),"Bright orange",NEON,1,true),
	"BOILER HOUSE", Color3.fromRGB(255, 180, 60), UDim2.new(0,320,0,54), Vector3.new(0,0,0))

-- Steam pipes running along the ground (east-west perimeter)
for _, pi2 in {
	{-115, GY+3, CZ-20, 0},   -- west main pipe runs N-S
	{ 115, GY+3, CZ-20, 0},   -- east main pipe
	{0, GY+4, CZ-84,    math.rad(90)},  -- north cross pipe
	{0, GY+4, CZ+70,    math.rad(90)},  -- south cross pipe
} do
	cyl("Pipe", Vector3.new(3, 3, 230),
		pos(pi2[1], pi2[2], pi2[3]) * CFrame.Angles(0, pi2[4], math.rad(90)),
		COPPER, METAL)
end
-- Pipe elbow joints (brass spheres at intersections)
for _, jt in {{-115, GY+3, CZ-84},{-115, GY+3, CZ+70},{115, GY+3, CZ-84},{115, GY+3, CZ+70}} do
	sph("PipeJoint", 4, jt[1], jt[2], jt[3], BRASS, METAL, 0)
end
-- Steam vent nozzles along pipes
for _, vn in {{-115, CZ-40},{-115, CZ+20},{115, CZ-40},{115, CZ+20}} do
	p("Nozzle", Vector3.new(3, 6, 3),   pos(vn[1], GY+7, vn[2]), COPPER, METAL)
	p("NozzleCap",Vector3.new(4,0.8,4), pos(vn[1], GY+10.4, vn[2]), IRON, METAL)
	p("SteamVent",Vector3.new(2, 10, 2),pos(vn[1], GY+17, vn[2]), "Institutional white", NEON, 0.75, true)
end

-- ════════════════ ADVENTURE STEAM DOCK (west) ════════════════════════════════
-- Green neon, valve-gate aesthetic — leads to Playground
local ADX, ADZ = -72, CZ + 5
local ADW, ADD, ADH = 38, 36, 26
-- Brick walls
p("ADFloor", Vector3.new(ADW, 1, ADD),     pos(ADX, GY-0.5, ADZ), DSTONE, CONC)
p("ADWallN", Vector3.new(ADW, ADH, 1.5),   pos(ADX, GY+ADH/2, ADZ-ADD/2), BRICK_C, BRICK)
-- South wall with arched opening (20W × 20H)
local adOW, adOH = 20, 20
local adSW = (ADW - adOW) / 2
p("ADWallSL", Vector3.new(adSW, ADH, 1.5), pos(ADX-(adOW+adSW)/2, GY+ADH/2, ADZ+ADD/2), BRICK_C, BRICK)
p("ADWallSR", Vector3.new(adSW, ADH, 1.5), pos(ADX+(adOW+adSW)/2, GY+ADH/2, ADZ+ADD/2), BRICK_C, BRICK)
p("ADWallST", Vector3.new(adOW, ADH-adOH, 1.5), pos(ADX, GY+adOH+(ADH-adOH)/2, ADZ+ADD/2), BRICK_C, BRICK)
p("ADWallE",  Vector3.new(1.5, ADH, ADD+3), pos(ADX+ADW/2, GY+ADH/2, ADZ), BRICK_C, BRICK)
p("ADWallW",  Vector3.new(1.5, ADH, ADD+3), pos(ADX-ADW/2, GY+ADH/2, ADZ), BRICK_C, BRICK)
-- Green neon arch frame over south opening
p("ADArchL", Vector3.new(1.5, adOH, 1.5), pos(ADX-adOW/2, GY+adOH/2, ADZ+ADD/2), "Lime green", NEON, 0.06)
p("ADArchR", Vector3.new(1.5, adOH, 1.5), pos(ADX+adOW/2, GY+adOH/2, ADZ+ADD/2), "Lime green", NEON, 0.06)
p("ADArchT", Vector3.new(adOW+3, 1.5, 1.5), pos(ADX, GY+adOH, ADZ+ADD/2), "Lime green", NEON, 0.06)
-- Green window glow on east/west
p("ADWinE", Vector3.new(0.4, ADH*0.5, ADD*0.55), pos(ADX+ADW/2, GY+ADH*0.3, ADZ), "Lime green", NEON, 0.72, true)
p("ADWinW", Vector3.new(0.4, ADH*0.5, ADD*0.55), pos(ADX-ADW/2, GY+ADH*0.3, ADZ), "Lime green", NEON, 0.72, true)
-- Iron roof + chimney
p("ADRoof",  Vector3.new(ADW+2, 1.5, ADD+2), pos(ADX, GY+ADH+0.75, ADZ), IRON, DP)
p("ADChimney",Vector3.new(4, 20, 4),          pos(ADX-10, GY+ADH+10, ADZ-10), DSTONE, BRICK)
p("ADChimRim",Vector3.new(5, 1.2, 5),         pos(ADX-10, GY+ADH+21, ADZ-10), IRON, METAL)
p("ADSteam",  Vector3.new(3, 14, 3),           pos(ADX-10, GY+ADH+29, ADZ-10), "Lime green", NEON, 0.6, true)
glow(p("ADSteamGl",Vector3.new(0.1,0.1,0.1),pos(ADX-10,GY+ADH+22,ADZ-10),"Lime green",NEON,1,true),
	Color3.fromRGB(80,255,130), 3, 35)
-- Gear decoration on east face
gear(ADX + ADW/2 + 1.2, GY + 12, ADZ, 7, 2.2, IRON, 8, 0)
-- Roof neon trim (green)
p("ADRTrimN", Vector3.new(ADW+6, 0.3, 0.3), pos(ADX, GY+ADH+1.6, ADZ-ADD/2-1), "Lime green", NEON, 0.12, true)
p("ADRTrimS", Vector3.new(ADW+6, 0.3, 0.3), pos(ADX, GY+ADH+1.6, ADZ+ADD/2+1), "Lime green", NEON, 0.12, true)
local adGl = p("ADGl",Vector3.new(0.1,0.1,0.1),pos(ADX, GY+ADH+5, ADZ),"Lime green",NEON,1,true)
glow(adGl, Color3.fromRGB(80,255,130), 4, 50)
billboard(adGl, "STEAM DOCK  ·  ADVENTURE",
	Color3.fromRGB(80, 255, 130), UDim2.new(0,400,0,60), Vector3.new(0,0,0))

-- Interior: giant valve/steam portal (the departure pad)
local advDisc = cyl("AdvPortalDisc", Vector3.new(1.8, 22, 22),
	pos(ADX, GY+3.5, ADZ-10) * CFrame.Angles(0,0,math.rad(90)), "Lime green", NEON, 0.14, true)
cyl("AdvRing1", Vector3.new(0.9, 18, 18),
	pos(ADX, GY+3.4, ADZ-10) * CFrame.Angles(0,0,math.rad(90)), "Lime green", NEON, 0.42, true)
p("AdvPad", Vector3.new(18, 0.5, 18), pos(ADX, GY+0.75, ADZ-10), "Lime green", NEON, 0.45, true)
glow(advDisc, Color3.fromRGB(80,255,130), 5, 42)
-- Gate frame (iron with green neon cap)
p("AdvGL",  Vector3.new(2.5, 22, 2.5), pos(ADX-9,  GY+11, ADZ-10), IRON, METAL)
p("AdvGR",  Vector3.new(2.5, 22, 2.5), pos(ADX+9,  GY+11, ADZ-10), IRON, METAL)
p("AdvGTop",Vector3.new(21, 2.5, 2.5), pos(ADX,    GY+23, ADZ-10), IRON, METAL)
p("AdvGNeon",Vector3.new(23, 0.4, 0.4),pos(ADX,    GY+24.4,ADZ-10),"Lime green",NEON,0.08,true)
-- Vertical steam beam above portal
p("AdvBeam", Vector3.new(1.5, 80, 1.5), pos(ADX, GY+ADH+40, ADZ-10), "Lime green", NEON, 0.6, true)
billboard(advDisc, "STEAM DOCK\n[ E ]  Depart to Adventure",
	Color3.fromRGB(80,255,130), UDim2.new(0,320,0,80), Vector3.new(0,16,0))
addPrompt(advDisc, "Board", "Steam Dock · Adventure", function(player)
	exitLanding(player, PLAYGROUND_CF)
end)
-- Lamp posts flanking dock entrance
lampPost(ADX - 22, GY, ADZ + ADD/2 + 3)
lampPost(ADX + 22, GY, ADZ + ADD/2 + 3)

-- ════════════════ CLOCKWORK TIME GATE (east) ══════════════════════════════════
-- Brass/gold gear-frame portal — leads to Time Machines
local TMX, TMZ = 72, CZ + 5
local TMW, TMD, TMH = 38, 36, 26
-- Brick walls (darker brick, aged)
p("TMFloor", Vector3.new(TMW, 1, TMD),   pos(TMX, GY-0.5, TMZ), DSTONE, CONC)
p("TMWallN", Vector3.new(TMW, TMH, 1.5), pos(TMX, GY+TMH/2, TMZ-TMD/2), DSTONE, BRICK)
local tmOW, tmOH = 20, 20
local tmSW = (TMW - tmOW) / 2
p("TMWallSL", Vector3.new(tmSW, TMH, 1.5), pos(TMX-(tmOW+tmSW)/2, GY+TMH/2, TMZ+TMD/2), DSTONE, BRICK)
p("TMWallSR", Vector3.new(tmSW, TMH, 1.5), pos(TMX+(tmOW+tmSW)/2, GY+TMH/2, TMZ+TMD/2), DSTONE, BRICK)
p("TMWallST", Vector3.new(tmOW, TMH-tmOH, 1.5), pos(TMX, GY+tmOH+(TMH-tmOH)/2, TMZ+TMD/2), DSTONE, BRICK)
p("TMWallE",  Vector3.new(1.5, TMH, TMD+3), pos(TMX+TMW/2, GY+TMH/2, TMZ), DSTONE, BRICK)
p("TMWallW",  Vector3.new(1.5, TMH, TMD+3), pos(TMX-TMW/2, GY+TMH/2, TMZ), DSTONE, BRICK)
-- Brass/gold arch frame over south opening
p("TMArchL", Vector3.new(1.5, tmOH, 1.5), pos(TMX-tmOW/2, GY+tmOH/2, TMZ+TMD/2), BRASS, NEON, 0.06)
p("TMArchR", Vector3.new(1.5, tmOH, 1.5), pos(TMX+tmOW/2, GY+tmOH/2, TMZ+TMD/2), BRASS, NEON, 0.06)
p("TMArchT", Vector3.new(tmOW+3, 1.5, 1.5), pos(TMX, GY+tmOH, TMZ+TMD/2), BRASS, NEON, 0.06)
-- Gold window glow
p("TMWinE", Vector3.new(0.4, TMH*0.5, TMD*0.55), pos(TMX+TMW/2, GY+TMH*0.3, TMZ), BRASS, NEON, 0.72, true)
p("TMWinW", Vector3.new(0.4, TMH*0.5, TMD*0.55), pos(TMX-TMW/2, GY+TMH*0.3, TMZ), BRASS, NEON, 0.72, true)
-- Iron roof
p("TMRoof",  Vector3.new(TMW+2, 1.5, TMD+2), pos(TMX, GY+TMH+0.75, TMZ), IRON, DP)
-- Large decorative gears flanking the building exterior
gear(TMX - TMW/2 - 1.2, GY + 10, TMZ,      9, 2.5, BRASS, 10, 0)
gear(TMX + TMW/2 + 1.2, GY + 14, TMZ,     11, 2.8, IRON,  12, math.rad(15))
gear(TMX,               GY + 22, TMZ-TMD/2-1, 7, 2.2, COPPER, 8, math.rad(7))
-- Roof neon trim (brass/gold)
p("TMRTrimN", Vector3.new(TMW+6, 0.3, 0.3), pos(TMX, GY+TMH+1.6, TMZ-TMD/2-1), BRASS, NEON, 0.1, true)
p("TMRTrimS", Vector3.new(TMW+6, 0.3, 0.3), pos(TMX, GY+TMH+1.6, TMZ+TMD/2+1), BRASS, NEON, 0.1, true)
local tmGl = p("TMGl",Vector3.new(0.1,0.1,0.1),pos(TMX, GY+TMH+5, TMZ), BRASS, NEON, 1, true)
glow(tmGl, Color3.fromRGB(255,210,60), 4, 50)
billboard(tmGl, "CLOCKWORK GATE  ·  TIME TRAVEL",
	Color3.fromRGB(255,210,60), UDim2.new(0,420,0,60), Vector3.new(0,0,0))

-- Interior: clockwork portal disc
local tmDisc = cyl("TMPortalDisc", Vector3.new(1.8, 22, 22),
	pos(TMX, GY+3.5, TMZ-10) * CFrame.Angles(0,0,math.rad(90)), BRASS, NEON, 0.14, true)
cyl("TMRing1", Vector3.new(0.9, 18, 18),
	pos(TMX, GY+3.4, TMZ-10) * CFrame.Angles(0,0,math.rad(90)), BRASS, NEON, 0.42, true)
p("TMPad", Vector3.new(18, 0.5, 18), pos(TMX, GY+0.75, TMZ-10), BRASS, NEON, 0.45, true)
glow(tmDisc, Color3.fromRGB(255,210,60), 5, 42)
-- Three concentric gear rings around portal
for gi, gr in {14, 10, 6} do
	cyl("TMGearRing"..gi, Vector3.new(gi * 0.3, gr * 2, gr * 2),
		pos(TMX, GY+gi*0.2, TMZ-10) * CFrame.Angles(0,0,math.rad(90)), IRON, METAL, 0.3, true)
end
-- Gate frame
p("TMGL",   Vector3.new(2.5, 22, 2.5), pos(TMX-9,  GY+11, TMZ-10), DSTONE, CONC)
p("TMGR",   Vector3.new(2.5, 22, 2.5), pos(TMX+9,  GY+11, TMZ-10), DSTONE, CONC)
p("TMGTop", Vector3.new(21, 2.5, 2.5), pos(TMX,    GY+23, TMZ-10), DSTONE, CONC)
p("TMGNeon",Vector3.new(23, 0.4, 0.4), pos(TMX, GY+24.4, TMZ-10), BRASS, NEON, 0.08, true)
p("TMBeam", Vector3.new(1.5, 80, 1.5), pos(TMX, GY+TMH+40, TMZ-10), BRASS, NEON, 0.6, true)
billboard(tmDisc, "CLOCKWORK GATE\n[ E ]  Travel Through Time",
	Color3.fromRGB(255,210,60), UDim2.new(0,340,0,80), Vector3.new(0,16,0))
addPrompt(tmDisc, "Board", "Clockwork Gate · Time Machines", function(player)
	exitLanding(player, TIME_MACHINE_CF)
end)
-- Lamp posts flanking gate entrance
lampPost(TMX - 22, GY, TMZ + TMD/2 + 3)
lampPost(TMX + 22, GY, TMZ + TMD/2 + 3)

-- The visible starter room now uses SpinWheel buttons in this footprint.
-- Remove the old Clockwork Time Gate building so those buttons are not hidden.
local removeTimeGatePart = {
	TMFloor = true, TMWallN = true, TMWallSL = true, TMWallSR = true, TMWallST = true,
	TMWallE = true, TMWallW = true, TMArchL = true, TMArchR = true, TMArchT = true,
	TMWinE = true, TMWinW = true, TMRoof = true, TMRTrimN = true, TMRTrimS = true,
	TMGl = true, TMPortalDisc = true, TMRing1 = true, TMPad = true,
	TMGL = true, TMGR = true, TMGTop = true, TMGNeon = true, TMBeam = true,
}
for _, obj in folder:GetChildren() do
	local isTimeGateGear = obj:IsA("BasePart")
		and obj.Position.X > 45 and obj.Position.X < 98
		and obj.Position.Z > TMZ - 28 and obj.Position.Z < TMZ + 28
		and obj.Name:match("^Gear")
	if removeTimeGatePart[obj.Name] or obj.Name:match("^TMGearRing") or isTimeGateGear then
		obj:Destroy()
	end
end

-- ════════════════ IRON CROSS-BRIDGES (connecting buildings) ══════════════════
-- Overhead walkway from tower to steam dock (iron beam + plank deck)
p("BridgeWA_Deck", Vector3.new(28, 0.8, 4),
	pos((TX+ADX)/2, BY+18, (TZ+ADZ)/2 - (math.abs(TZ-ADZ)/2)*0.0), WD)
-- (The bridge is angled; use two beams)
ibeam(TX-9,  BY+18, TZ, ADX+ADW/2, ADZ, 1.5)
ibeam(TX+9,  BY+18, TZ, ADX+ADW/2, ADZ+4, 1.5)
-- Bridge from tower to clockwork gate
ibeam(TX+9,  BY+18, TZ, TMX-TMW/2, TMZ, 1.5)
ibeam(TX-9,  BY+18, TZ, TMX-TMW/2, TMZ+4, 1.5)

-- ════════════════ GIANT STANDALONE GEARS (island decor) ══════════════════════
gear(-95, GY + 14, CZ - 30, 13, 3,   IRON,  14, 0)
gear( 95, GY + 18, CZ - 30, 16, 3.5, BRASS, 16, math.rad(11))
gear(-90, GY + 10, CZ + 55, 10, 2.8, COPPER, 11, math.rad(5))
gear( 88, GY + 12, CZ + 55, 12, 3.2, IRON,  13, math.rad(20))

-- ════════════════ HOT AIR BALLOON (tethered above island) ════════════════════
local balX, balY, balZ = 45, BY + 70, CZ - 45
-- Balloon envelope (large sphere, striped with alternating parts)
sph("BalloonMain", 22, balX, balY, balZ, BRICK_C, SMP, 0)
sph("BalloonStripe1",17, balX, balY, balZ, BRASS, SMP, 0)
sph("BalloonStripe2",12, balX, balY, balZ, "Bright red", SMP, 0)
sph("BalloonInner",   7, balX, balY, balZ, BRASS, NEON, 0.3)
glow(p("BalloonGl",Vector3.new(0.1,0.1,0.1),pos(balX,balY,balZ),"Bright yellow",NEON,1,true),
	Color3.fromRGB(255,200,60), 3, 48)
-- Skirt / apron at bottom of balloon
cyl("BalloonSkirt", Vector3.new(4, 18, 18),
	pos(balX, balY-18, balZ) * CFrame.Angles(0,0,math.rad(90)), DSTONE, METAL, 0.1, true)
-- Basket
p("BaskBase",  Vector3.new(8, 3, 8),  pos(balX, balY-30, balZ), COPPER, WD)
p("BaskSideN", Vector3.new(8, 5, 1),  pos(balX, balY-27.5, balZ-3.5), COPPER, WD)
p("BaskSideS", Vector3.new(8, 5, 1),  pos(balX, balY-27.5, balZ+3.5), COPPER, WD)
p("BaskSideE", Vector3.new(1, 5, 8),  pos(balX+3.5, balY-27.5, balZ), COPPER, WD)
p("BaskSideW", Vector3.new(1, 5, 8),  pos(balX-3.5, balY-27.5, balZ), COPPER, WD)
-- Rope strands (4 thin parts connecting basket to balloon base)
for _, rp in {{-3,-3},{3,-3},{-3,3},{3,3}} do
	ibeam(balX+rp[1], balY-24, balZ+rp[2], balX+rp[1]*0.4, balZ+rp[2]*0.4, 0.6)
end
-- Tether rope from basket down to island
p("BalloonTether", Vector3.new(0.6, 34, 0.6),
	pos(balX, BY + 17, balZ), COPPER, METAL)
-- Billboard label on balloon
billboard(p("BalloonSign",Vector3.new(0.1,0.1,0.1),pos(balX, balY+26, balZ),"Bright yellow",NEON,1,true),
	"⚙ CLOCKWORK KEEP", Color3.fromRGB(255,210,60), UDim2.new(0,260,0,52), Vector3.new(0,0,0))

-- ════════════════ DARK STORM CLOUD SEA ═══════════════════════════════════════
math.randomseed(55321)
local stormPalette = {
	"Dark stone grey", "Medium stone grey", "Smoky grey",
	"Black", "Dark stone grey",
}
for xi = -140, 140, 18 do
	for zi = CZ - 100, CZ + 100, 18 do
		sph("Cloud", math.random(18, 32),
			xi + math.random(-7,7), BY - 22 - math.random(0, 18),
			zi + math.random(-7,7), stormPalette[math.random(#stormPalette)], SMP, math.random(22, 48) * 0.01)
	end
end
-- Outer wispy dark clouds
for xi = -200, 200, 26 do
	sph("CldW", math.random(14, 26), xi + math.random(-10,10), BY-30-math.random(0,20),
		CZ-148-math.random(0,28), stormPalette[math.random(#stormPalette)], SMP, math.random(25,45)*0.01)
	sph("CldW", math.random(14, 26), xi + math.random(-10,10), BY-30-math.random(0,20),
		CZ+148+math.random(0,28), stormPalette[math.random(#stormPalette)], SMP, math.random(25,45)*0.01)
end

-- ════════════════ RETURN PORTAL ═══════════════════════════════════════════════
local ret = cyl("LandingReturnPortal", Vector3.new(0.5, 26, 26),
	pos(0, 5, -418) * CFrame.Angles(0, 0, math.rad(90)),
	BRASS, NEON, 0.18, false)
billboard(ret, "CLOCKWORK KEEP",
	Color3.fromRGB(255, 210, 60), UDim2.new(0, 220, 0, 58), Vector3.new(0, 8, 0))
glow(ret, Color3.fromRGB(255, 210, 60), 3, 36)
addPrompt(ret, "Return", "The Clockwork Keep", function(player)
	player:SetAttribute("InLandingWorld", true)
	playerStartTimes[player] = os.clock()
	fireEvent(player, "Start")
	setPlayerCF(player, START_CF)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  PLAYER HANDLING
-- ════════════════════════════════════════════════════════════════════════════
local function sendToLanding(player, character)
	player:SetAttribute("InLandingWorld", true)
	playerStartTimes[player] = os.clock()
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	-- Teleport immediately so the player never sees the default SpawnLocation.
	-- Re-apply for a few frames to override physics settling.
	for _ = 1, 4 do
		if not player.Parent then return end
		if not player:GetAttribute("InLandingWorld") then return end
		hrp.CFrame = START_CF
		hrp.AssemblyLinearVelocity = Vector3.zero
		task.wait()
	end
	if player:GetAttribute("InLandingWorld") then
		fireEvent(player, "Start")
	end
end

local function connectPlayer(player)
	player.CharacterAdded:Connect(function(character)
		player:SetAttribute("InLandingWorld", true)
		task.spawn(sendToLanding, player, character)
	end)
	-- Handle character already loaded (hot-join or script reload)
	if player.Character then
		player:SetAttribute("InLandingWorld", true)
		task.spawn(sendToLanding, player, player.Character)
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("InLandingWorld", true)
	connectPlayer(player)
end)

for _, player in Players:GetPlayers() do
	player:SetAttribute("InLandingWorld", true)
	connectPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	playerStartTimes[player] = nil
end)

-- When EmptyWorld1 stage is cleared, pull all players back to the Clockwork Keep
task.spawn(function()
	local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end
	local sig = gameEvents:WaitForChild("SendAllToLandingSignal", 60)
	if not sig then return end
	sig.Event:Connect(function()
		for _, player in Players:GetPlayers() do
			local char = player.Character
			if not char then continue end
			player:SetAttribute("InLandingWorld", true)
			playerStartTimes[player] = os.clock()
			task.spawn(sendToLanding, player, char)
		end
	end)
end)

print("[LandingWorld] The Clockwork Keep ready.")
