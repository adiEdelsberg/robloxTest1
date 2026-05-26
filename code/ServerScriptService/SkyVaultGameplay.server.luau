-- SkyVaultGameplay.server.luau  (World 21 — Sky Vault)
-- Jump tower, transparent walls, open balconies.
-- East wall: bridge to Neon Rift.  West wall: bridge to Storm Tower.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local WORLD_NAME = "Sky Vault"

-- ── Geometry ──────────────────────────────────────────────────────────────────
local CX      = -3500
local CZ      = 1700
local FLOOR_Y = 1
local HW      = 30      -- half interior width  (60 wide)
local HD      = 30      -- half interior depth  (60 deep)
local WALL_H  = 200
local WALL_T  = 4
local WALL_TRANS = 0.65

-- Bridge door openings (east & west Z-walls, centred at CZ)
local DOOR_HALF = 25   -- half-width along Z
local DOOR_H    = 12   -- height of opening

-- Balcony config
local BAL_W      = 50
local BAL_EXTEND = 30
local BAL_H      = 1.5
local BAL_DOOR_H = 16  -- hole height in wall

local FINISH_Y = FLOOR_Y + WALL_H - 10

local TIERS = {
	{ y = FLOOR_Y + 30,  launchV = 82,  color = "Lime green"    },
	{ y = FLOOR_Y + 68,  launchV = 84,  color = "Cyan"          },
	{ y = FLOOR_Y + 108, launchV = 86,  color = "Hot pink"      },
	{ y = FLOOR_Y + 148, launchV = 88,  color = "Bright orange" },
	{ y = FLOOR_Y + 185, launchV = 90,  color = "Bright yellow" },
}

-- Balconies alternate WE / NS pairs
local BALCONIES = {
	{ y = FLOOR_Y + 49,  wall = "NS" },
	{ y = FLOOR_Y + 88,  wall = "WE" },
	{ y = FLOOR_Y + 128, wall = "NS" },
	{ y = FLOOR_Y + 167, wall = "WE" },
}

-- High-power boost pads on the opposite wall from each balcony
local BOOST_PADS = {
	{ y = FLOOR_Y + 52,  wall = "WE", launchV = 115, color = "Magenta" },
	{ y = FLOOR_Y + 91,  wall = "NS", launchV = 118, color = "Magenta" },
	{ y = FLOOR_Y + 131, wall = "WE", launchV = 121, color = "Magenta" },
	{ y = FLOOR_Y + 170, wall = "NS", launchV = 125, color = "Magenta" },
}

local JUMPER_TYPES = {
	{ color = "Lime green",     launchV = 82  },
	{ color = "Cyan",           launchV = 96  },
	{ color = "Hot pink",       launchV = 110 },
	{ color = "Bright orange",  launchV = 124 },
	{ color = "Bright yellow",  launchV = 138 },
	{ color = "Magenta",        launchV = 152 },
}

-- ── GameEvents ─────────────────────────────────────────────────────────────────
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)

local remValue = gameEvents and gameEvents:FindFirstChild("SkyVaultRemaining")
if not remValue then
	remValue = Instance.new("NumberValue")
	remValue.Name   = "SkyVaultRemaining"
	remValue.Value  = 0
	remValue.Parent = gameEvents or ReplicatedStorage
end

local totValue = gameEvents and gameEvents:FindFirstChild("SkyVaultTotal")
if not totValue then
	totValue = Instance.new("NumberValue")
	totValue.Name   = "SkyVaultTotal"
	totValue.Value  = 0
	totValue.Parent = gameEvents or ReplicatedStorage
end

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET  = (Balance.StageTargets and Balance.StageTargets.SkyVault) or 1

local playerScored
task.spawn(function() playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30) end)

-- ── State ──────────────────────────────────────────────────────────────────────
local alive          = false
local worldFolder    = nil
local finishDebounce = {}
local padDebounce    = {}

