-- EmptyWorld43Gameplay.server.luau
-- World 43: simple empty platform with three small NPCs and one boss NPC.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local CX, CZ = -2860, 8410
local FLOOR_Y = 1
local WORLD_NAME = "Empty World 43"

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)

local function getOrCreate(parent, className, name)
	if not parent then return nil end
	local value = parent:FindFirstChild(name)
	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Value = 0
		value.Parent = parent
	end
	return value
end

local remValue = getOrCreate(gameEvents, "NumberValue", "EmptyWorld43Remaining")
local totValue = getOrCreate(gameEvents, "NumberValue", "EmptyWorld43Total")
local playerScored
task.spawn(function()
	playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30)
end)

local folder = workspace:FindFirstChild("EmptyWorld43World")
if folder then
	folder:Destroy()
end
local npcFolder = workspace:FindFirstChild("EmptyWorld43NPCs")
if npcFolder then
	npcFolder:Destroy()
end

folder = Instance.new("Folder")
folder.Name = "EmptyWorld43World"
folder.Parent = workspace

npcFolder = Instance.new("Folder")
npcFolder.Name = "EmptyWorld43NPCs"
npcFolder.Parent = workspace

local function part(name, size, cf, color, material, transparency, canCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = canCollide == true
	p.CanTouch = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function wedge(name, size, cf, color, material, transparency)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = true
	p.CastShadow = false
	p.Parent = folder
	return p
end

local function cylinder(name, size, cf, color, material, transparency)
	local p = part(name, size, cf, color, material, transparency, false)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ball(name, size, cf, color, material, transparency)
	local p = part(name, Vector3.new(size, size, size), cf, color, material, transparency, false)
	p.Shape = Enum.PartType.Ball
	return p
end

part("Empty43Floor", Vector3.new(148, 1.4, 140), CFrame.new(CX, FLOOR_Y, CZ), "Medium stone grey", Enum.Material.Concrete, 0, true)
part("Empty43CenterMat", Vector3.new(92, 0.35, 84), CFrame.new(CX, FLOOR_Y + 0.9, CZ), "Dark stone grey", Enum.Material.Slate, 0, true)
part("Empty43SpawnStripe", Vector3.new(24, 0.2, 116), CFrame.new(CX, FLOOR_Y + 1.12, CZ), "Lime green", Enum.Material.Neon, 0.68, false)

local function zCurbWithGap(zOffset, gapHalf)
	local minX, maxX = -74, 74
	local leftMax = -gapHalf
	local rightMin = gapHalf
	local leftLen = leftMax - minX
	local rightLen = maxX - rightMin
	if leftLen > 0 then
		part("Empty43Curb", Vector3.new(leftLen, 5, 3), CFrame.new(CX + minX + leftLen / 2, FLOOR_Y + 3, CZ + zOffset), "Really black", Enum.Material.Metal, 0, true)
	end
	if rightLen > 0 then
		part("Empty43Curb", Vector3.new(rightLen, 5, 3), CFrame.new(CX + rightMin + rightLen / 2, FLOOR_Y + 3, CZ + zOffset), "Really black", Enum.Material.Metal, 0, true)
	end
end

zCurbWithGap(-70, 28)
zCurbWithGap(70, 28)
for _, x in ipairs({ -74, 74 }) do
	part("Empty43Curb", Vector3.new(3, 5, 140), CFrame.new(CX + x, FLOOR_Y + 3, CZ), "Really black", Enum.Material.Metal, 0, true)
end

local activeNpcs = {}
local hitDebounce = {}

local function playHitSound(position)
	local s = Instance.new("Sound")
	s.Name = "Empty43NpcHit"
	s.SoundId = "rbxassetid://137750395861529"
	s.Volume = 0.9
	s.RollOffMaxDistance = 90
	s.Parent = workspace
	s:Play()
	Debris:AddItem(s, 3)
end

local function createNpc(index, spawnOffset, shirtColor)
	local model = Instance.new("Model")
	model.Name = "Empty43GreenNPC" .. index
	model.Parent = npcFolder

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = "Small NPC"
	humanoid.MaxHealth = 1
	humanoid.Health = 1
	humanoid.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.5, 2.5, 2.5)
	root.CFrame = CFrame.new(CX + spawnOffset.X, FLOOR_Y + 2.6, CZ + spawnOffset.Z)
	root.Transparency = 0.85
	root.BrickColor = BrickColor.new("Lime green")
	root.Material = Enum.Material.Neon
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = true
	root.CastShadow = false
	root:SetAttribute("Empty43NpcIndex", index)
	root.Parent = model
	model.PrimaryPart = root

	local function add(basePart)
		basePart:SetAttribute("Empty43NpcIndex", index)
		basePart.Parent = model
		return basePart
	end

	local function cf(localCf)
		return root.CFrame * localCf
	end

	add(ball("Head", 3.8, cf(CFrame.new(0, 8.9, -0.35) * CFrame.Angles(math.rad(-8), 0, 0)), "Lime green", Enum.Material.SmoothPlastic))
	add(part("Torso", Vector3.new(4.2, 5.5, 2.7), cf(CFrame.new(0, 4.8, 0)), "Bright green", Enum.Material.SmoothPlastic, 0, false))
	add(part("Tunic", Vector3.new(4.8, 4.6, 3), cf(CFrame.new(0, 4.4, -0.08)), shirtColor, Enum.Material.Fabric, 0, false))
	add(part("TunicTearA", Vector3.new(1.2, 2.4, 0.4), cf(CFrame.new(-1.6, 1.75, -1.45) * CFrame.Angles(0, 0, math.rad(-8))), shirtColor, Enum.Material.Fabric, 0, false))
	add(part("TunicTearB", Vector3.new(1.1, 2.1, 0.4), cf(CFrame.new(0, 1.6, -1.48) * CFrame.Angles(0, 0, math.rad(6))), shirtColor, Enum.Material.Fabric, 0, false))
	add(part("TunicTearC", Vector3.new(1.2, 2.5, 0.4), cf(CFrame.new(1.6, 1.7, -1.45) * CFrame.Angles(0, 0, math.rad(10))), shirtColor, Enum.Material.Fabric, 0, false))

	add(part("ArmL", Vector3.new(1.2, 5.8, 1.2), cf(CFrame.new(-3.25, 5.2, -0.9) * CFrame.Angles(math.rad(20), 0, math.rad(-22))), "Lime green", Enum.Material.SmoothPlastic, 0, false))
	add(part("ArmR", Vector3.new(1.2, 5.8, 1.2), cf(CFrame.new(3.25, 5.2, -0.9) * CFrame.Angles(math.rad(18), 0, math.rad(22))), "Lime green", Enum.Material.SmoothPlastic, 0, false))
	add(part("HandL", Vector3.new(1.6, 1.2, 1.6), cf(CFrame.new(-4.2, 2.7, -2.15)), "Lime green", Enum.Material.SmoothPlastic, 0, false))
	add(part("HandR", Vector3.new(1.6, 1.2, 1.6), cf(CFrame.new(4.2, 2.7, -2.15)), "Lime green", Enum.Material.SmoothPlastic, 0, false))

	for _, side in ipairs({ -1, 1 }) do
		add(part("Leg" .. side, Vector3.new(1.35, 4.1, 1.35), cf(CFrame.new(side * 1.25, 0.7, 0.2) * CFrame.Angles(math.rad(-8), 0, math.rad(side * 5))), "Bright green", Enum.Material.SmoothPlastic, 0, false))
		add(part("Foot" .. side, Vector3.new(2.2, 0.9, 2.8), cf(CFrame.new(side * 1.25, -1.55, -0.7)), "Lime green", Enum.Material.SmoothPlastic, 0, false))
		add(wedge("Ear" .. side, Vector3.new(1.3, 2.0, 5.8), cf(CFrame.new(side * 3.2, 9.4, -0.1) * CFrame.Angles(0, math.rad(side * 74), math.rad(side * -16))), "Lime green", Enum.Material.SmoothPlastic, 0))
		add(ball("Eye" .. side, 0.45, cf(CFrame.new(side * 0.9, 9.2, -2.05)), "Really red", Enum.Material.Neon, 0))
		for claw = -1, 1 do
			add(wedge("Claw" .. side .. "_" .. claw, Vector3.new(0.35, 0.55, 1.2), cf(CFrame.new(side * (4.1 + claw * 0.28), 2.05, -3.1) * CFrame.Angles(math.rad(-20), 0, 0)), "Lime green", Enum.Material.SmoothPlastic, 0))
			add(wedge("Toe" .. side .. "_" .. claw, Vector3.new(0.35, 0.45, 1.1), cf(CFrame.new(side * (1.25 + claw * 0.38), -2.0, -2.0) * CFrame.Angles(math.rad(-15), 0, 0)), "Lime green", Enum.Material.SmoothPlastic, 0))
		end
	end

	add(part("Mouth", Vector3.new(2.2, 0.28, 0.25), cf(CFrame.new(0, 8.35, -2.35)), "Really black", Enum.Material.SmoothPlastic, 0, false))

	activeNpcs[index] = {
		model = model,
		root = root,
		speed = 9 + index * 1.5,
		target = Vector3.new(CX + spawnOffset.X, FLOOR_Y + 2.6, CZ + spawnOffset.Z),
		phase = index,
		alive = true,
		hp = 1,
		maxHp = 1,
		baseY = FLOOR_Y + 2.6,
	}
