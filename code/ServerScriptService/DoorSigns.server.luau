-- Disabled: there are no more gate/door signs in the current flow.
if true then return end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local folder = Instance.new("Folder")
folder.Name = "DoorSigns"
folder.Parent = workspace

local WHITE = Color3.fromRGB(245, 245, 245)

local DOORS = {
	{ name = "TimeTravelEntranceDoor", axis = "Z", x = 0, z = -105, north = "Time Travel", south = "Playground", color = "Cyan", textColor = Color3.fromRGB(80, 220, 255) },

	{ name = "PlaygroundExitDoor", axis = "Z", x = 0, z = 59, north = "Pizza Place", south = "Playground", color = "Bright orange", textColor = Color3.fromRGB(255, 135, 45) },
	{ name = "PizzaEntryDoor", axis = "Z", x = 0, z = 130, north = "Pizza Place", south = "Playground", color = "Bright orange", textColor = Color3.fromRGB(255, 135, 45) },

	{ name = "PizzaExitDoor", axis = "Z", x = 0, z = 272, north = "Galactic Zone", south = "Pizza Place", color = "Bright violet", textColor = Color3.fromRGB(190, 90, 255) },
	{ name = "GalacticEntryDoor", axis = "Z", x = 0, z = 385, north = "Galactic Zone", south = "Pizza Place", color = "Bright violet", textColor = Color3.fromRGB(190, 90, 255) },

	{ name = "GalacticExitDoor", axis = "Z", x = 0, z = 524, north = "Jungle Zone", south = "Galactic Zone", color = "Bright green", textColor = Color3.fromRGB(80, 230, 90) },
	{ name = "JungleEntryDoor", axis = "Z", x = 0, z = 640, north = "Jungle Zone", south = "Galactic Zone", color = "Bright green", textColor = Color3.fromRGB(80, 230, 90) },

	{ name = "JungleExitDoor", axis = "Z", x = 0, z = 781, north = "Sports World", south = "Jungle Zone", color = "Bright yellow", textColor = Color3.fromRGB(255, 220, 70) },
	{ name = "SportsEntryDoor", axis = "Z", x = 0, z = 860, north = "Sports World", south = "Jungle Zone", color = "Bright yellow", textColor = Color3.fromRGB(255, 220, 70) },

	{ name = "SportsExitDoor", axis = "Z", x = 0, z = 1021, north = "Tennis Court", south = "Sports World", color = "Lime green", textColor = Color3.fromRGB(155, 255, 90) },
	{ name = "TennisEntryDoor", axis = "Z", x = 0, z = 1090, north = "Tennis Court", south = "Sports World", color = "Lime green", textColor = Color3.fromRGB(155, 255, 90) },

	{ name = "TennisExitDoor", axis = "Z", x = 0, z = 1231, north = "Game Station", south = "Tennis Court", color = "Cyan", textColor = Color3.fromRGB(80, 220, 255) },
	{ name = "GameStationEntryDoor", axis = "Z", x = 0, z = 1300, north = "Game Station", south = "Tennis Court", color = "Cyan", textColor = Color3.fromRGB(80, 220, 255) },

	{ name = "GameStationExitDoor", axis = "Z", x = 0, z = 1460, north = "Coffee Shop", south = "Game Station", color = "Bright orange", textColor = Color3.fromRGB(255, 180, 60) },
	{ name = "CoffeeEntryDoor", axis = "Z", x = 0, z = 1540, north = "Coffee Shop", south = "Game Station", color = "Bright orange", textColor = Color3.fromRGB(255, 180, 60) },

	{ name = "CoffeeExitDoor", axis = "X", x = 156, z = 1700, west = "Burger House", east = "Coffee Shop", color = "Bright yellow", textColor = Color3.fromRGB(255, 220, 70) },
	{ name = "BurgerEntryDoor", axis = "X", x = 196, z = 1700, west = "Burger House", east = "Coffee Shop", color = "Bright yellow", textColor = Color3.fromRGB(255, 220, 70) },

	{ name = "BurgerExitDoor", axis = "X", x = 508, z = 1700, west = "New Pizza Place", east = "Burger House", color = "Bright red", textColor = Color3.fromRGB(255, 120, 80) },
	{ name = "NewPizzaEntryDoor", axis = "X", x = 548, z = 1700, west = "New Pizza Place", east = "Burger House", color = "Bright red", textColor = Color3.fromRGB(255, 120, 80) },

	{ name = "NewPizzaExitDoor", axis = "X", x = 860, z = 1700, west = "Swimming Pool", east = "New Pizza Place", color = "Cyan", textColor = Color3.fromRGB(80, 220, 255) },
	{ name = "PoolEntryDoor", axis = "X", x = 900, z = 1700, west = "Swimming Pool", east = "New Pizza Place", color = "Cyan", textColor = Color3.fromRGB(80, 220, 255) },
	{ name = "PoolExitDoor", axis = "X", x = 1212, z = 1700, west = "Dinosaur Park", east = "Swimming Pool", color = "Bright green", textColor = Color3.fromRGB(100, 255, 110) },
	{ name = "DinosaurEntryDoor", axis = "X", x = 1252, z = 1700, west = "Dinosaur Park", east = "Swimming Pool", color = "Bright green", textColor = Color3.fromRGB(100, 255, 110) },
	{ name = "DinosaurExitDoor", axis = "X", x = 1564, z = 1700, west = "Dino Beach", east = "Dinosaur Park", color = "Bright yellow", textColor = Color3.fromRGB(255, 230, 90) },
	{ name = "DinoBeachEntryDoor", axis = "X", x = 1604, z = 1700, west = "Dino Beach", east = "Dinosaur Park", color = "Bright yellow", textColor = Color3.fromRGB(255, 230, 90) },
	{ name = "DinoBeachExitDoor", axis = "X", x = 1916, z = 1700, west = "Flying Dino Forest", east = "Dino Beach", color = "Bright green", textColor = Color3.fromRGB(100, 255, 110) },
	{ name = "FlyingDinoForestEntryDoor", axis = "X", x = 1956, z = 1700, west = "Flying Dino Forest", east = "Dino Beach", color = "Bright green", textColor = Color3.fromRGB(100, 255, 110) },
	{ name = "FlyingDinoForestExitDoor", axis = "X", x = 2268, z = 1700, west = "Cherry Grove", east = "Flying Dino Forest", color = "Really red", textColor = Color3.fromRGB(255, 80, 80) },
	{ name = "CherryGroveEntryDoor", axis = "X", x = 2308, z = 1700, west = "Cherry Grove", east = "Flying Dino Forest", color = "Really red", textColor = Color3.fromRGB(255, 80, 80) },
	{ name = "CherryGroveExitDoor", axis = "X", x = 2620, z = 1700, west = "Galactic Orchard", east = "Cherry Grove", color = "Cyan", textColor = Color3.fromRGB(80, 240, 255) },
	{ name = "GalacticFruitEntryDoor", axis = "X", x = 2660, z = 1700, west = "Galactic Orchard", east = "Cherry Grove", color = "Cyan", textColor = Color3.fromRGB(80, 240, 255) },
	{ name = "GalacticFruitExitDoor", axis = "X", x = 2980, z = 1700, west = "Finish Gate", east = "Galactic Orchard", color = "Hot pink", textColor = Color3.fromRGB(255, 90, 220) },
}

