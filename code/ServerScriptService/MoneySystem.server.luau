local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local CashService = require(script.Parent:WaitForChild("CashService"))

local function setupMoney(player)
	-- PlayerDataService loads saved cash and sets DataLoaded=true.
	-- Wait for it so we don't accidentally overwrite a returning player's balance
	-- with StartingCash.  If DataService never responds (DataStore outage), fall
	-- back to granting StartingCash after a short grace period.
	task.spawn(function()
		if not player:GetAttribute("DataLoaded") then
			local deadline = os.clock() + 6
			while not player:GetAttribute("DataLoaded") and os.clock() < deadline do
				task.wait(0.1)
			end
		end
		if not player.Parent then return end  -- player left while waiting
		-- Only grant starting cash for brand-new players (cash still at 0 after load)
		local cash = CashService.getCash(player)
		if cash.Value == 0 and Balance.Player.StartingCash > 0 then
			cash.Value = Balance.Player.StartingCash
		end
	end)
end

Players.PlayerAdded:Connect(setupMoney)
for _, player in Players:GetPlayers() do
	setupMoney(player)
end
