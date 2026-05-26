-- EmptyWorld3Builder.server.luau
-- Builds "Volt Abyss" — a sky arena with a deep violet floor and hot-pink grid.
-- Center: cx=460, cz=1500  |  Bounds: X=110..810, Z=1220..1780  |  floorY=80
-- Ramps peak at Y=90 (= floorY+10) to reach the flying dinos.

local WorldFramework = require(script.Parent:WaitForChild("WorldFramework"))

WorldFramework.build({
	name      = "EmptyWorld3",
	cx        = -2090,
	cz        = 1700,
	halfW     = 350,
	halfD     = 280,
	floorY      = 1,
	floorThick  = 3,
	floorColor  = "Dark indigo",
	gridColor   = "Hot pink",
	gridStep    = 16,
	gridAlpha   = 0.14,
	wallH       = 32,
	wallThick   = 1.0,
	wallColor   = "Magenta",
	wallAlpha   = 1,
	containH    = 400,
	northGap    = 0,
	southGap    = 0,
	eastGap     = 25,
	westGap     = 25,
})

-- ── Ramps ──────────────────────────────────────────────────────────────────────
-- Each ramp is a WedgePart rising from floorY to floorY+12 (dino float height).
-- Platforms give players a stable top surface at that height.
-- RISE = 12, RUN = 28 (gentle slope), WIDTH = 22
-- floorY = 80, so ramp bottom surface = 80, top surface = 92.
-- WedgePart center Y = floorY + RISE/2 = 86

local Workspace   = game:GetService("Workspace")
local FLOOR_Y     = 1
local RISE        = 10   -- matches FLOAT_HEIGHT in NPCs
local RUN         = 28
local WIDTH       = 22
local RAMP_COLOR  = BrickColor.new("Dark indigo")
local RAMP_TRIM   = BrickColor.new("Hot pink")
local PLAT_H      = 2    -- platform slab thickness
local PLAT_DEPTH  = 20
local PLAT_COLOR  = BrickColor.new("Dark indigo")

local folder = Instance.new("Folder")
folder.Name = "VoltAbyssRamps"
folder.Parent = Workspace

local function wedge(name, size, cframe, color)
	local w = Instance.new("WedgePart")
	w.Name           = name
	w.Size           = size
	w.CFrame         = cframe
	w.BrickColor     = color
	w.Material       = Enum.Material.SmoothPlastic
	w.Anchored       = true
	w.CanCollide     = true
	w.CastShadow     = false
	w.Parent         = folder
	return w
end

local function platform(name, size, cframe, color)
	local p = Instance.new("Part")
	p.Name           = name
	p.Size           = size
	p.CFrame         = cframe
	p.BrickColor     = color
	p.Material       = Enum.Material.SmoothPlastic
	p.Anchored       = true
	p.CanCollide     = true
	p.CastShadow     = false
	p.Parent         = folder
	return p
end

local function glowTrim(name, size, cframe)
	local t = Instance.new("Part")
	t.Name           = name
	t.Size           = size
	t.CFrame         = cframe
	t.BrickColor     = RAMP_TRIM
	t.Material       = Enum.Material.Neon
	t.Anchored       = true
	t.CanCollide     = false
	t.CastShadow     = false
	t.Transparency   = 0.35
	t.Parent         = folder
	return t
end

-- Ramp center Y: the wedge pivot is at the midpoint of its height
local rampCY = FLOOR_Y + RISE / 2  -- 86

-- Platform surface Y = FLOOR_Y + RISE = 92; platform center Y = 92 + PLAT_H/2 = 93
local platCY = FLOOR_Y + RISE + PLAT_H / 2  -- 93

--[[
  Layout (top-down, 6 ramps + 1 central platform):

        N wall (z=1220)
   [rampNW] ←  → [rampNE]
             ↑
         [centerPlat]
             ↓
   [rampSW] ←  → [rampSE]
        S wall (z=1780)

  Two extra ramps on the east and west sides (mid-Z).
  Ramps face inward so the wedge slope points toward center.
  A WedgePart with default orientation has its slope facing +Z (high end at -Z).
  Rotations:
    Facing south (+Z into arena from north): CFrame.Angles(0,0,0)   — high end toward north wall, low end toward center
    Facing north (-Z): CFrame.Angles(0,math.pi,0)
    Facing east (+X): CFrame.Angles(0,-math.pi/2,0)
    Facing west (-X): CFrame.Angles(0, math.pi/2,0)

  We want players to walk UP toward center, so low end faces center:
    North ramps: slope rises northward → high end at north, face = Angles(0,0,0) — player walks north, reaches top
    South ramps: high end at south → face = Angles(0,math.pi,0)
    West ramp:   high end at west  → face = Angles(0,-math.pi/2,0)
    East ramp:   high end at east  → face = Angles(0, math.pi/2,0)
]]

local cx, cz = -2090, 1700
local northTopZ = cz - 220
local southTopZ = cz + 220
local westTopX = cx - 300
local eastTopX = cx + 300

