local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage    = game:GetService("ServerStorage")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Debris           = game:GetService("Debris")

local function playSoundAt(id, _position)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = 1
    s.Parent = workspace
    s:Play()
    Debris:AddItem(s, 4)
end
local Balance          = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local BoundaryService = require(ServerStorage:WaitForChild("WorldBoundaryService"))

local GATE_X         = 2980
local GATE_Z         = 1700
local NEEDED         = Balance.StageTargets.GalacticOrchard
local CASH_PER_FRUIT = Balance.CatchRewards.GalacticFruit
local BOUNDS         = { minX = 2660, maxX = 2980, minZ = 1380, maxZ = 2020 }

local gameEvents  = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits   = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")
local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local dinoRemote = gameEvents:FindFirstChild("GiantDinoRideAction") or Instance.new("RemoteEvent")
dinoRemote.Name   = "GiantDinoRideAction"
dinoRemote.Parent = gameEvents

local fruitRemaining = Instance.new("NumberValue")
fruitRemaining.Name   = "GalacticFruitsRemaining"
fruitRemaining.Parent = gameEvents

local fruitTotal = Instance.new("NumberValue")
fruitTotal.Name   = "GalacticFruitsTotal"
fruitTotal.Parent = gameEvents

local folder = Instance.new("Folder")
folder.Name   = "GalacticFruitGameplay"
folder.Parent = workspace

local JUMP_POWERS = Balance.Movement.JumpPowers
local WALK_SPEEDS = Balance.Movement.WalkSpeeds
local BITE_REACH  = { [1]=48, [2]=64,  [3]=88 }

local fruitsEaten = 0
local gateOpen    = false
local riders      = {}
local dinos       = {}
local biteBusy    = {}
local fruitDecorations = {} -- [fruitPart] = {decor parts}
local activeFruits = {}

-- ── helpers ────────────────────────────────────────────────────────────────

local function setBoostsDisabled(player, disabled)
	local character = player.Character
	local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
	if disabled then
		if player:GetAttribute("DinoSavedSpeedBoost") == nil then
			player:SetAttribute("DinoSavedSpeedBoost", player:GetAttribute("SpeedBoost") or 0)
			player:SetAttribute("DinoSavedJumpBoost",  player:GetAttribute("JumpBoost")  or 0)
			player:SetAttribute("DinoSavedSkateboardMounted", player:GetAttribute("SkateboardMounted") == true)
		end
		player:SetAttribute("SpeedBoost", 0)
		player:SetAttribute("JumpBoost",  0)
		player:SetAttribute("SkateboardMounted", false)
		if character then
			local board = character:FindFirstChild("PrizeSkateboard")
			if board then board:Destroy() end
		end
		local eventsFolder = ReplicatedStorage:FindFirstChild("SpinWheelEvents")
		local skateState   = eventsFolder and eventsFolder:FindFirstChild("SkateboardState")
		if skateState then skateState:FireClient(player, false) end
	elseif player:GetAttribute("DinoSavedSpeedBoost") ~= nil then
		local savedSpeed = player:GetAttribute("DinoSavedSpeedBoost") or 0
		local savedJump  = player:GetAttribute("DinoSavedJumpBoost")  or 0
		player:SetAttribute("SpeedBoost", savedSpeed)
		player:SetAttribute("JumpBoost",  savedJump)
		player:SetAttribute("DinoSavedSpeedBoost",     nil)
		player:SetAttribute("DinoSavedJumpBoost",      nil)
		player:SetAttribute("DinoSavedSkateboardMounted", nil)
		if humanoid then
			humanoid.WalkSpeed  = WALK_SPEEDS[savedSpeed] or 16
			humanoid.JumpPower  = JUMP_POWERS[savedJump]  or 50
		end
	end
end

local function setJumpLocked(player, locked)
	local character = player.Character
	local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
	local hrp       = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid then return end
	if locked then
		if humanoid:GetAttribute("DinoOldJumpPower") == nil then
			humanoid:SetAttribute("DinoOldJumpPower",  humanoid.JumpPower)
			humanoid:SetAttribute("DinoOldJumpHeight", humanoid.JumpHeight)
		end
		humanoid.JumpPower  = 0
		humanoid.JumpHeight = 0
		humanoid.Jump       = false
		humanoid.AutoRotate = false
		humanoid.Sit        = false
		humanoid.PlatformStand = true
		if hrp then
			hrp.Anchored = true
			hrp.AssemblyLinearVelocity  = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	else
		local oldPower  = humanoid:GetAttribute("DinoOldJumpPower")
		local oldHeight = humanoid:GetAttribute("DinoOldJumpHeight")
		if oldPower  then humanoid.JumpPower  = oldPower  end
		if oldHeight then humanoid.JumpHeight = oldHeight end
		humanoid:SetAttribute("DinoOldJumpPower",  nil)
		humanoid:SetAttribute("DinoOldJumpHeight", nil)
		humanoid.AutoRotate    = true
		humanoid.Sit           = false
		humanoid.PlatformStand = false
		if hrp then hrp.Anchored = false end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end

-- ── part builders ──────────────────────────────────────────────────────────

