local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local player = Players.LocalPlayer
local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isConsole     = UserInputService.GamepadEnabled and not UserInputService.MouseEnabled

local SAFE_TOP    = GuiService:GetGuiInset().Y + (isConsole and 20 or 0)
local SAFE_BOTTOM = isConsole and 20 or 0
local SAFE_SIDE   = isConsole and 20 or 8
local SHOP_PRICES = Balance.Shop.ItemPrices

local purchaseEvent     = ReplicatedStorage:WaitForChild("ShopEvents"):WaitForChild("Purchase")
local purchaseResultEvt = ReplicatedStorage:WaitForChild("ShopEvents"):WaitForChild("PurchaseResult")

-- Items embedded on client so shop opens without server event
local ITEMS = {
	{ id="speed1", name="Speed Boost I",   desc="+5 walk speed",  price=SHOP_PRICES.speed1, attrName="SpeedBoost", tierValue=1, requiresTier=0, iconKind="speed", iconColor=Color3.fromRGB(80, 255, 130), iconAccent=Color3.fromRGB(250, 255, 120) },
	{ id="speed2", name="Speed Boost II",  desc="+10 walk speed", price=SHOP_PRICES.speed2, attrName="SpeedBoost", tierValue=2, requiresTier=1, iconKind="speed", iconColor=Color3.fromRGB(65, 240, 115), iconAccent=Color3.fromRGB(255, 245, 90) },
	{ id="speed3", name="Speed Boost III", desc="+16 walk speed", price=SHOP_PRICES.speed3, attrName="SpeedBoost", tierValue=3, requiresTier=2, iconKind="speed", iconColor=Color3.fromRGB(45, 225, 95),  iconAccent=Color3.fromRGB(255, 235, 70) },
	{ id="speed4", name="Speed Boost IV",  desc="+23 walk speed", price=SHOP_PRICES.speed4, attrName="SpeedBoost", tierValue=4, requiresTier=3, iconKind="speed", iconColor=Color3.fromRGB(30, 205, 80),  iconAccent=Color3.fromRGB(255, 225, 55) },
	{ id="speed5", name="Speed Boost V",   desc="+31 walk speed", price=SHOP_PRICES.speed5, attrName="SpeedBoost", tierValue=5, requiresTier=4, iconKind="speed", iconColor=Color3.fromRGB(20, 185, 65),  iconAccent=Color3.fromRGB(255, 215, 45) },
	{ id="jump1",  name="Jump Boost I",    desc="Higher jump",    price=SHOP_PRICES.jump1, attrName="JumpBoost",  tierValue=1, requiresTier=0, iconKind="jump",  iconColor=Color3.fromRGB(80, 210, 255), iconAccent=Color3.fromRGB(255, 255, 255) },
	{ id="jump2",  name="Jump Boost II",   desc="Super jump",     price=SHOP_PRICES.jump2, attrName="JumpBoost",  tierValue=2, requiresTier=1, iconKind="jump",  iconColor=Color3.fromRGB(70, 180, 255), iconAccent=Color3.fromRGB(230, 255, 255) },
	{ id="jump3",  name="Jump Boost III",  desc="Mega jump",      price=SHOP_PRICES.jump3, attrName="JumpBoost",  tierValue=3, requiresTier=2, iconKind="jump",  iconColor=Color3.fromRGB(70, 150, 255), iconAccent=Color3.fromRGB(210, 255, 255) },
	{ id="jump4",  name="Jump Boost IV",   desc="Ultra jump",     price=SHOP_PRICES.jump4, attrName="JumpBoost",  tierValue=4, requiresTier=3, iconKind="jump",  iconColor=Color3.fromRGB(90, 120, 255), iconAccent=Color3.fromRGB(200, 245, 255) },
	{ id="jump5",  name="Jump Boost V",    desc="Sky jump",       price=SHOP_PRICES.jump5, attrName="JumpBoost",  tierValue=5, requiresTier=4, iconKind="jump",  iconColor=Color3.fromRGB(120, 90, 255), iconAccent=Color3.fromRGB(220, 235, 255) },
}
local ITEM_MAP = {}
for _, item in ipairs(ITEMS) do ITEM_MAP[item.id] = item end

local function connectButtonPress(button, callback)
	local lastPress = 0
	local function fire()
		local now = os.clock()
		if now - lastPress < 0.28 then return end
		lastPress = now
		callback()
	end

	button.Activated:Connect(fire)
	button.MouseButton1Click:Connect(fire)
	button.TouchTap:Connect(fire)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			fire()
		end
	end)