-- ── North ramps (high end near north wall, Z~1280) ───────────────────────────
for _, xOff in ipairs({ -160, 160 }) do
	local rx = cx + xOff
	local rz = northTopZ + RUN / 2
	wedge("RampN_"..rx, Vector3.new(WIDTH, RISE, RUN),
		CFrame.new(rx, rampCY, rz) * CFrame.Angles(0, math.pi, 0), RAMP_COLOR)
	platform("PlatN_"..rx, Vector3.new(WIDTH, PLAT_H, PLAT_DEPTH),
		CFrame.new(rx, platCY, northTopZ - PLAT_DEPTH / 2), PLAT_COLOR)
	glowTrim("TrimN_"..rx, Vector3.new(WIDTH, 0.4, 0.4),
		CFrame.new(rx, FLOOR_Y + RISE + PLAT_H + 0.2, northTopZ - PLAT_DEPTH))
end

-- ── South ramps (high end near south wall, Z~1720) ───────────────────────────
for _, xOff in ipairs({ -160, 160 }) do
	local rx = cx + xOff
	local rz = southTopZ - RUN / 2
	wedge("RampS_"..rx, Vector3.new(WIDTH, RISE, RUN),
		CFrame.new(rx, rampCY, rz) * CFrame.Angles(0, 0, 0), RAMP_COLOR)
	platform("PlatS_"..rx, Vector3.new(WIDTH, PLAT_H, PLAT_DEPTH),
		CFrame.new(rx, platCY, southTopZ + PLAT_DEPTH / 2), PLAT_COLOR)
	glowTrim("TrimS_"..rx, Vector3.new(WIDTH, 0.4, 0.4),
		CFrame.new(rx, FLOOR_Y + RISE + PLAT_H + 0.2, southTopZ + PLAT_DEPTH))
end

-- ── West ramp (high end near west wall, X~160) ───────────────────────────────
do
	local rx = westTopX + RUN / 2
	wedge("RampW", Vector3.new(WIDTH, RISE, RUN),
		CFrame.new(rx, rampCY, cz) * CFrame.Angles(0, -math.pi / 2, 0), RAMP_COLOR)
	platform("PlatW", Vector3.new(PLAT_DEPTH, PLAT_H, WIDTH),
		CFrame.new(westTopX - PLAT_DEPTH / 2, platCY, cz), PLAT_COLOR)
	glowTrim("TrimW", Vector3.new(0.4, 0.4, WIDTH),
		CFrame.new(westTopX - PLAT_DEPTH, FLOOR_Y + RISE + PLAT_H + 0.2, cz))
end

-- ── East ramp (high end near east wall, X~760) ───────────────────────────────
do
	local rx = eastTopX - RUN / 2
	wedge("RampE", Vector3.new(WIDTH, RISE, RUN),
		CFrame.new(rx, rampCY, cz) * CFrame.Angles(0, math.pi / 2, 0), RAMP_COLOR)
	platform("PlatE", Vector3.new(PLAT_DEPTH, PLAT_H, WIDTH),
		CFrame.new(eastTopX + PLAT_DEPTH / 2, platCY, cz), PLAT_COLOR)
	glowTrim("TrimE", Vector3.new(0.4, 0.4, WIDTH),
		CFrame.new(eastTopX + PLAT_DEPTH, FLOOR_Y + RISE + PLAT_H + 0.2, cz))
end

-- ── Central raised platform ───────────────────────────────────────────────────
local CPW = 40
platform("CenterPlat", Vector3.new(CPW, PLAT_H, CPW),
	CFrame.new(cx, platCY, cz), PLAT_COLOR)
glowTrim("CenterTrimN", Vector3.new(CPW, 0.4, 0.4), CFrame.new(cx, platCY + PLAT_H/2 + 0.2, cz - CPW/2))
glowTrim("CenterTrimS", Vector3.new(CPW, 0.4, 0.4), CFrame.new(cx, platCY + PLAT_H/2 + 0.2, cz + CPW/2))
glowTrim("CenterTrimW", Vector3.new(0.4, 0.4, CPW), CFrame.new(cx - CPW/2, platCY + PLAT_H/2 + 0.2, cz))
glowTrim("CenterTrimE", Vector3.new(0.4, 0.4, CPW), CFrame.new(cx + CPW/2, platCY + PLAT_H/2 + 0.2, cz))

local CRRUN = 24
for _, def in ipairs({
	{ name="CN", dz=-CPW/2-CRRUN/2, rot=CFrame.Angles(0, 0, 0)           },
	{ name="CS", dz= CPW/2+CRRUN/2, rot=CFrame.Angles(0, math.pi, 0)     },
	{ name="CW", dx=-CPW/2-CRRUN/2, rot=CFrame.Angles(0, math.pi/2, 0)   },
	{ name="CE", dx= CPW/2+CRRUN/2, rot=CFrame.Angles(0,-math.pi/2, 0)   },
}) do
	local rx = cx + (def.dx or 0)
	local rz = cz + (def.dz or 0)
	wedge("CRamp"..def.name, Vector3.new(CPW, RISE, CRRUN),
		CFrame.new(rx, rampCY, rz) * def.rot, RAMP_COLOR)
end
