-- FrostBasinGameplay.server.luau  (World 23 — Frost Basin)
-- Ice-themed jump room with sliding floes, ice ramps, and disappearing tiles.
-- North wall: bridge to Neon Rift.  South wall: bridge to Ember Hold.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local WORLD_NAME = "Frost Basin"

-- ── Geometry ──────────────────────────────────────────────────────────────────
local CX      = -2860
local CZ      = 2200
local FLOOR_Y = 1
local HW      = 60
local HD      = 60
local WALL_H  = 120
local WALL_T  = 4
local WALL_TRANS = 0.65

local DOOR_HALF = 25
local DOOR_H    = 12

local FINISH_Y = FLOOR_Y + WALL_H - 10

-- ── GameEvents ─────────────────────────────────────────────────────────────────
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)

local remValue = gameEvents and gameEvents:FindFirstChild("FrostBasinRemaining")
if not remValue then
	remValue = Instance.new("NumberValue")
	remValue.Name   = "FrostBasinRemaining"
	remValue.Value  = 0
	remValue.Parent = gameEvents or ReplicatedStorage
end

local totValue = gameEvents and gameEvents:FindFirstChild("FrostBasinTotal")
if not totValue then
	totValue = Instance.new("NumberValue")
	totValue.Name   = "FrostBasinTotal"
	totValue.Value  = 0
	totValue.Parent = gameEvents or ReplicatedStorage
end

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET  = (Balance.StageTargets and Balance.StageTargets.FrostBasin) or 1

local playerScored
task.spawn(function() playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30) end)

-- ── State ──────────────────────────────────────────────────────────────────────
local alive          = false
local worldFolder    = nil
local finishDebounce = {}
local padDebounce    = {}
local activeConns    = {}   -- RunService connections cleared on destroy

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

local function solid(name, size, pos, color)
	return mkp(name, size, pos, color, Enum.Material.SmoothPlastic, 0)
end

local function ice(name, size, pos, color)
	return mkp(name, size, pos, color, Enum.Material.Ice, 0)
end

local function neon(name, size, pos, color)
	return mkp(name, size, pos, color, Enum.Material.Neon, 0.05, true)
end

-- ── Wall builder ────────────────────────────────────────────────────────────────
local function buildWall(isZWall, fixedCoord, alongMin, alongMax, yMin, yMax, holes)
	local yPts = { yMin, yMax }
	for _, h in ipairs(holes) do
		table.insert(yPts, h.yBot) ; table.insert(yPts, h.yTop)
	end
	table.sort(yPts)
	local uy = { yPts[1] }
	for i = 2, #yPts do
		if yPts[i] - uy[#uy] > 0.02 then table.insert(uy, yPts[i]) end
	end
	for bi = 1, #uy - 1 do
		local yBot, yTop = uy[bi], uy[bi + 1]
		local yH, yMid = yTop - yBot, (yBot + yTop) / 2
		local active = {}
		for _, h in ipairs(holes) do
			if h.yBot <= yBot + 0.01 and h.yTop >= yTop - 0.01 then
				table.insert(active, { h.alongMin, h.alongMax })
			end
		end
		table.sort(active, function(a, b) return a[1] < b[1] end)
		local segs, cur = {}, alongMin
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
				mkp("Wall", Vector3.new(WALL_T, yH, len), Vector3.new(fixedCoord, yMid, mid), "Pastel blue", Enum.Material.SmoothPlastic, WALL_TRANS)
			else
				mkp("Wall", Vector3.new(len, yH, WALL_T), Vector3.new(mid, yMid, fixedCoord), "Pastel blue", Enum.Material.SmoothPlastic, WALL_TRANS)
			end
		end
	end
end

-- ── Jump pad helpers ───────────────────────────────────────────────────────────
local function launchPlayer(player, vx, vy, vz, duration)
	if player:GetAttribute("SkyDescentBoundsActive") then return end
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(vx, vy, vz)
	bv.MaxForce = Vector3.new(math.abs(vx) > 0 and math.huge or 0, math.huge, math.abs(vz) > 0 and math.huge or 0)
	bv.P = math.huge
	bv.Parent = hrp
	Debris:AddItem(bv, duration or 0.13)
end

-- Simple upward floor pad
local function makeFloorPad(px, pz, launchV, color)
	local padY = FLOOR_Y + 0.35
	local pad  = solid("FloorPad", Vector3.new(7, 0.7, 7), Vector3.new(px, padY, pz), "Sand blue")
	neon("FPGlow", Vector3.new(7, 0.2, 7), Vector3.new(px, padY + 0.45, pz), color)
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, 0, launchV, 0)
		task.delay(0.2, function() padDebounce[player] = nil end)
	end)
