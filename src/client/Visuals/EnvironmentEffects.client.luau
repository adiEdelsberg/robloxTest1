-- EnvironmentEffects.client
-- Lightweight local arena ambience: drifting neon motes around the player.
-- Keep these effects client-only for mobile-friendly performance.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualConfig = require(ReplicatedStorage:WaitForChild("Visuals"):WaitForChild("VisualConfig"))
local player = Players.LocalPlayer

local attachment = Instance.new("Attachment")
attachment.Name = "PremiumAmbientAnchor"

local emitter = Instance.new("ParticleEmitter")
emitter.Name = "PremiumArenaMotes"
emitter.Color = ColorSequence.new(VisualConfig.VFX.NeonCyan, VisualConfig.VFX.NeonViolet)
emitter.LightEmission = 0.5
emitter.Rate = VisualConfig.Performance.MaxAmbientParticles * 0.08
emitter.Lifetime = NumberRange.new(2.5, 4.5)
emitter.Speed = NumberRange.new(0.4, 1.4)
emitter.SpreadAngle = Vector2.new(180, 180)
emitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.25, 0.12),
	NumberSequenceKeypoint.new(1, 0),
})
emitter.Transparency = NumberSequence.new(0.25, 1)
emitter.Parent = attachment

local function attachToCharacter(character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		attachment.Parent = root
	end
end

if player.Character then
	task.spawn(attachToCharacter, player.Character)
end
player.CharacterAdded:Connect(attachToCharacter)

print("[EnvironmentEffects] Local premium arena ambience ready.")
