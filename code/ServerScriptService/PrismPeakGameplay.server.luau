-- PrismPeakGameplay.server.luau  (World 26 — Prism Peak)
-- Crystal/prism jump room: spinning cube obstacles, pendulum platforms, rainbow launch pads.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Debris            = game:GetService("Debris")

local WORLD_NAME = "Prism Peak"

local CX      = -2860
local CZ      = 3200
local FLOOR_Y = 1
local HW      = 55
local HD      = 55
local WALL_H  = 130
local WALL_T  = 4
local WALL_TRANS = 0.3

local DOOR_HALF = 11
local DOOR_H    = 12
local FINISH_Y  = FLOOR_Y + WALL_H - 10

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)

local remValue = gameEvents and gameEvents:FindFirstChild("PrismPeakRemaining")
if not remValue then
	remValue = Instance.new("NumberValue")
	remValue.Name   = "PrismPeakRemaining"
	remValue.Value  = 0
	remValue.Parent = gameEvents or ReplicatedStorage
end
local totValue = gameEvents and gameEvents:FindFirstChild("PrismPeakTotal")
if not totValue then
	totValue = Instance.new("NumberValue")
	totValue.Name   = "PrismPeakTotal"
	totValue.Value  = 0
	totValue.Parent = gameEvents or ReplicatedStorage
end

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET  = (Balance.StageTargets and Balance.StageTargets.PrismPeak) or 1

local playerScored
task.spawn(function() playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30) end)

local alive          = false
local worldFolder    = nil
local finishDebounce = {}
local padDebounce    = {}
local activeConns    = {}

local RAINBOW = { "Bright red", "Bright orange", "Bright yellow", "Lime green", "Cyan", "Bright violet", "Hot pink" }

local function mkp(name, size, pos, color, mat, trans, noCollide)
	local p = Instance.new("Part")
	p.Name = name ; p.Size = size ; p.Position = pos
	p.BrickColor = BrickColor.new(color) ; p.Material = mat
	p.Anchored = true ; p.CanCollide = not noCollide ; p.CanTouch = true
	p.CastShadow = false ; p.Transparency = trans or 0
	p.TopSurface = Enum.SurfaceType.Smooth ; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = worldFolder ; return p
end

local function solid(n, sz, pos, col) return mkp(n, sz, pos, col, Enum.Material.SmoothPlastic, 0) end
local function glass(n, sz, pos, col, tr) return mkp(n, sz, pos, col, Enum.Material.Glass, tr or WALL_TRANS, false) end
local function neon(n, sz, pos, col, tr) return mkp(n, sz, pos, col, Enum.Material.Neon, tr or 0.05, true) end
local function mkball(sz, pos, col, tr)
	local p = neon("Orb", Vector3.one * sz, pos, col, tr) ; p.Shape = Enum.PartType.Ball ; return p
end

local function buildWall(isZWall, fixedCoord, alongMin, alongMax, yMin, yMax, holes)
	local yPts = { yMin, yMax }
	for _, h in ipairs(holes) do table.insert(yPts, h.yBot) ; table.insert(yPts, h.yTop) end
	table.sort(yPts)
	local uy = { yPts[1] }
	for i = 2, #yPts do if yPts[i] - uy[#uy] > 0.02 then table.insert(uy, yPts[i]) end end
	for bi = 1, #uy - 1 do
		local yBot, yTop = uy[bi], uy[bi + 1]
		local yH, yMid = yTop - yBot, (yBot + yTop) / 2
		local active = {}
		for _, h in ipairs(holes) do
			if h.yBot <= yBot + 0.01 and h.yTop >= yTop - 0.01 then table.insert(active, { h.alongMin, h.alongMax }) end
		end
		table.sort(active, function(a, b) return a[1] < b[1] end)
		local segs, cur = {}, alongMin
		for _, hole in ipairs(active) do
			if hole[1] > cur then table.insert(segs, { cur, hole[1] }) end
			cur = math.max(cur, hole[2])
		end
		if cur < alongMax then table.insert(segs, { cur, alongMax }) end
		for _, seg in ipairs(segs) do
			local len = seg[2] - seg[1] ; if len < 0.1 then continue end
			local mid = seg[1] + len / 2
			if isZWall then
				glass("Wall", Vector3.new(WALL_T, yH, len), Vector3.new(fixedCoord, yMid, mid), "Cyan", WALL_TRANS)
			else
				glass("Wall", Vector3.new(len, yH, WALL_T), Vector3.new(mid, yMid, fixedCoord), "Cyan", WALL_TRANS)
			end
		end
	end