end

local function createBoss(index, spawnOffset)
	local model = Instance.new("Model")
	model.Name = "Empty43BossNPC"
	model.Parent = npcFolder

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayName = "Boss"
	humanoid.MaxHealth = 7
	humanoid.Health = 7
	humanoid.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(7, 7, 7)
	root.CFrame = CFrame.new(CX + spawnOffset.X, FLOOR_Y + 5.8, CZ + spawnOffset.Z)
	root.Transparency = 0.82
	root.BrickColor = BrickColor.new("Really red")
	root.Material = Enum.Material.Neon
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = true
	root.CastShadow = false
	root:SetAttribute("Empty43NpcIndex", index)
	root.Parent = model
	model.PrimaryPart = root

	local function add(basePart)
		basePart:SetAttribute("Empty43NpcIndex", index)
		basePart.Parent = model
		return basePart
	end

	local function cf(localCf)
		return root.CFrame * localCf
	end

	add(ball("BossHead", 7.4, cf(CFrame.new(0, 18.8, -0.9) * CFrame.Angles(math.rad(-5), 0, 0)), "Bright green", Enum.Material.SmoothPlastic))
	add(part("BossTorso", Vector3.new(13, 15, 7), cf(CFrame.new(0, 9.4, 0)), "Bright green", Enum.Material.SmoothPlastic, 0, false))
	add(part("BossBelt", Vector3.new(15, 2.5, 7.8), cf(CFrame.new(0, 3.1, 0)), "Reddish brown", Enum.Material.Fabric, 0, false))
	add(part("BossBuckle", Vector3.new(4.5, 3.5, 1), cf(CFrame.new(0, 3.3, -4.2)), "Bright yellow", Enum.Material.Metal, 0, false))
	add(part("BossSkirt", Vector3.new(11, 7, 6), cf(CFrame.new(0, 0.6, 0)), "Dark stone grey", Enum.Material.Fabric, 0, false))

	for _, side in ipairs({ -1, 1 }) do
		add(part("BossArm" .. side, Vector3.new(3.2, 14, 3.2), cf(CFrame.new(side * 9, 9.3, -0.8) * CFrame.Angles(math.rad(10), 0, math.rad(side * -9))), "Bright green", Enum.Material.SmoothPlastic, 0, false))
		add(part("BossForearm" .. side, Vector3.new(3.8, 8, 3.8), cf(CFrame.new(side * 11.4, 2.1, -1.2) * CFrame.Angles(math.rad(8), 0, math.rad(side * 18))), "Bright green", Enum.Material.SmoothPlastic, 0, false))
		add(part("BossWristBand" .. side, Vector3.new(4.4, 3, 4.4), cf(CFrame.new(side * 12, -2.1, -1.3)), "Reddish brown", Enum.Material.Fabric, 0, false))
		add(part("BossHand" .. side, Vector3.new(4.5, 3, 4.5), cf(CFrame.new(side * 12.5, -4.2, -1.8)), "Lime green", Enum.Material.SmoothPlastic, 0, false))
		add(part("BossLeg" .. side, Vector3.new(4.4, 8, 4.4), cf(CFrame.new(side * 3.4, -5.1, 0.2)), "Bright green", Enum.Material.SmoothPlastic, 0, false))
		add(part("BossBoot" .. side, Vector3.new(5.2, 3.6, 5.6), cf(CFrame.new(side * 3.4, -10.3, -0.5)), "Dark stone grey", Enum.Material.Fabric, 0, false))
		add(wedge("BossEar" .. side, Vector3.new(2.1, 3.0, 8.5), cf(CFrame.new(side * 5.8, 20.0, -0.7) * CFrame.Angles(0, math.rad(side * 75), math.rad(side * -16))), "Bright green", Enum.Material.SmoothPlastic, 0))
		add(wedge("BossHorn" .. side, Vector3.new(2.5, 3.8, 8), cf(CFrame.new(side * 2.8, 23.0, -1.2) * CFrame.Angles(math.rad(-10), math.rad(side * 18), math.rad(side * 34))), "Institutional white", Enum.Material.SmoothPlastic, 0))
		add(ball("BossEye" .. side, 0.75, cf(CFrame.new(side * 1.5, 19.2, -4.3)), "Really red", Enum.Material.Neon, 0))
		for claw = -1, 1 do
			add(wedge("BossClaw" .. side .. "_" .. claw, Vector3.new(0.8, 1.0, 2.2), cf(CFrame.new(side * (12.4 + claw * 0.85), -5.7, -4.3) * CFrame.Angles(math.rad(-18), 0, 0)), "Bright yellow", Enum.Material.SmoothPlastic, 0))
		end
	end

	add(part("BossMouth", Vector3.new(4.6, 0.5, 0.5), cf(CFrame.new(0, 17.8, -4.9)), "Really black", Enum.Material.SmoothPlastic, 0, false))
	for tooth = -2, 2 do
		add(wedge("BossTooth" .. tooth, Vector3.new(0.55, 1.2, 0.65), cf(CFrame.new(tooth * 0.9, 17.25, -5.15) * CFrame.Angles(math.rad(180), 0, 0)), "Institutional white", Enum.Material.SmoothPlastic, 0))
	end

	for i = -3, 3 do
		add(wedge("BossBeard" .. i, Vector3.new(2.2, 5.2, 1.6), cf(CFrame.new(i * 1.15, 14.5 - math.abs(i) * 0.25, -4.3) * CFrame.Angles(math.rad(180), 0, math.rad(i * 8))), "Really red", Enum.Material.Fabric, 0))
	end
	for i = -2, 2 do
		add(wedge("BossMane" .. i, Vector3.new(2.4, 5.4, 2.0), cf(CFrame.new(i * 1.25, 24.6, 0.2) * CFrame.Angles(0, 0, math.rad(i * 10))), "Really red", Enum.Material.Fabric, 0))
	end
	for _, side in ipairs({ -1, 1 }) do
		for spike = 1, 4 do
			add(wedge("BossShoulderSpike" .. side .. "_" .. spike, Vector3.new(2.8, 4, 3), cf(CFrame.new(side * (5.6 + spike * 1.4), 15.5 - spike * 0.45, -0.8) * CFrame.Angles(0, math.rad(side * 30), math.rad(side * 50))), "Really red", Enum.Material.SmoothPlastic, 0))
		end
	end

	local clubAngle = CFrame.Angles(0, 0, math.rad(72))
	add(cylinder("BossClubHandle", Vector3.new(3, 20, 3), cf(CFrame.new(-14, -3.8, -2) * clubAngle), "Reddish brown", Enum.Material.Wood, 0))
	add(cylinder("BossClubHead", Vector3.new(6, 13, 6), cf(CFrame.new(-23, -7.7, -2) * clubAngle), "Brown", Enum.Material.Wood, 0))
	for spike = 0, 7 do
		local angle = math.rad(spike * 45)
		add(wedge("BossClubSpike" .. spike, Vector3.new(1.6, 2.4, 3.2), cf(CFrame.new(-23, -7.7 + math.sin(angle) * 3, -2 + math.cos(angle) * 3) * CFrame.Angles(0, angle, math.rad(90))), "Really black", Enum.Material.Metal, 0))
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 190, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 13, 0)
	billboard.MaxDistance = 140
	billboard.Parent = model:FindFirstChild("BossHead")

	local label = Instance.new("TextLabel")
	label.Name = "BossHealthLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(20, 12, 12)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Text = "BOSS 7/7"
	label.TextColor3 = Color3.fromRGB(255, 245, 220)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

	activeNpcs[index] = {
		model = model,
		root = root,
		speed = 5,
		target = Vector3.new(CX + spawnOffset.X, FLOOR_Y + 5.8, CZ + spawnOffset.Z),
		phase = index,
		alive = true,
		hp = 7,
		maxHp = 7,
		healthLabel = label,
		baseY = FLOOR_Y + 5.8,
	}
