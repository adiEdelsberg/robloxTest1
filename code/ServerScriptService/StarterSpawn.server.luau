local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

-- The game should always begin and respawn on the starter island by the spin wheel.
-- This runs immediately, before the larger world-building scripts finish creating scenery.
local STARTER_CF = CFrame.new(43, 88, -735) * CFrame.Angles(0, math.rad(90), 0)
local RESPAWN_AT_LAST_VISITED_WORLD = Balance.Gameplay and Balance.Gameplay.RespawnAtLastVisitedWorld == true

local function shouldUseLastVisitedWorld(player)
	return RESPAWN_AT_LAST_VISITED_WORLD and (player:GetAttribute("LastVisitedWorldOrder") or 0) > 0
end

local function moveToStarter(player, character)
	if shouldUseLastVisitedWorld(player) then
		player:SetAttribute("UseStarterRespawn", false)
		player:SetAttribute("InLandingWorld", false)
		return
	end
	player:SetAttribute("UseStarterRespawn", true)
	player:SetAttribute("InLandingWorld", true)

	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end

	-- Re-apply only during the first few frames. Longer re-teleports interrupt
	-- ProximityPrompts/clicks right after respawn and make buttons feel delayed.
	local delays = {0, 0.05, 0.12}
	for _, delayTime in delays do
		task.delay(delayTime, function()
			if not player.Parent then return end
			if player.Character ~= character then return end
			if player:GetAttribute("InLandingWorld") ~= true then return end
			if character.Parent ~= workspace then return end
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			root.CFrame = STARTER_CF
			root.AssemblyLinearVelocity = Vector3.zero
		end)
	end
end

local function connectPlayer(player)
	if shouldUseLastVisitedWorld(player) then
		player:SetAttribute("UseStarterRespawn", false)
		player:SetAttribute("InLandingWorld", false)
	else
		player:SetAttribute("UseStarterRespawn", true)
		player:SetAttribute("InLandingWorld", true)
	end
	player.CharacterAdded:Connect(function(character)
		moveToStarter(player, character)
	end)
	if player.Character then
		task.spawn(moveToStarter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(connectPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(connectPlayer, player)
end

print("[StarterSpawn] Start/respawn ready. Last-world respawn:", RESPAWN_AT_LAST_VISITED_WORLD)