local function part(parent, name, size, cf, color, material, transparency, noCollide, shape)
	local p = Instance.new("Part")
	p.Name         = name
	p.Size         = size
	p.CFrame       = cf
	p.BrickColor   = BrickColor.new(color)
	p.Material     = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored     = true
	p.CanCollide   = not noCollide
	p.CanTouch     = true
	p.CastShadow   = false
	p.TopSurface   = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function ball(parent, name, size, cf, color, material, transparency, noCollide)
	return part(parent, name, Vector3.new(size, size, size), cf, color, material, transparency, noCollide, Enum.PartType.Ball)
end

-- ── cash effect ────────────────────────────────────────────────────────────

local function addCash(player, amount, cf)
	local stats = player and player:FindFirstChild("leaderstats")
	local cash  = stats and stats:FindFirstChild("Cash")
	if cash then cash.Value += amount end

	local effect = part(folder, "GalacticFruitCashEffect", Vector3.new(1,1,1), cf, "Cyan", Enum.Material.SmoothPlastic, 1, true)
	effect.CanTouch = false
	local sound = Instance.new("Sound")
	sound.SoundId      = "rbxassetid://12221967"
	sound.Volume       = 1
	sound.PlaybackSpeed = 1.45
	sound.Parent = effect
	sound:Play()
	local particles = Instance.new("ParticleEmitter")
	particles.Color        = ColorSequence.new(Color3.fromRGB(80,240,255), Color3.fromRGB(255,80,220))
	particles.LightEmission = 1
	particles.LightInfluence = 0
	particles.Lifetime     = NumberRange.new(0.5, 0.9)
	particles.Speed        = NumberRange.new(10, 22)
	particles.SpreadAngle  = Vector2.new(180, 180)
	particles.Rate         = 0
	particles.Parent = effect
	particles:Emit(42)
	task.delay(1.2, function()
		if effect.Parent then effect:Destroy() end
	end)
end

-- ── gate open ──────────────────────────────────────────────────────────────

local function spawnGateCarpet()
	local cx = GATE_X - 9
	local carpet = Instance.new("Part")
	carpet.Name       = "GalacticFruitCarpet"
	carpet.Size       = Vector3.new(10, 0.4, 40)
	carpet.CFrame     = CFrame.new(cx, 1.2, GATE_Z)
	carpet.BrickColor = BrickColor.new("Cyan")
	carpet.Material   = Enum.Material.Neon
	carpet.Transparency = 0.28
	carpet.Anchored   = true
	carpet.Parent     = workspace

	local glow = Instance.new("Part")
	glow.Size       = Vector3.new(7, 0.12, 36)
	glow.CFrame     = CFrame.new(cx, 1.45, GATE_Z)
	glow.BrickColor = BrickColor.new("Bright violet")
	glow.Material   = Enum.Material.Neon
	glow.Transparency = 0.65
	glow.Anchored   = true
	glow.CanCollide = false
	glow.Parent     = workspace

	local carpetCooldown = {}
	task.spawn(function()
		while carpet.Parent do
			task.wait(0.1)
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local pos = hrp.Position
					if pos.X > GATE_X - 22 and pos.X < GATE_X + 6
						and math.abs(pos.Z - GATE_Z) < 22 and pos.Y < 18 then
						local now = os.clock()
						if not carpetCooldown[player] or now - carpetCooldown[player] >= 2 then
							carpetCooldown[player] = now
							hrp.AssemblyLinearVelocity = Vector3.new(90, 28, 0)
						end
					end
				end
			end
		end
	end)
end

local function openGate()
	if gateOpen then return end
	gateOpen = true
	fruitRemaining.Value = 0

	local dismounted = {}
	for player in pairs(riders) do
		table.insert(dismounted, player)
	end
	for _, player in dismounted do
		dismount(player)
	end

	local event = gameEvents:FindFirstChild("GateOpenNotify")
	if event then event:FireAllClients("Galactic Fruit Orchard") end
	stageHits.Value = NEEDED
end

-- ── fruit ──────────────────────────────────────────────────────────────────

local function eatFruit(fruit, headOrDino)
	if not fruit.Parent or fruit:GetAttribute("Eaten") then return end
	if gateOpen then return end
	local dino
	if typeof(headOrDino) == "table" then
		dino = headOrDino
	elseif headOrDino and headOrDino.Name == "GiantDinoHead" then
		dino = dinos[headOrDino.Parent]
	end
	if not dino then return end
	if dino.fruitColor ~= fruit:GetAttribute("FruitColor") then return end

	fruit:SetAttribute("Eaten", true)
	fruit.CanTouch = false
	playSoundAt("rbxassetid://9125402735", fruit.Position)
	fruitsEaten += 1
	fruitRemaining.Value = math.max(0, fruitRemaining.Value - 1)
	if not gateOpen then
		stageNeeded.Value = NEEDED
		stageHits.Value = fruitsEaten
	end
	addCash(dino.rider, CASH_PER_FRUIT, fruit.CFrame)
	if dino.rider and playerScored then playerScored:Fire(dino.rider, "Galactic Orchard") end

	local decors = fruitDecorations[fruit]
	fruitDecorations[fruit] = nil
	if decors then
		for _, d in decors do
			TweenService:Create(d, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
			task.delay(0.45, function() if d.Parent then d:Destroy() end end)
		end
	end

	local pop = Instance.new("ParticleEmitter")
	pop.Color          = ColorSequence.new(Color3.fromRGB(80, 240, 255), Color3.fromRGB(255, 80, 220))
	pop.LightEmission  = 1
	pop.LightInfluence = 0
	pop.Lifetime       = NumberRange.new(0.45, 0.85)
	pop.Speed          = NumberRange.new(14, 32)
	pop.SpreadAngle    = Vector2.new(180, 180)
	pop.Rate           = 0
	pop.Size           = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
	pop.Parent = fruit
	pop:Emit(70)

	local origSize = fruit.Size
	local flashTween = TweenService:Create(fruit, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = origSize * 1.38,
	})
	flashTween:Play()
	flashTween.Completed:Connect(function()
		TweenService:Create(fruit, TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size         = Vector3.new(0.05, 0.05, 0.05),
			Transparency = 1,
			CFrame       = fruit.CFrame * CFrame.new(0, origSize.Y * 0.45, 0) * CFrame.Angles(0, math.rad(300), math.rad(40)),
		}):Play()
	end)
	task.delay(0.65, function()
		if fruit.Parent then fruit:Destroy() end
	end)
	if not gateOpen and (fruitsEaten >= NEEDED or fruitRemaining.Value <= 0) then
		openGate()
	end
