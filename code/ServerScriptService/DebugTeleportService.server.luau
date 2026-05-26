-- DebugTeleportService.server.luau
-- Handles debug teleport requests from the client UI.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local ServerStorage     = game:GetService("ServerStorage")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local WorldOrder        = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local IS_DEBUG = Balance.ActiveMode == "debug" or Balance.ActiveMode == "test" or Balance.ActiveMode == "fallback-debug"
if not IS_DEBUG then return end

local SPAWN_POSITIONS = {
	[1]  = CFrame.new(  0,  7,    0),
	[2]  = CFrame.new(  0,  7,  142),
	[3]  = CFrame.new(  0,  8,  398),
	[4]  = CFrame.new(  0,  8,  652),
	[5]  = CFrame.new(  0,  8,  872),
	[6]  = CFrame.new(  0,  8, 1102),
	[7]  = CFrame.new(  0,  8, 1312),
	[8]  = CFrame.new(  0,  8, 1558),
	[9]  = CFrame.new(224,  8, 1700),
	[10] = CFrame.new(590,  8, 1700),
	[11] = CFrame.new(918,  8, 1700),
	[12] = CFrame.new(1270, 8, 1700),
	[13] = CFrame.new(1622, 8, 1700),
	[14] = CFrame.new(1974, 8, 1700),
	[15] = CFrame.new(2326, 8, 1700),
	[16] = CFrame.new(2678, 8, 1700),
	[17] = CFrame.new(-550,  8, 1700),
	[18] = CFrame.new(-1320, 8, 1700),
	[19] = CFrame.new(-2090, 8, 1700),
	[20] = CFrame.new(-2540, 8, 1700),
	[21] = CFrame.new(-3500, 8, 1700),
	[22] = CFrame.new(-3660, 8, 1700),
	[23] = CFrame.new(-2860, 8, 2162),
	[24] = CFrame.new(-2860, 8, 2550),
	[25] = CFrame.new(-2860, 8, 2900),
	[26] = CFrame.new(-2860, 8, 3200),
	[27] = CFrame.new(-2860, 8, 3500),
	[28] = CFrame.new(-2860, 8, 3830),
	[29] = CFrame.new(-2860, 8, 4130),
	[30] = CFrame.new(-2860, 8, 4450),
	[31] = CFrame.new(-2860, 8, 4760),
	[32] = CFrame.new(-2860, 8, 5060),
	[33] = CFrame.new(-2860, 8, 5340),
	[34] = CFrame.new(-2860, 8, 5620),
	[35] = CFrame.new(-2860, 8, 5900),
	[36] = CFrame.new(-2860, 8, 6185),
	[37] = CFrame.new(-2860, 8, 6470),
	[38] = CFrame.new(-2860, 8, 6755),
	[39] = CFrame.new(-2860, 8, 7040),
	[40] = CFrame.new(-2860, 8, 7325),
	[41] = CFrame.new(-2860, 8, 7610),
	[42] = CFrame.new(-2860, 8, 8100),
	[43] = CFrame.new(-2860, 8, 8410),
	[44] = CFrame.new(-2860, 8, 8700),
	[45] = CFrame.new(-2860, 8, 9150),
	[46] = CFrame.new(-2860, 8, 9800),
	[47] = CFrame.new(-2860, 8, 11520),
	[48] = CFrame.new(-2860, 8, 11700),
	[49] = CFrame.new(-2860, 8, 13000),
	[50] = CFrame.new(-2860, 8, 14300),
}
for order, respawnCFrame in WorldOrder.LevelRespawns do
	SPAWN_POSITIONS[order] = respawnCFrame
end

-- Create RemoteEvent
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
if not gameEvents then return end

local remote = gameEvents:FindFirstChild("DebugTeleport")
if remote and not remote:IsA("RemoteEvent") then
	remote:Destroy()
	remote = nil
end
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "DebugTeleport"
	remote.Parent = gameEvents
end

local STARTER_CF = CFrame.new(0, 7, 0)
local level43MovementConnection = nil