-- ── Build helpers ──────────────────────────────────────────────────────────────
local STRUCT_COLOR = "Dark stone grey"
local STRUCT_MAT   = Enum.Material.Metal

local function makePart(name, size, pos, color, mat, trans, noCollide)
	local p = Instance.new("Part")
	p.Name          = name
	p.Size          = size
	p.Position      = pos
	p.BrickColor    = BrickColor.new(color or STRUCT_COLOR)
	p.Material      = mat or STRUCT_MAT
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

local function neon(name, size, pos, color)
	return makePart(name, size, pos, color, Enum.Material.Neon, 0.05, true)
end

-- ── Wall builder with rectangular holes ────────────────────────────────────────
-- isZWall=true  → wall runs along Z (W/E), parts sized (WALL_T, h, len)
-- isZWall=false → wall runs along X (N/S), parts sized (len, h, WALL_T)
-- holes = { {alongMin, alongMax, yBot, yTop}, … }
local function buildWall(isZWall, fixedCoord, alongMin, alongMax, yMin, yMax, holes)
	local yPts = { yMin, yMax }
	for _, h in ipairs(holes) do
		table.insert(yPts, h.yBot)
		table.insert(yPts, h.yTop)
	end
	table.sort(yPts)
	local uy = { yPts[1] }
	for i = 2, #yPts do
		if yPts[i] - uy[#uy] > 0.02 then table.insert(uy, yPts[i]) end
	end

	for bi = 1, #uy - 1 do
		local yBot = uy[bi]
		local yTop = uy[bi + 1]
		local yH   = yTop - yBot
		local yMid = (yBot + yTop) / 2

		local active = {}
		for _, h in ipairs(holes) do
			if h.yBot <= yBot + 0.01 and h.yTop >= yTop - 0.01 then
				table.insert(active, { h.alongMin, h.alongMax })
			end
		end
		table.sort(active, function(a, b) return a[1] < b[1] end)

		local segs = {}
		local cur = alongMin
		for _, hole in ipairs(active) do
			if hole[1] > cur then table.insert(segs, { cur, hole[1] }) end
			cur = math.max(cur, hole[2])
		end
		if cur < alongMax then table.insert(segs, { cur, alongMax }) end

		for _, seg in ipairs(segs) do
			local len = seg[2] - seg[1]
			if len < 0.1 then continue end
			local mid = seg[1] + len / 2
			if isZWall then
				makePart("Wall", Vector3.new(WALL_T, yH, len), Vector3.new(fixedCoord, yMid, mid), nil, nil, WALL_TRANS)
			else
				makePart("Wall", Vector3.new(len, yH, WALL_T), Vector3.new(mid, yMid, fixedCoord), nil, nil, WALL_TRANS)
			end
		end
	end
end

-- ── Balcony builder (four wall directions) ─────────────────────────────────────
-- `along` = Z coordinate for W/E walls; X coordinate for N/S walls
-- `holeYBot` = bottom Y of the wall hole (balcony floor is flush with it)
local function makeBalcony(wall, along, holeYBot)
	local slabCY   = holeYBot + BAL_H / 2
	local BARRIER_H = 5
	local BARRIER_T = 1.5
	local barY = holeYBot + BAL_H + BARRIER_H / 2

	if wall == "W" then
		local extX   = CX - HW - WALL_T
		local outerX = extX - BAL_EXTEND
		local slabCX = extX - BAL_EXTEND / 2
		makePart("BalFloor", Vector3.new(BAL_EXTEND, BAL_H, BAL_W),
			Vector3.new(slabCX, slabCY, along), "Sand blue", Enum.Material.SmoothPlastic)
		makePart("BalBarF", Vector3.new(BARRIER_T, BARRIER_H, BAL_W + BARRIER_T * 2),
			Vector3.new(outerX - BARRIER_T / 2, barY, along), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarN", Vector3.new(BAL_EXTEND, BARRIER_H, BARRIER_T),
			Vector3.new(slabCX, barY, along - BAL_W / 2 - BARRIER_T / 2), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarS", Vector3.new(BAL_EXTEND, BARRIER_H, BARRIER_T),
			Vector3.new(slabCX, barY, along + BAL_W / 2 + BARRIER_T / 2), STRUCT_COLOR, STRUCT_MAT)
		neon("BalCapF", Vector3.new(0.4, 0.4, BAL_W + BARRIER_T * 2 + 0.4),
			Vector3.new(outerX - BARRIER_T / 2, barY + BARRIER_H / 2 + 0.2, along), "Cyan")
		neon("BalCapN", Vector3.new(BAL_EXTEND + 0.4, 0.4, 0.4),
			Vector3.new(slabCX, barY + BARRIER_H / 2 + 0.2, along - BAL_W / 2), "Cyan")
		neon("BalCapS", Vector3.new(BAL_EXTEND + 0.4, 0.4, 0.4),
			Vector3.new(slabCX, barY + BARRIER_H / 2 + 0.2, along + BAL_W / 2), "Cyan")

	elseif wall == "E" then
		local extX   = CX + HW + WALL_T
		local outerX = extX + BAL_EXTEND
		local slabCX = extX + BAL_EXTEND / 2
		makePart("BalFloor", Vector3.new(BAL_EXTEND, BAL_H, BAL_W),
			Vector3.new(slabCX, slabCY, along), "Sand blue", Enum.Material.SmoothPlastic)
		makePart("BalBarF", Vector3.new(BARRIER_T, BARRIER_H, BAL_W + BARRIER_T * 2),
			Vector3.new(outerX + BARRIER_T / 2, barY, along), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarN", Vector3.new(BAL_EXTEND, BARRIER_H, BARRIER_T),
			Vector3.new(slabCX, barY, along - BAL_W / 2 - BARRIER_T / 2), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarS", Vector3.new(BAL_EXTEND, BARRIER_H, BARRIER_T),
			Vector3.new(slabCX, barY, along + BAL_W / 2 + BARRIER_T / 2), STRUCT_COLOR, STRUCT_MAT)
		neon("BalCapF", Vector3.new(0.4, 0.4, BAL_W + BARRIER_T * 2 + 0.4),
			Vector3.new(outerX + BARRIER_T / 2, barY + BARRIER_H / 2 + 0.2, along), "Cyan")
		neon("BalCapN", Vector3.new(BAL_EXTEND + 0.4, 0.4, 0.4),
			Vector3.new(slabCX, barY + BARRIER_H / 2 + 0.2, along - BAL_W / 2), "Cyan")
		neon("BalCapS", Vector3.new(BAL_EXTEND + 0.4, 0.4, 0.4),
			Vector3.new(slabCX, barY + BARRIER_H / 2 + 0.2, along + BAL_W / 2), "Cyan")

	elseif wall == "N" then
		local extZ   = CZ - HD - WALL_T
		local outerZ = extZ - BAL_EXTEND
		local slabCZ = extZ - BAL_EXTEND / 2
		makePart("BalFloor", Vector3.new(BAL_W, BAL_H, BAL_EXTEND),
			Vector3.new(along, slabCY, slabCZ), "Sand blue", Enum.Material.SmoothPlastic)
		makePart("BalBarF", Vector3.new(BAL_W + BARRIER_T * 2, BARRIER_H, BARRIER_T),
			Vector3.new(along, barY, outerZ - BARRIER_T / 2), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarW", Vector3.new(BARRIER_T, BARRIER_H, BAL_EXTEND),
			Vector3.new(along - BAL_W / 2 - BARRIER_T / 2, barY, slabCZ), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarE", Vector3.new(BARRIER_T, BARRIER_H, BAL_EXTEND),
			Vector3.new(along + BAL_W / 2 + BARRIER_T / 2, barY, slabCZ), STRUCT_COLOR, STRUCT_MAT)
		neon("BalCapF", Vector3.new(BAL_W + BARRIER_T * 2 + 0.4, 0.4, 0.4),
			Vector3.new(along, barY + BARRIER_H / 2 + 0.2, outerZ - BARRIER_T / 2), "Cyan")
		neon("BalCapW", Vector3.new(0.4, 0.4, BAL_EXTEND + 0.4),
			Vector3.new(along - BAL_W / 2, barY + BARRIER_H / 2 + 0.2, slabCZ), "Cyan")
		neon("BalCapE", Vector3.new(0.4, 0.4, BAL_EXTEND + 0.4),
			Vector3.new(along + BAL_W / 2, barY + BARRIER_H / 2 + 0.2, slabCZ), "Cyan")

	elseif wall == "S" then
		local extZ   = CZ + HD + WALL_T
		local outerZ = extZ + BAL_EXTEND
		local slabCZ = extZ + BAL_EXTEND / 2
		makePart("BalFloor", Vector3.new(BAL_W, BAL_H, BAL_EXTEND),
			Vector3.new(along, slabCY, slabCZ), "Sand blue", Enum.Material.SmoothPlastic)
		makePart("BalBarF", Vector3.new(BAL_W + BARRIER_T * 2, BARRIER_H, BARRIER_T),
			Vector3.new(along, barY, outerZ + BARRIER_T / 2), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarW", Vector3.new(BARRIER_T, BARRIER_H, BAL_EXTEND),
			Vector3.new(along - BAL_W / 2 - BARRIER_T / 2, barY, slabCZ), STRUCT_COLOR, STRUCT_MAT)
		makePart("BalBarE", Vector3.new(BARRIER_T, BARRIER_H, BAL_EXTEND),
			Vector3.new(along + BAL_W / 2 + BARRIER_T / 2, barY, slabCZ), STRUCT_COLOR, STRUCT_MAT)
		neon("BalCapF", Vector3.new(BAL_W + BARRIER_T * 2 + 0.4, 0.4, 0.4),
			Vector3.new(along, barY + BARRIER_H / 2 + 0.2, outerZ + BARRIER_T / 2), "Cyan")
		neon("BalCapW", Vector3.new(0.4, 0.4, BAL_EXTEND + 0.4),
			Vector3.new(along - BAL_W / 2, barY + BARRIER_H / 2 + 0.2, slabCZ), "Cyan")
		neon("BalCapE", Vector3.new(0.4, 0.4, BAL_EXTEND + 0.4),
			Vector3.new(along + BAL_W / 2, barY + BARRIER_H / 2 + 0.2, slabCZ), "Cyan")
	end
end

-- ── Jump-pad factories ──────────────────────────────────────────────────────────
local PAD_W       = 16
local PAD_PROTRUDE = 10
local PAD_H       = 1.5
local LAUNCH_FLOOR = 80

local function makeWallPad(cx, cy, cz, launchV, padColor)
	local ledge = makePart("WallPad", Vector3.new(PAD_W, PAD_H, PAD_PROTRUDE),
		Vector3.new(cx, cy, cz), STRUCT_COLOR, STRUCT_MAT, 0)
	local typeIndex = 1
	local currentType = JUMPER_TYPES[typeIndex]
	local strip = neon("PadGlow", Vector3.new(PAD_W, 0.2, PAD_PROTRUDE),
		Vector3.new(cx, cy + PAD_H / 2 + 0.1, cz), currentType.color)
	local sp = Instance.new("Sparkles")
	sp.SparkleColor = BrickColor.new(currentType.color).Color ; sp.Parent = strip
	local function applyType()
		currentType = JUMPER_TYPES[typeIndex]
		if strip.Parent then
			strip.BrickColor = BrickColor.new(currentType.color)
		end
		if sp.Parent then
			sp.SparkleColor = BrickColor.new(currentType.color).Color
		end
	end
	local function cycleType()
		typeIndex = (typeIndex % #JUMPER_TYPES) + 1
		applyType()
	end
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
		if not player then return end
		if padDebounce[player] then return end
		padDebounce[player] = true
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local usedType = currentType
		if hrp then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(0, usedType.launchV, 0)
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.P = math.huge ; bv.Parent = hrp
			Debris:AddItem(bv, 0.12)
		end
		strip.BrickColor = BrickColor.new("White")
		task.delay(0.12, function()
			if strip.Parent then
				cycleType()
			end
		end)
		task.delay(0.15, function() padDebounce[player] = nil end)
	end)
end

local function makeFloorPad(cx, cz, padColor)
	local padY = FLOOR_Y + 0.3
	local pad = makePart("FloorPad", Vector3.new(7, 0.6, 7), Vector3.new(cx, padY, cz), STRUCT_COLOR, STRUCT_MAT, 0)
	local typeIndex = 1
	local currentType = JUMPER_TYPES[typeIndex]
	local strip = neon("FloorPadGlow", Vector3.new(7, 0.2, 7), Vector3.new(cx, padY + 0.4, cz), padColor)
	local sp = Instance.new("Sparkles")
	strip.BrickColor = BrickColor.new(currentType.color)
	sp.SparkleColor = BrickColor.new(currentType.color).Color ; sp.Parent = strip
	local function applyType()
		currentType = JUMPER_TYPES[typeIndex]
		if strip.Parent then
			strip.BrickColor = BrickColor.new(currentType.color)
		end
		if sp.Parent then
			sp.SparkleColor = BrickColor.new(currentType.color).Color
		end
	end
	local function cycleType()
		typeIndex = (typeIndex % #JUMPER_TYPES) + 1
		applyType()
	end
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
	pad.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then char = hit.Parent.Parent ; player = Players:GetPlayerFromCharacter(char) end
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player then return end
		if padDebounce[player] then return end
		padDebounce[player] = true
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local usedType = currentType
		if hrp then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(0, usedType.launchV, 0)
			bv.MaxForce = Vector3.new(0, math.huge, 0)
			bv.P = math.huge ; bv.Parent = hrp
			Debris:AddItem(bv, 0.12)
		end
		strip.BrickColor = BrickColor.new("White")
		task.delay(0.12, function()
			if strip.Parent then
				cycleType()
			end
		end)
		task.delay(0.15, function() padDebounce[player] = nil end)
	end)
end

-- ── Build the tower ─────────────────────────────────────────────────────────────
local function buildTower()
	worldFolder        = Instance.new("Folder")
	worldFolder.Name   = "SkyVaultWorld"
	worldFolder.Parent = workspace

	-- Floor
	makePart("Floor", Vector3.new(HW * 2, 4, HD * 2), Vector3.new(CX, FLOOR_Y - 2, CZ))

	-- Floor pads — 5 spots
	local fp = 14
	for _, dx in { -fp, fp } do
		for _, dz in { -fp, fp } do
			makeFloorPad(CX + dx, CZ + dz, "Lime green")
		end
	end
	makeFloorPad(CX, CZ, "Lime green")

	-- ── Hole lists per wall ──────────────────────────────────────────────────────
	local wHoles, eHoles, nHoles, sHoles = {}, {}, {}, {}
	local halfW = BAL_W / 2

	-- Bridge doors on east (Neon Rift) and west (Storm Tower) walls
	local eDoor = { alongMin = CZ - DOOR_HALF, alongMax = CZ + DOOR_HALF, yBot = FLOOR_Y, yTop = FLOOR_Y + DOOR_H }
	local wDoor = { alongMin = CZ - DOOR_HALF, alongMax = CZ + DOOR_HALF, yBot = FLOOR_Y, yTop = FLOOR_Y + DOOR_H }
	table.insert(eHoles, eDoor)
	table.insert(wHoles, wDoor)

	-- Balcony holes
	for _, bal in ipairs(BALCONIES) do
		if bal.wall == "WE" then
			local h = { alongMin = CZ - halfW, alongMax = CZ + halfW, yBot = bal.y, yTop = bal.y + BAL_DOOR_H }
			table.insert(eHoles, h)
			table.insert(wHoles, { alongMin = h.alongMin, alongMax = h.alongMax, yBot = h.yBot, yTop = h.yTop })
		else -- NS
			local h = { alongMin = CX - halfW, alongMax = CX + halfW, yBot = bal.y, yTop = bal.y + BAL_DOOR_H }
			table.insert(nHoles, h)
			table.insert(sHoles, { alongMin = h.alongMin, alongMax = h.alongMax, yBot = h.yBot, yTop = h.yTop })
		end
	end

	-- ── Build walls ──────────────────────────────────────────────────────────────
	local zMin = CZ - HD - WALL_T
	local zMax = CZ + HD + WALL_T
	local xMin = CX - HW - WALL_T
	local xMax = CX + HW + WALL_T
	local yMin = FLOOR_Y
	local yMax = FLOOR_Y + WALL_H

	buildWall(true,  CX - HW - WALL_T / 2, zMin, zMax, yMin, yMax, wHoles)  -- West
	buildWall(true,  CX + HW + WALL_T / 2, zMin, zMax, yMin, yMax, eHoles)  -- East
	buildWall(false, CZ - HD - WALL_T / 2, xMin, xMax, yMin, yMax, nHoles)  -- North
	buildWall(false, CZ + HD + WALL_T / 2, xMin, xMax, yMin, yMax, sHoles)  -- South

	-- ── Gold ring at open top ────────────────────────────────────────────────────
	local ringY = FLOOR_Y + WALL_H + 1
	neon("RingN", Vector3.new(HW*2+WALL_T*2, 1, 0.5), Vector3.new(CX, ringY, CZ-HD-WALL_T/2), "Bright yellow")
	neon("RingS", Vector3.new(HW*2+WALL_T*2, 1, 0.5), Vector3.new(CX, ringY, CZ+HD+WALL_T/2), "Bright yellow")
	neon("RingW", Vector3.new(0.5, 1, HD*2+WALL_T*2), Vector3.new(CX-HW-WALL_T/2, ringY, CZ), "Bright yellow")
	neon("RingE", Vector3.new(0.5, 1, HD*2+WALL_T*2), Vector3.new(CX+HW+WALL_T/2, ringY, CZ), "Bright yellow")

	-- ── Balconies ────────────────────────────────────────────────────────────────
	for _, bal in ipairs(BALCONIES) do
		if bal.wall == "WE" then
			makeBalcony("W", CZ, bal.y)
			makeBalcony("E", CZ, bal.y)
		else
			makeBalcony("N", CX, bal.y)
			makeBalcony("S", CX, bal.y)
		end
	end

	-- ── Jump pads ────────────────────────────────────────────────────────────────
	-- Odd tiers: W & E walls.  Even tiers: N & S walls.
	local INNER = PAD_PROTRUDE / 2
	for i, tier in ipairs(TIERS) do
		local py = tier.y + PAD_H / 2
		if i % 2 == 1 then
			local wX = CX - HW + INNER
			local eX = CX + HW - INNER
			for _, zOff in { -16, 0, 16 } do
				makeWallPad(wX, py, CZ + zOff, tier.launchV, tier.color)
				makeWallPad(eX, py, CZ - zOff, tier.launchV, tier.color)
			end
		else
			local nZ = CZ - HD + INNER
			local sZ = CZ + HD - INNER
			for _, xOff in { -16, 0, 16 } do
				makeWallPad(CX + xOff, py, nZ, tier.launchV, tier.color)
				makeWallPad(CX - xOff, py, sZ, tier.launchV, tier.color)
			end
		end
	end

	-- Boost pads
	for _, bp in ipairs(BOOST_PADS) do
		local py = bp.y + PAD_H / 2
		if bp.wall == "WE" then
			local wX = CX - HW + INNER
			local eX = CX + HW - INNER
			for _, zOff in { -10, 10 } do
				makeWallPad(wX, py, CZ + zOff, bp.launchV, bp.color)
				makeWallPad(eX, py, CZ - zOff, bp.launchV, bp.color)
			end
		else
			local nZ = CZ - HD + INNER
			local sZ = CZ + HD - INNER
			for _, xOff in { -10, 10 } do
				makeWallPad(CX + xOff, py, nZ, bp.launchV, bp.color)
				makeWallPad(CX - xOff, py, sZ, bp.launchV, bp.color)
			end
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
		if not player then return end
		if player:GetAttribute("SkyDescentBoundsActive") then return end
		if finishDebounce[player] then return end
		finishDebounce[player] = true
		remValue.Value = math.max(0, remValue.Value - 1)
		if playerScored then playerScored:Fire(player, WORLD_NAME) end
		task.delay(6, function() finishDebounce[player] = nil end)
	end)

	-- ── Sign ──────────────────────────────────────────────────────────────────────
	local signPart = makePart("SignPart", Vector3.new(26, 7, 0.4),
		Vector3.new(CX, FLOOR_Y + 14, CZ + HD + WALL_T + 0.3))
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TowerSign" ; gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud ; gui.PixelsPerStud = 30
	gui.LightInfluence = 0 ; gui.Parent = signPart
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1,0,1,0) ; bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
	bg.BackgroundTransparency = 0.05 ; bg.BorderSizePixel = 0 ; bg.Parent = gui
	local l1 = Instance.new("TextLabel")
	l1.Size = UDim2.new(1,0,0.5,0) ; l1.Position = UDim2.new(0,0,0.05,0)
	l1.BackgroundTransparency = 1 ; l1.Text = "SKY VAULT"
	l1.TextColor3 = Color3.fromRGB(255,215,0) ; l1.TextStrokeTransparency = 0.3
	l1.Font = Enum.Font.GothamBlack ; l1.TextSize = 30 ; l1.Parent = bg
	local l2 = Instance.new("TextLabel")
	l2.Size = UDim2.new(1,0,0.38,0) ; l2.Position = UDim2.new(0,0,0.58,0)
	l2.BackgroundTransparency = 1 ; l2.Text = "CLIMB THE WALLS — REACH THE TOP"
	l2.TextColor3 = Color3.fromRGB(200,230,255) ; l2.TextStrokeTransparency = 0.5
	l2.Font = Enum.Font.GothamBold ; l2.TextSize = 17 ; l2.Parent = bg
