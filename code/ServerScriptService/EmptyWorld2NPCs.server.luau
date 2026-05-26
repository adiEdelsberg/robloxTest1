-- EmptyWorld2NPCs.server.luau
-- 10 electric-colored jumping dinos patrolling EmptyWorld2.
-- Same anatomy as EmptyWorld1 giant dinos; dinos jump periodically.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage    = game:GetService("ServerStorage")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")

local Balance          = require(ReplicatedStorage:WaitForChild("GameBalanceConfig"))
local BoundaryService  = require(ServerStorage:WaitForChild("WorldBoundaryService"))

local BOUNDS         = { minX = -1670, maxX = -970, minZ = 1420, maxZ = 1980 }
local FLOOR_Y        = 1
local NEEDED         = Balance.StageTargets.EmptyWorld2
local CASH_PER_HIT   = Balance.NPCRewards.BaseMoneyPerHit
local HITS_TO_DEFEAT = 3
local MARGIN         = 45

local gameEvents   = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits    = gameEvents:WaitForChild("StageHits")
local stageNeeded  = gameEvents:WaitForChild("StageNeeded")
local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local remaining = Instance.new("NumberValue")
remaining.Name   = "EmptyWorld2NPCsRemaining"
remaining.Parent = gameEvents

local totalVal = Instance.new("NumberValue")
totalVal.Name   = "EmptyWorld2NPCsTotal"
totalVal.Parent = gameEvents

local folder = Instance.new("Folder")
folder.Name   = "EmptyWorld2NPCs"
folder.Parent = workspace

-- ── part helpers ─────────────────────────────────────────────────────────────

local function mkPart(parent, name, size, cf, color, mat, trans, noCollide, shape)
	local pt = Instance.new("Part")
	pt.Name            = name
	pt.Size            = size
	pt.CFrame          = cf
	pt.BrickColor      = BrickColor.new(color)
	pt.Material        = mat or Enum.Material.SmoothPlastic
	pt.Transparency    = trans or 0
	pt.Anchored        = true
	pt.CanCollide      = not noCollide
	pt.CanTouch        = true
	pt.CastShadow      = false
	pt.TopSurface      = Enum.SurfaceType.Smooth
	pt.BottomSurface   = Enum.SurfaceType.Smooth
	if shape then pt.Shape = shape end
	pt.Parent = parent
	return pt
end

local function mkBall(parent, name, size, cf, color, mat, trans, noCollide)
	return mkPart(parent, name, Vector3.new(size, size, size),
		cf, color, mat, trans, noCollide, Enum.PartType.Ball)
end

-- ── decorations ───────────────────────────────────────────────────────────────

local function addDetails(model, cf, def)
	local sc = def.scale
	for i = -3, 3 do
		local sz = 2.8 * sc * (1 - math.abs(i) * 0.08)
		mkPart(model, "BackSpike", Vector3.new(sz, sz * 2.3, sz),
			cf * CFrame.new(i * 8 * sc, 17 * sc, 0) * CFrame.Angles(0, 0, math.rad(45)),
			def.accent, Enum.Material.Neon, 0.05, true)
	end
	for _, side in { -1, 1 } do
		mkBall(model, "Eye", 2.1 * sc,
			cf * CFrame.new(def.length * 0.54, 25 * sc, side * 4.4 * sc),
			"Institutional white", Enum.Material.SmoothPlastic, 0, true)
		mkBall(model, "Pupil", 0.9 * sc,
			cf * CFrame.new(def.length * 0.56, 25 * sc, side * 4.7 * sc),
			"Really black", Enum.Material.SmoothPlastic, 0, true)
		mkBall(model, "EyeGlow", 2.6 * sc,
			cf * CFrame.new(def.length * 0.54, 25 * sc, side * 4.4 * sc),
			def.accent, Enum.Material.Neon, 0.55, true)
	end
	for _, side in { -1, 1 } do
		for step = 0, 2 do
			mkBall(model, "ToeClaw", 1.4 * sc,
				cf * CFrame.new(14 * sc - step * 12 * sc, 1.7 * sc, side * 7.7 * sc),
				"Institutional white", Enum.Material.SmoothPlastic, 0, true)
		end
	end
	local body = model:FindFirstChild("GiantDinoBody")
	if body then
		local aura = Instance.new("ParticleEmitter")
		aura.Color          = ColorSequence.new(BrickColor.new(def.accent).Color, Color3.fromRGB(10, 20, 40))
		aura.LightEmission  = 0.9
		aura.LightInfluence = 0
		aura.Lifetime       = NumberRange.new(0.7, 1.6)
		aura.Rate           = 10
		aura.Speed          = NumberRange.new(1, 4)
		aura.Size           = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7 * sc),
			NumberSequenceKeypoint.new(1, 0),
		})
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Parent      = body
	end
