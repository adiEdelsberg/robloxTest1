-- Place in StarterPlayerScripts/FlyingBirdsClient.client.luau
-- Client owns all bird visuals, effects, LOD, labels, wing flap, tails, and mobile-friendly culling.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local networkFolder = ReplicatedStorage:WaitForChild("FlyingBirdSystem")
local snapshotEvent = networkFolder:WaitForChild("BirdSnapshot")
local Config = require(networkFolder:WaitForChild("BirdConfig"))
local Rarity = require(networkFolder:WaitForChild("Rarity"))

local visualsFolder = Instance.new("Folder")
visualsFolder.Name = "FlyingBirdVisuals"
visualsFolder.Parent = workspace

local definitionsById = {}
for _, definition in Config.Birds do
	definitionsById[definition.id] = definition
end

local birds = {}
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function safeUnit(vector, fallback)
	if vector.Magnitude > 0.001 then
		return vector.Unit
	end
	return fallback or Vector3.new(0, 0, -1)
end

local function makePart(parent, name, size, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function addRareBillboard(model, definition)
	if not Rarity.isRareOrBetter(definition.rarity) then return end
	local anchor = model.PrimaryPart
	if not anchor then return end

	local gui = Instance.new("BillboardGui")
	gui.Name = "RareBirdBillboard"
	gui.Size = UDim2.new(0, 180, 0, 44)
	gui.StudsOffset = Vector3.new(0, 5 * definition.scale, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 180
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = definition.rarity .. "  " .. definition.displayName
	label.TextColor3 = Rarity.Colors[definition.rarity] or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end

local function addTrail(model, wing, definition)
	if not definition.trail then return end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(-wing.Size.X * 0.45, 0, 0)
	a0.Parent = wing
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(wing.Size.X * 0.45, 0, 0)
	a1.Parent = wing

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(definition.trail.color)
	trail.Transparency = NumberSequence.new(definition.trail.transparency or 0.55, 1)
	trail.Lifetime = 0.45
	trail.MinLength = 0.4
	trail.Enabled = true
	trail.Parent = model
end

local function addGlow(parent, definition)
	if not definition.glow then return end
	local light = Instance.new("PointLight")
	light.Color = definition.glow.color
	light.Range = definition.glow.range
	light.Brightness = definition.glow.brightness
	light.Parent = parent

	local glow = Instance.new("ParticleEmitter")
	glow.Color = ColorSequence.new(definition.glow.color)
	glow.LightEmission = 0.8
	glow.Lifetime = NumberRange.new(0.4, 0.8)
	glow.Rate = 8
	glow.Speed = NumberRange.new(0.2, 1.2)
	glow.SpreadAngle = Vector2.new(180, 180)
	glow.Parent = parent
end

local function createBirdVisual(snapshot)
	local definition = definitionsById[snapshot.typeId]
	if not definition then return end

	local model = Instance.new("Model")
	model.Name = "Flying_" .. definition.id .. "_" .. snapshot.id
	model.Parent = visualsFolder

	local scale = definition.scale
	local body
	if definition.meshId ~= "" then
		body = Instance.new("MeshPart")
		body.MeshId = definition.meshId
		body.TextureID = definition.textureId or ""
		body.Size = Vector3.new(3.2, 1.4, 2.4) * scale
		body.Color = definition.bodyColor
		body.Anchored = true
		body.CanCollide = false
		body.CanTouch = false
		body.CastShadow = false
		body.Parent = model
		if definition.surfaceAppearance then
			local appearance = Instance.new("SurfaceAppearance")
			for property, value in definition.surfaceAppearance do
				appearance[property] = value
			end
			appearance.Parent = body
		end
	else
		body = makePart(model, "Body", Vector3.new(3.2, 1.4, 2.4) * scale, definition.bodyColor, Enum.Material.SmoothPlastic)
	end

	model.PrimaryPart = body

	local leftWing = makePart(model, "LeftWing", Vector3.new(3.6, 0.18, 1.25) * scale, definition.wingColor, Enum.Material.SmoothPlastic)
	local rightWing = makePart(model, "RightWing", Vector3.new(3.6, 0.18, 1.25) * scale, definition.wingColor, Enum.Material.SmoothPlastic)
	local tail = makePart(model, "Tail", Vector3.new(1.1, 0.22, 1.8) * scale, definition.wingColor, Enum.Material.SmoothPlastic)

	addTrail(model, leftWing, definition)
	addTrail(model, rightWing, definition)
	addGlow(body, definition)
	addRareBillboard(model, definition)

	birds[snapshot.id] = {
		model = model,
		definition = definition,
		position = snapshot.position,
		targetPosition = snapshot.position,
		direction = snapshot.direction,
		targetDirection = snapshot.direction,
		leftWing = leftWing,
		rightWing = rightWing,
		tail = tail,
		body = body,
		lastSeen = os.clock(),
		lod = "full",
	}
end

local function setLod(record, lod)
	if record.lod == lod then return end
	record.lod = lod
	local full = lod == "full"
	for _, object in record.model:GetDescendants() do
		if object:IsA("Trail") or object:IsA("ParticleEmitter") or object:IsA("PointLight") or object:IsA("BillboardGui") then
			object.Enabled = full
		end
	end
end

local function updateBird(record, dt, fullLodBudgetUsed)
	local distance = (camera.CFrame.Position - record.position).Magnitude
	if distance > Config.Client.cullDistance then
		record.model.Parent = nil
		return fullLodBudgetUsed
	end
	record.model.Parent = visualsFolder

	local lod = "simple"
	local maxFull = isMobile and Config.Client.maxFullLodBirdsMobile or Config.Client.maxFullLodBirdsDesktop
	if distance < Config.Client.fullLodDistance and fullLodBudgetUsed < maxFull then
		lod = "full"
		fullLodBudgetUsed += 1
	elseif distance < Config.Client.mediumLodDistance then
		lod = "medium"
	end
	setLod(record, lod)

	local lerpAlpha = math.clamp(dt * (lod == "full" and 8 or 4), 0, 1)
	record.position = record.position:Lerp(record.targetPosition, lerpAlpha)
	record.direction = safeUnit(record.direction:Lerp(record.targetDirection, lerpAlpha), record.direction)

	local cf = CFrame.lookAt(record.position, record.position + record.direction)
	record.body.CFrame = cf

	if lod == "simple" then
		record.leftWing.Transparency = 1
		record.rightWing.Transparency = 1
		record.tail.Transparency = 1
		return fullLodBudgetUsed
	end

	record.leftWing.Transparency = 0
	record.rightWing.Transparency = 0
	record.tail.Transparency = 0

	local t = os.clock()
	local flap = math.sin(t * record.definition.flapRate) * (lod == "full" and 0.65 or 0.25)
	local scale = record.definition.scale
	record.leftWing.CFrame = cf * CFrame.new(-2.45 * scale, 0, 0) * CFrame.Angles(0, 0, flap)
	record.rightWing.CFrame = cf * CFrame.new(2.45 * scale, 0, 0) * CFrame.Angles(0, 0, -flap)
	record.tail.CFrame = cf * CFrame.new(0, 0, 1.65 * scale) * CFrame.Angles(math.sin(t * 3) * 0.12, 0, 0)

	return fullLodBudgetUsed
end

snapshotEvent.OnClientEvent:Connect(function(snapshot)
	local now = os.clock()
	for _, birdData in snapshot do
		local record = birds[birdData.id]
		if not record then
			createBirdVisual(birdData)
			record = birds[birdData.id]
		end
		if record then
			record.targetPosition = birdData.position
			record.targetDirection = birdData.direction
			record.lastSeen = now
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local fullLodBudgetUsed = 0
	local now = os.clock()
	for id, record in birds do
		if now - record.lastSeen > 8 then
			record.model:Destroy()
			birds[id] = nil
		else
			fullLodBudgetUsed = updateBird(record, dt, fullLodBudgetUsed)
		end
	end
end)
