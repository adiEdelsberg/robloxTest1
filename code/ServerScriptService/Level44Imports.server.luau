-- Level44Imports.server.luau
-- Places imported 3D models into level 44 and level 45

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CX44, CZ44 = -2860, 8700
local CX45, CZ45 = -2860, 9150
local FLOOR_Y = 1

-- Animate all bones and Motor6Ds found in a model
local function animateAllJoints(model, speedMult)
	speedMult = speedMult or 1
	local entries = {}

	for i, d in ipairs(model:GetDescendants()) do
		if d:IsA("Bone") or d:IsA("Motor6D") then
			local rest = d:IsA("Bone") and d.Transform or d.Transform
			local n    = d.Name:lower()
			local phase
			if n:find("right") or n:find("_r") or n:find("r_") then
				phase = 1
			elseif n:find("left") or n:find("_l") or n:find("l_") then
				phase = -1
			else
				phase = (i % 2 == 0) and 1 or -1
			end
			-- Pick axis based on joint name
			local ax, ay, az = 1, 0, 0
			if n:find("spine") or n:find("twist") or n:find("hip") or n:find("pelvis") then
				ax, ay, az = 0, 1, 0
			elseif n:find("head") or n:find("neck") then
				ax, ay, az = 0, 1, 0
			end
			table.insert(entries, { obj = d, isBone = d:IsA("Bone"), rest = rest, phase = phase, ax = ax, ay = ay, az = az })
		end
	end

	if #entries == 0 then
		print("[Anim] " .. model.Name .. " — no joints found")
		return
	end

	print("[Anim] " .. model.Name .. " — animating " .. #entries .. " joints")

	local SPEED = 2.5 * speedMult
	local AMP   = math.rad(22)

	RunService.Heartbeat:Connect(function()
		if not model.Parent then return end
		local t = os.clock()
		for _, e in entries do
			local swing = math.sin(t * SPEED * math.pi * 2 + e.phase * math.pi) * AMP
			local rot   = CFrame.Angles(e.ax * swing, e.ay * swing, e.az * swing)
			e.obj.Transform = e.rest * rot
		end
	end)
end

local function anchorAndPlace(model, x, y, z, scale, yaw)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true end
	end
	local pivot = model:GetPivot()
	if scale then
		model:ScaleTo(scale)
		model:PivotTo(pivot)
	end
	local _, size = model:GetBoundingBox()
	local finalY = y or (FLOOR_Y + size.Y / 2)
	model:PivotTo(CFrame.new(x, finalY, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	print("[Level44Imports] placed " .. model.Name)
end

local function patrolModel(model, waypoints, speed)
	speed = speed or 18
	local _, size = model:GetBoundingBox()
	local Y = FLOOR_Y + size.Y / 2

	local cfVal = Instance.new("CFrameValue")
	cfVal.Value  = model:GetPivot()
	cfVal.Parent = model

	cfVal:GetPropertyChangedSignal("Value"):Connect(function()
		if model.Parent then model:PivotTo(cfVal.Value) end
	end)

	task.spawn(function()
		local idx = 1
		while model.Parent do
			local nextIdx = (idx % #waypoints) + 1
			local from = waypoints[idx]
			local to   = waypoints[nextIdx]
			local dx   = to.x - from.x
			local dz   = to.z - from.z
			local dist = math.sqrt(dx*dx + dz*dz)
			local time = math.max(1.5, dist / speed)
			local yaw  = math.atan2(-dx, -dz)
			local target = CFrame.new(to.x, Y, to.z) * CFrame.Angles(0, yaw, 0)

			TweenService:Create(cfVal,
				TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Value = target }
			):Play()

			task.wait(time + 0.4)
			idx = nextIdx
		end
	end)
end

local function waitFor(name)
	local m = workspace:WaitForChild(name, 10)
	if not m then warn("[Level44Imports] not found: " .. name) end
	return m
end

-- ── Level 44: car, zombie, Model, room2 x2 ───────────────────────────────────
local room2 = waitFor("room2")
if room2 then
	anchorAndPlace(room2, CX44 - 80, nil, CZ44 - 80, nil, 0)
	animateAllJoints(room2)
	local room2clone = room2:Clone()
	room2clone.Parent = workspace
	anchorAndPlace(room2clone, CX44 + 80, nil, CZ44 + 80, nil, 180)
	animateAllJoints(room2clone, 1.3)

	-- Place tung tung from inside room2
	local tungtung = room2:FindFirstChild("Meshes/tung tung")
		or room2:FindFirstChild("tung tung", true)
	if tungtung then
		local clone = tungtung:Clone()
		clone.Parent = workspace
		anchorAndPlace(clone, CX44, nil, CZ44 - 60, nil, 180)
		animateAllJoints(clone, 1.0)
		print("[Level44Imports] tung tung placed")
	else
		warn("[Level44Imports] tung tung not found inside room2")
	end
end

local car = waitFor("2021 Koenigsegg Jesko // Rosh")
if car then
	anchorAndPlace(car, CX44 - 60, nil, CZ44, nil, 90)
	animateAllJoints(car, 0.8)
end

local zombie = waitFor("Drooling Zombie")
if zombie then
	anchorAndPlace(zombie, CX44, nil, CZ44, nil, 0)

	-- Print every single descendant so we know what's there
	print("[Zombie] === ALL DESCENDANTS ===")
	local parts = {}
	for _, d in zombie:GetDescendants() do
		print("[Zombie] " .. d.ClassName .. " | " .. d.Name)
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	print("[Zombie] === " .. #parts .. " BaseParts found ===")

	-- Walk cycle: categorise parts by position relative to model centre
	if #parts > 0 then
		local cf0, sz0 = zombie:GetBoundingBox()
		local midY  = cf0.Y
		local midX  = cf0.X
		local thirdH = sz0.Y / 3

		local pivotCF = zombie:GetPivot()
		local entries = {}
		for _, p in parts do
			local relCF = pivotCF:ToObjectSpace(p.CFrame)
			local py    = p.Position.Y
			local px    = p.Position.X

			-- Classify by vertical position
			local zone   -- "leg", "arm", "torso", "head"
			if py < midY - thirdH * 0.3 then
				zone = "leg"
			elseif py > midY + thirdH then
				zone = "head"
			else
				zone = "arm"
			end

			-- Left vs right by X
			local side = px < midX and -1 or 1

			-- Walk cycle settings per zone
			local amp, phase, axis
			if zone == "leg" then
				amp   = math.rad(35)
				phase = side          -- left leg forward when right leg back
				axis  = "x"
			elseif zone == "arm" then
				amp   = math.rad(25)
				phase = -side         -- arms swing opposite to same-side leg
				axis  = "x"
			elseif zone == "head" then
				amp   = math.rad(6)
				phase = 1
				axis  = "y"           -- head sways side to side
			else
				amp   = math.rad(4)
				phase = 1
				axis  = "z"
			end

			table.insert(entries, { part = p, relCF = relCF, amp = amp, phase = phase, axis = axis })
		end

		RunService.Heartbeat:Connect(function()
			if not zombie.Parent then return end
			local t     = os.clock()
			local pivot = zombie:GetPivot()
			for _, e in entries do
				local swing   = math.sin(t * 2.5 * math.pi * 2 + e.phase * math.pi) * e.amp
				local rot
				if e.axis == "x" then
					rot = CFrame.Angles(swing, 0, 0)
				elseif e.axis == "y" then
					rot = CFrame.Angles(0, swing, 0)
				else
					rot = CFrame.Angles(0, 0, swing)
				end
				local worldCF = pivot:ToWorldSpace(e.relCF)
				local topCF   = worldCF * CFrame.new(0, e.part.Size.Y / 2, 0)
				e.part.CFrame = topCF * rot * CFrame.new(0, -e.part.Size.Y / 2, 0)
			end
		end)
		print("[Zombie] walk animation running on " .. #entries .. " parts")
	end
end

local model = waitFor("Model")
if model then
	anchorAndPlace(model, CX44 + 60, nil, CZ44 + 50, nil, 0)
	animateAllJoints(model)
end

-- ── Level 45: spread the 67 brainrots in a grid ──────────────────────────────
local brainrots = waitFor("67")
if brainrots then
	local children = brainrots:GetChildren()
	print("[Level44Imports] placing " .. #children .. " brainrots in level 45")

	local cols    = math.ceil(math.sqrt(#children))
	local spacing = 30

	for i, child in ipairs(children) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local x   = CX45 + (col - cols / 2) * spacing
		local z   = CZ45 + (row - cols / 2) * spacing

		for _, d in child:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		local pivot = child:GetPivot()
		child:ScaleTo(1)
		child:PivotTo(pivot)
		local _, size = child:GetBoundingBox()
		child:PivotTo(CFrame.new(x, FLOOR_Y + size.Y / 2, z))
	end
end
