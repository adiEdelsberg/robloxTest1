-- NeonRiftHud.client.luau
-- Shows a color indicator while the player is inside Neon Rift.
-- Fires and hides based on the NeonRiftColorAssigned RemoteEvent.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 20)
if not gameEvents then return end

local colorEvent = gameEvents:WaitForChild("NeonRiftColorAssigned", 20)
if not colorEvent then return end

-- ── Build HUD ─────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "NeonRiftHud"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.Enabled         = true
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = player:WaitForChild("PlayerGui")

-- Outer card — bottom-center of screen
local card = Instance.new("Frame")
card.Name                  = "ColorCard"
card.Size                  = UDim2.new(0, 220, 0, 80)
card.Position              = UDim2.new(0.5, -110, 1, -110)
card.BackgroundColor3      = Color3.fromRGB(10, 10, 18)
card.BackgroundTransparency = 0.18
card.BorderSizePixel       = 0
card.Visible               = false
card.Parent                = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent       = card

local stroke = Instance.new("UIStroke")
stroke.Color       = Color3.new(1, 1, 1)
stroke.Thickness   = 1.5
stroke.Transparency = 0.7
stroke.Parent      = card

-- Label: "YOUR COLOR"
local label = Instance.new("TextLabel")
label.Size                  = UDim2.new(1, 0, 0, 22)
label.Position              = UDim2.new(0, 0, 0, 8)
label.BackgroundTransparency = 1
label.Text                  = "YOUR COLOR — JUMP ON IT!"
label.TextColor3            = Color3.new(1, 1, 1)
label.TextTransparency      = 0.1
label.Font                  = Enum.Font.GothamBold
label.TextSize              = 13
label.Parent                = card

-- Color swatch
local swatch = Instance.new("Frame")
swatch.Name                  = "Swatch"
swatch.Size                  = UDim2.new(0, 120, 0, 34)
swatch.Position              = UDim2.new(0.5, -60, 0, 36)
swatch.BackgroundColor3      = Color3.new(1, 1, 1)
swatch.BackgroundTransparency = 0
swatch.BorderSizePixel       = 0
swatch.Parent                = card

local swatchCorner = Instance.new("UICorner")
swatchCorner.CornerRadius = UDim.new(0, 8)
swatchCorner.Parent       = swatch

local swatchStroke = Instance.new("UIStroke")
swatchStroke.Color       = Color3.new(1, 1, 1)
swatchStroke.Thickness   = 2
swatchStroke.Transparency = 0.5
swatchStroke.Parent      = swatch

-- ── Pulse animation on the swatch ────────────────────────────────────────────
local pulseConn
local function startPulse(color)
	if pulseConn then pulseConn:Disconnect() pulseConn = nil end
	local on = true
	pulseConn = game:GetService("RunService").Heartbeat:Connect(function()
		-- driven by a simple time-based sine for smoothness
	end)
	-- Use TweenService to pulse transparency instead
	if pulseConn then pulseConn:Disconnect() pulseConn = nil end

	local function doPulse()
		if not card.Visible then return end
		TweenService:Create(swatch, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.55,
		}):Play()
		task.delay(0.22, function()
			if not card.Visible then return end
			TweenService:Create(swatch, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0,
			}):Play()
			task.delay(0.22, doPulse)
		end)
	end
	doPulse()
end

local function stopPulse()
	if pulseConn then pulseConn:Disconnect() pulseConn = nil end
end

-- ── Show / hide ───────────────────────────────────────────────────────────────
local function showColor(color3)
	swatch.BackgroundColor3 = color3
	swatchStroke.Color      = color3
	stroke.Color            = color3
	card.Visible            = true
	startPulse(color3)
end

local function hideColor()
	card.Visible = false
	stopPulse()
end

colorEvent.OnClientEvent:Connect(function(color3)
	if color3 then
		showColor(color3)
	else
		hideColor()
	end
end)
