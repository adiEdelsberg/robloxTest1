-- EmberHoldGameplay.server.luau  (World 24 — Ember Hold)
-- Galactic jump room south of Frost Basin.
-- Walls styled like galactic bridge floors: dark panels, neon overlay, pilasters, orb caps.
-- North wall: bridge to Frost Basin.  South wall: bridge to Nova Spire.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local WORLD_NAME = "Ember Hold"

-- ── Geometry ──────────────────────────────────────────────────────────────────
local CX      = -2860
local CZ      = 2550
local FLOOR_Y = 1
local HW      = 60      -- half interior width  (120 wide)
local HD      = 60      -- half interior depth  (120 deep)
local WALL_H  = 130
local WALL_T  = 5       -- wall thickness (slightly thicker for galactic panels)

local DOOR_HALF = 11    -- half-width in X (matches BW_Z=22 bridge)
local DOOR_H    = 12

local FINISH_Y = FLOOR_Y + WALL_H - 10

-- Galactic accent colors
local COLOR_PRIMARY = "Bright yellow"   -- gold neon (matches galactic bridges)
local COLOR_ACCENT  = "Cyan"

-- Jump tiers
local TIERS = {
	{ y = FLOOR_Y + 28,  launchV = 100, color = "Bright yellow" },
	{ y = FLOOR_Y + 62,  launchV = 107, color = "Cyan"          },
	{ y = FLOOR_Y + 98,  launchV = 114, color = "Bright yellow" },
	{ y = FLOOR_Y + 118, launchV = 122, color = "Cyan"          },
}

-- ── GameEvents ─────────────────────────────────────────────────────────────────
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)

local remValue = gameEvents and gameEvents:FindFirstChild("EmberHoldRemaining")
if not remValue then
	remValue = Instance.new("NumberValue")
	remValue.Name   = "EmberHoldRemaining"
	remValue.Value  = 0
	remValue.Parent = gameEvents or ReplicatedStorage
end

local totValue = gameEvents and gameEvents:FindFirstChild("EmberHoldTotal")
if not totValue then
	totValue = Instance.new("NumberValue")
	totValue.Name   = "EmberHoldTotal"
	totValue.Value  = 0
	totValue.Parent = gameEvents or ReplicatedStorage
end

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET  = (Balance.StageTargets and Balance.StageTargets.EmberHold) or 1

local playerScored
task.spawn(function() playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30) end)

-- ── State ──────────────────────────────────────────────────────────────────────
local alive          = false
local worldFolder    = nil
local finishDebounce = {}
local padDebounce    = {}

-- ── Part factory ───────────────────────────────────────────────────────────────
local function mkp(name, size, pos, color, mat, trans, noCollide)
	local p = Instance.new("Part")
	p.Name          = name
	p.Size          = size
	p.Position      = pos
	p.BrickColor    = BrickColor.new(color)
	p.Material      = mat
	p.Anchored      = true
	p.CanCollide    = not noCollide
	p.CanTouch      = true
	p.CastShadow    = false
	p.Transparency  = trans or 0
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent        = worldFolder
	return p
end

local function solid(name, size, pos, color, mat)
	return mkp(name, size, pos, color, mat or Enum.Material.SmoothPlastic, 0)
end

local function glow(name, size, pos, color, trans)
	return mkp(name, size, pos, color, Enum.Material.Neon, trans or 0.05, true)
end

local function mkball(size, pos, color, trans)
	local p = glow("Orb", Vector3.one * size, pos, color, trans)
	p.Shape = Enum.PartType.Ball
	return p
end

