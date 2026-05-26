--[[
    NPCSystem / BillboardController
    Creates a floating UI above each NPC's head showing:
      • Display name  (large, bold)
      • Rarity badge  (coloured pill)
      • Subtitle text (small, italic)
      • Health bar    (if NPC has maxHp)
    Distance-based fade: fully visible at <NEAR studs, invisible at >FAR studs.
    Update the health bar by calling :setHealth(current, max).
--]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config     = require(script.Parent.Config)

local NEAR = Config.Settings.BILLBOARD_FADE_NEAR
local FAR  = Config.Settings.BILLBOARD_FADE_FAR

local BillboardController = {}
BillboardController.__index = BillboardController

-- ── Constructor ───────────────────────────────────────────────────────────────
function BillboardController.new(model, npcDef, rarityDef)
    local self = setmetatable({}, BillboardController)
    self._model     = model
    self._npcDef    = npcDef
    self._rarityDef = rarityDef
    self._active    = true
    self._conn      = nil
    self._gui       = nil
    self._healthFill = nil

    self:_build()
    self:_startFadeLoop()
    return self
end

-- ── Build the BillboardGui ────────────────────────────────────────────────────
function BillboardController:_build()
    local head = self._model:FindFirstChild("Head")
    if not head then return end

    local r = self._rarityDef

    local gui = Instance.new("BillboardGui")
    gui.Name              = "NPCBillboard"
    gui.Size              = UDim2.new(0, 220, 0, 88)
    gui.StudsOffset       = Vector3.new(0, 2.6, 0)
    gui.AlwaysOnTop       = false
    gui.LightInfluence    = 0.0
    gui.MaxDistance       = FAR + 10
    gui.ResetOnSpawn      = false
    gui.Parent            = head
    self._gui             = gui

    -- ---- Background frame ----
    local bg = Instance.new("Frame")
    bg.Size                 = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3     = Color3.fromRGB(10, 10, 15)
    bg.BackgroundTransparency = 0.35
    bg.BorderSizePixel      = 0
    bg.Parent               = gui
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color       = r.outlineColor or Color3.fromRGB(80, 80, 80)
    stroke.Thickness   = 1.5
    stroke.Transparency = 0.25
    stroke.Parent       = bg

    -- ---- Rarity badge ----
    local badge = Instance.new("Frame")
    badge.Size             = UDim2.new(0, 74, 0, 18)
    badge.Position         = UDim2.new(0.5, -37, 0, 7)
    badge.BackgroundColor3 = r.badgeColor or Color3.fromRGB(60, 60, 70)
    badge.BorderSizePixel  = 0
    badge.Parent           = bg
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)

    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.Size                   = UDim2.new(1, 0, 1, 0)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Text                   = r.label or "Common"
    badgeLbl.TextColor3             = r.labelColor or Color3.new(1, 1, 1)
    badgeLbl.Font                   = Enum.Font.GothamBlack
    badgeLbl.TextSize               = 11
    badgeLbl.TextStrokeTransparency = 0.5
    badgeLbl.Parent                 = badge

    -- ---- Name label ----
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                   = UDim2.new(1, -12, 0, 26)
    nameLbl.Position               = UDim2.new(0, 6, 0, 27)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                   = self._npcDef.displayName or "NPC"
    nameLbl.TextColor3             = Color3.new(1, 1, 1)
    nameLbl.Font                   = Enum.Font.GothamBold
    nameLbl.TextSize               = 17
    nameLbl.TextStrokeTransparency = 0.3
    nameLbl.TextXAlignment         = Enum.TextXAlignment.Center
    nameLbl.Parent                 = bg

    -- ---- Subtitle label ----
    local subLbl = Instance.new("TextLabel")
    subLbl.Size                   = UDim2.new(1, -12, 0, 16)
    subLbl.Position               = UDim2.new(0, 6, 0, 52)
    subLbl.BackgroundTransparency = 1
    subLbl.Text                   = self._npcDef.subtitle or ""
    subLbl.TextColor3             = Color3.fromRGB(180, 180, 190)
    subLbl.Font                   = Enum.Font.Gotham
    subLbl.TextSize               = 11
    subLbl.TextXAlignment         = Enum.TextXAlignment.Center
    subLbl.Parent                 = bg

    -- ---- Health bar (if NPC has HP) ----
    if self._npcDef.maxHp then
        local barBg = Instance.new("Frame")
        barBg.Size             = UDim2.new(0.85, 0, 0, 7)
        barBg.Position         = UDim2.new(0.075, 0, 1, -12)
        barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        barBg.BorderSizePixel  = 0
        barBg.Parent           = bg
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame")
        fill.Size             = UDim2.new(1, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
        fill.BorderSizePixel  = 0
        fill.Parent           = barBg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
        self._healthFill = fill
    end
end

-- ── Update health bar ─────────────────────────────────────────────────────────
function BillboardController:setHealth(current, max)
    if not self._healthFill then return end
    local ratio = math.clamp(current / math.max(1, max), 0, 1)
    self._healthFill.Size = UDim2.new(ratio, 0, 1, 0)

    -- Colour: green → yellow → red
    local r = math.min(1, 2 * (1 - ratio))
    local g = math.min(1, 2 * ratio)
    self._healthFill.BackgroundColor3 = Color3.new(r, g, 0.1)
end

-- ── Distance-based fade loop ──────────────────────────────────────────────────
function BillboardController:_startFadeLoop()
    local gui = self._gui
    if not gui then return end

    self._conn = RunService.Heartbeat:Connect(function()
        if not self._active then return end

        local head = self._model:FindFirstChild("Head")
        if not head then return end

        -- Find nearest player
        local minDist = math.huge
        for _, p in Players:GetPlayers() do
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - head.Position).Magnitude
                if d < minDist then minDist = d end
            end
        end

        -- Map distance → transparency (0 = visible, 1 = hidden)
        local t
        if minDist <= NEAR then
            t = 0
        elseif minDist >= FAR then
            t = 1
        else
            t = (minDist - NEAR) / (FAR - NEAR)
        end

        gui.Enabled = t < 0.98
    end)
end

-- ── Cleanup ───────────────────────────────────────────────────────────────────
function BillboardController:cleanup()
    self._active = false
    if self._conn then self._conn:Disconnect() end
    if self._gui and self._gui.Parent then
        self._gui:Destroy()
    end
end

return BillboardController
