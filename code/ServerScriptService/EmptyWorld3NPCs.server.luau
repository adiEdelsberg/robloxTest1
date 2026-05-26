-- EmptyWorld3NPCs.server.luau
-- "Volt Abyss" — 10 flying warm-neon dinos that hover above the floor.
-- Same hit/shrink/color-cycle game logic as EmptyWorld2NPCs.
-- Flying mechanic: dinos float at FLOAT_HEIGHT above the floor with a gentle bob.

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local WORLD_NAME   = "Volt Abyss"
local FLOOR_Y      = 1
local FLOAT_HEIGHT = 4    -- studs above floor surface
local BOUNDS       = { minX = -2420, maxX = -1760, minZ = 1440, maxZ = 1960 }
local BOB_AMP      = 0.9
local BOB_SPEED    = 1.8

-- ── GameEvents values ────────────────────────────────────────────────────────
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
local playerScored
task.spawn(function() playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30) end)
local remValue = gameEvents and gameEvents:FindFirstChild("EmptyWorld3NPCsRemaining")
if not remValue then
	remValue = Instance.new("NumberValue")
	remValue.Name   = "EmptyWorld3NPCsRemaining"
	remValue.Value  = 0
	remValue.Parent = gameEvents or ReplicatedStorage
end
local totValue = gameEvents and gameEvents:FindFirstChild("EmptyWorld3NPCsTotal")
if not totValue then
	totValue = Instance.new("NumberValue")
	totValue.Name   = "EmptyWorld3NPCsTotal"
	totValue.Value  = 0
	totValue.Parent = gameEvents or ReplicatedStorage
end

local WorldOrder  = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))
local Balance     = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET      = Balance.StageTargets and Balance.StageTargets.EmptyWorld3 or 2


-- ── Hit states ───────────────────────────────────────────────────────────────
local HIT_STATES = {
	[3] = { scale = 1.00, color = nil,                           speedMult = 1.0  },
	[2] = { scale = 0.72, color = BrickColor.new("Bright orange"), speedMult = 7.0  },
	[1] = { scale = 0.48, color = BrickColor.new("Hot pink"),      speedMult = 13.0 },
}

-- ── Dino definitions (10 flying warm-neon dinos) ─────────────────────────────
local DINO_DEFS = {
	{ name = "Inferno Wing I",    scale = 1.6, baseSpeed = 14, legHeight = 3.2, color = BrickColor.new("Bright red"),    floatH = 4 },
	{ name = "Inferno Wing II",   scale = 2.2, baseSpeed = 0,  legHeight = 3.4, color = BrickColor.new("Deep orange"),   floatH = 2 },
	{ name = "Plasma Glider I",   scale = 1.5, baseSpeed = 15, legHeight = 3.0, color = BrickColor.new("Hot pink"),      floatH = 3 },
	{ name = "Plasma Glider II",  scale = 1.9, baseSpeed = 11, legHeight = 3.6, color = BrickColor.new("Magenta"),       floatH = 5 },
	{ name = "Blaze Striker I",   scale = 1.6, baseSpeed = 16, legHeight = 3.2, color = BrickColor.new("Bright orange"), floatH = 4 },
	{ name = "Blaze Striker II",  scale = 1.7, baseSpeed = 13, legHeight = 3.3, color = BrickColor.new("Neon orange"),   floatH = 3 },
	{ name = "Crimson Hover I",   scale = 1.5, baseSpeed = 17, legHeight = 2.9, color = BrickColor.new("Bright red"),    floatH = 4 },
	{ name = "Crimson Hover II",  scale = 2.0, baseSpeed = 10, legHeight = 3.8, color = BrickColor.new("Hot pink"),      floatH = 5 },
	{ name = "Solar Viper",       scale = 1.6, baseSpeed = 18, legHeight = 3.2, color = BrickColor.new("Bright yellow"), floatH = 4 },
	{ name = "Magma Falcon",      scale = 1.8, baseSpeed = 14, legHeight = 3.4, color = BrickColor.new("Deep orange"),   floatH = 5 },
}

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function rng(a, b) return a + math.random() * (b - a) end

