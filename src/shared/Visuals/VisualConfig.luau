-- VisualConfig
-- Central tuning for the premium visual layer. Require this module from client
-- or server visual scripts so lighting, camera, particles, and world VFX share
-- the same style values.

local VisualConfig = {}

VisualConfig.Performance = {
	MobileParticleScale = 0.45,
	DesktopParticleScale = 1,
	MaxImpactParticles = 36,
	MaxAmbientParticles = 80,
	ReduceVFXDistance = 180,
}

VisualConfig.Lighting = {
	ClockTime = 17.65,
	Brightness = 3.2,
	ExposureCompensation = 0.1,
	Ambient = Color3.fromRGB(52, 60, 88),
	OutdoorAmbient = Color3.fromRGB(115, 125, 165),
	EnvironmentDiffuseScale = 0.72,
	EnvironmentSpecularScale = 1,
	Atmosphere = {
		Density = 0.28,
		Offset = 0.08,
		Color = Color3.fromRGB(170, 205, 255),
		Decay = Color3.fromRGB(75, 45, 120),
		Glare = 0.18,
		Haze = 1.05,
	},
}

VisualConfig.Post = {
	Bloom = {
		Intensity = 0.42,
		Size = 34,
		Threshold = 1.15,
	},
	ColorCorrection = {
		Brightness = 0.02,
		Contrast = 0.16,
		Saturation = 0.12,
		TintColor = Color3.fromRGB(238, 246, 255),
	},
	DepthOfField = {
		FarIntensity = 0.24,
		FocusDistance = 80,
		InFocusRadius = 42,
		NearIntensity = 0.06,
	},
	SunRays = {
		Intensity = 0.07,
		Spread = 0.78,
	},
}

VisualConfig.Camera = {
	BaseFOV = 70,
	DashFOV = 78,
	HitShake = { Magnitude = 0.42, Duration = 0.16, Frequency = 28 },
	HeavyHitShake = { Magnitude = 0.9, Duration = 0.28, Frequency = 34 },
}

VisualConfig.VFX = {
	NeonGreen = Color3.fromRGB(120, 255, 60),
	NeonRed = Color3.fromRGB(255, 35, 70),
	NeonCyan = Color3.fromRGB(70, 225, 255),
	NeonViolet = Color3.fromRGB(170, 80, 255),
	ImpactLifetime = 0.42,
	DashLifetime = 0.28,
	ShockwaveLifetime = 0.34,
}

VisualConfig.World43NPC = {
	SmallScale = 1,
	BossScale = 2.4,
	Skin = Color3.fromRGB(93, 255, 29),
	SkinDark = Color3.fromRGB(32, 145, 42),
	Cloth = Color3.fromRGB(88, 45, 28),
	ClothAlt = Color3.fromRGB(125, 61, 30),
	Eye = Color3.fromRGB(255, 20, 62),
	Tooth = Color3.fromRGB(242, 246, 235),
}

return VisualConfig
