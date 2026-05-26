--[[
    NPCSystemMain  (ServerScriptService)
    Entry point for the high-graphics NPC system.

    ── What this script does ──────────────────────────────────────────────────
    1. Requires NPCService from ServerStorage/NPCSystem
    2. Starts the LOD loop
    3. Spawns a showcase group of example NPCs across the world
    4. Provides a SpawnManager that periodically replenishes despawned NPCs

    ── How to add your own NPCs ──────────────────────────────────────────────
    • Add a new entry to ServerStorage/NPCSystem/Config → Config.NPCs
    • Call NPCService.spawnNPC("YourNPCId", CFrame.new(x, y, z))  anywhere
    • Or add entries to SPAWN_GROUPS below

    ── Template models ────────────────────────────────────────────────────────
    For best visual quality, place pre-built R6 models in
    ServerStorage/NPCSystem/Templates/<npcDef.id>
    The service will clone them instead of building from parts.
--]]

local ServerStorage = game:GetService("ServerStorage")
local NPCSystem     = ServerStorage:WaitForChild("NPCSystem")
local NPCService    = require(NPCSystem:WaitForChild("NPCService"))

local ENABLE_NON_SCORING_NPCS = false
if not ENABLE_NON_SCORING_NPCS then
    print("[NPCSystem] Disabled non-scoring ambient/showcase NPCs.")
    return
end

-- ── Spawn groups: edit positions to match your map ───────────────────────────
-- Each entry: { id = Config.NPCs key, cframe = spawn CFrame }
local SPAWN_GROUPS = {
    -- Playground area skaters & bouncers
    { id = "SkaterKid",   cframe = CFrame.new( 12, 1, 22) },
    { id = "SkaterKid",   cframe = CFrame.new(-18, 1, 38) },
    { id = "BounceKid",   cframe = CFrame.new( 28, 1, 14) },
    { id = "BounceKid",   cframe = CFrame.new( -8, 1, 50) },

    -- Pizza zone: Chef Pepperoni stationed at entrance
    { id = "PizzaChef",   cframe = CFrame.new( -5, 1, 145) * CFrame.Angles(0, math.rad(180), 0) },
    { id = "VolcanoChef", cframe = CFrame.new( 20, 1, 220) },

    -- Sports / bridge area: Neon Racer patrols
    { id = "NeonRacer",   cframe = CFrame.new(  0, 1, 420) },
    { id = "NeonRacer",   cframe = CFrame.new(-25, 1, 440) },

    -- Dino / beach area: Dino Rider + Lifeguard
    { id = "DinoRider",   cframe = CFrame.new(  5, 1, 710) },
    { id = "Lifeguard",   cframe = CFrame.new( 30, 1, 680) },
    { id = "Lifeguard",   cframe = CFrame.new(-30, 1, 720) },

    -- Mythic seraph — one per world, deep in the final zone
    { id = "CrystalSeraph", cframe = CFrame.new( 0, 1, 950) },
}

-- ── Random ambient spawn zones ────────────────────────────────────────────────
-- Periodically spawn random NPCs within defined rectangular areas.
-- Format: { minX, maxX, minZ, maxZ, groundY, maxCount, intervalSeconds }
local AMBIENT_ZONES = {
    { minX=-50, maxX=50, minZ=-10, maxZ=80,  y=1, max=3, interval=60  },  -- playground
    { minX=-60, maxX=60, minZ=140, maxZ=265, y=1, max=2, interval=90  },  -- pizza zone
}

-- ── Registry for ambient NPCs ─────────────────────────────────────────────────
local ambientIds = {}   -- [zone index] = { registryId, ... }

local function spawnAmbient(zone, zoneIdx)
    ambientIds[zoneIdx] = ambientIds[zoneIdx] or {}
    local existing = ambientIds[zoneIdx]

    -- Remove dead entries
    for i = #existing, 1, -1 do
        local entry = NPCService.getEntry(existing[i])
        if not entry or not entry.model or not entry.model.Parent then
            table.remove(existing, i)
        end
    end

    -- Spawn up to max
    local toSpawn = zone.max - #existing
    for _ = 1, toSpawn do
        local x = zone.minX + math.random() * (zone.maxX - zone.minX)
        local z = zone.minZ + math.random() * (zone.maxZ - zone.minZ)
        local id = NPCService.spawnRandom(CFrame.new(x, zone.y, z))
        if id then table.insert(existing, id) end
    end
end

-- ── Initialise ────────────────────────────────────────────────────────────────
-- Short startup delay so the world fully loads before NPCs are placed.
task.wait(2)

-- Start LOD system
NPCService.startLOD()

-- Spawn fixed group
local groupIds = NPCService.spawnGroup(SPAWN_GROUPS)
print(string.format("[NPCSystem] Spawned %d fixed NPCs.", #groupIds))

-- Spawn initial ambient NPCs
for zoneIdx, zone in AMBIENT_ZONES do
    spawnAmbient(zone, zoneIdx)
end

-- ── Ambient replenishment loop ────────────────────────────────────────────────
-- Checks each zone on its own interval and tops up dead NPCs.
task.spawn(function()
    local timers = {}
    for i, zone in AMBIENT_ZONES do
        timers[i] = zone.interval  -- start immediately on first tick
    end

    while true do
        task.wait(5)   -- check every 5 seconds
        for i, zone in AMBIENT_ZONES do
            timers[i] = (timers[i] or 0) - 5
            if timers[i] <= 0 then
                timers[i] = zone.interval
                spawnAmbient(zone, i)
            end
        end
    end
end)

-- ── Cleanup on server shutdown ────────────────────────────────────────────────
game:BindToClose(function()
    NPCService.stopLOD()
    NPCService.despawnAll()
end)

print("[NPCSystem] Initialised. LOD active. Rarities: Common/Rare/Epic/Legendary/Mythic.")
