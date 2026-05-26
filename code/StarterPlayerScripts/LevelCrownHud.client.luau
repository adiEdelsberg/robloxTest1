-- LevelCrownHud.client.luau
-- Crown badge (top-right, visible while in a level) + trophy widget (bottom-left, always visible).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService        = game:GetService("GuiService")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local currentOrder = nil
local SAFE_SIDE    = 8
local SAFE_BOTTOM  = GuiService:GetGuiInset().Y > 0 and 0 or 0

-- ── ScreenGui ──────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "LevelCrownHud"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 55
gui.Parent         = player:WaitForChild("PlayerGui")

-- ── Crown badge (top-right, single row: 👑  5  LEVEL 23) ─────────────────────
local container = Instance.new("Frame")
container.AnchorPoint         = Vector2.new(1, 0)
container.Size                = UDim2.new(0, 220, 0, 36)
container.Position            = UDim2.new(1, -20, 0, 12)
container.BackgroundTransparency = 1
container.Visible             = false
container.Parent              = gui


local badgeLayout = Instance.new("UIListLayout")
badgeLayout.FillDirection       = Enum.FillDirection.Horizontal
badgeLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
badgeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
badgeLayout.Padding             = UDim.new(0, 8)
badgeLayout.Parent              = container

local crownIcon = Instance.new("TextLabel")
crownIcon.Size                   = UDim2.new(0, 28, 0, 28)
crownIcon.BackgroundTransparency = 1
crownIcon.Text                   = "👑"
crownIcon.TextScaled             = true
crownIcon.Font                   = Enum.Font.GothamBlack
crownIcon.LayoutOrder            = 1
crownIcon.Parent                 = container

local crownScale = Instance.new("UIScale")
crownScale.Scale  = 1
crownScale.Parent = crownIcon

local countLabel = Instance.new("TextLabel")
countLabel.Size                   = UDim2.new(0, 46, 0, 28)
countLabel.BackgroundTransparency = 1
countLabel.Text                   = "0"
countLabel.TextColor3             = Color3.fromRGB(255, 235, 70)
countLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
countLabel.TextStrokeTransparency = 0.0
countLabel.Font                   = Enum.Font.GothamBlack
countLabel.TextScaled             = true
countLabel.LayoutOrder            = 2
countLabel.Parent                 = container

local levelLabel = Instance.new("TextLabel")
levelLabel.Size                   = UDim2.new(0, 90, 0, 28)
levelLabel.BackgroundTransparency = 1
levelLabel.Text                   = ""
levelLabel.TextColor3             = Color3.fromRGB(180, 220, 255)
levelLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
levelLabel.TextStrokeTransparency = 0.25
levelLabel.Font                   = Enum.Font.GothamBold
levelLabel.TextScaled             = true
levelLabel.LayoutOrder            = 3
levelLabel.Parent                 = container

-- ── Trophy widget (bottom-left, always visible, next to cash) ─────────────────
local trophyFrame = Instance.new("Frame")
trophyFrame.AnchorPoint         = Vector2.new(0, 1)
trophyFrame.Size                = UDim2.new(0, 120, 0, 36)
trophyFrame.Position            = UDim2.new(0, SAFE_SIDE, 1, -62)
trophyFrame.BackgroundTransparency = 1
trophyFrame.Parent              = gui

local trophyIconScale = Instance.new("UIScale")
trophyIconScale.Scale  = 1
trophyIconScale.Parent = trophyIcon

local trophyLayout = Instance.new("UIListLayout")
trophyLayout.FillDirection       = Enum.FillDirection.Horizontal
trophyLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
trophyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
trophyLayout.Padding             = UDim.new(0, 6)
trophyLayout.Parent              = trophyFrame

local trophyIcon = Instance.new("TextLabel")
trophyIcon.Size                   = UDim2.new(0, 28, 0, 28)
trophyIcon.BackgroundTransparency = 1
trophyIcon.Text                   = "🏆"
trophyIcon.TextScaled             = true
trophyIcon.Font                   = Enum.Font.GothamBlack
trophyIcon.LayoutOrder            = 1
trophyIcon.Parent                 = trophyFrame