end

local function pickTarget()
	return Vector3.new(
		CX + math.random(-55, 55),
		FLOOR_Y,
		CZ + math.random(-50, 50)
	)
end

local function defeatNpc(index, player)
	local npc = activeNpcs[index]
	if not npc or not npc.alive then return end
	npc.alive = false
	if remValue and remValue.Value > 0 then
		remValue.Value -= 1
	end
	if player and playerScored then
		playerScored:Fire(player, WORLD_NAME)
	end

	for _, object in npc.model:GetDescendants() do
		if object:IsA("BasePart") then
			object.BrickColor = BrickColor.new("Dark stone grey")
			object.Material = Enum.Material.SmoothPlastic
			object.CanTouch = false
		end
	end

	task.delay(0.45, function()
		if npc.model.Parent then
			npc.model:Destroy()
		end
	end)
end

local function onNpcTouched(npcIndex, hit)
	local npc = activeNpcs[npcIndex]
	if not npc or not npc.alive then return end
	if not hit or not hit:IsA("BasePart") or hit.Name ~= "Ball" then return end
	if hit:GetAttribute("IsThrown") ~= true then return end
	local throwTime = hit:GetAttribute("ThrowTime")
	if typeof(throwTime) ~= "number" or os.clock() - throwTime > 8 then return end
	if hit.AssemblyLinearVelocity.Magnitude < 10 then return end
	if hitDebounce[npcIndex] then return end
	local throwerName = hit:GetAttribute("ThrowerName")
	local player = typeof(throwerName) == "string" and Players:FindFirstChild(throwerName) or nil
	if not player then return end
	hitDebounce[npcIndex] = true
	playHitSound(hit.Position)
	npc.hp -= 1
	if npc.healthLabel then
		npc.healthLabel.Text = "BOSS " .. math.max(0, npc.hp) .. "/" .. npc.maxHp
	end
	if npc.hp <= 0 then
		defeatNpc(npcIndex, player)
	else
		for _, object in npc.model:GetDescendants() do
			if object:IsA("BasePart") and object.Transparency < 1 then
				local old = object.BrickColor
				object.BrickColor = BrickColor.new("Institutional white")
				task.delay(0.12, function()
					if object.Parent and npc.alive then
						object.BrickColor = old
					end
				end)
			end
		end
		task.delay(0.45, function()
			hitDebounce[npcIndex] = nil
		end)
	end