end

-- =============================================
-- SHOP GUI
-- =============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ShopGui"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled        = false
screenGui.DisplayOrder   = 60
screenGui.Parent         = player.PlayerGui

-- Forward declaration so close button wiring below can reference it
local closeShop
local openShop

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size                  = UDim2.new(1,0,1,0)
overlay.BackgroundColor3      = Color3.new(0,0,0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel       = 0
overlay.Parent                = screenGui

-- Main panel
local panel = Instance.new("Frame")
panel.AnchorPoint           = Vector2.new(0.5, 0.5)
panel.Size                  = isTouchDevice and UDim2.new(0.97, 0, 0.88, 0) or isConsole and UDim2.new(0.88, 0, 0.84, 0) or UDim2.new(0, 520, 0, 480)
panel.Position              = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3      = Color3.fromRGB(20, 20, 30)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel       = 0
panel.Parent                = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Header bar
local header = Instance.new("Frame")
header.Size             = UDim2.new(1,0,0,52)
header.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
header.BorderSizePixel  = 0
header.Parent           = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)
local headerFill = Instance.new("Frame")
headerFill.Size             = UDim2.new(1,0,0.5,0)
headerFill.Position         = UDim2.new(0,0,0.5,0)
headerFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
headerFill.BorderSizePixel  = 0
headerFill.Parent           = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                   = UDim2.new(1,-60,1,0)
titleLabel.Position               = UDim2.new(0,12,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                   = "UPGRADE SHOP"
titleLabel.Font                   = Enum.Font.GothamBold
titleLabel.TextSize               = 22
titleLabel.TextColor3             = Color3.new(0,0,0)
titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
titleLabel.Parent                 = header

local cashLabel = Instance.new("TextLabel")
cashLabel.Size                   = UDim2.new(0, 160, 1, 0)
cashLabel.Position               = UDim2.new(1,-220,0,0)
cashLabel.BackgroundTransparency = 1
cashLabel.Font                   = Enum.Font.GothamBold
cashLabel.TextSize               = 18
cashLabel.TextColor3             = Color3.new(0,0,0)
cashLabel.TextXAlignment         = Enum.TextXAlignment.Right
cashLabel.Text                   = "$0"
cashLabel.Parent                 = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0,38,0,38)
closeBtn.Position         = UDim2.new(1,-46,0,7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = "X"
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 20
closeBtn.TextColor3       = Color3.new(1,1,1)
closeBtn.Parent           = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

connectButtonPress(closeBtn, function() closeShop() end)
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		closeShop()
	end
end)

-- Gamepad hint in header (console only)
if isConsole then
	local padHint = Instance.new("TextLabel")
	padHint.Size                   = UDim2.new(0, 160, 0, 20)
	padHint.Position               = UDim2.new(0, 12, 1, -22)
	padHint.BackgroundTransparency = 1
	padHint.Font                   = Enum.Font.Gotham
	padHint.TextSize               = 11
	padHint.TextColor3             = Color3.fromRGB(40, 20, 0)
	padHint.Text                   = "[A] Buy  [B] Close  [Y] Open"
	padHint.TextXAlignment         = Enum.TextXAlignment.Left
	padHint.Parent                 = header
end

-- Scrolling item list
local scroll = Instance.new("ScrollingFrame")
scroll.Size                  = UDim2.new(1,-20,1,-72)
scroll.Position              = UDim2.new(0,10,0,62)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel       = 0
scroll.ScrollBarThickness    = isTouchDevice and 10 or 6
scroll.ScrollBarImageColor3  = Color3.fromRGB(255,200,0)
scroll.CanvasSize            = UDim2.new(0,0,0,0)
scroll.SelectionGroup        = true
scroll.Parent                = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
listLayout.Padding      = UDim.new(0, 8)
listLayout.Parent       = scroll

local listPad = Instance.new("UIPadding")
listPad.PaddingTop   = UDim.new(0, 4)
listPad.PaddingBottom = UDim.new(0, 4)
listPad.Parent        = scroll

