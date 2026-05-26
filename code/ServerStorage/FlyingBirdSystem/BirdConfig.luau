-- Place in ServerStorage/FlyingBirdSystem/BirdConfig.luau
-- Add new bird types by appending to Config.Birds. Asset ids can be swapped for real MeshParts,
-- SurfaceAppearance textures, and animation ids from your own Roblox assets.

local Config = {}

Config.Network = {
	folderName = "FlyingBirdSystem",
	snapshotEventName = "BirdSnapshot",
	powerModeAttribute = "HighGraphicsBirds",
}

Config.Server = {
	maxBirds = 34,
	spawnTick = 3.5,
	snapshotRate = 0.12,
	defaultZoneRadius = 140,
	minAltitude = 28,
	maxAltitude = 90,
	avoidanceDistance = 28,
	landingChance = 0.08,
}

Config.Client = {
	fullLodDistance = 140,
	mediumLodDistance = 260,
	cullDistance = 520,
	maxFullLodBirdsMobile = 10,
	maxFullLodBirdsDesktop = 18,
}

Config.Behaviors = {
	Glide = { weight = 34, speedScale = 0.8, turnStrength = 0.55, vertical = 0.1 },
	Circle = { weight = 24, speedScale = 0.65, turnStrength = 1.2, vertical = 0.15 },
	Dive = { weight = 15, speedScale = 1.35, turnStrength = 0.75, vertical = -0.75 },
	Land = { weight = 10, speedScale = 0.55, turnStrength = 1.0, vertical = -0.35 },
	Flock = { weight = 17, speedScale = 0.95, turnStrength = 0.8, vertical = 0.05 },
}

Config.Birds = {
	{
		id = "small_bird",
		displayName = "Small Bird",
		rarity = "Common",
		spawnWeight = 55,
		scale = 0.75,
		cruiseSpeed = 34,
		flapRate = 7.5,
		meshId = "",
		textureId = "",
		surfaceAppearance = nil,
		wingAnimationId = "rbxassetid://0",
		bodyColor = Color3.fromRGB(145, 170, 210),
		wingColor = Color3.fromRGB(105, 125, 170),
		trail = nil,
		glow = nil,
	},
	{
		id = "eagle",
		displayName = "Eagle",
		rarity = "Rare",
		spawnWeight = 24,
		scale = 1.35,
		cruiseSpeed = 42,
		flapRate = 5.2,
		meshId = "",
		textureId = "",
		surfaceAppearance = nil,
		wingAnimationId = "rbxassetid://0",
		bodyColor = Color3.fromRGB(125, 82, 45),
		wingColor = Color3.fromRGB(95, 60, 34),
		trail = { color = Color3.fromRGB(255, 230, 150), transparency = 0.65 },
		glow = nil,
	},
	{
		id = "raven",
		displayName = "Raven",
		rarity = "Epic",
		spawnWeight = 13,
		scale = 1.05,
		cruiseSpeed = 39,
		flapRate = 6.4,
		meshId = "",
		textureId = "",
		surfaceAppearance = nil,
		wingAnimationId = "rbxassetid://0",
		bodyColor = Color3.fromRGB(18, 18, 24),
		wingColor = Color3.fromRGB(35, 35, 48),
		trail = { color = Color3.fromRGB(120, 90, 255), transparency = 0.58 },
		glow = { color = Color3.fromRGB(120, 90, 255), range = 8, brightness = 0.8 },
	},
	{
		id = "tropical_bird",
		displayName = "Tropical Bird",
		rarity = "Legendary",
		spawnWeight = 6,
		scale = 0.95,
		cruiseSpeed = 46,
		flapRate = 8.5,
		meshId = "",
		textureId = "",
		surfaceAppearance = nil,
		wingAnimationId = "rbxassetid://0",
		bodyColor = Color3.fromRGB(255, 85, 120),
		wingColor = Color3.fromRGB(50, 220, 255),
		trail = { color = Color3.fromRGB(255, 230, 70), transparency = 0.4 },
		glow = { color = Color3.fromRGB(60, 240, 255), range = 10, brightness = 1.1 },
	},
	{
		id = "mythical_glowing_bird",
		displayName = "Mythical Glowing Bird",
		rarity = "Mythic",
		spawnWeight = 2,
		scale = 1.6,
		cruiseSpeed = 52,
		flapRate = 4.8,
		meshId = "",
		textureId = "",
		surfaceAppearance = nil,
		wingAnimationId = "rbxassetid://0",
		bodyColor = Color3.fromRGB(80, 255, 210),
		wingColor = Color3.fromRGB(255, 90, 240),
		trail = { color = Color3.fromRGB(80, 255, 210), transparency = 0.22 },
		glow = { color = Color3.fromRGB(80, 255, 210), range = 18, brightness = 2.2 },
	},
}

return Config