local function makePart(name, size, color, mat, trans, noCollide)
	local p = Instance.new("Part")
	p.Name        = name
	p.Size        = size
	p.BrickColor  = color
	p.Material    = mat or Enum.Material.SmoothPlastic
	p.Anchored    = true
	p.CanCollide  = false  -- balls use proximity detection, not physics collision
	p.CastShadow  = false
	p.Transparency = trans or 0
	p.TopSurface  = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local BLACK = BrickColor.new("Really black")
local EYE_COLOR = BrickColor.new("Bright red")

local function buildDino(def, pos)
	local sc = def.scale

	local model = Instance.new("Model")
	model.Name  = def.name

	local bW = 5.2 * sc   -- body width
	local bH = 6.5 * sc   -- body height
	local bD = 7.0 * sc   -- body depth (front-back)

	-- Body (elongated, sleek)
	local body = makePart("Body", Vector3.new(bW, bH, bD), BLACK, Enum.Material.SmoothPlastic)
	body.Position = pos
	body.Parent   = model
	model.PrimaryPart = body

	-- Neck (angled forward-up)
	local neck = makePart("Neck", Vector3.new(bW * 0.52, bH * 0.45, bW * 0.52), BLACK, Enum.Material.SmoothPlastic)
	neck.CFrame = CFrame.new(pos + Vector3.new(0, bH * 0.42, bD * 0.38)) * CFrame.Angles(math.rad(-22), 0, 0)
	neck.Parent = model

	-- Head (flattened, aggressive)
	local hW = bW * 0.82
	local hH = bH * 0.38
	local hD = bD * 0.44
	local headPos = pos + Vector3.new(0, bH * 0.68, bD * 0.52)
	local head = makePart("Head", Vector3.new(hW, hH, hD), BLACK, Enum.Material.SmoothPlastic)
	head.Position = headPos
	head.Parent = model

	-- Crest (flat spike on top of head)
	local crest = makePart("Crest", Vector3.new(hW * 0.18, hH * 0.9, hD * 0.55), BLACK, Enum.Material.SmoothPlastic)
	crest.Position = headPos + Vector3.new(0, hH * 0.9, -hD * 0.1)
	crest.Parent = model

	-- Snout (narrow jaw)
	local snout = makePart("Snout", Vector3.new(hW * 0.48, hH * 0.28, hD * 0.55), BLACK, Enum.Material.SmoothPlastic)
	snout.Position = headPos + Vector3.new(0, -hH * 0.15, hD * 0.52)
	snout.Parent = model

	-- Eyes — bright red neon glow
	for _, sx in { -hW * 0.26, hW * 0.26 } do
		local eye = makePart("Eye", Vector3.new(sc * 0.85, sc * 0.85, sc * 0.22), EYE_COLOR, Enum.Material.Neon, 0, true)
		eye.Position = headPos + Vector3.new(sx, hH * 0.12, hD * 0.44)
		eye.Parent = model
	end

	-- Wings — two large swept-back panels, angled downward at tips
	-- Inner wing segment (close to body, nearly horizontal)
	-- Outer wing segment (swept back and angled down)
	local wingInW = bW * 1.4
	local wingInH = bH * 0.14
	local wingInD = bD * 0.7
	local wingOutW = bW * 2.2
	local wingOutH = bH * 0.10
	local wingOutD = bD * 0.55

	for _, side in { -1, 1 } do
		local inCF = CFrame.new(pos + Vector3.new(side * (bW * 0.5 + wingInW * 0.5 - 0.2), bH * 0.08, -bD * 0.05))
			* CFrame.Angles(0, side * math.rad(-12), side * math.rad(8))
		local wingIn = makePart("WingInner", Vector3.new(wingInW, wingInH, wingInD), BLACK, Enum.Material.SmoothPlastic)
		wingIn.CFrame = inCF
		wingIn.Parent = model

		local outCF = inCF * CFrame.new(side * (wingInW * 0.5 + wingOutW * 0.5 - 0.3), -bH * 0.05, -wingInD * 0.12)
			* CFrame.Angles(0, side * math.rad(-18), side * math.rad(22))
		local wingOut = makePart("WingOuter", Vector3.new(wingOutW, wingOutH, wingOutD), BLACK, Enum.Material.SmoothPlastic)
		wingOut.CFrame = outCF
		wingOut.Parent = model

		-- Neon edge strip along outer wing tip
		local tipStrip = makePart("WingTip", Vector3.new(wingOutW * 0.12, wingOutH * 0.7, wingOutD * 0.88),
			BrickColor.new("Really red"), Enum.Material.Neon, 0.25, true)
		tipStrip.CFrame = outCF * CFrame.new(side * wingOutW * 0.44, 0, 0)
		tipStrip.Parent = model
	end

	-- Tail (long and tapered)
	local tail1 = makePart("Tail", Vector3.new(bW * 0.42, bH * 0.28, bD * 0.72), BLACK, Enum.Material.SmoothPlastic)
	tail1.CFrame = CFrame.new(pos + Vector3.new(0, -bH * 0.05, -bD * 0.82)) * CFrame.Angles(math.rad(10), 0, 0)
	tail1.Parent = model

	local tail2 = makePart("TailTip", Vector3.new(bW * 0.22, bH * 0.16, bD * 0.44), BLACK, Enum.Material.SmoothPlastic)
	tail2.CFrame = CFrame.new(pos + Vector3.new(0, -bH * 0.14, -bD * 1.38)) * CFrame.Angles(math.rad(18), 0, 0)
	tail2.Parent = model

	-- Underbelly neon glow (very subtle red, semi-transparent)
	local belly = makePart("Belly", Vector3.new(bW * 0.5, bH * 0.45, bD * 0.65),
		BrickColor.new("Really red"), Enum.Material.Neon, 0.62, true)
	belly.Position = pos + Vector3.new(0, -bH * 0.06, bD * 0.08)
	belly.Parent = model

	model.Parent = workspace
	return model, body