-- Feedback toast
local toast = Instance.new("TextLabel")
toast.Size                   = UDim2.new(0, 360, 0, 42)
toast.Position               = UDim2.new(0.5,-180,1,-54)
toast.BackgroundColor3       = Color3.fromRGB(30,180,30)
toast.BackgroundTransparency = 0.15
toast.BorderSizePixel        = 0
toast.Font                   = Enum.Font.GothamBold
toast.TextSize               = 16
toast.TextColor3             = Color3.new(1,1,1)
toast.TextStrokeTransparency = 0.5
toast.Text                   = ""
toast.Visible                = false
toast.Parent                 = panel
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

local function showToast(msg, success)
	toast.Text             = msg
	toast.BackgroundColor3 = success and Color3.fromRGB(30,180,30) or Color3.fromRGB(180,40,40)
	toast.Visible          = true
	task.delay(2.5, function() toast.Visible = false end)
end

-- =============================================
-- BUILD ITEM CARDS
-- =============================================
local itemCards = {}

local function addCorner(guiObject, radius)
	Instance.new("UICorner", guiObject).CornerRadius = UDim.new(0, radius)
end

local function addStroke(guiObject, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.Parent = guiObject
	return stroke
end

local function addIconShape(parent, size, position, color, radius)
	local shape = Instance.new("Frame")
	shape.Size = size
	shape.Position = position
	shape.BackgroundColor3 = color
	shape.BorderSizePixel = 0
	shape.Parent = parent
	addCorner(shape, radius)
	return shape
end

local function makeBoostIcon(parent, item, size, position)
	local accent = item.iconAccent or Color3.new(1, 1, 1)
	local icon = Instance.new("Frame")
	icon.Size = size
	icon.Position = position
	icon.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	icon.BackgroundTransparency = 0.02
	icon.BorderSizePixel = 0
	icon.Parent = parent
	addCorner(icon, 10)
	addStroke(icon, item.iconColor, 2, 0.18)

	local glow = addIconShape(icon, UDim2.new(1, -8, 1, -8), UDim2.new(0, 4, 0, 4), item.iconColor, 8)
	glow.BackgroundTransparency = 0.74

	if item.iconKind == "damage" then
		addIconShape(icon, UDim2.new(0.48, 0, 0.48, 0), UDim2.new(0.17, 0, 0.27, 0), item.iconColor, 99)
		addIconShape(icon, UDim2.new(0.18, 0, 0.18, 0), UDim2.new(0.27, 0, 0.34, 0), accent, 99)
		for i = 1, 3 do
			local spark = addIconShape(icon, UDim2.new(0.16, 0, 0.06, 0), UDim2.new(0.63, 0, 0.24 + i * 0.13, 0), accent, 6)
			spark.Rotation = -24
		end
	elseif item.iconKind == "throw" then
		addIconShape(icon, UDim2.new(0.52, 0, 0.14, 0), UDim2.new(0.18, 0, 0.44, 0), item.iconColor, 8)
		local tip = addIconShape(icon, UDim2.new(0.25, 0, 0.25, 0), UDim2.new(0.58, 0, 0.39, 0), accent, 5)
		tip.Rotation = 45
		for i = 1, 2 do
			local trail = addIconShape(icon, UDim2.new(0.25, 0, 0.05, 0), UDim2.new(0.12, 0, 0.31 + i * 0.2, 0), accent, 6)
			trail.BackgroundTransparency = 0.2
		end
	elseif item.iconKind == "jump" then
		addIconShape(icon, UDim2.new(0.36, 0, 0.16, 0), UDim2.new(0.33, 0, 0.67, 0), item.iconColor, 7)
		addIconShape(icon, UDim2.new(0.13, 0, 0.37, 0), UDim2.new(0.45, 0, 0.31, 0), accent, 7)
		local arrowA = addIconShape(icon, UDim2.new(0.18, 0, 0.07, 0), UDim2.new(0.42, 0, 0.27, 0), accent, 6)
		arrowA.Rotation = 45
		local arrowB = addIconShape(icon, UDim2.new(0.18, 0, 0.07, 0), UDim2.new(0.50, 0, 0.27, 0), accent, 6)
		arrowB.Rotation = -45
	elseif item.iconKind == "speed" then
		addIconShape(icon, UDim2.new(0.5, 0, 0.22, 0), UDim2.new(0.31, 0, 0.48, 0), item.iconColor, 7)
		addIconShape(icon, UDim2.new(0.23, 0, 0.17, 0), UDim2.new(0.28, 0, 0.36, 0), accent, 7)
		addIconShape(icon, UDim2.new(0.18, 0, 0.06, 0), UDim2.new(0.13, 0, 0.39, 0), accent, 6)
		addIconShape(icon, UDim2.new(0.22, 0, 0.06, 0), UDim2.new(0.08, 0, 0.56, 0), accent, 6)
	elseif item.iconKind == "money" then
		addIconShape(icon, UDim2.new(0.42, 0, 0.5, 0), UDim2.new(0.29, 0, 0.24, 0), item.iconColor, 8)
		local band = addIconShape(icon, UDim2.new(0.42, 0, 0.12, 0), UDim2.new(0.29, 0, 0.43, 0), accent, 5)
		band.BackgroundTransparency = 0.05
		local coin = addIconShape(icon, UDim2.new(0.24, 0, 0.24, 0), UDim2.new(0.54, 0, 0.2, 0), accent, 99)
		addStroke(coin, Color3.fromRGB(255, 255, 190), 1, 0.25)
	elseif item.iconKind == "pickup" then
		local core = addIconShape(icon, UDim2.new(0.24, 0, 0.24, 0), UDim2.new(0.38, 0, 0.38, 0), item.iconColor, 99)
		addStroke(core, accent, 2, 0.1)
		for i = 1, 3 do
			local ring = addIconShape(icon, UDim2.new(0.25 + i * 0.16, 0, 0.25 + i * 0.16, 0), UDim2.new(0.375 - i * 0.08, 0, 0.375 - i * 0.08, 0), accent, 99)
			ring.BackgroundTransparency = 1
			addStroke(ring, accent, 1, 0.12 + i * 0.18)
		end
	else
		addIconShape(icon, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.25, 0, 0.25, 0), item.iconColor, 99)
	end

	return icon
