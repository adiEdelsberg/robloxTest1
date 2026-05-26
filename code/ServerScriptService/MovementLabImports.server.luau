-- MovementLabImports.server.luau
-- goblin1, goblin2, goblin3 walk around Level 20 (Neon Rift)

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FLOOR_Y    = 1
local MOVE_DELAY = 5   -- seconds all models stand still before starting to move

local function animateModel(model)
	-- Dump full hierarchy to find where bones actually live
	print("[Anim] === HERO DESCENDANTS ===")
	for _, d in model:GetDescendants() do
		print("[Anim]  " .. d.ClassName .. " | " .. d.Name)
	end
	print("[Anim] === END ===")

	-- Index all bones by name for easy lookup
	local boneMap = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Bone") then
			boneMap[d.Name] = d
		end
	end

	local count = 0
	for _ in boneMap do count += 1 end
	print("[Anim] " .. model.Name .. " — bones found: " .. count)
	if count == 0 then
		warn("[Anim] no bones found — check MeshPart children")
		return
	end

	local function get(name)
		return boneMap["mixamorig:" .. name]
	end

	-- Store rest transforms
	local rest = {}
	for _, b in boneMap do
		rest[b] = b.Transform
	end

	-- Walk cycle definition: { boneName, axisAngle(x,y,z), phase, amplitude }
	local WALK = {
		{ get("LeftUpLeg"),    1, 0, 0,  1,  math.rad(35) },  -- left thigh forward
		{ get("RightUpLeg"),   1, 0, 0, -1,  math.rad(35) },  -- right thigh back
		{ get("LeftLeg"),      1, 0, 0, -1,  math.rad(20) },  -- left knee bend
		{ get("RightLeg"),     1, 0, 0,  1,  math.rad(20) },  -- right knee
		{ get("LeftArm"),      1, 0, 0, -1,  math.rad(25) },  -- left arm swings opposite leg
		{ get("RightArm"),     1, 0, 0,  1,  math.rad(25) },
		{ get("LeftForeArm"),  1, 0, 0,  1,  math.rad(15) },
		{ get("RightForeArm"), 1, 0, 0, -1,  math.rad(15) },
		{ get("Spine"),        0, 0, 1,  1,  math.rad(5)  },  -- subtle torso twist
		{ get("Hips"),         1, 0, 0,  1,  math.rad(5)  },  -- slight hip bob
	}

	-- Remove nil entries (bones not found)
	local entries = {}
	for _, e in WALK do
		if e[1] then
			table.insert(entries, e)
		else
			print("[Anim] missing bone in walk cycle — skipping")
		end
	end

	local SPEED = 3.5  -- strides per second

	RunService.Heartbeat:Connect(function()
		if not model.Parent then return end
		local t = os.clock()
		for _, e in entries do
			local bone, ax, ay, az, phase, amp = e[1], e[2], e[3], e[4], e[5], e[6]
			local swing = math.sin(t * SPEED * math.pi * 2 + phase * math.pi) * amp
			bone.Transform = rest[bone] * CFrame.Angles(ax*swing, ay*swing, az*swing)
		end
	end)

	print("[Anim] Mixamo walk cycle running on " .. #entries .. " bones")
end

local function animateHeroJoints(model)
	local bones = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Bone") then
			table.insert(bones, d)
		end
	end

	print("[Anim] " .. model.Name .. " bones found: " .. #bones)
	if #bones == 0 then
		warn("[Anim] no bones found - imported hero may need a rigged/skinned mesh")
		return
	end

	local function classifyBone(bone)
		local name = bone.Name:lower()
		local phase = 1
		if name:find("left", 1, true) or name:find("_l", 1, true) or name:find(".l", 1, true) then
			phase = 1
		elseif name:find("right", 1, true) or name:find("_r", 1, true) or name:find(".r", 1, true) then
			phase = -1
		end

		if name:find("upleg", 1, true) or name:find("thigh", 1, true) or name:find("leg", 1, true) then
			return 1, 0, 0, phase, math.rad(22)
		end
		if name:find("foot", 1, true) or name:find("toe", 1, true) then
			return 1, 0, 0, -phase, math.rad(12)
		end
		if name:find("arm", 1, true) or name:find("shoulder", 1, true) then
			return 1, 0, 0, -phase, math.rad(18)
		end
		if name:find("hand", 1, true) or name:find("finger", 1, true) then
			return 0, 0, 1, phase, math.rad(10)
		end
		if name:find("spine", 1, true) or name:find("chest", 1, true) or name:find("neck", 1, true) then
			return 0, 0, 1, 1, math.rad(5)
		end
		if name:find("head", 1, true) then
			return 0, 1, 0, 1, math.rad(6)
		end
		if name:find("hip", 1, true) or name:find("pelvis", 1, true) or name:find("root", 1, true) then
			return 1, 0, 0, 1, math.rad(4)
		end
		if name:find("tail", 1, true) or name:find("hair", 1, true) or name:find("ear", 1, true) then
			return 0, 1, 0, phase, math.rad(8)
		end

		return nil
	end

	local rest = {}
	local entries = {}
	for _, bone in ipairs(bones) do
		local ax, ay, az, phase, amp = classifyBone(bone)
		if ax then
			rest[bone] = bone.Transform
			table.insert(entries, { bone, ax, ay, az, phase, amp })
		end
	end

	if #entries == 0 then
		warn("[Anim] bones exist, but no known joint names matched for animation")
		return
	end

	local speed = 1.35
	RunService.Heartbeat:Connect(function()
		if not model.Parent then return end
		local t = os.clock()
		for _, e in entries do
			local bone, ax, ay, az, phase, amp = e[1], e[2], e[3], e[4], e[5], e[6]
			local swing = math.sin(t * speed * math.pi * 2 + phase * math.pi) * amp
			bone.Transform = rest[bone] * CFrame.Angles(ax * swing, ay * swing, az * swing)
		end
	end)

	print("[Anim] in-place hero joint animation running on " .. #entries .. " bones")
end

local function playHeroAnimationController(model)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	if not controller then
		warn("[Anim] hero has no AnimationController; using procedural joint animation")
		return false
	end

	local animator = controller:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end

	local animations = {}
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("Animation") and object.AnimationId ~= "" then
			table.insert(animations, object)
		end
	end

	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("KeyframeSequence") then
			local ok, sequenceId = pcall(function()
				return KeyframeSequenceProvider:RegisterKeyframeSequence(object)
			end)
			if ok and sequenceId then
				local animation = Instance.new("Animation")
				animation.Name = object.Name .. "_RuntimeAnimation"
				animation.AnimationId = sequenceId
				animation.Parent = controller
				table.insert(animations, animation)
				print("[Anim] registered hero KeyframeSequence:", object:GetFullName(), sequenceId)
			else
				warn("[Anim] failed to register hero KeyframeSequence:", object:GetFullName(), sequenceId)
			end
		end
	end

	if #animations == 0 then
		warn("[Anim] hero AnimationController found, but no Animation/KeyframeSequence clips were found")
		return false
	end

	table.sort(animations, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)

	local animation = animations[1]
	local ok, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not ok or not trackOrError then
		warn("[Anim] failed to load hero animation:", animation:GetFullName(), trackOrError)
		return false
	end

	local track = trackOrError
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Idle
	track:Play(0.2, 1, 1)

	print("[Anim] playing hero AnimationController track:", animation:GetFullName(), animation.AnimationId)
	return true
end

local function playWalkAnimationById(model, animationId, priority, loopCount)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local animatorParent = controller or humanoid
	if not animatorParent then
		controller = Instance.new("AnimationController")
		controller.Name = "RuntimeAnimationController"
		controller.Parent = model
		animatorParent = controller
	end

	local animator = animatorParent:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animatorParent
	end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.05)
	end

	local animation = Instance.new("Animation")
	animation.Name = "RuntimeAnimation_" .. tostring(animationId)
	animation.AnimationId = "rbxassetid://" .. tostring(animationId)
	animation.Parent = animatorParent

	local ok, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not trackOrError then
		warn("[MovementLabImports] Could not load walk animation id " .. tostring(animationId), trackOrError)
		return false
	end

	local track = trackOrError
	track.Looped = loopCount == nil
	track.Priority = priority or Enum.AnimationPriority.Action
	track:Play(0.15, 1, 1)
	if loopCount then
		local completedLoops = 0
		track.DidLoop:Connect(function()
			completedLoops += 1
			if completedLoops >= loopCount then
				track:Stop(0.15)
			end
		end)
	else
		track.Stopped:Connect(function()
			if model.Parent then
				track:Play(0.15, 1, 1)
			end
		end)
	end
	print("[MovementLabImports] Playing walk animation id " .. tostring(animationId) .. " on " .. model.Name)
	return true
end

local function playAnimationWithRetry(model, animationId, priority, loopCount)
	playWalkAnimationById(model, animationId, priority, loopCount)
	if not loopCount then
		task.delay(2, function()
			if model.Parent then
				playWalkAnimationById(model, animationId, priority, loopCount)
			end
		end)
	end
end

local function playAnimationForSeconds(model, animationId, priority, seconds)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local animatorParent = controller or humanoid
	if not animatorParent then
		controller = Instance.new("AnimationController")
		controller.Name = "RuntimeAnimationController"
		controller.Parent = model
		animatorParent = controller
	end

	local animator = animatorParent:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animatorParent
	end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0.05)
	end

	local animation = Instance.new("Animation")
	animation.Name = "RuntimeAnimation_" .. tostring(animationId)
	animation.AnimationId = "rbxassetid://" .. tostring(animationId)
	animation.Parent = animatorParent

	local ok, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not trackOrError then
		warn("[MovementLabImports] Could not load timed animation id " .. tostring(animationId), trackOrError)
		return false
	end

	local track = trackOrError
	track.Looped = true
	track.Priority = priority or Enum.AnimationPriority.Movement
	track:Play(0.15, 1, 1)
	task.delay(seconds, function()
		if track.IsPlaying then
			track:Stop(0.15)
		end
	end)
	return true
end

local function playAnimationSequence(model, sequence)
	task.spawn(function()
		for _, step in ipairs(sequence) do
			if not model.Parent then
				return
			end
			playAnimationForSeconds(model, step.animationId, step.priority, step.seconds)
			task.wait(step.seconds)
		end
	end)
end

local function playAnimationTimesThenIdle(model, animationId, priority, playCount, idleAnimationId, idlePriority, idleSeconds)
	local track = nil
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local animatorParent = controller or humanoid
	if not animatorParent then
		controller = Instance.new("AnimationController")
		controller.Name = "RuntimeAnimationController"
		controller.Parent = model
		animatorParent = controller
	end

	local animator = animatorParent:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animatorParent
	end
	for _, playingTrack in ipairs(animator:GetPlayingAnimationTracks()) do
		playingTrack:Stop(0.05)
	end

	local animation = Instance.new("Animation")
	animation.Name = "RuntimeAnimation_" .. tostring(animationId)
	animation.AnimationId = "rbxassetid://" .. tostring(animationId)
	animation.Parent = animatorParent

	local ok, result = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not result then
		warn("[MovementLabImports] Could not load animation id " .. tostring(animationId), result)
		return false
	end

	track = result
	track.Looped = false
	track.Priority = priority or Enum.AnimationPriority.Action
	track:Play(0.15, 1, 1)
	local playsStarted = 1
	track.Stopped:Connect(function()
		if not model.Parent then
			return
		end

		if playsStarted >= playCount then
			if idleAnimationId and idleSeconds and idleSeconds > 0 then
				local idleAnimation = Instance.new("Animation")
				idleAnimation.Name = "RuntimeIdleAnimation_" .. tostring(idleAnimationId)
				idleAnimation.AnimationId = "rbxassetid://" .. tostring(idleAnimationId)
				idleAnimation.Parent = animatorParent

				local idleOk, idleTrackOrError = pcall(function()
					return animator:LoadAnimation(idleAnimation)
				end)
				if not idleOk or not idleTrackOrError then
					warn("[MovementLabImports] Could not load idle animation id " .. tostring(idleAnimationId), idleTrackOrError)
					return
				end

				local idleTrack = idleTrackOrError
				idleTrack.Looped = true
				idleTrack.Priority = idlePriority or Enum.AnimationPriority.Idle
				idleTrack:Play(0.15, 1, 1)
				task.delay(idleSeconds, function()
					if idleTrack.IsPlaying then
						idleTrack:Stop(0.15)
					end
				end)
			end
			return
		end
		playsStarted += 1
		task.defer(function()
			track:Play(0.15, 1, 1)
		end)
	end)

	print("[MovementLabImports] Playing animation id " .. tostring(animationId) .. " " .. tostring(playCount) .. " times on " .. model.Name)
	return true
end

local function playSavedKeyframeAnimation(model, folderName, clipName)
	local saves = ServerStorage:FindFirstChild("RBX_ANIMSAVES")
	local folder = saves and saves:FindFirstChild(folderName)
	local clip = folder and folder:FindFirstChild(clipName)
	if not clip or not clip:IsA("KeyframeSequence") then
		warn("[MovementLabImports] Missing saved KeyframeSequence:", "ServerStorage.RBX_ANIMSAVES." .. folderName .. "." .. clipName)
		return false
	end

	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local animatorParent = controller or humanoid
	if not animatorParent then
		controller = Instance.new("AnimationController")
		controller.Name = "RuntimeAnimationController"
		controller.Parent = model
		animatorParent = controller
	end

	local animator = animatorParent:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animatorParent
	end

	local ok, sequenceId = pcall(function()
		return KeyframeSequenceProvider:RegisterKeyframeSequence(clip)
	end)
	if not ok or not sequenceId then
		warn("[MovementLabImports] Could not register saved animation:", clip:GetFullName(), sequenceId)
		return false
	end

	local animation = Instance.new("Animation")
	animation.Name = clipName .. "_RuntimeAnimation"
	animation.AnimationId = sequenceId
	animation.Parent = animatorParent

	local loadOk, trackOrError = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not loadOk or not trackOrError then
		warn("[MovementLabImports] Could not load saved animation:", clip:GetFullName(), trackOrError)
		return false
	end

	local track = trackOrError
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement
	track:Play(0.15, 1, 1)
	track.Stopped:Connect(function()
		if model.Parent then
			track:Play(0.15, 1, 1)
		end
	end)

	print("[MovementLabImports] Playing saved animation " .. clip:GetFullName() .. " on " .. model.Name)
	return true
end

local function facingCF(from, to, y)
	local dx = to.x - from.x
	local dz = to.z - from.z
	return CFrame.new(to.x, y, to.z) * CFrame.Angles(0, math.atan2(-dx, -dz), 0)
end

local function floorAlignedCF(model, cf, extraLift)
	model:PivotTo(cf)
	local boxCf, size = model:GetBoundingBox()
	local bottomY = boxCf.Position.Y - size.Y / 2
	return cf + Vector3.new(0, FLOOR_Y - bottomY + (extraLift or 0), 0)
end

local function setupGoblin(name, startIdx, waypoints, scale, rotationOffset, extraLift, walkAnimationId, shouldPatrol, lockFloor)
	local goblin = workspace:WaitForChild(name, 10)
	if not goblin then
		warn("[MovementLabImports] " .. name .. " not found in Workspace")
		return
	end

	for _, d in goblin:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true end
	end

	local pivot = goblin:GetPivot()
	if scale then
		goblin:ScaleTo(scale)
		goblin:PivotTo(pivot)
	end

	rotationOffset = rotationOffset or CFrame.identity
	local first = waypoints[startIdx]
	goblin:PivotTo(CFrame.new(first.x, FLOOR_Y + 100, first.z) * rotationOffset)

	local _, size = goblin:GetBoundingBox()
	local Y = FLOOR_Y + size.Y / 2

	goblin:PivotTo(floorAlignedCF(goblin, CFrame.new(first.x, Y, first.z) * rotationOffset, extraLift))

	local cfVal = Instance.new("CFrameValue")
	cfVal.Value  = goblin:GetPivot()
	cfVal.Parent = goblin

	cfVal:GetPropertyChangedSignal("Value"):Connect(function()
		if goblin.Parent then goblin:PivotTo(cfVal.Value) end
	end)

	if walkAnimationId then
		playWalkAnimationById(goblin, walkAnimationId)
	end

	if shouldPatrol == false then
		if lockFloor then
			local floorLockConnection
			floorLockConnection = RunService.Heartbeat:Connect(function()
				if not goblin.Parent then
					floorLockConnection:Disconnect()
					return
				end

				local pivot = goblin:GetPivot()
				goblin:PivotTo(floorAlignedCF(goblin, pivot, extraLift))
			end)
		end
		print("[MovementLabImports] " .. name .. " standing still")
		return goblin
	end

	task.spawn(function()
		task.wait(MOVE_DELAY)   -- all models stand still first
		local idx = startIdx
		while goblin.Parent do
			local nextIdx = (idx % #waypoints) + 1
			local from = waypoints[idx]
			local to   = waypoints[nextIdx]
			local dist = math.sqrt((to.x-from.x)^2 + (to.z-from.z)^2)
			local time = math.max(1.5, dist / 20)

			TweenService:Create(cfVal,
				TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Value = floorAlignedCF(goblin, facingCF(from, to, Y) * rotationOffset, extraLift) }
			):Play()

			task.wait(time + 0.3)
			idx = nextIdx
		end
	end)

	print("[MovementLabImports] " .. name .. " patrolling")
	return goblin
end

local function addMissingImportMarker(name, x, z)
	local marker = Instance.new("Part")
	marker.Name = "MissingImport_" .. name
	marker.Size = Vector3.new(18, 18, 18)
	marker.CFrame = CFrame.new(x, FLOOR_Y + 10, z)
	marker.Material = Enum.Material.Neon
	marker.BrickColor = BrickColor.new("Really red")
	marker.Transparency = 0.2
	marker.Anchored = true
	marker.CanCollide = false
	marker.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(260, 70)
	billboard.StudsOffset = Vector3.new(0, 14, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 80
	billboard.Parent = marker

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(20, 8, 8)
	label.BorderSizePixel = 0
	label.Text = "MISSING " .. name
	label.TextColor3 = Color3.fromRGB(255, 230, 230)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

local function findImportSource(name)
	return workspace:FindFirstChild(name)
		or ServerStorage:FindFirstChild(name, true)
		or ReplicatedStorage:FindFirstChild(name, true)
end

local function placeCleanStaticImport(name, x, z, rotationOffset, extraLift)
	local source = findImportSource(name)
	if not source then
		warn("[MovementLabImports] " .. name .. " not found in Workspace, ServerStorage, or ReplicatedStorage")
		addMissingImportMarker(name, x, z)
		return nil
	end

	local model = source
	if source.Parent ~= workspace then
		source.Archivable = true
		for _, object in ipairs(source:GetDescendants()) do
			object.Archivable = true
		end

		local old = workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end

		model = source:Clone()
		model.Name = name
		model.Parent = workspace
	end

	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.AssemblyLinearVelocity = Vector3.zero
			object.AssemblyAngularVelocity = Vector3.zero
		elseif object:IsA("Humanoid") then
			object.WalkSpeed = 0
			object.JumpPower = 0
			object.AutoRotate = false
		elseif object:IsA("AnimationController") and object.Name == "RuntimeAnimationController" then
			object:Destroy()
		end
	end

	rotationOffset = rotationOffset or CFrame.identity
	model:PivotTo(CFrame.new(x, FLOOR_Y + 100, z) * rotationOffset)

	local boxCf, size = model:GetBoundingBox()
	local bottomY = boxCf.Position.Y - size.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, FLOOR_Y - bottomY + (extraLift or 0), 0))

	print("[MovementLabImports] " .. name .. " placed clean/static at level 20 center")
	return model
