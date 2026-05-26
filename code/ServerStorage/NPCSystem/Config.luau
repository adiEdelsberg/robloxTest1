--[[
    NPCSystem / Config
    Central configuration for all NPC definitions, rarity settings,
    animation IDs, and system tuning values.
    Edit this file to add new NPC types or tweak performance settings.
--]]

local Config = {}

-- ============================================================
-- SYSTEM SETTINGS
-- ============================================================
Config.Settings = {
    LOD_NEAR   = 60,    -- studs: full quality
    LOD_MID    = 120,   -- studs: reduce particles, stop idle anims
    LOD_FAR    = 220,   -- studs: freeze entirely
    LOD_UPDATE_RATE = 2.0,   -- seconds between LOD checks
    BEHAVIOR_UPDATE_RATE = 0.1, -- seconds per behavior tick (10 Hz)
    LOOK_AT_RANGE  = 18,    -- studs: NPC turns toward player within this range
    WANDER_RADIUS  = 14,    -- max studs from spawn point per wander
    BILLBOARD_FADE_NEAR = 8,
    BILLBOARD_FADE_FAR  = 55,
}

-- ============================================================
-- ANIMATION IDS  (replace with your custom animation IDs)
-- ============================================================
Config.Animations = {
    -- Core locomotion (standard Roblox R6 defaults)
    Idle  = "rbxassetid://507766388",
    Walk  = "rbxassetid://507777826",
    Run   = "rbxassetid://507767714",

    -- Idle sub-animations (random variety)
    IdleActions = {
        Wave    = "rbxassetid://507770239",
        Point   = "rbxassetid://507770453",
        Cheer   = "rbxassetid://507770677",
        Laugh   = "rbxassetid://507770818",
        Dance   = "rbxassetid://507771019",
        Salute  = "rbxassetid://507770239",  -- reuse wave as placeholder
    },
}

-- ============================================================
-- RARITY DEFINITIONS
-- Colours, effects and particle densities per tier.
-- ============================================================
Config.Rarities = {
    Common = {
        label       = "Common",
        labelColor  = Color3.fromRGB(200, 200, 200),
        outlineColor = nil,          -- no outline
        outlineThick = 0,
        lightColor  = nil,
        lightRange  = 0,
        lightBrightness = 0,
        particles   = false,
        auraColor   = nil,
        auraRate    = 0,
        badgeColor  = Color3.fromRGB(80, 80, 90),
    },
    Rare = {
        label       = "Rare",
        labelColor  = Color3.fromRGB(100, 180, 255),
        outlineColor = Color3.fromRGB(80, 160, 255),
        outlineThick = 0.04,
        lightColor  = Color3.fromRGB(80, 160, 255),
        lightRange  = 12,
        lightBrightness = 0.6,
        particles   = true,
        auraColor   = Color3.fromRGB(80, 160, 255),
        auraRate    = 12,
        badgeColor  = Color3.fromRGB(30, 90, 200),
    },
    Epic = {
        label       = "Epic",
        labelColor  = Color3.fromRGB(200, 100, 255),
        outlineColor = Color3.fromRGB(180, 80, 255),
        outlineThick = 0.055,
        lightColor  = Color3.fromRGB(180, 80, 255),
        lightRange  = 18,
        lightBrightness = 1.0,
        particles   = true,
        auraColor   = Color3.fromRGB(200, 80, 255),
        auraRate    = 28,
        badgeColor  = Color3.fromRGB(110, 20, 180),
    },
    Legendary = {
        label       = "Legendary",
        labelColor  = Color3.fromRGB(255, 210, 40),
        outlineColor = Color3.fromRGB(255, 200, 0),
        outlineThick = 0.07,
        lightColor  = Color3.fromRGB(255, 200, 0),
        lightRange  = 28,
        lightBrightness = 1.8,
        particles   = true,
        auraColor   = Color3.fromRGB(255, 200, 0),
        auraRate    = 55,
        halo        = true,   -- glowing ring above head
        badgeColor  = Color3.fromRGB(160, 110, 0),
    },
    Mythic = {
        label       = "Mythic",
        labelColor  = Color3.fromRGB(255, 80, 140),
        outlineColor = Color3.fromRGB(255, 60, 120),
        outlineThick = 0.09,
        lightColor  = Color3.fromRGB(255, 80, 140),
        lightRange  = 40,
        lightBrightness = 2.8,
        particles   = true,
        auraColor   = Color3.fromRGB(255, 60, 120),
        auraRate    = 90,
        halo        = true,
        wings       = true,   -- neon wing constructs
        rainbow     = true,   -- hue-shifts the outline over time
        badgeColor  = Color3.fromRGB(140, 0, 60),
    },
}