end

local firstBuyBtn = nil  -- set during buildCards, used for gamepad focus

local function buildCards()
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end
	itemCards = {}
	for order, item in ipairs(ITEMS) do
		local card = Instance.new("Frame")
		card.Size             = UDim2.new(1,-12,0,72)
		card.BackgroundColor3 = Color3.fromRGB(35,35,50)
		card.BorderSizePixel  = 0
		card.LayoutOrder      = order
		card.Parent           = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		makeBoostIcon(card, item, UDim2.new(0, 46, 0, 46), UDim2.new(0, 8, 0, 13))

		local nameL = Instance.new("TextLabel")
		nameL.Size                   = UDim2.new(1,-188,0,28)
		nameL.Position               = UDim2.new(0,62,0,8)
		nameL.BackgroundTransparency = 1
		nameL.Font                   = Enum.Font.GothamBold
		nameL.TextSize               = 17
		nameL.TextColor3             = Color3.new(1,1,1)
		nameL.TextXAlignment         = Enum.TextXAlignment.Left
		nameL.Text                   = item.name
		nameL.Parent                 = card

		local descL = Instance.new("TextLabel")
		descL.Size                   = UDim2.new(1,-188,0,22)
		descL.Position               = UDim2.new(0,62,0,36)
		descL.BackgroundTransparency = 1
		descL.Font                   = Enum.Font.Gotham
		descL.TextSize               = 13
		descL.TextColor3             = Color3.fromRGB(180,180,200)
		descL.TextXAlignment         = Enum.TextXAlignment.Left
		descL.Text                   = item.desc
		descL.Parent                 = card

		local priceL = Instance.new("TextLabel")
		priceL.Size                   = UDim2.new(0,70,0,28)
		priceL.Position               = UDim2.new(1,-130,0,8)
		priceL.BackgroundTransparency = 1
		priceL.Font                   = Enum.Font.GothamBold
		priceL.TextSize               = 16
		priceL.TextColor3             = Color3.fromRGB(255,215,0)
		priceL.Text                   = "$" .. item.price
		priceL.Parent                 = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size             = isTouchDevice and UDim2.new(0,88,0,44) or UDim2.new(0,80,0,34)
		buyBtn.Position         = isTouchDevice and UDim2.new(1,-100,0,24) or UDim2.new(1,-92,0,30)
		buyBtn.BackgroundColor3 = Color3.fromRGB(50,180,50)
		buyBtn.BorderSizePixel  = 0
		buyBtn.Font             = Enum.Font.GothamBold
		buyBtn.TextSize         = 15
		buyBtn.TextColor3       = Color3.new(1,1,1)
		buyBtn.Text             = "BUY"
		buyBtn.Selectable       = true
		buyBtn.SelectionOrder   = order
		buyBtn.Parent           = card
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

		connectButtonPress(buyBtn, function()
			purchaseEvent:FireServer(item.id)
		end)

		itemCards[item.id] = { card=card, buyBtn=buyBtn }
		if not firstBuyBtn then firstBuyBtn = buyBtn end
	end
	listLayout:ApplyLayout()
	scroll.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 12)
