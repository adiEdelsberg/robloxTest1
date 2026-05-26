--[[
    NPCSystem / NPCService
    Core service.  Responsibilities:
      • Build a complete high-quality R6 humanoid model from a npcDef blueprint
      • Wire up AnimationController, EffectController, BillboardController,
        NPCController for every spawned NPC
      • Run a distance-based LOD loop every LOD_UPDATE_RATE seconds
      • Provide spawnNPC / despawnNPC / spawnGroup / despawnAll API
      • Clean up every instance and connection on despawn (no leaks)

    ── Model anatomy built in code ─────────────────────────────────────────────
    We construct a standard R6 rig so that Roblox's Animator works with
    default animation IDs.  Body part sizes match the default Roblox R6 avatar.
    Users can swap this for template-model cloning (see _cloneTemplate).

    ── Skinning / high-quality look ─────────────────────────────────────────────
    • Rounded head via SpecialMesh (Sphere)
    • Smooth plastic body with custom BrickColors
    • SurfaceAppearance on torso / head (texture IDs from npcDef – leave blank
      to use solid colours)
    • Hair built from Parts welded to head
    • Accessory parts (hat brim, bag, etc.) driven by npcDef.accessories list
--]]

local RunService    = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config          = require(script.Parent.Config)
local NPCController   = require(script.Parent.NPCController)
local EffectController= require(script.Parent.EffectController)
local BillboardCtrl   = require(script.Parent.BillboardController)

local SETTINGS = Config.Settings

-- ── Module ────────────────────────────────────────────────────────────────────
local NPCService = {}
NPCService.__index = NPCService

-- Registry: [instanceId] = { model, npcCtrl, effectCtrl, billboardCtrl, npcDef, spawnPos }
local _registry = {}
local _nextId   = 1
local _lodConn  = nil

-- ── R6 Joint constants ────────────────────────────────────────────────────────
-- These match Roblox's default R6 character skeleton exactly so that
-- Roblox animation IDs play correctly.
local R6_JOINTS = {
    RootJoint       = { p0="HumanoidRootPart", p1="Torso",
        c0=CFrame.new(0,-1,0,-1,0,0,0,0,1,0,1,0),
        c1=CFrame.new(0,-1,0,-1,0,0,0,0,1,0,1,0) },
    Neck            = { p0="Torso",  p1="Head",
        c0=CFrame.new(0,1,0,-1,0,0,0,0,1,0,1,0),
        c1=CFrame.new(0,-0.5,0,-1,0,0,0,0,1,0,1,0) },
    ["Left Shoulder"] = { p0="Torso", p1="Left Arm",
        c0=CFrame.new(-1,0.5,0,0,0,-1,0,1,0,1,0,0),
        c1=CFrame.new(0.5,0.5,0,0,0,-1,0,1,0,1,0,0) },
    ["Right Shoulder"]= { p0="Torso", p1="Right Arm",
        c0=CFrame.new(1,0.5,0,0,0,1,0,1,0,-1,0,0),
        c1=CFrame.new(-0.5,0.5,0,0,0,1,0,1,0,-1,0,0) },
    ["Left Hip"]    = { p0="Torso", p1="Left Leg",
        c0=CFrame.new(-1,-1,0,0,0,-1,0,1,0,1,0,0),
        c1=CFrame.new(-0.5,1,0,0,0,-1,0,1,0,1,0,0) },
    ["Right Hip"]   = { p0="Torso", p1="Right Leg",
        c0=CFrame.new(1,-1,0,0,0,1,0,1,0,-1,0,0),
        c1=CFrame.new(0.5,1,0,0,0,1,0,1,0,-1,0,0) },
}