end

local function createFallbackNpc(index, spawnOffset, isBoss)
	local model = Instance.new("Model")
	model.Name = isBoss and "Empty43FallbackBoss" or ("Empty43FallbackNPC" .. index)
	model.Parent = npcFolder

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = isBoss and "Boss" or "Small NPC"
	humanoid.MaxHealth = isBoss and 7 or 1
	humanoid.Health = humanoid.MaxHealth
	humanoid.Parent = model

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = isBoss and Vector3.new(18, 24, 12) or Vector3.new(7, 11, 5)
	root.CFrame = CFrame.new(CX + spawnOffset.X, FLOOR_Y + (isBoss and 13 or 7), CZ + spawnOffset.Z)
	root.BrickColor = BrickColor.new(isBoss and "Bright green" or "Lime green")
	root.Material = Enum.Material.Neon
	root.Transparency = 0.08
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = true
	root.CastShadow = false
	root:SetAttribute("Empty43NpcIndex", index)
	root.Parent = model
	model.PrimaryPart = root

	local head = Instance.new("Part")
	head.Name = isBoss and "BossHead" or "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = isBoss and Vector3.new(10, 10, 10) or Vector3.new(4, 4, 4)
	head.CFrame = root.CFrame * CFrame.new(0, root.Size.Y / 2 + head.Size.Y / 2 - 1, -1)
	head.BrickColor = BrickColor.new("Bright green")
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CanTouch = true
	head:SetAttribute("Empty43NpcIndex", index)
	head.Parent = model

	if isBoss then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 190, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 8, 0)
		billboard.MaxDistance = 180
		billboard.Parent = head

		local label = Instance.new("TextLabel")
		label.Name = "BossHealthLabel"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(20, 12, 12)
		label.BackgroundTransparency = 0.18
		label.Text = "BOSS 7/7"
		label.TextColor3 = Color3.fromRGB(255, 245, 220)
		label.TextStrokeTransparency = 0.25
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = billboard
		activeNpcs[index] = {
			model = model,
			root = root,
			speed = 5,
			target = Vector3.new(CX + spawnOffset.X, FLOOR_Y, CZ + spawnOffset.Z),
			phase = index,
			alive = true,
			hp = 7,
			maxHp = 7,
			healthLabel = label,
			baseY = FLOOR_Y + 13,
		}
	else
		activeNpcs[index] = {
			model = model,
			root = root,
			speed = 9 + index * 1.5,
			target = Vector3.new(CX + spawnOffset.X, FLOOR_Y, CZ + spawnOffset.Z),
			phase = index,
			alive = true,
			hp = 1,
			maxHp = 1,
			baseY = FLOOR_Y + 7,
		}
	end