end

-- =============================================
-- REFRESH cards
-- =============================================
local function refreshCards()
	local stats = player:FindFirstChild("leaderstats")
	local cash  = stats and stats:FindFirstChild("Cash")
	local funds = cash and cash.Value or 0
	cashLabel.Text = "$" .. tostring(funds)

	for _, item in ipairs(ITEMS) do
		local entry = itemCards[item.id]
		if not entry then continue end
		local currentTier = player:GetAttribute(item.attrName) or 0
		local owned       = currentTier >= item.tierValue
		local unlocked    = currentTier >= item.requiresTier
		local affordable  = funds >= item.price
		local btn = entry.buyBtn
		if owned then
			btn.Text             = "OWNED"
			btn.BackgroundColor3 = Color3.fromRGB(60,60,80)
			btn.Active           = false
			entry.card.BackgroundColor3 = Color3.fromRGB(28,28,45)
		elseif not unlocked then
			btn.Text             = "LOCKED"
			btn.BackgroundColor3 = Color3.fromRGB(70,70,90)
			btn.Active           = true
			entry.card.BackgroundColor3 = Color3.fromRGB(30,30,42)
		elseif affordable then
			btn.Text             = "BUY"
			btn.BackgroundColor3 = Color3.fromRGB(50,180,50)
			btn.Active           = true
			entry.card.BackgroundColor3 = Color3.fromRGB(35,35,50)
		else
			btn.Text             = "BUY"
			btn.BackgroundColor3 = Color3.fromRGB(100,80,30)
			btn.Active           = true
			entry.card.BackgroundColor3 = Color3.fromRGB(35,30,35)
		end
	end
end

openShop = function()
	buildCards()
	refreshCards()
	screenGui.Enabled = true
	if isConsole and firstBuyBtn then
		GuiService.SelectedObject = firstBuyBtn
	end
end

closeShop = function()
	screenGui.Enabled = false
	if isConsole then
		GuiService.SelectedObject = nil
	end
end

-- =============================================
-- HUD SHOP BUTTON (always visible)
-- =============================================
local hudGui = Instance.new("ScreenGui")
hudGui.Name           = "ShopHUD"
hudGui.ResetOnSpawn   = false
hudGui.IgnoreGuiInset = true
hudGui.DisplayOrder   = 10
hudGui.Parent         = player.PlayerGui

local shopBtn = Instance.new("TextButton")
shopBtn.Size             = isTouchDevice and UDim2.new(0, 90, 0, 48) or UDim2.new(0, 82, 0, 36)
shopBtn.Position         = UDim2.new(0, SAFE_SIDE, 0, SAFE_TOP + 14)   -- top-left, below Roblox topbar
shopBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
shopBtn.BorderSizePixel  = 0
shopBtn.Font             = Enum.Font.GothamBold
shopBtn.TextSize         = isTouchDevice and 19 or 17
shopBtn.TextColor3       = Color3.new(0, 0, 0)
shopBtn.Text             = isConsole and "SHOP [Y]" or "SHOP"
shopBtn.Selectable       = true
shopBtn.Visible          = false
shopBtn.Parent           = hudGui
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 10)

connectButtonPress(shopBtn, openShop)

-- Gamepad: Y to open, B to close
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.ButtonY then
		if screenGui.Enabled then closeShop() else openShop() end
	elseif input.KeyCode == Enum.KeyCode.ButtonB and screenGui.Enabled then
		closeShop()
	end
end)

-- =============================================
-- CASH HUD  (no background, no border — text only)
-- =============================================
local cashBaseY = isTouchDevice and -(120 + SAFE_BOTTOM) or -(60 + SAFE_BOTTOM)

-- Invisible anchor frame (no bg, no border)
local cashHud = Instance.new("Frame")
cashHud.Name                   = "CashHud"
cashHud.Size                   = UDim2.new(0, 200, 0, 54)
cashHud.Position               = UDim2.new(0, SAFE_SIDE, 1, cashBaseY)
cashHud.BackgroundTransparency = 1
cashHud.BorderSizePixel        = 0
cashHud.Parent                 = hudGui