-- ── Part sizes (default R6 avatar) ────────────────────────────────────────────
local PART_SIZES = {
    HumanoidRootPart = Vector3.new(2, 2, 1),
    Head             = Vector3.new(2, 1, 1),
    Torso            = Vector3.new(2, 2, 1),
    ["Left Arm"]     = Vector3.new(1, 2, 1),
    ["Right Arm"]    = Vector3.new(1, 2, 1),
    ["Left Leg"]     = Vector3.new(1, 2, 1),
    ["Right Leg"]    = Vector3.new(1, 2, 1),
}

-- ── Internal: build a basic part ──────────────────────────────────────────────
local function makePart(name, size, color, material, parent)
    local p = Instance.new("Part")
    p.Name         = name
    p.Size         = size
    p.Color        = color or Color3.fromRGB(163, 162, 165)
    p.Material     = material or Enum.Material.SmoothPlastic
    p.TopSurface   = Enum.SurfaceType.Smooth
    p.BottomSurface= Enum.SurfaceType.Smooth
    p.CanCollide   = false
    p.CastShadow   = true
    p.Parent       = parent
    return p
end

-- ── Internal: build a Motor6D joint ───────────────────────────────────────────
local function makeJoint(name, part0, part1, c0, c1)
    local m = Instance.new("Motor6D")
    m.Name  = name
    m.Part0 = part0
    m.Part1 = part1
    m.C0    = c0
    m.C1    = c1
    m.Parent = part0
    return m
end

-- ── Internal: add a SurfaceAppearance (texture) to a part ─────────────────────
local function addSurfaceAppearance(part, textureId, color)
    -- If textureId is blank we just rely on part.Color for a clean solid look.
    if not textureId or textureId == "" then return end
    local sa = Instance.new("SurfaceAppearance")
    sa.AlbedoMap  = textureId
    sa.MetalnessMap = ""
    sa.NormalMap  = ""
    sa.RoughnessMap = ""
    sa.Parent     = part
end

-- ── Internal: build a hair style from parts welded to Head ────────────────────
local function buildHair(head, style, color)
    local hairParts = {}

    local function addHairPart(size, cf, trans)
        local p = makePart("Hair", size, color, Enum.Material.SmoothPlastic, head.Parent)
        p.CastShadow = false
        p.CFrame     = head.CFrame * cf
        local w = Instance.new("WeldConstraint")
        w.Part0 = head; w.Part1 = p; w.Parent = p
        p.Transparency = trans or 0
        table.insert(hairParts, p)
        return p
    end

    if style == "Short" then
        addHairPart(Vector3.new(2.05, 0.55, 1.05), CFrame.new(0,  0.5, -0.02))
        addHairPart(Vector3.new(1.85, 0.32, 1.05), CFrame.new(0,  0.28, -0.52))
    elseif style == "Long" then
        addHairPart(Vector3.new(2.05, 0.55, 1.05), CFrame.new(0,  0.5,  -0.02))
        addHairPart(Vector3.new(1.7,  2.2,  0.38), CFrame.new(0, -0.5,   0.55))
        addHairPart(Vector3.new(1.55, 1.2,  0.32), CFrame.new(-0.7,-0.9, 0.38))
        addHairPart(Vector3.new(1.55, 1.2,  0.32), CFrame.new( 0.7,-0.9, 0.38))
    elseif style == "Spiky" then
        addHairPart(Vector3.new(2.05, 0.45, 1.05), CFrame.new(0,  0.45,  0))
        local spikeOffsets = {
            CFrame.new( 0,    0.82, -0.3) * CFrame.Angles(-0.5, 0,  0),
            CFrame.new(-0.65, 0.75, -0.1) * CFrame.Angles(-0.3, 0,  0.4),
            CFrame.new( 0.65, 0.75, -0.1) * CFrame.Angles(-0.3, 0, -0.4),
        }
        for _, cf in spikeOffsets do
            addHairPart(Vector3.new(0.45, 0.95, 0.45), cf)
        end
    end
    -- "Bald" → no hair parts

    return hairParts
end

