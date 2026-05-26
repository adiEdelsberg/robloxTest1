-- NPCConfig
-- Shared fantasy NPC tuning. Designers can add enemies here without touching
-- controller code. MeshPart fields are optional: leave MeshId empty to use the
-- built-in stylized part fallback.

local NPCConfig = {}

NPCConfig.Performance = {
	MaxActiveNPCs = 40,
	ThinkRate = 0.12,
	ClientVFXDistance = 180,
	MobileVFXScale = 0.55,
}

NPCConfig.Defaults = {
	Health = 30,
	Damage = 8,
	WalkSpeed = 12,
	AttackRange = 6,
	AggroRange = 70,
	AttackCooldown = 1.4,
	TurnSpeed = 8,
}

NPCConfig.Enemies = {
	ForestGoblin = {
		DisplayName = "Forest Goblin",
		Health = 42,
		Damage = 9,
		WalkSpeed = 14,
		AttackRange = 6.5,
		AggroRange = 85,
		AttackCooldown = 1.2,
		Scale = 1,
		Style = {
			Skin = Color3.fromRGB(85, 255, 45),
			SkinDark = Color3.fromRGB(26, 130, 45),
			Eye = Color3.fromRGB(255, 28, 76),
			Cloth = Color3.fromRGB(92, 48, 31),
			Accent = Color3.fromRGB(120, 255, 75),
			Claw = Color3.fromRGB(242, 244, 220),
		},
		MeshParts = {
			-- Optional MeshPart-compatible slots for future custom meshes.
			-- Example:
			-- Head = { MeshId = "rbxassetid://0", TextureID = "", Scale = Vector3.new(1, 1, 1) }
		},
		Animations = {
			Idle = "",
			Run = "",
			Attack = "",
		},
	},
}

function NPCConfig.Get(enemyId)
	local enemy = NPCConfig.Enemies[enemyId]
	if not enemy then
		error(("Unknown enemy id: %s"):format(tostring(enemyId)))
	end
	local merged = table.clone(NPCConfig.Defaults)
	for key, value in pairs(enemy) do
		merged[key] = value
	end
	return merged
end

return NPCConfig