-- "$" symbol — large, gold
local dollarLbl = Instance.new("TextLabel")
dollarLbl.Size                   = UDim2.new(0, 36, 1, 0)
dollarLbl.Position               = UDim2.new(0, 0, 0, 0)
dollarLbl.BackgroundTransparency = 1
dollarLbl.Text                   = "$"
dollarLbl.Font                   = Enum.Font.GothamBlack
dollarLbl.TextScaled             = true
dollarLbl.TextColor3             = Color3.fromRGB(255, 210, 30)
dollarLbl.TextStrokeTransparency = 0.25
dollarLbl.TextStrokeColor3       = Color3.fromRGB(120, 80, 0)
dollarLbl.ZIndex                 = 5
dollarLbl.Parent                 = cashHud

-- Value number — white/cream, big
local cashLabel2 = Instance.new("TextLabel")
cashLabel2.Name                   = "CashValueLabel"
cashLabel2.Size                   = UDim2.new(1, -38, 1, 0)
cashLabel2.Position               = UDim2.new(0, 38, 0, 0)
cashLabel2.BackgroundTransparency = 1
cashLabel2.Text                   = "0"
cashLabel2.Font                   = Enum.Font.GothamBlack
cashLabel2.TextScaled             = true
cashLabel2.TextColor3             = Color3.fromRGB(255, 245, 200)
cashLabel2.TextStrokeTransparency = 0.2
cashLabel2.TextStrokeColor3       = Color3.fromRGB(100, 70, 0)
cashLabel2.TextXAlignment         = Enum.TextXAlignment.Left
cashLabel2.ZIndex                 = 5
cashLabel2.Parent                 = cashHud

-- =============================================
-- BOUNCING DOLLAR PARTICLES
-- =============================================
local function spawnDollarParticles(count)
	for i = 1, count do
		task.delay((i - 1) * 0.06, function()
			local lbl = Instance.new("TextLabel")
			lbl.Size                   = UDim2.new(0, 32, 0, 32)
			lbl.BackgroundTransparency = 1
			lbl.Text                   = "$"
			lbl.Font                   = Enum.Font.GothamBlack
			lbl.TextScaled             = true
			lbl.TextColor3             = Color3.fromRGB(255, 220, 40)
			lbl.TextStrokeTransparency = 0.2
			lbl.TextStrokeColor3       = Color3.fromRGB(120, 80, 0)
			lbl.ZIndex                 = 30
			lbl.Parent                 = hudGui

			-- Random spread around the cash hud
			local startX = SAFE_SIDE + math.random(-10, 60)
			local startY = cashBaseY + math.random(-10, 10)
			lbl.Position = UDim2.new(0, startX, 1, startY)

			-- Phase 1: jump up with random horizontal drift
			local targetX = startX + math.random(-40, 40)
			local jumpY   = startY - math.random(50, 100)
			TweenService:Create(lbl,
				TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0, targetX, 1, jumpY) }
			):Play()
			-- Scale up on jump
			TweenService:Create(lbl,
				TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 44, 0, 44) }
			):Play()

			-- Phase 2: fall down + fade
			task.delay(0.3, function()
				TweenService:Create(lbl,
					TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						Position        = UDim2.new(0, targetX, 1, startY + math.random(10, 30)),
						TextTransparency = 1,
						TextStrokeTransparency = 1,
						Size             = UDim2.new(0, 20, 0, 20),
					}
				):Play()
				task.delay(0.5, function() lbl:Destroy() end)
			end)
		end)
	end
end

-- Number bounce + color flash
local function pulseCashHud(gained)
	-- Dollar $ bounces
	TweenService:Create(dollarLbl,
		TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ TextColor3 = Color3.fromRGB(255, 255, 100) }
	):Play()
	task.delay(0.12, function()
		TweenService:Create(dollarLbl,
			TweenInfo.new(0.35),
			{ TextColor3 = Color3.fromRGB(255, 210, 30) }
		):Play()
	end)

	-- Value flashes green
	TweenService:Create(cashLabel2,
		TweenInfo.new(0.08),
		{ TextColor3 = Color3.fromRGB(140, 255, 120) }
	):Play()
	task.delay(0.1, function()
		TweenService:Create(cashLabel2,
			TweenInfo.new(0.45),
			{ TextColor3 = Color3.fromRGB(255, 245, 200) }
		):Play()
	end)

	-- Number scale bounce (via TextSize trick on parent)
	cashHud.Position = UDim2.new(0, SAFE_SIDE, 1, cashBaseY - 6)
	TweenService:Create(cashHud,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, SAFE_SIDE, 1, cashBaseY) }
	):Play()

	-- Spawn bouncing $ particles
	if gained and gained > 0 then
		local count = math.clamp(math.ceil(gained / 5), 2, 7)
		spawnDollarParticles(count)
	end
