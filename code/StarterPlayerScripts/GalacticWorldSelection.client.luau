-- GalacticWorldSelection.client.luau
-- Polished client-side Galactic Worlds level selection screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local openEvent = gameEvents:WaitForChild("OpenGalacticWorldSelection")
local launchEvent = gameEvents:WaitForChild("LaunchGalacticWorldSelection")
local selectedOrder = nil
local selectedData = nil
local cards = {}

local gui = Instance.new("ScreenGui")
gui.Name = "GalacticWorldSelectionGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local shade = Instance.new("Frame")
shade.Size = UDim2.new(1, 0, 1, 0)
shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shade.BackgroundTransparency = 0.38
shade.BorderSizePixel = 0
shade.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.new(0.88, 0, 0.76, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(5, 8, 18)
panel.BorderSizePixel = 0
panel.Parent = shade
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(105, 245, 255)
panelStroke.Thickness = 3
panelStroke.Transparency = 0.12
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 0, 54)
title.Position = UDim2.new(0, 24, 0, 14)
title.BackgroundTransparency = 1
title.Text = "GALACTIC WORLDS"
title.TextColor3 = Color3.fromRGB(130, 245, 255)
title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
title.TextStrokeTransparency = 0.15
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -48, 0, 24)
subtitle.Position = UDim2.new(0, 24, 0, 66)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Tap a level number, then confirm launch."
subtitle.TextColor3 = Color3.fromRGB(220, 230, 255)
subtitle.Font = Enum.Font.GothamBold
subtitle.TextScaled = true
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local selectedBox = Instance.new("Frame")
selectedBox.Size = UDim2.new(1, -48, 0, 58)
selectedBox.Position = UDim2.new(0, 24, 0, 96)
selectedBox.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
selectedBox.BorderSizePixel = 0
selectedBox.Parent = panel
Instance.new("UICorner", selectedBox).CornerRadius = UDim.new(0, 10)

local selectedStroke = Instance.new("UIStroke")
selectedStroke.Color = Color3.fromRGB(255, 225, 90)
selectedStroke.Thickness = 2
selectedStroke.Transparency = 0.22
selectedStroke.Parent = selectedBox

local selectedText = Instance.new("TextLabel")
selectedText.Size = UDim2.new(1, -190, 1, 0)
selectedText.Position = UDim2.new(0, 18, 0, 0)
selectedText.BackgroundTransparency = 1
selectedText.Text = "SELECT A LEVEL NUMBER"
selectedText.TextColor3 = Color3.fromRGB(235, 245, 255)
selectedText.TextStrokeTransparency = 0.55
selectedText.Font = Enum.Font.GothamBlack
selectedText.TextScaled = true
selectedText.TextXAlignment = Enum.TextXAlignment.Left
selectedText.Parent = selectedBox

local confirm = Instance.new("TextButton")
confirm.Size = UDim2.new(0, 154, 0, 42)
confirm.Position = UDim2.new(1, -168, 0.5, -21)
confirm.BackgroundColor3 = Color3.fromRGB(42, 70, 92)
confirm.BorderSizePixel = 0
confirm.Text = "CONFIRM"
confirm.TextColor3 = Color3.fromRGB(170, 180, 190)
confirm.Font = Enum.Font.GothamBlack
confirm.TextScaled = true
confirm.AutoButtonColor = false
confirm.Parent = selectedBox
Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 9)

local confirmStroke = Instance.new("UIStroke")
confirmStroke.Color = Color3.fromRGB(90, 120, 140)
confirmStroke.Thickness = 1.5
confirmStroke.Transparency = 0.2
confirmStroke.Parent = confirm

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 44, 0, 44)
close.Position = UDim2.new(1, -58, 0, 18)
close.BackgroundColor3 = Color3.fromRGB(26, 30, 48)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBlack
close.TextSize = 24
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 10)

local scroller = Instance.new("ScrollingFrame")
scroller.Size = UDim2.new(1, -48, 1, -184)
scroller.Position = UDim2.new(0, 24, 0, 166)
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.ScrollBarThickness = 8
scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
scroller.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 112, 0, 118)
grid.CellPadding = UDim2.new(0, 12, 0, 12)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = scroller

local function setConfirmEnabled(enabled)
	confirm.AutoButtonColor = enabled
	confirm.BackgroundColor3 = enabled and Color3.fromRGB(255, 210, 70) or Color3.fromRGB(42, 70, 92)
	confirm.TextColor3 = enabled and Color3.fromRGB(12, 14, 22) or Color3.fromRGB(170, 180, 190)
	confirmStroke.Color = enabled and Color3.fromRGB(255, 250, 180) or Color3.fromRGB(90, 120, 140)
