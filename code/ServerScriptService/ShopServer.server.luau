local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local shopFolder = Instance.new("Folder")
shopFolder.Name   = "ShopEvents"
shopFolder.Parent = ReplicatedStorage

local purchaseEvent = Instance.new("RemoteEvent")
purchaseEvent.Name   = "Purchase"
purchaseEvent.Parent = shopFolder

local purchaseResultEvent = Instance.new("RemoteEvent")
purchaseResultEvent.Name   = "PurchaseResult"
purchaseResultEvent.Parent = shopFolder

local SHOP_PRICES = Balance.Shop.ItemPrices

local ITEMS = {
	{ id="speed1", name="Speed Boost I",   desc="+5 walk speed",   price=SHOP_PRICES.speed1, attrName="SpeedBoost", tierValue=1, requiresTier=0, icon="SPD 1" },
	{ id="speed2", name="Speed Boost II",  desc="+10 walk speed",  price=SHOP_PRICES.speed2, attrName="SpeedBoost", tierValue=2, requiresTier=1, icon="SPD 2" },
	{ id="speed3", name="Speed Boost III", desc="+16 walk speed",  price=SHOP_PRICES.speed3, attrName="SpeedBoost", tierValue=3, requiresTier=2, icon="SPD 3" },
	{ id="speed4", name="Speed Boost IV",  desc="+23 walk speed",  price=SHOP_PRICES.speed4, attrName="SpeedBoost", tierValue=4, requiresTier=3, icon="SPD 4" },
	{ id="speed5", name="Speed Boost V",   desc="+31 walk speed",  price=SHOP_PRICES.speed5, attrName="SpeedBoost", tierValue=5, requiresTier=4, icon="SPD 5" },
	{ id="jump1",  name="Jump Boost I",    desc="Higher jump",     price=SHOP_PRICES.jump1, attrName="JumpBoost",  tierValue=1, requiresTier=0, icon="JMP 1" },
	{ id="jump2",  name="Jump Boost II",   desc="Super jump",      price=SHOP_PRICES.jump2, attrName="JumpBoost",  tierValue=2, requiresTier=1, icon="JMP 2" },
	{ id="jump3",  name="Jump Boost III",  desc="Mega jump",       price=SHOP_PRICES.jump3, attrName="JumpBoost",  tierValue=3, requiresTier=2, icon="JMP 3" },
	{ id="jump4",  name="Jump Boost IV",   desc="Ultra jump",      price=SHOP_PRICES.jump4, attrName="JumpBoost",  tierValue=4, requiresTier=3, icon="JMP 4" },
	{ id="jump5",  name="Jump Boost V",    desc="Sky jump",        price=SHOP_PRICES.jump5, attrName="JumpBoost",  tierValue=5, requiresTier=4, icon="JMP 5" },
}
local ITEM_MAP = {}
for _, item in ITEMS do ITEM_MAP[item.id] = item end
local activeBoosts = {}

local JUMP_POWERS = Balance.Movement.JumpPowers
local WALK_SPEEDS = Balance.Movement.WalkSpeeds
local SKATE_SPEED = Balance.Skateboard.Speed
local SKATE_JUMP  = Balance.Skateboard.JumpPower

local function applyStats(player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if player:GetAttribute("SkateboardMounted") then
		hum.JumpPower = SKATE_JUMP
		hum.WalkSpeed = SKATE_SPEED
	else
		hum.JumpPower = JUMP_POWERS[player:GetAttribute("JumpBoost")  or 0] or 50
		hum.WalkSpeed = WALK_SPEEDS[player:GetAttribute("SpeedBoost") or 0] or 16
	end
end

Players.PlayerAdded:Connect(function(player)
	activeBoosts[player] = {}
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		local playerBoosts = activeBoosts[player]
		if playerBoosts then
			for attrName in playerBoosts do
				player:SetAttribute(attrName, 0)
				playerBoosts[attrName] = nil
			end
		end
		applyStats(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	activeBoosts[player] = nil
end)

local function startLifeBoost(player, item)
	local playerBoosts = activeBoosts[player]
	if not playerBoosts then
		playerBoosts = {}
		activeBoosts[player] = playerBoosts
	end

	playerBoosts[item.attrName] = {
		itemId = item.id,
	}

	player:SetAttribute(item.attrName, item.tierValue)
	applyStats(player)
end

purchaseEvent.OnServerEvent:Connect(function(player, itemId)
	local item = ITEM_MAP[itemId]
	if not item then return end
	local stats = player:FindFirstChild("leaderstats")
	local cash  = stats and stats:FindFirstChild("Cash")
	if not cash then return end
	local currentTier = player:GetAttribute(item.attrName) or 0
	if currentTier >= item.tierValue then
		purchaseResultEvent:FireClient(player, false, "Already owned!")
		return
	end
	if currentTier < item.requiresTier then
		purchaseResultEvent:FireClient(player, false, "Buy the previous upgrade first!")
		return
	end
	if cash.Value < item.price then
		purchaseResultEvent:FireClient(player, false, "Not enough cash!")
		return
	end
	cash.Value -= item.price
	startLifeBoost(player, item)
	purchaseResultEvent:FireClient(player, true, "Purchased: " .. item.name, item.id, "life")
end)