-- ── Internal: build glowing eyes ──────────────────────────────────────────────
local function buildFace(head, eyeColor)
    local eyeData = {
        { cf = CFrame.new(-0.35, 0.1, -0.52), sz = Vector3.new(0.32, 0.32, 0.2) },
        { cf = CFrame.new( 0.35, 0.1, -0.52), sz = Vector3.new(0.32, 0.32, 0.2) },
    }
    for _, ed in eyeData do
        -- White sclera
        local sclera = makePart("EyeWhite", ed.sz, Color3.new(1,1,1), Enum.Material.SmoothPlastic, head.Parent)
        sclera.Shape = Enum.PartType.Ball
        sclera.CastShadow = false
        sclera.CFrame = head.CFrame * ed.cf
        local w1 = Instance.new("WeldConstraint"); w1.Part0=head; w1.Part1=sclera; w1.Parent=sclera

        -- Coloured iris (neon for the glowing look)
        local iris = makePart("EyeIris", Vector3.new(0.22, 0.22, 0.22), eyeColor, Enum.Material.Neon, head.Parent)
        iris.Shape = Enum.PartType.Ball
        iris.CastShadow = false
        iris.Transparency = 0.1
        iris.CFrame = head.CFrame * ed.cf * CFrame.new(0, 0, -0.06)
        local w2 = Instance.new("WeldConstraint"); w2.Part0=head; w2.Part1=iris; w2.Parent=iris

        -- Pupil
        local pupil = makePart("EyePupil", Vector3.new(0.12, 0.12, 0.12), Color3.new(0,0,0), Enum.Material.SmoothPlastic, head.Parent)
        pupil.Shape = Enum.PartType.Ball
        pupil.CastShadow = false
        pupil.CFrame = head.CFrame * ed.cf * CFrame.new(0, 0, -0.1)
        local w3 = Instance.new("WeldConstraint"); w3.Part0=head; w3.Part1=pupil; w3.Parent=pupil
    end
end

-- ── Internal: assemble a full R6 NPC model ────────────────────────────────────
local function buildModel(npcDef, spawnCF)
    local rarityDef = Config.Rarities[npcDef.rarity] or Config.Rarities.Common
    local skinColor = npcDef.skinColor  or Color3.fromRGB(255, 220, 177)
    local shirtCol  = npcDef.shirtColor or Color3.fromRGB(80, 110, 180)
    local pantsCol  = npcDef.pantsColor or Color3.fromRGB(50, 60, 80)
    local hairCol   = npcDef.hairColor  or Color3.fromRGB(40, 25, 15)
    local eyeCol    = npcDef.eyeColor   or Color3.fromRGB(60, 100, 200)

    local model = Instance.new("Model")
    model.Name  = npcDef.displayName or npcDef.id

    -- Create all body parts
    local parts = {}
    for partName, partSize in PART_SIZES do
        local color
        if partName == "Head" then
            color = skinColor
        elseif partName == "Torso" then
            color = shirtCol
        elseif partName:find("Arm") then
            color = skinColor
        elseif partName:find("Leg") then
            color = pantsCol
        else
            color = Color3.fromRGB(100, 100, 100)
        end

        local part = makePart(partName, partSize, color, Enum.Material.SmoothPlastic, model)

        -- HRP: invisible, only part with collision
        if partName == "HumanoidRootPart" then
            part.Transparency = 1
            part.CanCollide   = true
        end

        parts[partName] = part
    end

    -- Sphere mesh on head for a rounder, more cinematic look
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale    = Vector3.new(1.25, 1.25, 1.25)
    headMesh.Parent   = parts["Head"]

    -- Optional SurfaceAppearance textures (body/head)
    addSurfaceAppearance(parts["Head"],  npcDef.faceTextureId or "")
    addSurfaceAppearance(parts["Torso"], npcDef.bodyTextureId or "")

    -- Humanoid
    local hum = Instance.new("Humanoid")
    hum.DisplayName        = RunService:IsStudio() and (npcDef.displayName or npcDef.id or "") or ""
    hum.HealthDisplayType  = Enum.HumanoidHealthDisplayType.AlwaysOff
    hum.MaxHealth          = math.huge   -- ambient NPCs are immortal
    hum.Health             = math.huge
    hum.WalkSpeed          = math.random(8, 14)
    hum.JumpPower          = 0    -- NPCs don't jump via Humanoid
    hum.AutoJumpEnabled    = false
    hum.Parent             = model

    -- Animator
    local animator = Instance.new("Animator")
    animator.Parent = hum

    -- Place model at spawn position before creating joints
    local basePos = spawnCF.Position + Vector3.new(0, 3, 0)
    parts["HumanoidRootPart"].CFrame = CFrame.new(basePos) * CFrame.Angles(0, spawnCF:ToEulerAnglesYXZ(), 0)

    -- Default R6 part placement relative to HRP
    local hrpCF = parts["HumanoidRootPart"].CFrame
    parts["Torso"].CFrame    = hrpCF * CFrame.new(0, 0, 0)
    parts["Head"].CFrame     = hrpCF * CFrame.new(0, 1.5, 0)
    parts["Left Arm"].CFrame = hrpCF * CFrame.new(-1.5, 0, 0)
    parts["Right Arm"].CFrame= hrpCF * CFrame.new( 1.5, 0, 0)
    parts["Left Leg"].CFrame = hrpCF * CFrame.new(-0.5,-2, 0)
    parts["Right Leg"].CFrame= hrpCF * CFrame.new( 0.5,-2, 0)

    -- Create Motor6D joints using the R6 constants
    for jointName, jd in R6_JOINTS do
        local p0 = parts[jd.p0]
        local p1 = parts[jd.p1]
        if p0 and p1 then
            makeJoint(jointName, p0, p1, jd.c0, jd.c1)
        end
    end

    -- Humanoid needs to know the root part
    model.PrimaryPart = parts["HumanoidRootPart"]

    -- High-quality details
    buildFace(parts["Head"], eyeCol)
    buildHair(parts["Head"], npcDef.hairStyle or "Short", hairCol)

    return model, hum
