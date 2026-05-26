--[[
    NPCSystem / EffectController
    Applies rarity-based visual effects to an NPC model:
      • SelectionBox outline  (Rare+)
      • PointLight glow       (Rare+)
      • ParticleEmitter aura  (Rare+)
      • Halo ring             (Legendary+)
      • Neon wing constructs  (Mythic)
      • Rainbow hue-shift     (Mythic, via RunService loop)

    All instances are parented under a folder inside the model so
    cleanup() can remove everything in one call.
--]]

local RunService = game:GetService("RunService")

local EffectController = {}
EffectController.__index = EffectController

-- ── Constructor ───────────────────────────────────────────────────────────────
function EffectController.new(model, rarityDef)
    local self = setmetatable({}, EffectController)
    self._model     = model
    self._rarity    = rarityDef
    self._conns     = {}   -- RBXScriptConnections
    self._folder    = Instance.new("Folder")
    self._folder.Name = "NPCEffects"
    self._folder.Parent = model
    self._active    = true
    return self
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function getPart(model, name)
    return model:FindFirstChild(name)
end

local function makeAttachment(parent, name, cf)
    local a = Instance.new("Attachment")
    a.Name   = name
    a.CFrame = cf or CFrame.new()
    a.Parent = parent
    return a
end

local function makeParticle(attachment, color, rate, speed, lifetime, size)
    local p = Instance.new("ParticleEmitter")
    p.Color          = ColorSequence.new(color)
    p.Rate           = rate
    p.Speed          = NumberRange.new(speed * 0.5, speed)
    p.Lifetime       = NumberRange.new(lifetime * 0.6, lifetime)
    p.Size           = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   size,  0),
        NumberSequenceKeypoint.new(0.5, size * 1.4, 0),
        NumberSequenceKeypoint.new(1,   0,     0),
    })
    p.Transparency   = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.2, 0),
        NumberSequenceKeypoint.new(0.6, 0.5, 0),
        NumberSequenceKeypoint.new(1,   1,   0),
    })
    p.LightEmission  = 0.85
    p.LightInfluence = 0.1
    p.Rotation       = NumberRange.new(-180, 180)
    p.RotSpeed       = NumberRange.new(-45, 45)
    p.SpreadAngle    = Vector2.new(60, 60)
    p.Parent         = attachment
    return p
end

-- ── Apply all effects for this rarity ─────────────────────────────────────────
function EffectController:apply()
    if not self._active then return end
    local r = self._rarity
    if not r then return end

    local hrp  = getPart(self._model, "HumanoidRootPart")
    local head = getPart(self._model, "Head")
    if not hrp or not head then return end

    -- SelectionBox outline (Rare+)
    if r.outlineColor and r.outlineThick > 0 then
        local box = Instance.new("SelectionBox")
        box.Adornee           = self._model
        box.Color3            = r.outlineColor
        box.LineThickness     = r.outlineThick
        box.SurfaceTransparency = 0.9
        box.SurfaceColor3     = r.outlineColor
        box.Parent            = self._folder
        self._selectionBox    = box
    end

    -- PointLight glow (Rare+)
    if r.lightColor then
        local light = Instance.new("PointLight")
        light.Color      = r.lightColor
        light.Range      = r.lightRange
        light.Brightness = r.lightBrightness
        light.Shadows    = true
        light.Parent     = hrp
        table.insert(self._conns, { instance = light })
    end

    -- Aura particle emitter on HRP (Rare+)
    if r.particles and r.auraColor then
        local att = makeAttachment(hrp, "AuraAttach", CFrame.new(0, -1, 0))
        att.Parent = self._folder
        makeParticle(att, r.auraColor, r.auraRate, 3, 1.8, 0.35)
    end

    -- Halo ring above head (Legendary+)
    if r.halo then
        self:_buildHalo(head, r)
    end

    -- Neon wing constructs (Mythic)
    if r.wings then
        self:_buildWings(hrp, r)
    end

    -- Rainbow hue-shift loop (Mythic)
    if r.rainbow then
        self:_startRainbowLoop()
    end
