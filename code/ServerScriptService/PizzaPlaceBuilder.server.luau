-- PizzaPlaceBuilder.server.luau
-- Massive pizza palace — very high walls, octagonal shape with corner towers,
-- dramatic entrance arch, warm red/orange/yellow theme.
-- Zone: z=130→270, x=-62→62. Playable inside and out.

local G    = 1     -- ground Y
local SMP  = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local BRIK = Enum.Material.Brick
local WOOD = Enum.Material.Wood
local TILE = Enum.Material.SmoothPlastic

local folder = Instance.new("Folder")
folder.Name   = "PizzaPlace"
folder.Parent = workspace

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function p(sz, pos, col, mat, trans)
	local pt = Instance.new("Part")
	pt.Size          = sz
	pt.Position      = pos
	pt.BrickColor    = BrickColor.new(col)
	pt.Material      = mat or SMP
	pt.Anchored      = true
	pt.CanCollide    = true
	pt.CastShadow    = false
	pt.TopSurface    = Enum.SurfaceType.Smooth
	pt.BottomSurface = Enum.SurfaceType.Smooth
	pt.Transparency  = trans or 0
	pt.Parent        = folder
	return pt
end

local function pcf(sz, cf, col, mat, trans)
	local pt = Instance.new("Part")
	pt.Size          = sz
	pt.CFrame        = cf
	pt.BrickColor    = BrickColor.new(col)
	pt.Material      = mat or SMP
	pt.Anchored      = true
	pt.CanCollide    = true
	pt.CastShadow    = false
	pt.TopSurface    = Enum.SurfaceType.Smooth
	pt.BottomSurface = Enum.SurfaceType.Smooth
	pt.Transparency  = trans or 0
	pt.Parent        = folder
	return pt
end

local function wcf(sz, cf, col, mat)
	local w = Instance.new("WedgePart")
	w.Size = sz; w.CFrame = cf
	w.BrickColor = BrickColor.new(col); w.Material = mat or SMP
	w.Anchored = true; w.CastShadow = false; w.Parent = folder
	return w
end

local function neon(sz, pos, col, trans)
	return p(sz, pos, col, NEON, trans or 0.15)
end

-- ── Constants ────────────────────────────────────────────────────────────────
local CX,  CZ  = 0,   200   -- building center
local BW,  BD  = 88,  88    -- outer wall footprint (square, chamfered into octagon)
local WH       = 50          -- main wall height  ← VERY TALL
local TH       = 72          -- corner tower height
local TW       = 14          -- corner tower width
local WALL_T   = 2.5         -- wall thickness

-- Connector bridge from the playground exit to the big pizza level.
local BRIDGE_Z1, BRIDGE_Z2 = 59, 130
local BRIDGE_ZC = (BRIDGE_Z1 + BRIDGE_Z2) / 2
local BRIDGE_LEN = BRIDGE_Z2 - BRIDGE_Z1

p(Vector3.new(20, 0.7, BRIDGE_LEN), Vector3.new(0, G + 0.35, BRIDGE_ZC), "Dark stone grey", Enum.Material.DiamondPlate)
p(Vector3.new(15.5, 0.18, BRIDGE_LEN - 6), Vector3.new(0, G + 0.82, BRIDGE_ZC), "Bright orange", SMP, 0.08)

for bz = BRIDGE_Z1 + 5, BRIDGE_Z2 - 5, 7 do
	local stripeColor = math.floor((bz - BRIDGE_Z1) / 7) % 2 == 0 and "Really red" or "New Yeller"
	p(Vector3.new(14.5, 0.16, 1.2), Vector3.new(0, G + 0.95, bz), stripeColor, NEON, 0.22)
	p(Vector3.new(2.2, 0.18, 1.2), Vector3.new(-6.1, G + 1.03, bz), "White", SMP, 0.12)
	p(Vector3.new(2.2, 0.18, 1.2), Vector3.new(6.1, G + 1.03, bz), "White", SMP, 0.12)
end

