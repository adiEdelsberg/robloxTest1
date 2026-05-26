local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local STORE_NAME      = "PlayerProgress_v2"
local KEY_PREFIX      = "pd_"
local AUTOSAVE_SECS   = 120

local store = DataStoreService:GetDataStore(STORE_NAME)

local function defaultData()
	return {
		cash            = Balance.Player and Balance.Player.StartingCash or 0,
		crowns          = 0,
		trophies        = 1,
		checkpointOrder = 1,
		checkpointName  = "Playground",
		levelCrowns     = {},   -- [tostring(order)] = count
		totalLevelWins  = 0,
	}
end

-- ── Load ──────────────────────────────────────────────────────────────────────

local function loadData(player)
	local key = KEY_PREFIX .. player.UserId
	local ok, result = pcall(function()
		return store:GetAsync(key)
	end)
	if not ok then
		warn("[PlayerDataService] GetAsync failed for", player.Name, "–", result)
		return defaultData()
	end
	if type(result) ~= "table" then
		return defaultData()
	end
	-- Merge with defaults so missing fields are safe
	local d = defaultData()
	if type(result.cash) == "number"            then d.cash            = result.cash            end
	if type(result.crowns) == "number"          then d.crowns          = result.crowns          end
	if type(result.trophies) == "number"        then d.trophies        = result.trophies        end
	if type(result.checkpointOrder) == "number" then d.checkpointOrder = result.checkpointOrder end
	if type(result.checkpointName)  == "string" then d.checkpointName  = result.checkpointName  end
	if type(result.levelCrowns)    == "table"  then d.levelCrowns    = result.levelCrowns    end
	if type(result.totalLevelWins) == "number" then d.totalLevelWins = result.totalLevelWins end
	return d
end

-- ── Save ──────────────────────────────────────────────────────────────────────

local function collectData(player)
	local stats = player:FindFirstChild("leaderstats")
	local cash  = stats and stats:FindFirstChild("Cash")
	local crowns = stats and stats:FindFirstChild("Crowns")
	local trophies = stats and stats:FindFirstChild("Trophies")

	-- Collect per-level crown attributes (LevelCrown_1 … LevelCrown_40)
	local levelCrowns = {}
	for order = 1, 40 do
		local v = player:GetAttribute("LevelCrown_" .. tostring(order))
		if v and v > 0 then
			levelCrowns[tostring(order)] = v
		end
	end

	return {
		cash            = cash and cash.Value or 0,
		crowns          = crowns and crowns.Value or 0,
		trophies        = trophies and trophies.Value or 0,
		checkpointOrder = player:GetAttribute("CheckpointOrder") or 1,
		checkpointName  = player:GetAttribute("CheckpointName")  or "Playground",
		levelCrowns     = levelCrowns,
		totalLevelWins  = player:GetAttribute("TotalLevelWins") or 0,
	}
end

local function saveData(player)
	if not player:GetAttribute("DataLoaded") then return end  -- never save uninitialised data
	local key  = KEY_PREFIX .. player.UserId
	local data = collectData(player)
	local ok, err = pcall(function()
		store:SetAsync(key, data)
	end)
	if not ok then
		warn("[PlayerDataService] SetAsync failed for", player.Name, "–", err)
	end
end

-- ── Apply loaded data to player ───────────────────────────────────────────────

local function applyData(player, data)
	-- Checkpoint / stage progress
	player:SetAttribute("CheckpointOrder", data.checkpointOrder)
	player:SetAttribute("CheckpointName",  data.checkpointName)

	-- Cash (create leaderstats if CashService hasn't yet)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name   = "leaderstats"
		stats.Parent = player
	end
	local cash = stats:FindFirstChild("Cash")
	if not cash then
		cash = Instance.new("IntValue")
		cash.Name   = "Cash"
		cash.Value  = 0
		cash.Parent = stats
	end
	cash.Value = data.cash

	local crowns = stats:FindFirstChild("Crowns")
	if not crowns then
		crowns = Instance.new("IntValue")
		crowns.Name = "Crowns"
		crowns.Value = 0
		crowns.Parent = stats
	end
	crowns.Value = data.crowns or 0

	local trophies = stats:FindFirstChild("Trophies")
	if not trophies then
		trophies = Instance.new("IntValue")
		trophies.Name = "Trophies"
		trophies.Value = 0
		trophies.Parent = stats
	end
	trophies.Value = data.trophies or 0

	-- Restore total level wins
	player:SetAttribute("TotalLevelWins", data.totalLevelWins or 0)

	-- Restore per-level crowns as player attributes
	if type(data.levelCrowns) == "table" then
		for orderStr, count in data.levelCrowns do
			if type(count) == "number" and count > 0 then
				player:SetAttribute("LevelCrown_" .. orderStr, count)
			end
		end
	end

	-- Signal other scripts that data is ready
	player:SetAttribute("DataLoaded", true)

	local stageName = WorldOrder.getName(data.checkpointOrder) or "Playground"
	print(string.format(
		"[PlayerDataService] Loaded %s — cash=$%d  checkpoint=%d (%s)",
		player.Name, data.cash, data.checkpointOrder, stageName
	))
end

-- ── Player lifecycle ──────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
	local data = loadData(player)          -- blocks this coroutine ~100-400 ms
	if not player.Parent then return end   -- player left during load
	applyData(player, data)

	-- Save whenever the player reaches a new stage (so server crashes don't erase progress)
	player:GetAttributeChangedSignal("CheckpointOrder"):Connect(function()
		saveData(player)
	end)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local crowns = stats:FindFirstChild("Crowns")
		local trophies = stats:FindFirstChild("Trophies")
		if crowns then crowns.Changed:Connect(function() saveData(player) end) end
		if trophies then trophies.Changed:Connect(function() saveData(player) end) end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
end)

-- Autosave all players periodically
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECS)
		for _, player in Players:GetPlayers() do
			task.spawn(saveData, player)
		end
	end
end)

-- Handle already-connected players (Studio test play)
for _, player in Players:GetPlayers() do
	task.spawn(function()
		local data = loadData(player)
		if not player.Parent then return end
		applyData(player, data)
	end)
end

print("[PlayerDataService] Ready.")
