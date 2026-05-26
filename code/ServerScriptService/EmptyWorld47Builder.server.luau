-- EmptyWorld47Builder.server.luau
-- World 47: visual-only duplicate of Level 20's imported 3D characters.
-- This room is intentionally display-only: no patrols, combat, damage, or gameplay hooks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local WorldFramework = require(script.Parent:WaitForChild("WorldFramework"))

local CX, CZ = -2860, 11250
local FLOOR_Y = 1
local LEVEL20_MIN_X, LEVEL20_MAX_X = -3210, -2510
local LEVEL20_MIN_Z, LEVEL20_MAX_Z = 1420, 1980

local folder = nil

local function makePart(name, size, cf, material, color, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Material = material
	part.Color = color
	part.Transparency = transparency
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
	return makePart(name, size, cf, Enum.Material.Neon, color, transparency, false)
end

local function buildRoom()
	local oldFrameworkFolder = workspace:FindFirstChild("EmptyWorld47")
	if oldFrameworkFolder then oldFrameworkFolder:Destroy() end

	local oldCustomFolder = workspace:FindFirstChild("EmptyWorld47World")
	if oldCustomFolder then oldCustomFolder:Destroy() end

	folder = WorldFramework.build({
		name      = "EmptyWorld47",
		cx        = CX,
		cz        = CZ,
		halfW     = 350,
		halfD     = 280,
		floorY      = 1,
		floorThick  = 3,
		floorColor  = "Navy blue",
		gridColor   = "Hot pink",
		gridStep    = 16,
		gridAlpha   = 0.18,
		wallH       = 28,
		wallThick   = 0.9,
		wallColor   = "Dark indigo",
		wallAlpha   = 0.4,
		containH    = 400,
		northGap    = 0,
		southGap    = 25,
		eastGap     = 25,
		westGap     = 25,
	})
end

local function addBillboard(parent, text, height)
	local existing = parent:FindFirstChild("World47StaticLabel")
	if existing then
		existing:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "World47StaticLabel"
	billboard.Size = UDim2.fromOffset(260, 58)
	billboard.StudsOffset = Vector3.new(0, height or 8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 520
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.18
	label.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(190, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

local function isWorld47Object(object)
	return folder and (object == folder or object:IsDescendantOf(folder))
end

local function isDisplayCopy(object)
	local name = object.Name
	return name:find("^World47_", 1) ~= nil
		or name:find("^Missing_", 1) ~= nil
end

local function findSourceByName(name)
	local storageSource = ServerStorage:FindFirstChild(name, true)
	if storageSource then return storageSource end

	local replicatedSource = ReplicatedStorage:FindFirstChild(name, true)
	if replicatedSource then return replicatedSource end

	local directWorkspaceSource = workspace:FindFirstChild(name)
	if directWorkspaceSource and not isWorld47Object(directWorkspaceSource) then
		return directWorkspaceSource
	end

	for _, object in ipairs(workspace:GetDescendants()) do
		if object.Name == name and not isWorld47Object(object) and not isDisplayCopy(object) then
			return object
		end
	end

	return nil
end

local function findSource(names)
	if type(names) == "string" then
		return findSourceByName(names), names
	end

	for _, name in ipairs(names) do
		local source = findSourceByName(name)
		if source then
			return source, name
		end
	end

	return nil, nil
end

local function highestModel(object)
	local model = object and (object:IsA("Model") and object or object:FindFirstAncestorWhichIsA("Model"))
	if not model then return nil end

	local highest = model
	while highest.Parent and highest.Parent:IsA("Model") do
		highest = highest.Parent
	end
	return highest
end

local function hasImportedVisualGeometry(model)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("MeshPart") or object:IsA("SpecialMesh") or object:IsA("Bone") or object:IsA("AnimationController") then
			return true
		end
	end
	return false
end

local function findLevel20VisualModel(index)
	local candidates = {}
	for _, object in ipairs(workspace:GetChildren()) do
		if object:IsA("Model") and not isWorld47Object(object) and not isDisplayCopy(object) and object:FindFirstChildWhichIsA("BasePart", true) then
			local cf = object:GetBoundingBox()
			local p = cf.Position
			if p.X >= LEVEL20_MIN_X and p.X <= LEVEL20_MAX_X and p.Z >= LEVEL20_MIN_Z and p.Z <= LEVEL20_MAX_Z and hasImportedVisualGeometry(object) then
				table.insert(candidates, object)
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.Name < b.Name
	end)

	return candidates[index]
end

local function prepareStaticModel(model)
	for _, object in ipairs(model:GetDescendants()) do
		object.Archivable = true
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CastShadow = true
			object.Transparency = 0
			object.LocalTransparencyModifier = 0
			object.AssemblyLinearVelocity = Vector3.zero
			object.AssemblyAngularVelocity = Vector3.zero
			if object:IsA("MeshPart") then
				object.DoubleSided = true
				object.RenderFidelity = Enum.RenderFidelity.Precise
			end
		elseif object:IsA("Humanoid") then
			object.WalkSpeed = 0
			object.JumpPower = 0
			object.AutoRotate = false
		elseif object:IsA("Script") or object:IsA("LocalScript") then
			object.Disabled = true
		end
	end
end

local function placeMissingMarker(name, cloneName, x, z)
	local marker = neonPart("Missing_" .. cloneName, Vector3.new(22, 22, 22), CFrame.new(x, FLOOR_Y + 13, z), Color3.fromRGB(255, 40, 40), 0.15)
	addBillboard(marker, "MISSING " .. name, 14)
	warn("[EmptyWorld47] Missing visual source:", name)
end

local function placeStaticImport(sourceNames, cloneName, x, z, yawDegrees, level20FallbackIndex, targetHeight)
	local existing = folder:FindFirstChild("World47_" .. cloneName)
	if existing then existing:Destroy() end
	local existingMissing = folder:FindFirstChild("Missing_" .. cloneName)
	if existingMissing then existingMissing:Destroy() end

	local foundObject, foundName = findSource(sourceNames)
	if not foundObject and level20FallbackIndex then
		foundObject = findLevel20VisualModel(level20FallbackIndex)
		foundName = foundObject and foundObject.Name or nil
	end

	local source = highestModel(foundObject)
	if not source and foundObject and foundObject:IsA("BasePart") then
		local partClone = foundObject:Clone()
		local wrapper = Instance.new("Model")
		wrapper.Name = foundName or cloneName
		partClone.Parent = wrapper
		source = wrapper
	end

	if not source or not source:FindFirstChildWhichIsA("BasePart", true) then
		local label = type(sourceNames) == "table" and table.concat(sourceNames, "/") or sourceNames
		placeMissingMarker(label, cloneName, x, z)
		return nil
	end

	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = "World47_" .. cloneName
	clone.Parent = folder
	prepareStaticModel(clone)

	if targetHeight then
		local _, sizeBeforeScale = clone:GetBoundingBox()
		if sizeBeforeScale.Y > 0 then
			local scaleFactor = math.clamp(targetHeight / sizeBeforeScale.Y, 0.03, 40)
			pcall(function()
				clone:ScaleTo(scaleFactor)
			end)
		end
	end

	local root = clone.PrimaryPart
		or clone:FindFirstChild("HumanoidRootPart", true)
		or clone:FindFirstChild("RootPart", true)
		or clone:FindFirstChildWhichIsA("BasePart", true)

	if not root then
		clone:Destroy()
		placeMissingMarker(foundName or cloneName, cloneName, x, z)
		return nil
	end

	clone.PrimaryPart = root
	local boxCf, size = clone:GetBoundingBox()
	local targetCenter = Vector3.new(x, FLOOR_Y + math.max(2, size.Y * 0.5), z)
	local pivotOffsetFromBox = boxCf:ToObjectSpace(clone:GetPivot())
	clone:PivotTo(CFrame.new(targetCenter) * CFrame.Angles(0, math.rad(yawDegrees or 180), 0) * pivotOffsetFromBox)
	addBillboard(root, cloneName, math.max(9, size.Y * 0.65))

	neonPart("World47_" .. cloneName .. "_CenterMarker", Vector3.new(18, 0.35, 18), CFrame.new(x, FLOOR_Y + 1.4, z), Color3.fromRGB(40, 255, 255), 0.35)

	print("[EmptyWorld47] Placed static 3D", cloneName, "from", source:GetFullName())
	return clone
end

local function clearPlacedImports()
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name:find("^World47_", 1) or child.Name:find("^Missing_", 1) then
			child:Destroy()
		end
	end
end

local function placeVisualImports()
	clearPlacedImports()

	local slots = {
		{ "goblin1", "goblin1", CX, CZ, 180, nil, 18 },
	}

	for _, slot in ipairs(slots) do
		placeStaticImport(slot[1], slot[2], slot[3], slot[4], slot[5], slot[6], slot[7])
	end
end

buildRoom()
placeVisualImports()

-- Studio imports and level 20 placement can appear after server scripts start.
-- Keep retrying for a short time so late-loaded imported models get copied into 47.
for _, delaySeconds in ipairs({ 2, 5, 10, 20, 35, 55 }) do
	task.delay(delaySeconds, function()
		if folder.Parent then
			placeVisualImports()
		end
	end)
end