end

local function spawnNpc(index, spawnOffset, shirtColor)
	local ok, err = pcall(createNpc, index, spawnOffset, shirtColor)
	if not ok or not activeNpcs[index] then
		warn("[EmptyWorld43Gameplay] Detailed small NPC failed; using fallback:", index, err)
		createFallbackNpc(index, spawnOffset, false)
	end
end

local function spawnBoss(index, spawnOffset)
	local ok, err = pcall(createBoss, index, spawnOffset)
	if not ok or not activeNpcs[index] then
		warn("[EmptyWorld43Gameplay] Detailed boss failed; using fallback:", err)
		createFallbackNpc(index, spawnOffset, true)
	end
end

spawnNpc(1, Vector3.new(-28, 0, -18), "Reddish brown")
spawnNpc(2, Vector3.new(18, 0, 8), "Brown")
spawnNpc(3, Vector3.new(34, 0, -26), "Dark orange")
spawnBoss(4, Vector3.new(0, 0, 24))

for _, npc in pairs(activeNpcs) do
	for _, object in npc.model:GetDescendants() do
		if object:IsA("BasePart") and object:GetAttribute("Empty43NpcIndex") then
			local npcIndex = object:GetAttribute("Empty43NpcIndex")
			object.Touched:Connect(function(hit)
				onNpcTouched(npcIndex, hit)
			end)
		end
	end
	npc.target = pickTarget()