end

local function launchPlayer(player, vx, vy, vz, dur)
	if player:GetAttribute("SkyDescentBoundsActive") then return end
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(vx, vy, vz)
	bv.MaxForce = Vector3.new(math.abs(vx) > 0.1 and math.huge or 0, math.huge, math.abs(vz) > 0.1 and math.huge or 0)
	bv.P = math.huge ; bv.Parent = hrp
	Debris:AddItem(bv, dur or 0.14)
end

-- Spinning crystal cube: rotates on Y+Z axes; knocks players away on touch
local function makeSpinCube(px, py, pz, sz, speed, color)
	local cube = solid("SpinCube", Vector3.new(sz, sz, sz), Vector3.new(px, py, pz), color)
	cube.CanCollide = true
	neon("CubeGlo", Vector3.new(sz + 0.5, sz + 0.5, sz + 0.5), Vector3.new(px, py, pz), color, 0.75)
	local angle = math.random() * math.pi * 2
	table.insert(activeConns, RunService.Heartbeat:Connect(function(dt)
		if not cube.Parent then return end
		angle += dt * speed
		cube.CFrame = CFrame.new(px, py, pz) * CFrame.Angles(angle * 0.4, angle, 0)
	end))
	cube.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, (math.random() - 0.5) * 50, 38, (math.random() - 0.5) * 50, 0.15)
		task.delay(0.5, function() padDebounce[player] = nil end)
	end)
end

-- Pendulum platform: swings along X axis
local function makePendulum(baseX, baseY, baseZ, amplitude, period, color)
	local plat = solid("Pendulum", Vector3.new(20, 2, 12), Vector3.new(baseX, baseY, baseZ), "Dark indigo")
	neon("PendGlo", Vector3.new(20, 0.25, 12), Vector3.new(baseX, baseY + 1.1, baseZ), color, 0.2)
	local phase = math.random() * math.pi * 2
	table.insert(activeConns, RunService.Heartbeat:Connect(function()
		if not plat.Parent then return end
		local t   = workspace.DistributedGameTime
		local off = math.sin(t * math.pi * 2 / period + phase) * amplitude
		plat.CFrame = CFrame.new(baseX + off, baseY, baseZ)
	end))
end

-- Rainbow jump pad: directional launch, colour cycles through RAINBOW
local _ri = 0
local function makeRainbowPad(px, pz, vy, vx, vz)
	_ri = (_ri % #RAINBOW) + 1
	local color = RAINBOW[_ri]
	local py  = FLOOR_Y + 0.35
	local pad = solid("RainPad", Vector3.new(8, 0.7, 8), Vector3.new(px, py, pz), "Really black")
	local glo = neon("RainGlo", Vector3.new(8, 0.2, 8), Vector3.new(px, py + 0.45, pz), color, 0.05)
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, vx or 0, vy, vz or 0, 0.2)
		glo.BrickColor = BrickColor.new("White")
		task.delay(0.15, function() if glo.Parent then glo.BrickColor = BrickColor.new(color) end end)
		task.delay(0.3, function() padDebounce[player] = nil end)
	end)
end

