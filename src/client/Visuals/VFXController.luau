-- VFXController
-- Client-side reusable VFX. Prefer calling these from client events so the
-- server does not replicate short-lived particles/trails to every player.
-- Usage:
-- VFXController.Impact(position, color)
-- VFXController.Shockwave(CFrame.new(position), radius, color)
-- VFXController.Dash(character)

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local VisualConfig = require(ReplicatedStorage:WaitForChild("Visuals"):WaitForChild("VisualConfig"))
local CameraEffects = require(script.Parent:WaitForChild("CameraEffects"))

local VFXController = {}
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local particleScale = isMobile and VisualConfig.Performance.MobileParticleScale or VisualConfig.Performance.DesktopParticleScale

local function neonPart(name, size, cf, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = workspace
	return part
end

function VFXController.Impact(position, color)
	color = color or VisualConfig.VFX.NeonGreen
	local core = neonPart("PremiumImpactCore", Vector3.new(0.45, 0.45, 0.45), CFrame.new(position), color, 0.1)
	core.Shape = Enum.PartType.Ball

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ImpactSparks"
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 0.8
	emitter.Lifetime = NumberRange.new(0.18, 0.34)
	emitter.Speed = NumberRange.new(18, 34)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = core
	emitter:Emit(math.floor(VisualConfig.Performance.MaxImpactParticles * particleScale))

	TweenService:Create(core, TweenInfo.new(VisualConfig.VFX.ImpactLifetime), { Transparency = 1, Size = Vector3.new(2.4, 2.4, 2.4) }):Play()
	Debris:AddItem(core, VisualConfig.VFX.ImpactLifetime + 0.1)
	CameraEffects.Shake("Hit")
end

function VFXController.Shockwave(cf, radius, color)
	color = color or VisualConfig.VFX.NeonCyan
	local ring = neonPart("PremiumShockwave", Vector3.new(1, 0.08, 1), cf * CFrame.Angles(math.rad(90), 0, 0), color, 0.2)
	ring.Shape = Enum.PartType.Cylinder
	TweenService:Create(ring, TweenInfo.new(VisualConfig.VFX.ShockwaveLifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.08, radius or 18, radius or 18),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, VisualConfig.VFX.ShockwaveLifetime + 0.05)
end

function VFXController.Dash(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.4, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1.4, 0)
	a1.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "PremiumDashTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(VisualConfig.VFX.NeonCyan, VisualConfig.VFX.NeonViolet)
	trail.LightEmission = 0.8
	trail.Lifetime = VisualConfig.VFX.DashLifetime
	trail.MinLength = 0.1
	trail.Parent = root

	CameraEffects.FOVBoost(VisualConfig.Camera.DashFOV, 0.1)
	Debris:AddItem(trail, VisualConfig.VFX.DashLifetime + 0.1)
	Debris:AddItem(a0, VisualConfig.VFX.DashLifetime + 0.1)
	Debris:AddItem(a1, VisualConfig.VFX.DashLifetime + 0.1)
end

return VFXController
