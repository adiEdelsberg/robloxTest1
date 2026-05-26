-- WorldOrderConfig
-- Edit this file to change the visible/code order of the main game levels.
-- Keep `order` unique. HUD labels, time machines, and server scripts
-- can read these values so the in-game number matches the code number.

local WorldOrderConfig = {}

WorldOrderConfig.Worlds = {
	-- order = the level number shown in UI and used for checkpoint progression.
	-- name = the canonical world name used by gameplay scripts.
	-- aliases = alternate sign/old names that should show the same number.
	{ order = 1,  name = "Playground",          aliases = {} },
	{ order = 2,  name = "Pizza",              aliases = { "Pizza Place" } },
	{ order = 3,  name = "Galactic",           aliases = { "Galactic Zone" } },
	{ order = 4,  name = "Jungle",             aliases = { "Jungle Zone" } },
	{ order = 5,  name = "Sports",             aliases = { "Sports World" } },
	{ order = 6, name = "Tennis",             aliases = { "Tennis Court" } },
	{ order = 7, name = "Game Station",       aliases = { "GameStation" } },
	{ order = 8, name = "Coffee Shop",        aliases = { "CoffeeShop" } },
	{ order = 9, name = "Burger House",       aliases = { "BurgerHouse" } },
	{ order = 10, name = "New Pizza Place",    aliases = { "New Pizza", "NewPizza" } },
	{ order = 11, name = "Swimming Pool",      aliases = { "SwimmingPool" } },
	{ order = 12, name = "Dinosaur Park",      aliases = { "DinosaurPark" } },
	{ order = 13, name = "Dino Beach",         aliases = { "DinoBeach" } },
	{ order = 14, name = "Flying Dino Forest", aliases = { "FlyingDinoForest" } },
	{ order = 15, name = "Cherry Grove",       aliases = { "CherryGrove" } },
	{ order = 16, name = "Galactic Orchard",   aliases = { "GalacticOrchard" } },
	{ order = 17,  name = "Empty World 1",       aliases = { "Empty World", "Dino Ball Sky", "Dino Ball World" } },
	{ order = 18,  name = "Storm Dome",           aliases = { "Empty World 2", "EmptyWorld2", "StormDome" } },
	{ order = 19,  name = "Volt Abyss",           aliases = { "Empty World 3", "EmptyWorld3", "VoltAbyss" } },
	{ order = 20,  name = "Neon Rift",            aliases = { "Empty World 4", "EmptyWorld4", "NeonRift" } },
	{ order = 21,  name = "Sky Vault",            aliases = { "SkyVault" } },
	{ order = 22,  name = "Storm Tower",          aliases = { "StormTower" } },
	{ order = 23,  name = "Frost Basin",          aliases = { "FrostBasin" } },
	{ order = 24,  name = "Ember Hold",           aliases = { "EmberHold" } },
	{ order = 25,  name = "Nova Spire",           aliases = { "NovaSpire"    } },
	{ order = 26,  name = "Prism Peak",           aliases = { "PrismPeak"    } },
	{ order = 27,  name = "Magma Core",           aliases = { "MagmaCore"    } },
	{ order = 28,  name = "Storm Circuit",        aliases = { "StormCircuit" } },
	{ order = 29,  name = "Shadow Vault",         aliases = { "ShadowVault"  } },
	{ order = 30,  name = "Apex Nexus",           aliases = { "ApexNexus"    } },
	{ order = 31,  name = "Cloud Drift",          aliases = { "CloudDrift"   } },
	{ order = 32,  name = "Coral Reef",           aliases = { "CoralReef"    } },
	{ order = 33,  name = "Bubble Bounce",        aliases = { "BubbleBounce" } },
	{ order = 34,  name = "Zen Garden",           aliases = { "ZenGarden"      } },
	{ order = 35,  name = "Crystal Spires",       aliases = { "CrystalSpires"  } },
	{ order = 36,  name = "Neon Triangle",        aliases = { "NeonTriangle"   } },
	{ order = 37,  name = "Wide Canyon",          aliases = { "WideCanyon"     } },
	{ order = 38,  name = "Narrow Pass",          aliases = { "NarrowPass"     } },
	{ order = 39,  name = "Diamond Gate",         aliases = { "DiamondGate"    } },
	{ order = 40,  name = "Hourglass Vault",      aliases = { "HourglassVault" } },
	{ order = 41,  name = "Movement Lab",         aliases = { "MovementLab"    } },
	{ order = 42,  name = "Fight Arena",          aliases = { "FightArena"     } },
	{ order = 43,  name = "Empty World 43",       aliases = { "EmptyWorld43"   } },
	{ order = 44,  name = "Empty World 44",       aliases = { "EmptyWorld44"   } },
	{ order = 45,  name = "Empty World 45",       aliases = { "EmptyWorld45"   } },
	{ order = 46,  name = "Empty World 46",       aliases = { "EmptyWorld46"   } },
	{ order = 47,  name = "Empty World 47",       aliases = { "EmptyWorld47"   } },
	{ order = 48,  name = "Empty World 48",       aliases = { "EmptyWorld48"   } },
	{ order = 49,  name = "Empty World 49",       aliases = { "EmptyWorld49"   } },
	{ order = 50,  name = "Empty World 50",       aliases = { "EmptyWorld50"   } },
}

