--[[
    NPCModule  (ServerStorage)
    Core NPC system — handles model creation, R6 animation, hit/damage/defeat,
    money popups, HP bars, and now:
      • Rarity visual effects  (outline, glow, particles, halo, wings)
      • Enhanced billboard     (name + rarity badge + HP bar)
      • Look-at-player         (NPCs face nearby players when idle)
      • Rainbow hue-shift      (Mythic only)
--]]

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local TweenService= game:GetService("TweenService")
local Debris      = game:GetService("Debris")

local function playSoundAt(id, _position)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = 0.9
    s.Parent = workspace
    s:Play()
    Debris:AddItem(s, 4)
end
local BoundaryService = require(script.Parent:WaitForChild("WorldBoundaryService"))

local PI  = math.pi
local PI2 = math.pi / 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local BASE_MONEY_PER_HIT   = Balance.NPCRewards.BaseMoneyPerHit
local BASE_MONEY_ON_DEFEAT = Balance.NPCRewards.BaseMoneyOnDefeat
local LOOK_AT_RANGE        = 18   -- studs within which NPC faces player

local MONEY_MULT = { [0]=1, [1]=1.5, [2]=2 }

-- Neck Motor6D base transform (R6 standard)
local BASE_NECK_C0 = CFrame.new(0, 1, 0) * CFrame.Angles(-PI/2, 0, PI)

-- ============================================================
-- RARITY VISUAL CONFIG
-- ============================================================
local RARITY_FX = {
    Common = {
        outline       = nil,
        lightColor    = nil,
        particles     = false,
        halo          = false,
        wings         = false,
        rainbow       = false,
        eyeColor      = Color3.fromRGB(255, 255, 255),
        pupilColor    = Color3.fromRGB(40,  40,  40),
        eyeGlow       = false,
        badgeColor    = Color3.fromRGB(80,  80,  90),
        labelColor    = Color3.fromRGB(200, 200, 200),
        label         = "Common",
    },
    Rare = {
        outline       = Color3.fromRGB(80,  160, 255),
        outlineThick  = 0.04,
        lightColor    = Color3.fromRGB(80,  160, 255),
        lightRange    = 12,
        lightBright   = 0.7,
        particles     = true,
        particleColor = Color3.fromRGB(80,  160, 255),
        particleRate  = 12,
        halo          = false,
        wings         = false,
        rainbow       = false,
        eyeColor      = Color3.fromRGB(180, 220, 255),
        pupilColor    = Color3.fromRGB(0,   80,  220),
        eyeGlow       = true,
        badgeColor    = Color3.fromRGB(30,  90,  200),
        labelColor    = Color3.fromRGB(100, 180, 255),
        label         = "Rare",
    },
    Epic = {
        outline       = Color3.fromRGB(180, 80,  255),
        outlineThick  = 0.055,
        lightColor    = Color3.fromRGB(180, 80,  255),
        lightRange    = 18,
        lightBright   = 1.1,
        particles     = true,
        particleColor = Color3.fromRGB(200, 80,  255),
        particleRate  = 30,
        halo          = false,
        wings         = false,
        rainbow       = false,
        eyeColor      = Color3.fromRGB(230, 180, 255),
        pupilColor    = Color3.fromRGB(140, 0,   255),
        eyeGlow       = true,
        badgeColor    = Color3.fromRGB(110, 20,  180),
        labelColor    = Color3.fromRGB(200, 100, 255),
        label         = "Epic",
    },
    Legendary = {
        outline       = Color3.fromRGB(255, 200, 0),
        outlineThick  = 0.07,
        lightColor    = Color3.fromRGB(255, 200, 0),
        lightRange    = 28,
        lightBright   = 1.9,
        particles     = true,
        particleColor = Color3.fromRGB(255, 200, 0),
        particleRate  = 55,
        halo          = true,
        haloColor     = BrickColor.new("Bright yellow"),
        wings         = false,
        rainbow       = false,
        eyeColor      = Color3.fromRGB(255, 240, 160),
        pupilColor    = Color3.fromRGB(180, 110, 0),
        eyeGlow       = true,
        badgeColor    = Color3.fromRGB(160, 110, 0),
        labelColor    = Color3.fromRGB(255, 210, 40),
        label         = "Legendary",
    },
    Mythic = {
        outline       = Color3.fromRGB(255, 60,  120),
        outlineThick  = 0.09,
        lightColor    = Color3.fromRGB(255, 80,  140),
        lightRange    = 40,
        lightBright   = 2.8,
        particles     = true,
        particleColor = Color3.fromRGB(255, 60,  120),
        particleRate  = 90,
        halo          = true,
        haloColor     = BrickColor.new("Bright pink"),
        wings         = true,
        rainbow       = true,
        eyeColor      = Color3.fromRGB(255, 180, 220),
        pupilColor    = Color3.fromRGB(255, 0,   100),
        eyeGlow       = true,
        badgeColor    = Color3.fromRGB(140, 0,   60),
        labelColor    = Color3.fromRGB(255, 80,  140),
        label         = "Mythic",
    },
}

-- ============================================================
-- JOINT DEFINITIONS  (unchanged from original)
-- ============================================================
local JOINT_DEFS = {
    { name="RootJoint",      inPart="HumanoidRootPart", p0="HumanoidRootPart", p1="Torso",
      c0=CFrame.new(0,-1,0)*CFrame.Angles(-PI/2,0,PI),  c1=CFrame.new(0,-1,0)*CFrame.Angles(-PI/2,0,PI) },
    { name="Neck",           inPart="Torso",            p0="Torso",            p1="Head",
      c0=CFrame.new(0,1,0)*CFrame.Angles(-PI/2,0,PI),   c1=CFrame.new(0,-1.3,0)*CFrame.Angles(-PI/2,0,PI) },
    { name="Right Shoulder", inPart="Torso",            p0="Torso",            p1="Right Arm",
      c0=CFrame.new(1,0.5,0)*CFrame.Angles(0,PI2,0),    c1=CFrame.new(-0.5,0.5,0)*CFrame.Angles(0,PI2,0) },
    { name="Left Shoulder",  inPart="Torso",            p0="Torso",            p1="Left Arm",
      c0=CFrame.new(-1,0.5,0)*CFrame.Angles(0,-PI2,0),  c1=CFrame.new(0.5,0.5,0)*CFrame.Angles(0,-PI2,0) },
    { name="Right Hip",      inPart="Torso",            p0="Torso",            p1="Right Leg",
      c0=CFrame.new(1,-1,0)*CFrame.Angles(0,PI2,0),     c1=CFrame.new(0.5,1,0)*CFrame.Angles(0,PI2,0) },
    { name="Left Hip",       inPart="Torso",            p0="Torso",            p1="Left Leg",
      c0=CFrame.new(-1,-1,0)*CFrame.Angles(0,-PI2,0),   c1=CFrame.new(-0.5,1,0)*CFrame.Angles(0,-PI2,0) },
}