end

local boostHud = Instance.new("Frame")
boostHud.Name                   = "ActiveBoosts"
boostHud.AnchorPoint            = Vector2.new(0.5, 1)
boostHud.Size                   = isTouchDevice and UDim2.new(0.7, 0, 0, 54) or UDim2.new(0, 560, 0, 60)
boostHud.Position               = isTouchDevice and UDim2.new(0.5, 0, 1, -82) or UDim2.new(0.5, 0, 1, -18)
boostHud.BackgroundTransparency = 1
boostHud.Active                 = false
boostHud.Parent                 = hudGui

local boostLayout = Instance.new("UIListLayout")
boostLayout.FillDirection       = Enum.FillDirection.Horizontal
boostLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
boostLayout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
boostLayout.SortOrder           = Enum.SortOrder.LayoutOrder
boostLayout.Padding             = UDim.new(0, 8)
boostLayout.Parent              = boostHud

local activeBoosts = {}

local function showActiveBoost(itemId, duration)
	local item = ITEM_MAP[itemId]
	if not item then return end

	for activeId, active in activeBoosts do
		local activeItem = ITEM_MAP[activeId]
		if activeItem and activeItem.attrName == item.attrName and active.frame then
			active.frame:Destroy()
			activeBoosts[activeId] = nil
		end
	end

	local existing = activeBoosts[itemId]
	if existing and existing.frame then
		existing.frame:Destroy()
	end

	local frame = Instance.new("Frame")
	frame.Name = itemId .. "Boost"
	frame.Size = UDim2.new(0, 76, 0, 56)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = boostHud
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = item.iconColor
	stroke.Thickness = 2
	stroke.Transparency = 0.15
	stroke.Parent = frame

	makeBoostIcon(frame, item, UDim2.new(0, 34, 0, 34), UDim2.new(0.5, -17, 0, 4))

	local timer = Instance.new("TextLabel")
	timer.Size = UDim2.new(1, -10, 0, 18)
	timer.Position = UDim2.new(0, 5, 0, 36)
	timer.BackgroundTransparency = 1
	timer.Font = Enum.Font.GothamBold
	timer.TextSize = 14
	timer.TextColor3 = Color3.new(1, 1, 1)
	timer.Text = duration == "life" and "LIFE" or tostring(duration) .. "s"
	timer.Parent = frame

	activeBoosts[itemId] = {
		frame = frame,
		timer = timer,
		expiresAt = duration == "life" and nil or os.clock() + duration,
	}
end

-- =============================================
-- EVENTS
-- =============================================
purchaseResultEvt.OnClientEvent:Connect(function(success, msg, itemId, duration)
	showToast(msg, success)
	if success then
		refreshCards()
	end
end)

player.CharacterAdded:Connect(function()
	for itemId, boost in activeBoosts do
		if boost.frame then boost.frame:Destroy() end
		activeBoosts[itemId] = nil
	end
end)

player.AttributeChanged:Connect(function()
	if screenGui.Enabled then refreshCards() end
end)

task.spawn(function()
	local ls   = player:WaitForChild("leaderstats")
	local cash = ls:WaitForChild("Cash")
	local prevValue = cash.Value
	local function update()
		local val  = cash.Value
		local text = "$" .. tostring(val)
		cashLabel.Text    = text
		cashLabel2.Text   = tostring(val)
		local gained = val - prevValue
		if gained > 0 then
			pulseCashHud(gained)
		end
		prevValue = val
	end
	update()
	cash.Changed:Connect(update)
end)

RunService.Heartbeat:Connect(function()
	for itemId, boost in activeBoosts do
		if not boost.expiresAt then
			boost.timer.Text = "LIFE"
			continue
		end
		local remaining = math.max(0, math.ceil(boost.expiresAt - os.clock()))
		if remaining <= 0 then
			if boost.frame then boost.frame:Destroy() end
			activeBoosts[itemId] = nil
		else
			boost.timer.Text = tostring(remaining) .. "s"
		end
	end
end)
