-- PremiumNPCFactory
-- Reusable server/client-safe visual factory for premium arena NPC models.
-- This module only builds visuals and target parts. It does not own gameplay,
-- damage, AI, scoring, or movement.
--
-- Usage:
-- local Factory = require(ReplicatedStorage.Visuals.PremiumNPCFactory)
-- local model = Factory.CreateWorld43Small({
--   Parent = workspace,
--   CFrame = CFrame.new(-2860, 4, 8410),
--   TargetIndex = 1,
--   ShirtColor = Color3.fromRGB(95, 48, 28),
-- })

local PremiumNPCFactory = {}

local function makeBasePart(parent, name, size, cf, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function smooth(parent, name, scale, cf, color, transparency)
	local part = makeBasePart(parent, name, Vector3.new(1, 1, 1), cf, color, Enum.Material.SmoothPlastic, transparency)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = scale
	mesh.Parent = part
	return part
end

function PremiumNPCFactory.CreateMeshPart(parent, name, meshDef, cf, fallbackColor)
	-- MeshPart-compatible entry point. Provide MeshId/TextureID in meshDef, or
	-- the caller can fall back to smooth primitive construction.
	local part = Instance.new("MeshPart")
	part.Name = name
	part.MeshId = meshDef.MeshId or ""
	part.TextureID = meshDef.TextureID or ""
	part.Size = meshDef.Size or Vector3.new(2, 2, 2)
	part.CFrame = cf
	part.Color = meshDef.Color or fallbackColor or Color3.new(1, 1, 1)
	part.Material = meshDef.Material or Enum.Material.SmoothPlastic
	part.Transparency = meshDef.Transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function wedge(parent, name, size, cf, color, material, transparency)
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function target(part, index)
	if index then
		part:SetAttribute("Empty43NpcIndex", index)
	end
	return part
end

local function addPremiumFX(model, root, accent)
	local highlight = Instance.new("Highlight")
	highlight.Name = "PremiumRimLight"
	highlight.FillTransparency = 0.88
	highlight.OutlineTransparency = 0.22
	highlight.FillColor = accent
	highlight.OutlineColor = Color3.fromRGB(210, 255, 170)
	highlight.Parent = model

	local aura = Instance.new("ParticleEmitter")
	aura.Name = "PremiumAuraMotes"
	aura.Color = ColorSequence.new(accent, Color3.fromRGB(255, 255, 210))
	aura.LightEmission = 0.55
	aura.Rate = 7
	aura.Lifetime = NumberRange.new(0.7, 1.35)
	aura.Speed = NumberRange.new(0.25, 1.1)
	aura.SpreadAngle = Vector2.new(38, 38)
	aura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.35, 0.16),
		NumberSequenceKeypoint.new(1, 0),
	})
	aura.Transparency = NumberSequence.new(0.15, 1)
	aura.Parent = root
end

function PremiumNPCFactory.CreateWorld43Small(options)
	options = options or {}
	local parent = options.Parent or workspace
	local baseCf = options.CFrame or CFrame.new()
	local index = options.TargetIndex
	local skin = options.SkinColor or Color3.fromRGB(93, 255, 29)
	local skinDark = options.SkinDarkColor or Color3.fromRGB(32, 145, 42)
	local cloth = options.ShirtColor or Color3.fromRGB(95, 48, 28)
	local eyeColor = options.EyeColor or Color3.fromRGB(255, 20, 62)
	local meshParts = options.MeshParts or {}

	local model = Instance.new("Model")
	model.Name = options.Name or "PremiumWorld43SmallNPC"
	model.Parent = parent

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = options.DisplayName or "Small NPC"
	humanoid.MaxHealth = options.MaxHealth or 1
	humanoid.Health = humanoid.MaxHealth
	humanoid.Parent = model

	local root = makeBasePart(model, "HumanoidRootPart", Vector3.new(2, 2, 2), baseCf, skin, Enum.Material.Neon, 1)
	root.CanTouch = false
	model.PrimaryPart = root
	addPremiumFX(model, root, skin)

	local function cf(localCf)
		return baseCf * localCf
	end

	local headCf = cf(CFrame.new(0, 4.55, -1.25) * CFrame.Angles(math.rad(-13), 0, 0))
	if meshParts.Head and meshParts.Head.MeshId and meshParts.Head.MeshId ~= "" then
		target(PremiumNPCFactory.CreateMeshPart(model, "Head", meshParts.Head, headCf, skin), index)
	else
		target(smooth(model, "Head", Vector3.new(5.6, 4.25, 4.75), headCf, skin, 0), index)
	end
	target(smooth(model, "BrowMass", Vector3.new(4.65, 1.05, 1.25), cf(CFrame.new(0, 5.15, -3.15)), skin, 0), index)
	target(smooth(model, "Jaw", Vector3.new(3.9, 2.05, 2.9), cf(CFrame.new(0, 3.45, -2.85)), skin, 0), index)
	target(smooth(model, "Torso", Vector3.new(4.7, 5.25, 3.05), cf(CFrame.new(0, 0.2, 0.05) * CFrame.Angles(math.rad(9), 0, 0)), skin, 0), index)
	target(smooth(model, "RaggedVest", Vector3.new(5.25, 4.15, 3.25), cf(CFrame.new(0, 0, -0.25) * CFrame.Angles(math.rad(9), 0, 0)), cloth, 0.03), index)

	for side = -1, 1, 2 do
		target(wedge(model, "EarOuter" .. side, Vector3.new(1.45, 2.4, 7.8), cf(CFrame.new(side * 3.75, 4.95, -0.95) * CFrame.Angles(math.rad(-4), math.rad(side * 82), math.rad(side * -18))), skin, nil, 0), index)
		target(wedge(model, "EarInner" .. side, Vector3.new(0.55, 1.2, 5.3), cf(CFrame.new(side * 3.95, 4.82, -1.05) * CFrame.Angles(math.rad(-4), math.rad(side * 82), math.rad(side * -18))), skinDark, nil, 0), index)
		local eye = target(smooth(model, "EyeGlow" .. side, Vector3.new(0.82, 0.22, 0.12), cf(CFrame.new(side * 1.05, 4.94, -4.04) * CFrame.Angles(0, 0, math.rad(side * -13))), eyeColor, 0), index)
		eye.Material = Enum.Material.Neon
		local light = Instance.new("PointLight")
		light.Color = eyeColor
		light.Brightness = 1.8
		light.Range = 8
		light.Parent = eye
		target(wedge(model, "SideFang" .. side, Vector3.new(0.45, 0.95, 0.42), cf(CFrame.new(side * 1.28, 3.18, -4.38) * CFrame.Angles(math.rad(180), 0, math.rad(side * 8))), Color3.fromRGB(242, 246, 235), nil, 0), index)
	end

	return model
end

return PremiumNPCFactory
