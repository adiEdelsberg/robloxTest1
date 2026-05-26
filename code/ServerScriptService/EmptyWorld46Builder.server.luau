-- EmptyWorld46Builder.server.luau
-- World 46: huge empty transparent room, four times wider/deeper than room 45.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CX, CZ = -2860, 9800
local FLOOR_Y = 1
local SIZE = 1600 -- room 45 is 400, so this footprint is 4x wider/deeper.
local WALL_HEIGHT = 160

local folder = workspace:FindFirstChild("EmptyWorld46World")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "EmptyWorld46World"
folder.Parent = workspace

local function glassPart(name, size, cf, color, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(color)
	part.Material = Enum.Material.Glass
	part.Transparency = transparency
	part.Reflectance = 0.08
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function neonPart(name, size, cf, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(color)
	part.Material = Enum.Material.Neon
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

local H = SIZE / 2
local floorAlpha = 0.82
local wallAlpha = 0.86

glassPart("TransparentFloor", Vector3.new(SIZE, 3, SIZE), CFrame.new(CX, FLOOR_Y - 1, CZ), "Institutional white", floorAlpha, true)
glassPart("TransparentCeiling", Vector3.new(SIZE, 2, SIZE), CFrame.new(CX, FLOOR_Y + WALL_HEIGHT, CZ), "Institutional white", 0.9, false)
glassPart("TransparentWallN", Vector3.new(SIZE, WALL_HEIGHT, 3), CFrame.new(CX, FLOOR_Y + WALL_HEIGHT / 2, CZ - H), "Toothpaste", wallAlpha, true)
glassPart("TransparentWallS", Vector3.new(SIZE, WALL_HEIGHT, 3), CFrame.new(CX, FLOOR_Y + WALL_HEIGHT / 2, CZ + H), "Toothpaste", wallAlpha, true)
glassPart("TransparentWallE", Vector3.new(3, WALL_HEIGHT, SIZE), CFrame.new(CX + H, FLOOR_Y + WALL_HEIGHT / 2, CZ), "Toothpaste", wallAlpha, true)
glassPart("TransparentWallW", Vector3.new(3, WALL_HEIGHT, SIZE), CFrame.new(CX - H, FLOOR_Y + WALL_HEIGHT / 2, CZ), "Toothpaste", wallAlpha, true)

for _, xOff in { -H + 2, H - 2 } do
	neonPart("EdgeX", Vector3.new(3, 0.25, SIZE), CFrame.new(CX + xOff, FLOOR_Y + 1.05, CZ), "Cyan", 0.35)
end
for _, zOff in { -H + 2, H - 2 } do
	neonPart("EdgeZ", Vector3.new(SIZE, 0.25, 3), CFrame.new(CX, FLOOR_Y + 1.05, CZ + zOff), "Cyan", 0.35)
end

local gridStep = 200
for i = -3, 3 do
	neonPart("FloorGridX", Vector3.new(SIZE - 4, 0.15, 1.2), CFrame.new(CX, FLOOR_Y + 1.12, CZ + i * gridStep), "Electric blue", 0.62)
	neonPart("FloorGridZ", Vector3.new(1.2, 0.15, SIZE - 4), CFrame.new(CX + i * gridStep, FLOOR_Y + 1.12, CZ), "Electric blue", 0.62)
end

local function addBillboard(parent, text)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ImportName"
	billboard.Size = UDim2.fromOffset(280, 70)
	billboard.StudsOffset = Vector3.new(0, 14, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 700
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(8, 14, 20)
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(180, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

local function isInsideRoom46(object)
	return object == folder or object:IsDescendantOf(folder)
end

local function findImport(name)
	local exactStorage = ServerStorage:FindFirstChild(name, true)
	if exactStorage then return exactStorage end

	local exactReplicated = ReplicatedStorage:FindFirstChild(name, true)
	if exactReplicated then return exactReplicated end

	local exactWorkspace = workspace:FindFirstChild(name, true)
	if exactWorkspace and not isInsideRoom46(exactWorkspace) then
		return exactWorkspace
	end

	return nil
end

local function highestModel(object)
	local model = object and (object:IsA("Model") and object or object:FindFirstAncestorWhichIsA("Model"))
	if not model then
		return nil
	end

	local highest = model
	while highest.Parent and highest.Parent:IsA("Model") do
		highest = highest.Parent
	end
	return highest
end

local function removePreviousPlacement(sourceName)
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == "Room46_" .. sourceName
			or child.Name == "Missing_" .. sourceName
			or child.Name == "Empty_" .. sourceName
			or child.Name == "Platform_" .. sourceName then
			child:Destroy()
		end
	end
end

local function clearImportCopies()
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name:match("^Room46Copy_")
			or child.Name:match("^CopyPlatform_")
			or child.Name == "Room46_goblin3"
			or child.Name == "Room46_hero"
			or child.Name == "Platform_goblin3"
			or child.Name == "Platform_hero"
			or child.Name == "Missing_goblin3"
			or child.Name == "Missing_hero" then
			child:Destroy()
		end
	end
end

local function placeImportedModel(sourceName, x, z, label)
	removePreviousPlacement(sourceName)

	local platform = neonPart("Platform_" .. sourceName, Vector3.new(42, 0.45, 42), CFrame.new(x, FLOOR_Y + 1.35, z), "Cyan", 0.42)
	addBillboard(platform, (label or sourceName) .. "\nSOURCE SPOT")

	local source = highestModel(findImport(sourceName))
	if not source then
		local marker = neonPart("Missing_" .. sourceName, Vector3.new(18, 18, 18), CFrame.new(x, FLOOR_Y + 10, z), "Really red", 0.35)
		addBillboard(marker, "MISSING " .. sourceName)
		warn("[EmptyWorld46] Missing imported model:", sourceName)
		return nil
	end

	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = "Room46_" .. sourceName
	clone.Parent = folder

	local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart", true) or clone:FindFirstChild("RootPart", true) or clone:FindFirstChildWhichIsA("BasePart", true)
	if not root then
		local marker = neonPart("Empty_" .. sourceName, Vector3.new(18, 18, 18), CFrame.new(x, FLOOR_Y + 10, z), "New Yeller", 0.35)
		addBillboard(marker, sourceName .. " NO PARTS")
		warn("[EmptyWorld46] Imported model has no BasePart descendants:", sourceName)
		return clone
	end

	clone.PrimaryPart = root
	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = true
			object.CastShadow = true
			object.Transparency = 0
			object.LocalTransparencyModifier = 0
			if object:IsA("MeshPart") then
				object.DoubleSided = true
				object.RenderFidelity = Enum.RenderFidelity.Precise
			end
		elseif object:IsA("Humanoid") then
			object.WalkSpeed = 0
			object.JumpPower = 0
			object.AutoRotate = false
		end
	end

	local boxCf, size = clone:GetBoundingBox()
	local targetCenter = Vector3.new(x, FLOOR_Y + math.max(2, size.Y * 0.5), z)
	local pivotOffsetFromBox = boxCf:ToObjectSpace(clone:GetPivot())
	clone:PivotTo(CFrame.new(targetCenter) * CFrame.Angles(0, math.rad(180), 0) * pivotOffsetFromBox)
	addBillboard(root, label or sourceName)

	local highlight = Instance.new("Highlight")
	highlight.Name = "Room46ImportHighlight"
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(120, 255, 255)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = clone

	print("[EmptyWorld46] Placed " .. sourceName .. " at original size from " .. source:GetFullName())
	return clone
end

local function findCopySource()
	for _, name in ipairs({ "67", "goblin3", "hero", "Drooling Zombie" }) do
		local source = highestModel(findImport(name))
		if source and source:FindFirstChildWhichIsA("BasePart", true) then
			return source, name
		end
	end
	return nil, nil
end

local function placeOneCopy(source, sourceName, index, x, z)
	local platform = neonPart("CopyPlatform_" .. index, Vector3.new(38, 0.45, 38), CFrame.new(x, FLOOR_Y + 1.35, z), "Cyan", 0.42)
	addBillboard(platform, sourceName .. "\nCOPY " .. index)

	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = "Room46Copy_" .. index .. "_" .. sourceName:gsub("%s+", "")
	clone.Parent = folder

	local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart", true) or clone:FindFirstChild("RootPart", true) or clone:FindFirstChildWhichIsA("BasePart", true)
	if not root then
		addBillboard(platform, sourceName .. "\nNO PARTS")
		return nil
	end

	clone.PrimaryPart = root
	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = true
			object.CastShadow = true
			object.Transparency = 0
			object.LocalTransparencyModifier = 0
			if object:IsA("MeshPart") then
				object.DoubleSided = true
				object.RenderFidelity = Enum.RenderFidelity.Precise
			end
		elseif object:IsA("Humanoid") then
			object.WalkSpeed = 0
			object.JumpPower = 0
			object.AutoRotate = false
		end
	end

	local boxCf, size = clone:GetBoundingBox()
	local targetCenter = Vector3.new(x, FLOOR_Y + math.max(2, size.Y * 0.5), z)
	local pivotOffsetFromBox = boxCf:ToObjectSpace(clone:GetPivot())
	clone:PivotTo(CFrame.new(targetCenter) * CFrame.Angles(0, math.rad(180), 0) * pivotOffsetFromBox)
	addBillboard(root, sourceName .. " " .. index)

	local highlight = Instance.new("Highlight")
	highlight.Name = "Room46CopyHighlight"
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(120, 255, 255)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = clone

	return clone
end

local function placeRoom46Imports()
	clearImportCopies()
end

placeRoom46Imports()
task.delay(5, placeRoom46Imports)

print("[EmptyWorld46] Transparent 4x room built at CZ=" .. CZ)