local BASE_C0 = {
    ["Right Shoulder"] = CFrame.new(1,0.5,0)*CFrame.Angles(0,PI2,0),
    ["Left Shoulder"]  = CFrame.new(-1,0.5,0)*CFrame.Angles(0,-PI2,0),
    ["Right Hip"]      = CFrame.new(1,-1,0)*CFrame.Angles(0,PI2,0),
    ["Left Hip"]       = CFrame.new(-1,-1,0)*CFrame.Angles(0,-PI2,0),
}

local npcRegistry  = {}
local hitCooldowns = {}

local npcDefeatedEvent = Instance.new("BindableEvent")
local npcHitEvent      = Instance.new("BindableEvent")

-- ============================================================
-- HEARTBEAT — animation + look-at
-- ============================================================
local startTime = tick()

RunService.Heartbeat:Connect(function(dt)
    local now = tick()
    for model, info in npcRegistry do
        if not model.Parent then npcRegistry[model] = nil; continue end
        local hrp = model.PrimaryPart
        if not hrp then continue end

        local vel        = hrp.AssemblyLinearVelocity
        local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        info.animPhase  += dt * (horizSpeed > 1 and horizSpeed * 1.4 or 0.8)

        local swing    = math.sin(info.animPhase)
        local legAngle = swing * math.rad(35)
        local armAngle = -swing * math.rad(22)
        local j = info.joints

        if j["Left Hip"]       then j["Left Hip"].C0       = BASE_C0["Left Hip"]       * CFrame.Angles(legAngle,  0, 0) end
        if j["Right Hip"]      then j["Right Hip"].C0      = BASE_C0["Right Hip"]      * CFrame.Angles(-legAngle, 0, 0) end
        if j["Left Shoulder"]  then j["Left Shoulder"].C0  = BASE_C0["Left Shoulder"]  * CFrame.Angles(armAngle,  0, 0) end
        if j["Right Shoulder"] then j["Right Shoulder"].C0 = BASE_C0["Right Shoulder"] * CFrame.Angles(-armAngle, 0, 0) end

        -- ── Find nearest player ───────────────────────────────────────────────
        local bestHRP = nil
        local bestD   = LOOK_AT_RANGE
        for _, p in Players:GetPlayers() do
            local char = p.Character
            local phrp = char and char:FindFirstChild("HumanoidRootPart")
            if phrp then
                local d = (phrp.Position - hrp.Position).Magnitude
                if d < bestD then bestD = d; bestHRP = phrp end
            end
        end

        -- ── Body look-at (HRP yaw) when idle ─────────────────────────────────
        if horizSpeed < 3 and bestHRP then
            local goal = CFrame.lookAt(
                hrp.Position,
                Vector3.new(bestHRP.Position.X, hrp.Position.Y, bestHRP.Position.Z)
            )
            hrp.CFrame = hrp.CFrame:Lerp(goal, math.min(1, dt * 5))
        end

        -- ── Neck joint: head turns & tilts toward player ──────────────────────
        local neckJoint = j["Neck"]
        if neckJoint then
            local torso = model:FindFirstChild("Torso")
            local targetYaw, targetPitch = 0, 0

            if bestHRP and torso then
                local worldDir  = (bestHRP.Position - torso.Position)
                local localDir  = torso.CFrame:VectorToObjectSpace(worldDir.Unit)
                targetYaw   = math.clamp(math.atan2(localDir.X, -localDir.Z), -math.rad(55), math.rad(55))
                targetPitch = math.clamp(math.atan2(localDir.Y, math.sqrt(localDir.X^2 + localDir.Z^2)), -math.rad(35), math.rad(25))
            end

            -- Smooth toward target
            info.headYaw   = info.headYaw   + (targetYaw   - info.headYaw)   * math.min(1, dt * 7)
            info.headPitch = info.headPitch + (targetPitch - info.headPitch) * math.min(1, dt * 7)

            -- Gentle head bob while walking
            local bob = horizSpeed > 1 and math.sin(info.animPhase * 0.7) * math.rad(2.5) or 0

            neckJoint.C0 = BASE_NECK_C0 * CFrame.Angles(-info.headPitch + bob, -info.headYaw, 0)
        end

        -- ── Pupil tracking (Motor6D C0 updated toward player direction) ───────
        local face = info.face
        if face then
            local head = model:FindFirstChild("Head")
            if head and head.Parent then
                local px, py = 0, 0
                if bestHRP then
                    local localDir = head.CFrame:VectorToObjectSpace((bestHRP.Position - head.Position).Unit)
                    px = math.clamp( localDir.X * 0.15, -0.10, 0.10)
                    py = math.clamp(-localDir.Y * 0.10, -0.07, 0.07)
                end

                -- Smooth pupil movement (info.pupilX/Y lazily initialized)
                info.pupilX = (info.pupilX or 0) + (px - (info.pupilX or 0)) * math.min(1, dt * 8)
                info.pupilY = (info.pupilY or 0) + (py - (info.pupilY or 0)) * math.min(1, dt * 8)

                local EL = EYE_OFFSETS[1]
                local ER = EYE_OFFSETS[2]
                if face.motorPupils[1] and face.motorPupils[1].Parent then
                    face.motorPupils[1].C0 = CFrame.new(EL.X + info.pupilX, EL.Y + info.pupilY, PUPIL_Z)
                end
                if face.motorPupils[2] and face.motorPupils[2].Parent then
                    face.motorPupils[2].C0 = CFrame.new(ER.X + info.pupilX, ER.Y + info.pupilY, PUPIL_Z)
                end

                -- Eyebrow raise when looking at a player (subtle)
                local browRaise = bestHRP and math.rad(4) or 0
                local mb1 = face.motorBrows[1]; local mb2 = face.motorBrows[2]
                if mb1 and mb1.Parent then
                    mb1.C0 = face.browBaseC0_1 * CFrame.new(0, browRaise * 0.4, 0)
                end
                if mb2 and mb2.Parent then
                    mb2.C0 = face.browBaseC0_2 * CFrame.new(0, browRaise * 0.4, 0)
                end
            end

            -- ── Blinking ─────────────────────────────────────────────────────
            if not info.isBlinking and now >= (info.blinkNext or 0) then
                info.isBlinking = true
                info.blinkNext  = now + math.random(3, 7) + math.random() * 2

                local eyeParts = face.eyeParts
                local pupils   = face.motorPupils
                task.spawn(function()
                    -- Close (squish Y)
                    for _, ep in eyeParts do
                        if ep and ep.Parent then ep.Size = Vector3.new(EYE_SIZE.X, 0.06, EYE_SIZE.Z) end
                    end
                    for _, m in pupils do
                        if m and m.Parent then m.Part1.Transparency = 1 end
                    end
                    task.wait(0.07)
                    -- Reopen
                    for _, ep in eyeParts do
                        if ep and ep.Parent then ep.Size = EYE_SIZE end
                    end
                    for _, m in pupils do
                        if m and m.Parent then m.Part1.Transparency = 0 end
                    end
                    info.isBlinking = false
                end)
            end

            -- ── Mythic rainbow pupils ─────────────────────────────────────────
            if info.rainbow then
                local hue = (now * 0.5) % 1
                for _, m in face.motorPupils do
                    if m and m.Parent and m.Part1 then
                        m.Part1.Color = Color3.fromHSV(hue, 1, 1)
                    end
                end
            end
        end

        -- ── Rainbow outline hue-shift (Mythic) ───────────────────────────────
        if info.selectionBox and info.rainbow then
            local hue = (now * 0.3) % 1
            info.selectionBox.Color3 = Color3.fromHSV(hue, 1, 1)
        end
    end
end)

