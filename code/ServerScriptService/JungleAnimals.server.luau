local Players           = game:GetService("Players")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local NPC               = require(ServerStorage:WaitForChild("NPCModule"))
local BoundaryService   = require(ServerStorage:WaitForChild("WorldBoundaryService"))

local G = 1  -- ground Y

local BOUNDS = { minX = -65, maxX = 65, minZ = 645, maxZ = 775 }

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")

local stageHits   = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")

local jungleRemaining = Instance.new("NumberValue")
jungleRemaining.Name   = "JungleAnimalsRemaining"
jungleRemaining.Parent = gameEvents

local jungleTotal = Instance.new("NumberValue")
jungleTotal.Name   = "JungleAnimalsTotal"
jungleTotal.Parent = gameEvents

local NEEDED        = Balance.StageTargets.Jungle
local JUMPS_NEEDED  = Balance.StageCarpets.JumpsNeeded
local defeatsThisArea = 0
local jumpsThisArea  = 0

local C90  = CFrame.Angles(0, 0, math.rad(90))
local HT   = 1.3
local NEON = Enum.Material.Neon
local HOVER_BASE_Y = G + 3
local HOVER_BOB    = 1.2
local HOVER_MIN_Y  = G + 1.5   -- flies low, near ground
local HOVER_MAX_Y  = G + 22    -- surges very high on darts

