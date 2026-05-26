local Players = game:GetService("Players")

local CashService = {}

function CashService.getCash(player)
	if not player or not player:IsA("Player") then return nil end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end

	local cash = stats:FindFirstChild("Cash")
	if not cash then
		cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = stats
	end
	return cash
end

function CashService.add(player, amount)
	local cash = CashService.getCash(player)
	if cash then
		cash.Value += amount
	end
	return cash
end

return CashService
