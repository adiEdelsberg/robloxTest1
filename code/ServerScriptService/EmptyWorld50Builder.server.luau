-- EmptyWorld50Builder.server.luau
-- Level 50: clean copy of level 49 room geometry with one goblin for 1v1 testing.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CX, CZ = -2860, 14300
local FLOOR_Y = 1
local HALF_W = 350
local HALF_D = 280
local WALL_H = 60
local CONTAIN_H = 400
local GOBLIN_SCALE = 0.3
local GOBLIN_ROTATION = CFrame.Angles(0,math.rad(90), 0)
local GOBLIN_LIFT = 0
local GOBLIN_WALK_ANIMATION_ID_FALLBACK = 107190533745367
local WALK_ANIMATION_GROUND_OFFSET = 0

local old = workspace:FindFirstChild("EmptyWorld50")
if old then
	old:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = "EmptyWorld50"
folder.Parent = workspace

local function part(name, size, cf, transparency, canCollide, material, color)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cf
	object.BrickColor = BrickColor.new(color or "Really black")
	object.Material = material or Enum.Material.Glass
	object.Transparency = transparency
	object.Anchored = true
	object.CanCollide = canCollide
	object.CanTouch = false
	object.CastShadow = false
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = folder
	return object
end

local fullW = HALF_W * 2
local fullD = HALF_D * 2
local minX, maxX = CX - HALF_W, CX + HALF_W
local minZ, maxZ = CZ - HALF_D, CZ + HALF_D

part("GrassFloor", Vector3.new(fullW, 3, fullD), CFrame.new(CX, FLOOR_Y - 1.5, CZ), 0, true, Enum.Material.Grass, "Bright green")

part("TransparentWallN", Vector3.new(fullW, WALL_H, 2), CFrame.new(CX, FLOOR_Y + WALL_H / 2, minZ), 0.9, true)
part("TransparentWallS", Vector3.new(fullW, WALL_H, 2), CFrame.new(CX, FLOOR_Y + WALL_H / 2, maxZ), 0.9, true)
part("TransparentWallW", Vector3.new(2, WALL_H, fullD), CFrame.new(minX, FLOOR_Y + WALL_H / 2, CZ), 0.9, true)
part("TransparentWallE", Vector3.new(2, WALL_H, fullD), CFrame.new(maxX, FLOOR_Y + WALL_H / 2, CZ), 0.9, true)

part("ContainN", Vector3.new(fullW, CONTAIN_H, 1), CFrame.new(CX, FLOOR_Y + CONTAIN_H / 2, minZ), 1, true)
part("ContainS", Vector3.new(fullW, CONTAIN_H, 1), CFrame.new(CX, FLOOR_Y + CONTAIN_H / 2, maxZ), 1, true)
part("ContainW", Vector3.new(1, CONTAIN_H, fullD), CFrame.new(minX, FLOOR_Y + CONTAIN_H / 2, CZ), 1, true)
part("ContainE", Vector3.new(1, CONTAIN_H, fullD), CFrame.new(maxX, FLOOR_Y + CONTAIN_H / 2, CZ), 1, true)

local function findGoblinSource()
	return workspace:FindFirstChild("goblin1", true)
		or ServerStorage:FindFirstChild("goblin1", true)
		or ReplicatedStorage:FindFirstChild("goblin1", true)
end

local function waitForGoblinSource(timeoutSeconds)
	local deadline = os.clock() + timeoutSeconds
	local source = findGoblinSource()
	while not source and os.clock() < deadline do
		task.wait(0.5)
		source = findGoblinSource()
	end
	return source
end

local function getVisiblePartBottomY(model, meshOnly)
	local bottomY = nil
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart")
			and object.Transparency < 1
			and object.Name ~= "HumanoidRootPart"
			and object.Name ~= "RootPart"
			and object.Name ~= "GoblinCollisionBody"
			and (not meshOnly or object:IsA("MeshPart"))
		then
			local half = object.Size * 0.5
			for _, x in ipairs({ -half.X, half.X }) do
				for _, y in ipairs({ -half.Y, half.Y }) do
					for _, z in ipairs({ -half.Z, half.Z }) do
						local corner = object.CFrame:PointToWorldSpace(Vector3.new(x, y, z))
						bottomY = bottomY and math.min(bottomY, corner.Y) or corner.Y
					end
				end
			end
		end
	end
	return bottomY
end

local function getVisualMeshBottomY(model)
	return getVisiblePartBottomY(model, true) or getVisiblePartBottomY(model, false)
end

local function floorAlignedCF(model, cf, extraLift)
	model:PivotTo(cf)
	local boxCf, size = model:GetBoundingBox()
	local bottomY = getVisualMeshBottomY(model) or (boxCf.Position.Y - size.Y / 2)
	return cf + Vector3.new(0, FLOOR_Y - bottomY + (extraLift or 0), 0)
end