-- Tier 4: flying animals with very high HP
local JUNGLE_ANIMALS = {
	{
		name = "Eagle", bodyColor = "Dark stone grey", headColor = "Nougat",
		maxHp = 5,
		minSpeed = 32, maxSpeed = 48, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Brown wings on sides
			{ size=Vector3.new(0.2,2.1,1.2), color="Reddish brown", parent="Torso",
			  cf=CFrame.new(-1.3,0.3,0.8)*CFrame.Angles(0, 0.5, 0.3) },
			{ size=Vector3.new(0.2,2.1,1.2), color="Reddish brown", parent="Torso",
			  cf=CFrame.new( 1.3,0.3,0.8)*CFrame.Angles(0,-0.5,-0.3) },
		},
	},
	{
		name = "Parrot", bodyColor = "Bright red", headColor = "Bright red",
		maxHp = 5,
		minSpeed = 28, maxSpeed = 44, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Red feather crest
			{ cyl=true, size=Vector3.new(0.3,2.5,2.5), color="Bright red", mat=NEON, cf=CFrame.new(0,HT+0.15,0)*C90 },
		},
	},
	{
		name = "Toucan", bodyColor = "Bright yellow", headColor = "Nougat",
		maxHp = 5,
		minSpeed = 26, maxSpeed = 40, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Yellow wings
			{ size=Vector3.new(0.2,1.8,1.0), color="Bright yellow", parent="Torso",
			  cf=CFrame.new(-1.2,0.5,0.7)*CFrame.Angles(0, 0.4, 0.25) },
			{ size=Vector3.new(0.2,1.8,1.0), color="Bright yellow", parent="Torso",
			  cf=CFrame.new( 1.2,0.5,0.7)*CFrame.Angles(0,-0.4,-0.25) },
		},
	},
	{
		name = "Hummingbird", bodyColor = "Bright green", headColor = "Hot pink",
		maxHp = 5,
		minSpeed = 42, maxSpeed = 60, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Shimmering iridescent wings
			{ size=Vector3.new(0.15,1.5,0.9), color="Cyan", mat=NEON, trans=0.2, parent="Torso",
			  cf=CFrame.new(-0.95,0.2,0.6)*CFrame.Angles(0, 0.35, 0.2) },
			{ size=Vector3.new(0.15,1.5,0.9), color="Cyan", mat=NEON, trans=0.2, parent="Torso",
			  cf=CFrame.new( 0.95,0.2,0.6)*CFrame.Angles(0,-0.35,-0.2) },
		},
	},
	{
		name = "Butterfly", bodyColor = "Hot pink", headColor = "Nougat",
		maxHp = 5,
		minSpeed = 30, maxSpeed = 46, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Pink neon wings
			{ size=Vector3.new(0.18,2.0,1.3), color="Hot pink", mat=NEON, parent="Torso",
			  cf=CFrame.new(-1.1,0.4,0.7)*CFrame.Angles(0, 0.45, 0.3) },
			{ size=Vector3.new(0.18,2.0,1.3), color="Hot pink", mat=NEON, parent="Torso",
			  cf=CFrame.new( 1.1,0.4,0.7)*CFrame.Angles(0,-0.45,-0.3) },
		},
	},
	{
		name = "Owl", bodyColor = "Medium stone grey", headColor = "Nougat",
		maxHp = 5,
		minSpeed = 25, maxSpeed = 38, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Grey wings
			{ size=Vector3.new(0.22,2.2,1.1), color="Dark stone grey", parent="Torso",
			  cf=CFrame.new(-1.35,0.35,0.8)*CFrame.Angles(0, 0.5, 0.35) },
			{ size=Vector3.new(0.22,2.2,1.1), color="Dark stone grey", parent="Torso",
			  cf=CFrame.new( 1.35,0.35,0.8)*CFrame.Angles(0,-0.5,-0.35) },
		},
	},
	{
		name = "Macaw", bodyColor = "Bright blue", headColor = "Nougat",
		maxHp = 5,
		minSpeed = 29, maxSpeed = 45, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Blue feather plume
			{ cyl=true, size=Vector3.new(0.25,2.8,2.8), color="Bright blue", mat=NEON, cf=CFrame.new(0,HT+0.12,0)*C90 },
		},
	},
	{
		name = "Pelican", bodyColor = "White", headColor = "Nougat",
		maxHp = 5,
		minSpeed = 27, maxSpeed = 42, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Large white wings
			{ size=Vector3.new(0.25,2.4,1.4), color="White", parent="Torso",
			  cf=CFrame.new(-1.4,0.3,0.85)*CFrame.Angles(0, 0.52, 0.35) },
			{ size=Vector3.new(0.25,2.4,1.4), color="White", parent="Torso",
			  cf=CFrame.new( 1.4,0.3,0.85)*CFrame.Angles(0,-0.52,-0.35) },
		},
	},
	{
		name = "Flamingo", bodyColor = "Hot pink", headColor = "Hot pink",
		maxHp = 5,
		minSpeed = 31, maxSpeed = 47, minJump = 160, maxJump = 220, jumpChance = 0.8, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Pink wings with feather detail
			{ size=Vector3.new(0.2,2.3,1.2), color="Hot pink", mat=NEON, trans=0.1, parent="Torso",
			  cf=CFrame.new(-1.25,0.35,0.75)*CFrame.Angles(0, 0.48, 0.32) },
			{ size=Vector3.new(0.2,2.3,1.2), color="Hot pink", mat=NEON, trans=0.1, parent="Torso",
			  cf=CFrame.new( 1.25,0.35,0.75)*CFrame.Angles(0,-0.48,-0.32) },
		},
	},
	-- RARE - Phoenix with 10 HP and multi-tier gold crown
	{
		name = "Phoenix", bodyColor = "Bright orange", headColor = "Nougat",
		maxHp = 10, moneyPerHit = 150, moneyOnDefeat = 800,
		minSpeed = 45, maxSpeed = 65, minJump = 180, maxJump = 240, jumpChance = 0.9, minJumpWait = 1, maxJumpWait = 2,
		accessories = {
			-- Flaming wings (orange + red)
			{ size=Vector3.new(0.3,2.8,1.5), color="Bright orange", mat=NEON, trans=0.15, parent="Torso",
			  cf=CFrame.new(-1.5,0.4,0.85)*CFrame.Angles(0, 0.55, 0.4) },
			{ size=Vector3.new(0.3,2.8,1.5), color="Bright orange", mat=NEON, trans=0.15, parent="Torso",
			  cf=CFrame.new( 1.5,0.4,0.85)*CFrame.Angles(0,-0.55,-0.4) },
			-- Golden crown
			{ cyl=true, size=Vector3.new(0.32,3.2,3.2), color="Bright yellow", mat=NEON, cf=CFrame.new(0,HT+0.16,0)*C90 },
			{ cyl=true, size=Vector3.new(1.4,0.5,0.5), color="Bright yellow", mat=NEON, cf=CFrame.new(0,HT+0.32+0.8,0)*C90 },
		},
	},
}

