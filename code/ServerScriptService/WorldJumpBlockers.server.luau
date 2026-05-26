-- Disabled: old gate jump blockers are obsolete now that there are no gates.
if true then return end

local GROUND_Y = 1
local BLOCKER_HEIGHT = 180
local BLOCKER_Y = GROUND_Y + BLOCKER_HEIGHT / 2
local THICKNESS = 2

local folder = Instance.new("Folder")
folder.Name = "WorldJumpBlockers"
folder.Parent = workspace

local WORLD_BOUNDS = {
	{ name = "Playground", minX = -59, maxX = 59, minZ = -59, maxZ = 59, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "south", center = 0, half = 8 },
		{ side = "east", center = -42, half = 10 },
	} },
	{ name = "Pizza", minX = -70, maxX = 70, minZ = 132, maxZ = 268, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "south", center = 0, half = 8 },
	} },
	{ name = "Galactic", minX = -70, maxX = 70, minZ = 385, maxZ = 525, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "south", center = 0, half = 8 },
	} },
	{ name = "Jungle", minX = -70, maxX = 70, minZ = 640, maxZ = 780, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "south", center = 0, half = 8 },
	} },
	{ name = "Sports", minX = -82, maxX = 82, minZ = 860, maxZ = 1020, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "south", center = 0, half = 8 },
	} },
	{ name = "Tennis", minX = -70, maxX = 70, minZ = 1090, maxZ = 1230, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "south", center = 0, half = 8 },
	} },
	{ name = "GameStation", minX = -78, maxX = 78, minZ = 1300, maxZ = 1460, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "south", center = 0, half = 8 },
	} },
	{ name = "CoffeeShop", minX = -140, maxX = 140, minZ = 1540, maxZ = 1860, openings = {
		{ side = "north", center = 0, half = 8 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "BurgerHouse", minX = 214, maxX = 490, minZ = 1540, maxZ = 1860, openings = {
		{ side = "west", center = 1700, half = 22 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "NewPizza", minX = 566, maxX = 842, minZ = 1540, maxZ = 1860, openings = {
		{ side = "west", center = 1700, half = 22 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "SwimmingPool", minX = 918, maxX = 1194, minZ = 1540, maxZ = 1860, openings = {
		{ side = "west", center = 1700, half = 22 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "DinosaurPark", minX = 1270, maxX = 1546, minZ = 1540, maxZ = 1860, openings = {
		{ side = "west", center = 1700, half = 22 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "DinoBeach", minX = 1622, maxX = 1898, minZ = 1540, maxZ = 1860, openings = {
		{ side = "west", center = 1700, half = 22 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "FlyingDinoForest", minX = 1974, maxX = 2250, minZ = 1540, maxZ = 1860, openings = {
		{ side = "west", center = 1700, half = 22 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "CherryGrove", minX = 2308, maxX = 2620, minZ = 1380, maxZ = 2020, openings = {
		{ side = "west", center = 1700, half = 22 },
		{ side = "east", center = 1700, half = 22 },
	} },
	{ name = "GalacticOrchard", minX = 2660, maxX = 2980, minZ = 1380, maxZ = 2020, openings = {
		{ side = "west", center = 1700, half = 22 },
	} },
}

local function makeBlocker(name, size, position)
	if size.X <= 0 or size.Z <= 0 then return end
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = 1
	part.CastShadow = false
	part.Parent = folder
	return part
end

local function openingsFor(world, side)
	local result = {}
	for _, opening in world.openings or {} do
		if opening.side == side then
			table.insert(result, opening)
		end
	end
	table.sort(result, function(a, b)
		return a.center < b.center
	end)
	return result
end

local function edgeSegments(minValue, maxValue, openings)
	local segments = {}
	local cursor = minValue
	for _, opening in openings do
		local startValue = math.max(minValue, opening.center - opening.half)
		local endValue = math.min(maxValue, opening.center + opening.half)
		if startValue > cursor then
			table.insert(segments, { from = cursor, to = startValue })
		end
		cursor = math.max(cursor, endValue)
	end
	if cursor < maxValue then
		table.insert(segments, { from = cursor, to = maxValue })
	end
	return segments
end

local function addNorthSouth(world, side, z)
	for _, segment in edgeSegments(world.minX, world.maxX, openingsFor(world, side)) do
		local length = segment.to - segment.from
		makeBlocker(
			world.name .. side .. "JumpBlocker",
			Vector3.new(length, BLOCKER_HEIGHT, THICKNESS),
			Vector3.new((segment.from + segment.to) / 2, BLOCKER_Y, z)
		)
	end
end

local function addEastWest(world, side, x)
	for _, segment in edgeSegments(world.minZ, world.maxZ, openingsFor(world, side)) do
		local length = segment.to - segment.from
		makeBlocker(
			world.name .. side .. "JumpBlocker",
			Vector3.new(THICKNESS, BLOCKER_HEIGHT, length),
			Vector3.new(x, BLOCKER_Y, (segment.from + segment.to) / 2)
		)
	end
end

for _, world in WORLD_BOUNDS do
	addNorthSouth(world, "north", world.minZ)
	addNorthSouth(world, "south", world.maxZ)
	addEastWest(world, "west", world.minX)
	addEastWest(world, "east", world.maxX)
end

local function strengthenExistingContainment(part)
	if not part:IsA("BasePart") then return end
	local name = part.Name
	if not (name:find("Contain") or name == "IWall") then return end
	if part.Size.Y >= BLOCKER_HEIGHT then return end

	part.Size = Vector3.new(part.Size.X, BLOCKER_HEIGHT, part.Size.Z)
	part.Position = Vector3.new(part.Position.X, BLOCKER_Y, part.Position.Z)
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = math.max(part.Transparency, 1)
	part.CastShadow = false
end

local LEGACY_GATES = {
	BridgeGate = true,
	PizzaGate = true,
	GalacticGate = true,
	JungleGate = true,
	SportsGate = true,
	TennisGate = true,
	GameStationGate = true,
	CoffeeGate = true,
	BurgerGate = true,
	NewPizzaGate = true,
	PoolGate = true,
	DinosaurGate = true,
	DinoBeachGate = true,
	FlyingDinoForestGate = true,
	GiantDinoCherryGate = true,
	GalacticFruitGate = true,
}

local function disableLegacyGateBlocker(part)
	if not part:IsA("BasePart") then return end
	if not (part.Name:find("GateBlocker") or LEGACY_GATES[part.Name]) then return end
	part.CanCollide = false
	part.CanTouch = false
	part.Transparency = 1
	part:Destroy()
end

for _, object in workspace:GetDescendants() do
	strengthenExistingContainment(object)
	disableLegacyGateBlocker(object)
end

workspace.DescendantAdded:Connect(function(object)
	strengthenExistingContainment(object)
	disableLegacyGateBlocker(object)
end)

print("[WorldJumpBlockers] High invisible wall blockers built for all worlds.")