end

-- Directional pad: launches with X and Z components too
local function makeDirPad(px, py, pz, vx, vy, vz, color, label)
	local pad  = solid(label or "DirPad", Vector3.new(9, 0.7, 9), Vector3.new(px, py, pz), "Really black")
	local glow = neon("DirGlow", Vector3.new(9, 0.2, 9), Vector3.new(px, py + 0.45, pz), color)
	-- Arrow indicator pointing in launch direction
	if math.abs(vx) > math.abs(vz) then
		neon("Arrow", Vector3.new(5, 0.2, 1.5), Vector3.new(px + (vx > 0 and 1.5 or -1.5), py + 0.5, pz), "White")
	else
		neon("Arrow", Vector3.new(1.5, 0.2, 5), Vector3.new(px, py + 0.5, pz + (vz > 0 and 1.5 or -1.5)), "White")
	end
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, vx, vy, vz, 0.22)
		glow.BrickColor = BrickColor.new("White")
		task.delay(0.15, function() if glow.Parent then glow.BrickColor = BrickColor.new(color) end end)
		task.delay(0.35, function() padDebounce[player] = nil end)
	end)
end

-- Sliding ice platform (oscillates in X with sine wave)
-- phase offsets the sine so adjacent platforms are out of sync
local function makeSlidingFloe(baseX, y, pz, amplitude, period, phase, color)
	local plat = ice("IceFloe", Vector3.new(22, 1.5, 14), Vector3.new(baseX, y, pz), color)
	neon("FloGlow", Vector3.new(22, 0.15, 14), Vector3.new(baseX, y + 0.8, pz), "Cyan")
	table.insert(activeConns, RunService.Heartbeat:Connect(function()
		if not plat.Parent then return end
		local t = workspace.DistributedGameTime
		local off = math.sin(t * math.pi * 2 / period + phase) * amplitude
		plat.CFrame = CFrame.new(baseX + off, y, pz)
	end))
	return plat
end

-- Disappearing ice tile: visible for visTime, gone for goneTime, with flash warning
local function makeDisappearTile(px, y, pz, visTime, goneTime, color)
	local tile = ice("SnapTile", Vector3.new(14, 1.5, 14), Vector3.new(px, y, pz), color)
	neon("SnapGlow", Vector3.new(14, 0.15, 14), Vector3.new(px, y + 0.8, pz), "Cyan")
	task.spawn(function()
		task.wait(math.random() * visTime)  -- stagger start
		while tile.Parent and alive do
			task.wait(visTime)
			if not tile.Parent or not alive then break end
			-- Flash warning (3 flickers)
			for _ = 1, 3 do
				tile.BrickColor = BrickColor.new("White")
				tile.Transparency = 0.5
				task.wait(0.12)
				if not tile.Parent then break end
				tile.BrickColor = BrickColor.new(color)
				tile.Transparency = 0
				task.wait(0.12)
			end
			if not tile.Parent then break end
			tile.Transparency = 0.92
			tile.CanCollide   = false
			task.wait(goneTime)
			if not tile.Parent then break end
			tile.Transparency = 0
			tile.CanCollide   = true
		end
	end)
	return tile