-- ============================================================
-- MONEY POPUP  (unchanged)
-- ============================================================
local function showMoneyPopup(model, amount, isBonus)
    local head = model:FindFirstChild("Head")
    if not head then return end
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 110, 0, 38)
    bg.StudsOffset = Vector3.new(0, 5.5, 0)
    bg.AlwaysOnTop = true
    bg.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = "+$" .. amount
    label.TextColor3 = isBonus and Color3.fromRGB(255,80,220) or Color3.fromRGB(255,215,0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = bg
    TweenService:Create(bg, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { StudsOffset = Vector3.new(0, 9, 0) }):Play()
    task.delay(0.5, function()
        if label.Parent then
            TweenService:Create(label, TweenInfo.new(0.7), { TextTransparency=1, TextStrokeTransparency=1 }):Play()
        end
    end)
    task.delay(1.4, function() if bg.Parent then bg:Destroy() end end)
end

-- ============================================================
-- FACE BUILDER  (eyes, pupils, brows, mouth — all welded to Head)
-- ============================================================
--[[
    Eye whites  → WeldConstraint (fixed to head)
    Eye shine   → WeldConstraint (small highlight dot inside each eye)
    Pupils      → Motor6D       (updated each frame for player tracking)
    Eyebrows    → Motor6D       (updated occasionally for expressions)
    Mouth       → WeldConstraint (static shape; Y-scaled for blink-mouth open)
--]]
local EYE_SIZE    = Vector3.new(0.58, 0.58, 0.58)
local PUPIL_SIZE  = Vector3.new(0.26, 0.26, 0.26)
local SHINE_SIZE  = Vector3.new(0.12, 0.12, 0.12)
local BROW_SIZE   = Vector3.new(0.52, 0.12, 0.13)
local MOUTH_SIZE  = Vector3.new(0.72, 0.16, 0.12)

-- Eye whites are at ±0.52 X, +0.14 Y, -1.26 Z in head local space
local EYE_OFFSETS = { Vector3.new(-0.52, 0.14, -1.26), Vector3.new(0.52, 0.14, -1.26) }
local PUPIL_Z     = -1.44   -- pupils sit just in front of eye whites

local HAIR_PALETTE = {
    "Really black", "Reddish brown", "Bright yellow", "White",
    "Hot pink", "Cyan", "Royal purple", "Bright orange", "Teal",
    "Dark orange", "Sand red", "Cashmere", "Medium stone grey",
}
local HAIR_STYLES = {
    "Spiky", "Mohawk", "Afro", "Short", "Long",
    "Bun", "Ponytail", "Curly", "Bowl", "Wavy",
}

-- Brainrot title generation ("coffe birda caught 18" style)
local BRAINROT_WORDS = {
    "coffe", "skibidi", "sigma", "ohio", "fanum", "rizz", "gyatt", "mogging",
    "looksmax", "bonk", "bussin", "drip", "glazing", "griddy", "ratio",
    "mewing", "delulu", "gooning", "slay", "sus", "npc", "beta", "alpha",
    "gigachad", "erm", "cuh", "blud", "fax", "lowkey", "yapping", "buss",
}
local BRAINROT_ANIMALS = {
    "birda", "monke", "catta", "doggo", "snakey", "foxo", "wolfo", "frogg",
    "shrimpo", "wormo", "boaro", "fishy", "ratto", "bunneh", "ducky",
    "chicky", "crabbo", "bearo", "snaily", "hamsta", "piggo", "turto",
}
local function makeBrainrotName()
    local w = BRAINROT_WORDS[math.random(#BRAINROT_WORDS)]
    local a = BRAINROT_ANIMALS[math.random(#BRAINROT_ANIMALS)]
    return w .. " " .. a .. " caught " .. math.random(1, 99)
end

local function weldTo(parent, child)
    local wc = Instance.new("WeldConstraint")
    wc.Part0 = parent; wc.Part1 = child; wc.Parent = child
end

local function makePart(size, color, mat, transparent, cyl, ball)
    local p = Instance.new("Part")
    p.Size         = size
    p.Color        = color
    p.Material     = mat or Enum.Material.SmoothPlastic
    p.Transparency = transparent or 0
    p.CanCollide   = false
    p.CastShadow   = false
    if cyl  then p.Shape = Enum.PartType.Cylinder end
    if ball then p.Shape = Enum.PartType.Ball      end
    return p
end

local function buildHair(head, style, color)
    local col  = Color3.new(color.R, color.G, color.B)
    local mat  = Enum.Material.SmoothPlastic
    local neon = Enum.Material.Neon
    local hr   = 1.3  -- head radius

    local function attach(p, offset, rotCF)
        p.CFrame  = head.CFrame * (rotCF or CFrame.new()) * CFrame.new(offset)
        p.Parent  = head.Parent
        weldTo(head, p)
    end

    if style == "Spiky" then
        -- 5 upward spikes radiating from crown
        local angles = {0, 72, 144, 216, 288}
        for i, ang in ipairs(angles) do
            local p = makePart(Vector3.new(0.35, 0.9 + i * 0.05, 0.35), col, mat)
            local rad = math.rad(ang)
            local ox = math.sin(rad) * 0.6
            local oz = math.cos(rad) * 0.6
            attach(p, Vector3.new(ox, hr + 0.35, oz))
        end
        -- center tall spike
        local c = makePart(Vector3.new(0.28, 1.1, 0.28), col, mat)
        attach(c, Vector3.new(0, hr + 0.55, 0))

    elseif style == "Mohawk" then
        -- ridge of 6 blocks front-to-back along top center
        for i = 1, 6 do
            local t = (i - 1) / 5
            local h = 0.5 + math.sin(t * math.pi) * 0.55
            local p = makePart(Vector3.new(0.32, h, 0.32), col, mat)
            attach(p, Vector3.new(0, hr + h * 0.5, (t - 0.5) * 2 * hr))
        end

    elseif style == "Afro" then
        -- big fluffy sphere cluster
        local offsets = {
            {0, hr + 0.55, 0}, {0.55, hr + 0.3, 0}, {-0.55, hr + 0.3, 0},
            {0, hr + 0.3, 0.55}, {0, hr + 0.3, -0.55},
            {0.38, hr + 0.5, 0.38}, {-0.38, hr + 0.5, 0.38},
            {0.38, hr + 0.5, -0.38}, {-0.38, hr + 0.5, -0.38},
        }
        for _, o in ipairs(offsets) do
            local sz = 0.65 + math.random() * 0.3
            local p = makePart(Vector3.new(sz, sz, sz), col, mat, 0, false, true)
            attach(p, Vector3.new(o[1], o[2], o[3]))
        end

    elseif style == "Short" then
        -- thin flat cap hugging the top
        local cap = makePart(Vector3.new(2.1, 0.35, 2.1), col, mat, 0, false, false)
        attach(cap, Vector3.new(0, hr + 0.17, 0))
        -- small back bump
        local back = makePart(Vector3.new(1.5, 0.28, 0.6), col, mat)
        attach(back, Vector3.new(0, hr - 0.05, hr * 0.7))

    elseif style == "Long" then
        -- top cap + two long side curtains + back drape
        local cap = makePart(Vector3.new(2.1, 0.35, 2.0), col, mat)
        attach(cap, Vector3.new(0, hr + 0.17, 0))
        local left = makePart(Vector3.new(0.38, 1.8, 0.38), col, mat)
        attach(left, Vector3.new(-hr + 0.1, -0.55, 0))
        local right = makePart(Vector3.new(0.38, 1.8, 0.38), col, mat)
        attach(right, Vector3.new(hr - 0.1, -0.55, 0))
        local back = makePart(Vector3.new(1.4, 1.8, 0.38), col, mat)
        attach(back, Vector3.new(0, -0.55, hr - 0.1))

    elseif style == "Bun" then
        -- flat cap + large round bun on top-back
        local cap = makePart(Vector3.new(2.1, 0.3, 2.0), col, mat)
        attach(cap, Vector3.new(0, hr + 0.15, 0))
        local bun = makePart(Vector3.new(1.0, 1.0, 1.0), col, mat, 0, false, true)
        attach(bun, Vector3.new(0, hr + 0.5, hr * 0.55))

    elseif style == "Ponytail" then
        -- cap + long tail hanging at back
        local cap = makePart(Vector3.new(2.1, 0.32, 2.0), col, mat)
        attach(cap, Vector3.new(0, hr + 0.16, 0))
        local band = makePart(Vector3.new(0.6, 0.28, 0.6), col, mat, 0, false, true)
        attach(band, Vector3.new(0, hr * 0.2, hr))
        local tail = makePart(Vector3.new(0.32, 1.6, 0.32), col, mat)
        attach(tail, Vector3.new(0, hr * 0.2 - 0.8, hr + 0.1))

    elseif style == "Curly" then
        -- spiral blob clusters around sides and top
        local offsets = {
            {0, hr + 0.5, 0}, {0.7, hr + 0.1, 0.4}, {-0.7, hr + 0.1, 0.4},
            {0.7, hr + 0.1, -0.4}, {-0.7, hr + 0.1, -0.4},
            {0.55, hr + 0.4, 0}, {-0.55, hr + 0.4, 0},
        }
        for _, o in ipairs(offsets) do
            local s = 0.55 + math.random() * 0.25
            local p = makePart(Vector3.new(s, s, s), col, mat, 0, false, true)
            attach(p, Vector3.new(o[1], o[2], o[3]))
        end

    elseif style == "Bowl" then
        -- wide flat dome sitting low on head
        local dome = makePart(Vector3.new(2.5, 0.5, 2.5), col, mat, 0, false, false)
        attach(dome, Vector3.new(0, hr * 0.55, 0))
        -- slight front fringe
        local fringe = makePart(Vector3.new(2.3, 0.22, 0.4), col, mat)
        attach(fringe, Vector3.new(0, hr * 0.1, -hr + 0.05))

    elseif style == "Wavy" then
        -- cap + wavy side strips
        local cap = makePart(Vector3.new(2.1, 0.32, 2.0), col, mat)
        attach(cap, Vector3.new(0, hr + 0.16, 0))
        local waveOffsets = { {-hr + 0.12, 0.05}, {hr - 0.12, 0.05} }
        for _, wo in ipairs(waveOffsets) do
            for seg = 1, 4 do
                local t = (seg - 1) / 3
                local wy = -t * 1.2 + math.sin(t * math.pi * 2) * 0.2
                local p = makePart(Vector3.new(0.36, 0.42, 0.36), col, mat)
                attach(p, Vector3.new(wo[1], wo[2] + wy, (t - 0.5) * 1.8))
            end
        end
    end
end

local function buildFace(head, data, fx)
    local modelParent = head.Parent
    local eyeWhite    = fx.eyeColor   or Color3.new(1,1,1)
    local pupilCol    = fx.pupilColor or Color3.fromRGB(40,40,40)
    local browCol     = Color3.fromRGB(55, 38, 22)

    -- Derive brow color from body color when available
    if data.bodyColor then
        local bc = BrickColor.new(data.bodyColor)
        local r,g,b = bc.Color.R, bc.Color.G, bc.Color.B
        -- slightly darker than body
        browCol = Color3.new(r*0.55, g*0.55, b*0.55)
    end

    local face = { eyeParts={}, motorPupils={}, motorBrows={} }

    -- ── Eye whites + shine ────────────────────────────────────────────────────
    for i, offset in EYE_OFFSETS do
        local eye = makePart(EYE_SIZE, eyeWhite, Enum.Material.SmoothPlastic, 0, false, true)
        eye.Name  = "Eye" .. i
        eye.CFrame = head.CFrame * CFrame.new(offset)
        eye.Parent = modelParent
        weldTo(head, eye)
        face.eyeParts[i] = eye

        -- Subtle highlight dot (top-left of each eye)
        local shine = makePart(SHINE_SIZE, Color3.new(1,1,1), Enum.Material.Neon, 0.3, false, true)
        shine.Name  = "EyeShine" .. i
        shine.CFrame = head.CFrame * CFrame.new(offset + Vector3.new(offset.X < 0 and 0.1 or -0.1, 0.11, -0.18))
        shine.Parent = modelParent
        weldTo(head, shine)
    end

    -- ── Pupils via Motor6D (so we can update C0 each frame) ──────────────────
    local pupilMat = fx.eyeGlow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    for i, offset in EYE_OFFSETS do
        local pupil = makePart(PUPIL_SIZE, pupilCol, pupilMat, 0, false, true)
        pupil.Name  = "Pupil" .. i
        pupil.CFrame = head.CFrame * CFrame.new(offset.X, offset.Y, PUPIL_Z)
        pupil.Parent = modelParent

        local m = Instance.new("Motor6D")
        m.Name  = "PupilMotor" .. i
        m.C0    = CFrame.new(offset.X, offset.Y, PUPIL_Z)
        m.C1    = CFrame.new(0, 0, 0)
        m.Part0 = head
        m.Part1 = pupil
        m.Parent = head
        face.motorPupils[i] = m
    end

    -- ── Eyebrows via Motor6D (for expression changes) ─────────────────────────
    local browOffsets = {
        { x=-0.52, y=0.72, z=-1.22, tilt= math.rad(8)  },
        { x= 0.52, y=0.72, z=-1.22, tilt=-math.rad(8)  },
    }
    for i, bd in browOffsets do
        local brow = makePart(BROW_SIZE, browCol, Enum.Material.SmoothPlastic, 0)
        brow.Name  = "Brow" .. i
        brow.CFrame = head.CFrame * CFrame.new(bd.x, bd.y, bd.z) * CFrame.Angles(0, 0, bd.tilt)
        brow.Parent = modelParent

        local m = Instance.new("Motor6D")
        m.Name  = "BrowMotor" .. i
        m.C0    = CFrame.new(bd.x, bd.y, bd.z) * CFrame.Angles(0, 0, bd.tilt)
        m.C1    = CFrame.new(0, 0, 0)
        m.Part0 = head
        m.Part1 = brow
        m.Parent = head
        face.motorBrows[i] = m
        face["browBaseC0_"..i] = m.C0
    end

    -- ── Mouth ─────────────────────────────────────────────────────────────────
    local mouth = makePart(MOUTH_SIZE, Color3.fromRGB(175, 55, 55), Enum.Material.SmoothPlastic, 0)
    mouth.Name   = "Mouth"
    mouth.CFrame = head.CFrame * CFrame.new(0, -0.46, -1.26)
    mouth.Parent = modelParent
    weldTo(head, mouth)
    face.mouth = mouth

    -- Inner mouth (darker cavity, slightly recessed)
    local innerMouth = makePart(Vector3.new(0.54, 0.10, 0.06), Color3.fromRGB(80,20,20), Enum.Material.SmoothPlastic, 0)
    innerMouth.Name   = "MouthInner"
    innerMouth.CFrame = head.CFrame * CFrame.new(0, -0.46, -1.30)
    innerMouth.Parent = modelParent
    weldTo(head, innerMouth)

    return face
end

-- ============================================================
-- ENHANCED BILLBOARD  (name + rarity badge + HP bar)
-- ============================================================
local function buildBillboard(head, data, fx)
    -- Remove any legacy HP bar gui that may exist
    for _, c in head:GetChildren() do
        if c:IsA("BillboardGui") then c:Destroy() end
    end

    local gui = Instance.new("BillboardGui")
    gui.Name           = "NPCBillboard"
    gui.Size           = UDim2.new(0, 200, 0, 72)
    gui.StudsOffset    = Vector3.new(0, 3.2, 0)
    gui.AlwaysOnTop    = false
    gui.LightInfluence = 0
    gui.MaxDistance    = 80
    gui.Parent         = head

    -- Dark background
    local bg = Instance.new("Frame")
    bg.Size                 = UDim2.new(1,0,1,0)
    bg.BackgroundColor3     = Color3.fromRGB(10,10,15)
    bg.BackgroundTransparency = 0.32
    bg.BorderSizePixel      = 0
    bg.Parent               = gui
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,10)

    local stroke = Instance.new("UIStroke")
    stroke.Color       = fx.outline or Color3.fromRGB(70,70,80)
    stroke.Thickness   = 1.5
    stroke.Transparency = 0.2
    stroke.Parent      = bg

    -- Rarity badge
    local badge = Instance.new("Frame")
    badge.Size             = UDim2.new(0, 72, 0, 17)
    badge.Position         = UDim2.new(0.5,-36,0,6)
    badge.BackgroundColor3 = fx.badgeColor
    badge.BorderSizePixel  = 0
    badge.Parent           = bg
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0,8)

    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.Size                   = UDim2.new(1,0,1,0)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Text                   = fx.label
    badgeLbl.TextColor3             = fx.labelColor
    badgeLbl.Font                   = Enum.Font.GothamBlack
    badgeLbl.TextSize               = 11
    badgeLbl.TextStrokeTransparency = 0.45
    badgeLbl.Parent                 = badge

    -- NPC name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                   = UDim2.new(1,-10,0,22)
    nameLbl.Position               = UDim2.new(0,5,0,25)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                   = makeBrainrotName()
    nameLbl.TextColor3             = Color3.new(1,1,1)
    nameLbl.Font                   = Enum.Font.GothamBold
    nameLbl.TextSize               = 15
    nameLbl.TextStrokeTransparency = 0.3
    nameLbl.TextXAlignment         = Enum.TextXAlignment.Center
    nameLbl.Parent                 = bg

    -- HP bar (only when NPC has multiple HP)
    local hpFill = nil
    if (data.maxHp or 1) > 1 then
        local barBg = Instance.new("Frame")
        barBg.Size             = UDim2.new(0.84,0,0,7)
        barBg.Position         = UDim2.new(0.08,0,1,-11)
        barBg.BackgroundColor3 = Color3.fromRGB(25,25,25)
        barBg.BorderSizePixel  = 0
        barBg.Parent           = bg
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(0,4)

        hpFill = Instance.new("Frame")
        hpFill.Size             = UDim2.new(1,0,1,0)
        hpFill.BackgroundColor3 = Color3.fromRGB(50,210,50)
        hpFill.BorderSizePixel  = 0
        hpFill.Parent           = barBg
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0,4)
    end

    return hpFill
end

local function updateHpBar(fill, hp, maxHp)
    if not fill or not fill.Parent then return end
    local ratio = maxHp > 0 and math.max(0, hp / maxHp) or 0
    fill.Size = UDim2.new(ratio,0,1,0)
    local r = math.min(1, 2*(1-ratio))
    local g = math.min(1, 2*ratio)
    fill.BackgroundColor3 = Color3.new(r, g, 0.08)
end

-- ============================================================
-- RARITY VISUAL EFFECTS
-- ============================================================
local function applyRarityFX(model, fx)
    local hrp  = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    if not hrp then return end

    local selectionBox = nil

    -- Outline
    if fx.outline then
        local box = Instance.new("SelectionBox")
        box.Adornee             = model
        box.Color3              = fx.outline
        box.LineThickness       = fx.outlineThick or 0.05
        box.SurfaceTransparency = 0.88
        box.SurfaceColor3       = fx.outline
        box.Parent              = model
        selectionBox = box
    end

    -- PointLight glow
    if fx.lightColor then
        local light = Instance.new("PointLight")
        light.Color      = fx.lightColor
        light.Range      = fx.lightRange or 16
        light.Brightness = fx.lightBright or 1
        light.Shadows    = true
        light.Parent     = hrp
    end

    -- Aura particles on HRP
    if fx.particles and fx.particleColor then
        local att = Instance.new("Attachment")
        att.CFrame  = CFrame.new(0, -0.8, 0)
        att.Parent  = hrp

        local p = Instance.new("ParticleEmitter")
        p.Color         = ColorSequence.new(fx.particleColor)
        p.Rate          = fx.particleRate or 15
        p.Speed         = NumberRange.new(1, 2.5)
        p.Lifetime      = NumberRange.new(0.8, 2.0)
        p.Size          = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0.28, 0),
            NumberSequenceKeypoint.new(0.5, 0.42, 0),
            NumberSequenceKeypoint.new(1,   0,    0),
        })
        p.Transparency  = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0.15, 0),
            NumberSequenceKeypoint.new(0.6, 0.5,  0),
            NumberSequenceKeypoint.new(1,   1,    0),
        })
        p.LightEmission  = 0.9
        p.LightInfluence = 0.05
        p.SpreadAngle    = Vector2.new(55, 55)
        p.RotSpeed       = NumberRange.new(-30, 30)
        p.Parent         = att
    end

    -- Halo ring (Legendary+)
    if fx.halo and head then
        local ring = Instance.new("Part")
        ring.Name         = "HaloRing"
        ring.Shape        = Enum.PartType.Cylinder
        ring.Size         = Vector3.new(0.2, 3.4, 3.4)
        ring.CFrame       = head.CFrame * CFrame.new(0, 2.0, 0) * CFrame.Angles(0,0,math.rad(90))
        ring.Anchored     = false
        ring.CanCollide   = false
        ring.CastShadow   = false
        ring.BrickColor   = fx.haloColor or BrickColor.new("Bright yellow")
        ring.Material     = Enum.Material.Neon
        ring.Transparency = 0.1
        ring.Parent       = model
        local hw = Instance.new("WeldConstraint")
        hw.Part0 = head; hw.Part1 = ring; hw.Parent = ring

        -- Particle sparkle inside halo
        local ha = Instance.new("Attachment"); ha.Parent = ring
        local hp2 = Instance.new("ParticleEmitter")
        hp2.Color        = ColorSequence.new(fx.particleColor or Color3.new(1,1,0))
        hp2.Rate         = 18
        hp2.Speed        = NumberRange.new(0.5, 1.5)
        hp2.Lifetime     = NumberRange.new(0.6, 1.2)
        hp2.Size         = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.18,0), NumberSequenceKeypoint.new(1,0,0) })
        hp2.LightEmission= 1
        hp2.Parent       = ha
    end

    -- Neon wings (Mythic)
    if fx.wings then
        local wingDefs = {
            { cf=CFrame.new(-1.85,0.4,0.3)*CFrame.Angles(0, 0.5, 0.5), sz=Vector3.new(0.18,2.6,1.5) },
            { cf=CFrame.new( 1.85,0.4,0.3)*CFrame.Angles(0,-0.5,-0.5), sz=Vector3.new(0.18,2.6,1.5) },
            { cf=CFrame.new(-2.55,0.0,0.5)*CFrame.Angles(0, 0.6, 0.65),sz=Vector3.new(0.12,1.6,0.9) },
            { cf=CFrame.new( 2.55,0.0,0.5)*CFrame.Angles(0,-0.6,-0.65),sz=Vector3.new(0.12,1.6,0.9) },
        }
        for _, wd in wingDefs do
            local w = Instance.new("Part")
            w.Name        = "Wing"
            w.Size        = wd.sz
            w.CFrame      = hrp.CFrame * wd.cf
            w.Anchored    = false
            w.CanCollide  = false
            w.CastShadow  = false
            w.BrickColor  = BrickColor.new("Bright pink")
            w.Material    = Enum.Material.Neon
            w.Transparency= 0.22
            w.Parent      = model
            local ww = Instance.new("WeldConstraint")
            ww.Part0 = hrp; ww.Part1 = w; ww.Parent = w
        end
    end

    return selectionBox
