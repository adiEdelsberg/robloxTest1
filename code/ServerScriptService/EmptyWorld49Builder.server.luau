-- EmptyWorld49Builder.server.luau
-- Level 49: transparent test room, placed far away from other levels.
-- Goblin numbering convention: level number + number inside level.
-- First goblin in level 49 is labeled 491.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CX, CZ = -2860, 13000
local FLOOR_Y = 1
local HALF_W = 350
local HALF_D = 280
local WALL_H = 60
local CONTAIN_H = 400
local GOBLIN_ROTATION = CFrame.Angles(0, math.rad(90), 0)
local GOBLIN_LIFT = 0
local SECOND_GROUP_SCALE_MULTIPLIER = 0.03
local THIRD_GROUP_SCALE_MULTIPLIER = 0.08
local KICK_PUSH_BACK_SPEED = 95
local KICK_PUSH_UP_SPEED = 90
local KICK_IMPACT_DELAY = 1.4
local MMA_KICK_IMPACT_DELAY = 0.65
local KICK_IMPACT_WINDOW = 0.35
local DOUBLE_KICK_FORWARD_STEP = 4
local DOUBLE_KICK_CUT_AFTER_IMPACT = 1
local FLOOR_LOCK_ENABLED = true
local GROUP1_PATROL_SPEED = 7
local GROUP1_HUNTER_SPEED = 38
local GROUP1_HUNTER_ATTACK_SPEED = 38
local GROUP1_HUNTER_KICK_RANGE = 5
local GOBLIN_FAST_RUN_ANIMATION_ID = 100809685153003
local HUNTER_KICK_IMPACT_WINDOW = 0.7
local GROUP1_IDLE_SEARCH_MIN_WAIT = 1
local GROUP1_IDLE_SEARCH_MAX_WAIT = 30
local GROUP1_IDLE_SEARCH_DURATION = 2.2
local GROUP1_PATROL_POINTS = {
	Vector3.new(CX - 90, FLOOR_Y + 100, CZ - 80),
	Vector3.new(CX + 90, FLOOR_Y + 100, CZ - 80),
	Vector3.new(CX + 90, FLOOR_Y + 100, CZ + 80),
	Vector3.new(CX - 90, FLOOR_Y + 100, CZ + 80),
}
local STATIC_GOBLINS = {
	["496"] = true,
}
local GOBLIN_GROUP = {
	{ label = "491", offset = Vector3.new(0, 0, 0) },
	{ label = "492", offset = Vector3.new(-8, 0, 10) },
	{ label = "493", offset = Vector3.new(8, 0, 10) },
	{ label = "494", offset = Vector3.new(-4, 0, 18) },
	{ label = "495", offset = Vector3.new(4, 0, 18) },
	{ label = "496", offset = Vector3.new(32, 0, -4) },
	{ label = "497", offset = Vector3.new(24, 0, 6) },
	{ label = "498", offset = Vector3.new(40, 0, 6) },
	{ label = "499", offset = Vector3.new(28, 0, 14) },
	{ label = "4910", offset = Vector3.new(36, 0, 14) },
	{ label = "4911", offset = Vector3.new(-32, 0, -4) },
	{ label = "4912", offset = Vector3.new(-40, 0, 6) },
	{ label = "4913", offset = Vector3.new(-24, 0, 6) },
	{ label = "4914", offset = Vector3.new(-36, 0, 14) },
	{ label = "4915", offset = Vector3.new(-28, 0, 14) },
}

local old = workspace:FindFirstChild("EmptyWorld49")
if old then
	old:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = "EmptyWorld49"
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

local level49AnimationsActive = false
local group1States = {}
local group1LeaderPosition = Vector3.new(CX, FLOOR_Y + 100, CZ)
local group1FacingCF = GOBLIN_ROTATION
local group1Searching = false

local function isAnyPlayerInsideLevel49()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local position = hrp.Position
			if position.X >= minX and position.X <= maxX and position.Z >= minZ and position.Z <= maxZ then
				return true
			end
		end
	end
	return false
end

task.spawn(function()
	while folder.Parent do
		level49AnimationsActive = isAnyPlayerInsideLevel49()
		task.wait(0.25)
	end
end)

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