end

RunService.Heartbeat:Connect(function(dt)
	for _, npc in pairs(activeNpcs) do
		if not npc.alive or not npc.model.Parent then continue end
		local pivot = npc.model:GetPivot()
		local pos = pivot.Position
		local delta = Vector3.new(npc.target.X - pos.X, 0, npc.target.Z - pos.Z)
		if delta.Magnitude < 3 then
			npc.target = pickTarget()
			delta = Vector3.new(npc.target.X - pos.X, 0, npc.target.Z - pos.Z)
		end
		if delta.Magnitude < 0.01 then continue end

		npc.phase += dt * 8
		local step = math.min(delta.Magnitude, npc.speed * dt)
		local dir = delta.Unit
		local nextPos = pos + dir * step
		local bob = math.sin(npc.phase) * 0.18
		local pivotPos = Vector3.new(nextPos.X, (npc.baseY or FLOOR_Y + 2.6) + bob, nextPos.Z)
		npc.model:PivotTo(CFrame.lookAt(pivotPos, Vector3.new(npc.target.X, pivotPos.Y, npc.target.Z)))
	end
end)

if remValue then remValue.Value = 4 end
if totValue then totValue.Value = 4 end

print("[EmptyWorld43Gameplay] Built " .. WORLD_NAME .. " with 3 small NPCs and 1 boss NPC.")