end

-- ── Halo ring ────────────────────────────────────────────────────────────────
function EffectController:_buildHalo(head, r)
    local ring = Instance.new("Part")
    ring.Name         = "HaloRing"
    ring.Shape        = Enum.PartType.Cylinder
    ring.Size         = Vector3.new(0.18, 3.2, 3.2)
    ring.CFrame       = head.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored     = false
    ring.CanCollide   = false
    ring.CastShadow   = false
    ring.BrickColor   = BrickColor.new(r.label == "Mythic" and "Bright pink" or "Bright yellow")
    ring.Material     = Enum.Material.Neon
    ring.Transparency = 0.12
    ring.Parent       = self._model

    local weld = Instance.new("WeldConstraint")
    weld.Part0  = head
    weld.Part1  = ring
    weld.Parent = ring

    -- Glow particles inside the halo
    local att = makeAttachment(ring, "HaloParticles")
    att.Parent = ring
    makeParticle(att, r.auraColor, 20, 1.5, 1.2, 0.18)

    self._haloRing = ring
end

-- ── Neon wings ────────────────────────────────────────────────────────────────
function EffectController:_buildWings(hrp, r)
    local wingColor = BrickColor.new("Bright pink")
    local wingData  = {
        { cf = CFrame.new(-1.8, 0.5, 0.3) * CFrame.Angles(0,  0.5, 0.5), sz = Vector3.new(0.18, 2.8, 1.6) },
        { cf = CFrame.new( 1.8, 0.5, 0.3) * CFrame.Angles(0, -0.5,-0.5), sz = Vector3.new(0.18, 2.8, 1.6) },
        { cf = CFrame.new(-2.6, 0.0, 0.5) * CFrame.Angles(0,  0.6, 0.7), sz = Vector3.new(0.12, 1.8, 1.0) },
        { cf = CFrame.new( 2.6, 0.0, 0.5) * CFrame.Angles(0, -0.6,-0.7), sz = Vector3.new(0.12, 1.8, 1.0) },
    }

    for _, wd in wingData do
        local w = Instance.new("Part")
        w.Name         = "Wing"
        w.Size         = wd.sz
        w.CFrame       = hrp.CFrame * wd.cf
        w.Anchored     = false
        w.CanCollide   = false
        w.CastShadow   = false
        w.BrickColor   = wingColor
        w.Material     = Enum.Material.Neon
        w.Transparency = 0.22
        w.Parent       = self._model

        local weld = Instance.new("WeldConstraint")
        weld.Part0  = hrp
        weld.Part1  = w
        weld.Parent = w
    end
end

-- ── Rainbow outline loop (Mythic) ─────────────────────────────────────────────
function EffectController:_startRainbowLoop()
    local box = self._selectionBox
    if not box then return end

    local conn = RunService.Heartbeat:Connect(function()
        if not self._active then return end
        local hue = (tick() * 0.25) % 1
        box.Color3 = Color3.fromHSV(hue, 1, 1)
    end)
    table.insert(self._conns, conn)
end

-- ── LOD helpers ───────────────────────────────────────────────────────────────

-- Disable particles when NPC is far away.
function EffectController:setParticlesEnabled(enabled)
    for _, desc in self._model:GetDescendants() do
        if desc:IsA("ParticleEmitter") then
            desc.Enabled = enabled
        end
    end
end

-- ── Cleanup ───────────────────────────────────────────────────────────────────
function EffectController:cleanup()
    self._active = false

    for _, conn in self._conns do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._conns = {}

    if self._folder and self._folder.Parent then
        self._folder:Destroy()
    end

    -- Remove lights and particles that were parented directly to model parts
    for _, desc in self._model:GetDescendants() do
        if desc:IsA("PointLight") or desc:IsA("ParticleEmitter") then
            desc:Destroy()
        end
    end
end

return EffectController