end

local FRUIT_TIER = { Cyan = 1, ["Hot pink"] = 2, ["New Yeller"] = 3 }

local function findNearestReachableFruit(dino, bitePosition)
	local best, bestDist = nil, math.huge
	local reach = BITE_REACH[dino.reachTier] or 20
	for _, item in folder:GetChildren() do
		if item.Name == "GalacticFruit" and item:IsA("BasePart") and not item:GetAttribute("Eaten") then
			if item:GetAttribute("FruitColor") == dino.fruitColor then
				local distance = (item.Position - bitePosition).Magnitude
				if distance <= reach and distance < bestDist then
					best, bestDist = item, distance
				end
			end
		end
	end
	return best
end

local function makeFruit(cf, color)
	local tier = FRUIT_TIER[color] or 1
	local sz = 12 + tier * 3 -- 15, 18, 21

	local fruit = ball(folder, "GalacticFruit", sz, cf, color, Enum.Material.Neon, 0.04, true)
	fruit:SetAttribute("FruitColor", color)
	activeFruits[fruit] = true

	local stemH = sz * 0.55
	local stem = Instance.new("Part")
	stem.Name       = "GalacticFruitStem"
	stem.Size       = Vector3.new(1.4, stemH, 1.4)
	stem.CFrame     = CFrame.new(cf.Position + Vector3.new(0, sz * 0.5 + stemH * 0.5, 0))
	stem.BrickColor = BrickColor.new("Really black")
	stem.Material   = Enum.Material.Neon
	stem.Transparency = 0.3
	stem.Anchored   = true
	stem.CanCollide = false
	stem.CastShadow = false
	stem.Parent     = folder

	local leaf = Instance.new("Part")
	leaf.Name       = "GalacticFruitLeaf"
	leaf.Size       = Vector3.new(sz * 0.5, 0.4, sz * 0.32)
	leaf.CFrame     = CFrame.new(cf.Position + Vector3.new(sz * 0.2, sz * 0.5 + stemH * 0.9, 0)) * CFrame.Angles(0, 0, math.rad(25))
	leaf.BrickColor = BrickColor.new(color)
	leaf.Material   = Enum.Material.Neon
	leaf.Transparency = 0.2
	leaf.Anchored   = true
	leaf.CanCollide = false
	leaf.CastShadow = false
	leaf.Parent     = folder

	local ring = Instance.new("Part")
	ring.Name       = "GalacticFruitRing"
	ring.Shape      = Enum.PartType.Cylinder
	ring.Size       = Vector3.new(0.38, sz * 1.8, sz * 1.8)
	ring.CFrame     = CFrame.new(cf.Position) * CFrame.Angles(0, 0, math.rad(90))
	ring.BrickColor = BrickColor.new(color)
	ring.Material   = Enum.Material.Neon
	ring.Transparency = 0.72
	ring.Anchored   = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Parent     = folder

	fruitDecorations[fruit] = { stem, leaf, ring }

	local shine = Instance.new("PointLight")
	shine.Color      = BrickColor.new(color).Color
	shine.Brightness = 3.2
	shine.Range      = 38 + tier * 12
	shine.Parent     = fruit

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color        = ColorSequence.new(BrickColor.new(color).Color, Color3.fromRGB(255, 255, 255))
	sparkle.LightEmission  = 0.9
	sparkle.LightInfluence = 0
	sparkle.Lifetime     = NumberRange.new(1.0, 2.2)
	sparkle.Speed        = NumberRange.new(0.4, 2.5)
	sparkle.SpreadAngle  = Vector2.new(90, 90)
	sparkle.Rate         = 5 + tier * 2
	sparkle.Size         = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55 + tier * 0.18), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Parent       = fruit

	fruit.Touched:Connect(function(hit)
		eatFruit(fruit, hit)
	end)
	return fruit
end

-- ── mount / dismount ───────────────────────────────────────────────────────