end

-- ── Cash helper ──────────────────────────────────────────────────────────────
local CASH_PER_HIT = Balance.NPCRewards and Balance.NPCRewards.BaseMoneyPerHit or 10

local function addCash(player, amount)
	if not player then return end
	local stats = player:FindFirstChild("leaderstats")
	local cash  = stats and stats:FindFirstChild("Cash")
	if cash then cash.Value += amount end
end

local function getShooter(ball)
	local name = ball:GetAttribute("ThrowerName")
	if not name then return nil end
	for _, p in Players:GetPlayers() do
		if p.Name == name then return p end
	end
	return nil
end

-- ── Active dino state ─────────────────────────────────────────────────────────
local dinos      = {}
local aliveCount = 0   -- dinos currently alive in world (wave tracking)
local alive      = false

local function recolorModel(model, col)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "WingTip" and p.Name ~= "Belly" and p.Name ~= "Eye" then
			p.BrickColor = col
		end
	end
end

local colorCycleConns = {}
local function startColorCycle(state)
	if colorCycleConns[state] then return end
	local colors = {
		BrickColor.new("Really red"), BrickColor.new("Hot pink"),
		BrickColor.new("Bright orange"), BrickColor.new("New Yeller"),
		BrickColor.new("Bright red"),
	}
	local ci = 1
	colorCycleConns[state] = RunService.Heartbeat:Connect(function()
		if not state.model or not state.model.Parent then
			colorCycleConns[state]:Disconnect()
			colorCycleConns[state] = nil
			return
		end
		ci = (ci % #colors) + 1
		recolorModel(state.model, colors[ci])
	end)
end

local function spawnDino(def, idx)
	local angle  = (idx - 1) / #DINO_DEFS * math.pi * 2
	local rad    = 80
	local sx     = (BOUNDS.minX + BOUNDS.maxX) / 2 + math.cos(angle) * rad
	local sz     = (BOUNDS.minZ + BOUNDS.maxZ) / 2 + math.sin(angle) * rad
	local sc     = def.scale
	local floatY = FLOOR_Y + def.floatH
	local bodyY  = floatY + def.legHeight * 0.45 + sc * 11

	local model, body = buildDino(def, Vector3.new(sx, bodyY, sz))

	local state = {
		model  = model,
		body   = body,
		def    = def,
		scale  = sc,
		hp     = 3,
		speed  = def.baseSpeed,
		vel    = def.baseSpeed > 0 and Vector3.new(rng(-1,1), 0, rng(-1,1)).Unit * def.baseSpeed or Vector3.zero,
		bobT   = rng(0, math.pi * 2),
		floatY = floatY,
		bodyY  = bodyY,
		alive  = true,
	}
	dinos[idx]  = state
	aliveCount += 1
	return state
end

local spawnAll  -- forward declare
local function destroyDino(state, idx)
	if not state.alive then return end
	state.alive = false
	if colorCycleConns[state] then
		colorCycleConns[state]:Disconnect()
		colorCycleConns[state] = nil
	end
	aliveCount = math.max(0, aliveCount - 1)
	if state.model and state.model.Parent then state.model:Destroy() end
	dinos[idx] = nil
end

-- ── Ball hit detection ────────────────────────────────────────────────────────
local hitDebounce = {}

local function onBallHit(ball, state, idx)
	if not state.alive then return end
	if not ball.Parent then return end
	if not ball:GetAttribute("IsThrown") then return end

	if hitDebounce[ball] then return end
	hitDebounce[ball] = true

	local shooter = getShooter(ball)
	ball:Destroy()   -- one hit per throw

	local dmg = 1
	state.hp  = state.hp - dmg
	addCash(shooter, CASH_PER_HIT)

	local hitState = HIT_STATES[math.max(1, state.hp)]

	if state.hp <= 0 then
		-- Count defeat only if dino was already at smallest size (hit 3 times properly)
		if math.abs(state.scale - 0.48) < 0.05 then
			local newRem = math.max(0, remValue.Value - 1)
			remValue.Value = newRem
			if shooter and playerScored then playerScored:Fire(shooter, WORLD_NAME) end
		end

		local pos = state.body and state.body.Position or Vector3.new(0, FLOOR_Y + 20, 0)
		destroyDino(state, idx)

		-- Explosion fragments
		for _ = 1, 6 do
			local frag = Instance.new("Part")
			frag.Size       = Vector3.new(rng(0.4, 1.2), rng(0.4, 1.2), rng(0.4, 1.2))
			frag.BrickColor = BrickColor.new("Hot pink")
			frag.Material   = Enum.Material.Neon
			frag.Anchored   = false
			frag.CastShadow = false
			frag.Position   = pos + Vector3.new(rng(-2, 2), rng(0, 2), rng(-2, 2))
			frag.Velocity   = Vector3.new(rng(-18, 18), rng(8, 22), rng(-18, 18))
			frag.Parent     = workspace
			game:GetService("Debris"):AddItem(frag, 1.4)
		end

		-- If wave is cleared but stage not done, respawn after 2s
		if aliveCount <= 0 and remValue.Value > 0 then
			task.delay(2, function()
				if alive then spawnAll() end
			end)
		end
		return
	end

	-- Shrink + recolor
	state.scale = hitState.scale
	state.speed = state.def.baseSpeed * hitState.speedMult
	if state.speed > 0 then
		local dir = state.vel.Magnitude > 0.01 and state.vel.Unit or Vector3.new(rng(-1,1), 0, rng(-1,1)).Unit
		state.vel = dir * state.speed
	else
		state.vel = Vector3.zero
	end
	if hitState.color then recolorModel(state.model, hitState.color) end

	state.model:ScaleTo(state.scale)
	state.floatY = FLOOR_Y + state.def.floatH
	state.bodyY  = state.floatY + state.scale * (state.def.legHeight * 0.45 + state.scale * 11)

	if state.hp == 1 then startColorCycle(state) end
end

-- ── Movement loop ─────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
	if not alive then return end
	for idx, state in dinos do
		if not state.alive or not state.body or not state.model.Parent then continue end

		local pos = state.body.Position

		if state.speed > 0 and math.random() < 0.008 then
			state.vel = Vector3.new(rng(-1,1), 0, rng(-1,1)).Unit * state.speed
		end

		local nx = pos.X + state.vel.X * dt
		local nz = pos.Z + state.vel.Z * dt
		if nx < BOUNDS.minX or nx > BOUNDS.maxX then state.vel = Vector3.new(-state.vel.X, 0, state.vel.Z) end
		if nz < BOUNDS.minZ or nz > BOUNDS.maxZ then state.vel = Vector3.new(state.vel.X, 0, -state.vel.Z) end
		nx = math.clamp(nx, BOUNDS.minX, BOUNDS.maxX)
		nz = math.clamp(nz, BOUNDS.minZ, BOUNDS.maxZ)

		state.bobT += dt * BOB_SPEED
		local bob       = math.sin(state.bobT) * BOB_AMP
		local flapAngle = math.sin(state.bobT * 2.5) * math.rad(12)
		local targetY   = state.bodyY + bob

		state.body.CFrame = CFrame.new(nx, targetY, nz) * CFrame.Angles(0, math.atan2(state.vel.X, state.vel.Z), flapAngle)

		for _, p in state.model:GetDescendants() do
			if p:IsA("BasePart") and p ~= state.body then
				local off = p.Position - pos
				p.Position = Vector3.new(nx + off.X, targetY + off.Y, nz + off.Z)
			end
		end
	end
end)

