-- UniversalLevelSigns.server.luau
-- Static level-number signs for every ordered gameplay room.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local oldFolder = workspace:FindFirstChild("UniversalLevelSigns")
if oldFolder then
	oldFolder:Destroy()
end

-- Disabled to avoid duplicate level signs.
-- WorldGlassCubes.server.luau owns the single default level-number sign for each room.
if true then return end

local folder = Instance.new("Folder")
folder.Name = "UniversalLevelSigns"
folder.Parent = workspace

local GROUND_Y = 1

local LEVELS = {
	{ name = "Playground", minX = -59, maxX = 59, minZ = -59, maxZ = 59, color = "Cyan" },
	{ name = "Pizza", minX = -72, maxX = 72, minZ = 132, maxZ = 268, color = "Bright orange" },
	{ name = "Galactic", minX = -70, maxX = 70, minZ = 385, maxZ = 525, color = "Bright violet" },
	{ name = "Jungle", minX = -70, maxX = 70, minZ = 640, maxZ = 780, color = "Bright green" },
	{ name = "Sports", minX = -82, maxX = 82, minZ = 860, maxZ = 1020, color = "Bright yellow" },
	{ name = "Tennis", minX = -70, maxX = 70, minZ = 1090, maxZ = 1230, color = "Lime green" },
	{ name = "Game Station", minX = -78, maxX = 78, minZ = 1300, maxZ = 1460, color = "Cyan" },
	{ name = "Coffee Shop", minX = -140, maxX = 140, minZ = 1540, maxZ = 1860, color = "Bright orange" },
	{ name = "Burger House", minX = 214, maxX = 490, minZ = 1540, maxZ = 1860, color = "Bright yellow" },
	{ name = "New Pizza Place", minX = 566, maxX = 842, minZ = 1540, maxZ = 1860, color = "Really red" },
	{ name = "Swimming Pool", minX = 918, maxX = 1194, minZ = 1540, maxZ = 1860, color = "Cyan" },
	{ name = "Dinosaur Park", minX = 1270, maxX = 1546, minZ = 1540, maxZ = 1860, color = "Bright green" },
	{ name = "Dino Beach", minX = 1622, maxX = 1898, minZ = 1540, maxZ = 1860, color = "New Yeller" },
	{ name = "Flying Dino Forest", minX = 1974, maxX = 2250, minZ = 1540, maxZ = 1860, color = "Bright green" },
	{ name = "Cherry Grove", minX = 2308, maxX = 2620, minZ = 1380, maxZ = 2020, color = "Really red" },
	{ name = "Galactic Orchard", minX = 2660, maxX = 2980, minZ = 1380, maxZ = 2020, color = "Cyan" },
	{ name = "Empty World 1", minX = -900, maxX = -200, minZ = 1420, maxZ = 1980, color = "Really red" },
	{ name = "Storm Dome", minX = -1670, maxX = -970, minZ = 1420, maxZ = 1980, color = "New Yeller" },
	{ name = "Volt Abyss", minX = -2440, maxX = -1740, minZ = 1420, maxZ = 1980, color = "Hot pink" },
	{ name = "Neon Rift", minX = -3210, maxX = -2510, minZ = 1420, maxZ = 1980, color = "Cyan" },
	{ name = "Sky Vault", minX = -3534, maxX = -3466, minZ = 1666, maxZ = 1734, color = "Bright yellow" },
	{ name = "Storm Tower", minX = -3762, maxX = -3558, minZ = 1604, maxZ = 1796, color = "Cyan" },
	{ name = "Frost Basin", minX = -2924, maxX = -2796, minZ = 2136, maxZ = 2264, color = "Cyan" },
	{ name = "Ember Hold", minX = -2924, maxX = -2796, minZ = 2486, maxZ = 2614, color = "Bright orange" },
	{ name = "Nova Spire", minX = -2924, maxX = -2796, minZ = 2836, maxZ = 2964, color = "Bright violet" },
	{ name = "Prism Peak", minX = -2919, maxX = -2801, minZ = 3141, maxZ = 3259, color = "Hot pink" },
	{ name = "Magma Core", minX = -2929, maxX = -2791, minZ = 3431, maxZ = 3569, color = "Bright red" },
	{ name = "Storm Circuit", minX = -2934, maxX = -2786, minZ = 3771, maxZ = 3889, color = "Cyan" },
	{ name = "Shadow Vault", minX = -2924, maxX = -2796, minZ = 4066, maxZ = 4194, color = "Bright violet" },
	{ name = "Apex Nexus", minX = -2944, maxX = -2776, minZ = 4366, maxZ = 4534, color = "Bright yellow" },
	{ name = "Cloud Drift", minX = -2929, maxX = -2791, minZ = 4691, maxZ = 4829, color = "Institutional white" },
	{ name = "Coral Reef", minX = -2924, maxX = -2796, minZ = 4996, maxZ = 5124, color = "Bright blue" },
	{ name = "Bubble Bounce", minX = -2929, maxX = -2791, minZ = 5271, maxZ = 5409, color = "Toothpaste" },
	{ name = "Zen Garden", minX = -2924, maxX = -2796, minZ = 5556, maxZ = 5684, color = "Lime green" },
	{ name = "Crystal Spires", minX = -2929, maxX = -2791, minZ = 5831, maxZ = 5969, color = "Cyan" },
	{ name = "Neon Triangle", minX = -2929, maxX = -2791, minZ = 6116, maxZ = 6254, color = "Hot pink" },
	{ name = "Wide Canyon", minX = -2929, maxX = -2791, minZ = 6401, maxZ = 6539, color = "Bright orange" },
	{ name = "Narrow Pass", minX = -2929, maxX = -2791, minZ = 6686, maxZ = 6824, color = "Lime green" },
	{ name = "Diamond Gate", minX = -2929, maxX = -2791, minZ = 6971, maxZ = 7109, color = "Bright yellow" },
	{ name = "Hourglass Vault", minX = -2929, maxX = -2791, minZ = 7256, maxZ = 7394, color = "Bright violet" },
}