end

local function startPivotPatrol(model, waypoints, startIdx, rotationOffset, extraLift, speed)
	if not model then return end

	rotationOffset = rotationOffset or CFrame.identity
	extraLift = extraLift or 0
	speed = speed or 22

	local idx = startIdx or 1
	local nextIdx = (idx % #waypoints) + 1
	local current = Vector3.new(waypoints[idx].x, FLOOR_Y, waypoints[idx].z)
	local target = Vector3.new(waypoints[nextIdx].x, FLOOR_Y, waypoints[nextIdx].z)

	local function placeAt(pos, lookAt)
		local dx = lookAt.X - pos.X
		local dz = lookAt.Z - pos.Z
		local yaw = math.atan2(-dx, -dz)
		local cf = CFrame.new(pos.X, FLOOR_Y + 100, pos.Z) * CFrame.Angles(0, yaw, 0) * rotationOffset
		model:PivotTo(floorAlignedCF(model, cf, extraLift))
	end

	placeAt(current, target)

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not model.Parent then
			connection:Disconnect()
			return
		end

		local offset = target - current
		local distance = offset.Magnitude
		if distance < 0.1 then
			idx = nextIdx
			nextIdx = (idx % #waypoints) + 1
			current = target
			target = Vector3.new(waypoints[nextIdx].x, FLOOR_Y, waypoints[nextIdx].z)
			return
		end

		local step = math.min(distance, speed * dt)
		current += offset.Unit * step
		placeAt(current, target)
	end)
end

local function addImportLabel(model, text)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root then
		return
	end

	local existing = root:FindFirstChild("ImportNameLabel")
	if existing then
		existing:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ImportNameLabel"
	billboard.Size = UDim2.fromOffset(220, 54)
	local _, size = model:GetBoundingBox()
	billboard.StudsOffset = Vector3.new(0, math.max(4, size.Y * 0.5 + 2), 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	billboard.Parent = root

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

local function makeGoblinCopy(source, cloneName, x, z, labelText, animationId)
	local old = workspace:FindFirstChild(cloneName)
	if old then
		old:Destroy()
	end

	if not source then
		return nil
	end

	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = cloneName
	clone.Parent = workspace

	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.AssemblyLinearVelocity = Vector3.zero
			object.AssemblyAngularVelocity = Vector3.zero
		end
	end

	clone:PivotTo(floorAlignedCF(clone, CFrame.new(x, FLOOR_Y + 100, z) * CFrame.Angles(math.rad(90), 0, 0), 10))
	addImportLabel(clone, labelText)
	playAnimationWithRetry(clone, animationId, Enum.AnimationPriority.Movement)
	return clone
end

local function addStaticLabelFollow(model, text)
	local labelPartName = model.Name .. "_StaticLabelAnchor"
	local old = workspace:FindFirstChild(labelPartName)
	if old then
		old:Destroy()
	end

	local anchor = Instance.new("Part")
	anchor.Name = labelPartName
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.Parent = workspace
	addImportLabel(anchor, text)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			connection:Disconnect()
			anchor:Destroy()
			return
		end

		local boxCf, size = model:GetBoundingBox()
		anchor.CFrame = CFrame.new(boxCf.Position + Vector3.new(0, size.Y / 2 + 4, 0))
	end)
end

local function setupStaticImport(name, waypoint, scale)
	local model = workspace:WaitForChild(name, 10)
	if not model then
		warn("[MovementLabImports] " .. name .. " not found in Workspace")
		return nil
	end

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.AssemblyLinearVelocity = Vector3.zero
			d.AssemblyAngularVelocity = Vector3.zero
		elseif d:IsA("Humanoid") then
			d.WalkSpeed = 0
			d.JumpPower = 0
			d.AutoRotate = false
		end
	end

	local pivot = model:GetPivot()
	if scale then
		model:ScaleTo(scale)
		model:PivotTo(pivot)
	end

	local _, size = model:GetBoundingBox()
	local y = FLOOR_Y + size.Y / 2
	model:PivotTo(CFrame.new(waypoint.x, y, waypoint.z))

	local root = model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart", true)
		or model:FindFirstChild("RootPart", true)
		or model:FindFirstChildWhichIsA("BasePart", true)
	if root then
		model.PrimaryPart = root
		root.Anchored = true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	print("[MovementLabImports] " .. name .. " placed static")
	return model
end

local function addImportLabel(root, text)
	local existing = root:FindFirstChild("MovementLabImportLabel")
	if existing then
		existing:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MovementLabImportLabel"
	billboard.Size = UDim2.fromOffset(220, 54)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.22
	label.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(170, 255, 255)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

local function cloneStaticImport(sourceName, cloneName, waypoint)
	local existing = workspace:FindFirstChild(cloneName)
	if existing then
		existing:Destroy()
	end

	local source = workspace:FindFirstChild(sourceName)
	if not source then
		warn("[MovementLabImports] " .. sourceName .. " source not found for extra clone")
		return nil
	end

	source.Archivable = true
	for _, d in source:GetDescendants() do
		d.Archivable = true
	end

	local clone = source:Clone()
	clone.Name = cloneName
	clone.Parent = workspace

	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.AssemblyLinearVelocity = Vector3.zero
			d.AssemblyAngularVelocity = Vector3.zero
		elseif d:IsA("Humanoid") then
			d.WalkSpeed = 0
			d.JumpPower = 0
			d.AutoRotate = false
		end
	end

	local root = clone.PrimaryPart
		or clone:FindFirstChild("HumanoidRootPart", true)
		or clone:FindFirstChild("RootPart", true)
		or clone:FindFirstChildWhichIsA("BasePart", true)
	if root then
		clone.PrimaryPart = root
		local _, size = clone:GetBoundingBox()
		local y = FLOOR_Y + size.Y / 2
		clone:PivotTo(CFrame.new(waypoint.x, y, waypoint.z) * CFrame.Angles(0, math.rad(180), 0))
		addImportLabel(root, cloneName)
	end

	print("[MovementLabImports] " .. cloneName .. " cloned from " .. sourceName)
	return clone
end

local WAYPOINTS_1 = {
	{ x = -2860, z = 1700 },
	{ x = -3100, z = 1480 },
	{ x = -2860, z = 1450 },
	{ x = -2600, z = 1480 },
	{ x = -2560, z = 1700 },
	{ x = -2620, z = 1920 },
	{ x = -2860, z = 1950 },
	{ x = -3100, z = 1920 },
	{ x = -3150, z = 1700 },
}

local WAYPOINTS_2 = {
	{ x = -2860, z = 1700 },
	{ x = -2960, z = 1570 },
	{ x = -2760, z = 1570 },
	{ x = -2760, z = 1830 },
	{ x = -2960, z = 1830 },
}

local WAYPOINTS_3 = {
	{ x = -2860, z = 1700 },
	{ x = -3050, z = 1550 },
	{ x = -2670, z = 1850 },
	{ x = -2860, z = 1700 },
	{ x = -2670, z = 1550 },
	{ x = -3050, z = 1850 },
}

local WAYPOINTS_HERO = {
	{ x = -2860, z = 1700 },
	{ x = -2960, z = 1600 },
	{ x = -2760, z = 1600 },
	{ x = -2760, z = 1800 },
	{ x = -2960, z = 1800 },
}

-- Hero jump-hop behavior
local HERO_POINTS = {
	{ x = -2860, z = 1700 },
	{ x = -3050, z = 1500 },
	{ x = -2660, z = 1500 },
	{ x = -2660, z = 1900 },
	{ x = -3050, z = 1900 },
	{ x = -2860, z = 1600 },
	{ x = -2960, z = 1750 },
	{ x = -2760, z = 1750 },
	{ x = -3100, z = 1700 },
	{ x = -2620, z = 1700 },
	{ x = -2860, z = 1850 },
}

local ARC_HEIGHT = 120  -- studs — all heroes use this

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local function shakeGround(x, z)
	-- Spawn 3 expanding shockwave rings
	for wave = 1, 3 do
		task.delay((wave - 1) * 0.12, function()
			local ring = Instance.new("Part")
			ring.Name        = "ShockWave"
			ring.Shape       = Enum.PartType.Cylinder
			ring.Size        = Vector3.new(0.4, 10, 10)
			ring.CFrame      = CFrame.new(x, FLOOR_Y + 0.3, z) * CFrame.Angles(0, 0, math.rad(90))
			ring.BrickColor  = BrickColor.new("Bright orange")
			ring.Material    = Enum.Material.Neon
			ring.Transparency = 0.2
			ring.Anchored    = true
			ring.CanCollide  = false
			ring.CastShadow  = false
			ring.Parent      = workspace

			-- Expand and fade
			local startTime = os.clock()
			local duration  = 0.6
			local maxSize   = 200

			local conn
			conn = game:GetService("RunService").Heartbeat:Connect(function()
				local t = (os.clock() - startTime) / duration
				if t >= 1 or not ring.Parent then
					ring:Destroy()
					conn:Disconnect()
					return
				end
				local s = t * maxSize
				ring.Size         = Vector3.new(0.4, s, s)
				ring.Transparency = 0.2 + t * 0.8
			end)
		end)
	end

	-- Flash the ground briefly
	task.spawn(function()
		local flash = Instance.new("Part")
		flash.Name        = "GroundFlash"
		flash.Shape       = Enum.PartType.Cylinder
		flash.Size        = Vector3.new(0.2, 168, 168)
		flash.CFrame      = CFrame.new(x, FLOOR_Y + 0.15, z) * CFrame.Angles(0, 0, math.rad(90))
		flash.BrickColor  = BrickColor.new("Bright yellow")
		flash.Material    = Enum.Material.Neon
		flash.Transparency = 0.3
		flash.Anchored    = true
		flash.CanCollide  = false
		flash.CastShadow  = false
		flash.Parent      = workspace
		task.wait(0.08)
		flash.Transparency = 0.6
		task.wait(0.08)
		flash:Destroy()
	end)
end

local function makeShadow(x, z)
	local shadow = Instance.new("Part")
	shadow.Name        = "HeroLandShadow"
	shadow.Shape       = Enum.PartType.Cylinder
	shadow.Size        = Vector3.new(0.3, 168, 168)
	shadow.CFrame      = CFrame.new(x, FLOOR_Y + 0.2, z) * CFrame.Angles(0, 0, math.rad(90))
	shadow.BrickColor  = BrickColor.new("Really red")
	shadow.Material    = Enum.Material.Neon
	shadow.Transparency = 0.45
	shadow.Anchored    = true
	shadow.CanCollide  = false
	shadow.CastShadow  = false
	shadow.Parent      = workspace
	return shadow
end

local function kickPlayersAtLanding(x, z)
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Only check horizontal distance so Y height doesn't affect it
			local dx   = hrp.Position.X - x
			local dz   = hrp.Position.Z - z
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist < 84 then
				local strength = (150 * (1 - dist / 84) + 80) * 5
				local dirX = dist > 0.1 and dx / dist or 1
				local dirZ = dist > 0.1 and dz / dist or 0
				local bv = Instance.new("BodyVelocity")
				bv.Velocity = Vector3.new(dirX * strength * 0.4, strength * 2, dirZ * strength * 0.4)
				bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				bv.P        = 1e5
				bv.Parent   = hrp
				Debris:AddItem(bv, 0.2)
				print("[Hero] kicked " .. player.Name .. " (dist=" .. math.floor(dist) .. ")")
			end
		end
	end
end

local function startHeroJump(hero, Y, startIdx)
	task.spawn(function()
		task.wait(MOVE_DELAY + math.random(0, 30) / 10)
		local idx = startIdx or 1
		while hero.Parent do
			task.wait(math.random(4, 20) / 10)

			-- 25% chance to jump back to the same spot
			local nextIdx
			if math.random() < 0.25 then
				nextIdx = idx
			else
				repeat nextIdx = math.random(1, #HERO_POINTS) until nextIdx ~= idx
			end
			idx = nextIdx
			local to = HERO_POINTS[idx]

			local jumpTime = 1.0
			local landTime = 1.0

			local fromPos = hero:GetPivot().Position
			local dx = to.x - fromPos.X
			local dz = to.z - fromPos.Z
			local yaw = math.atan2(-dx, -dz)

			local midCF = CFrame.new(
				(fromPos.X + to.x) / 2,
				Y + ARC_HEIGHT,
				(fromPos.Z + to.z) / 2
			) * CFrame.Angles(0, yaw, 0)

			local cfVal = Instance.new("CFrameValue")
			cfVal.Value  = hero:GetPivot()
			cfVal.Parent = hero

			local conn = cfVal:GetPropertyChangedSignal("Value"):Connect(function()
				if hero.Parent then hero:PivotTo(cfVal.Value) end
			end)

			-- Show shadow at landing spot
			local shadow = makeShadow(to.x, to.z)

			-- Rise to peak (facing destination)
			TweenService:Create(cfVal,
				TweenInfo.new(jumpTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Value = midCF }
			):Play()
			-- Pulse shadow while in the air
			task.spawn(function()
				while shadow.Parent do
					shadow.Transparency = 0.15
					task.wait(0.15)
					if shadow.Parent then
						shadow.Transparency = 0.6
						task.wait(0.15)
					end
				end
			end)

			task.wait(jumpTime)

			-- Fall and land with bounce
			TweenService:Create(cfVal,
				TweenInfo.new(landTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
				{ Value = CFrame.new(to.x, Y, to.z) * CFrame.Angles(0, yaw, 0) }
			):Play()
			task.wait(landTime + 0.1)

			-- Ground shake + kick on landing
			shakeGround(to.x, to.z)
			kickPlayersAtLanding(to.x, to.z)

			-- Remove shadow
			if shadow.Parent then shadow:Destroy() end

			conn:Disconnect()
			cfVal:Destroy()
			hero:PivotTo(CFrame.new(to.x, Y, to.z) * CFrame.Angles(0, yaw, 0))
		end
	end)
end

local function getNearestPlayerPos()
	local best, bestDist = nil, math.huge
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local dist = hrp.Position.Magnitude
			if dist < bestDist then
				bestDist = dist
				best = hrp.Position
			end
		end
	end
	return best
end

local function startHeroHunt(hero, Y)
	task.spawn(function()
		task.wait(MOVE_DELAY)
		while hero.Parent do
			task.wait(math.random(8, 20) / 10)

			-- Always aim at nearest player, fall back to random point
			local target = getNearestPlayerPos()
			local to
			if target then
				to = { x = target.X, z = target.Z }
			else
				local idx = math.random(1, #HERO_POINTS)
				to = HERO_POINTS[idx]
			end

			local jumpTime = 1.0
			local landTime = 1.0
			local fromPos  = hero:GetPivot().Position
			local dx = to.x - fromPos.X
			local dz = to.z - fromPos.Z
			local yaw = math.atan2(-dx, -dz)

			local shadow = makeShadow(to.x, to.z)

			local midCF = CFrame.new(
				(fromPos.X + to.x) / 2,
				Y + ARC_HEIGHT,
				(fromPos.Z + to.z) / 2
			) * CFrame.Angles(0, yaw, 0)

			local cfVal = Instance.new("CFrameValue")
			cfVal.Value  = hero:GetPivot()
			cfVal.Parent = hero
			local conn = cfVal:GetPropertyChangedSignal("Value"):Connect(function()
				if hero.Parent then hero:PivotTo(cfVal.Value) end
			end)

			task.spawn(function()
				while shadow.Parent do
					shadow.Transparency = 0.15
					task.wait(0.15)
					if shadow.Parent then shadow.Transparency = 0.6 task.wait(0.15) end
				end
			end)

			TweenService:Create(cfVal,
				TweenInfo.new(jumpTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Value = midCF }
			):Play()
			task.wait(jumpTime)

			TweenService:Create(cfVal,
				TweenInfo.new(landTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
				{ Value = CFrame.new(to.x, Y, to.z) * CFrame.Angles(0, yaw, 0) }
			):Play()
			task.wait(landTime + 0.1)

			shakeGround(to.x, to.z)
			kickPlayersAtLanding(to.x, to.z)
			if shadow.Parent then shadow:Destroy() end
			conn:Disconnect()
			cfVal:Destroy()
			hero:PivotTo(CFrame.new(to.x, Y, to.z) * CFrame.Angles(0, yaw, 0))
		end
	end)
end

local function setupHeroJump(name, scale)
	local hero = workspace:WaitForChild(name, 10)
	if not hero then warn("[MovementLabImports] " .. name .. " not found") return end

	for _, d in hero:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true end
	end
	local pivot = hero:GetPivot()
	if scale then hero:ScaleTo(scale) hero:PivotTo(pivot) end

	local _, size = hero:GetBoundingBox()
	local Y = FLOOR_Y + size.Y / 2
	hero:PivotTo(CFrame.new(HERO_POINTS[1].x, Y, HERO_POINTS[1].z))

	if not playHeroAnimationController(hero) then
		animateHeroJoints(hero)
	end

	startHeroJump(hero, Y, 1)   -- hunting disabled, use random jumps
	print("[MovementLabImports] " .. name .. " hunting players")
	return hero
end

local function removeUnusedImported3Ds(removeGoblinCopies)
	if removeGoblinCopies then
		local labels = workspace:FindFirstChild("GoblinStaticLabels")
		if labels then
			labels:Destroy()
		end
	end

	for _, name in ipairs({
		"goblin2",
		"goblin3",
		"goblin4",
		"giblin4",
		"hero",
		"goblin_extra",
		"hero_extra",
		"hero_extra2",
		"hero_extra3",
		"hero_extra4",
		"hero_extra5",
		"hero_extra6",
		"goblin1_walk2_copy",
		"goblin1_walk1_copy",
	}) do
		local object = workspace:FindFirstChild(name)
		if object then
			object:Destroy()
		end
	end

	if removeGoblinCopies then
		for _, object in ipairs(workspace:GetChildren()) do
			if object.Name:match("^goblin1_copy_%d+$") then
				object:Destroy()
			end
		end
	end
end

local GOBLIN_ROTATION = CFrame.Angles(0, math.rad(90), 0)
local GOBLIN_BASE_SCALE = 0.1
local GOBLIN_LIFT = 0
local GOBLIN_1_TO_10_LIFT = 0
local GOBLIN_11_TO_12_LIFT = 5
local GOBLIN_DEFAULT_ANIMATION_ID = 103227491027789
local GOBLIN_WALK_ANIMATION_ID = 107190533745367
local GOBLIN_FAST_RUN_ANIMATION_ID = 100809685153003
local GOBLIN_WALK_TYPE_2_ANIMATION_ID = 100938432734765
local GOBLIN_SLOW_WALK_ANIMATION_ID = 140346610829211
local GOBLIN_KICK_ANIMATION_ID = 83050605440023
local GOBLIN_MMA_KICK_ANIMATION_ID = 139956682286517
local GOBLIN_DOUBLE_KICK_ANIMATION_ID = 127462757738787
local GOBLIN_INSIDE_KICK_ANIMATION_ID = 124566055260637
local GOBLIN_IDLE_SEARCH_ANIMATION_ID = 130540795443372
local GOBLIN_SIT_TALK_ANIMATION_ID = 111277368354357 
local GOBLIN_RUN_DIVE_ANIMATION_ID = 115400980127259 

local function publishGoblinAnimationIds()
	local folder = ReplicatedStorage:FindFirstChild("GoblinAnimationIds")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GoblinAnimationIds"
		folder.Parent = ReplicatedStorage
	end

	local ids = {
		GOBLIN_DEFAULT_ANIMATION_ID = GOBLIN_DEFAULT_ANIMATION_ID,
		GOBLIN_WALK_ANIMATION_ID = GOBLIN_WALK_ANIMATION_ID,
		GOBLIN_FAST_RUN_ANIMATION_ID = GOBLIN_FAST_RUN_ANIMATION_ID,
		GOBLIN_WALK_TYPE_2_ANIMATION_ID = GOBLIN_WALK_TYPE_2_ANIMATION_ID,
		GOBLIN_SLOW_WALK_ANIMATION_ID = GOBLIN_SLOW_WALK_ANIMATION_ID,
		GOBLIN_KICK_ANIMATION_ID = GOBLIN_KICK_ANIMATION_ID,
		GOBLIN_MMA_KICK_ANIMATION_ID = GOBLIN_MMA_KICK_ANIMATION_ID,
		GOBLIN_DOUBLE_KICK_ANIMATION_ID = GOBLIN_DOUBLE_KICK_ANIMATION_ID,
		GOBLIN_INSIDE_KICK_ANIMATION_ID = GOBLIN_INSIDE_KICK_ANIMATION_ID,
		GOBLIN_IDLE_SEARCH_ANIMATION_ID = GOBLIN_IDLE_SEARCH_ANIMATION_ID,
		GOBLIN_SIT_TALK_ANIMATION_ID = GOBLIN_SIT_TALK_ANIMATION_ID,
		GOBLIN_RUN_DIVE_ANIMATION_ID = GOBLIN_RUN_DIVE_ANIMATION_ID,
	}

	for name, id in pairs(ids) do
		folder:SetAttribute(name, id)
	end
end
publishGoblinAnimationIds()

local function getGoblinLabelFolder()
	local folder = workspace:FindFirstChild("GoblinStaticLabels")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GoblinStaticLabels"
		folder.Parent = workspace
	end
	return folder
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

local function cloneNumberedGoblin(source, index)
	source.Archivable = true
	for _, object in ipairs(source:GetDescendants()) do
		object.Archivable = true
	end

	local cloneName = string.format("goblin1_copy_%02d", index)
	local old = workspace:FindFirstChild(cloneName)
	if old then
		old:Destroy()
	end

	local clone = source:Clone()
	clone.Name = cloneName
	clone.Parent = workspace
	removeGeneratedGoblinObjects(clone)
	return clone
end

local function getGoblinScale(index)
	if index >= 1 and index <= 5 then
		return GOBLIN_BASE_SCALE / 5
	end
	if index == 17 then
		return GOBLIN_BASE_SCALE * 5
	elseif index == 16 then
		return GOBLIN_BASE_SCALE * 4
	elseif index == 19 then
		return GOBLIN_BASE_SCALE * 3
	elseif index == 20 then
		return GOBLIN_BASE_SCALE * 2
	end
	return GOBLIN_BASE_SCALE
end

local function addStaticWorldText(model, index)
	local folder = getGoblinLabelFolder()
	local old = folder:FindFirstChild(model.Name .. "_StaticText")
	if old then
		old:Destroy()
	end

	local labelScale = 1

	local sign = Instance.new("Part")
	sign.Name = model.Name .. "_StaticText"
	sign.Size = Vector3.new(32 * labelScale, 14 * labelScale, 0.1)
	sign.Transparency = 1
	sign.Anchored = true
	sign.CanCollide = false
	sign.CanTouch = false
	sign.CanQuery = false
	sign.CastShadow = false
	sign.Parent = folder

	local function addFace(face)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "WhiteTextOnly"
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 10
		gui.LightInfluence = 0
		gui.AlwaysOnTop = false
		gui.Parent = sign

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Text = tostring(index)
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

		local boxCf = model:GetBoundingBox()
		local labelY = index <= 10 and FLOOR_Y + 40 or FLOOR_Y + 32
		local position = Vector3.new(boxCf.Position.X, labelY, boxCf.Position.Z)
		sign.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0)
	end)
end

local function getGoblinVisualParts(model)
	local parts = {}
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") and object.Name ~= "GoblinCollisionBody" then
			table.insert(parts, object)
		end
	end
	return parts
end

local function blinkGoblin(model)
	if model:GetAttribute("BlinkingNow") then
		return
	end

	model:SetAttribute("BlinkingNow", true)
	local originalState = {}
	for _, part in ipairs(getGoblinVisualParts(model)) do
		originalState[part] = {
			color = part.Color,
			material = part.Material,
			transparency = part.Transparency,
		}
	end

	task.spawn(function()
		local highlight = Instance.new("Highlight")
		highlight.Name = "GoblinBlinkHighlight"
		highlight.Adornee = model
		highlight.FillColor = Color3.fromRGB(255, 45, 210)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.25
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = model

		local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		local light
		if root then
			light = Instance.new("PointLight")
			light.Name = "GoblinBlinkLight"
			light.Range = 18
			light.Brightness = 5
			light.Parent = root
		end

		local startedAt = os.clock()
		local pulse = 0
		while model.Parent and os.clock() - startedAt < 10 do
			pulse += 1
			local color = pulse % 2 == 0 and Color3.fromRGB(255, 45, 210) or Color3.fromRGB(45, 255, 255)
			for part in pairs(originalState) do
				if part.Parent then
					part.Color = color
					part.Material = Enum.Material.Neon
					part.Transparency = 0.35
				end
			end
			highlight.FillColor = color
			if light then
				light.Color = color
				light.Brightness = 7
			end
			task.wait(0.18)
			for part, original in pairs(originalState) do
				if part.Parent then
					part.Color = original.color
					part.Material = original.material
					part.Transparency = math.min(0.65, original.transparency + 0.18)
				end
			end
			if light then
				light.Brightness = 2
			end
			task.wait(0.18)
		end

		for part, original in pairs(originalState) do
			if part.Parent then
				part.Color = original.color
				part.Material = original.material
				part.Transparency = original.transparency
			end
		end
		if highlight.Parent then
			highlight:Destroy()
		end
		if light and light.Parent then
			light:Destroy()
		end
		if model.Parent then
			model:SetAttribute("BlinkingNow", false)
		end
	end)
end

local function addGoblinCollisionBody(model)
	local boxCf, size = model:GetBoundingBox()
	local height = math.max(5, size.Y * 0.82)
	local bottomY = boxCf.Position.Y - size.Y / 2

	local collider = Instance.new("Part")
	collider.Name = "GoblinCollisionBody"
	collider.Size = Vector3.new(math.max(3, size.X * 0.45), height, math.max(3, size.Z * 0.45))
	collider.CFrame = CFrame.new(boxCf.Position.X, bottomY + height / 2, boxCf.Position.Z)
	collider.Transparency = 1
	collider.Anchored = true
	collider.CanCollide = true
	collider.CanTouch = true
	collider.CanQuery = false
	collider.CastShadow = false
	collider.Parent = model

	local lastTouchAt = 0
	local function triggerBlink()
		local now = os.clock()
		if now - lastTouchAt < 0.8 then
			return
		end
		lastTouchAt = now
		blinkGoblin(model)
	end

	collider.Touched:Connect(function(hit)
		if hit and not hit:IsDescendantOf(model) then
			triggerBlink()
		end
	end)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent or not collider.Parent then
			connection:Disconnect()
			return
		end
		local halfSize = collider.Size / 2
		local cf = collider.CFrame
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local localPos = cf:PointToObjectSpace(hrp.Position)
				if math.abs(localPos.X) <= halfSize.X + 1.5
					and math.abs(localPos.Y) <= halfSize.Y + 3
					and math.abs(localPos.Z) <= halfSize.Z + 1.5
				then
					triggerBlink()
					return
				end
			end
		end
	end)
end

local function setupNumberedGoblin(model, index, x, z)
	removeGeneratedGoblinObjects(model)
	local modelScale = getGoblinScale(index)
	model:ScaleTo(modelScale)
	local lift = GOBLIN_LIFT
	if index <= 10 then
		lift = GOBLIN_1_TO_10_LIFT
	elseif index == 11 or index == 12 then
		lift = GOBLIN_11_TO_12_LIFT
	end
	if index == 16 or index == 17 or index == 19 or index == 20 then
		lift = 0
	elseif index == 18 or index == 6 or index == 7 or index == 8 or index == 9 or index == 10 then
		lift = -4
	elseif index == 13 or index == 14 then
		lift = 6
	end

	for _, object in ipairs(model:GetDescendants()) do
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

	model:PivotTo(floorAlignedCF(model, CFrame.new(x, FLOOR_Y + 100, z) * GOBLIN_ROTATION, lift))
	addStaticWorldText(model, index)
	addGoblinCollisionBody(model)

	local animationId = index <= 20 and GOBLIN_WALK_TYPE_2_ANIMATION_ID 
	local priority = Enum.AnimationPriority.Movement
	if index == 18 then
		animationId = GOBLIN_SLOW_WALK_ANIMATION_ID
	elseif index == 20 then
		animationId = GOBLIN_DEFAULT_ANIMATION_ID
	elseif index == 11 or index == 12 then
		animationId = GOBLIN_KICK_ANIMATION_ID
		priority = Enum.AnimationPriority.Action
	elseif index == 6 then
		animationId = GOBLIN_MMA_KICK_ANIMATION_ID
		priority = Enum.AnimationPriority.Action
	elseif index == 7 then
		animationId = GOBLIN_DOUBLE_KICK_ANIMATION_ID
		priority = Enum.AnimationPriority.Action
	elseif index == 8 then
		animationId = GOBLIN_INSIDE_KICK_ANIMATION_ID
		priority = Enum.AnimationPriority.Action
	elseif index == 9 then
		animationId = GOBLIN_SIT_TALK_ANIMATION_ID
		priority = Enum.AnimationPriority.Action
	elseif index == 10 then
		animationId = GOBLIN_RUN_DIVE_ANIMATION_ID
		priority = Enum.AnimationPriority.Action
	end
	playAnimationWithRetry(model, animationId, priority)
end

removeUnusedImported3Ds(true)
local goblin1 = placeCleanStaticImport("goblin1", -2860, 1700, GOBLIN_ROTATION, GOBLIN_LIFT)
if goblin1 then
	local goblins = { goblin1 }
	for index = 2, 20 do
		table.insert(goblins, cloneNumberedGoblin(goblin1, index))
	end

	local spawned = 0
	local spacingX = 140
	local spacingZ = 105
	for index, model in ipairs(goblins) do
		local row = math.floor((index - 1) / 5)
		local col = (index - 1) % 5
		local x = -2860 + (col - 2) * spacingX
		local z = 1700 + (row - 1.5) * spacingZ
		setupNumberedGoblin(model, index, x, z)
		spawned += 1
	end

	print("[MovementLabImports] Spawned " .. tostring(spawned) .. " numbered goblin1 NPCs in level 20.")
end
-- Place goblin1House in the centre of Level 20
local houseSource = workspace:FindFirstChild("goblin1House")
if houseSource then
	for _, d in houseSource:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = true
			d.AssemblyLinearVelocity = Vector3.zero
			d.AssemblyAngularVelocity = Vector3.zero
		end
	end
	houseSource:PivotTo(floorAlignedCF(houseSource, CFrame.new(-2860, FLOOR_Y + 100, 1700), -2))
	print("[MovementLabImports] goblin1House placed at centre of Level 20.")
else
	warn("[MovementLabImports] goblin1House not found in Workspace.")
end

task.delay(3, function()
	removeUnusedImported3Ds(false)
end)