end

-- ── build one dino ───────────────────────────────────────────────────────────

local function buildDino(def)
	local model    = Instance.new("Model")
	model.Name     = def.name
	model.Parent   = folder

	local sc = def.scale
	local cf = CFrame.new(def.x, FLOOR_Y + def.legHeight * 0.45 + sc * 3, def.z)

	local body = mkBall(model, "GiantDinoBody", def.bodySize,
		cf * CFrame.new(0, 8 * sc, 0), def.color, Enum.Material.SmoothPlastic, 0.02, false)

	mkPart(model, "GiantDinoBelly",
		Vector3.new(def.length * 0.55, def.height * 0.25, def.width * 0.82),
		cf * CFrame.new(5 * sc, 4.4 * sc, 0),
		def.belly, Enum.Material.SmoothPlastic, 0.02, true, Enum.PartType.Ball)

	mkPart(model, "GiantDinoTail",
		Vector3.new(def.length * 0.7, def.height * 0.18, def.width * 0.25),
		cf * CFrame.new(-def.length * 0.62, 7 * sc, 0) * CFrame.Angles(0, 0, math.rad(-8)),
		def.color, Enum.Material.SmoothPlastic, 0.01)

	mkPart(model, "NeckShoulderSocket",
		Vector3.new(def.length * 0.2, def.height * 0.34, def.width * 0.44),
		cf * CFrame.new(def.length * 0.2, def.neckY - 3 * sc, 0) * CFrame.Angles(0, 0, math.rad(-13)),
		def.color, Enum.Material.SmoothPlastic, 0.01, false, Enum.PartType.Ball)

	local neckParts       = {}
	local neckLocalCFrames = {}
	for segment = 1, 6 do
		local alpha     = segment / 6
		local sx        = def.length * (0.18 + alpha * 0.44)
		local sy        = def.neckY + alpha * (def.headY - def.neckY) * 0.72
		local thickness = def.width * (0.34 - alpha * 0.07)
		local nk = mkPart(model, "GiantDinoNeckSegment",
			Vector3.new(def.length * 0.16, def.neckHeight * 0.23, thickness),
			cf * CFrame.new(sx, sy, 0) * CFrame.Angles(0, 0, math.rad(-19 + alpha * 9)),
			def.color, Enum.Material.SmoothPlastic, 0.01, false, Enum.PartType.Ball)
		neckParts[segment]        = nk
		neckLocalCFrames[segment] = body.CFrame:ToObjectSpace(nk.CFrame)
		mkPart(model, "NeckCrestPlate",
			Vector3.new(2.4 * sc, 5.2 * sc, thickness * 0.56),
			cf * CFrame.new(sx - 1.5 * sc, sy + thickness * 0.32, 0) * CFrame.Angles(0, 0, math.rad(25)),
			def.accent, Enum.Material.Neon, 0.08, true)
	end

	local head = mkBall(model, "GiantDinoHead", def.headSize,
		cf * CFrame.new(def.length * 0.78, def.headY, 0),
		def.color, Enum.Material.SmoothPlastic, 0.01, false)

	local snout = mkPart(model, "GiantDinoSnout",
		Vector3.new(def.headSize * 0.82, def.headSize * 0.28, def.headSize * 0.42),
		cf * CFrame.new(def.length * 0.94, def.headY - 0.45 * sc, 0),
		def.accent, Enum.Material.SmoothPlastic, 0.01)

	for _, side in { -1, 1 } do
		mkBall(model, "BrowRidge", def.headSize * 0.22,
			cf * CFrame.new(def.length * 0.84, def.headY + def.headSize * 0.34, side * def.headSize * 0.28),
			def.accent, Enum.Material.Neon, 0.08, true)
	end

	for _, xOff in { -def.length * 0.25, def.length * 0.22 } do
		for _, zOff in { -def.width * 0.32, def.width * 0.32 } do
			mkPart(model, "GiantDinoLeg",
				Vector3.new(5 * sc, def.legHeight, 5 * sc),
				cf * CFrame.new(xOff, -1 * sc, zOff),
				def.color, Enum.Material.SmoothPlastic, 0.01)
			mkBall(model, "GiantDinoFoot", 6 * sc,
				cf * CFrame.new(xOff + 2 * sc, -def.legHeight * 0.45, zOff),
				def.accent, Enum.Material.SmoothPlastic, 0.02, false)
		end
	end

	addDetails(model, cf, def)

	model.PrimaryPart = body
	BoundaryService.bindModel(model, BOUNDS, { margin = MARGIN, minY = FLOOR_Y, maxY = FLOOR_Y + 120 })

	-- Ground body Y (feet on floor, same formula as spawn)
	local groundBodyY = FLOOR_Y + def.legHeight * 0.45 + sc * 3 + 8 * sc

	local dino = {
		model             = model,
		body              = body,
		head              = head,
		snout             = snout,
		neckParts         = neckParts,
		neckLocalCFrames  = neckLocalCFrames,
		headLocalCFrame   = body.CFrame:ToObjectSpace(head.CFrame),
		snoutLocalCFrame  = body.CFrame:ToObjectSpace(snout.CFrame),
		scale             = sc,
		legHeight         = def.legHeight,
		hitRadius         = body.Size.X / 2 + 5,
		length            = def.length,
		width             = def.width,
		speed             = def.speed,
		baseSpeed         = def.speed,
		heading           = Vector3.new(1, 0, 0),
		walkPhase         = math.random() * math.pi * 2,
		neckYaw           = 0,
		target            = Vector3.new(def.x, FLOOR_Y + 1, def.z),
		targetTimer       = math.random(4, 12),
		caught            = false,
		frozen            = false,
		hp                = HITS_TO_DEFEAT,
		-- Jump state
		groundBodyY       = groundBodyY,
		jumpPeakH         = def.jumpPeakH or 35,
		jumpDuration      = def.jumpDuration or 1.4,
		jumpTimer         = math.random(4, 14),
		inJump            = false,
		jumpT             = 0,
		jumpOffset        = 0,
	}
	return dino