end

-- ── Optional: clone a pre-built template from ServerStorage ───────────────────
-- Place R6 models in ServerStorage/NPCSystem/Templates/<npcDef.id>
-- If found, the template is cloned instead of building from parts.
local function tryCloneTemplate(npcDef)
    local sys = ServerStorage:FindFirstChild("NPCSystem")
    local tmpl = sys and sys:FindFirstChild("Templates")
    if not tmpl then return nil end
    local t = tmpl:FindFirstChild(npcDef.id)
    if not t then return nil end
    return t:Clone()
end

-- ── Internal: full NPC spawn pipeline ────────────────────────────────────────
local function _doSpawn(id, npcDef, spawnCF)
    local rarityDef = Config.Rarities[npcDef.rarity] or Config.Rarities.Common

    -- Try template first, build from parts as fallback
    local model, hum = tryCloneTemplate(npcDef)
    if not model then
        model, hum = buildModel(npcDef, spawnCF)
    else
        model:PivotTo(spawnCF * CFrame.new(0, 3, 0))
        hum = model:FindFirstChildOfClass("Humanoid")
    end

    model.Parent = workspace

    local spawnPos = spawnCF.Position

    -- Controllers
    local npcCtrl   = NPCController.new(model, npcDef, spawnPos)
    local effectCtrl= EffectController.new(model, rarityDef)
    local billCtrl  = nil -- overhead UI disabled

    effectCtrl:apply()
    npcCtrl:start()

    _registry[id] = {
        id            = id,
        model         = model,
        humanoid      = hum,
        npcCtrl       = npcCtrl,
        effectCtrl    = effectCtrl,
        billboardCtrl = billCtrl,
        npcDef        = npcDef,
        spawnPos      = spawnPos,
        lodLevel      = 0,    -- 0=full, 1=mid, 2=far/frozen
    }

    return id
end