end

local function refreshSelection()
	if selectedOrder and selectedData then
		selectedText.Text = ("LEVEL %d  -  %s"):format(selectedOrder, string.upper(selectedData.name or "WORLD"))
	else
		selectedText.Text = "SELECT A LEVEL NUMBER"
	end
	setConfirmEnabled(selectedOrder ~= nil)
	for order, card in cards do
		local isSelected = order == selectedOrder
		card.BackgroundColor3 = isSelected and Color3.fromRGB(45, 35, 12) or Color3.fromRGB(13, 18, 34)
		local stroke = card:FindFirstChild("SelectionStroke")
		if stroke and stroke:IsA("UIStroke") then
			stroke.Color = isSelected and Color3.fromRGB(255, 230, 90) or Color3.fromRGB(95, 235, 255)
			stroke.Thickness = isSelected and 3 or 1.5
			stroke.Transparency = isSelected and 0.02 or 0.32
		end
	end
end

local function clearCards()
	for _, child in scroller:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	table.clear(cards)
end

local function addCard(order, data)
	local card = Instance.new("TextButton")
	card.LayoutOrder = order
	card.BackgroundColor3 = Color3.fromRGB(13, 18, 34)
	card.BorderSizePixel = 0
	card.Text = tostring(order)
	card.TextColor3 = Color3.fromRGB(255, 230, 90)
	card.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	card.TextStrokeTransparency = 0.08
	card.Font = Enum.Font.GothamBlack
	card.TextScaled = true
	card.AutoButtonColor = true
	card.Parent = scroller
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	cards[order] = card

	local stroke = Instance.new("UIStroke")
	stroke.Name = "SelectionStroke"
	stroke.Color = Color3.fromRGB(95, 235, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.32
	stroke.Parent = card

	local numberPadding = Instance.new("UIPadding")
	numberPadding.PaddingLeft = UDim.new(0, 10)
	numberPadding.PaddingRight = UDim.new(0, 10)
	numberPadding.PaddingTop = UDim.new(0, 8)
	numberPadding.PaddingBottom = UDim.new(0, 40)
	numberPadding.Parent = card

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -12, 0, 32)
	name.Position = UDim2.new(0, 6, 1, -38)
	name.BackgroundTransparency = 1
	name.Text = string.upper(data.name or "WORLD")
	name.TextColor3 = Color3.fromRGB(235, 245, 255)
	name.TextStrokeTransparency = 0.5
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.Parent = card

	local action = Instance.new("TextLabel")
	action.Size = UDim2.new(1, -12, 0, 14)
	action.Position = UDim2.new(0, 6, 1, -15)
	action.BackgroundTransparency = 1
	action.Text = "TAP NUMBER"
	action.TextColor3 = Color3.fromRGB(120, 245, 255)
	action.Font = Enum.Font.GothamBold
	action.TextScaled = true
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Parent = card

	card.Activated:Connect(function()
		selectedOrder = order
		selectedData = data
		refreshSelection()
	end)
end

local function openSelector(worlds)
	clearCards()
	selectedOrder = nil
	selectedData = nil
	for order = 20, 40 do
		local data = worlds[order]
		if data then
			addCard(order, data)
		end
	end
	refreshSelection()
	task.defer(function()
		scroller.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 16)
	end)
	gui.Enabled = true
	panel.Size = UDim2.new(0.82, 0, 0.68, 0)
	TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0.88, 0, 0.76, 0) }):Play()
end

close.Activated:Connect(function()
	gui.Enabled = false
end)

confirm.Activated:Connect(function()
	if not selectedOrder then return end
	gui.Enabled = false
	launchEvent:FireServer(selectedOrder)
end)

shade.InputBegan:Connect(function(input)
	if input.UserInputType.Name == "MouseButton1" or input.UserInputType.Name == "Touch" then
		if input.Position.X < panel.AbsolutePosition.X or input.Position.X > panel.AbsolutePosition.X + panel.AbsoluteSize.X
			or input.Position.Y < panel.AbsolutePosition.Y or input.Position.Y > panel.AbsolutePosition.Y + panel.AbsoluteSize.Y then
			gui.Enabled = false
		end
	end
end)

openEvent.OnClientEvent:Connect(openSelector)