end

-- ── World lifecycle ─────────────────────────────────────────────────────────────
local function destroyTower()
	if worldFolder and worldFolder.Parent then worldFolder:Destroy() end
	worldFolder = nil
	table.clear(finishDebounce)
	table.clear(padDebounce)
end

local function doSpawnAll()
	if alive then return end
	alive = true
	remValue.Value = TARGET
	totValue.Value = TARGET
	buildTower()
end

local function doDespawnAll()
	if not alive then return end
	alive = false
	destroyTower()
	remValue.Value = TARGET
end

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName == WORLD_NAME or wName == "SkyVault" then
			doDespawnAll() ; task.wait(0.4) ; doSpawnAll()
		elseif alive then
			doDespawnAll()
		end
	end)
end)

task.spawn(function()
	local activeName = gameEvents:WaitForChild("ActiveWorldName", 30)
	if not activeName then doSpawnAll() return end
	if activeName.Value == WORLD_NAME or activeName.Value == "SkyVault" then doSpawnAll() end
	activeName.Changed:Connect(function(val)
		if val == WORLD_NAME or val == "SkyVault" then
			if not alive then doSpawnAll() end
		elseif alive then
			doDespawnAll()
		end
	end)
end)

print("[SkyVault] Tower ready. TARGET =", TARGET)