local function buildRoom()
	worldFolder        = Instance.new("Folder")
	worldFolder.Name   = "PrismPeakWorld"
	worldFolder.Parent = workspace

	local xMin = CX - HW - WALL_T
	local xMax = CX + HW + WALL_T
	local yMin = FLOOR_Y
	local yMax = FLOOR_Y + WALL_H

	-- Floor: dark crystal base with rainbow edge neon
	solid("Floor", Vector3.new(HW * 2, 4, HD * 2), Vector3.new(CX, FLOOR_Y - 2, CZ), "Really black")
	neon("FloorWash", Vector3.new(HW * 2 - 2, 0.1, HD * 2 - 2), Vector3.new(CX, FLOOR_Y + 0.05, CZ), "Cyan", 0.85)
	neon("FloorSpX",  Vector3.new(HW * 2, 0.15, 0.4), Vector3.new(CX, FLOOR_Y + 0.12, CZ), "White", 0.4)
	neon("FloorSpZ",  Vector3.new(0.4, 0.15, HD * 2), Vector3.new(CX, FLOOR_Y + 0.12, CZ), "White", 0.4)
	for i, col in ipairs({ "Bright red", "Bright yellow", "Lime green", "Bright violet" }) do
		local a = (i - 1) / 4 * math.pi * 2
		mkball(0.8, Vector3.new(CX + math.cos(a) * (HW - 3), FLOOR_Y + 0.4, CZ + math.sin(a) * (HD - 3)), col, 0.15)
	end

	-- Walls: semi-transparent glass (crystal look)
	local nDoor = { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H }
	local sDoor = { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H }
	buildWall(true,  CX - HW - WALL_T / 2, CZ - HD - WALL_T, CZ + HD + WALL_T, yMin, yMax, {})
	buildWall(true,  CX + HW + WALL_T / 2, CZ - HD - WALL_T, CZ + HD + WALL_T, yMin, yMax, {})
	buildWall(false, CZ - HD - WALL_T / 2, xMin, xMax, yMin, yMax, { nDoor })
	buildWall(false, CZ + HD + WALL_T / 2, xMin, xMax, yMin, yMax, { sDoor })

	-- ── LEVEL 1: Floor → spinning cube gauntlet (y=1→35) ────────────────────────
	-- Four corner rainbow pads aimed inward-and-up
	makeRainbowPad(CX - 32, CZ - 32, 85,  28,  28)
	makeRainbowPad(CX + 32, CZ - 32, 85, -28,  28)
	makeRainbowPad(CX - 32, CZ + 32, 85,  28, -28)
	makeRainbowPad(CX + 32, CZ + 32, 85, -28, -28)
	makeRainbowPad(CX, CZ, 100, 0, 0)  -- center safety pad

	-- Four spinning cubes at mid-air height, players dodge while launched
	makeSpinCube(CX - 18, FLOOR_Y + 20, CZ - 18,  7,  1.3, "Cyan")
	makeSpinCube(CX + 18, FLOOR_Y + 20, CZ + 18,  7, -1.0, "Hot pink")
	makeSpinCube(CX + 18, FLOOR_Y + 20, CZ - 18,  6,  1.6, "Bright yellow")
	makeSpinCube(CX - 18, FLOOR_Y + 20, CZ + 18,  6, -1.2, "Lime green")

	-- ── LEVEL 2: Pendulum platform pair (y=36) ───────────────────────────────────
	local p2Y = FLOOR_Y + 36
	makePendulum(CX, p2Y, CZ - 18, 30, 2.2, "Cyan")
	makePendulum(CX, p2Y, CZ + 18, 30, 2.7, "Magenta")
	-- Corner static ledges as safety
	for _, dx in { -42, 42 } do
		for _, dz in { -28, 28 } do
			solid("Ledge", Vector3.new(10, 2, 10), Vector3.new(CX + dx, p2Y, CZ + dz), "Dark indigo")
			neon("LedgeGlo", Vector3.new(10, 0.2, 10), Vector3.new(CX + dx, p2Y + 1.1, CZ + dz), "Bright violet", 0.2)
		end
	end
	-- Spinning cubes flanking pendulums
	makeSpinCube(CX - 6, p2Y + 14, CZ - 18, 5, 2.0, "Bright violet")
	makeSpinCube(CX + 6, p2Y + 14, CZ + 18, 5, -1.7, "Cyan")

	-- ── LEVEL 3: Radial crystal platform ring (y=62) ─────────────────────────────
	local p3Y = FLOOR_Y + 62
	for i = 1, 6 do
		local a  = (i - 1) / 6 * math.pi * 2
		local px = CX + math.cos(a) * 30
		local pz = CZ + math.sin(a) * 30
		local col = RAINBOW[((i - 1) % #RAINBOW) + 1]
		solid("CrysPlat", Vector3.new(14, 2.5, 8), Vector3.new(px, p3Y, pz), "Dark indigo")
		neon("CrysGlo",   Vector3.new(14, 0.2, 8),  Vector3.new(px, p3Y + 1.3, pz), col, 0.15)
		mkball(1.3, Vector3.new(px, p3Y + 2.8, pz), col, 0.1)
		-- Directional launch pad angled toward center
		local pad = solid("CPad", Vector3.new(7, 0.5, 7), Vector3.new(px, p3Y + 1.5, pz), "Really black")
		local da  = a  -- capture
		pad.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or padDebounce[player] then return end
			padDebounce[player] = true
			launchPlayer(player, -math.cos(da) * 20, 88, -math.sin(da) * 20, 0.18)
			task.delay(0.3, function() padDebounce[player] = nil end)
		end)
	end
	-- Center spinning cube at ring level acts as gatekeeping obstacle
	makeSpinCube(CX, p3Y + 8, CZ, 10, 0.65, "Cyan")

	-- ── LEVEL 4: Four slow pendulums + apex disk (y=90) ──────────────────────────
	local p4Y = FLOOR_Y + 90
	makePendulum(CX, p4Y, CZ - 25, 22, 1.9, "Cyan")
	makePendulum(CX, p4Y, CZ + 25, 22, 2.3, "Hot pink")
	makePendulum(CX - 25, p4Y, CZ, 22, 2.1, "Bright yellow")
	makePendulum(CX + 25, p4Y, CZ, 22, 1.7, "Lime green")

	local apex = solid("ApexDisk", Vector3.new(16, 2, 16), Vector3.new(CX, p4Y, CZ), "Dark indigo")
	neon("ApexGlo", Vector3.new(16, 0.3, 16), Vector3.new(CX, p4Y + 1.2, CZ), "White", 0.05)
	mkball(3.5, Vector3.new(CX, p4Y + 5, CZ), "Bright yellow", 0.05)
	apex.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, 0, 155, 0, 0.18)
		task.delay(0.3, function() padDebounce[player] = nil end)
	end)

	-- Rainbow ceiling crown
	for i = 1, 8 do
		local a = (i - 1) / 8 * math.pi * 2
		mkball(1.8, Vector3.new(CX + math.cos(a) * (HW - 5), FLOOR_Y + WALL_H - 3, CZ + math.sin(a) * (HD - 5)), RAINBOW[((i-1)%7)+1], 0.08)
	end

	-- Finish trigger
	local trigger = Instance.new("Part")
	trigger.Name        = "FinishTrigger"
	trigger.Size        = Vector3.new(HW * 2, 8, HD * 2)
	trigger.Position    = Vector3.new(CX, FINISH_Y + 4, CZ)
	trigger.Anchored    = true ; trigger.CanCollide = false ; trigger.CanTouch = true
	trigger.Transparency = 1 ; trigger.Parent = worldFolder
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

	-- Sign
	local sp = solid("SignPart", Vector3.new(22, 7, 0.4), Vector3.new(CX + HW + WALL_T + 0.3, FLOOR_Y + 12, CZ), "Really black")
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back ; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30 ; gui.LightInfluence = 0 ; gui.Parent = sp
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1,0,1,0) ; bg.BackgroundColor3 = Color3.fromRGB(0, 18, 28)
	bg.BackgroundTransparency = 0.05 ; bg.BorderSizePixel = 0 ; bg.Parent = gui
	local l1 = Instance.new("TextLabel")
	l1.Size = UDim2.new(1,0,0.5,0) ; l1.Position = UDim2.new(0,0,0.05,0)
	l1.BackgroundTransparency = 1 ; l1.Text = "PRISM PEAK"
	l1.TextColor3 = Color3.fromRGB(100, 240, 255) ; l1.Font = Enum.Font.GothamBlack
	l1.TextSize = 28 ; l1.TextStrokeTransparency = 0.3 ; l1.Parent = bg
	local l2 = Instance.new("TextLabel")
	l2.Size = UDim2.new(1,0,0.38,0) ; l2.Position = UDim2.new(0,0,0.58,0)
	l2.BackgroundTransparency = 1 ; l2.Text = "DODGE THE CRYSTALS"
	l2.TextColor3 = Color3.fromRGB(180, 255, 255) ; l2.Font = Enum.Font.GothamBold
	l2.TextSize = 17 ; l2.TextStrokeTransparency = 0.5 ; l2.Parent = bg
end

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
			destroyRoom() ; alive = true
			remValue.Value = TARGET ; totValue.Value = TARGET
			buildRoom()
		end)
	end
end)

alive = true ; remValue.Value = TARGET ; totValue.Value = TARGET
buildRoom()
print("[PrismPeak] World 26 built — spinning crystal cubes, pendulum platforms, rainbow pads.")