-- ── Ball proximity detection ──────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
	if not alive then return end
	for idx, state in dinos do
		if not state.alive or not state.body then continue end
		local bodyPos = state.body.Position
		local hitR    = 9 * state.scale + 3
		for _, ball in workspace:GetChildren() do
			if ball:IsA("BasePart") and ball.Name == "Ball" and ball:GetAttribute("IsThrown") then
				if (ball.Position - bodyPos).Magnitude < hitR then
					task.spawn(onBallHit, ball, state, idx)
				end
			end
		end
	end
end)

-- ── Spawn / despawn ───────────────────────────────────────────────────────────
spawnAll = function()
	for i, def in ipairs(DINO_DEFS) do
		if not dinos[i] then spawnDino(def, i) end
	end
end

local function doSpawnAll()
	if alive then return end
	alive          = true
	aliveCount     = 0
	remValue.Value = TARGET
	totValue.Value = TARGET
	spawnAll()
end

local function doDespawnAll()
	if not alive then return end
	alive = false
	for idx, state in dinos do destroyDino(state, idx) end
	table.clear(dinos)
	table.clear(hitDebounce)
	aliveCount     = 0
	remValue.Value = TARGET
end

-- ── WorldRestartSignal ────────────────────────────────────────────────────────
task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= WORLD_NAME then return end
		doDespawnAll()
		task.wait(0.5)
		doSpawnAll()
	end)
end)

-- ── Presence poll: wake/sleep when players enter/leave ───────────────────────
task.spawn(function()
	while true do
		task.wait(3)
		local present = false
		for _, p in Players:GetPlayers() do
			local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local pos = hrp.Position
				if pos.X >= BOUNDS.minX and pos.X <= BOUNDS.maxX and pos.Z >= BOUNDS.minZ and pos.Z <= BOUNDS.maxZ then
					present = true
					break
				end
			end
		end
		if present and not alive then
			doSpawnAll()
		elseif not present and alive then
			doDespawnAll()
		end
	end
end)

print("[EmptyWorld3NPCs] Volt Abyss flying dinos ready.")