-- ── Galactic wall panel builder ─────────────────────────────────────────────────
-- Builds one rectangular galactic wall segment (no door gap — call per segment).
-- isZWall=true  → wall faces inward along X (W/E faces), panel extends in Z.
-- isZWall=false → wall faces inward along Z (N/S faces), panel extends in X.
-- fixedCoord = X for ZWalls, Z for XWalls.
-- along1/along2 = range in the spanning direction.
-- yBot/yTop = height range.
local function galWallSeg(isZWall, fixedCoord, along1, along2, yBot, yTop, primaryColor, accentColor)
	local len  = along2 - along1
	local yH   = yTop - yBot
	local midA = (along1 + along2) / 2
	local midY = (yBot + yTop) / 2

	local function sz(wx, wy, wz) return Vector3.new(wx, wy, wz) end
	local function pos(x, y, z)   return Vector3.new(x, y, z)   end

	if isZWall then
		-- Dark base panel
		solid("WallBase", sz(WALL_T, yH, len), pos(fixedCoord, midY, midA), "Really black", Enum.Material.SmoothPlastic)
		-- Neon color wash (inner face)
		glow("WallWash", sz(0.15, yH - 0.6, len - 0.6), pos(fixedCoord, midY, midA), primaryColor, 0.85)
		-- Edge neon strips top/bottom
		glow("WallEdgeB", sz(WALL_T + 0.1, 0.35, len), pos(fixedCoord, yBot + 0.2, midA), accentColor, 0.15)
		glow("WallEdgeT", sz(WALL_T + 0.1, 0.35, len), pos(fixedCoord, yTop - 0.2, midA), accentColor, 0.15)
		-- Diamond-plate base strip (bottom 1.5 studs)
		mkp("WallDP", sz(WALL_T, math.min(1.5, yH * 0.15), len), pos(fixedCoord, yBot + 0.75, midA),
			"Dark stone grey", Enum.Material.DiamondPlate, 0.05)
		-- Vertical neon pilasters every 14 studs
		local postStep = 14
		local a = along1 + postStep / 2
		while a < along2 do
			glow("Pilaster", sz(WALL_T + 0.1, yH, 0.5), pos(fixedCoord, midY, a), accentColor, 0.35)
			mkball(1.0, pos(fixedCoord, yTop + 0.5, a), primaryColor, 0.18)
			a += postStep
		end
		-- Horizontal neon guard rail near top
		glow("WallRail", sz(WALL_T + 0.1, 0.4, len), pos(fixedCoord, yTop - 4, midA), primaryColor, 0.28)

	else -- N/S face, extends in X
		solid("WallBase", sz(len, yH, WALL_T), pos(midA, midY, fixedCoord), "Really black", Enum.Material.SmoothPlastic)
		glow("WallWash", sz(len - 0.6, yH - 0.6, 0.15), pos(midA, midY, fixedCoord), primaryColor, 0.85)
		glow("WallEdgeB", sz(len, 0.35, WALL_T + 0.1), pos(midA, yBot + 0.2, fixedCoord), accentColor, 0.15)
		glow("WallEdgeT", sz(len, 0.35, WALL_T + 0.1), pos(midA, yTop - 0.2, fixedCoord), accentColor, 0.15)
		mkp("WallDP", sz(len, math.min(1.5, yH * 0.15), WALL_T), pos(midA, yBot + 0.75, fixedCoord),
			"Dark stone grey", Enum.Material.DiamondPlate, 0.05)
		local postStep = 14
		local a = along1 + postStep / 2
		while a < along2 do
			glow("Pilaster", sz(0.5, yH, WALL_T + 0.1), pos(a, midY, fixedCoord), accentColor, 0.35)
			mkball(1.0, pos(a, yTop + 0.5, fixedCoord), primaryColor, 0.18)
			a += postStep
		end
		glow("WallRail", sz(len, 0.4, WALL_T + 0.1), pos(midA, yTop - 4, fixedCoord), primaryColor, 0.28)
	end
end