-- ============================================================
-- NPC DEFINITIONS
-- Each entry is a blueprint for one NPC type.
-- ============================================================
Config.NPCs = {

    -- ---- COMMON ----
    SkaterKid = {
        id          = "SkaterKid",
        displayName = "Skater Kid",
        rarity      = "Common",
        skinColor   = Color3.fromRGB(255, 210, 160),
        shirtColor  = Color3.fromRGB(220, 60,  40),   -- bright red hoodie
        pantsColor  = Color3.fromRGB(30,  30,  30),   -- black jeans
        hairColor   = Color3.fromRGB(255, 200, 50),   -- bleached yellow
        hairStyle   = "Spiky",
        eyeColor    = Color3.fromRGB(60,  200, 100),
        wander      = true,
        lookAtPlayers = true,
        maxHp       = 100,
        subtitle    = "Shredding daily",
        weight      = 55,
    },

    BounceKid = {
        id          = "BounceKid",
        displayName = "Bounce Kid",
        rarity      = "Common",
        skinColor   = Color3.fromRGB(210, 170, 130),
        shirtColor  = Color3.fromRGB(50,  180, 255),  -- cyan tee
        pantsColor  = Color3.fromRGB(220, 100, 20),   -- orange shorts
        hairColor   = Color3.fromRGB(80,  40,  10),
        hairStyle   = "Short",
        eyeColor    = Color3.fromRGB(200, 120, 30),
        wander      = true,
        lookAtPlayers = true,
        maxHp       = 100,
        subtitle    = "Loves the mushrooms!",
        weight      = 45,
    },

    -- ---- RARE ----
    PizzaChef = {
        id          = "PizzaChef",
        displayName = "Chef Pepperoni",
        rarity      = "Rare",
        skinColor   = Color3.fromRGB(245, 205, 165),
        shirtColor  = Color3.fromRGB(255, 255, 255),  -- white chef coat
        pantsColor  = Color3.fromRGB(30,  30,  30),   -- black trousers
        hairColor   = Color3.fromRGB(20,  15,  10),
        hairStyle   = "Bald",
        eyeColor    = Color3.fromRGB(80,  50,  20),
        wander      = false,
        lookAtPlayers = true,
        maxHp       = 250,
        subtitle    = "Best pizza in town!",
        weight      = 20,
    },

    Lifeguard = {
        id          = "Lifeguard",
        displayName = "Lifeguard Lou",
        rarity      = "Rare",
        skinColor   = Color3.fromRGB(220, 160, 100),  -- tanned
        shirtColor  = Color3.fromRGB(255, 50,  50),   -- red swimwear
        pantsColor  = Color3.fromRGB(255, 80,  30),   -- orange shorts
        hairColor   = Color3.fromRGB(255, 220, 100),  -- sun-bleached
        hairStyle   = "Short",
        eyeColor    = Color3.fromRGB(50,  180, 220),
        wander      = true,
        lookAtPlayers = true,
        maxHp       = 300,
        subtitle    = "On duty 24/7",
        weight      = 20,
    },

    -- ---- EPIC ----
    NeonRacer = {
        id          = "NeonRacer",
        displayName = "Neon Racer",
        rarity      = "Epic",
        skinColor   = Color3.fromRGB(40,  40,  60),   -- dark blue-grey
        shirtColor  = Color3.fromRGB(0,   220, 255),  -- electric cyan jacket
        pantsColor  = Color3.fromRGB(20,  20,  40),   -- near-black
        hairColor   = Color3.fromRGB(0,   240, 255),  -- cyan
        hairStyle   = "Spiky",
        eyeColor    = Color3.fromRGB(0,   255, 200),
        wander      = true,
        lookAtPlayers = true,
        maxHp       = 600,
        subtitle    = "Speed is everything",
        weight      = 8,
    },

    VolcanoChef = {
        id          = "VolcanoChef",
        displayName = "Volcano Chef",
        rarity      = "Epic",
        skinColor   = Color3.fromRGB(80,  40,  20),
        shirtColor  = Color3.fromRGB(255, 80,  0),    -- blazing orange coat
        pantsColor  = Color3.fromRGB(40,  20,  10),
        hairColor   = Color3.fromRGB(255, 60,  0),    -- fire red
        hairStyle   = "Spiky",
        eyeColor    = Color3.fromRGB(255, 140, 0),
        wander      = true,
        lookAtPlayers = true,
        maxHp       = 700,
        subtitle    = "Cooking with FIRE",
        weight      = 7,
    },

    -- ---- LEGENDARY ----
    DinoRider = {
        id          = "DinoRider",
        displayName = "Dino Rider Rex",
        rarity      = "Legendary",
        skinColor   = Color3.fromRGB(60,  160, 60),   -- green explorer
        shirtColor  = Color3.fromRGB(50,  120, 40),   -- jungle green
        pantsColor  = Color3.fromRGB(100, 70,  20),   -- khaki
        hairColor   = Color3.fromRGB(255, 200, 0),    -- gold
        hairStyle   = "Long",
        eyeColor    = Color3.fromRGB(255, 200, 0),
        wander      = true,
        lookAtPlayers = true,
        maxHp       = 2000,
        subtitle    = "Tamed every dino!",
        weight      = 3,
    },

    -- ---- MYTHIC ----
    CrystalSeraph = {
        id          = "CrystalSeraph",
        displayName = "Crystal Seraph",
        rarity      = "Mythic",
        skinColor   = Color3.fromRGB(200, 230, 255),
        shirtColor  = Color3.fromRGB(120, 200, 255),
        pantsColor  = Color3.fromRGB(80,  140, 220),
        hairColor   = Color3.fromRGB(255, 255, 255),
        hairStyle   = "Long",
        eyeColor    = Color3.fromRGB(150, 230, 255),
        wander      = true,
        lookAtPlayers = true,
        maxHp       = 5000,
        subtitle    = "Born of Starlight",
        weight      = 1,
    },
}

return Config