local function dismount(player, keepPosition)
	local dino = riders[player]
	if not dino then return end
	riders[player] = nil
	dino.rider = nil
	player:SetAttribute("RidingGiantDino", false)
	setJumpLocked(player, false)
	setBoostsDisabled(player, false)
	for _, p in dino.allPrompts do p.ActionText = "Step On" end
	dinoRemote:FireClient(player, "Dismounted")

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and not keepPosition then
		hrp.CFrame = dino.model:GetPivot() * CFrame.new(-dino.length * 0.15, 10 + dino.scale * 2, -dino.width)
	end
end

local function mount(player, dino)
	if riders[player] then dismount(player) end
	if dino.rider and dino.rider ~= player then return end
	dino.rider = player
	riders[player] = dino
	player:SetAttribute("RidingGiantDino", true)
	setBoostsDisabled(player, true)
	setJumpLocked(player, true)
	dino.moveDirection = Vector3.zero
	dino.velocity      = Vector3.zero
	for _, p in dino.allPrompts do p.ActionText = "Drop" end
	dinoRemote:FireClient(player, "Mounted", dino.model, dino.head)

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = dino.safeSeat.CFrame * CFrame.new(0, 4.2 + dino.scale * 1.2, 0)
		hrp.AssemblyLinearVelocity  = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end

-- ── bite ───────────────────────────────────────────────────────────────────

local function triggerBite(dino)
	if biteBusy[dino] then return end
	biteBusy[dino] = true
	local head      = dino.head
	local snout     = dino.snout
	local headStart = head.CFrame
	local snoutStart = snout.CFrame
	local neckStarts = {}
	for _, neckPart in dino.neckParts do
		neckStarts[neckPart] = neckPart.CFrame
	end
	local lunge = dino.length * 0.34
	local dip   = -dino.reachTier * 3.1

	local headGoal  = headStart  * CFrame.new(lunge, dip, 0) * CFrame.Angles(0, 0, math.rad(-7))
	local snoutGoal = snoutStart * CFrame.new(lunge, dip, 0)
	for index, neckPart in dino.neckParts do
		local partLunge = lunge * (index / #dino.neckParts) * 0.42
		local partDip   = dip   * (index / #dino.neckParts) * 0.3
		TweenService:Create(neckPart, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = neckStarts[neckPart] * CFrame.new(partLunge, partDip, 0) * CFrame.Angles(0, 0, math.rad(-4 - index)),
		}):Play()
	end
	TweenService:Create(head,  TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = headGoal  }):Play()
	TweenService:Create(snout, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = snoutGoal }):Play()
	task.wait(0.22)
	local biteForward = dino.heading.Magnitude > 0.001 and dino.heading.Unit or Vector3.xAxis
	local bitePosition = snoutGoal.Position + biteForward * (dino.head.Size.X * 1.8)
	local fruit = findNearestReachableFruit(dino, bitePosition)
	if fruit then eatFruit(fruit, dino) end
	TweenService:Create(head, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = headStart }):Play()
	for neckPart, startCFrame in neckStarts do
		TweenService:Create(neckPart, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = startCFrame }):Play()
	end
	TweenService:Create(snout, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = snoutStart }):Play()
	task.wait(0.28)
	biteBusy[dino] = nil
end

-- ── neck pose ──────────────────────────────────────────────────────────────

local function updateNeckPose(dino, dt)
	if biteBusy[dino] then return end
	local pivot      = dino.model:GetPivot()
	local lookDirection = dino.lookDirection or dino.heading
	local localLook  = pivot:VectorToObjectSpace(Vector3.new(lookDirection.X, 0, lookDirection.Z))
	local yaw        = math.clamp(math.atan2(localLook.Z, localLook.X), math.rad(-32), math.rad(32))
	dino.neckYaw     = dino.neckYaw + (yaw - dino.neckYaw) * (1 - math.exp(-dt * 5.5))

	for index, neckPart in dino.neckParts do
		local alpha = index / #dino.neckParts
		local base  = pivot * dino.neckLocalCFrames[index]
		neckPart.CFrame = base * CFrame.Angles(0, dino.neckYaw * alpha * 0.75, math.sin(dino.walkPhase + alpha) * math.rad(1.2) * alpha)
	end
	dino.head.CFrame  = (pivot * dino.headLocalCFrame)  * CFrame.Angles(0, dino.neckYaw, 0)
	dino.snout.CFrame = (pivot * dino.snoutLocalCFrame) * CFrame.Angles(0, dino.neckYaw, 0)
	for index, decor in dino.headDecorParts do
		decor.CFrame = (pivot * dino.headDecorLocalCFrames[index]) * CFrame.Angles(0, dino.neckYaw, 0)
	end
end

-- ── galactic dino visuals ──────────────────────────────────────────────────