local function getVisiblePartBottomY(model)
	local bottomY = nil
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart")
			and object.Transparency < 1
			and object.Name ~= "HumanoidRootPart"
			and object.Name ~= "RootPart"
			and object.Name ~= "GoblinCollisionBody"
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

local function floorAlignedCF(model, cf, extraLift)
	model:PivotTo(cf)
	local boxCf, size = model:GetBoundingBox()
	local bottomY = getVisiblePartBottomY(model) or (boxCf.Position.Y - size.Y / 2)
	return cf + Vector3.new(0, FLOOR_Y - bottomY + (extraLift or 0), 0)
end

local function keepModelOnFloor(model, baseCF)
	model:PivotTo(baseCF)
	local boxCf, size = model:GetBoundingBox()
	local bottomY = boxCf.Position.Y - size.Y / 2
	model:PivotTo(baseCF + Vector3.new(0, FLOOR_Y - bottomY, 0))
end

local function keepVisibleModelOnFloor(model, baseCF)
	model:PivotTo(baseCF)
	local bottomY = getVisiblePartBottomY(model)
	if not bottomY then
		local boxCf, size = model:GetBoundingBox()
		bottomY = boxCf.Position.Y - size.Y / 2
	end
	model:PivotTo(baseCF + Vector3.new(0, FLOOR_Y - bottomY, 0))
end

local function addGoblinCollisionBody(model)
	local boxCf, size = model:GetBoundingBox()
	local height = 5
	local width = math.max(2, math.min(5, size.X * 0.35))
	local depth = math.max(2, math.min(5, size.Z * 0.35))

	local collider = Instance.new("Part")
	collider.Name = "GoblinCollisionBody"
	collider.Size = Vector3.new(width, height, depth)
	collider.CFrame = CFrame.new(boxCf.Position.X, FLOOR_Y + height / 2, boxCf.Position.Z)
	collider.Transparency = 1
	collider.Anchored = true
	collider.CanCollide = true
	collider.CanTouch = false
	collider.CanQuery = false
	collider.CastShadow = false
	collider.Parent = model
end

local function addStaticLabel(model, text)
	local sign = Instance.new("Part")
	sign.Name = "GoblinLabel_" .. text
	sign.Size = Vector3.new(9, 3.5, 0.1)
	sign.Transparency = 1
	sign.Anchored = true
	sign.CanCollide = false
	sign.CanTouch = false
	sign.CanQuery = false
	sign.CastShadow = false
	sign.Parent = folder

	local function addFace(face)
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 8
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = sign

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 1
		label.Font = Enum.Font.SourceSansBold
		label.TextScaled = true
		label.Parent = gui
	end

	addFace(Enum.NormalId.Front)
	addFace(Enum.NormalId.Back)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent or not sign.Parent then
			if sign.Parent then
				sign:Destroy()
			end
			connection:Disconnect()
			return
		end

		local boxCf, size = model:GetBoundingBox()
		sign.CFrame = CFrame.new(boxCf.Position.X, boxCf.Position.Y + size.Y / 2 + 5, boxCf.Position.Z) * CFrame.Angles(0, math.rad(180), 0)
	end)
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

local function loadTrack(model, animationId, looped, priority)
	local parent, animator = getAnimatorParent(model)
	if not parent or not animator then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.Name = "GoblinRuntimeAnimation"
	animation.AnimationId = "rbxassetid://" .. tostring(animationId)
	animation.Parent = parent

	local ok, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not trackOrError then
		warn("[EmptyWorld49Builder] Could not load animation " .. tostring(animationId) .. ":", trackOrError)
		return
	end

	local track = trackOrError
	track.Looped = looped
	track.Priority = priority or Enum.AnimationPriority.Movement
	return track
end

local function stopAnimatorTracks(animator)
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.1)
	end
end

local function waitForActiveRoom(model)
	while model.Parent and not level49AnimationsActive do
		task.wait(0.25)
	end
	return model.Parent ~= nil
end