end

-- Ice ramp: angled wedge that deflects player upward + inward when landed on
-- dirX/dirZ = horizontal push direction on touch
local function makeRamp(px, py, pz, sx, sy, sz, rx, color, dirX, dirZ, launchV)
	local ramp = mkp("IceRamp", Vector3.new(sx, sy, sz), Vector3.new(px, py, pz), color, Enum.Material.Ice, 0)
	ramp.CFrame = CFrame.new(px, py, pz) * CFrame.Angles(rx, 0, 0)
	ramp.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, dirX, launchV, dirZ, 0.18)
		task.delay(0.3, function() padDebounce[player] = nil end)
	end)
end

-- ── Build the room ──────────────────────────────────────────────────────────────
local function buildRoom()
	worldFolder        = Instance.new("Folder")
	worldFolder.Name   = "FrostBasinWorld"
	worldFolder.Parent = workspace

	local xMin = CX - HW - WALL_T
	local xMax = CX + HW + WALL_T
	local yMin = FLOOR_Y
	local yMax = FLOOR_Y + WALL_H

	-- ── Floor ────────────────────────────────────────────────────────────────────
	ice("Floor", Vector3.new(HW * 2, 4, HD * 2), Vector3.new(CX, FLOOR_Y - 2, CZ), "Pastel blue")
	neon("FloorWash", Vector3.new(HW * 2 - 2, 0.1, HD * 2 - 2), Vector3.new(CX, FLOOR_Y + 0.05, CZ), "Cyan")

	-- Floor pads
	for _, dx in { -22, 22 } do
		for _, dz in { -22, 22 } do
			makeFloorPad(CX + dx, CZ + dz, 70, "Cyan")
		end
	end

	-- ── Walls ────────────────────────────────────────────────────────────────────
	local nDoor = { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H }
	local sDoor = { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H }
	buildWall(true,  CX - HW - WALL_T / 2, CZ - HD - WALL_T, CZ + HD + WALL_T, yMin, yMax, {})
	buildWall(true,  CX + HW + WALL_T / 2, CZ - HD - WALL_T, CZ + HD + WALL_T, yMin, yMax, {})
	buildWall(false, CZ - HD - WALL_T / 2, xMin, xMax, yMin, yMax, { nDoor })
	buildWall(false, CZ + HD + WALL_T / 2, xMin, xMax, yMin, yMax, { sDoor })

	-- ── LEVEL 1: Sliding ice floes (y=26) ────────────────────────────────────────
	-- Three floes slide in X; middle one is 180° out of phase creating a weaving gap.
	local floeY = FLOOR_Y + 26
	makeSlidingFloe(CX - 10, floeY, CZ - 20, 28, 5,  0,        "Light blue")
	makeSlidingFloe(CX + 10, floeY, CZ + 20, 28, 5,  math.pi,  "Light blue")
	makeSlidingFloe(CX,      floeY, CZ,       20, 3.5, math.pi/2, "Cyan")
	-- Wall boost pads to first floe height
	for _, pair in { {CX - HW - WALL_T + 5, CZ - 22}, {CX + HW + WALL_T - 5, CZ + 22} } do
		solid("BoostShelf", Vector3.new(10, 1.5, 12), Vector3.new(pair[1], floeY - 1, pair[2]), "Sand blue")
		neon("ShelfGlow", Vector3.new(10, 0.2, 12), Vector3.new(pair[1], floeY - 0.25, pair[2]), "Cyan")
	end

	-- ── LEVEL 2: Ice ramps (y=50) — launch player inward + upward ────────────────
	local rampY = FLOOR_Y + 50
	-- West ramps: slope inward (toward CX), launch +X and up
	makeRamp(CX - HW + 12, rampY,     CZ - 15, 24, 4, 10, -0.45, "Pastel blue", 55, 0, 90)
	makeRamp(CX - HW + 12, rampY,     CZ + 15, 24, 4, 10, -0.45, "Pastel blue", 55, 0, 90)
	-- East ramps: slope inward, launch -X and up
	makeRamp(CX + HW - 12, rampY,     CZ - 15, 24, 4, 10,  0.45, "Pastel blue", -55, 0, 90)
	makeRamp(CX + HW - 12, rampY,     CZ + 15, 24, 4, 10,  0.45, "Pastel blue", -55, 0, 90)
	-- Center catch ledge between ramps so players land safely
	ice("CatchLedge", Vector3.new(20, 2, HD * 2 - 10), Vector3.new(CX, rampY, CZ), "Light blue")
	neon("CatchGlow",  Vector3.new(20, 0.15, HD * 2 - 10), Vector3.new(CX, rampY + 1.1, CZ), "Cyan")
	-- Directional pads on the catch ledge: shoot player upward from center
	makeDirPad(CX, rampY + 1.5, CZ - 10, 0, 110, 0, "Cyan")
	makeDirPad(CX, rampY + 1.5, CZ + 10, 0, 110, 0, "Cyan")

	-- ── LEVEL 3: Disappearing ice tiles (y=75) ───────────────────────────────────
	local tileY = FLOOR_Y + 75
	-- 2x4 grid of tiles; tiles disappear and reappear on staggered cycles
	-- Two "safe" permanent ledges on N and S walls
	ice("SafeN", Vector3.new(HW * 2 - 6, 2, 10), Vector3.new(CX, tileY, CZ - HD + 8), "Sand blue")
	ice("SafeS", Vector3.new(HW * 2 - 6, 2, 10), Vector3.new(CX, tileY, CZ + HD - 8), "Sand blue")
	-- 6 disappearing tiles arranged in two rows
	local tilePositions = {
		{ CX - 30, CZ - 18 }, { CX, CZ - 18 }, { CX + 30, CZ - 18 },
		{ CX - 30, CZ + 18 }, { CX, CZ + 18 }, { CX + 30, CZ + 18 },
	}
	for i, tp in ipairs(tilePositions) do
		-- Alternate cycles so at least half are visible at any time
		local visT  = (i % 2 == 0) and 3.5 or 4.0
		local goneT = 1.8
		makeDisappearTile(tp[1], tileY, tp[2], visT, goneT, "Light blue")
	end
	-- Small boost pads on the safe ledges to reach this level
	makeDirPad(CX - 20, tileY + 1.5, CZ - HD + 8, 0, 70, 0, "Cyan")
	makeDirPad(CX + 20, tileY + 1.5, CZ - HD + 8, 0, 70, 0, "Cyan")

	-- ── LEVEL 4: Perimeter ice ledge + center launcher (y=96) ────────────────────
	local ledgeY = FLOOR_Y + 96
	local lw = 6   -- ledge width
	-- Four strips forming a hollow ring
	ice("LedgeN", Vector3.new(HW * 2, 2, lw), Vector3.new(CX, ledgeY, CZ - HD + lw / 2), "Pastel blue")
	ice("LedgeS", Vector3.new(HW * 2, 2, lw), Vector3.new(CX, ledgeY, CZ + HD - lw / 2), "Pastel blue")
	ice("LedgeW", Vector3.new(lw, 2, HD * 2 - lw * 2), Vector3.new(CX - HW + lw / 2, ledgeY, CZ), "Pastel blue")
	ice("LedgeE", Vector3.new(lw, 2, HD * 2 - lw * 2), Vector3.new(CX + HW - lw / 2, ledgeY, CZ), "Pastel blue")
	-- Neon edge on all ledges
	for _, n in { {"LNeon", HW * 2, CZ - HD + lw / 2}, {"SNeon", HW * 2, CZ + HD - lw / 2} } do
		neon(n[1], Vector3.new(n[2], 0.2, lw), Vector3.new(CX, ledgeY + 1.1, n[3]), "Cyan")
	end
	-- Center floating launch disk
	local disk = solid("LaunchDisk", Vector3.new(18, 1, 18), Vector3.new(CX, ledgeY, CZ), "Sand blue")
	neon("DiskRing", Vector3.new(18, 0.2, 18), Vector3.new(CX, ledgeY + 0.6, CZ), "Cyan")
	disk.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, 0, 130, 0)
		task.delay(0.25, function() padDebounce[player] = nil end)
	end)

	-- ── Top ring ─────────────────────────────────────────────────────────────────
	local ringY = FLOOR_Y + WALL_H + 1
	neon("RingN", Vector3.new(HW*2+WALL_T*2, 1, 0.5), Vector3.new(CX, ringY, CZ-HD-WALL_T/2), "Cyan")
	neon("RingS", Vector3.new(HW*2+WALL_T*2, 1, 0.5), Vector3.new(CX, ringY, CZ+HD+WALL_T/2), "Cyan")
	neon("RingW", Vector3.new(0.5, 1, HD*2+WALL_T*2), Vector3.new(CX-HW-WALL_T/2, ringY, CZ), "Cyan")
	neon("RingE", Vector3.new(0.5, 1, HD*2+WALL_T*2), Vector3.new(CX+HW+WALL_T/2, ringY, CZ), "Cyan")
	-- ── Finish trigger ────────────────────────────────────────────────────────────
	local trigger = Instance.new("Part")
	trigger.Name = "FinishTrigger"
	trigger.Size = Vector3.new(24, 5, 24)
	trigger.Position = Vector3.new(CX, FINISH_Y + 3.2, CZ)
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.CanTouch = true
	trigger.Transparency = 1
	trigger.Parent = worldFolder
	trigger.Touched:Connect(function(hit)
		if not alive then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or finishDebounce[player] then return end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp or math.abs(hrp.Position.X - CX) > 15 or math.abs(hrp.Position.Z - CZ) > 15 then return end
		finishDebounce[player] = true
		remValue.Value = math.max(0, remValue.Value - 1)
		if playerScored then playerScored:Fire(player, WORLD_NAME) end
		task.delay(6, function() finishDebounce[player] = nil end)
	end)

	-- ── Giant styled "23" wall sign (east interior wall) ─────────────────────────
	do
		-- Panel spans nearly full wall height, centered on east interior face
		local panelW, panelH = HD * 2 - 4, WALL_H - 8
		local panelX = CX + HW - 0.4
		local panelY = FLOOR_Y + panelH / 2 + 4
		local panelZ = CZ

		-- deep backing slab
		local back = solid("NumPanel", Vector3.new(0.7, panelH, panelW),
			Vector3.new(panelX, panelY, panelZ), "Really black")
		back.Material = Enum.Material.Metal

		-- outer neon border – thick cyan
		local bT = 1.4
		neon("NF_Top",   Vector3.new(bT, bT, panelW + bT * 2), Vector3.new(panelX, panelY + panelH / 2 + bT / 2,  panelZ), "Cyan")
		neon("NF_Bot",   Vector3.new(bT, bT, panelW + bT * 2), Vector3.new(panelX, panelY - panelH / 2 - bT / 2,  panelZ), "Cyan")
		neon("NF_L",     Vector3.new(bT, panelH + bT * 2, bT), Vector3.new(panelX, panelY, panelZ + panelW / 2 + bT / 2), "Cyan")
		neon("NF_R",     Vector3.new(bT, panelH + bT * 2, bT), Vector3.new(panelX, panelY, panelZ - panelW / 2 - bT / 2), "Cyan")

		-- inner border – thinner light blue, inset 3 studs
		local ins = 3
		neon("NI_Top",   Vector3.new(bT * 0.6, bT * 0.6, panelW - ins * 2), Vector3.new(panelX, panelY + panelH / 2 - ins,  panelZ), "Light blue")
		neon("NI_Bot",   Vector3.new(bT * 0.6, bT * 0.6, panelW - ins * 2), Vector3.new(panelX, panelY - panelH / 2 + ins,  panelZ), "Light blue")
		neon("NI_L",     Vector3.new(bT * 0.6, panelH - ins * 2, bT * 0.6), Vector3.new(panelX, panelY, panelZ + panelW / 2 - ins), "Light blue")
		neon("NI_R",     Vector3.new(bT * 0.6, panelH - ins * 2, bT * 0.6), Vector3.new(panelX, panelY, panelZ - panelW / 2 + ins), "Light blue")

		-- glowing corner cap orbs
		for _, sz in ipairs({ {1, 1}, {1, -1}, {-1, 1}, {-1, -1} }) do
			local orb = mkp("CornerOrb", Vector3.one * 3.5,
				Vector3.new(panelX, panelY + sz[1] * (panelH / 2), panelZ + sz[2] * (panelW / 2)),
				"Cyan", Enum.Material.Neon, 0.08, true)
			orb.Shape = Enum.PartType.Ball
		end

		-- horizontal divider bar (sits 28% from bottom — separates number from footer)
		local divY = panelY - panelH / 2 + panelH * 0.22
		neon("Divider",     Vector3.new(bT, bT * 0.5, panelW - 10), Vector3.new(panelX, divY, panelZ), "Cyan")
		neon("DividerGlow", Vector3.new(bT * 0.4, bT * 0.3, panelW - 18), Vector3.new(panelX, divY, panelZ), "Light blue")

		-- decorative diamond orbs along divider
		for i = -2, 2 do
			local orb = mkp("DivOrb", Vector3.one * 1.8,
				Vector3.new(panelX, divY, panelZ + i * (panelW / 5.5)),
				"Cyan", Enum.Material.Neon, 0.1, true)
			orb.Shape = Enum.PartType.Ball
		end

		-- SurfaceGui (Left face = interior-facing on east wall)
		local gui = Instance.new("SurfaceGui")
		gui.Face          = Enum.NormalId.Left
		gui.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 9          -- lower ppu = larger effective text
		gui.LightInfluence = 0
		gui.Parent        = back

		-- background
		local bg = Instance.new("Frame")
		bg.Size                   = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3       = Color3.fromRGB(1, 6, 18)
		bg.BackgroundTransparency = 0.0
		bg.BorderSizePixel        = 0
		bg.Parent                 = gui

		-- diagonal ice-streak texture
		for i = 0, 9 do
			local streak = Instance.new("Frame")
			streak.Size                   = UDim2.new(0, 6, 2.2, 0)
			streak.Position               = UDim2.new(0, i * 120 - 60, -0.6, 0)
			streak.Rotation               = 15
			streak.BackgroundColor3       = Color3.fromRGB(15, 70, 130)
			streak.BackgroundTransparency = 0.78
			streak.BorderSizePixel        = 0
			streak.Parent                 = bg
		end

		-- "WORLD" micro label above number
		local worldTag = Instance.new("TextLabel")
		worldTag.Size                   = UDim2.new(0.55, 0, 0.07, 0)
		worldTag.Position               = UDim2.new(0.225, 0, 0.225, 0)
		worldTag.BackgroundTransparency = 1
		worldTag.Text                   = "W O R L D"
		worldTag.TextColor3             = Color3.fromRGB(100, 200, 255)
		worldTag.TextStrokeColor3       = Color3.fromRGB(0, 20, 60)
		worldTag.TextStrokeTransparency = 0.2
		worldTag.Font                   = Enum.Font.GothamBold
		worldTag.TextScaled             = true
		worldTag.Parent                 = bg

		-- giant "23" — occupies most of the panel
		local numLabel = Instance.new("TextLabel")
		numLabel.Size                   = UDim2.new(1, 0, 0.62, 0)
		numLabel.Position               = UDim2.new(0, 0, 0.27, 0)
		numLabel.BackgroundTransparency = 1
		numLabel.Text                   = "23"
		numLabel.TextColor3             = Color3.fromRGB(160, 235, 255)
		numLabel.TextStrokeColor3       = Color3.fromRGB(0, 30, 70)
		numLabel.TextStrokeTransparency = 0.0
		numLabel.Font                   = Enum.Font.GothamBlack
		numLabel.TextScaled             = true
		numLabel.Parent                 = bg

		-- UIStroke for extra bold outline on the number
		local stroke = Instance.new("UIStroke")
		stroke.Color       = Color3.fromRGB(0, 120, 200)
		stroke.Thickness   = 6
		stroke.Transparency = 0.1
		stroke.Parent      = numLabel

		-- footer: world name
		local footer = Instance.new("TextLabel")
		footer.Size                   = UDim2.new(1, 0, 0.10, 0)
		footer.Position               = UDim2.new(0, 0, 0.885, 0)
		footer.BackgroundTransparency = 1
		footer.Text                   = "✦  FROST BASIN  ✦"
		footer.TextColor3             = Color3.fromRGB(200, 240, 255)
		footer.TextStrokeColor3       = Color3.fromRGB(0, 30, 70)
		footer.TextStrokeTransparency = 0.25
		footer.Font                   = Enum.Font.GothamBold
		footer.TextScaled             = true
		footer.Parent                 = bg

		-- thin separator line above footer
		local sep = Instance.new("Frame")
		sep.Size                   = UDim2.new(0.7, 0, 0, 2)
		sep.Position               = UDim2.new(0.15, 0, 0.875, 0)
		sep.BackgroundColor3       = Color3.fromRGB(80, 180, 255)
		sep.BackgroundTransparency = 0.3
		sep.BorderSizePixel        = 0
		sep.Parent                 = bg
	end

	-- ── Sign ──────────────────────────────────────────────────────────────────────
	local sp = solid("SignPart", Vector3.new(28, 7, 0.4), Vector3.new(CX + HW + WALL_T + 0.3, FLOOR_Y + 14, CZ), "Sand blue")
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back ; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30 ; gui.LightInfluence = 0 ; gui.Parent = sp
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1,0,1,0) ; bg.BackgroundColor3 = Color3.fromRGB(4,10,30)
	bg.BackgroundTransparency = 0.05 ; bg.BorderSizePixel = 0 ; bg.Parent = gui
	local l1 = Instance.new("TextLabel")
	l1.Size = UDim2.new(1,0,0.5,0) ; l1.Position = UDim2.new(0,0,0.05,0)
	l1.BackgroundTransparency = 1 ; l1.Text = "FROST BASIN"
	l1.TextColor3 = Color3.fromRGB(130,220,255) ; l1.Font = Enum.Font.GothamBlack
	l1.TextSize = 28 ; l1.TextStrokeTransparency = 0.3 ; l1.Parent = bg
	local l2 = Instance.new("TextLabel")
	l2.Size = UDim2.new(1,0,0.38,0) ; l2.Position = UDim2.new(0,0,0.58,0)
	l2.BackgroundTransparency = 1 ; l2.Text = "MIND THE ICE"
	l2.TextColor3 = Color3.fromRGB(180,235,255) ; l2.Font = Enum.Font.GothamBold
	l2.TextSize = 17 ; l2.TextStrokeTransparency = 0.5 ; l2.Parent = bg
end

-- ── Lifecycle ───────────────────────────────────────────────────────────────────
local function destroyRoom()
	for _, c in activeConns do c:Disconnect() end
	table.clear(activeConns)
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
print("[FrostBasin] World 23 built — sliding floes, ramps, disappearing tiles.")