end

-- ============================================================
-- HIT → DAMAGE → DEFEAT
-- ============================================================
local function playDropDefeat(model)
    if not model or not model.Parent then return end

    local pivotValue = Instance.new("CFrameValue")
    pivotValue.Value = model:GetPivot()
    local startPivot = pivotValue.Value
    local dropPivot = startPivot * CFrame.new(0, -7, 0) * CFrame.Angles(math.rad(78), 0, math.rad(8))

    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    local pivotConn = pivotValue.Changed:Connect(function(cf)
        if model.Parent then
            model:PivotTo(cf)
        end
    end)

    local dropTween = TweenService:Create(
        pivotValue,
        TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        { Value = dropPivot }
    )
    dropTween:Play()

    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") and part.Transparency < 1 then
            TweenService:Create(part, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Transparency = math.min(1, part.Transparency + 0.45),
            }):Play()
        end
    end

    task.wait(0.48)
    pivotConn:Disconnect()
    pivotValue:Destroy()
end

local function onBallHit(model, ball)
    if hitCooldowns[model] then return end
    if not ball or not ball:IsA("BasePart") then return end
    local throwerName = ball:GetAttribute("ThrowerName")
    if not throwerName then return end
    if ball:GetAttribute("IsThrown") ~= true then return end
    local throwTime = ball:GetAttribute("ThrowTime")
    if typeof(throwTime) ~= "number" or os.clock() - throwTime > 8 then return end
    if ball.AssemblyLinearVelocity.Magnitude < 10 then return end
    local thrower = Players:FindFirstChild(throwerName)
    if not thrower then return end

    hitCooldowns[model] = true
    npcHitEvent:Fire(model)
    playSoundAt("rbxassetid://137750395861529", ball.Position)

    local info = npcRegistry[model]
    if not info then hitCooldowns[model] = nil; return end

    local mult  = MONEY_MULT[thrower:GetAttribute("MoneyTier") or 0] or 1
    local maxHp = model:GetAttribute("MaxHp") or 1
    local hp    = 0
    model:SetAttribute("Hp", hp)

    local stats = thrower:FindFirstChild("leaderstats")
    local cash  = stats and stats:FindFirstChild("Cash")
    if cash then
        local hitMoney = math.ceil((info.moneyPerHit or BASE_MONEY_PER_HIT) * mult)
        cash.Value += hitMoney
        showMoneyPopup(model, hitMoney, false)
    end

    updateHpBar(info.hpFill, hp, maxHp)

    task.spawn(function()
        local saved = {}
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") and part.Transparency < 1 then
                saved[part] = part.BrickColor
                part.BrickColor = BrickColor.new("White")
            end
        end
        task.wait(0.12)
        for part in saved do
            if part.Parent then part.BrickColor = BrickColor.new("Bright yellow") end
        end
        task.wait(0.08)

        if cash then
            local defeatMoney = math.ceil((info.moneyOnDefeat or BASE_MONEY_ON_DEFEAT) * mult)
            cash.Value += defeatMoney
            showMoneyPopup(model, defeatMoney, true)
        end

        npcRegistry[model]  = nil
        hitCooldowns[model] = nil
        npcDefeatedEvent:Fire(model, thrower)

        playDropDefeat(model)
        if model.Parent then
            model:Destroy()
        end
    end)
