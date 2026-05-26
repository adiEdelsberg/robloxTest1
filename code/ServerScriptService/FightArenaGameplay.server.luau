-- FightArenaGameplay.server.luau  (World 42 — Fight Arena / Crimson Colosseum)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local CX, CZ  = -2860, 8100
local FLOOR_Y = 1

-- ── Bootstrap ─────────────────────────────────────────────────────────────────
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)

local function getOrCreate(parent, class, name)
	if not parent then return nil end
	local v = parent:FindFirstChild(name)
	if not v then
		v = Instance.new(class)
		v.Name   = name
		v.Value  = 0
		v.Parent = parent
	end
	return v
end

local remValue = getOrCreate(gameEvents, "NumberValue", "FightArenaRemaining")
local totValue = getOrCreate(gameEvents, "NumberValue", "FightArenaTotal")

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET  = (Balance.StageTargets and Balance.StageTargets.FightArena) or 1

-- ── Part factory ──────────────────────────────────────────────────────────────
local worldFolder = nil

local function mkp(name, size, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name          = name
	part.Size          = size
	part.CFrame        = typeof(cf) == "CFrame" and cf or CFrame.new(cf)
	part.BrickColor    = BrickColor.new(color)
	part.Material      = mat or Enum.Material.SmoothPlastic
	part.Anchored      = true
	part.CanCollide    = not noCollide
	part.CanTouch      = true
	part.CastShadow    = false
	part.Transparency  = trans or 0
	part.TopSurface    = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent        = worldFolder
	return part
end

local function neon(name, size, cf, color, trans)
	return mkp(name, size, cf, color, Enum.Material.Neon, trans or 0, true)
end

-- World-space CFrame helpers
local function wv(x, y, z)   return Vector3.new(CX + x, FLOOR_Y + y, CZ + z) end
local function wcf(x, y, z)  return CFrame.new(CX + x, FLOOR_Y + y, CZ + z) end
local function rcf(x, y, z, ry)
	return CFrame.new(CX + x, FLOOR_Y + y, CZ + z) * CFrame.Angles(0, ry, 0)
end

-- Ring position helpers (angle = math radians from +X, CCW when viewed from above)
local function ringPos(angle, r, y)
	return wv(math.cos(angle) * r, y, math.sin(angle) * r)
end
local function ringCF(angle, r, y, extraRot)
	local base = CFrame.new(CX + math.cos(angle)*r, FLOOR_Y + y, CZ + math.sin(angle)*r)
		* CFrame.Angles(0, math.pi/2 - angle + (extraRot or 0), 0)
	return base
end

-- ── Build ─────────────────────────────────────────────────────────────────────
local finishDebounce = {}

local function buildWorld()
	if worldFolder then worldFolder:Destroy() end
	finishDebounce = {}

	worldFolder = Instance.new("Folder")
	worldFolder.Name   = "FightArenaWorld"
	worldFolder.Parent = workspace

	-- ┌─────────────────────────────────────────────────────────────────────────┐
	-- │  KEY DIMENSIONS                                                         │
	-- │  R_SAND   = 78   : sand floor inradius (octagonal)                     │
	-- │  R_RWALL  = 80   : inner retaining wall inradius                       │
	-- │  R_OUTER  = 108  : outer wall inradius                                 │
	-- │  WALL_H   = 55   : outer wall height                                   │
	-- │  COL_R    = 115  : decorative column distance from center              │
	-- └─────────────────────────────────────────────────────────────────────────┘
	local R_SAND   = 78
	local R_RWALL  = 82
	local R_OUTER  = 110
	local OUTER_T  = 8
	local WALL_H   = 58
	local WALL_W   = 88    -- octagon wall segment width (inradius 110)
	local COL_R    = 117
	local COL_H    = 70
	local COL_W    = 8

	-- North gate angle = 270° = -Z (entrance from world 41)
	-- South gate angle = 90°  = +Z (exit toward next world)
	local GATE_W   = 16   -- opening width each arch
	local GATE_H   = 22
	local SKIP_N   = 6    -- octagon index for north wall
	local SKIP_S   = 2    -- octagon index for south wall

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 1. UNDERGROUND BASE  (below ground, solid foundation feel)
	-- ═══════════════════════════════════════════════════════════════════════════
	mkp("Foundation", Vector3.new(R_OUTER*2 + 40, 10, R_OUTER*2 + 40),
		wcf(0, -5, 0), "Really black", Enum.Material.SmoothPlastic)

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 2. ARENA FLOOR  (ancient cracked stone tiles with moss-filled joints)
	-- ═══════════════════════════════════════════════════════════════════════════
	local rng = Random.new(77)

	-- Deep stone substrate below tiles
	mkp("FloorBase", Vector3.new(R_SAND*2 + 6, 4, R_SAND*2 + 6),
		wcf(0, -1.2, 0), "Dark stone grey", Enum.Material.Cobblestone)

	-- Dark grout — shows through the gaps between tiles as black joint lines
	mkp("GroutFill", Vector3.new(R_SAND*2 + 2, 0.55, R_SAND*2 + 2),
		wcf(0, 0.05, 0), "Really black", Enum.Material.SmoothPlastic)

	-- ── Stone tile grid ───────────────────────────────────────────────────────
	local TILE_W = 13.2
	local TILE_D = 13.2
	local GAP    = 1.2
	local STEP   = TILE_W + GAP   -- 14.4 per cell

	local tilePalette = {
		"Medium stone grey", "Medium stone grey", "Medium stone grey",
		"Sand yellow", "Cashmere", "Tan", "Sand yellow",
		"Medium stone grey", "Cashmere",
	}

	for ix = -5, 5 do
		for iz = -5, 5 do
			local tx   = ix * STEP
			local tz   = iz * STEP
			local dist = math.sqrt(tx*tx + tz*tz)
			if dist < R_SAND - 3 then
				local tw   = TILE_W + rng:NextNumber(-1.0, 0.8)
				local td   = TILE_D + rng:NextNumber(-1.0, 0.8)
				local rot  = rng:NextNumber(-0.018, 0.018)
				local yOff = rng:NextNumber(-0.06, 0.06)
				local col  = (dist > 55) and "Dark stone grey" or tilePalette[rng:NextInteger(1, #tilePalette)]
				local mat  = rng:NextNumber() < 0.25 and Enum.Material.Concrete or Enum.Material.Cobblestone
				mkp("StoneTile", Vector3.new(tw, 0.55, td),
					rcf(tx, 0.45 + yOff, tz, rot), col, mat, 0, true)
			end
		end
	end

	-- Half-grid offset sub-tiles for corner coverage and texture variety
	for ix = -5, 4 do
		for iz = -5, 4 do
			local tx   = (ix + 0.5) * STEP
			local tz   = (iz + 0.5) * STEP
			local dist = math.sqrt(tx*tx + tz*tz)
			if dist < R_SAND - 8 then
				local tw   = TILE_W * 0.65 + rng:NextNumber(-0.8, 0.8)
				local td   = TILE_D * 0.65 + rng:NextNumber(-0.8, 0.8)
				local rot  = rng:NextNumber(-0.02, 0.02)
				local yOff = rng:NextNumber(-0.04, 0.03)
				mkp("StoneTileSub", Vector3.new(tw, 0.45, td),
					rcf(tx, 0.42 + yOff, tz, rot),
					tilePalette[rng:NextInteger(1, #tilePalette)], Enum.Material.Cobblestone, 0, true)
			end
		end
	end

	-- ── Moss growing in the cracks ────────────────────────────────────────────
	local mossPalette = { "Bright green", "Bright green", "Olive", "Sand green", "Bright green" }
	for ix = -5, 5 do
		for iz = -5, 5 do
			-- N-S joints
			local txNS = ix * STEP + STEP * 0.5
			local tzNS = iz * STEP
			if math.sqrt(txNS*txNS + tzNS*tzNS) < R_SAND - 5 and rng:NextNumber() < 0.72 then
				local ml = TILE_D * rng:NextNumber(0.4, 0.95)
				local mz = tzNS + rng:NextNumber(-2.5, 2.5)
				mkp("MossNS", Vector3.new(GAP - 0.15, 0.12, ml),
					rcf(txNS, 0.56, mz, 0),
					mossPalette[rng:NextInteger(1, #mossPalette)], Enum.Material.Grass, 0.05, true)
			end
			-- E-W joints
			local txEW = ix * STEP
			local tzEW = iz * STEP + STEP * 0.5
			if math.sqrt(txEW*txEW + tzEW*tzEW) < R_SAND - 5 and rng:NextNumber() < 0.72 then
				local ml  = TILE_W * rng:NextNumber(0.4, 0.95)
				local mx2 = txEW + rng:NextNumber(-2.5, 2.5)
				mkp("MossEW", Vector3.new(ml, 0.12, GAP - 0.15),
					rcf(mx2, 0.64, tzEW, 0),
					mossPalette[rng:NextInteger(1, #mossPalette)], Enum.Material.Grass, 0.05, true)
			end
		end
	end

	-- ── Perimeter curb ring ───────────────────────────────────────────────────
	for i = 0, 31 do
		local a   = math.rad(i * (360/32))
		local r   = 74
		local tw  = math.pi * 2 * r / 32 + 0.4
		local col = (i % 2 == 0) and "Dark stone grey" or "Medium stone grey"
		mkp("Curb", Vector3.new(tw, 1.4, 5),
			CFrame.new(CX + math.cos(a)*r, FLOOR_Y + 0.7, CZ + math.sin(a)*r)
				* CFrame.Angles(0, math.pi/2 - a, 0),
			col, Enum.Material.Cobblestone)
	end

	-- ── Boundary marker posts ─────────────────────────────────────────────────
	for i = 0, 7 do
		local a  = math.rad(i * 45 + 22.5)
		local mx = CX + math.cos(a) * 71
		local mz = CZ + math.sin(a) * 71
		mkp("BoundPost",    Vector3.new(3, 7, 3),   CFrame.new(mx, FLOOR_Y + 3.5, mz),
			"Dark stone grey", Enum.Material.Cobblestone)
		mkp("BoundPostCap", Vector3.new(4, 1.8, 4),  CFrame.new(mx, FLOOR_Y + 7.6, mz),
			"Really black", Enum.Material.SmoothPlastic)
		neon("BoundGlow",   Vector3.new(2, 1.2, 2),  CFrame.new(mx, FLOOR_Y + 6, mz),
			"Bright red", 0.6)
	end

	-- BattleStone (finish trigger — invisible)
	mkp("BattleStone", Vector3.new(9, 0.5, 9),
		wcf(0, 2.1, 0), "Really black", Enum.Material.SmoothPlastic, 1.0, true)

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 3. RUINED OUTER WALLS  (rough ancient stone blocks, varied height, gaps)
	-- ═══════════════════════════════════════════════════════════════════════════
	local WR = 96   -- wall face inradius
	local WT = 10   -- wall thickness

	-- Per octagon face: height (0 = gate opening), broken = jagged collapsed top
	local wallFaces = {
		{ h=30, broken=false },  -- 0 = E
		{ h=24, broken=false },  -- 1 = SE
		{ h=0,  broken=false },  -- 2 = S gate
		{ h=28, broken=true  },  -- 3 = SW  (partially collapsed)
		{ h=36, broken=false },  -- 4 = W
		{ h=22, broken=true  },  -- 5 = NW  (partially collapsed)
		{ h=0,  broken=false },  -- 6 = N gate
		{ h=32, broken=false },  -- 7 = NE
	}

	local function buildWallFace(wx, wy, wz, faceRot, w, h, thick, broken)
		local wrng = Random.new(math.floor(wx * 7 + wz * 3))
		-- Main wall body
		mkp("RuinWall", Vector3.new(w, h, thick),
			CFrame.new(wx, wy + h/2, wz) * CFrame.Angles(0, faceRot, 0),
			"Dark stone grey", Enum.Material.Cobblestone)
		-- Stone block course seams (alternating rows, darker/lighter)
		local blockH = 7
		local rows = math.floor(h / blockH)
		for row = 0, rows - 1 do
			local rowY = wy + row * blockH + blockH/2
			local blockW = 14 + wrng:NextNumber(-2, 2)
			local cols = math.floor(w / blockW)
			for col = 0, cols - 1 do
				local bOff = -w/2 + blockW/2 + col * blockW + wrng:NextNumber(-0.8, 0.8)
				local bW   = blockW + wrng:NextNumber(-1.5, 1.5)
				local bc   = (row % 2 == 0) and "Dark stone grey" or "Medium stone grey"
				mkp("WallBlock", Vector3.new(bW, blockH - 0.5, thick + 1.2),
					CFrame.new(wx, rowY, wz) * CFrame.Angles(0, faceRot, 0) * CFrame.new(bOff, 0, 0),
					bc, Enum.Material.Cobblestone, 0, true)
			end
		end
		-- Irregular jagged top edge (merlons / broken crenellations)
		local mW = 9
		local mCnt = math.floor(w / mW)
		for m = 0, mCnt - 1 do
			local skipChance = broken and 0.45 or 0.25
			if wrng:NextNumber() > skipChance then
				local mOff = -w/2 + mW/2 + m * mW + wrng:NextNumber(-1.5, 1.5)
				local mH   = wrng:NextNumber(broken and 2 or 3, broken and 7 or 10)
				local mTilt = wrng:NextNumber(-0.06, 0.06)
				mkp("WallMerlon", Vector3.new(mW - 1, mH, thick + 1),
					CFrame.new(wx, wy + h + mH/2, wz) * CFrame.Angles(mTilt, faceRot, 0) * CFrame.new(mOff, 0, 0),
					"Dark stone grey", Enum.Material.Cobblestone)
			end
		end
		-- Rubble stones at wall base (fallen blocks)
		for r = 0, 4 do
			local rOff  = wrng:NextNumber(-w/2 + 4, w/2 - 4)
			local rSide = wrng:NextNumber() > 0.5 and 1 or -1
			local rs    = wrng:NextNumber(3, 8)
			local bCF   = CFrame.new(wx, wy + rs * 0.4, wz)
				* CFrame.Angles(0, faceRot, 0)
				* CFrame.new(rOff, 0, rSide * (thick/2 + rs/2 + 1))
				* CFrame.Angles(wrng:NextNumber(-0.3, 0.3), wrng:NextNumber(0, math.pi), 0)
			mkp("Rubble", Vector3.new(rs, rs * 0.65, rs * 0.8), bCF,
				"Dark stone grey", Enum.Material.Cobblestone)
		end
	end

	for i = 0, 7 do
		local face = wallFaces[i + 1]
		if face.h > 0 then
			local a       = math.rad(i * 45)
			local wx      = CX + math.cos(a) * WR
			local wz      = CZ + math.sin(a) * WR
			local faceRot = math.pi/2 - a
			local faceW   = 2 * WR * math.tan(math.rad(22.5)) - 4
			buildWallFace(wx, FLOOR_Y, wz, faceRot, faceW, face.h, WT, face.broken)
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 4. RUINED STONE COLUMNS  (mix of standing and fallen, around arena ring)
	-- ═══════════════════════════════════════════════════════════════════════════
	local columns = {
		{ r=84, a=0,   standing=true,  h=50 },
		{ r=84, a=58,  standing=true,  h=38 },
		{ r=84, a=118, standing=false, h=20 },
		{ r=84, a=180, standing=true,  h=46 },
		{ r=84, a=240, standing=true,  h=30 },
		{ r=84, a=302, standing=false, h=24 },
	}

	for _, col in ipairs(columns) do
		local ca  = math.rad(col.a)
		local cpx = CX + math.cos(ca) * col.r
		local cpz = CZ + math.sin(ca) * col.r
		local cw  = 7

		mkp("ColPlinth", Vector3.new(cw + 6, 4, cw + 6), CFrame.new(cpx, FLOOR_Y + 2, cpz),
			"Dark stone grey", Enum.Material.Cobblestone)
		mkp("ColShaft1", Vector3.new(cw, col.h * 0.55, cw),
			CFrame.new(cpx, FLOOR_Y + 4 + col.h * 0.275, cpz), "Medium stone grey", Enum.Material.Cobblestone)

		if col.standing then
			mkp("ColShaft2", Vector3.new(cw - 1, col.h * 0.45, cw - 1),
				CFrame.new(cpx, FLOOR_Y + 4 + col.h * 0.775, cpz), "Medium stone grey", Enum.Material.Cobblestone)
			mkp("ColCapital", Vector3.new(cw + 8, 6, cw + 8),
				CFrame.new(cpx, FLOOR_Y + 4 + col.h + 3, cpz), "Dark stone grey", Enum.Material.Cobblestone)
			mkp("ColAbacus", Vector3.new(cw + 11, 3, cw + 11),
				CFrame.new(cpx, FLOOR_Y + 4 + col.h + 7.5, cpz), "Really black", Enum.Material.SmoothPlastic)
		else
			-- Broken stump with jagged top
			mkp("ColBroken", Vector3.new(cw + 2, 4, cw + 2),
				CFrame.new(cpx, FLOOR_Y + 4 + col.h + 2, cpz) * CFrame.Angles(0, 0, math.rad(7)),
				"Dark stone grey", Enum.Material.Cobblestone)
			-- Fallen shaft section lying nearby
			local dAngle = ca + math.pi/2
			mkp("ColFallen", Vector3.new(col.h * 0.4, cw - 1, cw - 1),
				CFrame.new(cpx + math.cos(dAngle)*12, FLOOR_Y + (cw-1)/2, cpz + math.sin(dAngle)*12)
					* CFrame.Angles(0, dAngle, 0),
				"Medium stone grey", Enum.Material.Cobblestone)
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 5. TREES  (ancient trees growing through the ruins, with foliage canopy)
	-- ═══════════════════════════════════════════════════════════════════════════
	local trees = {
		{ x= 74, z=-32, trunkH=28, fr=18, lean= 0.05 },
		{ x=-68, z= 42, trunkH=24, fr=16, lean=-0.06 },
		{ x= 32, z= 82, trunkH=32, fr=20, lean= 0.04 },
		{ x=-52, z=-74, trunkH=22, fr=15, lean= 0.07 },
		{ x= 88, z= 56, trunkH=20, fr=13, lean=-0.03 },
	}
	local foliagePal = { "Bright green", "Medium green", "Olive", "Sand green" }
	local trunkPal   = { "Reddish brown", "Dark orange", "Brown" }

	for ti, tree in ipairs(trees) do
		local tx   = CX + tree.x
		local tz2  = CZ + tree.z
		local trng = Random.new(ti * 37)
		local tc   = trunkPal[trng:NextInteger(1, #trunkPal)]
		local tw1  = trng:NextNumber(4, 6)

		-- Trunk (two tapered sections)
		mkp("TrunkLow",  Vector3.new(tw1,     tree.trunkH * 0.6, tw1),
			CFrame.new(tx, FLOOR_Y + tree.trunkH * 0.3,  tz2) * CFrame.Angles(0, 0, tree.lean), tc, Enum.Material.Wood)
		mkp("TrunkHigh", Vector3.new(tw1-1.5, tree.trunkH * 0.4, tw1-1.5),
			CFrame.new(tx + math.sin(tree.lean)*tree.trunkH*0.4, FLOOR_Y + tree.trunkH * 0.8, tz2),
			tc, Enum.Material.Wood)

		-- Root flares at base
		for r = 0, 2 do
			local ra = math.rad(r * 120 + trng:NextNumber(0, 30))
			local rl = trng:NextNumber(5, 9)
			mkp("Root"..r, Vector3.new(1.8, 2.5, rl),
				CFrame.new(tx + math.cos(ra)*rl*0.4, FLOOR_Y + 1, tz2 + math.sin(ra)*rl*0.4)
					* CFrame.Angles(0, ra, math.rad(-12)),
				tc, Enum.Material.Wood)
		end

		-- Main canopy
		local fc1  = foliagePal[trng:NextInteger(1, #foliagePal)]
		local fy   = FLOOR_Y + tree.trunkH + tree.fr * 0.55
		local main = mkp("Canopy", Vector3.new(tree.fr*2, tree.fr*1.4, tree.fr*2),
			CFrame.new(tx, fy, tz2), fc1, Enum.Material.LeafyGrass, 0, true)
		main.Shape = Enum.PartType.Ball

		-- Secondary canopy lobes
		for l = 0, 2 do
			local la   = math.rad(l * 120 + trng:NextNumber(0, 40))
			local lr   = tree.fr * 0.55
			local lobe = mkp("Lobe"..l, Vector3.new(lr*2, lr*1.6, lr*2),
				CFrame.new(tx + math.cos(la)*tree.fr*0.55, fy + trng:NextNumber(-tree.fr*0.2, tree.fr*0.2),
					tz2 + math.sin(la)*tree.fr*0.55),
				foliagePal[trng:NextInteger(1, #foliagePal)], Enum.Material.LeafyGrass, 0, true)
			lobe.Shape = Enum.PartType.Ball
		end

		-- Dark under-shadow lobe
		local shad = mkp("TreeShade", Vector3.new(tree.fr*1.4, tree.fr*0.4, tree.fr*1.4),
			CFrame.new(tx, fy - tree.fr*0.55, tz2), "Olive", Enum.Material.Grass, 0.3, true)
		shad.Shape = Enum.PartType.Ball
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 6. SCATTERED BOULDERS  (rock clusters around arena edges)
	-- ═══════════════════════════════════════════════════════════════════════════
	local boulderClusters = {
		{ x= 55, z=-58, n=4, seed=11 },
		{ x=-62, z=-46, n=3, seed=22 },
		{ x= 72, z= 44, n=5, seed=33 },
		{ x=-40, z= 70, n=4, seed=44 },
		{ x= 20, z=-82, n=3, seed=55 },
		{ x=-76, z= 12, n=4, seed=66 },
	}
	for _, cluster in ipairs(boulderClusters) do
		local brng = Random.new(cluster.seed)
		for b = 1, cluster.n do
			local bx  = CX + cluster.x + brng:NextNumber(-10, 10)
			local bz2 = CZ + cluster.z + brng:NextNumber(-10, 10)
			local bw  = brng:NextNumber(5, 14)
			local bh  = bw * brng:NextNumber(0.5, 0.8)
			local bd  = bw * brng:NextNumber(0.6, 1.0)
			mkp("Boulder", Vector3.new(bw, bh, bd),
				CFrame.new(bx, FLOOR_Y + bh/2, bz2)
					* CFrame.Angles(brng:NextNumber(-0.25, 0.25), brng:NextNumber(0, math.pi*2), 0),
				"Dark stone grey", Enum.Material.Cobblestone)
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 7. RAISED VIEWING PLATFORM  (east side — wooden canopied spectator dais)
	-- ═══════════════════════════════════════════════════════════════════════════
	local PX = CX + 94   -- east of arena
	local PZ = CZ
	local PH = 10

	-- Stepped stone base (3 tiers) — each step height oversized by 0.4 so tiers embed into each other
	local sh = PH/3 + 0.4
	for step = 0, 2 do
		mkp("PlatStep"..step, Vector3.new(40 - step*6, sh, 28 - step*4),
			CFrame.new(PX, FLOOR_Y + step * PH/3 + sh/2, PZ),
			"Dark stone grey", Enum.Material.Cobblestone)
	end
	-- Platform deck — bottom embedded into top step, not flush with it
	mkp("PlatDeck", Vector3.new(28, 2, 18), CFrame.new(PX, FLOOR_Y + PH + 0.8, PZ),
		"Medium stone grey", Enum.Material.Concrete)
	-- Front parapet (faces arena)
	mkp("PlatParapet", Vector3.new(28, 5, 3), CFrame.new(PX - 6, FLOOR_Y + PH + 3.5, PZ),
		"Dark stone grey", Enum.Material.Cobblestone)
	-- Back wall
	mkp("PlatBackWall", Vector3.new(3, 22, 18), CFrame.new(PX + 11, FLOOR_Y + PH + 11, PZ),
		"Dark stone grey", Enum.Material.Cobblestone)
	-- Side walls
	for _, sz in ipairs({-9, 9}) do
		mkp("PlatSideWall", Vector3.new(28, 14, 3), CFrame.new(PX - 1, FLOOR_Y + PH + 7, PZ + sz),
			"Dark stone grey", Enum.Material.Cobblestone)
	end
	-- Wooden canopy structure
	mkp("CanopyTop",   Vector3.new(30, 2, 22), CFrame.new(PX, FLOOR_Y + PH + 23, PZ),
		"Dark orange",    Enum.Material.Wood)
	mkp("CanopyBeam1", Vector3.new(30, 2, 3),  CFrame.new(PX, FLOOR_Y + PH + 22, PZ - 7),
		"Bright orange",  Enum.Material.Wood)
	mkp("CanopyBeam2", Vector3.new(30, 2, 3),  CFrame.new(PX, FLOOR_Y + PH + 22, PZ + 7),
		"Bright orange",  Enum.Material.Wood)
	-- Canopy posts
	for _, pz in ipairs({-7, 7}) do
		mkp("CanopyPost1", Vector3.new(3, 24, 3), CFrame.new(PX - 10, FLOOR_Y + PH + 11, PZ + pz),
			"Reddish brown", Enum.Material.Wood)
		mkp("CanopyPost2", Vector3.new(3, 20.6, 3), CFrame.new(PX + 8,  FLOOR_Y + PH + 11, PZ + pz),
			"Reddish brown", Enum.Material.Wood)
	end
	-- Hanging banners on platform
	for _, bz2 in ipairs({-6, 0, 6}) do
		mkp("PlatBanner", Vector3.new(5, 14, 1.5),
			CFrame.new(PX - 7, FLOOR_Y + PH + 11, PZ + bz2), "Maroon", Enum.Material.Fabric)
	end
	-- Throne
	mkp("Throne",     Vector3.new(8, 7, 6),  CFrame.new(PX,   FLOOR_Y + PH + 4.5, PZ), "Dark stone grey", Enum.Material.Cobblestone)
	mkp("ThroneBack", Vector3.new(8, 10, 2), CFrame.new(PX+2, FLOOR_Y + PH + 11,  PZ), "Dark stone grey", Enum.Material.Cobblestone)

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 8. GATE OPENINGS  (N and S — simple stone archway in ruined wall)
	-- ═══════════════════════════════════════════════════════════════════════════
	for _, side in ipairs({-1, 1}) do
		local gz = CZ + side * WR
		local GW = 20; local GH = 26; local GT = WT + 4

		-- Gate pillars flanking opening
		for _, gx in ipairs({CX - GW/2 - 6, CX + GW/2 + 6}) do
			mkp("GatePillar",    Vector3.new(12, 36, GT),   CFrame.new(gx, FLOOR_Y + 18, gz),
				"Dark stone grey", Enum.Material.Cobblestone)
			mkp("GatePillarCap", Vector3.new(16, 5, GT + 4), CFrame.new(gx, FLOOR_Y + 38, gz),
				"Dark stone grey", Enum.Material.Cobblestone)
			-- Block courses on pillar
			for b = 0, 3 do
				mkp("GPBlock", Vector3.new(12, 7, GT + 1.2),
					CFrame.new(gx, FLOOR_Y + 4 + b * 8.5, gz), "Medium stone grey", Enum.Material.Cobblestone, 0, true)
			end
		end
		-- Lintel (solid block above opening)
		mkp("GateLintel",    Vector3.new(GW, 9, GT),    CFrame.new(CX, FLOOR_Y + GH + 4.5, gz),
			"Dark stone grey", Enum.Material.Cobblestone)
		mkp("GateLintelTop", Vector3.new(GW + 6, 5, GT + 3), CFrame.new(CX, FLOOR_Y + GH + 11, gz),
			"Medium stone grey", Enum.Material.Cobblestone)
		-- Rough stone keystone
		mkp("GateKeystone", Vector3.new(8, 9, GT + 2), CFrame.new(CX, FLOOR_Y + GH + 5, gz),
			"Really black", Enum.Material.Cobblestone)
		-- Flanking wall sections connecting to main ruin wall
		for _, fx in ipairs({-1, 1}) do
			local wallX = CX + fx * (GW/2 + 6 + 18)
			mkp("GateFill",  Vector3.new(24, 30, WT), CFrame.new(wallX, FLOOR_Y + 15, gz),
				"Dark stone grey", Enum.Material.Cobblestone)
			for b = 0, 2 do
				mkp("GFBlock", Vector3.new(24, 8, WT + 1.2),
					CFrame.new(wallX, FLOOR_Y + 5 + b * 10, gz), "Medium stone grey", Enum.Material.Cobblestone, 0, true)
			end
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 9. GROUND VEGETATION  (grass tufts near walls and cracks)
	-- ═══════════════════════════════════════════════════════════════════════════
	local vegRng = Random.new(99)
	local vegSpots = {
		{ x= 66, z= 10 }, { x=-58, z= 22 }, { x= 44, z=-64 }, { x=-72, z=-18 },
		{ x= 78, z= 38 }, { x=-80, z= 50 }, { x= 30, z= 72 }, { x=-28, z=-70 },
		{ x= 58, z=-50 }, { x=-64, z= 62 }, { x= 82, z=-22 }, { x=-86, z=  8 },
	}
	for _, vp in ipairs(vegSpots) do
		local vx = CX + vp.x + vegRng:NextNumber(-3, 3)
		local vz = CZ + vp.z + vegRng:NextNumber(-3, 3)
		mkp("Grass", Vector3.new(vegRng:NextNumber(4, 9), 1.5, vegRng:NextNumber(4, 9)),
			CFrame.new(vx, FLOOR_Y + 1, vz), "Bright green", Enum.Material.Grass, 0, true)
		if vegRng:NextNumber() > 0.5 then
			mkp("Weed", Vector3.new(1, vegRng:NextNumber(3, 7), 1),
				CFrame.new(vx + vegRng:NextNumber(-2,2), FLOOR_Y + 2, vz + vegRng:NextNumber(-2,2)),
				"Olive", Enum.Material.Grass, 0, true)
		end
	end

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 10. WALL TORCHES  (mounted on inner face of ruin walls)
	-- ═══════════════════════════════════════════════════════════════════════════
	local torchFaceIds = {0, 1, 3, 4, 7}
	for _, fi in ipairs(torchFaceIds) do
		local a   = math.rad(fi * 45)
		local fh  = wallFaces[fi + 1].h
		local twx = CX + math.cos(a) * (WR - WT * 0.5 - 1)
		local twz = CZ + math.sin(a) * (WR - WT * 0.5 - 1)
		local ty  = FLOOR_Y + fh * 0.58
		mkp("TorchBracket", Vector3.new(1.5, 3, 3),  CFrame.new(twx, ty, twz),       "Really black",  Enum.Material.Metal)
		mkp("TorchStick",   Vector3.new(1.2, 6, 1.2), CFrame.new(twx, ty + 4.1, twz), "Reddish brown", Enum.Material.Wood)
		neon("TorchFlame1", Vector3.new(3, 5, 3),     CFrame.new(twx, ty + 8.5, twz), "Bright orange", 0.05)
		neon("TorchFlame2", Vector3.new(1.8, 3.5, 1.8),CFrame.new(twx, ty + 9.5, twz),"Bright yellow", 0.12)
	end

	-- Very faint ambient sky glow (no neon ring, just sky atmosphere)
	neon("AmbientGlow", Vector3.new(8, 8, 8), wcf(0, 60, 0), "White", 0.45)

	-- ═══════════════════════════════════════════════════════════════════════════
	-- 12. GLADIATOR NPC
	-- ═══════════════════════════════════════════════════════════════════════════
	local MAX_HITS = 3
	local gladDead = false
	local gladKnockedDown = false
	local hitDebounce = {}

	-- Helper: place a gladiator part relative to arena center
	local GY = FLOOR_Y + 1   -- base elevation
	local gladiatorModel = Instance.new("Model")
	gladiatorModel.Name = "ArenaGladiator"
	gladiatorModel.Parent = worldFolder

	local gladiatorRoot = Instance.new("Part")
	gladiatorRoot.Name = "GladiatorRoot"
	gladiatorRoot.Size = Vector3.new(1, 1, 1)
	gladiatorRoot.CFrame = CFrame.new(CX, GY, CZ)
	gladiatorRoot.Transparency = 1
	gladiatorRoot.Anchored = true
	gladiatorRoot.CanCollide = false
	gladiatorRoot.CanTouch = false
	gladiatorRoot.CastShadow = false
	gladiatorRoot.Parent = gladiatorModel
	gladiatorModel.PrimaryPart = gladiatorRoot

	local function registerGladiatorPart(part)
		part:SetAttribute("IsGladiatorPart", true)
		part.Parent = gladiatorModel
		return part
	end

	local function gp(name, size, ox, oy, oz, color, mat, trans, noCollide)
		return registerGladiatorPart(mkp("Glad_"..name, size,
			CFrame.new(CX + ox, GY + oy, CZ + oz),
			color, mat or Enum.Material.SmoothPlastic, trans, noCollide))
	end
	local function gpCF(name, size, cf, color, mat, trans, noCollide)
		return registerGladiatorPart(mkp("Glad_"..name, size, cf, color, mat or Enum.Material.SmoothPlastic, trans, noCollide))
	end

	-- ── GOBLIN BODY ──────────────────────────────────────────────────────────
	-- Dark reddish-brown boots
	gp("BootL",      Vector3.new(6,   2.5, 7),    -3.5, 1.25, 0.5, "Reddish brown")
	gp("BootR",      Vector3.new(6,   2.5, 7),     3.5, 1.25, 0.5, "Reddish brown")
	-- Dark green pants / legs
	gp("PantsL",     Vector3.new(5.5, 7,   6),    -3.5, 7,    0,   "Earth green")
	gp("PantsR",     Vector3.new(5.5, 7,   6),     3.5, 7,    0,   "Earth green")
	-- Wide green torso (bright green skin)
	gp("Torso",      Vector3.new(13,  10,  8),     0,   13,   0,   "Bright green")
	-- Brown leather chest vest
	gp("VestFront",  Vector3.new(13,  9,   1.5),   0,   13.5,-4.7, "Dark orange")
	gp("VestSeamL",  Vector3.new(1,   9,   0.5),  -4.5, 13.5,-5.2, "Reddish brown")
	gp("VestSeamR",  Vector3.new(1,   9,   0.5),   4.5, 13.5,-5.2, "Reddish brown")
	-- Rope belt (prominent coiled bands — signature goblin look)
	gp("BeltRope1",  Vector3.new(14,  3,   9),     0,   9.5,  0,   "Sand yellow")
	gp("BeltRope2",  Vector3.new(13.5,2.5, 8.5),  0,   7.5,  0,   "Cashmere")
	gp("BeltKnot",   Vector3.new(4.5, 3.5, 2),    0,   8.5, -5.1, "Sand yellow")
	gp("BeltNub",    Vector3.new(2.5, 2,   1),     0,   8.5, -6.3, "Cashmere")
	-- Green skin shoulder masses above vest
	gp("ShoulderL",  Vector3.new(5,   4.5, 7.5),  -8,  18.5,  0,  "Bright green")
	gp("ShoulderR",  Vector3.new(5,   4.5, 7.5),   8,  18.5,  0,  "Bright green")
	-- Upper arms (bright green, hanging wide at angle)
	gpCF("ArmUpL",   Vector3.new(5,   9,   5),
		CFrame.new(CX-8.5, GY+14, CZ) * CFrame.Angles(0, 0, math.rad(10)), "Bright green")
	gpCF("ArmUpR",   Vector3.new(5,   9,   5),
		CFrame.new(CX+8.5, GY+14, CZ) * CFrame.Angles(0, 0, math.rad(-10)), "Bright green")
	-- Brown leather bracers on forearms
	gpCF("BracerL",  Vector3.new(5.5, 7,   5.5),
		CFrame.new(CX-9, GY+7, CZ-0.5) * CFrame.Angles(0, 0, math.rad(7)), "Dark orange")
	gpCF("BracerR",  Vector3.new(5.5, 7,   5.5),
		CFrame.new(CX+9, GY+7, CZ-0.5) * CFrame.Angles(0, 0, math.rad(-7)), "Dark orange")
	gpCF("StrapL1",  Vector3.new(5.8, 1.2, 5.8), CFrame.new(CX-9,  GY+10, CZ-0.5), "Reddish brown")
	gpCF("StrapL2",  Vector3.new(5.8, 1.2, 5.8), CFrame.new(CX-9,  GY+5,  CZ-0.5), "Reddish brown")
	gpCF("StrapR1",  Vector3.new(5.8, 1.2, 5.8), CFrame.new(CX+9,  GY+10, CZ-0.5), "Reddish brown")
	gpCF("StrapR2",  Vector3.new(5.8, 1.2, 5.8), CFrame.new(CX+9,  GY+5,  CZ-0.5), "Reddish brown")
	-- Big green hands
	gp("HandL",      Vector3.new(5.5, 4.5, 5),    -9,  2.5,  -0.5, "Bright green")
	gp("HandR",      Vector3.new(5.5, 4.5, 5),     9,  2.5,  -0.5, "Bright green")
	-- Yellow claws (3 per hand, pointing forward)
	for c = -1, 1 do
		gp("ClawL"..c, Vector3.new(1.3, 1.5, 3.5), -9+c*1.8, 0.5, -3.5, "Bright yellow")
		gp("ClawR"..c, Vector3.new(1.3, 1.5, 3.5),  9+c*1.8, 0.5, -3.5, "Bright yellow")
	end
	-- Short thick neck
	gp("Neck",       Vector3.new(6.5, 4,   6.5),   0,  20.5,  0,   "Bright green")

	-- ── HEAD (large, wide, goblin proportions) ───────────────────────────────
	local headPart = gp("HeadSkin", Vector3.new(11, 10, 9), 0, 27, 0, "Bright green")
	headPart.Name = "GladiatorHead"
	-- Heavy overhanging brow ridge
	gp("Brow",       Vector3.new(11,  3,   4),     0,  31.2, -3.5, "Bright green")
	-- Wide cheek masses
	gp("CheekL",     Vector3.new(3,   5,   8),    -7,  26.5,  0,   "Bright green")
	gp("CheekR",     Vector3.new(3,   5,   8),     7,  26.5,  0,   "Bright green")
	-- Lower jaw (wider than skull, goblin-style)
	gp("Jaw",        Vector3.new(10,  4,   9),     0,  23,    0,   "Bright green")
	-- Bright yellow eyes (fierce, angry)
	gp("EyeL",       Vector3.new(3,   2.5, 1),    -2.5,29.5, -5,   "Bright yellow")
	gp("EyeR",       Vector3.new(3,   2.5, 1),     2.5,29.5, -5,   "Bright yellow")
	gp("PupilL",     Vector3.new(1.5, 1.5, 0.6),  -2.5,29.5, -5.7, "Really black")
	gp("PupilR",     Vector3.new(1.5, 1.5, 0.6),   2.5,29.5, -5.7, "Really black")
	-- Dark angry brow marks (slanting inward)
	gp("BrowMarkL",  Vector3.new(2.5, 1.2, 0.8),  -2,  31.8, -5.3, "Dark green")
	gp("BrowMarkR",  Vector3.new(2.5, 1.2, 0.8),   2,  31.8, -5.3, "Dark green")
	-- Wide flat goblin nose
	gp("Nose",       Vector3.new(4,   2.5, 2),     0,  26.5, -5.2, "Lime green")
	gp("NostrilL",   Vector3.new(1.3, 1.3, 0.8),  -1.3,25.3, -6,   "Dark green")
	gp("NostrilR",   Vector3.new(1.3, 1.3, 0.8),   1.3,25.3, -6,   "Dark green")
	-- Wide mouth with visible fangs
	gp("MouthSlot",  Vector3.new(8,   2.2, 0.8),   0,  23.8, -5.5, "Really black")
	gp("FangL",      Vector3.new(2,   2.8, 0.8),  -2.5,24.2, -5.9, "White")
	gp("FangR",      Vector3.new(2,   2.8, 0.8),   2.5,24.2, -5.9, "White")
	gp("FangMid",    Vector3.new(1.5, 2.2, 0.8),   0,  24.2, -5.9, "White")
	gp("LowerLip",   Vector3.new(7,   1.5, 1.5),   0,  22.5, -5.2, "Bright green")

	-- ── WHITE HORNS (curving outward and upward from sides of head) ──────────
	gpCF("HornL1",   Vector3.new(3,   9,  3),
		CFrame.new(CX-7, GY+28, CZ+1) * CFrame.Angles(0, 0, math.rad(-46)) * CFrame.Angles(math.rad(-8), 0, 0),
		"White")
	gpCF("HornL2",   Vector3.new(2.5, 6,  2.5),
		CFrame.new(CX-12, GY+32.5, CZ+1) * CFrame.Angles(0, 0, math.rad(-24)) * CFrame.Angles(math.rad(-5), 0, 0),
		"White")
	gpCF("HornR1",   Vector3.new(3,   9,  3),
		CFrame.new(CX+7, GY+28, CZ+1) * CFrame.Angles(0, 0, math.rad(46)) * CFrame.Angles(math.rad(-8), 0, 0),
		"White")
	gpCF("HornR2",   Vector3.new(2.5, 6,  2.5),
		CFrame.new(CX+12, GY+32.5, CZ+1) * CFrame.Angles(0, 0, math.rad(24)) * CFrame.Angles(math.rad(-5), 0, 0),
		"White")

	-- ── RED MOHAWK (spiky crest shooting straight up from top of head) ────────
	gp("MohawkBase", Vector3.new(4.5, 2.5, 7.5),  0,  34,    0,   "Bright red")
	gpCF("MSpike1",  Vector3.new(3.5, 6.5, 2),
		CFrame.new(CX, GY+38.5, CZ+0.5) * CFrame.Angles(math.rad(-10), 0, 0), "Bright red")
	gpCF("MSpike2",  Vector3.new(3,   8,   1.8),
		CFrame.new(CX, GY+40,   CZ-0.5) * CFrame.Angles(math.rad(-6),  0, 0), "Bright red")
	gpCF("MSpike3",  Vector3.new(2.5, 6,   1.5),
		CFrame.new(CX, GY+38,   CZ-1.5) * CFrame.Angles(math.rad(-4),  0, 0), "Bright red")
	gpCF("MSpike4",  Vector3.new(2,   5,   1.5),
		CFrame.new(CX+0.5, GY+37, CZ+2)   * CFrame.Angles(math.rad(-14), 0, 0), "Bright red")
	gpCF("MSpike5",  Vector3.new(2,   5,   1.5),
		CFrame.new(CX-0.5, GY+37, CZ-2.5) * CFrame.Angles(math.rad(3),  0, 0), "Bright red")

	-- ── RED BEARD / MANE (large flame-like beard, defining goblin feature) ────
	gp("BeardMain",  Vector3.new(8,   9.5, 3),     0,  21,   -5,   "Bright red")
	gp("BeardL1",    Vector3.new(4,   8,   2.5),  -4.5,20,   -4.8, "Bright red")
	gp("BeardR1",    Vector3.new(4,   8,   2.5),   4.5,20,   -4.8, "Bright red")
	gp("BeardL2",    Vector3.new(2.8, 7,   2),    -7,  19,   -4.3, "Bright red")
	gp("BeardR2",    Vector3.new(2.8, 7,   2),     7,  19,   -4.3, "Bright red")
	gpCF("BrdTipL",  Vector3.new(2.5, 5.5, 1.8),
		CFrame.new(CX-6.5, GY+15.5, CZ-4.6) * CFrame.Angles(math.rad(14), 0, 0), "Bright red")
	gpCF("BrdTipR",  Vector3.new(2.5, 5.5, 1.8),
		CFrame.new(CX+6.5, GY+15.5, CZ-4.6) * CFrame.Angles(math.rad(14), 0, 0), "Bright red")
	gpCF("BrdTipC",  Vector3.new(3.5, 6.5, 2),
		CFrame.new(CX,     GY+16,   CZ-5.8) * CFrame.Angles(math.rad(17), 0, 0), "Bright red")

	-- ── GIANT SPIKED MACE (held on left side, bottom near ground) ─────────────
	-- Long wooden handle, angled slightly outward
	gpCF("WepHandle", Vector3.new(3.5, 22, 3.5),
		CFrame.new(CX-14, GY+12, CZ-3) * CFrame.Angles(0, 0, math.rad(8)),
		"Reddish brown", Enum.Material.Wood)
	gpCF("WepGrip1",  Vector3.new(4.8, 2, 4.8),
		CFrame.new(CX-14, GY+5,  CZ-3), "Dark stone grey", Enum.Material.Metal)
	gpCF("WepGrip2",  Vector3.new(4.8, 2, 4.8),
		CFrame.new(CX-15, GY+21, CZ-3), "Dark stone grey", Enum.Material.Metal)
	-- Metal collar connecting handle to head
	gpCF("WepCollar", Vector3.new(5.5, 4, 5.5),
		CFrame.new(CX-17, GY+26, CZ-3), "Dark stone grey", Enum.Material.Metal)
	-- Main club head (large dark metal block)
	gpCF("WepHead",   Vector3.new(16, 12, 12),
		CFrame.new(CX-20, GY+33, CZ-3) * CFrame.Angles(0, 0, math.rad(5)),
		"Dark stone grey", Enum.Material.Metal)
	-- Front face panel (slightly lighter detail)
	gpCF("WepFaceF",  Vector3.new(14, 10, 1),
		CFrame.new(CX-20, GY+33, CZ-9.5) * CFrame.Angles(0, 0, math.rad(5)),
		"Medium stone grey", Enum.Material.Metal)
	-- Spike fins radiating from club head
	gpCF("FinTop",    Vector3.new(4.5, 8, 6),
		CFrame.new(CX-20, GY+41, CZ-3), "Dark stone grey", Enum.Material.Metal)
	gpCF("FinBot",    Vector3.new(4.5, 6, 5),
		CFrame.new(CX-20, GY+26, CZ-3) * CFrame.Angles(0, 0, math.rad(5)),
		"Dark stone grey", Enum.Material.Metal)
	gpCF("FinLeft",   Vector3.new(7, 4.5, 5.5),
		CFrame.new(CX-29, GY+33, CZ-3), "Dark stone grey", Enum.Material.Metal)
	gpCF("FinRight",  Vector3.new(7, 4.5, 5.5),
		CFrame.new(CX-11, GY+34, CZ-3) * CFrame.Angles(0, 0, math.rad(12)),
		"Dark stone grey", Enum.Material.Metal)
	-- Flat blade fins on front face of club
	gpCF("FinFrontT", Vector3.new(14, 4, 3.5),
		CFrame.new(CX-20, GY+38.5, CZ-11) * CFrame.Angles(math.rad(-12), 0, 0),
		"Dark stone grey", Enum.Material.Metal)
	gpCF("FinFrontB", Vector3.new(14, 4, 3.5),
		CFrame.new(CX-20, GY+28,   CZ-11) * CFrame.Angles(math.rad(12),  0, 0),
		"Dark stone grey", Enum.Material.Metal)

	-- ── BillboardGui health bar ──────────────────────────────────────────────
	local billboard = Instance.new("BillboardGui")
	billboard.Size         = UDim2.new(0, 240, 0, 44)
	billboard.StudsOffset  = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop  = false
	billboard.MaxDistance  = 120
	billboard.Parent       = headPart

	local bgFrame = Instance.new("Frame")
	bgFrame.Size                   = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
	bgFrame.BackgroundTransparency = 0.15
	bgFrame.BorderSizePixel        = 0
	bgFrame.Parent                 = billboard
	Instance.new("UICorner", bgFrame).CornerRadius = UDim.new(0, 8)

	local healthBar = Instance.new("Frame")
	healthBar.Name             = "HealthBar"
	healthBar.Size             = UDim2.new(1, -6, 1, -6)
	healthBar.Position         = UDim2.new(0, 3, 0, 3)
	healthBar.BackgroundColor3 = Color3.fromRGB(190, 25, 25)
	healthBar.BorderSizePixel  = 0
	healthBar.Parent           = bgFrame
	Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 6)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size                   = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = "⚔  GOBLIN  ❤ ❤ ❤"
	nameLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
	nameLabel.Font                   = Enum.Font.GothamBlack
	nameLabel.TextSize               = 14
	nameLabel.Parent                 = healthBar

	-- Heart display states
	local STATES = {
		{ bar = 1,    text = "⚔  GOBLIN  ❤ ❤ ❤", barColor = Color3.fromRGB(190, 25, 25) },
		{ bar = 0.66, text = "⚔  GOBLIN  ❤ ❤",    barColor = Color3.fromRGB(200, 90, 20) },
		{ bar = 0.33, text = "⚔  GOBLIN  ❤",       barColor = Color3.fromRGB(180, 160, 10) },
		{ bar = 0,    text = "      DEFEATED",          barColor = Color3.fromRGB(60,  60,  60) },
	}

	-- ── Hit logic ────────────────────────────────────────────────────────────
	local hits = 0

	local function applyState(idx)
		local s = STATES[idx]
		healthBar.Size             = UDim2.new(s.bar, -6, 1, -6)
		healthBar.BackgroundColor3 = s.barColor
		nameLabel.Text             = s.text
	end

	local function flashHead(color)
		headPart.BrickColor = BrickColor.new(color)
		task.delay(0.25, function()
			if headPart.Parent then headPart.BrickColor = BrickColor.new("Bright green") end
		end)
	end

	local function playHeadHitSound()
		local sound = Instance.new("Sound")
		sound.Name = "GladiatorHeadHit"
		sound.SoundId = "rbxassetid://137750395861529"
		sound.Volume = 1
		sound.RollOffMaxDistance = 90
		sound.Parent = headPart
		sound:Play()
		Debris:AddItem(sound, 3)
	end

	local function tweenGladiatorPivot(fromPivot, toPivot, duration)
		local pivotValue = Instance.new("CFrameValue")
		pivotValue.Value = fromPivot

		local pivotConn = pivotValue.Changed:Connect(function(cf)
			if gladiatorModel.Parent then
				gladiatorModel:PivotTo(cf)
			end
		end)

		local tween = TweenService:Create(
			pivotValue,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = toPivot }
		)
		tween:Play()
		tween.Completed:Wait()
		pivotConn:Disconnect()
		pivotValue:Destroy()
	end

	local function knockGladiatorDown()
		if gladDead or gladKnockedDown or not gladiatorModel.Parent then return end
		gladKnockedDown = true

		local standingPivot = gladiatorModel:GetPivot()
		local fallenPivot = standingPivot * CFrame.new(0, -4, 0) * CFrame.Angles(math.rad(78), 0, math.rad(10))
		tweenGladiatorPivot(standingPivot, fallenPivot, 0.35)

		task.wait(3)
		if gladDead or not gladiatorModel.Parent then return end

		tweenGladiatorPivot(gladiatorModel:GetPivot(), standingPivot, 0.45)
		if not gladDead then
			gladKnockedDown = false
		end
	end

	local patrolPoints = {
		CFrame.new(CX - 42, GY, CZ - 24),
		CFrame.new(CX + 36, GY, CZ - 34),
		CFrame.new(CX + 48, GY, CZ + 22),
		CFrame.new(CX - 28, GY, CZ + 42),
		CFrame.new(CX,      GY, CZ),
	}
	local patrolIndex = 1
	local patrolSpeed = 18
	local walkBob = 0
	local moveConnection

	moveConnection = RunService.Heartbeat:Connect(function(dt)
		if gladDead or not gladiatorModel.Parent then
			if moveConnection then
				moveConnection:Disconnect()
				moveConnection = nil
			end
			return
		end
		if gladKnockedDown then return end

		local currentPivot = gladiatorModel:GetPivot()
		local currentPos = currentPivot.Position
		local targetPos = patrolPoints[patrolIndex].Position
		local flatDelta = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z)

		if flatDelta.Magnitude < 2 then
			patrolIndex = patrolIndex % #patrolPoints + 1
			targetPos = patrolPoints[patrolIndex].Position
			flatDelta = Vector3.new(targetPos.X - currentPos.X, 0, targetPos.Z - currentPos.Z)
		end
		if flatDelta.Magnitude < 0.01 then return end

		local step = math.min(flatDelta.Magnitude, patrolSpeed * dt)
		local direction = flatDelta.Unit
		local nextPos = currentPos + direction * step
		walkBob += dt * 8

		local bobY = math.sin(walkBob) * 0.35
		local pivotPos = Vector3.new(nextPos.X, GY + bobY, nextPos.Z)
		local lookAt = Vector3.new(targetPos.X, pivotPos.Y, targetPos.Z)
		gladiatorModel:PivotTo(CFrame.lookAt(pivotPos, lookAt))
	end)

	headPart.Touched:Connect(function(hit)
		if gladDead or gladKnockedDown then return end
		local char   = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end

		-- Must be coming from above: player's HRP above the head center
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if hrp.Position.Y < headPart.Position.Y - 2 then return end

		if hitDebounce[player.UserId] then return end
		hitDebounce[player.UserId] = true

		hits += 1
		playHeadHitSound()
		applyState(hits + 1)
		flashHead(hits >= MAX_HITS and "Dark stone grey" or "Bright red")

		if hits >= MAX_HITS then
			gladDead = true
			-- Darken entire gladiator on death
			for _, p in worldFolder:GetDescendants() do
				if p:IsA("BasePart") and p:GetAttribute("IsGladiatorPart") == true then
					p.BrickColor = BrickColor.new("Dark stone grey")
					p.Material   = Enum.Material.SmoothPlastic
				end
			end
			-- Complete level
			if remValue and remValue.Value > 0 then
				remValue.Value = remValue.Value - 1
			end
		else
			task.spawn(knockGladiatorDown)
		end

		task.delay(1.5, function() hitDebounce[player.UserId] = nil end)
	end)

	if remValue then remValue.Value = TARGET end
	if totValue then totValue.Value = TARGET end
	print("[FightArenaGameplay] Crimson Colosseum built.")
end

buildWorld()
print("[FightArenaGameplay] Ready.")