local function waitActiveSeconds(model, seconds)
	local remaining = seconds
	while model.Parent and remaining > 0 do
		if level49AnimationsActive then
			local step = math.min(0.25, remaining)
			task.wait(step)
			remaining -= step
		else
			task.wait(0.25)
		end
	end
	return model.Parent ~= nil and level49AnimationsActive
end

local function waitActiveRoomSeconds(seconds)
	local remaining = seconds
	while folder.Parent and remaining > 0 do
		if level49AnimationsActive then
			local step = math.min(0.25, remaining)
			task.wait(step)
			remaining -= step
		else
			task.wait(0.25)
		end
	end
	return folder.Parent ~= nil and level49AnimationsActive
end

local function getClosestPlayerInLevel49(position)
	local closestPlayer = nil
	local closestHrp = nil
	local closestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local playerPosition = hrp.Position
			if playerPosition.X >= minX and playerPosition.X <= maxX and playerPosition.Z >= minZ and playerPosition.Z <= maxZ then
				local distance = (Vector3.new(playerPosition.X, 0, playerPosition.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestPlayer = player
					closestHrp = hrp
				end
			end
		end
	end

	return closestPlayer, closestHrp, closestDistance
end

local function floorFacingCF(position, direction)
	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude < 0.1 then
		return CFrame.new(position) * group1FacingCF
	end
	return CFrame.new(position) * (CFrame.lookAt(Vector3.zero, flatDirection.Unit) * GOBLIN_ROTATION)
end

local function pushPlayersHitByKick(model, durationSeconds)
	local boxCf, size = model:GetBoundingBox()
	local hitbox = Instance.new("Part")
	hitbox.Name = "GoblinKickHitbox"
	hitbox.Size = Vector3.new(math.max(8, size.X * 0.8), math.max(8, size.Y * 0.7), math.max(8, size.Z * 1.1))
	hitbox.CFrame = CFrame.new(boxCf.Position + Vector3.new(0, 2, 0))
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = true
	hitbox.Parent = folder

	local alreadyHit = {}
	local deadline = os.clock() + durationSeconds
	while model.Parent and hitbox.Parent and os.clock() < deadline do
		boxCf, size = model:GetBoundingBox()
		hitbox.CFrame = CFrame.new(boxCf.Position + Vector3.new(0, 2, 0))

		local touching = workspace:GetPartsInPart(hitbox)
		for _, part in ipairs(touching) do
			local character = part:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if player and not alreadyHit[player] then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					alreadyHit[player] = true
					local away = hrp.Position - boxCf.Position
					away = Vector3.new(away.X, 0, away.Z)
					if away.Magnitude < 0.1 then
						away = boxCf.LookVector
					end
					hrp.AssemblyLinearVelocity = away.Unit * KICK_PUSH_BACK_SPEED + Vector3.new(0, KICK_PUSH_UP_SPEED, 0)
				end
			end
		end
		task.wait(0.05)
	end

	hitbox:Destroy()
end

local function startGoblinAnimations(model, state)
	local floorCF = state.floorCF
	local _, animator = getAnimatorParent(model)
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0.05)
		end
	end

	local walkAnimationId = getGoblinAnimationId("GOBLIN_WALK_ANIMATION_ID", 107190533745367)
	local kickAnimationId = getGoblinAnimationId("GOBLIN_INSIDE_KICK_ANIMATION_ID", 124566055260637)
	local labelNumber = tonumber(model.Name:match("(%d+)$"))
	local isSecondGroup = labelNumber and labelNumber >= 496 and labelNumber < 4911
	local isThirdGroup = labelNumber and labelNumber >= 4911
	if isSecondGroup then
		kickAnimationId = getGoblinAnimationId("GOBLIN_DOUBLE_KICK_ANIMATION_ID", 127462757738787)
	end
	if isThirdGroup then
		kickAnimationId = getGoblinAnimationId("GOBLIN_MMA_KICK_ANIMATION_ID", 139956682286517)
	end
	local walkTrack = loadTrack(model, walkAnimationId, true, Enum.AnimationPriority.Movement)
	if walkTrack and level49AnimationsActive then
		walkTrack:Play(0.15, 1, 1)
	end

	local currentFloorCF = floorCF
	local isKicking = false
	local isSearching = false
	local floorLock
	if FLOOR_LOCK_ENABLED then
		floorLock = RunService.Heartbeat:Connect(function()
			if not model.Parent then
				floorLock:Disconnect()
				return
			end
			currentFloorCF = state.floorCF
			keepVisibleModelOnFloor(model, currentFloorCF)
		end)
	end

	task.spawn(function()
		while model.Parent do
			if not level49AnimationsActive then
				if animator then
					stopAnimatorTracks(animator)
				elseif walkTrack then
					walkTrack:Stop(0.1)
				end
				keepVisibleModelOnFloor(model, currentFloorCF)
			elseif walkTrack and not isKicking and not isSearching and not group1Searching and not walkTrack.IsPlaying then
				walkTrack:Play(0.15, 1, 1)
			end
			task.wait(0.25)
		end
	end)

	task.spawn(function()
		if not waitForActiveRoom(model) then return end
		waitActiveSeconds(model, math.random(1, 8))
		while model.Parent do
			if not waitActiveSeconds(model, math.random(10, 30)) then
				break
			end

			while (isSearching or group1Searching) and model.Parent do
				task.wait(0.25)
			end

			if walkTrack then
				walkTrack:Stop(0.1)
			end
			isKicking = true

			local kickTrack = loadTrack(model, kickAnimationId, false, Enum.AnimationPriority.Action)
			if kickTrack then
				kickTrack:Play(0.1, 1, 1)
				task.wait(isThirdGroup and MMA_KICK_IMPACT_DELAY or KICK_IMPACT_DELAY)
				task.spawn(pushPlayersHitByKick, model, KICK_IMPACT_WINDOW)
				if isSecondGroup then
					task.wait(DOUBLE_KICK_CUT_AFTER_IMPACT)
					kickTrack:Stop(0.03)
					currentFloorCF = currentFloorCF + Vector3.new(0, 0, -DOUBLE_KICK_FORWARD_STEP)
					state.floorCF = currentFloorCF
					if model.Parent then
						keepVisibleModelOnFloor(model, currentFloorCF)
					end
				else
					task.wait(KICK_IMPACT_WINDOW)
					kickTrack:Stop(0.1)
				end
			else
				task.wait(isThirdGroup and MMA_KICK_IMPACT_DELAY or KICK_IMPACT_DELAY)
				task.spawn(pushPlayersHitByKick, model, KICK_IMPACT_WINDOW)
				task.wait(KICK_IMPACT_WINDOW)
				if model.Parent and isSecondGroup then
					currentFloorCF = currentFloorCF + Vector3.new(0, 0, -DOUBLE_KICK_FORWARD_STEP)
					state.floorCF = currentFloorCF
				end
			end

			if group1Searching then
				if kickTrack then
					kickTrack:Stop(0.05)
				end
				isKicking = false
				continue
			end

			if not level49AnimationsActive then
				if kickTrack then
					kickTrack:Stop(0.05)
				end
				isKicking = false
				continue
			end

			if model.Parent then
				keepVisibleModelOnFloor(model, currentFloorCF)
			end
			isKicking = false
			if walkTrack and model.Parent then
				walkTrack:Play(0.15, 1, 1)
			end
		end
	end)
end

local function playHunterKick(state)
	local model = state.model
	local _, animator = getAnimatorParent(model)
	if animator then
		stopAnimatorTracks(animator)
	end

	local kickAnimationId = getGoblinAnimationId("GOBLIN_INSIDE_KICK_ANIMATION_ID", 124566055260637)
	local kickTrack = loadTrack(model, kickAnimationId, false, Enum.AnimationPriority.Action)
	if kickTrack then
		kickTrack:Play(0.1, 1, 1)
		task.wait(KICK_IMPACT_DELAY)
		task.spawn(pushPlayersHitByKick, model, HUNTER_KICK_IMPACT_WINDOW)
		task.wait(HUNTER_KICK_IMPACT_WINDOW)
		kickTrack:Stop(0.1)
	else
		task.wait(KICK_IMPACT_DELAY)
		task.spawn(pushPlayersHitByKick, model, HUNTER_KICK_IMPACT_WINDOW)
		task.wait(HUNTER_KICK_IMPACT_WINDOW)
	end
end

local function moveStateToward(state, targetPosition, speed)
	local currentPosition = state.floorCF.Position
	local delta = Vector3.new(targetPosition.X - currentPosition.X, 0, targetPosition.Z - currentPosition.Z)
	local distance = delta.Magnitude
	if distance < 0.5 then
		return true
	end

	local step = math.min(distance, speed * 0.05)
	local nextPosition = currentPosition + delta.Unit * step
	local flatDir = Vector3.new(delta.X, 0, delta.Z)
	local rotCF = CFrame.lookAt(Vector3.zero, flatDir.Unit) * GOBLIN_ROTATION
	state.floorCF = CFrame.new(nextPosition.X, state.floorY, nextPosition.Z) * rotCF
	return distance <= step + 0.5
end

local function startGroup1Hunter()
	task.spawn(function()
		local hunterState = nil
		while folder.Parent and not hunterState do
			for _, state in ipairs(group1States) do
				if state.label == "491" then
					hunterState = state
					break
				end
			end
			task.wait(0.25)
		end
		if not hunterState then return end

		while folder.Parent and hunterState.model.Parent do
			if not waitActiveSeconds(hunterState.model, math.random(1, 20)) then
				continue
			end
			if hunterState.isSearching then
				continue
			end

			local _, targetHrp = getClosestPlayerInLevel49(hunterState.floorCF.Position)
			if not targetHrp then
				continue
			end

			hunterState.isSolo = true

			-- play fast run animation for the chase
			local _, hunterAnimator = getAnimatorParent(hunterState.model)
			if hunterAnimator then stopAnimatorTracks(hunterAnimator) end
			local fastRunId = getGoblinAnimationId("GOBLIN_FAST_RUN_ANIMATION_ID", GOBLIN_FAST_RUN_ANIMATION_ID)
			local fastRunTrack = loadTrack(hunterState.model, fastRunId, true, Enum.AnimationPriority.Movement)
			if fastRunTrack then fastRunTrack:Play(0.1, 1, 1) end

			local startedAt = os.clock()
			while hunterState.model.Parent and targetHrp.Parent and level49AnimationsActive and os.clock() - startedAt < 10 do
				local distance = (Vector3.new(targetHrp.Position.X, 0, targetHrp.Position.Z) - Vector3.new(hunterState.floorCF.Position.X, 0, hunterState.floorCF.Position.Z)).Magnitude
				if distance <= GROUP1_HUNTER_KICK_RANGE then
					break
				end
				moveStateToward(hunterState, targetHrp.Position, GROUP1_HUNTER_ATTACK_SPEED)
				task.wait(0.05)
			end

			if fastRunTrack then fastRunTrack:Stop(0.1) end

			if hunterState.model.Parent and level49AnimationsActive then
				playHunterKick(hunterState)
			end

			-- return home with fast run
			if fastRunTrack and hunterState.model.Parent then fastRunTrack:Play(0.1, 1, 1) end
			while hunterState.model.Parent and level49AnimationsActive do
				local homePosition = group1LeaderPosition + hunterState.offset
				if moveStateToward(hunterState, homePosition, GROUP1_HUNTER_ATTACK_SPEED) then
					break
				end
				task.wait(0.05)
			end
			if fastRunTrack then fastRunTrack:Stop(0.1) end
			hunterState.isSolo = false
		end
	end)
end

local function placeGoblin(entry, source)
	if not source then
		warn("[EmptyWorld49Builder] Missing goblin1 source for goblin " .. entry.label)
		return
	end

	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = "World49_goblin_" .. entry.label
	clone.Parent = folder
	local labelNumber = tonumber(entry.label)
	if labelNumber and labelNumber >= 4911 then
		clone:ScaleTo(THIRD_GROUP_SCALE_MULTIPLIER)
	elseif labelNumber and labelNumber >= 496 then
		clone:ScaleTo(SECOND_GROUP_SCALE_MULTIPLIER)
	end

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

	local position = Vector3.new(CX, FLOOR_Y + 100, CZ) + entry.offset
	local placedCF = floorAlignedCF(clone, CFrame.new(position) * GOBLIN_ROTATION, GOBLIN_LIFT)
	local state = {
		model = clone,
		label = entry.label,
		offset = entry.offset,
		floorCF = placedCF,
		floorY = placedCF.Position.Y,
	}
	clone:PivotTo(placedCF)
	keepVisibleModelOnFloor(clone, placedCF)
	addGoblinCollisionBody(clone)
	addStaticLabel(clone, entry.label)
	if labelNumber and labelNumber >= 491 and labelNumber <= 495 then
		table.insert(group1States, state)
	end
	if not STATIC_GOBLINS[entry.label] then
		startGoblinAnimations(clone, state)
	end
	print("[EmptyWorld49Builder] Placed goblin " .. entry.label)
end

local function startGroup1Patrol()
	task.spawn(function()
		local pointIndex = 1
		group1LeaderPosition = Vector3.new(CX, FLOOR_Y + 100, CZ)
		group1FacingCF = GOBLIN_ROTATION
		local nextSearchAt = os.clock() + math.random(GROUP1_IDLE_SEARCH_MIN_WAIT, GROUP1_IDLE_SEARCH_MAX_WAIT)

		while folder.Parent do
			if #group1States == 0 or not level49AnimationsActive then
				task.wait(0.25)
				continue
			end

			if os.clock() >= nextSearchAt then
				group1Searching = true
				local tracks = {}
				local searchAnimationId = getGoblinAnimationId("GOBLIN_IDLE_SEARCH_ANIMATION_ID", 130540795443372)

				for _, state in ipairs(group1States) do
					if state.model.Parent and not state.isSolo then
						state.isSearching = true
						local _, animator = getAnimatorParent(state.model)
						if animator then
							stopAnimatorTracks(animator)
						end
						task.wait()
						if animator then
							stopAnimatorTracks(animator)
						end
						local track = loadTrack(state.model, searchAnimationId, false, Enum.AnimationPriority.Idle)
						if track then
							track:Play(0.1, 1, 1)
							table.insert(tracks, track)
						end
					end
				end

				waitActiveRoomSeconds(GROUP1_IDLE_SEARCH_DURATION)
				for _, track in ipairs(tracks) do
					track:Stop(0.1)
				end
				for _, state in ipairs(group1States) do
					state.isSearching = false
				end
				group1Searching = false
				local oldPointIndex = pointIndex
				if #GROUP1_PATROL_POINTS > 1 then
					repeat
						pointIndex = math.random(1, #GROUP1_PATROL_POINTS)
					until pointIndex ~= oldPointIndex
				end
				nextSearchAt = os.clock() + math.random(GROUP1_IDLE_SEARCH_MIN_WAIT, GROUP1_IDLE_SEARCH_MAX_WAIT)
			end

			local target = GROUP1_PATROL_POINTS[pointIndex]
			local delta = target - group1LeaderPosition
			local distance = delta.Magnitude
			if distance < 1 then
				pointIndex = (pointIndex % #GROUP1_PATROL_POINTS) + 1
				task.wait(0.1)
				continue
			end

			local step = math.min(distance, GROUP1_PATROL_SPEED * 0.05)
			local moveDirection = delta.Unit
			group1LeaderPosition += moveDirection * step
			group1FacingCF = CFrame.lookAt(Vector3.zero, Vector3.new(moveDirection.X, 0, moveDirection.Z)) * GOBLIN_ROTATION

			for _, state in ipairs(group1States) do
				if state.model.Parent and not state.isSolo and not state.isSearching then
					local newPos = group1LeaderPosition + state.offset
					state.floorCF = CFrame.new(newPos.X, state.floorY, newPos.Z) * group1FacingCF
				end
			end

			task.wait(0.05)
		end
	end)
end

task.spawn(function()
	task.wait(1)
	local source = waitForGoblinSource(60)
	if not source then
		warn("[EmptyWorld49Builder] Missing goblin1 source; no level 49 goblins placed.")
		return
	end

	for _, entry in ipairs(GOBLIN_GROUP) do
		placeGoblin(entry, source)
	end
	startGroup1Patrol()
	startGroup1Hunter()
end)

print("[EmptyWorld49Builder] Transparent room 49 built far away at CZ=" .. tostring(CZ))