local function makePart(name, size, cf, brick, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(brick)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function addText(part, face, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 28
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -14, 1, -8)
	label.Position = UDim2.new(0, 7, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = WorldOrder.formatName(text)
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end

local function buildZDoor(data)
	local x, z = data.x or 0, data.z
	local color = data.color

	makePart(data.name .. "_LeftPost", Vector3.new(1.1, 12, 0.72), CFrame.new(x - 7.4, 6.5, z), color, Enum.Material.Neon, 0.1)
	makePart(data.name .. "_RightPost", Vector3.new(1.1, 12, 0.72), CFrame.new(x + 7.4, 6.5, z), color, Enum.Material.Neon, 0.1)
	makePart(data.name .. "_TopBeam", Vector3.new(15.8, 1.1, 0.72), CFrame.new(x, 12.1, z), color, Enum.Material.Neon, 0.08)
	makePart(data.name .. "_Threshold", Vector3.new(15.8, 0.35, 0.72), CFrame.new(x, 1.12, z), color, Enum.Material.Neon, 0.3)

	local sign = makePart(data.name .. "_TwoSideSign", Vector3.new(13.2, 2.55, 0.38), CFrame.new(x, 14.05, z), "Really black")
	addText(sign, Enum.NormalId.Front, data.north, data.textColor)
	addText(sign, Enum.NormalId.Back, data.south, WHITE)
	makePart(data.name .. "_SignGlowTop", Vector3.new(13.8, 0.25, 0.44), CFrame.new(x, 15.48, z), color, Enum.Material.Neon, 0.12)
	makePart(data.name .. "_SignGlowBottom", Vector3.new(13.8, 0.25, 0.44), CFrame.new(x, 12.62, z), color, Enum.Material.Neon, 0.12)
end

local function buildXDoor(data)
	local x, z = data.x, data.z
	local color = data.color

	makePart(data.name .. "_LeftPost", Vector3.new(0.72, 12, 1.1), CFrame.new(x, 6.5, z - 7.4), color, Enum.Material.Neon, 0.1)
	makePart(data.name .. "_RightPost", Vector3.new(0.72, 12, 1.1), CFrame.new(x, 6.5, z + 7.4), color, Enum.Material.Neon, 0.1)
	makePart(data.name .. "_TopBeam", Vector3.new(0.72, 1.1, 15.8), CFrame.new(x, 12.1, z), color, Enum.Material.Neon, 0.08)
	makePart(data.name .. "_Threshold", Vector3.new(0.72, 0.35, 15.8), CFrame.new(x, 1.12, z), color, Enum.Material.Neon, 0.3)

	local sign = makePart(data.name .. "_TwoSideSign", Vector3.new(0.38, 2.55, 13.2), CFrame.new(x, 14.05, z), "Really black")
	addText(sign, Enum.NormalId.Left, data.west, data.textColor)
	addText(sign, Enum.NormalId.Right, data.east, WHITE)
	makePart(data.name .. "_SignGlowTop", Vector3.new(0.44, 0.25, 13.8), CFrame.new(x, 15.48, z), color, Enum.Material.Neon, 0.12)
	makePart(data.name .. "_SignGlowBottom", Vector3.new(0.44, 0.25, 13.8), CFrame.new(x, 12.62, z), color, Enum.Material.Neon, 0.12)
end

for _, data in DOORS do
	if data.axis == "X" then
		buildXDoor(data)
	else
		buildZDoor(data)
	end
end

print("[DoorSigns] Built unified entry/exit doors with signs on both sides.")