-- ── LOD system ────────────────────────────────────────────────────────────────
local function _updateLOD()
    local players = game:GetService("Players"):GetPlayers()

    for id, entry in _registry do
        if not entry.model or not entry.model.Parent then
            _registry[id] = nil
            continue
        end

        local pos = entry.model:GetPivot().Position
        local minDist = math.huge
        for _, p in players do
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - pos).Magnitude
                if d < minDist then minDist = d end
            end
        end

        local newLevel
        if minDist <= SETTINGS.LOD_NEAR then
            newLevel = 0
        elseif minDist <= SETTINGS.LOD_MID then
            newLevel = 1
        else
            newLevel = 2
        end

        if newLevel ~= entry.lodLevel then
            entry.lodLevel = newLevel

            if newLevel == 0 then
                -- Full quality
                entry.npcCtrl:setPaused(false)
                entry.effectCtrl:setParticlesEnabled(true)

            elseif newLevel == 1 then
                -- Mid: particles off, AI still running
                entry.effectCtrl:setParticlesEnabled(false)

            else
                -- Far: freeze everything
                entry.npcCtrl:setPaused(true)
                entry.effectCtrl:setParticlesEnabled(false)
            end
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Spawn a single NPC by definition id or table.
-- npcDefOrId : string key from Config.NPCs, or a full npcDef table
-- spawnCF    : CFrame (position + initial facing direction)
-- Returns the registry id (integer) for later despawning.
function NPCService.spawnNPC(npcDefOrId, spawnCF)
    local npcDef
    if type(npcDefOrId) == "string" then
        npcDef = Config.NPCs[npcDefOrId]
        if not npcDef then
            warn("[NPCService] Unknown NPC id:", npcDefOrId)
            return nil
        end
    else
        npcDef = npcDefOrId
    end

    local id = _nextId
    _nextId += 1

    local ok, err = pcall(_doSpawn, id, npcDef, spawnCF or CFrame.new())
    if not ok then
        warn("[NPCService] spawnNPC failed:", err)
        return nil
    end
    return id
end

-- Spawn multiple NPCs from a group definition.
-- group = { { id="Wanderer", cframe=CFrame.new(...) }, ... }
function NPCService.spawnGroup(group)
    local ids = {}
    for _, entry in group do
        local id = NPCService.spawnNPC(entry.id, entry.cframe)
        if id then table.insert(ids, id) end
    end
    return ids
end

-- Despawn a single NPC by registry id.
function NPCService.despawnNPC(registryId)
    local entry = _registry[registryId]
    if not entry then return end

    entry.npcCtrl:cleanup()
    entry.effectCtrl:cleanup()
    entry.billboardCtrl:cleanup()

    if entry.model and entry.model.Parent then
        entry.model:Destroy()
    end

    _registry[registryId] = nil
end

-- Despawn all active NPCs.
function NPCService.despawnAll()
    for id in pairs(table.clone(_registry)) do
        NPCService.despawnNPC(id)
    end
end

-- Spawn one random NPC (weighted by npcDef.weight) at the given CFrame.
function NPCService.spawnRandom(spawnCF)
    local pool = {}
    for _, def in Config.NPCs do
        for _ = 1, (def.weight or 10) do
            table.insert(pool, def)
        end
    end
    if #pool == 0 then return nil end
    return NPCService.spawnNPC(pool[math.random(#pool)], spawnCF)
end

-- Return the active registry entry for a given id (read-only, handle with care).
function NPCService.getEntry(registryId)
    return _registry[registryId]
end

-- ── LOD loop ──────────────────────────────────────────────────────────────────
function NPCService.startLOD()
    if _lodConn then return end
    local elapsed = 0
    _lodConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed >= SETTINGS.LOD_UPDATE_RATE then
            elapsed = 0
            _updateLOD()
        end
    end)
end

function NPCService.stopLOD()
    if _lodConn then
        _lodConn:Disconnect()
        _lodConn = nil
    end
end

return NPCService
