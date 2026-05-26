-- Bird world jump enabler: ensures players always have jumping enabled.
-- The net mechanic has been removed; catching is now done by direct touch.
-- Jump power-ups are granted by BirdWorldJumpBalls (5-minute boosts).

local Players = game:GetService("Players")

local function ensureJumpEnabled(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	if humanoid:GetAttribute("NetJumpDisabled") then
		local oldPower  = humanoid:GetAttribute("NetOldJumpPower")
		local oldHeight = humanoid:GetAttribute("NetOldJumpHeight")
		if oldPower  then humanoid.JumpPower  = oldPower  end
		if oldHeight then humanoid.JumpHeight = oldHeight end
		humanoid:SetAttribute("NetJumpDisabled", nil)
		humanoid:SetAttribute("NetOldJumpPower",  nil)
		humanoid:SetAttribute("NetOldJumpHeight", nil)
	end
	-- Remove any leftover net models
	local net = character:FindFirstChild("BirdCatchingNet")
	if net then net:Destroy() end
end

local function onCharacterAdded(character)
	task.wait(0.2)
	ensureJumpEnabled(character)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then onCharacterAdded(player.Character) end
end)
for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then ensureJumpEnabled(player.Character) end
end
