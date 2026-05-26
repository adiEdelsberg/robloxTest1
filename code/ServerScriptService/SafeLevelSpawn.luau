-- SafeLevelSpawn.luau
-- Shared launcher landing helper. Prefer open floor instead of fixed room centers,
-- so teleporters do not place players inside ramps, props, or raised platforms.

local SafeLevelSpawn = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local ORDER_BOUNDS = {
	[1] = { minX = -59, maxX = 59, minZ = -59, maxZ = 59 },
	[2] = { minX = -72, maxX = 72, minZ = 132, maxZ = 268 },
	[3] = { minX = -70, maxX = 70, minZ = 385, maxZ = 525 },
	[4] = { minX = -70, maxX = 70, minZ = 640, maxZ = 780 },
	[5] = { minX = -82, maxX = 82, minZ = 860, maxZ = 1020 },
	[6] = { minX = -70, maxX = 70, minZ = 1090, maxZ = 1230 },
	[7] = { minX = -78, maxX = 78, minZ = 1300, maxZ = 1460 },
	[8] = { minX = -140, maxX = 140, minZ = 1540, maxZ = 1860 },
	[9] = { minX = 214, maxX = 490, minZ = 1540, maxZ = 1860 },
	[10] = { minX = 566, maxX = 842, minZ = 1540, maxZ = 1860 },
	[11] = { minX = 918, maxX = 1194, minZ = 1540, maxZ = 1860 },
	[12] = { minX = 1270, maxX = 1546, minZ = 1540, maxZ = 1860 },
	[13] = { minX = 1622, maxX = 1898, minZ = 1540, maxZ = 1860 },
	[14] = { minX = 1974, maxX = 2250, minZ = 1540, maxZ = 1860 },
	[15] = { minX = 2308, maxX = 2620, minZ = 1380, maxZ = 2020 },
	[16] = { minX = 2660, maxX = 2980, minZ = 1380, maxZ = 2020 },
	[17] = { minX = -900, maxX = -200, minZ = 1420, maxZ = 1980 },
	[18] = { minX = -1670, maxX = -970, minZ = 1420, maxZ = 1980 },
	[19] = { minX = -2440, maxX = -1740, minZ = 1420, maxZ = 1980 },
	[20] = { minX = -3210, maxX = -2510, minZ = 1420, maxZ = 1980 },
	[21] = { minX = -3534, maxX = -3466, minZ = 1666, maxZ = 1734 },
	[22] = { minX = -3762, maxX = -3558, minZ = 1604, maxZ = 1796 },
	[23] = { minX = -2924, maxX = -2796, minZ = 2136, maxZ = 2264 },
	[24] = { minX = -2924, maxX = -2796, minZ = 2486, maxZ = 2614 },
	[25] = { minX = -2924, maxX = -2796, minZ = 2836, maxZ = 2964 },
	[26] = { minX = -2919, maxX = -2801, minZ = 3141, maxZ = 3259 },
	[27] = { minX = -2929, maxX = -2791, minZ = 3431, maxZ = 3569 },
	[28] = { minX = -2934, maxX = -2786, minZ = 3771, maxZ = 3889 },
	[29] = { minX = -2924, maxX = -2796, minZ = 4066, maxZ = 4194 },
	[30] = { minX = -2944, maxX = -2776, minZ = 4366, maxZ = 4534 },
	[31] = { minX = -2929, maxX = -2791, minZ = 4691, maxZ = 4829 },
	[32] = { minX = -2924, maxX = -2796, minZ = 4996, maxZ = 5124 },
	[33] = { minX = -2929, maxX = -2791, minZ = 5271, maxZ = 5409 },
	[34] = { minX = -2924, maxX = -2796, minZ = 5556, maxZ = 5684 },
	[35] = { minX = -2929, maxX = -2791, minZ = 5831, maxZ = 5969 },
	[36] = { minX = -2929, maxX = -2791, minZ = 6116, maxZ = 6254 },
	[37] = { minX = -2929, maxX = -2791, minZ = 6401, maxZ = 6539 },
	[38] = { minX = -2929, maxX = -2791, minZ = 6686, maxZ = 6824 },
	[39] = { minX = -2929, maxX = -2791, minZ = 6971, maxZ = 7109 },
	[40] = { minX = -2929, maxX = -2791, minZ = 7256, maxZ = 7394 },
}