for _, x in { -10.4, 10.4 } do
	p(Vector3.new(0.55, 0.55, BRIDGE_LEN), Vector3.new(x, G + 3.7, BRIDGE_ZC), "Bright orange", NEON, 0.12)
	p(Vector3.new(0.45, 0.45, BRIDGE_LEN), Vector3.new(x, G + 2.15, BRIDGE_ZC), "Really red", NEON, 0.18)
	for bz = BRIDGE_Z1 + 4, BRIDGE_Z2 - 4, 9 do
		p(Vector3.new(0.75, 4.0, 0.75), Vector3.new(x, G + 2.0, bz), "Really black", SMP)
		p(Vector3.new(1.35, 1.35, 1.35), Vector3.new(x, G + 4.35, bz), "New Yeller", NEON, 0.15).Shape = Enum.PartType.Ball
	end
end

-- Landing pads on both door sides make the connector feel intentional.
for _, z in { BRIDGE_Z1, BRIDGE_Z2 } do
	p(Vector3.new(24, 0.55, 7), Vector3.new(0, G + 0.42, z), "Really red", BRIK)
	p(Vector3.new(16, 0.18, 3.4), Vector3.new(0, G + 0.85, z), "New Yeller", NEON, 0.25)
end

-- ── Ground floor ─────────────────────────────────────────────────────────────
-- Extra pizza yard space with transparent boundary walls around the full stage.
local PIZZA_X1, PIZZA_X2 = -72, 72
local PIZZA_Z1, PIZZA_Z2 = 132, 268
local PIZZA_XC, PIZZA_ZC = (PIZZA_X1 + PIZZA_X2) / 2, (PIZZA_Z1 + PIZZA_Z2) / 2
local PIZZA_W, PIZZA_D = PIZZA_X2 - PIZZA_X1, PIZZA_Z2 - PIZZA_Z1

p(Vector3.new(PIZZA_W, 0.45, PIZZA_D), Vector3.new(PIZZA_XC, G + 0.22, PIZZA_ZC), "Dark stone grey", Enum.Material.DiamondPlate)
p(Vector3.new(PIZZA_W - 18, 0.12, 20), Vector3.new(PIZZA_XC, G + 0.56, PIZZA_Z1 + 15), "Bright orange", NEON, 0.7)
p(Vector3.new(PIZZA_W - 18, 0.12, 20), Vector3.new(PIZZA_XC, G + 0.56, PIZZA_Z2 - 15), "New Yeller", NEON, 0.72)

local function glassWall(size, pos)
	local wall = p(size, pos, "Cyan", Enum.Material.Glass, 0.62)
	wall.CanCollide = true
	return wall
end

local wallH = 28
local wallY = G + wallH / 2
glassWall(Vector3.new(1, wallH, PIZZA_D), Vector3.new(PIZZA_X1, wallY, PIZZA_ZC))
glassWall(Vector3.new(1, wallH, PIZZA_D), Vector3.new(PIZZA_X2, wallY, PIZZA_ZC))
glassWall(Vector3.new(56, wallH, 1), Vector3.new(-44, wallY, PIZZA_Z1))
glassWall(Vector3.new(56, wallH, 1), Vector3.new(44, wallY, PIZZA_Z1))
glassWall(Vector3.new(56, wallH, 1), Vector3.new(-44, wallY, PIZZA_Z2))
glassWall(Vector3.new(56, wallH, 1), Vector3.new(44, wallY, PIZZA_Z2))
for _, z in { PIZZA_Z1, PIZZA_Z2 } do
	p(Vector3.new(18, 0.22, 3), Vector3.new(0, G + 0.66, z), "Bright orange", NEON, 0.32)
end

p(Vector3.new(BW+10, 0.8, BD+10), Vector3.new(CX, G+0.4, CZ), "Bright red", BRIK)
-- Tile interior
for tx = -4, 4 do
	for tz = -4, 4 do
		local col = (tx+tz) % 2 == 0 and "White" or "Bright red"
		p(Vector3.new(9.5, 0.4, 9.5), Vector3.new(CX+tx*10, G+0.7, CZ+tz*10), col, SMP)
	end
end

-- ── Octagonal walls (square + 45° chamfered corners) ─────────────────────────
local HW = BW/2   -- half-width  = 44
local HD = BD/2   -- half-depth  = 44
local CUT = 16    -- corner cut size

