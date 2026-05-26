-- DebugTeleportUI.client.luau
-- Small 🛠 badge top-left; click to open teleport popup.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance           = require(ReplicatedStorage:WaitForChild("GameBalanceConfig"))
local WorldOrder        = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local IS_DEBUG = Balance.ActiveMode == "debug" or Balance.ActiveMode == "test" or Balance.ActiveMode == "fallback-debug"
if not IS_DEBUG then return end
local MAX_LEVEL = #WorldOrder.Worlds

local player = Players.LocalPlayer

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
if not gameEvents then return end
local remote = gameEvents:WaitForChild("DebugTeleport", 15)
if not remote then return end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "DebugTeleportUI"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 200
gui.Parent         = player:WaitForChild("PlayerGui")

-- ── Badge (top-left) ──────────────────────────────────────────────────────────
local badge = Instance.new("TextButton")
badge.AnchorPoint         = Vector2.new(0, 0)
badge.Size                = UDim2.new(0, 38, 0, 38)
badge.Position            = UDim2.new(0, 10, 0, 10)
badge.BackgroundColor3    = Color3.fromRGB(180, 30, 30)
badge.BorderSizePixel     = 0
badge.Text                = "🛠"
badge.TextScaled          = true
badge.Font                = Enum.Font.GothamBlack
badge.ZIndex              = 10
badge.Parent              = gui
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color     = Color3.fromRGB(255, 80, 80)
badgeStroke.Thickness = 2
badgeStroke.Parent    = badge

-- ── Popup ─────────────────────────────────────────────────────────────────────
local popup = Instance.new("Frame")
popup.AnchorPoint         = Vector2.new(0, 0)
popup.Size                = UDim2.new(0, 220, 0, 110)
popup.Position            = UDim2.new(0, 10, 0, 54)
popup.BackgroundColor3    = Color3.fromRGB(10, 10, 20)
popup.BackgroundTransparency = 0.1
popup.BorderSizePixel     = 0
popup.Visible             = false
popup.ZIndex              = 9
popup.Parent              = gui
Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 10)

local popupStroke = Instance.new("UIStroke")
popupStroke.Color     = Color3.fromRGB(255, 80, 80)
popupStroke.Thickness = 2
popupStroke.Parent    = popup

-- X close button
local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint         = Vector2.new(1, 0)
closeBtn.Size                = UDim2.new(0, 26, 0, 26)
closeBtn.Position            = UDim2.new(1, -6, 0, 6)
closeBtn.BackgroundColor3    = Color3.fromRGB(180, 30, 30)
closeBtn.BorderSizePixel     = 0
closeBtn.Text                = "✕"
closeBtn.TextColor3          = Color3.fromRGB(255, 255, 255)
closeBtn.Font                = Enum.Font.GothamBlack
closeBtn.TextSize            = 14
closeBtn.ZIndex              = 11
closeBtn.Parent              = popup
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Title
local title = Instance.new("TextLabel")
title.Size                   = UDim2.new(1, -40, 0, 28)
title.Position               = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Text                   = "GO TO LEVEL"
title.TextColor3             = Color3.fromRGB(255, 80, 80)
title.Font                   = Enum.Font.GothamBlack
title.TextSize               = 13
title.TextXAlignment         = Enum.TextXAlignment.Left
title.ZIndex                 = 10
title.Parent                 = popup

-- Input
local inputBox = Instance.new("TextBox")
inputBox.Size              = UDim2.new(0, 110, 0, 32)
inputBox.Position          = UDim2.new(0, 10, 0, 40)
inputBox.BackgroundColor3  = Color3.fromRGB(20, 20, 40)
inputBox.BorderSizePixel   = 0
inputBox.Text              = ""
inputBox.PlaceholderText   = "Level 1-" .. tostring(MAX_LEVEL)
inputBox.TextColor3        = Color3.fromRGB(255, 255, 255)
inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
inputBox.Font              = Enum.Font.GothamBold
inputBox.TextSize          = 16
inputBox.ClearTextOnFocus  = true
inputBox.ZIndex            = 10
inputBox.Parent            = popup
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)

local goBtn = Instance.new("TextButton")
goBtn.Size             = UDim2.new(0, 88, 0, 32)
goBtn.Position         = UDim2.new(0, 124, 0, 40)
goBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
goBtn.BorderSizePixel  = 0
goBtn.Text             = "GO TO LEVEL"
goBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
goBtn.Font             = Enum.Font.GothamBlack
goBtn.TextSize         = 11
goBtn.ZIndex           = 10
goBtn.Parent           = popup
Instance.new("UICorner", goBtn).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size                   = UDim2.new(1, -16, 0, 20)
statusLabel.Position               = UDim2.new(0, 8, 0, 80)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                   = ""
statusLabel.TextColor3             = Color3.fromRGB(160, 160, 180)
statusLabel.Font                   = Enum.Font.Gotham
statusLabel.TextSize               = 12
statusLabel.TextXAlignment         = Enum.TextXAlignment.Left
statusLabel.ZIndex                 = 10
statusLabel.Parent                 = popup

-- ── Logic ─────────────────────────────────────────────────────────────────────
badge.MouseButton1Click:Connect(function()
	popup.Visible = not popup.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
	popup.Visible = false
end)

local function doTeleport()
	local n = tonumber(inputBox.Text)
	remote:FireServer(n)  -- server handles nil/unknown → starter
	if n then
		statusLabel.TextColor3 = Color3.fromRGB(80, 255, 130)
		statusLabel.Text = "Going to level " .. n .. "..."
	else
		statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		statusLabel.Text = "Going to starter..."
	end
end

goBtn.MouseButton1Click:Connect(doTeleport)
inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then doTeleport() end
end)