end

-- ── definitions (10 electric-colored jumping dinos) ─────────────────────────

-- All X/Z inside BOUNDS: X=110..810, Z=470..1030
local dinoDefs = {
	{ name = "Plasma Rex I",      x = 210, z = 510,  scale = 1.4, speed = 14, jumpPeakH = 40, jumpDuration = 1.5,
	  color = "Bright blue",    belly = "Cyan",           accent = "Cyan",
	  length = 80, height = 32, width = 30, bodySize = 44, headSize = 15,
	  neckHeight = 74, legHeight = 38, headY = 96,  neckY = 55 },

	{ name = "Plasma Rex II",     x = 720, z = 990,  scale = 1.3, speed = 16, jumpPeakH = 35, jumpDuration = 1.3,
	  color = "Bright blue",    belly = "Cyan",           accent = "Lime green",
	  length = 74, height = 29, width = 28, bodySize = 40, headSize = 14,
	  neckHeight = 68, legHeight = 34, headY = 88,  neckY = 50 },

	{ name = "Volt Titan I",      x = 460, z = 540,  scale = 1.6, speed = 12, jumpPeakH = 50, jumpDuration = 1.7,
	  color = "Dark indigo",    belly = "Bright violet",  accent = "Bright violet",
	  length = 90, height = 36, width = 34, bodySize = 50, headSize = 17,
	  neckHeight = 84, legHeight = 43, headY = 106, neckY = 62 },

	{ name = "Volt Titan II",     x = 180, z = 860,  scale = 1.5, speed = 13, jumpPeakH = 45, jumpDuration = 1.6,
	  color = "Dark indigo",    belly = "Bright violet",  accent = "Magenta",
	  length = 86, height = 34, width = 32, bodySize = 47, headSize = 16,
	  neckHeight = 80, legHeight = 40, headY = 100, neckY = 58 },

	{ name = "Neon Stalker I",    x = 660, z = 750, scale = 1.2, speed = 18, jumpPeakH = 30, jumpDuration = 1.2,
	  color = "Lime green",     belly = "Bright green",   accent = "Bright yellow",
	  length = 66, height = 26, width = 25, bodySize = 36, headSize = 12,
	  neckHeight = 61, legHeight = 30, headY = 80,  neckY = 45 },

	{ name = "Neon Stalker II",   x = 280, z = 710, scale = 1.3, speed = 17, jumpPeakH = 32, jumpDuration = 1.2,
	  color = "Lime green",     belly = "Bright green",   accent = "Cyan",
	  length = 72, height = 28, width = 27, bodySize = 39, headSize = 13,
	  neckHeight = 66, legHeight = 33, headY = 86,  neckY = 49 },

	{ name = "Arc Crusher I",     x = 770, z = 530,  scale = 1.6, speed = 12, jumpPeakH = 55, jumpDuration = 1.8,
	  color = "Bright violet",  belly = "Magenta",         accent = "Hot pink",
	  length = 90, height = 36, width = 34, bodySize = 50, headSize = 17,
	  neckHeight = 84, legHeight = 43, headY = 106, neckY = 62 },

	{ name = "Arc Crusher II",    x = 150, z = 970,  scale = 1.5, speed = 14, jumpPeakH = 42, jumpDuration = 1.5,
	  color = "Bright violet",  belly = "Magenta",         accent = "Bright blue",
	  length = 86, height = 35, width = 33, bodySize = 48, headSize = 17,
	  neckHeight = 80, legHeight = 41, headY = 102, neckY = 60 },

	{ name = "Surge Colossus",    x = 540, z = 960,  scale = 1.4, speed = 15, jumpPeakH = 38, jumpDuration = 1.4,
	  color = "Cyan",           belly = "Bright blue",     accent = "New Yeller",
	  length = 80, height = 32, width = 30, bodySize = 44, headSize = 15,
	  neckHeight = 74, legHeight = 38, headY = 96,  neckY = 55 },

	{ name = "Thunder Titan",     x = 360, z = 850,  scale = 1.5, speed = 13, jumpPeakH = 44, jumpDuration = 1.6,
	  color = "Cyan",           belly = "Bright blue",     accent = "Bright violet",
	  length = 86, height = 34, width = 32, bodySize = 47, headSize = 16,
	  neckHeight = 80, legHeight = 40, headY = 100, neckY = 58 },
}