-- North wall (two segments either side of entrance gap)
p(Vector3.new(HW-CUT-12, WH, WALL_T), Vector3.new(CX-(HW-CUT)/2-6, G+WH/2, CZ-HD), "Bright red", BRIK)
p(Vector3.new(HW-CUT-12, WH, WALL_T), Vector3.new(CX+(HW-CUT)/2+6, G+WH/2, CZ-HD), "Bright red", BRIK)
-- South wall
p(Vector3.new(BW-CUT*2, WH, WALL_T), Vector3.new(CX, G+WH/2, CZ+HD), "Bright red", BRIK)
-- East wall
p(Vector3.new(WALL_T, WH, BD-CUT*2), Vector3.new(CX+HW, G+WH/2, CZ), "Bright red", BRIK)
-- West wall
p(Vector3.new(WALL_T, WH, BD-CUT*2), Vector3.new(CX-HW, G+WH/2, CZ), "Bright red", BRIK)

-- Chamfered corners (45° panels) — octagon cuts
local sqrt2 = math.sqrt(2)
local diagLen = CUT * sqrt2 + 2
local diagH   = WH
local function chamferWall(cx, cz, rotY)
	pcf(Vector3.new(WALL_T, diagH, diagLen),
		CFrame.new(cx, G+diagH/2, cz) * CFrame.Angles(0, rotY, 0),
		"Bright red", BRIK)
end
chamferWall(CX-HW+CUT/2, CZ-HD+CUT/2, math.rad( 45))
chamferWall(CX+HW-CUT/2, CZ-HD+CUT/2, math.rad(-45))
chamferWall(CX-HW+CUT/2, CZ+HD-CUT/2, math.rad(-45))
chamferWall(CX+HW-CUT/2, CZ+HD-CUT/2, math.rad( 45))

-- ── Corner towers ────────────────────────────────────────────────────────────
local towerCenters = {
	{CX-HW+TW/2-1, CZ-HD+TW/2-1},
	{CX+HW-TW/2+1, CZ-HD+TW/2-1},
	{CX-HW+TW/2-1, CZ+HD-TW/2+1},
	{CX+HW-TW/2+1, CZ+HD-TW/2+1},
}
for _, tc in towerCenters do
	local tx, tz = tc[1], tc[2]
	-- Tower body
	p(Vector3.new(TW, TH, TW), Vector3.new(tx, G+TH/2, tz), "Bright red", BRIK)
	-- Tower cap (pyramid-style using wedges stacked)
	p(Vector3.new(TW+2, 1, TW+2), Vector3.new(tx, G+TH+0.5, tz), "Bright orange", SMP)
	-- Tower top cone layers
	for tier = 0, 4 do
		local ts = (TW - tier*2.5)
		if ts > 1 then
			p(Vector3.new(ts, 2.5, ts), Vector3.new(tx, G+TH+2+tier*2.2, tz), "Really red", SMP)
		end
	end
	-- Tower tip finial
	p(Vector3.new(1.5, 4, 1.5), Vector3.new(tx, G+TH+15, tz), "Bright orange", NEON)
	-- Neon window strips on tower
	for wh = 8, TH-4, 10 do
		local wn = p(Vector3.new(TW+0.2, 3, 0.3), Vector3.new(tx, G+wh, tz-TW/2), "Bright orange", NEON, 0.3)
		p(Vector3.new(TW+0.2, 3, 0.3), Vector3.new(tx, G+wh, tz+TW/2), "Bright orange", NEON, 0.3)
		p(Vector3.new(0.3, 3, TW+0.2), Vector3.new(tx+TW/2, G+wh, tz), "Bright orange", NEON, 0.3)
		p(Vector3.new(0.3, 3, TW+0.2), Vector3.new(tx-TW/2, G+wh, tz), "Bright orange", NEON, 0.3)
	end
end

-- ── Wall decoration — horizontal neon bands ──────────────────────────────────
for wh = 6, WH-2, 8 do
	local col = wh % 16 == 6 and "Bright orange" or "New Yeller"
	-- North strips
	p(Vector3.new(BW+0.3, 0.6, 0.3), Vector3.new(CX, G+wh, CZ-HD), col, NEON, 0.25)
	-- South
	p(Vector3.new(BW-CUT*2+0.3, 0.6, 0.3), Vector3.new(CX, G+wh, CZ+HD), col, NEON, 0.25)
	-- East
	p(Vector3.new(0.3, 0.6, BD-CUT*2+0.3), Vector3.new(CX+HW, G+wh, CZ), col, NEON, 0.25)
	-- West
	p(Vector3.new(0.3, 0.6, BD-CUT*2+0.3), Vector3.new(CX-HW, G+wh, CZ), col, NEON, 0.25)