local function addGalacticDetails(model, cf, def, body, head, snout, headDecorParts, headDecorLocalCFrames)
	local starColors = { "Cyan", "Hot pink", "New Yeller", "Institutional white" }
	for band = -2, 2 do
		part(model, "NebulaRibPlate",
			Vector3.new(def.length * 0.12, 1.2 * def.scale, def.width * 0.92),
			cf * CFrame.new(band * def.length * 0.1, 18 * def.scale, 0) * CFrame.Angles(0, 0, math.rad(18)),
			def.accent, Enum.Material.Neon, 0.35, true)
	end
	for i = 1, 18 do
		local x = -def.length * 0.34 + (i % 6) * def.length * 0.12
		local z = ((i % 2 == 0) and 1 or -1) * (def.width * (0.34 + (i % 3) * 0.08))
		local y = 10 * def.scale + (i % 4) * 3.2 * def.scale
		ball(model, "GalacticStarSpot",
			0.9 * def.scale + (i % 3) * 0.25 * def.scale,
			cf * CFrame.new(x, y, z),
			starColors[(i % #starColors) + 1], Enum.Material.Neon, 0.08, true)
	end
	for _, side in { -1, 1 } do
		part(model, "CosmicJawLine",
			Vector3.new(def.headSize * 0.5, def.headSize * 0.12, def.headSize * 0.1),
			head.CFrame * CFrame.new(def.headSize * 0.12, -def.headSize * 0.33, side * def.headSize * 0.42),
			def.accent, Enum.Material.Neon, 0.05, true)
		part(model, "TempleFin",
			Vector3.new(def.headSize * 0.18, def.headSize * 0.5, def.headSize * 0.08),
			head.CFrame * CFrame.new(-def.headSize * 0.15, def.headSize * 0.25, side * def.headSize * 0.48) * CFrame.Angles(math.rad(18), 0, side * math.rad(18)),
			def.accent, Enum.Material.Neon, 0.08, true)
		ball(model, "GlowEye", def.headSize * 0.18,
			head.CFrame * CFrame.new(def.headSize * 0.25, def.headSize * 0.06, side * def.headSize * 0.42),
			side == 1 and "Cyan" or "Hot pink", Enum.Material.Neon, 0.02, true)
		ball(model, "DarkPupil", def.headSize * 0.08,
			head.CFrame * CFrame.new(def.headSize * 0.31, def.headSize * 0.06, side * def.headSize * 0.45),
			"Really black", Enum.Material.SmoothPlastic, 0, true)
	end
	for horn = -1, 1, 2 do
		part(model, "GalaxyHorn",
			Vector3.new(def.headSize * 0.16, def.headSize * 0.64, def.headSize * 0.16),
			head.CFrame * CFrame.new(-def.headSize * 0.18, def.headSize * 0.62, horn * def.headSize * 0.22) * CFrame.Angles(0, 0, horn * math.rad(15)),
			def.accent, Enum.Material.Neon, 0.04, true)
	end
	for dot = -1, 1 do
		ball(model, "SnoutGlowDot", def.headSize * 0.1,
			snout.CFrame * CFrame.new(def.headSize * 0.35, def.headSize * 0.08, dot * def.headSize * 0.17),
			"Institutional white", Enum.Material.Neon, 0.04, true)
	end
	local aura = Instance.new("ParticleEmitter")
	aura.Name          = "GalacticFruitDinoAura"
	aura.Color         = ColorSequence.new(Color3.fromRGB(80,230,255), Color3.fromRGB(255,70,200))
	aura.LightEmission  = 0.8
	aura.LightInfluence = 0
	aura.Lifetime      = NumberRange.new(1.2, 2)
	aura.Rate          = 10
	aura.Speed         = NumberRange.new(1.5, 4)
	aura.Size          = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7 * def.scale), NumberSequenceKeypoint.new(1, 0) })
	aura.SpreadAngle   = Vector2.new(180, 180)
	aura.Parent        = body

	for _, item in model:GetChildren() do
		if item:IsA("BasePart") and (
			item.Name == "CosmicJawLine" or item.Name == "TempleFin" or
			item.Name == "GlowEye"       or item.Name == "DarkPupil"  or
			item.Name == "GalaxyHorn"    or item.Name == "SnoutGlowDot") then
			headDecorParts[#headDecorParts + 1]      = item
			headDecorLocalCFrames[#headDecorLocalCFrames + 1] = body.CFrame:ToObjectSpace(item.CFrame)
		end
	end
end

local function addDinoSpikes(model, cf, def)
	local scale = def.scale
	for i = -3, 3 do
		local sz = 2.8 * scale * (1 - math.abs(i) * 0.08)
		part(model, "BackSpike",
			Vector3.new(sz, sz * 2.3, sz),
			cf * CFrame.new(i * 8 * scale, 17 * scale, 0) * CFrame.Angles(0, 0, math.rad(45)),
			def.accent, Enum.Material.Neon, 0.05, true)
	end
	for _, side in { -1, 1 } do
		ball(model, "CheekScale", 2.4 * scale, cf * CFrame.new(def.length * 0.5, 23 * scale, side * 5.3 * scale), def.accent, Enum.Material.Neon, 0.05, true)
		ball(model, "Eye", 2.1 * scale, cf * CFrame.new(def.length * 0.54, 25 * scale, side * 4.4 * scale), "Institutional white", Enum.Material.SmoothPlastic, 0, true)
		ball(model, "Pupil", 0.9 * scale, cf * CFrame.new(def.length * 0.56, 25 * scale, side * 4.7 * scale), "Really black", Enum.Material.SmoothPlastic, 0, true)
	end
	for _, side in { -1, 1 } do
		for step = 0, 2 do
			ball(model, "ToeClaw", 1.4 * scale, cf * CFrame.new(14 * scale - step * 12 * scale, 1.7 * scale, side * 7.7 * scale), "Institutional white", Enum.Material.SmoothPlastic, 0, true)
		end
	end
end

-- ── build dino ─────────────────────────────────────────────────────────────

local function labelPrompt(prompt, text)
	prompt.ActionText            = text
	prompt.ObjectText            = "Galactic Dino"
	prompt.HoldDuration          = 0
	prompt.MaxActivationDistance = 48
	prompt.RequiresLineOfSight   = false
end

local function buildGalacticDino(def)
	local model = Instance.new("Model")
	model.Name   = def.name
	model.Parent = folder

	local cf = CFrame.new(def.x, 1 + def.scale * 5, def.z)

	local body = ball(model, "GiantDinoBody", def.bodySize, cf * CFrame.new(0, 8 * def.scale, 0), def.color, Enum.Material.SmoothPlastic, 0.02, false)
	part(model, "GiantDinoBelly", Vector3.new(def.length * 0.55, def.height * 0.25, def.width * 0.82), cf * CFrame.new(5 * def.scale, 4.4 * def.scale, 0), def.belly, Enum.Material.SmoothPlastic, 0.02, true, Enum.PartType.Ball)
	part(model, "GiantDinoTail",  Vector3.new(def.length * 0.7,  def.height * 0.18, def.width * 0.25), cf * CFrame.new(-def.length * 0.62, 7 * def.scale, 0) * CFrame.Angles(0, 0, math.rad(-8)), def.color, Enum.Material.SmoothPlastic, 0.01)

	local neckParts       = {}
	local neckLocalCFrames = {}
	part(model, "NeckShoulderSocket", Vector3.new(def.length * 0.2, def.height * 0.34, def.width * 0.44), cf * CFrame.new(def.length * 0.2, def.neckY - 3 * def.scale, 0) * CFrame.Angles(0, 0, math.rad(-13)), def.color, Enum.Material.SmoothPlastic, 0.01, false, Enum.PartType.Ball)
	part(model, "NeckChestBlend",    Vector3.new(def.length * 0.18, def.height * 0.22, def.width * 0.5),  cf * CFrame.new(def.length * 0.13, def.neckY - 8 * def.scale, 0), def.belly, Enum.Material.SmoothPlastic, 0.06, false, Enum.PartType.Ball)
	for segment = 1, 6 do
		local alpha     = segment / 6
		local sx        = def.length * (0.18 + alpha * 0.44)
		local sy        = def.neckY + alpha * (def.headY - def.neckY) * 0.72
		local thickness = def.width * (0.34 - alpha * 0.07)
		local neckPart  = part(model, "GiantDinoNeckSegment", Vector3.new(def.length * 0.16, def.neckHeight * 0.23, thickness), cf * CFrame.new(sx, sy, 0) * CFrame.Angles(0, 0, math.rad(-19 + alpha * 9)), def.color, Enum.Material.SmoothPlastic, 0.01, false, Enum.PartType.Ball)
		neckParts[#neckParts + 1]       = neckPart
		neckLocalCFrames[#neckLocalCFrames + 1] = body.CFrame:ToObjectSpace(neckPart.CFrame)
		part(model, "NeckCrestPlate", Vector3.new(2.4 * def.scale, 5.2 * def.scale, thickness * 0.56), cf * CFrame.new(sx - 1.5 * def.scale, sy + thickness * 0.32, 0) * CFrame.Angles(0, 0, math.rad(25)), def.accent, Enum.Material.Neon, 0.08, true)
	end

	local head  = ball(model, "GiantDinoHead",  def.headSize, cf * CFrame.new(def.length * 0.78, def.headY, 0), def.color, Enum.Material.SmoothPlastic, 0.01, false)
	local snout = part(model, "GiantDinoSnout", Vector3.new(def.headSize * 0.82, def.headSize * 0.28, def.headSize * 0.42), cf * CFrame.new(def.length * 0.94, def.headY - 0.45 * def.scale, 0), def.accent, Enum.Material.SmoothPlastic, 0.01)

	local headDecorParts        = {
		ball(model, "BrowRidge", def.headSize * 0.22, cf * CFrame.new(def.length * 0.84, def.headY + def.headSize * 0.34, -def.headSize * 0.28), def.accent, Enum.Material.Neon, 0.08, true),
		ball(model, "BrowRidge", def.headSize * 0.22, cf * CFrame.new(def.length * 0.84, def.headY + def.headSize * 0.34,  def.headSize * 0.28), def.accent, Enum.Material.Neon, 0.08, true),
	}
	local headDecorLocalCFrames = {}
	for index, decor in headDecorParts do
		headDecorLocalCFrames[index] = body.CFrame:ToObjectSpace(decor.CFrame)
	end

	addGalacticDetails(model, cf, def, body, head, snout, headDecorParts, headDecorLocalCFrames)
	addDinoSpikes(model, cf, def)

	local saddle   = part(model, "RideSaddle",       Vector3.new(def.length * 0.33, 1.5, def.width * 0.52), cf * CFrame.new(-def.length * 0.02, def.saddleY, 0), def.accent, Enum.Material.Neon, 0.12, false)
	local safeSeat = part(model, "DinoSafeBackSeat", Vector3.new(def.length * 0.3,  0.7, def.width * 0.5),  cf * CFrame.new(-def.length * 0.24, def.saddleY + 2.2 * def.scale, 0), "Institutional white", Enum.Material.ForceField, 0.62, false)

	-- Step-on button (same as cherry grove)
	local stepButton = part(model, "DinoStepOnButton",     Vector3.new(10 * def.scale, 1.2, 10 * def.scale), cf * CFrame.new(def.length * 0.28, 1.2, -def.width * 0.78), "Really red", Enum.Material.Neon, 0.08, false, Enum.PartType.Ball)
	local stepGlow   = part(model, "DinoStepOnButtonGlow", Vector3.new(13 * def.scale, 0.18, 13 * def.scale), stepButton.CFrame * CFrame.new(0, -0.72, 0), def.accent, Enum.Material.Neon, 0.45, true, Enum.PartType.Ball)
	stepGlow.CanTouch = false

	for _, xOff in { -def.length * 0.25, def.length * 0.22 } do
		for _, zOff in { -def.width * 0.32, def.width * 0.32 } do
			part(model, "GiantDinoLeg",  Vector3.new(5 * def.scale, def.legHeight, 5 * def.scale), cf * CFrame.new(xOff, -1 * def.scale, zOff), def.color, Enum.Material.SmoothPlastic, 0.01)
			ball(model, "GiantDinoFoot", 6 * def.scale, cf * CFrame.new(xOff + 2 * def.scale, -def.legHeight * 0.45, zOff), def.accent, Enum.Material.SmoothPlastic, 0.02, false)
		end
	end

	model.PrimaryPart = body
	BoundaryService.bindModel(model, BOUNDS, { margin = 14, minY = 0, maxY = 90 })

	local function makePrompt(parent)
		local p = Instance.new("ProximityPrompt")
		labelPrompt(p, "Step On")
		p.ObjectText = def.name
		p.Parent = parent
		return p
	end
	local prompt = makePrompt(stepButton)
	local allPrompts = { prompt, makePrompt(body), makePrompt(head) }
	if #neckParts > 0 then
		table.insert(allPrompts, makePrompt(neckParts[math.ceil(#neckParts / 2)]))
	end

	local dino = {
		model               = model,
		body                = body,
		head                = head,
		neckParts           = neckParts,
		neckLocalCFrames    = neckLocalCFrames,
		headLocalCFrame     = body.CFrame:ToObjectSpace(head.CFrame),
		snoutLocalCFrame    = body.CFrame:ToObjectSpace(snout.CFrame),
		headDecorParts      = headDecorParts,
		headDecorLocalCFrames = headDecorLocalCFrames,
		snout               = snout,
		saddle              = saddle,
		safeSeat            = safeSeat,
		stepButton          = stepButton,
		prompt              = prompt,
		allPrompts          = allPrompts,
		scale               = def.scale,
		length              = def.length,
		width               = def.width,
		reachTier           = def.reachTier,
		fruitColor          = def.fruitColor,
		speed               = def.speed,
		y                   = cf.Position.Y,
		heading             = Vector3.new(1, 0, 0),
		lookDirection       = Vector3.new(1, 0, 0),
		moveDirection       = Vector3.zero,
		neckYaw             = 0,
		velocity            = Vector3.zero,
		walkPhase           = 0,
		rider               = nil,
	}
	dinos[model] = dino

	for _, p in allPrompts do
		p.Triggered:Connect(function(player)
			if riders[player] == dino then
				dismount(player)
			else
				mount(player, dino)
			end
		end)
	end

	return dino
end

-- ── dino definitions ───────────────────────────────────────────────────────
-- headY chosen so world-space head Y = (1 + scale*5) + headY ≈ fruit tier height
-- Tier-1 fruits ~40Y, Tier-2 ~66Y, Tier-3 ~98Y

local dinoDefs = {
	{ name = "Nebula Sprout",    x = 2730, z = 1630, scale = 0.82, reachTier = 1, fruitColor = "Cyan",       speed = 140,
	  color = "Navy blue",   belly = "Royal purple", accent = "Cyan",
	  length = 48,  height = 19, width = 19, bodySize = 25,  headSize = 9,
	  neckHeight = 36, legHeight = 20, headY = 44,  neckY = 28, saddleY = 25 },

	{ name = "Starfire Strider", x = 2840, z = 1765, scale = 1.1,  reachTier = 2, fruitColor = "Hot pink",   speed = 115,
	  color = "Really black", belly = "Bright violet", accent = "Hot pink",
	  length = 62,  height = 24, width = 24, bodySize = 33,  headSize = 11.5,
	  neckHeight = 52, legHeight = 27, headY = 66,  neckY = 40, saddleY = 35 },

	{ name = "Galaxy Titan",     x = 2910, z = 1695, scale = 1.42, reachTier = 3, fruitColor = "New Yeller", speed = 90,
	  color = "Dark indigo",  belly = "Royal purple", accent = "New Yeller",
	  length = 80,  height = 32, width = 31, bodySize = 43,  headSize = 15.5,
	  neckHeight = 74, legHeight = 38, headY = 96,  neckY = 54, saddleY = 47 },
}

-- ── fruit targets ──────────────────────────────────────────────────────────
-- Cyan fruits on short trees (~40Y) for Nebula Sprout
-- Hot pink on medium trees (~66Y) for Starfire Strider
-- New Yeller on tall trees (~96Y) for Galaxy Titan

local fruitTargets = {
	{ color = "Cyan",       x = 2710, z = 1415, y = 40 },
	{ color = "Cyan",       x = 2930, z = 1460, y = 38 },
	{ color = "Hot pink",   x = 2748, z = 1618, y = 62 },
	{ color = "Hot pink",   x = 2906, z = 1710, y = 66 },
	{ color = "Hot pink",   x = 2762, z = 1808, y = 70 },
	{ color = "New Yeller", x = 2718, z = 1908, y = 90 },
	{ color = "New Yeller", x = 2948, z = 1952, y = 96 },
	{ color = "New Yeller", x = 2836, z = 1992, y = 104 },
}

-- ── heartbeat ──────────────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function(dt)
	for player, dino in riders do
		if player:GetAttribute("CompletionAirLaunchActive") then
			dismount(player, true)
			continue
		end

		local character = player.Character
		local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
		local hrp       = character and character:FindFirstChild("HumanoidRootPart")
		if not character or not humanoid or humanoid.Health <= 0 or not hrp or not dino.model.Parent then
			dismount(player)
			continue
		end

		humanoid.Jump = false
		local pivot       = dino.model:GetPivot()
		local move        = dino.moveDirection or Vector3.zero
		local targetVelocity = Vector3.zero
		if move.Magnitude > 0.05 then
			targetVelocity = Vector3.new(move.X, 0, move.Z).Unit * dino.speed
		end
		local accelAlpha = 1 - math.exp(-dt * (targetVelocity.Magnitude > 0 and 4.5 or 7))
		dino.velocity = dino.velocity:Lerp(targetVelocity, accelAlpha)

		local flatVelocity = Vector3.new(dino.velocity.X, 0, dino.velocity.Z)
		if flatVelocity.Magnitude > 0.35 then
			local desiredHeading = flatVelocity.Unit
			local turnAlpha      = 1 - math.exp(-dt * 5.5)
			dino.heading         = dino.heading:Lerp(desiredHeading, turnAlpha)
			if dino.heading.Magnitude > 0.001 then
				dino.heading = dino.heading.Unit
			else
				dino.heading = desiredHeading
			end
		end

		local speedRatio = math.clamp(flatVelocity.Magnitude / math.max(dino.speed, 1), 0, 1)
		dino.walkPhase  += dt * (2.4 + dino.speed * 0.05) * speedRatio
		local nextPos    = BoundaryService.clampPosition(pivot.Position + flatVelocity * dt, BOUNDS, 18, 0, 90)
		local bob        = math.sin(dino.walkPhase * math.pi * 2) * 0.25 * dino.scale * speedRatio
		local right      = dino.heading.Magnitude > 0.001 and dino.heading.Unit or Vector3.xAxis
		local up         = Vector3.yAxis
		local back       = right:Cross(up)
		if back.Magnitude < 0.001 then back = Vector3.zAxis else back = back.Unit end
		local targetPivot = CFrame.fromMatrix(nextPos + Vector3.new(0, bob, 0), right, up, back)
		dino.model:PivotTo(pivot:Lerp(targetPivot, 1 - math.exp(-dt * 8)))
		updateNeckPose(dino, dt)

		hrp.CFrame = dino.safeSeat.CFrame * CFrame.new(0, 4.2 + dino.scale * 1.2, 0)
		hrp.AssemblyLinearVelocity  = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
end)

-- ── remote handler ─────────────────────────────────────────────────────────

task.spawn(function()
	local forceDinoDismount = gameEvents:WaitForChild("ForceDinoDismount", 30)
	if not forceDinoDismount then return end
	forceDinoDismount.Event:Connect(function(player)
		dismount(player, true)
	end)
end)

dinoRemote.OnServerEvent:Connect(function(player, action, payload)
	local dino = riders[player]
	if not dino then return end
	if action == "Bite" then
		task.spawn(triggerBite, dino)
	elseif action == "Drop" then
		dismount(player)
	elseif action == "Look" and typeof(payload) == "Vector3" then
		if payload.Magnitude > 0.05 then
			dino.lookDirection = Vector3.new(payload.X, 0, payload.Z).Unit
		end
	elseif action == "Move" and typeof(payload) == "Vector3" then
		if payload.Magnitude > 0.05 then
			dino.moveDirection = Vector3.new(payload.X, 0, payload.Z).Unit
		else
			dino.moveDirection = Vector3.zero
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	dismount(player)
end)

-- ── spawn when previous stage clears ──────────────────────────────────────

fruitTotal.Value     = NEEDED
fruitRemaining.Value = NEEDED

local function spawnGalacticFruits()
	stageNeeded.Value = NEEDED
	stageHits.Value   = 0
	for _, def in dinoDefs do
		buildGalacticDino(def)
	end
	for index, target in fruitTargets do
		local angle = math.rad(index * 47)
		makeFruit(CFrame.new(target.x + math.cos(angle) * 10, target.y, target.z + math.sin(angle) * 10), target.color)
	end
end

task.spawn(spawnGalacticFruits)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Galactic Orchard" then return end
		for fruit, decors in fruitDecorations do
			fruitDecorations[fruit] = nil
			for _, decor in decors do
				if decor.Parent then decor:Destroy() end
			end
			if fruit.Parent then fruit:Destroy() end
		end
		for fruit in activeFruits do
			activeFruits[fruit] = nil
			if fruit.Parent then fruit:Destroy() end
		end
		fruitsEaten = 0
		gateOpen = false
		fruitRemaining.Value = NEEDED
		spawnGalacticFruits()
	end)
end)