-- Build a full wall with rectangular door holes using galactic style.
local function buildGalacticWall(isZWall, fixedCoord, along1, along2, yBot, yTop, holes)
	-- Collect unique Y breakpoints
	local yPts = { yBot, yTop }
	for _, h in holes do
		table.insert(yPts, h.yBot)
		table.insert(yPts, h.yTop)
	end
	table.sort(yPts)
	local uy = { yPts[1] }
	for i = 2, #yPts do
		if yPts[i] - uy[#uy] > 0.02 then table.insert(uy, yPts[i]) end
	end

	for bi = 1, #uy - 1 do
		local y0, y1 = uy[bi], uy[bi + 1]
		-- Find holes active in this Y band
		local active = {}
		for _, h in holes do
			if h.yBot <= y0 + 0.01 and h.yTop >= y1 - 0.01 then
				table.insert(active, { h.alongMin, h.alongMax })
			end
		end
		table.sort(active, function(a, b) return a[1] < b[1] end)
		-- Build segments between holes
		local cur = along1
		for _, hole in active do
			if hole[1] > cur then
				galWallSeg(isZWall, fixedCoord, cur, hole[1], y0, y1, COLOR_PRIMARY, COLOR_ACCENT)
			end
			cur = math.max(cur, hole[2])
		end
		if cur < along2 then
			galWallSeg(isZWall, fixedCoord, cur, along2, y0, y1, COLOR_PRIMARY, COLOR_ACCENT)
		end
	end
end

-- ── Galactic floor panel ────────────────────────────────────────────────────────
local function buildGalacticFloor(x1, x2, z1, z2, y, thickness)
	local cx = (x1 + x2) / 2
	local cz = (z1 + z2) / 2
	local lx  = x2 - x1
	local lz  = z2 - z1
	-- Dark base
	solid("FloorBase", Vector3.new(lx, thickness, lz), Vector3.new(cx, y - thickness / 2, cz),
		"Really black", Enum.Material.SmoothPlastic)
	-- Neon wash
	glow("FloorWash", Vector3.new(lx - 1, 0.1, lz - 1), Vector3.new(cx, y + 0.05, cz), COLOR_PRIMARY, 0.88)
	-- Edge neon strips
	for _, zOff in { -(lz / 2 - 0.5), (lz / 2 - 0.5) } do
		glow("FloorEdgeZ", Vector3.new(lx, 0.2, 0.7), Vector3.new(cx, y + 0.1, cz + zOff), COLOR_ACCENT, 0.15)
	end
	for _, xOff in { -(lx / 2 - 0.5), (lx / 2 - 0.5) } do
		glow("FloorEdgeX", Vector3.new(0.7, 0.2, lz), Vector3.new(cx + xOff, y + 0.1, cz), COLOR_ACCENT, 0.15)
	end
	-- Centre spine X
	glow("FloorSpineX", Vector3.new(lx, 0.15, 0.4), Vector3.new(cx, y + 0.12, cz), COLOR_ACCENT, 0.35)
	-- Centre spine Z
	glow("FloorSpineZ", Vector3.new(0.4, 0.15, lz), Vector3.new(cx, y + 0.12, cz), COLOR_ACCENT, 0.35)
	-- Star orbs at grid intersections
	local stepX = math.floor(lx / 4)
	local stepZ = math.floor(lz / 4)
	for i = 1, 3 do
		for j = 1, 3 do
			mkball(0.6, Vector3.new(cx - lx/2 + i*stepX, y + 0.4, cz - lz/2 + j*stepZ), "Institutional white", 0.25)
		end
	end
end

-- ── Galactic tier platform ──────────────────────────────────────────────────────
local function buildGalacticTier(y, color)
	local w   = HW * 2 - 20   -- width spanning W-E with small inset from walls
	local d   = 8              -- depth
	local cx  = CX
	local midY = y + 1

	-- Two half-platforms with a 20-stud gap in the centre (jump-through gap)
	local halfW = (w - 20) / 2
	for _, side in { -1, 1 } do
		local px = cx + side * (halfW / 2 + 10)
		-- Dark base
		solid("TierBase", Vector3.new(halfW, 2, d), Vector3.new(px, midY, CZ), "Really black", Enum.Material.SmoothPlastic)
		-- Neon top wash
		glow("TierWash", Vector3.new(halfW - 0.4, 0.1, d - 0.4), Vector3.new(px, midY + 1.05, CZ), color, 0.85)
		-- Edge strips
		glow("TierEdge", Vector3.new(halfW, 0.3, d + 0.1), Vector3.new(px, midY + 1, CZ), COLOR_ACCENT, 0.2)
	end
	-- Centre spine orb
	mkball(1.2, Vector3.new(cx, midY + 1.2, CZ), color, 0.12)
end

-- ── Jump pad helpers ───────────────────────────────────────────────────────────
local PAD_W        = 14
local PAD_H        = 1.5
local PAD_PROTRUDE = 8
local LAUNCH_FLOOR = 85

local function makeWallPad(px, py, pz, launchV, padColor)
	local ledge = solid("WallPad", Vector3.new(PAD_W, PAD_H, PAD_PROTRUDE),
		Vector3.new(px, py, pz), "Really black", Enum.Material.SmoothPlastic)
	local strip = glow("PadGlow", Vector3.new(PAD_W, 0.2, PAD_PROTRUDE),
		Vector3.new(px, py + PAD_H / 2 + 0.1, pz), padColor, 0.05)
	local sp = Instance.new("Sparkles")
	sp.SparkleColor = BrickColor.new(padColor).Color ; sp.Parent = strip
	local function pulse()
		if not strip.Parent then return end
		TweenService:Create(strip, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.6 }):Play()
		task.delay(0.5, function()
			if not strip.Parent then return end
			TweenService:Create(strip, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.05 }):Play()
			task.delay(0.5, pulse)
		end)
	end
	pulse()
	ledge.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then char = hit.Parent.Parent ; player = Players:GetPlayerFromCharacter(char) end
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(0, launchV, 0)
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.P = math.huge ; bv.Parent = hrp
			Debris:AddItem(bv, 0.12)
		end
		strip.BrickColor = BrickColor.new("White")
		task.delay(0.12, function() if strip.Parent then strip.BrickColor = BrickColor.new(padColor) end end)
		task.delay(0.15, function() padDebounce[player] = nil end)
	end)