-- ── state ────────────────────────────────────────────────────────────────────

for _, def in dinoDefs do
	def.x += -1780
	def.z += 950
end

local activeDinos = {}
local catches     = 0

local function addCash(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local cash  = stats and stats:FindFirstChild("Cash")
	if cash then cash.Value += amount end
end

local function pickTarget(dino)
	local rx = BOUNDS.minX + MARGIN + math.random() * (BOUNDS.maxX - BOUNDS.minX - MARGIN * 2)
	local rz = BOUNDS.minZ + MARGIN + math.random() * (BOUNDS.maxZ - BOUNDS.minZ - MARGIN * 2)
	dino.target      = Vector3.new(rx, FLOOR_Y + 1, rz)
	dino.targetTimer = math.random(8, 20)
end

local CYCLE_COLORS = {
	BrickColor.new("Cyan"),
	BrickColor.new("Bright blue"),
	BrickColor.new("Bright violet"),
	BrickColor.new("Hot pink"),
	BrickColor.new("Lime green"),
	BrickColor.new("New Yeller"),
}

local function startColorCycle(dino)
	local skip = { Eye = true, Pupil = true, ToeClaw = true }
	local bodyParts = {}
	for _, desc in dino.model:GetDescendants() do
		if desc:IsA("BasePart") and not skip[desc.Name] then
			table.insert(bodyParts, desc)
		end
	end
	task.spawn(function()
		local idx = 1
		while dino.model.Parent and not dino.caught do
			local col = CYCLE_COLORS[idx]
			for _, p in bodyParts do
				if p.Parent then p.BrickColor = col end
			end
			idx = idx % #CYCLE_COLORS + 1
			task.wait(0.18)
		end
	end)
end

local function markLastDino(dino)
	if dino.isLastDino then return end
	dino.isLastDino = true
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 240, 0, 64)
	bb.StudsOffset = Vector3.new(0, dino.body.Size.Y + 12, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 200
	bb.Parent      = dino.body
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "⚡  LAST DINO  ⚡"
	lbl.TextColor3             = Color3.fromRGB(100, 220, 255)
	lbl.TextStrokeTransparency = 0
	lbl.Font                   = Enum.Font.GothamBlack
	lbl.TextScaled             = true
	lbl.Parent                 = bb
end

local function defeatDino(dino, player)
	if dino.caught then return end
	dino.caught = true

	catches           += 1
	stageNeeded.Value  = NEEDED
	stageHits.Value    = catches
	remaining.Value    = math.max(0, remaining.Value - 1)
	addCash(player, CASH_PER_HIT)
	if player and playerScored then playerScored:Fire(player, "Storm Dome") end

	for _, desc in dino.model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.BrickColor = BrickColor.new("Cyan")
			desc.Material   = Enum.Material.Neon
			TweenService:Create(desc, TweenInfo.new(0.7), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.8, function()
		if dino.model.Parent then dino.model:Destroy() end
	end)
	for i, d in activeDinos do
		if d == dino then table.remove(activeDinos, i) break end
	end

	if #activeDinos == 1 then
		markLastDino(activeDinos[1])
	end
end

local HIT_STATE = {
	[2] = { scale = 0.72, color = BrickColor.new("Bright orange"), speedMult = 7.0  },
	[1] = { scale = 0.48, color = BrickColor.new("Hot pink"),      speedMult = 13.0 },
}

local hitDebounce = {}

local function applyHitState(dino)
	local state = HIT_STATE[dino.hp]
	if not state then return end

	dino.frozen = true
	dino.model:ScaleTo(state.scale)

	do
		local pivot    = dino.model:GetPivot()
		local correctY = FLOOR_Y + state.scale * (dino.legHeight * 0.45 + dino.scale * 11)
		dino.model:PivotTo(pivot + Vector3.new(0, correctY - pivot.Position.Y, 0))
		dino.groundBodyY = correctY
	end

	dino.headLocalCFrame  = dino.body.CFrame:ToObjectSpace(dino.head.CFrame)
	dino.snoutLocalCFrame = dino.body.CFrame:ToObjectSpace(dino.snout.CFrame)
	for i, nk in dino.neckParts do
		dino.neckLocalCFrames[i] = dino.body.CFrame:ToObjectSpace(nk.CFrame)
	end
	dino.hitRadius = dino.body.Size.X / 2 + 5

	local skip = { Eye = true, Pupil = true, ToeClaw = true }
	for _, part in dino.model:GetDescendants() do
		if part:IsA("BasePart") and not skip[part.Name] then
			part.BrickColor = state.color
		end
	end

	dino.speed = dino.baseSpeed * state.speedMult

	if dino.hp == 1 then
		startColorCycle(dino)
	end

	task.delay(0.4, function()
		if dino.model.Parent and not dino.caught then
			dino.frozen = false
		end
	end)
end

local function onBallHit(dino, hit)
	if dino.caught then return end
	if hit.Name ~= "Ball" then return end
	if not hit:GetAttribute("BallType") then return end
	if not hit:GetAttribute("IsThrown") then return end

	local now = os.clock()
	local last = hitDebounce[hit]
	if last and now - last < 0.2 then return end
	hitDebounce[hit] = now

	hit:Destroy()

	local throwerName = hit:GetAttribute("ThrowerName")
	local shooter = nil
	if throwerName then
		for _, p in Players:GetPlayers() do
			if p.Name == throwerName then shooter = p break end
		end
	end

	dino.hp = math.max(0, dino.hp - 1)
	addCash(shooter, CASH_PER_HIT)

	local speedMultipliers = { [2] = 7.0, [1] = 13.0 }
	local mult = speedMultipliers[dino.hp]
	if mult then
		dino.speed = dino.baseSpeed * mult
	end

	if dino.hp <= 0 then
		defeatDino(dino, shooter)
	else
		applyHitState(dino)
	end
end

local function updateNeckPose(dino, dt)
	local pivot     = dino.model:GetPivot()
	local localLook = pivot:VectorToObjectSpace(Vector3.new(dino.heading.X, 0, dino.heading.Z))
	local yaw       = math.clamp(math.atan2(localLook.Z, localLook.X), math.rad(-32), math.rad(32))
	dino.neckYaw    = dino.neckYaw + (yaw - dino.neckYaw) * (1 - math.exp(-dt * 5))

	for index, nk in dino.neckParts do
		local alpha = index / #dino.neckParts
		local base  = pivot * dino.neckLocalCFrames[index]
		nk.CFrame   = base * CFrame.Angles(0,
			dino.neckYaw * alpha * 0.75,
			math.sin(dino.walkPhase + alpha) * math.rad(1.2) * alpha)
	end
	dino.head.CFrame  = (pivot * dino.headLocalCFrame)  * CFrame.Angles(0, dino.neckYaw, 0)
	dino.snout.CFrame = (pivot * dino.snoutLocalCFrame) * CFrame.Angles(0, dino.neckYaw, 0)
end

-- ── spawn ────────────────────────────────────────────────────────────────────

local function spawnAll()
	for _, def in dinoDefs do
		local dino = buildDino(def)
		pickTarget(dino)
		table.insert(activeDinos, dino)
	end
end

-- ── presence tracking ────────────────────────────────────────────────────────

local alive = false

local function anyPlayerInBounds()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local p = hrp.Position
			if p.X >= BOUNDS.minX and p.X <= BOUNDS.maxX
				and p.Z >= BOUNDS.minZ and p.Z <= BOUNDS.maxZ then
				return true
			end
		end
	end
	return false
end

local function doSpawnAll()
	if alive then return end
	alive = true
	catches           = 0
	remaining.Value   = NEEDED
	totalVal.Value    = NEEDED
	stageNeeded.Value = NEEDED
	stageHits.Value   = 0
	spawnAll()
end

local function doDespawnAll()
	if not alive then return end
	alive = false
	for _, dino in activeDinos do
		if dino.model.Parent then dino.model:Destroy() end
	end
	table.clear(activeDinos)
	table.clear(hitDebounce)
	catches         = 0
	remaining.Value = NEEDED
	stageHits.Value = 0
end

task.spawn(function()
	while true do
		task.wait(2)
		if anyPlayerInBounds() then
			doSpawnAll()
		else
			doDespawnAll()
		end
	end
end)

-- ── main loop ────────────────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function(dt)
	if not alive then return end

	local thrownBalls = {}
	for _, obj in workspace:GetChildren() do
		if obj.Name == "Ball" and obj:IsA("BasePart") and obj:GetAttribute("IsThrown") then
			table.insert(thrownBalls, obj)
		end
	end

	for _, dino in activeDinos do
		if not dino.model.Parent then continue end

		-- Proximity-based hit detection
		if not dino.caught then
			local bodyPos = dino.body.Position
			for _, ball in thrownBalls do
				if ball.Parent and (ball.Position - bodyPos).Magnitude < dino.hitRadius then
					onBallHit(dino, ball)
				end
			end
		end

		if dino.frozen then continue end

		-- ── Jump mechanic ──────────────────────────────────────────────────
		dino.jumpTimer -= dt
		if not dino.inJump and dino.jumpTimer <= 0 then
			dino.inJump  = true
			dino.jumpT   = 0
			dino.jumpTimer = dino.jumpDuration + math.random(6, 16)
		end

		if dino.inJump then
			dino.jumpT += dt
			local progress = dino.jumpT / dino.jumpDuration
			if progress >= 1 then
				dino.inJump     = false
				dino.jumpOffset = 0
			else
				dino.jumpOffset = math.sin(math.pi * progress) * dino.jumpPeakH
			end
		end

		-- ── Patrol movement ────────────────────────────────────────────────
		dino.targetTimer -= dt
		local pivot    = dino.model:GetPivot()
		local pos      = pivot.Position

		local timerMax = math.max(2, 10 - (HITS_TO_DEFEAT - dino.hp) * 3)
		local toTarget = dino.target - pos
		local flatDist = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude
		if flatDist < 10 or dino.targetTimer <= 0 then
			pickTarget(dino)
			dino.targetTimer = math.random(1, timerMax)
		end

		local desiredDir = flatDist > 0.5
			and Vector3.new(toTarget.X, 0, toTarget.Z).Unit
			or dino.heading

		local hitsDone  = HITS_TO_DEFEAT - dino.hp
		local jitter    = hitsDone * 0.55
		local perp      = Vector3.new(-desiredDir.Z, 0, desiredDir.X)
		local strafeDir = desiredDir + perp * (math.sin(dino.walkPhase * 3.1 + dino.neckYaw * 5) * jitter)
		if strafeDir.Magnitude > 0.001 then
			desiredDir = strafeDir.Unit
		end

		local turnRate = 4 + hitsDone * 3
		dino.heading = dino.heading:Lerp(desiredDir, 1 - math.exp(-dt * turnRate))
		if dino.heading.Magnitude > 0.001 then
			dino.heading = dino.heading.Unit
		end

		local slowFactor = math.min(flatDist / 20, 1)
		local vel        = dino.heading * dino.speed * slowFactor
		-- Always move at floor level; jump is applied separately so the dino returns on landing
		local flatPos    = Vector3.new(pos.X, FLOOR_Y, pos.Z)
		local newPos     = BoundaryService.clampPosition(
			flatPos + vel * dt, BOUNDS, MARGIN, FLOOR_Y, FLOOR_Y + 1)

		dino.walkPhase += dt * (2.0 + hitsDone * 1.5)
		local bob   = math.sin(dino.walkPhase * math.pi * 2) * 0.26 * dino.scale * slowFactor
		local right = dino.heading
		local back  = right:Cross(Vector3.yAxis)
		if back.Magnitude < 0.001 then back = Vector3.zAxis else back = back.Unit end

		-- Y is always groundBodyY + jump arc; newPos.X/Z carry the horizontal movement
		local targetY  = dino.groundBodyY + dino.jumpOffset + bob
		local targetCF = CFrame.fromMatrix(
			Vector3.new(newPos.X, targetY, newPos.Z),
			right, Vector3.yAxis, back)
		dino.model:PivotTo(pivot:Lerp(targetCF, 1 - math.exp(-dt * (6 + hitsDone * 4))))

		updateNeckPose(dino, dt)
	end
end)

-- ── world restart ─────────────────────────────────────────────────────────────

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Storm Dome" then return end
		doDespawnAll()
	end)
end)
