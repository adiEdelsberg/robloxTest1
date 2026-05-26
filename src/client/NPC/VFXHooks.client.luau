-- VFXHooks.client
-- Client-side bridge for NPCController VFX events. Add new event names here
-- without changing server NPC logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientVisuals = script.Parent.Parent:WaitForChild("Visuals")
local VFXController = require(clientVisuals:WaitForChild("VFXController"))
local CameraEffects = require(clientVisuals:WaitForChild("CameraEffects"))

local remotes = ReplicatedStorage:WaitForChild("NPCVFX")
local vfxRemote = remotes:WaitForChild("FantasyNPCVFX")

vfxRemote.OnClientEvent:Connect(function(kind, position, color)
	if kind == "Impact" then
		VFXController.Impact(position, color)
	elseif kind == "AttackSwipe" then
		VFXController.Shockwave(CFrame.new(position), 14, color)
	elseif kind == "CameraShake" then
		CameraEffects.Shake("HeavyHit")
	end
end)