end

-- ── Wall windows (large arched openings on E/W) ──────────────────────────────
for wz = -15, 15, 15 do
	-- East windows
	local ew = p(Vector3.new(0.5, 18, 10), Vector3.new(CX+HW, G+14, CZ+wz), "Cyan", Enum.Material.Glass, 0.4)
	-- West windows
	local ww = p(Vector3.new(0.5, 18, 10), Vector3.new(CX-HW, G+14, CZ+wz), "Cyan", Enum.Material.Glass, 0.4)
end
-- South windows
for wx = -28, 28, 18 do
	p(Vector3.new(10, 18, 0.5), Vector3.new(CX+wx, G+14, CZ+HD), "Cyan", Enum.Material.Glass, 0.4)
end

-- ── Roof ─────────────────────────────────────────────────────────────────────
p(Vector3.new(BW+2, 1.5, BD+2), Vector3.new(CX, G+WH+0.75, CZ), "Really red", SMP)
-- Roof neon border
p(Vector3.new(BW+4, 0.5, 0.4), Vector3.new(CX, G+WH+2, CZ-HD), "New Yeller", NEON, 0.1)
p(Vector3.new(BW+4, 0.5, 0.4), Vector3.new(CX, G+WH+2, CZ+HD), "New Yeller", NEON, 0.1)
p(Vector3.new(0.4, 0.5, BD+4), Vector3.new(CX+HW, G+WH+2, CZ), "New Yeller", NEON, 0.1)
p(Vector3.new(0.4, 0.5, BD+4), Vector3.new(CX-HW, G+WH+2, CZ), "New Yeller", NEON, 0.1)

-- Rooftop pizza sign (giant letters via neon parts)
local signBase = p(Vector3.new(48, 6, 1.5), Vector3.new(CX, G+WH+5, CZ-HD+2), "Really black", SMP)
local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Front
sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
sg.PixelsPerStud = 30
sg.Parent = signBase
local sl = Instance.new("TextLabel")
sl.Size = UDim2.new(1,0,1,0); sl.BackgroundTransparency=1
sl.Text = "🍕 PIZZA PLACE 🍕"; sl.Font = Enum.Font.GothamBlack
sl.TextScaled = true; sl.TextColor3 = Color3.fromRGB(255,220,40)
sl.TextStrokeTransparency = 0; sl.TextStrokeColor3 = Color3.fromRGB(180,0,0)
sl.Parent = sg

-- ── Grand entrance arch (north face, gap between the two wall segments) ───────
local ARCH_CX = CX
local ARCH_Z  = CZ - HD
local ARCH_W  = 22    -- opening width
local ARCH_H  = 30    -- arch top height

-- Arch pillars
p(Vector3.new(4, ARCH_H, WALL_T+1), Vector3.new(ARCH_CX-ARCH_W/2-2, G+ARCH_H/2, ARCH_Z), "Bright orange", BRIK)
p(Vector3.new(4, ARCH_H, WALL_T+1), Vector3.new(ARCH_CX+ARCH_W/2+2, G+ARCH_H/2, ARCH_Z), "Bright orange", BRIK)
-- Arch crossbeam
p(Vector3.new(ARCH_W+8, 4, WALL_T+1), Vector3.new(ARCH_CX, G+ARCH_H, ARCH_Z), "Really red", BRIK)
-- Arch neon glow
p(Vector3.new(ARCH_W+8, 1, 0.4), Vector3.new(ARCH_CX, G+ARCH_H+2.5, ARCH_Z), "New Yeller", NEON, 0.1)
p(Vector3.new(0.4, ARCH_H, 0.4), Vector3.new(ARCH_CX-ARCH_W/2-2, G+ARCH_H/2, ARCH_Z), "Bright orange", NEON, 0.2)
p(Vector3.new(0.4, ARCH_H, 0.4), Vector3.new(ARCH_CX+ARCH_W/2+2, G+ARCH_H/2, ARCH_Z), "Bright orange", NEON, 0.2)
-- Entrance sign above arch
local archSign = p(Vector3.new(ARCH_W+4, 5, 1), Vector3.new(ARCH_CX, G+ARCH_H+5, ARCH_Z), "Really black", SMP)
local asg = Instance.new("SurfaceGui")
asg.Face = Enum.NormalId.Front; asg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
asg.PixelsPerStud = 40; asg.Parent = archSign
local al = Instance.new("TextLabel")
al.Size = UDim2.new(1,0,1,0); al.BackgroundTransparency=1
al.Text = "PIZZA PLACE"; al.Font = Enum.Font.GothamBlack
al.TextScaled = true; al.TextColor3 = Color3.fromRGB(255,220,40)
al.TextStrokeTransparency = 0; al.TextStrokeColor3 = Color3.fromRGB(0,0,0); al.Parent = asg

