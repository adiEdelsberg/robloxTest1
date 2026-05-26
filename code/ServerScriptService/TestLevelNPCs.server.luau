-- TestLevelNPCs.server.luau
-- Test Level (order = -1): 10 giant black dinos in the red sky arena near the Clockwork Keep.
-- Identical dino behaviour to EmptyWorld1 but with NO game-progression tracking.
-- Dinos respawn automatically every 60 s after all are defeated.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage    = game:GetService("ServerStorage")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local BoundaryService  = require(ServerStorage:WaitForChild("WorldBoundaryService"))

-- Arena: cx=460, cz=-750, halfW=350, halfD=280, floorY=80
local BOUNDS         = { minX = 110, maxX = 810, minZ = -1030, maxZ = -470 }
local FLOOR_Y        = 80
local HITS_TO_DEFEAT = 3
local MARGIN         = 45
local CASH_PER_HIT   = 5   -- flat reward per hit (no Balance config dependency)

local Players = game:GetService("Players")

local folder = Instance.new("Folder")
folder.Name   = "TestLevelNPCs"
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
		aura.Color          = ColorSequence.new(BrickColor.new(def.accent).Color, Color3.fromRGB(20, 20, 20))
		aura.LightEmission  = 0.7
		aura.LightInfluence = 0
		aura.Lifetime       = NumberRange.new(0.9, 1.8)
		aura.Rate           = 6
		aura.Speed          = NumberRange.new(1, 3)
		aura.Size           = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6 * sc),
			NumberSequenceKeypoint.new(1, 0),
		})
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Parent      = body
	end
end

-- ── build one dino ───────────────────────────────────────────────────────────

local function buildDino(def)
	local model = Instance.new("Model")
	model.Name  = def.name
	model.Parent = folder

	local sc = def.scale
	-- Raise cf so foot bottoms (= cf.Y - legHeight*0.45 - 3*sc) sit exactly at FLOOR_Y
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

	local neckParts        = {}
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
	BoundaryService.bindModel(model, BOUNDS, { margin = MARGIN, minY = FLOOR_Y, maxY = FLOOR_Y + 70 })

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
	}
	return dino
end

-- ── dino definitions ─────────────────────────────────────────────────────────
-- All X/Z inside BOUNDS (X: 110..810, Z: -1030..-470)

local dinoDefs = {
	{ name = "Shadow Rex I",      x = 210, z = -900, scale = 1.4, speed = 14,
	  color = "Really black", belly = "Dark stone grey", accent = "Bright violet",
	  length = 80, height = 32, width = 30, bodySize = 44, headSize = 15,
	  neckHeight = 74, legHeight = 38, headY = 96,  neckY = 55 },

	{ name = "Shadow Rex II",     x = 720, z = -580, scale = 1.3, speed = 16,
	  color = "Really black", belly = "Dark stone grey", accent = "Cyan",
	  length = 74, height = 29, width = 28, bodySize = 40, headSize = 14,
	  neckHeight = 68, legHeight = 34, headY = 88,  neckY = 50 },

	{ name = "Dark Titan I",      x = 460, z = -510, scale = 1.6, speed = 12,
	  color = "Really black", belly = "Smoky grey",     accent = "Hot pink",
	  length = 90, height = 36, width = 34, bodySize = 50, headSize = 17,
	  neckHeight = 84, legHeight = 43, headY = 106, neckY = 62 },

	{ name = "Dark Titan II",     x = 180, z = -960, scale = 1.5, speed = 13,
	  color = "Really black", belly = "Smoky grey",     accent = "Bright orange",
	  length = 86, height = 34, width = 32, bodySize = 47, headSize = 16,
	  neckHeight = 80, legHeight = 40, headY = 100, neckY = 58 },

	{ name = "Void Stalker I",    x = 660, z = -750, scale = 1.2, speed = 18,
	  color = "Really black", belly = "Dark stone grey", accent = "Lime green",
	  length = 66, height = 26, width = 25, bodySize = 36, headSize = 12,
	  neckHeight = 61, legHeight = 30, headY = 80,  neckY = 45 },

	{ name = "Void Stalker II",   x = 280, z = -750, scale = 1.3, speed = 17,
	  color = "Really black", belly = "Dark stone grey", accent = "Bright yellow",
	  length = 72, height = 28, width = 27, bodySize = 39, headSize = 13,
	  neckHeight = 66, legHeight = 33, headY = 86,  neckY = 49 },

	{ name = "Night Crusher I",   x = 770, z = -500, scale = 1.6, speed = 12,
	  color = "Really black", belly = "Black",           accent = "Really red",
	  length = 90, height = 36, width = 34, bodySize = 50, headSize = 17,
	  neckHeight = 84, legHeight = 43, headY = 106, neckY = 62 },

	{ name = "Night Crusher II",  x = 150, z = -1000, scale = 1.5, speed = 14,
	  color = "Really black", belly = "Black",           accent = "Bright blue",
	  length = 86, height = 35, width = 33, bodySize = 48, headSize = 17,
	  neckHeight = 80, legHeight = 41, headY = 102, neckY = 60 },

	{ name = "Obsidian Colossus", x = 540, z = -980, scale = 1.4, speed = 15,
	  color = "Really black", belly = "Dark stone grey", accent = "New Yeller",
	  length = 80, height = 32, width = 30, bodySize = 44, headSize = 15,
	  neckHeight = 74, legHeight = 38, headY = 96,  neckY = 55 },

	{ name = "Abyss Titan",       x = 360, z = -620, scale = 1.5, speed = 13,
	  color = "Really black", belly = "Smoky grey",     accent = "Institutional white",
	  length = 86, height = 34, width = 32, bodySize = 47, headSize = 16,
	  neckHeight = 80, legHeight = 40, headY = 100, neckY = 58 },
}