local TOTAL = #JUNGLE_ANIMALS
jungleTotal.Value     = TOTAL
jungleRemaining.Value = TOTAL

local aliveSet = {}
local gateOpen = false
local animalConnections = {}

local function attachPart(model, parentPartName, name, size, color, cf, material, shape, transparency)
	local parentPart = model:FindFirstChild(parentPartName)
	if not parentPart then return nil end

	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.BrickColor = BrickColor.new(color)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = false
	part.CastShadow = false
	if shape then part.Shape = shape end
	part.CFrame = parentPart.CFrame * cf
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = parentPart
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function improveAnimalLook(model, data)
	local beakColor = data.name == "Toucan" and "Bright orange" or "Bright yellow"
	if data.name == "Pelican" then beakColor = "Bright orange" end
	if data.name == "Owl" then beakColor = "Bright yellow" end

	attachPart(model, "Head", "Beak", Vector3.new(0.55, 0.34, 1.25), beakColor,
		CFrame.new(0, -0.08, -1.75), Enum.Material.SmoothPlastic)
	attachPart(model, "Head", "LeftEyeWhite", Vector3.new(0.42, 0.42, 0.18), "White",
		CFrame.new(-0.48, 0.38, -1.2), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	attachPart(model, "Head", "RightEyeWhite", Vector3.new(0.42, 0.42, 0.18), "White",
		CFrame.new(0.48, 0.38, -1.2), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	attachPart(model, "Head", "LeftPupil", Vector3.new(0.18, 0.18, 0.12), "Really black",
		CFrame.new(-0.48, 0.37, -1.34), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	attachPart(model, "Head", "RightPupil", Vector3.new(0.18, 0.18, 0.12), "Really black",
		CFrame.new(0.48, 0.37, -1.34), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	attachPart(model, "Head", "CheekLeft", Vector3.new(0.28, 0.16, 0.12), "Nougat",
		CFrame.new(-0.72, -0.1, -1.18), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.1)
	attachPart(model, "Head", "CheekRight", Vector3.new(0.28, 0.16, 0.12), "Nougat",
		CFrame.new(0.72, -0.1, -1.18), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.1)
	attachPart(model, "Torso", "TailFeather", Vector3.new(0.45, 1.4, 2.4), data.bodyColor,
		CFrame.new(0, -0.2, 1.45) * CFrame.Angles(math.rad(-28), 0, 0), NEON, nil, 0.15)

	if data.name == "Toucan" then
		attachPart(model, "Head", "BigToucanBeak", Vector3.new(1.05, 0.62, 2.35), "Bright orange",
			CFrame.new(0, -0.05, -2.1), NEON, nil, 0.05)
		attachPart(model, "Head", "BeakTip", Vector3.new(0.82, 0.32, 0.45), "Bright yellow",
			CFrame.new(0, -0.04, -3.35), NEON, nil, 0.08)
	elseif data.name == "Owl" then
		attachPart(model, "Head", "LeftBrow", Vector3.new(0.75, 0.18, 0.18), "Dark stone grey",
			CFrame.new(-0.38, 0.72, -1.05) * CFrame.Angles(0, 0, math.rad(-18)))
		attachPart(model, "Head", "RightBrow", Vector3.new(0.75, 0.18, 0.18), "Dark stone grey",
			CFrame.new(0.38, 0.72, -1.05) * CFrame.Angles(0, 0, math.rad(18)))
		attachPart(model, "Head", "FaceDiscLeft", Vector3.new(0.85, 0.85, 0.12), "Light stone grey",
			CFrame.new(-0.38, 0.27, -1.24), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.08)
		attachPart(model, "Head", "FaceDiscRight", Vector3.new(0.85, 0.85, 0.12), "Light stone grey",
			CFrame.new(0.38, 0.27, -1.24), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.08)
	elseif data.name == "Flamingo" then
		attachPart(model, "Torso", "LongNeck", Vector3.new(0.45, 2.8, 0.45), "Hot pink",
			CFrame.new(0, 1.4, -0.35), Enum.Material.SmoothPlastic)
		attachPart(model, "Torso", "ThinLegs", Vector3.new(0.25, 2.4, 0.25), "Hot pink",
			CFrame.new(0, -2.1, 0.25), Enum.Material.SmoothPlastic)
	elseif data.name == "Butterfly" then
		attachPart(model, "Torso", "LeftBigWing", Vector3.new(0.2, 3.6, 2.3), "Hot pink",
			CFrame.new(-1.65, 0.3, 0.55) * CFrame.Angles(0, 0.35, 0.35), NEON, nil, 0.2)
		attachPart(model, "Torso", "RightBigWing", Vector3.new(0.2, 3.6, 2.3), "Hot pink",
			CFrame.new(1.65, 0.3, 0.55) * CFrame.Angles(0, -0.35, -0.35), NEON, nil, 0.2)
	elseif data.name == "Phoenix" then
		attachPart(model, "Torso", "FlameTail", Vector3.new(0.8, 2.2, 3.2), "Bright red",
			CFrame.new(0, -0.25, 1.8) * CFrame.Angles(math.rad(-35), 0, 0), NEON, nil, 0.12)
		attachPart(model, "Head", "FlameCrest", Vector3.new(0.45, 1.25, 0.45), "Bright red",
			CFrame.new(0, 1.35, -0.15) * CFrame.Angles(math.rad(-18), 0, 0), NEON, nil, 0.08)
	end

	if data.name == "Parrot" or data.name == "Macaw" then
		attachPart(model, "Head", "ColorFacePatch", Vector3.new(1.15, 0.85, 0.14), "White",
			CFrame.new(0, 0.08, -1.25), Enum.Material.SmoothPlastic, Enum.PartType.Ball, 0.08)
		attachPart(model, "Torso", "LeftColorWing", Vector3.new(0.2, 2.4, 1.5), "Bright blue",
			CFrame.new(-1.35, 0.25, 0.75) * CFrame.Angles(0, 0.5, 0.35), NEON, nil, 0.15)
		attachPart(model, "Torso", "RightColorWing", Vector3.new(0.2, 2.4, 1.5), "Bright yellow",
			CFrame.new(1.35, 0.25, 0.75) * CFrame.Angles(0, -0.5, -0.35), NEON, nil, 0.15)
	end
end

local HOVER_IDLE_MAX = G + 7   -- idle targets stay low; darts go up to HOVER_MAX_Y

local function randomHoverTarget()
	return Vector3.new(
		math.random(BOUNDS.minX + 4, BOUNDS.maxX - 4),
		math.random(math.floor(HOVER_MIN_Y * 10), math.floor(HOVER_IDLE_MAX * 10)) / 10,
		math.random(BOUNDS.minZ + 4, BOUNDS.maxZ - 4)
	)
end

local function randomFlatDirection()
	local angle = math.random() * math.pi * 2
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local function openGate() end

-- Connect listeners FIRST
NPC.OnNPCDefeated:Connect(function(model, player)
	if not aliveSet[model] then return end
	aliveSet[model] = nil

	if animalConnections[model] then
		animalConnections[model]:Disconnect()
		animalConnections[model] = nil
	end

	jungleRemaining.Value = jungleRemaining.Value - 1
	defeatsThisArea += 1
	if player and playerScored then playerScored:Fire(player, "Jungle") end
	if not gateOpen then stageHits.Value = defeatsThisArea end

	if defeatsThisArea >= NEEDED or jungleRemaining.Value <= 0 then
		openGate()
	end
end)

local function spawnJungleAnimals()
	stageNeeded.Value = NEEDED
	math.randomseed(tick() + 2999)
	local startTime = tick()

	for _, data in JUNGLE_ANIMALS do
		data.rarity = data.rarity or (data.name == "Phoenix" and "Mythic" or "Legendary")
		data.spawnX = math.random(-60, 60)
		data.spawnZ = math.random(655, 765)
		local model, humanoid = NPC.createNPC(data)
		aliveSet[model] = true
		BoundaryService.bindModel(model, BOUNDS, { margin = 6, minY = HOVER_MIN_Y, maxY = HOVER_MAX_Y })
		improveAnimalLook(model, data)

		local hrp = model:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.Anchored = true end

		local target = randomHoverTarget()
		local nextTargetAt = tick() + math.random(4, 12) * 0.1
		local nextDartAt = tick() + math.random(12, 28) * 0.1
		local flightSpeed = math.random(data.minSpeed, data.maxSpeed) * 0.36
		local swayDir = randomFlatDirection()
		local swayPhase = math.random() * math.pi * 2
		local dartBoost = 1
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not model or not model.Parent or not hrp or not hrp.Parent then
				if conn then conn:Disconnect() end
				return
			end

			local t = tick() - startTime
			if tick() >= nextTargetAt or (target - hrp.Position).Magnitude < 3 then
				target = randomHoverTarget()
				nextTargetAt = tick() + math.random(5, 16) * 0.1
				flightSpeed = math.random(data.minSpeed, data.maxSpeed) * 0.36
				swayDir = randomFlatDirection()
				swayPhase = math.random() * math.pi * 2
			end

			if tick() >= nextDartAt then
				target = hrp.Position + randomFlatDirection() * math.random(10, 24)
					+ Vector3.new(0, math.random(-22, 22) * 0.1, 0)
				target = Vector3.new(
					math.clamp(target.X, BOUNDS.minX + 4, BOUNDS.maxX - 4),
					math.clamp(target.Y, HOVER_MIN_Y, HOVER_MAX_Y),
					math.clamp(target.Z, BOUNDS.minZ + 4, BOUNDS.maxZ - 4)
				)
				nextTargetAt = tick() + math.random(4, 10) * 0.1
				nextDartAt = tick() + math.random(14, 32) * 0.1
				dartBoost = 2.35
			end

			dartBoost = math.max(1, dartBoost - dt * 2.2)
			local bob = math.sin(t * 3.5 + data.spawnX) * HOVER_BOB
			local verticalWave = math.sin(t * 1.7 + data.spawnZ) * 0.75
			local sideSway = swayDir * math.sin(t * 2.4 + swayPhase) * 2.2
			local current = hrp.Position
			local desired = Vector3.new(target.X, target.Y + bob + verticalWave, target.Z) + sideSway
			local offset = desired - current
			local distance = offset.Magnitude
			if distance <= 0.01 then return end

			local step = math.min(distance, flightSpeed * dartBoost * dt)
			local nextPos = current + offset.Unit * step
			nextPos = Vector3.new(
				math.clamp(nextPos.X, BOUNDS.minX, BOUNDS.maxX),
				math.clamp(nextPos.Y, HOVER_MIN_Y, HOVER_MAX_Y),
				math.clamp(nextPos.Z, BOUNDS.minZ, BOUNDS.maxZ)
			)

			local lookAt = Vector3.new(desired.X, nextPos.Y, desired.Z)
			if (lookAt - nextPos).Magnitude < 0.05 then
				lookAt += Vector3.new(0, 0, -1)
			end
			model:PivotTo(CFrame.lookAt(nextPos, lookAt))
		end)

		animalConnections[model] = conn
	end
end

task.spawn(spawnJungleAnimals)

-- ---- World restart listener ----
task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Jungle" then return end
		for model, conn in animalConnections do
			if conn then conn:Disconnect() end
			animalConnections[model] = nil
		end
		for model in aliveSet do
			aliveSet[model] = nil
			if model.Parent then model:Destroy() end
		end
		defeatsThisArea = 0
		gateOpen = false
		jungleRemaining.Value = TOTAL
		spawnJungleAnimals()
	end)
end)