-- ── Tall entrance flagpoles ───────────────────────────────────────────────────
for _, fx in {ARCH_CX-18, ARCH_CX+18} do
	p(Vector3.new(1, 55, 1), Vector3.new(fx, G+27, ARCH_Z-2), "Institutional white", SMP)
	p(Vector3.new(8, 5, 0.3), Vector3.new(fx+4, G+50, ARCH_Z-2), "Really red", SMP)
	p(Vector3.new(0.4, 55, 0.4), Vector3.new(fx, G+27, ARCH_Z-2), "Bright orange", NEON, 0.3)
end

-- ── Inside: pizza oven (big, dramatic) ────────────────────────────────────────
local OX, OZ = CX+32, CZ+28
p(Vector3.new(14, 12, 11), Vector3.new(OX, G+6, OZ), "Dark stone grey", SMP)
p(Vector3.new(14, 14, 0.5), Vector3.new(OX, G+7, OZ-5.5), "Dark stone grey", SMP)
-- Oven opening
p(Vector3.new(6, 6, 0.6), Vector3.new(OX, G+4, OZ-5.5), "Really black", SMP)
local ovenGlow = p(Vector3.new(5.5, 5.5, 0.5), Vector3.new(OX, G+4, OZ-5.4), "Bright orange", NEON, 0.1)
-- Oven chimney
p(Vector3.new(3, 30, 3), Vector3.new(OX, G+22, OZ), "Dark stone grey", SMP)
p(Vector3.new(4, 2, 4), Vector3.new(OX, G+38, OZ), "Really black", SMP)
p(Vector3.new(3.5, 0.5, 3.5), Vector3.new(OX, G+39.5, OZ), "Bright orange", NEON, 0.15)

-- ── Inside: serving counter ───────────────────────────────────────────────────
p(Vector3.new(40, 4, 4), Vector3.new(CX-5, G+2, CZ+28), "Bright orange", SMP)
p(Vector3.new(40, 0.5, 4.5), Vector3.new(CX-5, G+4.25, CZ+28), "White", SMP)
-- Stools
for i = 0, 7 do
	local sx = CX-18+i*5.2
	p(Vector3.new(1, 4, 1), Vector3.new(sx, G+2, CZ+23), "Dark stone grey", SMP)
	p(Vector3.new(3, 0.4, 3), Vector3.new(sx, G+4.2, CZ+23), "Really red", SMP)
end

-- ── Inside: dining tables ─────────────────────────────────────────────────────
local function diningTable(tx, tz)
	p(Vector3.new(1.2, 4, 1.2), Vector3.new(tx, G+2, tz), "Dark stone grey", SMP)
	p(Vector3.new(8, 0.5, 8), Vector3.new(tx, G+4.25, tz), "White", SMP)
	-- Red/white checkered tablecloth feel
	p(Vector3.new(7.5, 0.1, 7.5), Vector3.new(tx, G+4.4, tz), "Bright red", SMP, 0.5)
	-- Chairs around table
	for _, off in {{5,0},{-5,0},{0,5},{0,-5}} do
		p(Vector3.new(1, 3, 1), Vector3.new(tx+off[1], G+1.5, tz+off[2]), "Bright orange", SMP)
		p(Vector3.new(3, 0.4, 3), Vector3.new(tx+off[1], G+3.2, tz+off[2]), "Bright red", SMP)
	end