-- ── state ────────────────────────────────────────────────────────────────────

local activeDinos = {}

local HIT_STATE = {
	[2] = { scale = 0.72, color = BrickColor.new("Bright orange"), speedMult = 1.8 },
	[1] = { scale = 0.48, color = BrickColor.new("Really red"),    speedMult = 2.8 },
}

local hitDebounce = {}

local function addCash(player, amount)
	local stats = player and player:FindFirstChild("leaderstats")
	local cash  = stats and stats:FindFirstChild("Cash")
	if cash then cash.Value += amount end
end

local function pickTarget(dino)
	local rx = BOUNDS.minX + MARGIN + math.random() * (BOUNDS.maxX - BOUNDS.minX - MARGIN * 2)
	local rz = BOUNDS.minZ + MARGIN + math.random() * (BOUNDS.maxZ - BOUNDS.minZ - MARGIN * 2)
	dino.target      = Vector3.new(rx, FLOOR_Y + 1, rz)
	dino.targetTimer = math.random(8, 20)
end

local function defeatDino(dino, player)
	if dino.caught then return end
	dino.caught = true

	addCash(player, CASH_PER_HIT * 3)

	for _, desc in dino.model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.BrickColor = BrickColor.new("Bright orange")
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

	-- Auto-respawn all dinos 60 s after the last one is defeated
	if #activeDinos == 0 then
		task.delay(60, function()
			for _, def in dinoDefs do
				local d = buildDino(def)
				pickTarget(d)
				table.insert(activeDinos, d)
				for _, part in d.model:GetDescendants() do
					if part:IsA("BasePart") and part.CanCollide then
						part.Touched:Connect(function(hit) onBallHit(d, hit) end)
					end
				end
			end
		end)
	end
end

local function applyHitState(dino)
	local state = HIT_STATE[dino.hp]
	if not state then return end

	dino.frozen = true
	dino.model:ScaleTo(state.scale)

	-- Re-cache local CFrames after ScaleTo repositions parts
	local pivot = dino.model:GetPivot()
	dino.headLocalCFrame  = pivot:ToObjectSpace(dino.head.CFrame)
	dino.snoutLocalCFrame = pivot:ToObjectSpace(dino.snout.CFrame)
	for i, nk in dino.neckParts do
		dino.neckLocalCFrames[i] = pivot:ToObjectSpace(nk.CFrame)
	end

	for _, desc in dino.model:GetDescendants() do
		if desc:IsA("BasePart")
			and desc.Name ~= "Eye" and desc.Name ~= "Pupil"
			and desc.Name ~= "EyeGlow" and desc.Name ~= "ToeClaw" then
			desc.BrickColor = state.color
		end
	end

	dino.speed = dino.baseSpeed * state.speedMult

	task.delay(0.4, function() dino.frozen = false end)
end