-- Respawn/teleport landing points by level number.
-- Edit these CFrames when you want to move where a level places the player.
-- The starter respawn is the hub/spin-wheel area used when last-world respawn is off.
WorldOrderConfig.StarterRespawnCFrame = CFrame.new(43, 88, -735) * CFrame.Angles(0, math.rad(90), 0)

-- Set this to a level number to make player respawns go to that level.
-- Example: WorldOrderConfig.PlayerRespawnLevelOrder = 48
-- Keep nil to use the normal starter/spin-wheel respawn behavior.
WorldOrderConfig.PlayerRespawnLevelOrder = nil

WorldOrderConfig.LevelRespawns = {
	[1]  = CFrame.new(0, 7, 0),
	[2]  = CFrame.new(0, 7, 142),
	[3]  = CFrame.new(0, 8, 398),
	[4]  = CFrame.new(0, 8, 652),
	[5]  = CFrame.new(0, 8, 872),
	[6]  = CFrame.new(0, 8, 1102),
	[7]  = CFrame.new(0, 8, 1312),
	[8]  = CFrame.new(0, 8, 1558),
	[9]  = CFrame.new(224, 8, 1700),
	[10] = CFrame.new(590, 8, 1700),
	[11] = CFrame.new(918, 8, 1700),
	[12] = CFrame.new(1270, 8, 1700),
	[13] = CFrame.new(1622, 8, 1700),
	[14] = CFrame.new(1974, 8, 1700),
	[15] = CFrame.new(2326, 8, 1700),
	[16] = CFrame.new(2678, 8, 1700),
	[17] = CFrame.new(-550, 8, 1700),
	[18] = CFrame.new(-1320, 8, 1700),
	[19] = CFrame.new(-2090, 8, 1580),
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
	[47] = CFrame.new(-2860, 8, 11250),
	[48] = CFrame.new(-2860, 8, 11700),
	[49] = CFrame.new(-2860, 8, 13000),
	[50] = CFrame.new(-2860, 8, 14300),
}

local byName = {}
local byOrder = {}

local function register(name, world)
	byName[string.lower(name)] = world
end

for _, world in WorldOrderConfig.Worlds do
	byOrder[world.order] = world
	register(world.name, world)
	for _, alias in world.aliases or {} do
		register(alias, world)
	end
end

function WorldOrderConfig.getWorld(name)
	if type(name) ~= "string" then return nil end
	return byName[string.lower(name)]
end

function WorldOrderConfig.getOrder(name)
	local world = WorldOrderConfig.getWorld(name)
	return world and world.order or nil
end

function WorldOrderConfig.getName(order)
	local world = byOrder[order]
	return world and world.name or nil
end

function WorldOrderConfig.getRespawnCFrame(orderOrName, fallback)
	local order = tonumber(orderOrName)
	if not order and type(orderOrName) == "string" then
		order = WorldOrderConfig.getOrder(orderOrName)
	end
	return (order and WorldOrderConfig.LevelRespawns[order]) or fallback
end

function WorldOrderConfig.getStarterRespawnCFrame()
	return WorldOrderConfig.StarterRespawnCFrame
end

function WorldOrderConfig.getConfiguredPlayerRespawnCFrame()
	if WorldOrderConfig.PlayerRespawnLevelOrder then
		return WorldOrderConfig.getRespawnCFrame(WorldOrderConfig.PlayerRespawnLevelOrder)
	end
	return nil
end

function WorldOrderConfig.formatName(name)
	local world = WorldOrderConfig.getWorld(name)
	if not world then return name end
	return string.format("%02d  %s", world.order, name)
end

function WorldOrderConfig.formatCanonical(name)
	local world = WorldOrderConfig.getWorld(name)
	if not world then return name end
	return string.format("%02d  %s", world.order, world.name)
end

return WorldOrderConfig