local trophyCount = Instance.new("TextLabel")
trophyCount.Size                   = UDim2.new(0, 60, 0, 28)
trophyCount.BackgroundTransparency = 1
trophyCount.Text                   = "1"
trophyCount.TextColor3             = Color3.fromRGB(255, 235, 70)
trophyCount.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
trophyCount.TextStrokeTransparency = 0.0
trophyCount.Font                   = Enum.Font.GothamBlack
trophyCount.TextScaled             = true
trophyCount.LayoutOrder            = 2
trophyCount.Parent                 = trophyFrame

-- ── Animation ─────────────────────────────────────────────────────────────────
local CROWN_NORMAL_COLOR  = Color3.fromRGB(255, 235, 70)
local CROWN_FLASH_COLOR   = Color3.fromRGB(255, 255, 255)
local TROPHY_NORMAL_COLOR = Color3.fromRGB(255, 235, 70)
local TROPHY_FLASH_COLOR  = Color3.fromRGB(255, 255, 255)

local function pulseBadge(scaleObj, label, normalColor, flashColor)
	local DURATION   = 5
	local PULSE_TIME = 0.35
	local deadline   = tick() + DURATION

	task.spawn(function()
		while tick() < deadline do
			-- grow + flash white
			TweenService:Create(scaleObj, TweenInfo.new(PULSE_TIME * 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.3 }):Play()
			TweenService:Create(label,    TweenInfo.new(PULSE_TIME * 0.4), { TextColor3 = flashColor }):Play()
			task.wait(PULSE_TIME * 0.4)
			-- shrink back + restore color
			TweenService:Create(scaleObj, TweenInfo.new(PULSE_TIME * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			TweenService:Create(label,    TweenInfo.new(PULSE_TIME * 0.6), { TextColor3 = normalColor }):Play()
			task.wait(PULSE_TIME * 0.6)
		end
		-- ensure clean state
		scaleObj.Scale      = 1
		label.TextColor3    = normalColor
	end)
end

-- ── Helpers ────────────────────────────────────────────────────────────────────
local function getCrownCount(order)
	return player:GetAttribute("LevelCrown_" .. tostring(order)) or 0
end

local prevTrophyValue = nil

local function refreshTrophy(animate)
	local stats    = player:FindFirstChild("leaderstats")
	local trophies = stats and stats:FindFirstChild("Trophies")
	local val = trophies and trophies.Value or 1
	trophyCount.Text = tostring(val)
	if animate and prevTrophyValue and val ~= prevTrophyValue then
		pulseBadge(trophyIconScale, trophyCount, TROPHY_NORMAL_COLOR, TROPHY_FLASH_COLOR)
	end
	prevTrophyValue = val
end

local function playEarnAnimation(newCount)
	countLabel.Text = tostring(newCount)
	pulseBadge(crownScale, countLabel, CROWN_NORMAL_COLOR, CROWN_FLASH_COLOR)
	refreshTrophy(true)
end

local function showBadge(order)
	currentOrder     = order
	countLabel.Text  = tostring(getCrownCount(order))
	levelLabel.Text  = "LEVEL " .. tostring(order)
	crownScale.Scale = 1
	container.Visible = true
end

local function hideBadge()
	currentOrder      = nil
	container.Visible = false
end

-- Keep trophy count fresh whenever Trophies leaderstats changes
task.spawn(function()
	player:WaitForChild("leaderstats", 30)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	local trophies = stats:WaitForChild("Trophies", 15)
	if trophies then
		prevTrophyValue = trophies.Value
		trophies.Changed:Connect(function() refreshTrophy(true) end)
		refreshTrophy(false)
	end
end)

-- ── WorldHud + StageReward events ─────────────────────────────────────────────
task.spawn(function()
	local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end
	local worldHudEvent = gameEvents:WaitForChild("WorldHud", 30)
	if not worldHudEvent then return end

	worldHudEvent.OnClientEvent:Connect(function(eventType, a)
		if eventType == "Enter" then
			local order = WorldOrder.getOrder(a)
			if order then showBadge(order) end
		elseif eventType == "Exit" or eventType == "GameComplete" then
			hideBadge()
		end
	end)

	local stageRewardEvent = gameEvents:WaitForChild("StageReward", 30)
	if stageRewardEvent then
		stageRewardEvent.OnClientEvent:Connect(function(worldName)
			local order = WorldOrder.getOrder(worldName)
			if not order then return end
			if not container.Visible or currentOrder ~= order then
				showBadge(order)
			end
			task.defer(function()
				playEarnAnimation(getCrownCount(order))
			end)
		end)
	end
end)