local NAME_TO_ORDER = {
	["New Pizza"] = 10,
	["New Pizza Place"] = 10,
	["GameStation"] = 7,
	["CoffeeShop"] = 8,
	["BurgerHouse"] = 9,
	["SwimmingPool"] = 11,
	["DinosaurPark"] = 12,
	["DinoBeach"] = 13,
	["FlyingDinoForest"] = 14,
	["CherryGrove"] = 15,
	["GalacticOrchard"] = 16,
	["Volt Abyss"] = 19,
}

local FIXED_SPAWNS = {
	-- Center of Volt Abyss has ramps and a raised platform; land in open floor.
	[19] = CFrame.new(-2090, 8, 1580),
	[23] = CFrame.new(-2860, 8, 2162),
	[25] = CFrame.new(-2860, 8, 2862),
}

local raycastParams

local function getRaycastParams()
	if not raycastParams then
		raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	end
	return raycastParams
end

local function isClear(position)
	local parts = workspace:GetPartBoundsInBox(CFrame.new(position + Vector3.new(0, 4, 0)), Vector3.new(5, 8, 5))
	for _, part in parts do
		if part.CanCollide and part.Transparency < 1 and not part.Name:find("Floor") and not part.Name:find("SafetyFloor") then
			return false
		end
	end
	return true
end

local function resolveOrder(order, name)
	return tonumber(order) or NAME_TO_ORDER[name or ""]
end

function SafeLevelSpawn.getBounds(order, name)
	return ORDER_BOUNDS[resolveOrder(order, name)]
end

function SafeLevelSpawn.getCFrame(order, name, fallbackCFrame, bounds)
	local resolvedOrder = resolveOrder(order, name)
	local configured = WorldOrder.getRespawnCFrame(resolvedOrder or name)
	if configured then
		return configured
	end

	local fixed = resolvedOrder and FIXED_SPAWNS[resolvedOrder]
	if fixed then
		return fixed
	end

	bounds = bounds or SafeLevelSpawn.getBounds(resolvedOrder, name)
	if not bounds then
		return fallbackCFrame
	end

	local fallbackPos = fallbackCFrame and fallbackCFrame.Position
	local cx = fallbackPos and fallbackPos.X or (bounds.minX + bounds.maxX) / 2
	local cz = fallbackPos and fallbackPos.Z or (bounds.minZ + bounds.maxZ) / 2
	local margin = 12
	local best

	for _, radius in { 0, 18, 36, 54 } do
		for _, offset in {
			Vector2.new(0, 0), Vector2.new(radius, 0), Vector2.new(-radius, 0),
			Vector2.new(0, radius), Vector2.new(0, -radius),
			Vector2.new(radius, radius), Vector2.new(radius, -radius),
			Vector2.new(-radius, radius), Vector2.new(-radius, -radius),
		} do
			local x = math.clamp(cx + offset.X, bounds.minX + margin, bounds.maxX - margin)
			local z = math.clamp(cz + offset.Y, bounds.minZ + margin, bounds.maxZ - margin)
			local result = workspace:Raycast(Vector3.new(x, 380, z), Vector3.new(0, -520, 0), getRaycastParams())
			if result then
				local pos = Vector3.new(x, result.Position.Y + 5, z)
				if isClear(pos) and (not best or result.Position.Y < best.hitY) then
					best = { pos = pos, hitY = result.Position.Y }
				end
			end
		end
	end

	local pos = best and best.pos or (fallbackPos or Vector3.new(cx, 8, cz))
	local rotation = fallbackCFrame and (fallbackCFrame - fallbackCFrame.Position) or CFrame.new()
	return CFrame.new(pos) * rotation
end

return SafeLevelSpawn