end

local function makeFloorPad(px, pz, padColor)
	local padY = FLOOR_Y + 0.3
	local pad   = solid("FloorPad", Vector3.new(7, 0.6, 7), Vector3.new(px, padY, pz), "Really black", Enum.Material.SmoothPlastic)
	local strip = glow("FloorPadGlow", Vector3.new(7, 0.2, 7), Vector3.new(px, padY + 0.4, pz), padColor, 0.05)
	pad.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then char = hit.Parent.Parent ; player = Players:GetPlayerFromCharacter(char) end
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(0, LAUNCH_FLOOR, 0)
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.P = math.huge ; bv.Parent = hrp
			Debris:AddItem(bv, 0.12)
		end
		strip.BrickColor = BrickColor.new("White")
		task.delay(0.12, function() if strip.Parent then strip.BrickColor = BrickColor.new(padColor) end end)
		task.delay(0.15, function() padDebounce[player] = nil end)
	end)
end

-- ── Build ───────────────────────────────────────────────────────────────────────
local function buildRoom()
	worldFolder        = Instance.new("Folder")
	worldFolder.Name   = "EmberHoldWorld"
	worldFolder.Parent = workspace

	local xMin = CX - HW - WALL_T
	local xMax = CX + HW + WALL_T
	local zMin = CZ - HD - WALL_T
	local zMax = CZ + HD + WALL_T
	local yMin = FLOOR_Y
	local yMax = FLOOR_Y + WALL_H

	-- ── Galactic floor ───────────────────────────────────────────────────────────
	buildGalacticFloor(CX - HW, CX + HW, CZ - HD, CZ + HD, FLOOR_Y, 4)

	-- ── Floor launch pads ────────────────────────────────────────────────────────
	local fp = 18
	for _, dx in { -fp, fp } do
		for _, dz in { -fp, fp } do
			makeFloorPad(CX + dx, CZ + dz, COLOR_PRIMARY)
		end
	end
	makeFloorPad(CX, CZ, COLOR_ACCENT)

	-- ── Door holes ───────────────────────────────────────────────────────────────
	local nHoles = { { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H } }
	local sHoles = { { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H } }

	-- ── Galactic walls ───────────────────────────────────────────────────────────
	-- West (isZWall=true, fixedX, zMin→zMax)
	buildGalacticWall(true,  CX - HW - WALL_T / 2, zMin, zMax, yMin, yMax, {})
	-- East
	buildGalacticWall(true,  CX + HW + WALL_T / 2, zMin, zMax, yMin, yMax, {})
	-- North (isZWall=false, fixedZ, xMin→xMax)
	buildGalacticWall(false, CZ - HD - WALL_T / 2, xMin, xMax, yMin, yMax, nHoles)
	-- South
	buildGalacticWall(false, CZ + HD + WALL_T / 2, xMin, xMax, yMin, yMax, sHoles)

	-- ── Galactic tier platforms ──────────────────────────────────────────────────
	for _, tier in ipairs(TIERS) do
		buildGalacticTier(tier.y, tier.color)
	end

	-- ── Wall launch pads at each tier ────────────────────────────────────────────
	for _, tier in ipairs(TIERS) do
		local padCY = tier.y + PAD_H / 2 + 0.1
		local westX = CX - HW - WALL_T + PAD_PROTRUDE / 2 + 0.5
		local eastX = CX + HW + WALL_T - PAD_PROTRUDE / 2 - 0.5
		makeWallPad(westX, padCY, CZ - 20, tier.launchV, tier.color)
		makeWallPad(westX, padCY, CZ + 20, tier.launchV, tier.color)
		makeWallPad(eastX, padCY, CZ - 20, tier.launchV, tier.color)
		makeWallPad(eastX, padCY, CZ + 20, tier.launchV, tier.color)
	end

	-- ── Galactic ceiling ring ────────────────────────────────────────────────────
	local ringY = FLOOR_Y + WALL_H + 1
	glow("RingN", Vector3.new(HW*2+WALL_T*2+1, 1.2, 0.6), Vector3.new(CX, ringY, CZ-HD-WALL_T/2), COLOR_PRIMARY, 0.1)
	glow("RingS", Vector3.new(HW*2+WALL_T*2+1, 1.2, 0.6), Vector3.new(CX, ringY, CZ+HD+WALL_T/2), COLOR_PRIMARY, 0.1)
	glow("RingW", Vector3.new(0.6, 1.2, HD*2+WALL_T*2+1), Vector3.new(CX-HW-WALL_T/2, ringY, CZ), COLOR_PRIMARY, 0.1)
	glow("RingE", Vector3.new(0.6, 1.2, HD*2+WALL_T*2+1), Vector3.new(CX+HW+WALL_T/2, ringY, CZ), COLOR_PRIMARY, 0.1)
	-- Corner orbs
	for _, dx in { -(HW + WALL_T/2), (HW + WALL_T/2) } do
		for _, dz in { -(HD + WALL_T/2), (HD + WALL_T/2) } do
			mkball(2.5, Vector3.new(CX + dx, ringY, CZ + dz), COLOR_ACCENT, 0.08)
		end
	end

	-- ── Finish trigger ────────────────────────────────────────────────────────────
	local trigger = Instance.new("Part")
	trigger.Name        = "FinishTrigger"
	trigger.Size        = Vector3.new(HW * 2, 8, HD * 2)
	trigger.Position    = Vector3.new(CX, FINISH_Y + 4, CZ)
	trigger.Anchored    = true
	trigger.CanCollide  = false
	trigger.CanTouch    = true
	trigger.Transparency = 1
	trigger.Parent      = worldFolder
	trigger.Touched:Connect(function(hit)
		if not alive then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or finishDebounce[player] then return end
		finishDebounce[player] = true
		remValue.Value = math.max(0, remValue.Value - 1)
		if playerScored then playerScored:Fire(player, WORLD_NAME) end
		task.delay(6, function() finishDebounce[player] = nil end)
	end)

	-- ── Sign ──────────────────────────────────────────────────────────────────────
	local signPart = solid("SignPart", Vector3.new(26, 7, 0.4),
		Vector3.new(CX + HW + WALL_T + 0.3, FLOOR_Y + 14, CZ), "Really black", Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "RoomSign" ; gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud ; gui.PixelsPerStud = 30
	gui.LightInfluence = 0 ; gui.Parent = signPart
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1,0,1,0) ; bg.BackgroundColor3 = Color3.fromRGB(5,5,5)
	bg.BackgroundTransparency = 0.05 ; bg.BorderSizePixel = 0 ; bg.Parent = gui
	local l1 = Instance.new("TextLabel")
	l1.Size = UDim2.new(1,0,0.5,0) ; l1.Position = UDim2.new(0,0,0.05,0)
	l1.BackgroundTransparency = 1 ; l1.Text = "EMBER HOLD"
	l1.TextColor3 = Color3.fromRGB(255,215,0) ; l1.TextStrokeTransparency = 0.3
	l1.Font = Enum.Font.GothamBlack ; l1.TextSize = 28 ; l1.Parent = bg
	local l2 = Instance.new("TextLabel")
	l2.Size = UDim2.new(1,0,0.38,0) ; l2.Position = UDim2.new(0,0,0.58,0)
	l2.BackgroundTransparency = 1 ; l2.Text = "REACH THE SUMMIT"
	l2.TextColor3 = Color3.fromRGB(130,220,255) ; l2.TextStrokeTransparency = 0.5
	l2.Font = Enum.Font.GothamBold ; l2.TextSize = 17 ; l2.Parent = bg
end

-- ── Lifecycle ───────────────────────────────────────────────────────────────────
local function destroyRoom()
	if worldFolder and worldFolder.Parent then worldFolder:Destroy() end
	worldFolder = nil
	table.clear(finishDebounce)
	table.clear(padDebounce)
end

task.spawn(function()
	local sig = gameEvents and gameEvents:WaitForChild("WorldRestartSignal", 30)
	if sig then
		sig.Event:Connect(function(worldName)
			if worldName ~= WORLD_NAME then return end
			destroyRoom()
			alive = true
			remValue.Value = TARGET
			totValue.Value = TARGET
			buildRoom()
		end)
	end
end)

alive = true
remValue.Value = TARGET
totValue.Value = TARGET
buildRoom()
print("[EmberHold] World 24 built — galactic style.")