-- Forward declaration so defeatDino can reference it
local onBallHit
onBallHit = function(dino, hit)
	if dino.caught then return end
	if hit.Name ~= "Ball" then return end
	if not hit:GetAttribute("BallType") then return end
	if not hit:GetAttribute("IsThrown") then return end

	local now  = os.clock()
	local last = hitDebounce[hit]
	if last and now - last < 0.2 then return end
	hitDebounce[hit] = now

	local shooterName = hit:GetAttribute("ThrowerName")
	local shooter     = shooterName and Players:FindFirstChild(shooterName)
	local damage      = hit:GetAttribute("Damage") or 1

	dino.hp = math.max(0, dino.hp - damage)
	if shooter then addCash(shooter, CASH_PER_HIT) end

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

-- ── presence tracking ────────────────────────────────────────────────────────
-- Dinos only live while at least one player is at the Clockwork Keep landing world.
-- The moment everyone leaves, all dinos are destroyed; they respawn when someone returns.

local alive = false   -- true while dinos are spawned

local function countAtLanding()
	local n = 0
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InLandingWorld") then n += 1 end
	end
	return n
end

local function spawnAll()
	if alive then return end
	alive = true
	for _, def in dinoDefs do
		local dino = buildDino(def)
		pickTarget(dino)
		table.insert(activeDinos, dino)
		for _, pt in dino.model:GetDescendants() do
			if pt:IsA("BasePart") and pt.CanCollide then
				pt.Touched:Connect(function(hit) onBallHit(dino, hit) end)
			end
		end
	end
end

local function despawnAll()
	if not alive then return end
	alive = false
	for _, dino in activeDinos do
		if dino.model.Parent then dino.model:Destroy() end
	end
	table.clear(activeDinos)
	table.clear(hitDebounce)
end

local function refresh()
	if countAtLanding() > 0 then
		spawnAll()
	else
		despawnAll()
	end
end

-- Watch every player's InLandingWorld attribute
local function watchPlayer(player)
	player:GetAttributeChangedSignal("InLandingWorld"):Connect(refresh)
end

for _, p in Players:GetPlayers() do watchPlayer(p) end
Players.PlayerAdded:Connect(function(p)
	watchPlayer(p)
	-- attribute may already be set by the time we connect
	task.defer(refresh)
end)
Players.PlayerRemoving:Connect(function()
	task.defer(refresh)  -- re-check after the player is fully gone
end)

-- Initial check (someone may already be in the landing world on script start)
refresh()

-- ── main loop ─────────────────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function(dt)
	if not alive then return end
	for _, dino in activeDinos do
		if not dino.model.Parent then continue end
		if dino.frozen then continue end

		dino.targetTimer -= dt
		local pivot    = dino.model:GetPivot()
		local pos      = pivot.Position
		local toTarget = dino.target - pos
		local flatDist = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude

		if flatDist < 14 or dino.targetTimer <= 0 then
			pickTarget(dino)
		end

		local desiredDir = flatDist > 0.5
			and Vector3.new(toTarget.X, 0, toTarget.Z).Unit
			or dino.heading
		dino.heading = dino.heading:Lerp(desiredDir, 1 - math.exp(-dt * 3))
		if dino.heading.Magnitude > 0.001 then
			dino.heading = dino.heading.Unit
		end

		local slowFactor = math.min(flatDist / 25, 1)
		local vel        = dino.heading * dino.speed * slowFactor
		local newPos     = BoundaryService.clampPosition(
			pos + vel * dt, BOUNDS, MARGIN, FLOOR_Y, FLOOR_Y + 70)

		dino.walkPhase += dt * 2.0
		local bob   = math.sin(dino.walkPhase * math.pi * 2) * 0.26 * dino.scale * slowFactor
		local right = dino.heading
		local back  = right:Cross(Vector3.yAxis)
		if back.Magnitude < 0.001 then back = Vector3.zAxis else back = back.Unit end
		local targetCF = CFrame.fromMatrix(newPos + Vector3.new(0, bob, 0), right, Vector3.yAxis, back)
		dino.model:PivotTo(pivot:Lerp(targetCF, 1 - math.exp(-dt * 6)))

		updateNeckPose(dino, dt)
	end
end)

print("[TestLevel] Test arena ready — dinos spawn only while players are at the Clockwork Keep.")