local function ensureLevel43DebugNpcs()
	local existing = workspace:FindFirstChild("EmptyWorld43NPCs")
	if existing and existing:GetAttribute("DesignVersion") == "premium-framework-v12" and #existing:GetChildren() >= 8 then
		return
	end
	if existing then
		existing:Destroy()
	end
	if level43MovementConnection then
		level43MovementConnection:Disconnect()
		level43MovementConnection = nil
	end

	local folder = Instance.new("Folder")
	folder.Name = "EmptyWorld43NPCs"
	folder:SetAttribute("DesignVersion", "premium-framework-v12")
	folder.Parent = workspace

	local function makePart(parent, name, size, cf, color, material, transparency)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.BrickColor = BrickColor.new(color)
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

	local function makeBall(parent, name, size, cf, color, material, transparency)
		local part = makePart(parent, name, Vector3.new(size, size, size), cf, color, material, transparency)
		part.Shape = Enum.PartType.Ball
		return part
	end

	local function makeWedge(parent, name, size, cf, color, material, transparency)
		local part = Instance.new("WedgePart")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.BrickColor = BrickColor.new(color)
		part.Material = material or Enum.Material.SmoothPlastic
		part.Transparency = transparency or 0
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = true
		part.CastShadow = false
		part.Parent = parent
		return part
	end

	local function makeCylinder(parent, name, size, cf, color, material, transparency)
		local part = makePart(parent, name, size, cf, color, material, transparency)
		part.Shape = Enum.PartType.Cylinder
		return part
	end

	local function makeSmooth(parent, name, scale, cf, color, transparency)
		local part = makePart(parent, name, Vector3.new(1, 1, 1), cf, color, Enum.Material.SmoothPlastic, transparency)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = scale
		mesh.Parent = part
		return part
	end

	local function tagTarget(part, index)
		part:SetAttribute("Empty43NpcIndex", index)
		return part
	end

	local function addPremiumModelFX(model, root, accentColor)
		local highlight = Instance.new("Highlight")
		highlight.Name = "PremiumNPC_RimLight"
		highlight.FillTransparency = 0.86
		highlight.OutlineTransparency = 0.22
		highlight.FillColor = accentColor
		highlight.OutlineColor = Color3.fromRGB(190, 255, 120)
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model

		local aura = Instance.new("ParticleEmitter")
		aura.Name = "PremiumNPC_AuraMotes"
		aura.Color = ColorSequence.new(accentColor, Color3.fromRGB(255, 255, 190))
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

	local function addEyeLight(parent, color)
		local light = Instance.new("PointLight")
		light.Name = "PremiumEyeLight"
		light.Color = color
		light.Brightness = 1.8
		light.Range = 8
		light.Shadows = false
		light.Parent = parent
	end

	local function addNameBillboard(adornee, text, color)
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "PremiumNameplate"
		billboard.Size = UDim2.new(0, 190, 0, 34)
		billboard.StudsOffset = Vector3.new(0, 5.8, 0)
		billboard.MaxDistance = 180
		billboard.AlwaysOnTop = true
		billboard.Parent = adornee

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
		label.BackgroundTransparency = 0.18
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.15
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = label
	end

	local function getFullNameSafe(instance)
		local ok, name = pcall(function()
			return instance:GetFullName()
		end)
		return ok and name or instance.Name
	end

	local function addSpawnMarker(x, z, text)
		local marker = makePart(folder, text .. "Marker", Vector3.new(8, 0.35, 8), CFrame.new(x, 1.95, z), "Cyan", Enum.Material.Neon, 0.35)
		marker.CanTouch = false
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 180, 0, 28)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 180
		billboard.Parent = marker
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(120, 255, 255)
		label.TextStrokeTransparency = 0.2
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = billboard
	end

	local function makeSmall(index, x, z, shirtColor)
		local model = Instance.new("Model")
		model.Name = "Empty43DebugNPC" .. index
		model.Parent = folder

		local humanoid = Instance.new("Humanoid")
		humanoid.DisplayName = "Small NPC"
		humanoid.MaxHealth = 1
		humanoid.Health = 1
		humanoid.Parent = model

		local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 2), CFrame.new(x, 4, z), "Lime green", Enum.Material.Neon, 1)
		root.CanTouch = false
		model.PrimaryPart = root
		addPremiumModelFX(model, root, Color3.fromRGB(120, 255, 60))

		local function cf(localCf)
			return root.CFrame * localCf
		end

		local oldHead = tagTarget(makeSmooth(model, "HeadSmooth", Vector3.new(5.6, 4.25, 4.75), cf(CFrame.new(0, 8.55, -1.25) * CFrame.Angles(math.rad(-13), 0, 0)), "Lime green", 0), index)
		if index == 1 then
			addNameBillboard(oldHead, "OLD NPC - MOVING", Color3.fromRGB(170, 255, 120))
		end
		tagTarget(makeSmooth(model, "BrowMass", Vector3.new(4.65, 1.05, 1.25), cf(CFrame.new(0, 9.15, -3.15) * CFrame.Angles(math.rad(-10), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "JawSmooth", Vector3.new(3.9, 2.05, 2.9), cf(CFrame.new(0, 7.45, -2.85) * CFrame.Angles(math.rad(-10), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "ChinPoint", Vector3.new(1.45, 0.95, 1.25), cf(CFrame.new(0, 6.95, -3.1) * CFrame.Angles(math.rad(-10), 0, 0)), "Lime green", 0), index)
		tagTarget(makeSmooth(model, "CheekL", Vector3.new(1.65, 1.22, 1.22), cf(CFrame.new(-1.42, 8.0, -2.85)), "Lime green", 0), index)
		tagTarget(makeSmooth(model, "CheekR", Vector3.new(1.65, 1.22, 1.22), cf(CFrame.new(1.42, 8.0, -2.85)), "Lime green", 0), index)
		tagTarget(makeSmooth(model, "FacePlane", Vector3.new(3.5, 2.0, 0.45), cf(CFrame.new(0, 8.25, -3.55) * CFrame.Angles(math.rad(-5), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "NeckSmooth", Vector3.new(2.0, 1.55, 1.75), cf(CFrame.new(0, 6.15, -0.55) * CFrame.Angles(math.rad(-12), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "TorsoSmooth", Vector3.new(4.7, 5.25, 3.05), cf(CFrame.new(0, 4.2, 0.05) * CFrame.Angles(math.rad(9), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "BellySmooth", Vector3.new(4.1, 3.0, 2.65), cf(CFrame.new(0, 3.6, -0.65) * CFrame.Angles(math.rad(10), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "RaggedVestBody", Vector3.new(5.25, 4.15, 3.25), cf(CFrame.new(0, 4.0, -0.25) * CFrame.Angles(math.rad(9), 0, 0)), shirtColor, 0.03), index)
		tagTarget(makeSmooth(model, "VestNeckOpening", Vector3.new(2.55, 1.15, 3.55), cf(CFrame.new(0, 6.0, -0.52) * CFrame.Angles(math.rad(9), 0, 0)), "Bright green", 0), index)
		for tear = -2, 2 do
			local h = 1.5 + (math.abs(tear) % 2) * 0.55
			tagTarget(makeWedge(model, "SharpTunicTear" .. tear, Vector3.new(1.0, h, 1.25), cf(CFrame.new(tear * 0.95, 1.55 - h * 0.08, -1.7) * CFrame.Angles(math.rad(180), 0, math.rad(tear * 7))), shirtColor, Enum.Material.Fabric, 0), index)
		end
		tagTarget(makeSmooth(model, "ShoulderWrapSmooth", Vector3.new(5.85, 0.85, 3.35), cf(CFrame.new(0, 5.95, -0.25) * CFrame.Angles(math.rad(9), 0, 0)), "Brown", 0), index)

		for _, side in ipairs({ -1, 1 }) do
			tagTarget(makeSmooth(model, "ShoulderSmooth" .. side, Vector3.new(1.65, 1.35, 1.4), cf(CFrame.new(side * 2.8, 5.88, -0.45)), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "UpperArmSmooth" .. side, Vector3.new(1.05, 3.55, 1.05), cf(CFrame.new(side * 3.35, 4.55, -1.05) * CFrame.Angles(math.rad(22), 0, math.rad(side * 22))), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "ElbowSmooth" .. side, Vector3.new(1.1, 1.1, 1.0), cf(CFrame.new(side * 3.92, 3.05, -1.85)), "Bright green", 0), index)
			tagTarget(makeSmooth(model, "ForearmSmooth" .. side, Vector3.new(0.95, 3.45, 0.95), cf(CFrame.new(side * 4.18, 2.35, -2.2) * CFrame.Angles(math.rad(42), 0, math.rad(side * -8))), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "HandSmooth" .. side, Vector3.new(1.65, 1.2, 1.45), cf(CFrame.new(side * 4.45, 0.98, -3.22)), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "ThighSmooth" .. side, Vector3.new(1.2, 2.75, 1.15), cf(CFrame.new(side * 1.35, 1.25, 0.2) * CFrame.Angles(math.rad(-18), 0, math.rad(side * 8))), "Bright green", 0), index)
			tagTarget(makeSmooth(model, "KneeSmooth" .. side, Vector3.new(1.1, 0.95, 1.05), cf(CFrame.new(side * 1.47, -0.2, -0.1)), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "ShinSmooth" .. side, Vector3.new(1.0, 2.5, 1.0), cf(CFrame.new(side * 1.55, -0.8, -0.35) * CFrame.Angles(math.rad(12), 0, math.rad(side * -6))), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "FootSmooth" .. side, Vector3.new(2.4, 0.85, 3.2), cf(CFrame.new(side * 1.55, -2.2, -1.45) * CFrame.Angles(math.rad(-4), 0, 0)), "Lime green", 0), index)
			tagTarget(makeWedge(model, "EarOuter" .. side, Vector3.new(1.45, 2.4, 7.8), cf(CFrame.new(side * 3.75, 8.95, -0.95) * CFrame.Angles(math.rad(-4), math.rad(side * 82), math.rad(side * -18))), "Lime green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "EarInner" .. side, Vector3.new(0.55, 1.2, 5.3), cf(CFrame.new(side * 3.95, 8.82, -1.05) * CFrame.Angles(math.rad(-4), math.rad(side * 82), math.rad(side * -18))), "Bright green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeSmooth(model, "EyeSocket" .. side, Vector3.new(1.35, 0.62, 0.18), cf(CFrame.new(side * 1.05, 8.94, -3.93) * CFrame.Angles(0, 0, math.rad(side * -13))), "Really black", 0), index)
			local eye = tagTarget(makeSmooth(model, "EyeGlow" .. side, Vector3.new(0.82, 0.22, 0.12), cf(CFrame.new(side * 1.05, 8.94, -4.04) * CFrame.Angles(0, 0, math.rad(side * -13))), "Really red", 0), index)
			eye.Material = Enum.Material.Neon
			addEyeLight(eye, Color3.fromRGB(255, 20, 62))
			tagTarget(makePart(model, "SharpUpperLid" .. side, Vector3.new(1.45, 0.18, 0.22), cf(CFrame.new(side * 1.05, 9.18, -4.04) * CFrame.Angles(0, 0, math.rad(side * -18))), "Forest green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makePart(model, "SharpLowerLid" .. side, Vector3.new(1.05, 0.12, 0.18), cf(CFrame.new(side * 1.04, 8.74, -4.02) * CFrame.Angles(0, 0, math.rad(side * 7))), "Bright green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "AngryBrow" .. side, Vector3.new(0.55, 0.42, 1.8), cf(CFrame.new(side * 1.02, 9.34, -3.85) * CFrame.Angles(math.rad(84), math.rad(side * 6), math.rad(side * 58))), "Forest green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeSmooth(model, "TempleRidge" .. side, Vector3.new(0.95, 0.65, 1.05), cf(CFrame.new(side * 1.95, 8.85, -3.15) * CFrame.Angles(0, math.rad(side * 20), 0)), "Bright green", 0), index)
			for claw = -1, 1 do
				tagTarget(makeWedge(model, "Finger" .. side .. "_" .. claw, Vector3.new(0.35, 0.45, 1.55), cf(CFrame.new(side * (4.35 + claw * 0.34), 0.65, -4.1) * CFrame.Angles(math.rad(-24), 0, math.rad(side * 4))), "Lime green", Enum.Material.SmoothPlastic, 0), index)
				tagTarget(makeWedge(model, "Toe" .. side .. "_" .. claw, Vector3.new(0.38, 0.45, 1.35), cf(CFrame.new(side * (1.55 + claw * 0.42), -2.45, -2.95) * CFrame.Angles(math.rad(-16), 0, 0)), "Lime green", Enum.Material.SmoothPlastic, 0), index)
			end
		end

		tagTarget(makeSmooth(model, "NoseBridge", Vector3.new(0.85, 1.2, 0.55), cf(CFrame.new(0, 8.55, -4.0) * CFrame.Angles(math.rad(-7), 0, 0)), "Forest green", 0), index)
		tagTarget(makeSmooth(model, "NoseBulb", Vector3.new(1.18, 0.72, 0.55), cf(CFrame.new(0, 8.08, -4.22) * CFrame.Angles(math.rad(-7), 0, 0)), "Bright green", 0), index)
		for _, side in ipairs({ -1, 1 }) do
			tagTarget(makeSmooth(model, "Nostril" .. side, Vector3.new(0.28, 0.16, 0.08), cf(CFrame.new(side * 0.34, 7.98, -4.53)), "Really black", 0), index)
		end
		tagTarget(makeSmooth(model, "UpperLip", Vector3.new(2.65, 0.32, 0.22), cf(CFrame.new(0, 7.62, -4.18) * CFrame.Angles(math.rad(-4), 0, 0)), "Forest green", 0), index)
		tagTarget(makePart(model, "MouthShadow", Vector3.new(2.45, 0.34, 0.18), cf(CFrame.new(0, 7.42, -4.28) * CFrame.Angles(math.rad(-2), 0, 0)), "Really black", Enum.Material.SmoothPlastic, 0), index)
		tagTarget(makeSmooth(model, "LowerLip", Vector3.new(2.1, 0.28, 0.18), cf(CFrame.new(0, 7.2, -4.2) * CFrame.Angles(math.rad(-4), 0, 0)), "Lime green", 0), index)
		for tooth = -2, 2 do
			local h = tooth == 0 and 0.7 or 0.5
			tagTarget(makeWedge(model, "UpperTooth" .. tooth, Vector3.new(0.32, h, 0.38), cf(CFrame.new(tooth * 0.42, 7.18, -4.42) * CFrame.Angles(math.rad(180), 0, 0)), "Institutional white", Enum.Material.SmoothPlastic, 0), index)
		end
		for _, side in ipairs({ -1, 1 }) do
			tagTarget(makeWedge(model, "SideFang" .. side, Vector3.new(0.45, 0.95, 0.42), cf(CFrame.new(side * 1.28, 7.18, -4.38) * CFrame.Angles(math.rad(180), 0, math.rad(side * 8))), "Institutional white", Enum.Material.SmoothPlastic, 0), index)
		end

		return model
	end

	local function makePremiumFrameworkEnemy(index, x, z, shirtColor)
		local function findImportedGoblin()
			local wantedNames = {
				goblin2 = true,
				goblin1 = true,
				sketchfab_scene = true,
			}
			local roots = { workspace, ReplicatedStorage, ServerStorage }
			for _, root in ipairs(roots) do
				for _, object in ipairs(root:GetDescendants()) do
					if wantedNames[object.Name:lower()] and not object:IsDescendantOf(folder) then
						return object
					end
				end
			end
			return nil
		end

		local function normalizeImportedClone(clone)
			if clone:IsA("Model") then
				return clone
			end
			if clone:IsA("BasePart") then
				local model = Instance.new("Model")
				clone.Parent = model
				model.PrimaryPart = clone
				return model
			end
			local model = Instance.new("Model")
			for _, child in ipairs(clone:GetChildren()) do
				child.Parent = model
			end
			clone:Destroy()
			return model
		end

		local imported = nil -- Premium framework NPCs stay procedural; imported goblins are placed separately below.
		if imported then
			imported.Archivable = true
			local clone = imported:Clone()
			if not clone then
				warn("[DebugTeleportService] Found sketchfab_scene but Clone returned nil:", getFullNameSafe(imported))
				return nil
			end
			print("[DebugTeleportService] Found imported goblin model:", getFullNameSafe(imported))
			local model = normalizeImportedClone(clone)
			model.Name = "World43ImportedGoblinNPC" .. index
			model.Parent = folder

			local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)
			if root then
				model.PrimaryPart = root
				local visibleParts = 0
				for _, object in ipairs(model:GetDescendants()) do
					if object:IsA("BasePart") then
						object.Transparency = 0
						object.LocalTransparencyModifier = 0
						if object.Color == Color3.new(0, 0, 0) then
							object.Color = Color3.fromRGB(95, 255, 45)
							object.Material = Enum.Material.SmoothPlastic
						end
						object.CastShadow = true
						if object:IsA("MeshPart") then
							object.DoubleSided = true
							object.RenderFidelity = Enum.RenderFidelity.Precise
						end
						visibleParts += 1
					elseif object:IsA("SurfaceAppearance") or object:IsA("Decal") or object:IsA("Texture") then
						object:Destroy()
					end
				end
				local _, sizeBefore = model:GetBoundingBox()
				print("[DebugTeleportService] Imported goblin clone visible parts:", visibleParts, "size:", sizeBefore)
				if sizeBefore.Y > 0 then
					local targetHeight = 16
					local scaleFactor = math.clamp(targetHeight / sizeBefore.Y, 0.03, 35)
					pcall(function()
						model:ScaleTo(scaleFactor)
					end)
				end
				local boxCf, sizeAfter = model:GetBoundingBox()
				local targetCenter = Vector3.new(x, 2 + math.max(4, sizeAfter.Y * 0.5), z)
				local pivotOffsetFromBox = boxCf:ToObjectSpace(model:GetPivot())
				model:PivotTo(CFrame.new(targetCenter) * CFrame.Angles(0, math.rad(index == 5 and -25 or 25), 0) * pivotOffsetFromBox)
				local _, finalSize = model:GetBoundingBox()
				local outline = makePart(folder, "ImportedGoblinBounds" .. index, finalSize + Vector3.new(0.8, 0.8, 0.8), CFrame.new(targetCenter), "Cyan", Enum.Material.ForceField, 0.78)
				outline.CanTouch = false
				outline.CanCollide = false
				addNameBillboard(root, index == 5 and "NEW IMPORTED GOBLIN 1" or "NEW IMPORTED GOBLIN 2", Color3.fromRGB(120, 255, 255))
				addPremiumModelFX(model, root, Color3.fromRGB(120, 255, 60))
				addSpawnMarker(x, z, index == 5 and "IMPORTED 1" or "IMPORTED 2")
			else
				warn("[DebugTeleportService] Found sketchfab_scene but it has no BasePart descendants.")
			end

			local humanoid = model:FindFirstChildWhichIsA("Humanoid")
			if not humanoid then
				humanoid = Instance.new("Humanoid")
				humanoid.Parent = model
			end
			humanoid.DisplayName = "Imported Goblin"
			humanoid.MaxHealth = 42
			humanoid.Health = 42

			for _, object in ipairs(model:GetDescendants()) do
				if object:IsA("BasePart") then
					object.Anchored = true
					object.CanCollide = false
					object.CanTouch = true
					object.CastShadow = true
					object:SetAttribute("Empty43NpcIndex", index)
				end
			end

			return model
		end
		warn("[DebugTeleportService] Could not find imported goblin2/goblin1/sketchfab_scene in Workspace, ReplicatedStorage, or ServerStorage; using procedural premium NPC.")

		local model = Instance.new("Model")
		model.Name = "World43PremiumNPC" .. index
		model.Parent = folder

		local humanoid = Instance.new("Humanoid")
		humanoid.DisplayName = "Forest Goblin"
		humanoid.MaxHealth = 42
		humanoid.Health = 42
		humanoid.Parent = model

		local root = makePart(model, "HumanoidRootPart", Vector3.new(2, 2, 2), CFrame.new(x, 4, z), "Lime green", Enum.Material.Neon, 1)
		root.CanTouch = false
		model.PrimaryPart = root
		addPremiumModelFX(model, root, Color3.fromRGB(120, 255, 60))

		local function cf(localCf)
			return root.CFrame * localCf
		end

		local premiumHead = tagTarget(makeSmooth(model, "PremiumHeadCranium", Vector3.new(6.55, 4.25, 5.3), cf(CFrame.new(0, 9.52, -1.25) * CFrame.Angles(math.rad(-15), 0, 0)), "Bright green", 0), index)
		addNameBillboard(premiumHead, index == 5 and "NEW PREMIUM NPC 1" or "NEW PREMIUM NPC 2", Color3.fromRGB(120, 255, 255))
		tagTarget(makeSmooth(model, "PremiumBackSkull", Vector3.new(4.8, 3.5, 3.1), cf(CFrame.new(0, 9.65, 0.55) * CFrame.Angles(math.rad(-8), 0, 0)), "Lime green", 0), index)
		tagTarget(makeSmooth(model, "PremiumFaceWedge", Vector3.new(4.55, 2.25, 1.15), cf(CFrame.new(0, 9.0, -4.08) * CFrame.Angles(math.rad(-12), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "PremiumBrowMass", Vector3.new(5.55, 1.32, 1.45), cf(CFrame.new(0, 10.02, -3.62) * CFrame.Angles(math.rad(-10), 0, 0)), "Forest green", 0), index)
		tagTarget(makeWedge(model, "PremiumCenterBrowPoint", Vector3.new(1.25, 0.8, 1.65), cf(CFrame.new(0, 10.08, -4.0) * CFrame.Angles(math.rad(82), 0, math.rad(45))), "Forest green", Enum.Material.SmoothPlastic, 0), index)
		tagTarget(makeSmooth(model, "PremiumJaw", Vector3.new(4.45, 2.22, 3.25), cf(CFrame.new(0, 8.12, -3.22) * CFrame.Angles(math.rad(-10), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "PremiumChinBlade", Vector3.new(1.55, 1.05, 1.28), cf(CFrame.new(0, 7.55, -3.62) * CFrame.Angles(math.rad(-12), 0, 0)), "Lime green", 0), index)
		tagTarget(makeSmooth(model, "PremiumTorso", Vector3.new(5.25, 6.1, 3.55), cf(CFrame.new(0, 4.65, 0.05) * CFrame.Angles(math.rad(8), 0, 0)), "Bright green", 0), index)
		tagTarget(makeSmooth(model, "PremiumArmorChest", Vector3.new(5.7, 4.7, 3.75), cf(CFrame.new(0, 4.55, -0.38) * CFrame.Angles(math.rad(8), 0, 0)), "Really black", 0.08), index)
		tagTarget(makeSmooth(model, "PremiumClothSkirt", Vector3.new(5.45, 2.2, 3.45), cf(CFrame.new(0, 2.05, -0.18) * CFrame.Angles(math.rad(7), 0, 0)), shirtColor, 0.02), index)
		local chestCore = tagTarget(makeSmooth(model, "PremiumChestCore", Vector3.new(1.1, 1.1, 0.35), cf(CFrame.new(0, 4.95, -2.22)), "Really red", 0), index)
		chestCore.Material = Enum.Material.Neon
		addEyeLight(chestCore, Color3.fromRGB(255, 35, 70))

		for tear = -2, 2 do
			local h = 1.5 + (math.abs(tear) % 2) * 0.55
			tagTarget(makeWedge(model, "PremiumArmorTear" .. tear, Vector3.new(1.05, h, 1.25), cf(CFrame.new(tear * 0.98, 0.92 - h * 0.08, -1.85) * CFrame.Angles(math.rad(180), 0, math.rad(tear * 7))), shirtColor, Enum.Material.Fabric, 0), index)
		end

		for crest = -2, 2 do
			tagTarget(makeWedge(model, "PremiumRedMane" .. crest, Vector3.new(1.3, 3.4, 1.45), cf(CFrame.new(crest * 0.72, 12.0 - math.abs(crest) * 0.22, 0.58) * CFrame.Angles(0, 0, math.rad(crest * 9))), "Really red", Enum.Material.Neon, 0.04), index)
		end

		for _, side in ipairs({ -1, 1 }) do
			tagTarget(makeWedge(model, "PremiumShoulderPlate" .. side, Vector3.new(2.4, 1.4, 3.4), cf(CFrame.new(side * 3.18, 6.7, -0.5) * CFrame.Angles(0, math.rad(side * 22), math.rad(side * 18))), "Really black", Enum.Material.Metal, 0.03), index)
			tagTarget(makeWedge(model, "PremiumShoulderSpike" .. side, Vector3.new(1.4, 1.5, 3.0), cf(CFrame.new(side * 4.05, 7.0, -0.72) * CFrame.Angles(0, math.rad(side * 42), math.rad(side * 42))), "Really red", Enum.Material.Neon, 0.04), index)
			tagTarget(makeSmooth(model, "PremiumShoulder" .. side, Vector3.new(1.9, 1.45, 1.55), cf(CFrame.new(side * 3.02, 6.05, -0.45)), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "PremiumUpperArm" .. side, Vector3.new(1.16, 3.95, 1.16), cf(CFrame.new(side * 3.68, 4.55, -1.2) * CFrame.Angles(math.rad(20), 0, math.rad(side * 29))), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "PremiumForearm" .. side, Vector3.new(1.08, 3.85, 1.08), cf(CFrame.new(side * 4.75, 2.12, -2.55) * CFrame.Angles(math.rad(42), 0, math.rad(side * -11))), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "PremiumHand" .. side, Vector3.new(2.05, 1.35, 1.72), cf(CFrame.new(side * 5.08, 0.58, -3.82)), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "PremiumThigh" .. side, Vector3.new(1.4, 3.05, 1.32), cf(CFrame.new(side * 1.62, 1.12, 0.15) * CFrame.Angles(math.rad(-14), 0, math.rad(side * 10))), "Bright green", 0), index)
			tagTarget(makeSmooth(model, "PremiumShin" .. side, Vector3.new(1.14, 2.95, 1.14), cf(CFrame.new(side * 1.82, -1.12, -0.42) * CFrame.Angles(math.rad(10), 0, math.rad(side * -8))), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "PremiumFoot" .. side, Vector3.new(2.9, 0.95, 3.65), cf(CFrame.new(side * 1.82, -2.82, -1.68) * CFrame.Angles(math.rad(-4), 0, 0)), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "PremiumCheekPlane" .. side, Vector3.new(1.35, 1.15, 1.55), cf(CFrame.new(side * 1.72, 8.75, -3.42) * CFrame.Angles(0, math.rad(side * 18), 0)), "Lime green", 0), index)
			tagTarget(makeSmooth(model, "PremiumTempleBulge" .. side, Vector3.new(1.35, 1.25, 1.35), cf(CFrame.new(side * 2.72, 9.78, -1.2) * CFrame.Angles(0, math.rad(side * 14), 0)), "Lime green", 0), index)
			tagTarget(makeWedge(model, "PremiumEarOuterBase" .. side, Vector3.new(1.85, 3.05, 5.2), cf(CFrame.new(side * 4.05, 9.68, -0.85) * CFrame.Angles(math.rad(-5), math.rad(side * 76), math.rad(side * -12))), "Lime green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "PremiumEarOuterTip" .. side, Vector3.new(1.35, 2.15, 5.9), cf(CFrame.new(side * 5.52, 9.85, -1.22) * CFrame.Angles(math.rad(-7), math.rad(side * 88), math.rad(side * -20))), "Lime green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "PremiumEarInnerBase" .. side, Vector3.new(0.72, 1.55, 3.65), cf(CFrame.new(side * 4.28, 9.56, -1.18) * CFrame.Angles(math.rad(-5), math.rad(side * 76), math.rad(side * -12))), "Forest green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "PremiumEarInnerTip" .. side, Vector3.new(0.5, 1.0, 3.95), cf(CFrame.new(side * 5.55, 9.73, -1.48) * CFrame.Angles(math.rad(-7), math.rad(side * 88), math.rad(side * -20))), "Bright green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "PremiumEarRidgeTop" .. side, Vector3.new(0.42, 0.55, 5.6), cf(CFrame.new(side * 4.85, 10.78, -1.0) * CFrame.Angles(math.rad(-8), math.rad(side * 84), math.rad(side * -18))), "Forest green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "PremiumEarRidgeBottom" .. side, Vector3.new(0.34, 0.46, 4.8), cf(CFrame.new(side * 4.9, 8.72, -1.12) * CFrame.Angles(math.rad(6), math.rad(side * 84), math.rad(side * -18))), "Forest green", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "PremiumHorn" .. side, Vector3.new(1.18, 1.6, 4.05), cf(CFrame.new(side * 2.0, 11.85, -1.86) * CFrame.Angles(math.rad(-18), math.rad(side * 20), math.rad(side * 34))), "Institutional white", Enum.Material.SmoothPlastic, 0), index)
			tagTarget(makeWedge(model, "PremiumSmallHorn" .. side, Vector3.new(0.75, 0.95, 2.2), cf(CFrame.new(side * 2.85, 11.28, -0.38) * CFrame.Angles(math.rad(-8), math.rad(side * 30), math.rad(side * 28))), "Institutional white", Enum.Material.SmoothPlastic, 0), index)

			local eye = tagTarget(makeSmooth(model, "PremiumEyeGlow" .. side, Vector3.new(0.9, 0.24, 0.12), cf(CFrame.new(side * 1.1, 9.0, -4.22) * CFrame.Angles(0, 0, math.rad(side * -13))), "Really red", 0), index)
			eye.Material = Enum.Material.Neon
			addEyeLight(eye, Color3.fromRGB(255, 20, 62))
			tagTarget(makeWedge(model, "PremiumBrowBlade" .. side, Vector3.new(0.58, 0.45, 1.95), cf(CFrame.new(side * 1.08, 9.42, -4.0) * CFrame.Angles(math.rad(84), math.rad(side * 6), math.rad(side * 58))), "Forest green", Enum.Material.SmoothPlastic, 0), index)
			for claw = -1, 1 do
				tagTarget(makeWedge(model, "PremiumFinger" .. side .. "_" .. claw, Vector3.new(0.44, 0.52, 1.95), cf(CFrame.new(side * (5.0 + claw * 0.42), 0.08, -4.82) * CFrame.Angles(math.rad(-24), 0, math.rad(side * 4))), "Institutional white", Enum.Material.SmoothPlastic, 0), index)
				tagTarget(makeWedge(model, "PremiumToe" .. side .. "_" .. claw, Vector3.new(0.46, 0.5, 1.65), cf(CFrame.new(side * (1.82 + claw * 0.5), -3.12, -3.48) * CFrame.Angles(math.rad(-16), 0, 0)), "Institutional white", Enum.Material.SmoothPlastic, 0), index)
			end
		end

		tagTarget(makeSmooth(model, "PremiumNoseBridge", Vector3.new(0.9, 1.25, 0.58), cf(CFrame.new(0, 8.62, -4.18) * CFrame.Angles(math.rad(-7), 0, 0)), "Forest green", 0), index)
		tagTarget(makeSmooth(model, "PremiumNoseBulb", Vector3.new(1.22, 0.74, 0.58), cf(CFrame.new(0, 8.08, -4.42) * CFrame.Angles(math.rad(-7), 0, 0)), "Bright green", 0), index)
		tagTarget(makePart(model, "PremiumMouthShadow", Vector3.new(2.55, 0.36, 0.18), cf(CFrame.new(0, 7.38, -4.48) * CFrame.Angles(math.rad(-2), 0, 0)), "Really black", Enum.Material.SmoothPlastic, 0), index)
		for tooth = -2, 2 do
			local h = tooth == 0 and 0.75 or 0.55
			tagTarget(makeWedge(model, "PremiumTooth" .. tooth, Vector3.new(0.34, h, 0.4), cf(CFrame.new(tooth * 0.44, 7.12, -4.62) * CFrame.Angles(math.rad(180), 0, 0)), "Institutional white", Enum.Material.SmoothPlastic, 0), index)
		end

		return model
	end

	local function makeBoss()
		local model = Instance.new("Model")
		model.Name = "Empty43DebugBoss"
		model.Parent = folder

		local humanoid = Instance.new("Humanoid")
		humanoid.DisplayName = "Boss"
		humanoid.MaxHealth = 7
		humanoid.Health = 7
		humanoid.Parent = model

		local root = makePart(model, "HumanoidRootPart", Vector3.new(16, 22, 10), CFrame.new(-2860, 13, 8434), "Bright green", Enum.Material.Neon, 0.05)
		root:SetAttribute("Empty43NpcIndex", 4)
		model.PrimaryPart = root
		local head = makePart(model, "BossHead", Vector3.new(10, 10, 10), CFrame.new(-2860, 29, 8431), "Bright green", Enum.Material.SmoothPlastic, 0)
		head.Shape = Enum.PartType.Ball
		head:SetAttribute("Empty43NpcIndex", 4)
		makePart(model, "BossBeard", Vector3.new(12, 8, 2), CFrame.new(-2860, 23, 8425), "Really red", Enum.Material.Neon, 0.05)
		makePart(model, "BossClub", Vector3.new(5, 24, 5), CFrame.new(-2875, 12, 8430) * CFrame.Angles(0, 0, math.rad(70)), "Brown", Enum.Material.Wood, 0)

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
		label.BorderSizePixel = 0
		label.Text = "BOSS 7/7"
		label.TextColor3 = Color3.fromRGB(255, 245, 220)
		label.TextStrokeTransparency = 0.25
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = billboard
	end

	local function placeSimpleImportedGoblin(importName, targetIndex, x, z, labelText)
		local source = workspace:FindFirstChild(importName, true)
			or ReplicatedStorage:FindFirstChild(importName, true)
			or ServerStorage:FindFirstChild(importName, true)
		if not source then
			warn("[DebugTeleportService] No imported goblin found for simple placement:", importName)
			return nil
		end

		source.Archivable = true
		for _, object in ipairs(source:GetDescendants()) do
			object.Archivable = true
		end

		local clone = source:Clone()
		clone.Name = "World43Imported_" .. importName
		clone.Parent = folder

		local model
		if clone:IsA("Model") then
			model = clone
		else
			model = Instance.new("Model")
			model.Name = "World43Imported_" .. importName
			clone.Parent = model
			model.Parent = folder
		end

		local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if root then
			model.PrimaryPart = root
			local _, sizeBefore = model:GetBoundingBox()
			if sizeBefore.Y > 0 then
				local scaleFactor = math.clamp(16 / sizeBefore.Y, 0.05, 20)
				pcall(function()
					model:ScaleTo(scaleFactor)
				end)
			end

			local boxCf, sizeAfter = model:GetBoundingBox()
			local targetCenter = Vector3.new(x, 2 + math.max(4, sizeAfter.Y * 0.5), z)
			local pivotOffsetFromBox = boxCf:ToObjectSpace(model:GetPivot())
			model:PivotTo(CFrame.new(targetCenter) * CFrame.Angles(0, math.rad(180), 0) * pivotOffsetFromBox)
			addNameBillboard(root, labelText, Color3.fromRGB(255, 230, 120))

			local outline = makePart(folder, "ImportedGoblinBounds_" .. importName, sizeAfter + Vector3.new(0.8, 0.8, 0.8), CFrame.new(targetCenter), "Cyan", Enum.Material.ForceField, 0.78)
			outline.CanCollide = false
			outline.CanTouch = false
			addSpawnMarker(x, z, labelText)
		end

		local humanoid = model:FindFirstChildWhichIsA("Humanoid") or Instance.new("Humanoid")
		humanoid.DisplayName = "Imported Goblin"
		humanoid.MaxHealth = 42
		humanoid.Health = 42
		humanoid.Parent = model

		local partCount = 0
		for _, object in ipairs(model:GetDescendants()) do
			if object:IsA("BasePart") then
				partCount += 1
				object.Anchored = true
				object.CanCollide = false
				object.CanTouch = true
				object.CastShadow = true
				object.Transparency = 0
				object.LocalTransparencyModifier = 0
				if object:IsA("MeshPart") then
					object.DoubleSided = true
					object.RenderFidelity = Enum.RenderFidelity.Precise
				end
				object:SetAttribute("Empty43NpcIndex", targetIndex)
			end
		end

		local _, finalSize = model:GetBoundingBox()
		print("[DebugTeleportService] Placed simple imported goblin from:", getFullNameSafe(source), "parts:", partCount, "size:", finalSize)
		return model
	end

	local movingOld = makeSmall(1, -2888, 8392, "Reddish brown")
	makeSmall(2, -2842, 8418, "Brown")
	makeSmall(3, -2826, 8384, "Dark orange")
	local movingNew = makePremiumFrameworkEnemy(5, -2898, 8432, "Reddish brown")
	makePremiumFrameworkEnemy(6, -2822, 8444, "Dark orange")
	placeSimpleImportedGoblin("goblin2", 8, -2848, 8434, "IMPORTED GOBLIN 2")
	makeBoss()

	local movers = {
		{ model = movingOld, base = movingOld and movingOld:GetPivot(), radius = 13, speed = 1.2, phase = 0 },
		{ model = movingNew, base = movingNew and movingNew:GetPivot(), radius = 17, speed = 0.9, phase = math.pi },
	}

	level43MovementConnection = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, mover in ipairs(movers) do
			if mover.model and mover.model.Parent and mover.base then
				local x = math.sin(now * mover.speed + mover.phase) * mover.radius
				local z = math.cos(now * mover.speed + mover.phase) * (mover.radius * 0.55)
				local pos = mover.base.Position + Vector3.new(x, 0, z)
				local look = mover.base.Position + Vector3.new(math.sin(now * mover.speed + mover.phase + 0.2) * mover.radius, 0, math.cos(now * mover.speed + mover.phase + 0.2) * (mover.radius * 0.55))
				mover.model:PivotTo(CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z)))
			end
		end
	end)
	print("[DebugTeleportService] Spawned level 43 debug NPC fallback.")
end

local function ensureLevel42ImportedGoblins()
	local existing = workspace:FindFirstChild("Level42ImportedGoblinDebug")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Level42ImportedGoblinDebug"
	folder:SetAttribute("DesignVersion", "import-test-v8")
	folder.Parent = workspace

	local function makeDebugPart(name, size, cf, color, transparency)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.BrickColor = BrickColor.new(color)
		part.Material = Enum.Material.Neon
		part.Transparency = transparency or 0.25
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = folder
		return part
	end

	local function addLabel(adornee, text)
		for _, child in ipairs(adornee:GetChildren()) do
			if child.Name == "ImportedGoblinDebugLabel" then
				child:Destroy()
			end
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ImportedGoblinDebugLabel"
		billboard.Size = UDim2.fromOffset(360, 82)
		billboard.StudsOffset = Vector3.new(0, 12, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 500
		billboard.Adornee = adornee

		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 0.22
		label.BackgroundColor3 = Color3.fromRGB(10, 20, 24)
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = Color3.fromRGB(120, 255, 255)
		label.TextStrokeTransparency = 0.2
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = billboard
		billboard.Parent = adornee
	end

	local function addStaticTextSign(name, cf, text)
		local sign = Instance.new("Part")
		sign.Name = name
		sign.Size = Vector3.new(15, 4, 0.35)
		sign.CFrame = cf
		sign.Anchored = true
		sign.CanCollide = false
		sign.CanTouch = false
		sign.CastShadow = false
		sign.Material = Enum.Material.SmoothPlastic
		sign.Color = Color3.fromRGB(8, 18, 22)
		sign.Parent = folder

		local surface = Instance.new("SurfaceGui")
		surface.Name = "StaticText"
		surface.Face = Enum.NormalId.Front
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 64
		surface.Parent = sign

		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(120, 255, 255)
		label.TextStrokeTransparency = 0.15
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = surface

		return sign
	end

	local function makeVisibleFallbackGoblin(x, z)
		local model = Instance.new("Model")
		model.Name = "VisibleFallbackImportedGoblin"
		model.Parent = folder

		local body = makeDebugPart("FallbackBody", Vector3.new(4, 7, 2.8), CFrame.new(x, 6, z), "Lime green", 0)
		body.Material = Enum.Material.SmoothPlastic
		body.Parent = model

		local head = makeDebugPart("FallbackHead", Vector3.new(3.6, 3.2, 3.2), CFrame.new(x, 11.2, z - 0.2), "Bright green", 0)
		head.Shape = Enum.PartType.Ball
		head.Material = Enum.Material.SmoothPlastic
		head.Parent = model

		local leftEar = makeDebugPart("FallbackEarL", Vector3.new(0.7, 2.2, 4.8), CFrame.new(x - 2.8, 11.6, z - 0.3) * CFrame.Angles(0, math.rad(75), math.rad(-18)), "Lime green", 0)
		leftEar.Parent = model
		local rightEar = makeDebugPart("FallbackEarR", Vector3.new(0.7, 2.2, 4.8), CFrame.new(x + 2.8, 11.6, z - 0.3) * CFrame.Angles(0, math.rad(-75), math.rad(18)), "Lime green", 0)
		rightEar.Parent = model

		model.PrimaryPart = body
		return model
	end

	local usedImportSources = {}

	local function isIgnoredImportCandidate(object)
		if object == folder or object:IsDescendantOf(folder) then
			return true
		end
		local level43Folder = workspace:FindFirstChild("EmptyWorld43NPCs")
		if level43Folder and (object == level43Folder or object:IsDescendantOf(level43Folder)) then
			return true
		end
		return object == workspace.CurrentCamera or object == workspace.Terrain
	end

	local function getHighestModel(object)
		local model = object:IsA("Model") and object or object:FindFirstAncestorWhichIsA("Model")
		if not model then
			return nil
		end

		local highest = model
		local parent = model.Parent
		while parent and parent:IsA("Model") do
			highest = parent
			parent = parent.Parent
		end
		return highest
	end

	local function hasVisiblePart(model)
		return model and model:FindFirstChildWhichIsA("BasePart", true) ~= nil
	end

	local function findExactImport(importName)
		return workspace:FindFirstChild(importName, true)
			or ServerStorage:FindFirstChild(importName, true)
			or ReplicatedStorage:FindFirstChild(importName, true)
	end

	local function findImportedGoblinSource()
		local directCandidates = {
			workspace:FindFirstChild("Sketchfab_Scene"),
			ServerStorage:FindFirstChild("Sketchfab_Scene"),
			ReplicatedStorage:FindFirstChild("Sketchfab_Scene"),
			workspace:FindFirstChild("goblin1"),
			ServerStorage:FindFirstChild("goblin1"),
			ReplicatedStorage:FindFirstChild("goblin1"),
			workspace:FindFirstChild("Sketchfab_model", true),
			ServerStorage:FindFirstChild("Sketchfab_model", true),
			ReplicatedStorage:FindFirstChild("Sketchfab_model", true),
			workspace:FindFirstChild("sketchfab_scene", true),
			ServerStorage:FindFirstChild("sketchfab_scene", true),
			ReplicatedStorage:FindFirstChild("sketchfab_scene", true),
		}

		for _, candidate in ipairs(directCandidates) do
			local model = candidate and getHighestModel(candidate)
			if model and hasVisiblePart(model) and not isIgnoredImportCandidate(model) then
				return model
			end
		end

		return nil
	end

	local function findImport(importName, fallbackName, allowReuse)
		local explicitSource = findImportedGoblinSource()
		if explicitSource and (allowReuse or not usedImportSources[explicitSource]) then
			return explicitSource
		end

		local exact = findExactImport(importName) or (fallbackName and findExactImport(fallbackName))
		local exactModel = exact and getHighestModel(exact)
		if exactModel and hasVisiblePart(exactModel) and not isIgnoredImportCandidate(exactModel) and (allowReuse or not usedImportSources[exactModel]) then
			return exactModel
		end

		local keywords = { importName:lower(), "goblin", "sketchfab", "styx", "skm_" }
		if fallbackName then
			keywords[#keywords + 1] = fallbackName:lower()
		end
		local roots = { workspace, ReplicatedStorage, ServerStorage }
		local candidates = {}

		for _, root in ipairs(roots) do
			for _, object in ipairs(root:GetDescendants()) do
				if not isIgnoredImportCandidate(object) then
					local lowerName = object.Name:lower()
					local matched = false
					for _, keyword in ipairs(keywords) do
						if lowerName:find(keyword, 1, true) then
							matched = true
							break
						end
					end

					if matched then
						local model = getHighestModel(object)
						if model and hasVisiblePart(model) and (allowReuse or not usedImportSources[model]) then
							candidates[#candidates + 1] = model
						end
					end
				end
			end
		end

		table.sort(candidates, function(a, b)
			return getFullNameSafe(a) < getFullNameSafe(b)
		end)

		return candidates[1]
	end

	local function showImportScanner()
		local found = {}
		local roots = { workspace, ServerStorage, ReplicatedStorage }
		local keywords = { "sketchfab", "goblin", "styx", "skm_" }

		for _, root in ipairs(roots) do
			for _, object in ipairs(root:GetDescendants()) do
				if not isIgnoredImportCandidate(object) then
					local lowerName = object.Name:lower()
					for _, keyword in ipairs(keywords) do
						if lowerName:find(keyword, 1, true) then
							found[#found + 1] = getFullNameSafe(object)
							break
						end
					end
				end
				if #found >= 6 then
					break
				end
			end
			if #found >= 6 then
				break
			end
		end

		local scanner = makeDebugPart("ImportScannerStatus", Vector3.new(10, 20, 10), CFrame.new(-2860, 13, 8082), "Lime green", 0.72)
		local text = #found > 0 and table.concat(found, "\n") or "NO IMPORTS FOUND\nClick Import first"
		addLabel(scanner, "IMPORT SCAN\n" .. text)
	end

	local function placeImport(importName, x, z, labelText, fallbackName)
		local beacon = makeDebugPart("CENTER_BEACON_" .. importName, Vector3.new(6, 30, 6), CFrame.new(x, 16, z), "Toothpaste", 0.55)
		addStaticTextSign("StaticText_" .. importName, CFrame.new(x, 27, z - 9), labelText)

		local allowReuse = fallbackName ~= nil
		local source = findImport(importName, fallbackName, allowReuse)
		if not source then
			warn("[DebugTeleportService] Level 42 import test could not find:", importName)
			addStaticTextSign("MissingPathText_" .. importName, CFrame.new(x, 21, z - 9), "PATH NOT FOUND\nWorkspace.Sketchfab_Scene\nor ServerStorage.goblin1")
			makeVisibleFallbackGoblin(x, z)
			return nil
		end
		if not allowReuse then
			usedImportSources[source] = true
		end

		source.Archivable = true
		for _, object in ipairs(source:GetDescendants()) do
			object.Archivable = true
		end

		local clone = source:Clone()
		clone.Name = "Level42Imported_" .. importName
		clone.Parent = folder

		local model
		if clone:IsA("Model") then
			model = clone
		else
			model = Instance.new("Model")
			model.Name = "Level42Imported_" .. importName
			clone.Parent = model
			model.Parent = folder
		end

		local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if not root then
			warn("[DebugTeleportService] Level 42 import test found no BasePart inside:", getFullNameSafe(source))
			makeVisibleFallbackGoblin(x, z)
			return model
		end

		model.PrimaryPart = root

		local partCount = 0
		for _, object in ipairs(model:GetDescendants()) do
			if object:IsA("BasePart") then
				partCount += 1
				object.Anchored = true
				object.CanCollide = false
				object.CanTouch = true
				object.CastShadow = true
				object.Transparency = 0
				object.LocalTransparencyModifier = 0
				object.Material = Enum.Material.SmoothPlastic
				object.Color = Color3.fromRGB(115, 255, 45)
				if object:IsA("MeshPart") then
					object.DoubleSided = true
					object.RenderFidelity = Enum.RenderFidelity.Precise
				end
			end
		end

		local highlight = Instance.new("Highlight")
		highlight.Name = "ImportedGoblinVisibilityHighlight"
		highlight.FillColor = Color3.fromRGB(80, 255, 40)
		highlight.FillTransparency = 0.35
		highlight.OutlineColor = Color3.fromRGB(255, 245, 120)
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = model

		local _, sizeBefore = model:GetBoundingBox()
		if sizeBefore.Y > 0 then
			local scaleFactor = math.clamp(12 / sizeBefore.Y, 0.01, 30)
			pcall(function()
				model:ScaleTo(scaleFactor)
			end)
		end

		local boxCf, sizeAfter = model:GetBoundingBox()
		local displayHalfHeight = math.clamp(sizeAfter.Y * 0.5, 3, 10)
		local targetCenter = Vector3.new(x, 2 + displayHalfHeight, z)
		local pivotOffsetFromBox = boxCf:ToObjectSpace(model:GetPivot())
		model:PivotTo(CFrame.new(targetCenter) * CFrame.Angles(0, math.rad(180), 0) * pivotOffsetFromBox)

		makeDebugPart("Level42Bounds_" .. importName, sizeAfter + Vector3.new(2, 2, 2), CFrame.new(targetCenter), "Cyan", 0.9)
		makeDebugPart("Level42Marker_" .. importName, Vector3.new(14, 0.5, 14), CFrame.new(x, 1.8, z), "Toothpaste", 0.05)

		local humanoid = model:FindFirstChildWhichIsA("Humanoid") or Instance.new("Humanoid")
		humanoid.DisplayName = labelText
		humanoid.MaxHealth = 42
		humanoid.Health = 42
		humanoid.Parent = model

		print("[DebugTeleportService] Level 42 placed imported goblin clone:", getFullNameSafe(source), "parts:", partCount, "size:", sizeAfter)
		return model
	end

	placeImport("Sketchfab_Scene", -2860, 8100, "IMPORTED GOBLIN")
	print("[DebugTeleportService] Spawned level 42 imported goblin debug test.")
end

remote.OnServerEvent:Connect(function(player, levelOrder)
	local n  = type(levelOrder) == "number" and math.floor(levelOrder) or nil
	local cf = (n and SPAWN_POSITIONS[n]) or STARTER_CF

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = cf + Vector3.new(0, 3, 0)
	end

	if n == 43 then
		task.spawn(function()
			local ok, err = pcall(ensureLevel43DebugNpcs)
			if not ok then
				warn("[DebugTeleportService] Level 43 NPC spawn failed, teleport still completed:", err)
			end
		end)
	end
end)

print("[DebugTeleportService] Ready.")