local function keepModelOnFloor(model, baseCF)
	model:PivotTo(baseCF)
	local boxCf, size = model:GetBoundingBox()
	local bottomY = boxCf.Position.Y - size.Y / 2
	local correctedCF = baseCF + Vector3.new(0, FLOOR_Y - bottomY, 0)
	model:PivotTo(correctedCF)
	return correctedCF
end

local function keepVisibleModelOnFloor(model, baseCF)
	model:PivotTo(baseCF)
	local bottomY = getVisualMeshBottomY(model)
	if not bottomY then
		local boxCf, size = model:GetBoundingBox()
		bottomY = boxCf.Position.Y - size.Y / 2
	end
	local correctedCF = baseCF + Vector3.new(0, FLOOR_Y - bottomY, 0)
	model:PivotTo(correctedCF)
	return correctedCF
end

local function lockStationaryModelOnFloor(model, floorCF)
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			connection:Disconnect()
			return
		end

		keepVisibleModelOnFloor(model, floorCF + Vector3.new(0, WALK_ANIMATION_GROUND_OFFSET, 0))
	end)
end

local function removeGeneratedGoblinObjects(model)
	for _, object in ipairs(model:GetDescendants()) do
		if object.Name == "GoblinCollisionBody"
			or object.Name == "ImportNameLabel"
			or object.Name == "MovementLabImportLabel"
			or object.Name == "GoblinTextAnchor"
			or object.Name == "GoblinBlinkHighlight"
			or object.Name == "GoblinBlinkLight"
		then
			object:Destroy()
		end
	end
end

local function addGoblinCollisionBody(model)
	local boxCf, size = model:GetBoundingBox()
	local height = math.max(5, size.Y * 0.75)

	local collider = Instance.new("Part")
	collider.Name = "GoblinCollisionBody"
	collider.Size = Vector3.new(math.max(3, size.X * 0.45), height, math.max(3, size.Z * 0.45))
	collider.CFrame = CFrame.new(boxCf.Position.X, FLOOR_Y + height / 2, boxCf.Position.Z)
	collider.Transparency = 1
	collider.Anchored = true
	collider.CanCollide = true
	collider.CanTouch = false
	collider.CanQuery = false
	collider.CastShadow = false
	collider.Parent = model
end

local function getAnimatorParent(model)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local parent = humanoid or controller
	if not parent then
		controller = Instance.new("AnimationController")
		controller.Name = "RuntimeAnimationController"
		controller.Parent = model
		parent = controller
	end

	local animator = parent:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = parent
	end

	return parent, animator
end

local function getGoblinAnimationId(name, fallback)
	local animationIds = ReplicatedStorage:FindFirstChild("GoblinAnimationIds")
	if animationIds then
		local value = animationIds:GetAttribute(name)
		if type(value) == "number" then
			return value
		end
	end
	return fallback
end

local function loadTrack(model, name, animationId, looped, priority)
	local parent, animator = getAnimatorParent(model)
	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = "rbxassetid://" .. tostring(animationId)
	animation.Parent = parent

	local ok, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not trackOrError then
		warn("[EmptyWorld50Builder] Could not load animation " .. tostring(animationId), trackOrError)
		return nil
	end

	local track = trackOrError
	track.Looped = looped
	track.Priority = priority or Enum.AnimationPriority.Movement
	return track
end

local function stopTracks(animator)
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.05)
	end
end

local function playStationaryWalk(model, floorCF)
	local _, animator = getAnimatorParent(model)
	stopTracks(animator)

	local walkTrack = loadTrack(model, "GoblinStationaryWalkLoop", getGoblinAnimationId("GOBLIN_WALK_ANIMATION_ID", GOBLIN_WALK_ANIMATION_ID_FALLBACK), true, Enum.AnimationPriority.Movement)
	if walkTrack then
		walkTrack:Play(0.15, 1, 1)
	end
	lockStationaryModelOnFloor(model, floorCF)
end

local function placeGoblin()
	local source = waitForGoblinSource(60)
	if not source then
		warn("[EmptyWorld50Builder] Missing goblin1 source; no 1v1 goblin placed.")
		return
	end

	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = "World50_goblin_501"
	clone.Parent = folder
	removeGeneratedGoblinObjects(clone)
	clone:ScaleTo(GOBLIN_SCALE)

	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.AssemblyLinearVelocity = Vector3.zero
			object.AssemblyAngularVelocity = Vector3.zero
		elseif object:IsA("Humanoid") then
			object.WalkSpeed = 0
			object.JumpPower = 0
			object.AutoRotate = false
		end
	end

	local placedCF = floorAlignedCF(clone, CFrame.new(CX, FLOOR_Y + 100, CZ) * GOBLIN_ROTATION, GOBLIN_LIFT)
	clone:PivotTo(placedCF)
	placedCF = keepVisibleModelOnFloor(clone, placedCF)
	addGoblinCollisionBody(clone)
	playStationaryWalk(clone, placedCF)
	print("[EmptyWorld50Builder] Placed 1v1 goblin 501.")
end

task.spawn(function()
	task.wait(1)
	placeGoblin()
end)

print("[EmptyWorld50Builder] Level 50 built at CZ=" .. tostring(CZ))