local function makePart(name, size, cf, color, material, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(color)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = canCollide == true
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function addGui(sign, face, level)
	local order = WorldOrder.getOrder(level.name)
	if not order then return end

	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.Parent = sign

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(4, 7, 16)
	bg.BackgroundTransparency = 0.03
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local number = Instance.new("TextLabel")
	number.Size = UDim2.new(0.42, 0, 1, 0)
	number.Position = UDim2.new(0.03, 0, 0, 0)
	number.BackgroundTransparency = 1
	number.Text = tostring(order)
	number.TextColor3 = BrickColor.new(level.color).Color
	number.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	number.TextStrokeTransparency = 0
	number.Font = Enum.Font.GothamBlack
	number.TextScaled = true
	number.Parent = bg

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, 0, 0.42, 0)
	title.Position = UDim2.new(0.46, 0, 0.14, 0)
	title.BackgroundTransparency = 1
	title.Text = "LEVEL"
	title.TextColor3 = Color3.fromRGB(235, 245, 255)
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.25
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = bg

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.5, 0, 0.3, 0)
	name.Position = UDim2.new(0.46, 0, 0.58, 0)
	name.BackgroundTransparency = 1
	name.Text = string.upper(level.name)
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	name.TextStrokeTransparency = 0.35
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	name.Parent = bg
end

local function addLevelSign(level)
	local order = WorldOrder.getOrder(level.name)
	if not order then return end

	local width = math.clamp((level.maxX - level.minX) * 0.55, 44, 92)
	local centerX = (level.minX + level.maxX) / 2
	local z = level.minZ + 1.8
	local y = GROUND_Y + 34
	local cf = CFrame.new(centerX, y, z)
	local sign = makePart("Level" .. order .. "StaticSign", Vector3.new(width, 24, 0.75), cf, "Really black", Enum.Material.Metal, 0.02, false)
	makePart("Level" .. order .. "StaticSignGlow", Vector3.new(width + 2, 26, 0.25), cf * CFrame.new(0, 0, -0.44), level.color, Enum.Material.Neon, 0.5, false)
	addGui(sign, Enum.NormalId.Front, level)
	addGui(sign, Enum.NormalId.Back, level)
end

for _, level in LEVELS do
	addLevelSign(level)
end

print("[UniversalLevelSigns] Built static level signs for all ordered rooms.")
