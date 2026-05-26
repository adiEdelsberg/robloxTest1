local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local GROUND_Y = 1
local CUBE_HEIGHT = 1200
local WALL_THICKNESS = 0.45
local EDGE_THICKNESS = 0.42
local DOOR_HALF_WIDTH = 11
local SIDE_DOOR_HALF_WIDTH = 25
local DOOR_FRAME_HEIGHT = 16

local oldFolder = workspace:FindFirstChild("WorldGlassCubes")
if oldFolder then
	oldFolder:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = "WorldGlassCubes"
folder.Parent = workspace

local WORLDS = {
	{ name = "Playground", minX = -59, maxX = 59, minZ = -59, maxZ = 59, color = "Cyan", openings = { south = { center = 0, half = DOOR_HALF_WIDTH }, west = { center = 0, half = 16 }, east = { center = 0, half = 16 } } },
	{ name = "Empty World 1", minX = -900, maxX = -200, minZ = 1420, maxZ = 1980, color = "Really red", openings = { east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Storm Dome", minX = -1670, maxX = -970, minZ = 1420, maxZ = 1980, color = "New Yeller", openings = { east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Volt Abyss", minX = -2440, maxX = -1740, minZ = 1420, maxZ = 1980, color = "Hot pink", openings = { east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Neon Rift", minX = -3210, maxX = -2510, minZ = 1420, maxZ = 1980, color = "Cyan", openings = { east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, north = { center = -2860, half = 42 }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Sky Vault", minX = -3534, maxX = -3466, minZ = 1666, maxZ = 1734, color = "Bright yellow", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Pizza", minX = -72, maxX = 72, minZ = 132, maxZ = 268, color = "Bright orange", openings = { north = { center = 0, half = DOOR_HALF_WIDTH }, south = { center = 0, half = DOOR_HALF_WIDTH } } },
	{ name = "Galactic", minX = -70, maxX = 70, minZ = 385, maxZ = 525, color = "Bright violet", openings = { north = { center = 0, half = DOOR_HALF_WIDTH }, south = { center = 0, half = DOOR_HALF_WIDTH } } },
	{ name = "Jungle", minX = -70, maxX = 70, minZ = 640, maxZ = 780, color = "Bright green", openings = { north = { center = 0, half = DOOR_HALF_WIDTH }, south = { center = 0, half = DOOR_HALF_WIDTH } } },
	{ name = "Sports", minX = -82, maxX = 82, minZ = 860, maxZ = 1020, color = "Bright yellow", openings = { north = { center = 0, half = DOOR_HALF_WIDTH }, south = { center = 0, half = DOOR_HALF_WIDTH } } },
	{ name = "Tennis", minX = -70, maxX = 70, minZ = 1090, maxZ = 1230, color = "Lime green", openings = { north = { center = 0, half = DOOR_HALF_WIDTH }, south = { center = 0, half = DOOR_HALF_WIDTH } } },
	{ name = "GameStation", minX = -78, maxX = 78, minZ = 1300, maxZ = 1460, color = "Cyan", openings = { north = { center = 0, half = DOOR_HALF_WIDTH }, south = { center = 0, half = DOOR_HALF_WIDTH } } },
	{ name = "CoffeeShop", minX = -140, maxX = 140, minZ = 1540, maxZ = 1860, color = "Bright orange", openings = { north = { center = 0, half = DOOR_HALF_WIDTH }, west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "BurgerHouse", minX = 214, maxX = 490, minZ = 1540, maxZ = 1860, color = "Bright yellow", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "NewPizza", minX = 566, maxX = 842, minZ = 1540, maxZ = 1860, color = "Really red", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "SwimmingPool", minX = 918, maxX = 1194, minZ = 1540, maxZ = 1860, color = "Cyan", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "DinosaurPark", minX = 1270, maxX = 1546, minZ = 1540, maxZ = 1860, color = "Bright green", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "DinoBeach", minX = 1622, maxX = 1898, minZ = 1540, maxZ = 1860, color = "New Yeller", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "FlyingDinoForest", minX = 1974, maxX = 2250, minZ = 1540, maxZ = 1860, color = "Bright green", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "CherryGrove", minX = 2308, maxX = 2620, minZ = 1380, maxZ = 2020, color = "Really red", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "GalacticOrchard", minX = 2660, maxX = 2980, minZ = 1380, maxZ = 2020, color = "Cyan", openings = { west = { center = 1700, half = SIDE_DOOR_HALF_WIDTH }, east = { center = 1700, half = 42 } } },
	{ name = "Storm Tower", minX = -3762, maxX = -3558, minZ = 1604, maxZ = 1796, color = "Cyan", openings = { east = { center = 1700, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Frost Basin", minX = -2924, maxX = -2796, minZ = 2136, maxZ = 2264, color = "Cyan", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Ember Hold", minX = -2924, maxX = -2796, minZ = 2486, maxZ = 2614, color = "Bright orange", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Nova Spire", minX = -2924, maxX = -2796, minZ = 2836, maxZ = 2964, color = "Bright violet", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Prism Peak", minX = -2919, maxX = -2801, minZ = 3141, maxZ = 3259, color = "Hot pink", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Magma Core", minX = -2929, maxX = -2791, minZ = 3431, maxZ = 3569, color = "Bright red", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Storm Circuit", minX = -2934, maxX = -2786, minZ = 3771, maxZ = 3889, color = "Cyan", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Shadow Vault", minX = -2924, maxX = -2796, minZ = 4066, maxZ = 4194, color = "Bright violet", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Apex Nexus", minX = -2944, maxX = -2776, minZ = 4366, maxZ = 4534, color = "Bright yellow", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Cloud Drift", minX = -2929, maxX = -2791, minZ = 4691, maxZ = 4829, color = "Institutional white", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Coral Reef", minX = -2924, maxX = -2796, minZ = 4996, maxZ = 5124, color = "Bright blue", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Bubble Bounce", minX = -2929, maxX = -2791, minZ = 5271, maxZ = 5409, color = "Toothpaste", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Zen Garden", minX = -2924, maxX = -2796, minZ = 5556, maxZ = 5684, color = "Lime green", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Crystal Spires", minX = -2929, maxX = -2791, minZ = 5831, maxZ = 5969, color = "Cyan", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Neon Triangle", minX = -2929, maxX = -2791, minZ = 6116, maxZ = 6254, color = "Hot pink", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Wide Canyon", minX = -2929, maxX = -2791, minZ = 6401, maxZ = 6539, color = "Bright orange", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Narrow Pass", minX = -2929, maxX = -2791, minZ = 6686, maxZ = 6824, color = "Lime green", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Diamond Gate", minX = -2929, maxX = -2791, minZ = 6971, maxZ = 7109, color = "Bright yellow", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Hourglass Vault", minX = -2929, maxX = -2791, minZ = 7256, maxZ = 7394, color = "Bright violet", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Movement Lab", minX = -2934, maxX = -2786, minZ = 7540, maxZ = 7680, color = "Electric blue", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Fight Arena", minX = -2990, maxX = -2730, minZ = 7990, maxZ = 8210, color = "Bright red", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH }, south = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
	{ name = "Empty World 43", minX = -2934, maxX = -2786, minZ = 8340, maxZ = 8480, color = "Lime green", openings = { north = { center = -2860, half = SIDE_DOOR_HALF_WIDTH } } },
}

local function makePart(name, size, position, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.BrickColor = BrickColor.new(color)
	part.Material = material
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function glass(name, size, position, color)
	return makePart(name, size, position, color, Enum.Material.Glass, 0.78)
end

local function wall(name, size, position, color)
	local part = glass(name, size, position, color)
	part.CanCollide = true
	return part
end

local function ceiling(name, size, position, color)
	local part = makePart(name, size, position, color, Enum.Material.Glass, 0.78)
	part.CanCollide = true
	return part
end

local function wallWithOpening(prefix, side, minA, maxA, fixed, y, height, thickness, depthAxis, opening, color)
	local function makeSegment(label, fromA, toA, segmentHeight, segmentY)
		local length = toA - fromA
		if length <= 0 then return end
		local centerA = (fromA + toA) / 2
		segmentHeight = segmentHeight or height
		segmentY = segmentY or y
		if depthAxis == "X" then
			wall(prefix .. label, Vector3.new(length, segmentHeight, thickness), Vector3.new(centerA, segmentY, fixed), color)
		else
			wall(prefix .. label, Vector3.new(thickness, segmentHeight, length), Vector3.new(fixed, segmentY, centerA), color)
		end
	end

	if not opening then
		makeSegment(side .. "Wall", minA, maxA)
		return
	end

	local gapMin = math.max(minA, opening.center - opening.half)
	local gapMax = math.min(maxA, opening.center + opening.half)
	makeSegment(side .. "WallLeft", minA, gapMin)
	makeSegment(side .. "WallRight", gapMax, maxA)

	local topHeight = math.max(0, height - DOOR_FRAME_HEIGHT)
	if topHeight > 0 then
		local topY = GROUND_Y + DOOR_FRAME_HEIGHT + topHeight / 2
		makeSegment(side .. "WallAboveDoor", gapMin, gapMax, topHeight, topY)
	end
end

local function edge(name, size, position, color)
	return makePart(name, size, position, color, Enum.Material.Neon, 0.18)
end

local function addLevelNumberSign(world, centerX, wallZ, color)
	local order = WorldOrder.getOrder(world.name)
	if not order then return end

	local signY = GROUND_Y + 74
	local sign = makePart(world.name .. "LevelNumberSign", Vector3.new(76, 74, 0.7), Vector3.new(centerX, signY, wallZ), "Really black", Enum.Material.Metal, 0.02)
	sign.CanCollide = false
	local glow = makePart(world.name .. "LevelNumberGlow", Vector3.new(80, 78, 0.35), Vector3.new(centerX, signY, wallZ - 0.35), color, Enum.Material.Neon, 0.42)
	glow.CanCollide = false

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 8
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = sign

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(3, 6, 16)
		bg.BorderSizePixel = 0
		bg.Parent = gui

		for i = 0, 8 do
			local streak = Instance.new("Frame")
			streak.Size = UDim2.new(0, 7, 2.1, 0)
			streak.Position = UDim2.new(0, i * 90 - 50, -0.55, 0)
			streak.Rotation = -18
			streak.BackgroundColor3 = BrickColor.new(color).Color
			streak.BackgroundTransparency = 0.82
			streak.BorderSizePixel = 0
			streak.Parent = bg
		end

		local tag = Instance.new("TextLabel")
		tag.Size = UDim2.new(0.64, 0, 0.055, 0)
		tag.Position = UDim2.new(0.18, 0, 0.055, 0)
		tag.BackgroundTransparency = 1
		tag.Text = "L E V E L"
		tag.TextColor3 = BrickColor.new(color).Color
		tag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		tag.TextStrokeTransparency = 0.25
		tag.Font = Enum.Font.GothamBold
		tag.TextScaled = true
		tag.Parent = bg

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1.14, 0, 0.98, 0)
		label.Position = UDim2.new(-0.07, 0, 0.025, 0)
		label.BackgroundTransparency = 1
		label.Text = tostring(order)
		label.TextColor3 = BrickColor.new(color).Color
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = bg

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 5
		stroke.Transparency = 0.15
		stroke.Parent = label

		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(0.82, 0, 0.012, 0)
		divider.Position = UDim2.new(0.09, 0, 0.925, 0)
		divider.BackgroundColor3 = BrickColor.new(color).Color
		divider.BorderSizePixel = 0
		divider.Parent = bg

		local footer = Instance.new("TextLabel")
		footer.Size = UDim2.new(0.9, 0, 0.055, 0)
		footer.Position = UDim2.new(0.05, 0, 0.935, 0)
		footer.BackgroundTransparency = 1
		footer.Text = string.upper(WorldOrder.formatCanonical(world.name):gsub("^%d+%s+", ""))
		footer.TextColor3 = Color3.fromRGB(235, 245, 255)
		footer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		footer.TextStrokeTransparency = 0.35
		footer.Font = Enum.Font.GothamBlack
		footer.TextScaled = true
		footer.Parent = bg
	end
end

local function decorativeWall(name, size, position, color)
	local part = makePart(name, size, position, color, Enum.Material.Glass, 0.42)
	part.CanCollide = false
	return part
end

local function playgroundBaseCurb(name, size, position)
	local part = makePart(name, size, position, "Institutional white", Enum.Material.SmoothPlastic, 0.08)
	part.CanCollide = true
	return part
end

local function playgroundFloorFiller(name, size, position, color)
	local part = makePart(name, size, position, color, Enum.Material.SmoothPlastic, 0)
	part.CanCollide = true
	return part
end

local function buildSegmentedPlaygroundWalls(world)
	local wallHeight = 42
	local wallY = GROUND_Y + wallHeight / 2
	local wallThickness = 1.2
	local curbHeight = 2
	local curbY = 0.5 + curbHeight / 2
	local curbThickness = 4
	local minX, maxX = world.minX, world.maxX
	local minZ, maxZ = world.minZ, world.maxZ
	local color = "Cyan"
	local prefix = "PlaygroundStyledWall"

	-- Playground tiles end around +/-56 while the world box is +/-59.
	-- Fill that edge band so players cannot fall between the floor and walls.
	local fillerY = 0
	local fillerThickness = 8
	playgroundFloorFiller(prefix .. "NorthFloorFiller", Vector3.new(maxX - minX, 1, fillerThickness), Vector3.new((minX + maxX) / 2, fillerY, minZ + fillerThickness / 2), "Bright blue")
	playgroundFloorFiller(prefix .. "SouthFloorFiller", Vector3.new(maxX - minX, 1, fillerThickness), Vector3.new((minX + maxX) / 2, fillerY, maxZ - fillerThickness / 2), "Bright blue")
	playgroundFloorFiller(prefix .. "WestFloorFiller", Vector3.new(fillerThickness, 1, maxZ - minZ), Vector3.new(minX + fillerThickness / 2, fillerY, (minZ + maxZ) / 2), "Bright blue")
	playgroundFloorFiller(prefix .. "EastFloorFiller", Vector3.new(fillerThickness, 1, maxZ - minZ), Vector3.new(maxX - fillerThickness / 2, fillerY, (minZ + maxZ) / 2), "Bright blue")

	local function zWall(name, z, gapCenter, gapHalf)
		local leftSize = (gapCenter - gapHalf) - minX
		local rightSize = maxX - (gapCenter + gapHalf)
		if leftSize > 0 then
			decorativeWall(prefix .. name .. "Left", Vector3.new(leftSize, wallHeight, wallThickness), Vector3.new(minX + leftSize / 2, wallY, z), color)
			playgroundBaseCurb(prefix .. name .. "CurbLeft", Vector3.new(leftSize, curbHeight, curbThickness), Vector3.new(minX + leftSize / 2, curbY, z), color)
		end
		if rightSize > 0 then
			decorativeWall(prefix .. name .. "Right", Vector3.new(rightSize, wallHeight, wallThickness), Vector3.new(gapCenter + gapHalf + rightSize / 2, wallY, z), color)
			playgroundBaseCurb(prefix .. name .. "CurbRight", Vector3.new(rightSize, curbHeight, curbThickness), Vector3.new(gapCenter + gapHalf + rightSize / 2, curbY, z), color)
		end
	end

	local function xWall(name, x, gapCenter, gapHalf)
		local northSize = (gapCenter - gapHalf) - minZ
		local southSize = maxZ - (gapCenter + gapHalf)
		if northSize > 0 then
			decorativeWall(prefix .. name .. "North", Vector3.new(wallThickness, wallHeight, northSize), Vector3.new(x, wallY, minZ + northSize / 2), color)
			playgroundBaseCurb(prefix .. name .. "CurbNorth", Vector3.new(curbThickness, curbHeight, northSize), Vector3.new(x, curbY, minZ + northSize / 2), color)
		end
		if southSize > 0 then
			decorativeWall(prefix .. name .. "South", Vector3.new(wallThickness, wallHeight, southSize), Vector3.new(x, wallY, gapCenter + gapHalf + southSize / 2), color)
			playgroundBaseCurb(prefix .. name .. "CurbSouth", Vector3.new(curbThickness, curbHeight, southSize), Vector3.new(x, curbY, gapCenter + gapHalf + southSize / 2), color)
		end
	end

	zWall("North", minZ, 0, 9)
zWall("South", maxZ, 0, DOOR_HALF_WIDTH + 3)
	xWall("East", maxX, 0, 16)
	xWall("West", minX, 0, 16)

	for _, corner in {
		Vector3.new(minX, wallY, minZ),
		Vector3.new(maxX, wallY, minZ),
		Vector3.new(minX, wallY, maxZ),
		Vector3.new(maxX, wallY, maxZ),
	} do
		edge(prefix .. "CornerPillar", Vector3.new(2.4, wallHeight + 3, 2.4), corner, color)
	end
end

local function buildCube(world)
	local width = world.maxX - world.minX
	local depth = world.maxZ - world.minZ
	local centerX = (world.minX + world.maxX) / 2
	local centerZ = (world.minZ + world.maxZ) / 2
	local centerY = GROUND_Y + CUBE_HEIGHT / 2
	local topY = GROUND_Y + CUBE_HEIGHT
	local color = world.color
	local prefix = world.name .. "GlassCube"

	local openings = world.openings or {}
	wallWithOpening(prefix, "North", world.minX, world.maxX, world.minZ, centerY, CUBE_HEIGHT, WALL_THICKNESS, "X", openings.north, color)
	wallWithOpening(prefix, "South", world.minX, world.maxX, world.maxZ, centerY, CUBE_HEIGHT, WALL_THICKNESS, "X", openings.south, color)
	wallWithOpening(prefix, "West", world.minZ, world.maxZ, world.minX, centerY, CUBE_HEIGHT, WALL_THICKNESS, "Z", openings.west, color)
	wallWithOpening(prefix, "East", world.minZ, world.maxZ, world.maxX, centerY, CUBE_HEIGHT, WALL_THICKNESS, "Z", openings.east, color)
	ceiling(prefix .. "Ceiling", Vector3.new(width, WALL_THICKNESS, depth), Vector3.new(centerX, topY, centerZ), color)
	addLevelNumberSign(world, centerX, world.minZ, color)

	edge(prefix .. "TopNorthEdge", Vector3.new(width, EDGE_THICKNESS, EDGE_THICKNESS), Vector3.new(centerX, topY, world.minZ), color)
	edge(prefix .. "TopSouthEdge", Vector3.new(width, EDGE_THICKNESS, EDGE_THICKNESS), Vector3.new(centerX, topY, world.maxZ), color)
	edge(prefix .. "TopWestEdge", Vector3.new(EDGE_THICKNESS, EDGE_THICKNESS, depth), Vector3.new(world.minX, topY, centerZ), color)
	edge(prefix .. "TopEastEdge", Vector3.new(EDGE_THICKNESS, EDGE_THICKNESS, depth), Vector3.new(world.maxX, topY, centerZ), color)

	for _, corner in {
		Vector3.new(world.minX, centerY, world.minZ),
		Vector3.new(world.maxX, centerY, world.minZ),
		Vector3.new(world.minX, centerY, world.maxZ),
		Vector3.new(world.maxX, centerY, world.maxZ),
	} do
		edge(prefix .. "VerticalEdge", Vector3.new(EDGE_THICKNESS, CUBE_HEIGHT, EDGE_THICKNESS), corner, color)
	end

	if world.name == "Playground" then
		buildSegmentedPlaygroundWalls(world)
	end
end

for _, world in WORLDS do
	if world.name ~= "Neon Rift" and world.name ~= "Volt Abyss" then
		buildCube(world)
	end
end

print("[WorldGlassCubes] Built transparent cube shells around all worlds.")
