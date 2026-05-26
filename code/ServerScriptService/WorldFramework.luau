--[[
    WorldFramework.luau  (ModuleScript)

    Builds the standard shell for any world:
      • Galactic-style neon-grid floor
      • Four solid cube walls (full height) around the perimeter
      • Optional entrance/exit gaps in the north/south walls

    cfg fields (all required unless marked optional):
        name        string   – folder name, e.g. "EmptyWorld1"
        cx, cz      number   – world center in world-space
        halfW       number   – half-width  (X radius)
        halfD       number   – half-depth  (Z radius)

    optional cfg fields:
        floorY          number   default 0        – Y of the top surface of the floor slab
        floorThick      number   default 2        – thickness of the floor slab
        floorColor      string   default "Dark indigo"
        gridColor       string   default "Cyan"
        gridStep        number   default 14       – neon grid line spacing (studs)
        gridAlpha       number   default 0.25     – grid neon transparency (0=opaque)
        wallH           number   default 20       – visible perimeter wall height
        wallThick       number   default 0.8      – wall thickness
        wallColor       string   default "Dark indigo"
        wallAlpha       number   default 0.45     – visible wall transparency
        containH        number   default 350      – invisible containment wall height
        northGap        number   default 0        – half-width of open gap in north wall (0 = closed)
        southGap        number   default 0        – half-width of open gap in south wall (0 = closed)

    Returns the Folder that contains all parts.
]]

local WorldFramework = {}

local function makePart(folder, name, size, pos, color, mat, trans, noCollide)
	local p = Instance.new("Part")
	p.Name            = name
	p.Size            = size
	p.Position        = pos
	p.BrickColor      = BrickColor.new(color)
	p.Material        = mat or Enum.Material.SmoothPlastic
	p.Anchored        = true
	p.CanCollide      = not noCollide
	p.CastShadow      = false
	p.TopSurface      = Enum.SurfaceType.Smooth
	p.BottomSurface   = Enum.SurfaceType.Smooth
	p.Transparency    = trans or 0
	p.Parent          = folder
	return p
end

-- Builds two wall segments split around a central gap.
-- If gap == 0, builds one full-width wall instead.
local function wallWithGap(folder, name, length, thick, wallH, wallColor, wallAlpha, cx, y, z, axis, gap, containH)
	local G    = 1  -- ground offset for wall mid-point calculation
	local half = length / 2

	local function seg(segName, segLen, segCX)
		if segLen <= 0 then return end
		local sz, pos
		if axis == "X" then  -- wall faces Z; runs along X
			sz  = Vector3.new(segLen, wallH, thick)
			pos = Vector3.new(segCX, y + wallH / 2, z)
		else  -- axis == "Z"; wall faces X; runs along Z
			sz  = Vector3.new(thick, wallH, segLen)
			pos = Vector3.new(z, y + wallH / 2, segCX)  -- z here is actually the X position
		end
		makePart(folder, segName, sz, pos, wallColor, wallMat, wallAlpha)

		-- invisible containment wall above
		local csz, cpos
		if axis == "X" then
			csz  = Vector3.new(segLen, containH, thick)
			cpos = Vector3.new(segCX, y + containH / 2, z)
		else
			csz  = Vector3.new(thick, containH, segLen)
			cpos = Vector3.new(z, y + containH / 2, segCX)
		end
		makePart(folder, segName .. "Contain", csz, cpos, "Really black", Enum.Material.SmoothPlastic, 1)
	end

	if gap <= 0 then
		seg(name, length, cx)
	else
		local leftLen  = half - gap
		local rightLen = half - gap
		seg(name .. "L", leftLen,  cx - (gap + leftLen / 2))
		seg(name .. "R", rightLen, cx + (gap + rightLen / 2))
	end
end

function WorldFramework.build(cfg)
	-- ── defaults ──────────────────────────────────────────────────────────────
	local cx         = cfg.cx
	local cz         = cfg.cz
	local hw         = cfg.halfW
	local hd         = cfg.halfD
	local floorY     = cfg.floorY      or 0
	local floorThick = cfg.floorThick  or 2
	local floorColor = cfg.floorColor  or "Dark indigo"
	local gridColor  = cfg.gridColor   or "Cyan"
	local gridStep   = cfg.gridStep    or 14
	local gridAlpha  = cfg.gridAlpha   or 0.25
	local wallH      = cfg.wallH       or 20
	local wallThick  = cfg.wallThick   or 0.8
	local wallColor  = cfg.wallColor   or "Dark indigo"
	local wallAlpha  = cfg.wallAlpha   or 0.45
	local wallMat    = cfg.wallMat     or Enum.Material.Neon
	local containH   = cfg.containH    or 350
	local northGap   = cfg.northGap    or 0
	local southGap   = cfg.southGap    or 0
	local eastGap    = cfg.eastGap     or 0
	local westGap    = cfg.westGap     or 0

	local fullW = hw * 2
	local fullD = hd * 2

	local minX = cx - hw
	local maxX = cx + hw
	local minZ = cz - hd
	local maxZ = cz + hd

	-- ── folder ────────────────────────────────────────────────────────────────
	local folder = Instance.new("Folder")
	folder.Name   = cfg.name
	folder.Parent = workspace

	-- ── floor slab ────────────────────────────────────────────────────────────
	makePart(folder, "Floor",
		Vector3.new(fullW, floorThick, fullD),
		Vector3.new(cx, floorY - floorThick / 2, cz),
		floorColor)

	-- ── neon grid overlay ─────────────────────────────────────────────────────
	local gridY = floorY + 0.06
	for xi = minX, maxX, gridStep do
		makePart(folder, "GridZ",
			Vector3.new(0.2, 0.1, fullD),
			Vector3.new(xi, gridY, cz),
			gridColor, Enum.Material.Neon, gridAlpha, true)
	end
	for zi = minZ, maxZ, gridStep do
		makePart(folder, "GridX",
			Vector3.new(fullW, 0.1, 0.2),
			Vector3.new(cx, gridY, zi),
			gridColor, Enum.Material.Neon, gridAlpha, true)
	end

	-- ── perimeter walls ───────────────────────────────────────────────────────
	-- North wall (minZ face) — gap for entrance if northGap > 0
	wallWithGap(folder, "WallN", fullW, wallThick, wallH, wallColor, wallAlpha,
		cx, floorY, minZ, "X", northGap, containH)

	-- South wall (maxZ face) — gap for exit if southGap > 0
	wallWithGap(folder, "WallS", fullW, wallThick, wallH, wallColor, wallAlpha,
		cx, floorY, maxZ, "X", southGap, containH)

	-- East wall (maxX face) — always closed
	-- reuse wallWithGap with axis "Z": "z" param = X position, "cx" param = center Z
	wallWithGap(folder, "WallE", fullD, wallThick, wallH, wallColor, wallAlpha,
		cz, floorY, maxX, "Z", eastGap, containH)

	-- West wall (minX face) — always closed
	wallWithGap(folder, "WallW", fullD, wallThick, wallH, wallColor, wallAlpha,
		cz, floorY, minX, "Z", westGap, containH)

	print(("[WorldFramework] Built '%s'  bounds X[%d,%d] Z[%d,%d]"):format(
		cfg.name, minX, maxX, minZ, maxZ))

	return folder
end

return WorldFramework