end

for _, pos in {
	{-28, 165},{-14, 165},{0, 165},{14, 165},{28, 165},
	{-28, 182},{-14, 182},{0, 182},{14, 182},{28, 182},
	{-28, 199},{-14, 199},{0, 199},{14, 199},
} do
	diningTable(pos[1], pos[2])
end

-- ── Outdoor plaza area (north of building) ────────────────────────────────────
-- Decorative floor tiles
for tx = -4, 4 do
	local col = tx % 2 == 0 and "Bright red" or "White"
	p(Vector3.new(10, 0.4, 22), Vector3.new(CX+tx*10, G+0.3, CZ-HD-11), col, SMP)
end

-- Tall neon lamp posts lining the entrance
for _, lx in {-38, -22, -6, 6, 22, 38} do
	p(Vector3.new(1.2, 20, 1.2), Vector3.new(lx, G+10, CZ-HD-4), "Dark stone grey", SMP)
	local globe = p(Vector3.new(3, 3, 3), Vector3.new(lx, G+21, CZ-HD-4), "New Yeller", NEON, 0.05)
	globe.Shape = Enum.PartType.Ball
	-- Horizontal arm
	p(Vector3.new(3, 0.6, 0.6), Vector3.new(lx+1.5, G+20, CZ-HD-4), "Dark stone grey", SMP)
end

-- ── Bouncy mushrooms (pizza themed — big and dramatic) ────────────────────────
local mushroomCooldown = {}
local function bounceCharacter(hit, power)
	local char = hit.Parent
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	if mushroomCooldown[char] then return end
	mushroomCooldown[char] = true
	local angle = math.random() * math.pi * 2
	hrp.AssemblyLinearVelocity = Vector3.new(math.cos(angle)*20, power, math.sin(angle)*20)
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	task.delay(0.5, function() mushroomCooldown[char] = nil end)
end

for _, md in {
	{-50, 155, 1.1, "Really red",    "New Yeller"  },
	{-32, 240, 1.2, "Bright orange", "White"        },
	{ 50, 160, 1.0, "Bright red",    "Bright orange"},
	{ 36, 238, 1.3, "Really red",    "Cyan"         },
	{-50, 210, 0.9, "Hot pink",      "New Yeller"   },
	{ 50, 210, 1.1, "Bright orange", "White"        },
} do
	local mx, mz, ms, cc, sc = md[1], md[2], md[3], md[4], md[5]
	-- Stem
	local stem = Instance.new("Part")
	stem.Shape = Enum.PartType.Cylinder
	stem.Size = Vector3.new(4.5*ms, 3.5*ms, 3.5*ms)
	stem.CFrame = CFrame.new(mx, G+1.75*ms, mz) * CFrame.Angles(0, 0, math.rad(90))
	stem.BrickColor = BrickColor.new("Institutional white")
	stem.Material = SMP; stem.Anchored = true; stem.CanCollide = false; stem.Parent = folder
	-- Cap
	local cap = p(Vector3.new(10*ms, 3*ms, 10*ms), Vector3.new(mx, G+5.5*ms, mz), cc, NEON)
	cap.Shape = Enum.PartType.Ball; cap.Transparency = 0.05
	cap.Touched:Connect(function(hit) bounceCharacter(hit, 80 + ms*30) end)
	-- Spots
	for _, off in {{0,0},{2.5,1.5},{-2.5,1.2},{1.8,-2.3},{-1.9,-2}} do
		local sp = p(Vector3.new(1.4*ms,0.2*ms,1.4*ms), Vector3.new(mx+off[1]*ms, G+7.2*ms, mz+off[2]*ms), sc, NEON)
		sp.Shape = Enum.PartType.Ball; sp.Transparency = 0.12; sp.CanCollide = false
	end
	-- Ground glow
	local gl = p(Vector3.new(11*ms, 0.15, 11*ms), Vector3.new(mx, G+0.55, mz), sc, NEON, 0.7)
	gl.CanCollide = false
end

print("[PizzaPlace] Mega Pizza Palace built! Walls=" .. WH .. " Towers=" .. TH)
