local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local event = ReplicatedStorage:WaitForChild("LandingWorldEvent", 30)
local SAFE_TOP = GuiService:GetGuiInset().Y

local gui = Instance.new("ScreenGui")
gui.Name           = "LandingWorldHud"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.Parent         = playerGui

-- ── Main welcome banner ───────────────────────────────────────────────────────
local banner = Instance.new("Frame")
banner.Name              = "LandingBanner"
banner.AnchorPoint       = Vector2.new(0.5, 0)
banner.Size              = UDim2.new(0.88, 0, 0, 96)
banner.Position          = UDim2.new(0.5, 0, 0, SAFE_TOP + 12)
banner.BackgroundColor3  = Color3.fromRGB(4, 6, 18)
banner.BackgroundTransparency = 0.08
banner.BorderSizePixel   = 0
banner.Visible           = false
banner.ZIndex            = 10
banner.Parent            = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)

local bannerLimit = Instance.new("UISizeConstraint")
bannerLimit.MinSize = Vector2.new(320, 96)
bannerLimit.MaxSize = Vector2.new(520, 96)
bannerLimit.Parent  = banner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color       = Color3.fromRGB(200, 150, 50)
bannerStroke.Thickness   = 2
bannerStroke.Transparency = 0.15
bannerStroke.Parent      = banner

local bannerGrad = Instance.new("UIGradient")
bannerGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 12, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 6, 18)),
})
bannerGrad.Rotation = 90
bannerGrad.Parent   = banner

-- Station name label
local stationLabel = Instance.new("TextLabel")
stationLabel.Size                   = UDim2.new(1, -16, 0, 32)
stationLabel.Position               = UDim2.new(0, 12, 0, 8)
stationLabel.BackgroundTransparency = 1
stationLabel.Font                   = Enum.Font.GothamBlack
stationLabel.TextSize               = 20
stationLabel.TextXAlignment         = Enum.TextXAlignment.Left
stationLabel.TextColor3             = Color3.fromRGB(200, 150, 50)
stationLabel.TextStrokeTransparency = 0.4
stationLabel.Text                   = "THE CLOCKWORK KEEP"
stationLabel.ZIndex                 = 11
stationLabel.Parent                 = banner

-- Separator line
local sep = Instance.new("Frame")
sep.Size                 = UDim2.new(1, -24, 0, 1)
sep.Position             = UDim2.new(0, 12, 0, 42)
sep.BackgroundColor3     = Color3.fromRGB(200, 150, 50)
sep.BackgroundTransparency = 0.55
sep.BorderSizePixel      = 0
sep.ZIndex               = 11
sep.Parent               = banner

-- Instruction sub-line
local instructLabel = Instance.new("TextLabel")
instructLabel.Size                   = UDim2.new(1, -16, 0, 44)
instructLabel.Position               = UDim2.new(0, 12, 0, 46)
instructLabel.BackgroundTransparency = 1
instructLabel.Font                   = Enum.Font.GothamBold
instructLabel.TextSize               = 12
instructLabel.TextXAlignment         = Enum.TextXAlignment.Left
instructLabel.TextWrapped            = true
instructLabel.TextColor3             = Color3.fromRGB(200, 220, 255)
instructLabel.TextStrokeTransparency = 0.65
instructLabel.Text                   = "🗺  Start Adventure  ·  ⚙  Time Machines  ·  🎡  Spin the Wheel"
instructLabel.ZIndex                 = 11
instructLabel.Parent                 = banner

-- ── Toast notification (brief message that fades) ────────────────────────────
local toast = Instance.new("Frame")
toast.Name                  = "LandingToast"
toast.AnchorPoint           = Vector2.new(0.5, 0)
toast.Size                  = UDim2.new(0, 340, 0, 48)
toast.Position              = UDim2.new(0.5, 0, 0, SAFE_TOP + 120)
toast.BackgroundColor3      = Color3.fromRGB(10, 22, 38)
toast.BackgroundTransparency = 1
toast.BorderSizePixel       = 0
toast.Visible               = false
toast.ZIndex                = 12
toast.Parent                = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)

local toastStroke = Instance.new("UIStroke")
toastStroke.Color       = Color3.fromRGB(200, 150, 50)
toastStroke.Thickness   = 1.5
toastStroke.Transparency = 0.3
toastStroke.Parent      = toast

local toastLabel = Instance.new("TextLabel")
toastLabel.Size                   = UDim2.new(1, -16, 1, 0)
toastLabel.Position               = UDim2.new(0, 8, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Font                   = Enum.Font.GothamBlack
toastLabel.TextSize               = 15
toastLabel.TextColor3             = Color3.fromRGB(255, 210, 100)
toastLabel.TextStrokeTransparency = 0.45
toastLabel.Text                   = ""
toastLabel.ZIndex                 = 13
toastLabel.Parent                 = toast

local function showToast(text, color)
	toastLabel.Text       = text
	toastLabel.TextColor3 = color or Color3.fromRGB(255, 210, 100)
	toastStroke.Color     = color or Color3.fromRGB(200, 150, 50)
	toast.Visible         = true
	toast.BackgroundTransparency = 0.1
	toast.Position        = UDim2.new(0.5, 0, 0, SAFE_TOP + 126)
	TweenService:Create(toast,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, SAFE_TOP + 112) }):Play()
	task.delay(2.6, function()
		TweenService:Create(toast, TweenInfo.new(0.28),
			{ BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, SAFE_TOP + 100) }):Play()
		task.delay(0.35, function() toast.Visible = false end)
	end)
end

-- ── Visibility control ────────────────────────────────────────────────────────
local isInLanding = false

local function applyVisibility()
	isInLanding = player:GetAttribute("InLandingWorld") == true
	banner.Visible = false
	if not isInLanding then
		toast.Visible = false
	end
end

player:GetAttributeChangedSignal("InLandingWorld"):Connect(applyVisibility)
applyVisibility()

if event then
	event.OnClientEvent:Connect(function(kind, payload)
		if kind == "Start" then
			isInLanding = true
			banner.Visible = false
			toast.Visible = false
		elseif kind == "Finish" then
			isInLanding = false
			banner.Visible = false
			toast.Visible  = false
		end
	end)
end

-- Keep banner hidden when not in landing world
RunService.Heartbeat:Connect(function()
	local inLanding = player:GetAttribute("InLandingWorld") == true
	if banner.Visible then
		banner.Visible = false
	end
	if not inLanding and toast.Visible then
		toast.Visible = false
	end
end)