end

-- ============================================================
-- PUBLIC API
-- ============================================================
local module = {}

module.OnNPCDefeated = npcDefeatedEvent.Event
module.OnNPCHit      = npcHitEvent.Event

function module.createNPC(data)
    local sx = data.spawnX or math.random(-40, 40)
    local sz = data.spawnZ or math.random(-40, 40)

    -- Rarity lookup (defaults to Common if not set)
    local fx = RARITY_FX[data.rarity or "Common"] or RARITY_FX.Common

    local model = Instance.new("Model")
    model.Name = data.name
    model:SetAttribute("IsBrainrot", true)

    local maxHp = data.maxHp or 1
    model:SetAttribute("MaxHp", maxHp)
    model:SetAttribute("Hp",    maxHp)

    local partDefs = {
        { name="HumanoidRootPart", size=Vector3.new(2,2,1),         color="White",               trans=1, collide=false },
        { name="Torso",            size=Vector3.new(2,2,1),         color=data.bodyColor },
        { name="Head",             size=Vector3.new(2.6,2.6,2.6),   color=data.headColor or "Nougat" },
        { name="Left Arm",         size=Vector3.new(1,2,1),         color=data.bodyColor },
        { name="Right Arm",        size=Vector3.new(1,2,1),         color=data.bodyColor },
        { name="Left Leg",         size=Vector3.new(1,2,1),         color=data.bodyColor },
        { name="Right Leg",        size=Vector3.new(1,2,1),         color=data.bodyColor },
    }
    for _, def in partDefs do
        local part = Instance.new("Part")
        part.Name        = def.name
        part.Size        = def.size
        part.BrickColor  = BrickColor.new(def.color)
        part.Material    = Enum.Material.SmoothPlastic
        part.Transparency= def.trans or 0
        part.CanCollide  = def.collide ~= false
        part.CFrame      = CFrame.new(sx, 8, sz)
        part.Parent      = model
    end
    model.PrimaryPart = model.HumanoidRootPart
    model:FindFirstChild("Head").Shape = Enum.PartType.Ball

    local joints = {}
    for _, jd in JOINT_DEFS do
        local m = Instance.new("Motor6D")
        m.Name  = jd.name
        m.C0    = jd.c0
        m.C1    = jd.c1
        m.Part0 = model:FindFirstChild(jd.p0)
        m.Part1 = model:FindFirstChild(jd.p1)
        m.Parent= model:FindFirstChild(jd.inPart)
        joints[jd.name] = m
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.RigType           = Enum.HumanoidRigType.R6
    humanoid.WalkSpeed         = math.random(data.minSpeed, data.maxSpeed)
    humanoid.JumpPower         = math.random(data.minJump or 40, data.maxJump or 60)
    humanoid.AutoRotate        = true
    humanoid.AutoJumpEnabled   = true
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.DisplayName       = RunService:IsStudio() and (data.name or "") or ""
    humanoid.Parent            = model

    -- Accessories (hats, crowns, etc. from data.accessories)
    if data.accessories then
        for _, acc in data.accessories do
            local parentPart = model:FindFirstChild(acc.parent or "Head")
            if not parentPart then continue end
            local ap = Instance.new("Part")
            ap.Name        = "Accessory"
            ap.Size        = acc.size
            ap.BrickColor  = BrickColor.new(acc.color)
            ap.Material    = acc.mat or Enum.Material.SmoothPlastic
            ap.Transparency= acc.trans or 0
            ap.CanCollide  = false
            ap.CastShadow  = false
            if acc.cyl  then ap.Shape = Enum.PartType.Cylinder end
            if acc.ball then ap.Shape = Enum.PartType.Ball      end
            ap.CFrame  = parentPart.CFrame * acc.cf
            ap.Parent  = model
            local wc = Instance.new("WeldConstraint")
            wc.Part0 = parentPart; wc.Part1 = ap; wc.Parent = ap
        end
    end

    -- Hit detection
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            part.Touched:Connect(function(hit)
                if hit.Name == "Ball" then onBallHit(model, hit) end
            end)
        end
    end

    model.Parent = workspace

    -- Billboard removed (overhead UI disabled)
    local head   = model:FindFirstChild("Head")
    local hpFill = nil

    -- Face (eyes, pupils, brows, mouth)
    local faceData = head and buildFace(head, data, fx)

    -- Hair
    if head then
        local hairStyle = HAIR_STYLES[math.random(#HAIR_STYLES)]
        local hairColorName = HAIR_PALETTE[math.random(#HAIR_PALETTE)]
        local hairColor = BrickColor.new(hairColorName).Color
        buildHair(head, hairStyle, hairColor)
    end

    -- Rarity visual effects (outline, glow, particles, halo, wings)
    local selectionBox = applyRarityFX(model, fx)

    npcRegistry[model] = {
        joints        = joints,
        animPhase     = math.random() * math.pi * 2,
        hpFill        = hpFill,
        moneyPerHit   = data.moneyPerHit,
        moneyOnDefeat = data.moneyOnDefeat,
        selectionBox  = selectionBox,
        rainbow       = fx.rainbow or false,
        -- Face & head tracking state
        face          = faceData,
        headYaw       = 0,
        headPitch     = 0,
        pupilX        = 0,
        pupilY        = 0,
        blinkNext     = tick() + math.random(2, 5),
        isBlinking    = false,
    }

    return model, humanoid
end

function module.startWander(model, humanoid, data, bounds)
    local b = bounds or { minX=-44, maxX=44, minZ=-44, maxZ=44 }
    BoundaryService.bindModel(model, b, { margin = data.boundaryMargin or 5, minY = 0.5, maxY = data.maxBoundaryY or 140 })
    local function pick()
        return Vector3.new(
            math.random(b.minX + 5, b.maxX - 5),
            1,
            math.random(b.minZ + 5, b.maxZ - 5)
        )
    end
    local function move()
        if not model.Parent then return end
        humanoid:MoveTo(pick())
    end
    humanoid.MoveToFinished:Connect(function()
        humanoid.WalkSpeed = math.random(data.minSpeed, data.maxSpeed)
        task.wait(math.random(1, 4))
        move()
    end)
    local jumpChance  = data.jumpChance  or 0.4
    local minJumpWait = data.minJumpWait or 3
    local maxJumpWait = data.maxJumpWait or 9
    task.spawn(function()
        while model.Parent do
            task.wait(math.random(minJumpWait, maxJumpWait))
            if model.Parent and math.random() < jumpChance then humanoid.Jump = true end
        end
    end)
    task.delay(math.random(0, 4), move)
end

return module
