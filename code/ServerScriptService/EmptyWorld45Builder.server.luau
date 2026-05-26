-- EmptyWorld45Builder.server.luau
-- World 45: showcase room for the imported model named "67".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CX, CZ = -2860, 9150
local FLOOR_Y = 1
local SIZE = 400

local folder = workspace:FindFirstChild("EmptyWorld45World")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "EmptyWorld45World"
folder.Parent = workspace

local function mkp(name, size, cf, color, mat, trans, noCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.BrickColor = BrickColor.new(color)
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = trans or 0
	p.Anchored = true
	p.CanCollide = not noCollide
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function neon(name, size, cf, color, trans)
	return mkp(name, size, cf, color, Enum.Material.Neon, trans, true)
end

local H = SIZE / 2

mkp("Floor", Vector3.new(SIZE, 4, SIZE), CFrame.new(CX, FLOOR_Y - 1, CZ), "Really black")
mkp("Ceiling", Vector3.new(SIZE, 2, SIZE), CFrame.new(CX, FLOOR_Y + 60, CZ), "Institutional white", Enum.Material.Glass, 0.7, true)
mkp("WallN", Vector3.new(SIZE, 64, 2), CFrame.new(CX, FLOOR_Y + 32, CZ - H), "Really black")
mkp("WallS", Vector3.new(SIZE, 64, 2), CFrame.new(CX, FLOOR_Y + 32, CZ + H), "Really black")
mkp("WallE", Vector3.new(2, 64, SIZE), CFrame.new(CX + H, FLOOR_Y + 32, CZ), "Really black")
mkp("WallW", Vector3.new(2, 64, SIZE), CFrame.new(CX - H, FLOOR_Y + 32, CZ), "Really black")

for _, xOff in { -H + 1, H - 1 } do
	neon("EdgeX", Vector3.new(2, 0.2, SIZE), CFrame.new(CX + xOff, FLOOR_Y + 1.1, CZ), "Hot pink", 0.2)
end
for _, zOff in { -H + 1, H - 1 } do
	neon("EdgeZ", Vector3.new(SIZE, 0.2, 2), CFrame.new(CX, FLOOR_Y + 1.1, CZ + zOff), "Hot pink", 0.2)
end

local GRID = 80
for i = -2, 2 do
	neon("GridX", Vector3.new(SIZE - 2, 0.15, 0.4), CFrame.new(CX, FLOOR_Y + 1.05, CZ + i * GRID), "Bright violet", 0.5)
	neon("GridZ", Vector3.new(0.4, 0.15, SIZE - 2), CFrame.new(CX + i * GRID, FLOOR_Y + 1.05, CZ), "Bright violet", 0.5)
end

local function addBillboard(parent, text, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Imported67Name"
	billboard.Size = UDim2.fromOffset(220, 52)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 300
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.18
	label.BackgroundColor3 = Color3.fromRGB(12, 8, 18)
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 245, 255)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

local function findImport67()
	return workspace:FindFirstChild("67", true)
		or ServerStorage:FindFirstChild("67", true)
		or ReplicatedStorage:FindFirstChild("67", true)
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

local function placeImport67()
	local source = highestModel(findImport67())
	if not source then
		local marker = neon("MissingImport67", Vector3.new(18, 18, 18), CFrame.new(CX, FLOOR_Y + 10, CZ), "Really red", 0.35)
		addBillboard(marker, "MISSING 67", Color3.fromRGB(255, 110, 110))
		warn("[EmptyWorld45] Could not find imported model named 67 in Workspace, ServerStorage, or ReplicatedStorage.")
		return
	end

	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = "Imported67"
	clone.Parent = folder

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
		end
	end

	local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart", true) or clone:FindFirstChildWhichIsA("BasePart", true)
	if not root then
		local marker = neon("EmptyImport67", Vector3.new(18, 18, 18), CFrame.new(CX, FLOOR_Y + 10, CZ), "New Yeller", 0.35)
		addBillboard(marker, "67 HAS NO PARTS", Color3.fromRGB(255, 240, 120))
		warn("[EmptyWorld45] Imported model 67 exists but has no BasePart descendants.")
		return
	end

	clone.PrimaryPart = root
	local _, sizeBefore = clone:GetBoundingBox()
	if sizeBefore.Y > 0 then
		local scaleFactor = math.clamp(28 / sizeBefore.Y, 0.03, 40)
		pcall(function()
			clone:ScaleTo(scaleFactor)
		end)
	end

	local boxCf, sizeAfter = clone:GetBoundingBox()
	local targetCenter = Vector3.new(CX, FLOOR_Y + math.max(5, sizeAfter.Y * 0.5), CZ)
	local pivotOffsetFromBox = boxCf:ToObjectSpace(clone:GetPivot())
	clone:PivotTo(CFrame.new(targetCenter) * CFrame.Angles(0, math.rad(180), 0) * pivotOffsetFromBox)

	addBillboard(root, "67", Color3.fromRGB(255, 180, 255))

	local highlight = Instance.new("Highlight")
	highlight.Name = "Imported67Highlight"
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(255, 90, 220)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = clone

	print("[EmptyWorld45] Imported model 67 placed from " .. source:GetFullName())
end

placeImport67()

print("[EmptyWorld45] Room built at CZ=" .. CZ)
