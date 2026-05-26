-- HideDefaultUI.client.luau
-- Removes default Roblox overhead name/health display and chat bubbles.

local StarterGui = game:GetService("StarterGui")
local Players    = game:GetService("Players")

-- Disable default CoreGui elements
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,  false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,      false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,    false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,        false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu,  false)
end)

-- Remove overhead name/health BillboardGui from local player's character
local function cleanCharacter(char)
	-- Strip any BillboardGui Roblox places on the HumanoidRootPart or Head
	for _, part in char:GetDescendants() do
		if part:IsA("BillboardGui") and part.Name ~= "PickupHint" and part.Name ~= "NPCBillboard" then
			part:Destroy()
		end
	end
	char.DescendantAdded:Connect(function(d)
		if d:IsA("BillboardGui") and d.Name ~= "PickupHint" and d.Name ~= "NPCBillboard" then
			task.defer(function()
				if d.Parent then d:Destroy() end
			end)
		end
	end)
end

local player = Players.LocalPlayer
if player.Character then cleanCharacter(player.Character) end
player.CharacterAdded:Connect(cleanCharacter)
