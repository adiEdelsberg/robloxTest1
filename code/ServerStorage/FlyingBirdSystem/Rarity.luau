-- Place in ServerStorage/FlyingBirdSystem/Rarity.luau
-- Shared rarity helpers. Server uses this to pick bird types by weight.

local Rarity = {}

Rarity.Order = {
	Common = 1,
	Rare = 2,
	Epic = 3,
	Legendary = 4,
	Mythic = 5,
}

Rarity.Colors = {
	Common = Color3.fromRGB(235, 235, 235),
	Rare = Color3.fromRGB(90, 170, 255),
	Epic = Color3.fromRGB(190, 90, 255),
	Legendary = Color3.fromRGB(255, 205, 70),
	Mythic = Color3.fromRGB(80, 255, 210),
}

function Rarity.pickWeighted(definitions, randomSource)
	local rng = randomSource or Random.new()
	local totalWeight = 0
	for _, definition in definitions do
		totalWeight += definition.spawnWeight or 1
	end

	local roll = rng:NextNumber(0, totalWeight)
	local running = 0
	for _, definition in definitions do
		running += definition.spawnWeight or 1
		if roll <= running then
			return definition
		end
	end

	return definitions[#definitions]
end

function Rarity.isRareOrBetter(rarity)
	return (Rarity.Order[rarity] or 1) >= Rarity.Order.Rare
end

return Rarity
