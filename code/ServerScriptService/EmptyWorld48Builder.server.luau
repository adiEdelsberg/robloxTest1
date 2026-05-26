-- EmptyWorld48Builder.server.luau
-- Level 48 — standalone black floor, transparent walls, goblin #21.
-- Detached: no bridges to any other world.

local CX, CZ    = -2860, 11700
local FLOOR_Y   = 1
local HALF_W    = 350
local HALF_D    = 280
local WALL_H    = 60
local CONTAIN_H = 400

local GOBLIN_ROTATION       = CFrame.Angles(math.rad(90), 0, 0)
local GOBLIN_BASE_SCALE     = 0.1
local GOBLIN_SCALE_21       = GOBLIN_BASE_SCALE / 5   -- same as index 1 in level 20
local GOBLIN_LIFT           = 0
local GOBLIN_ANIM_ID        = 100938432734765          -- walk type 2 (same as goblins 1-10)
local GOBLIN_RUN_DIVE_ANIM  = 115400980127259          -- run dive (used for attack)

local old = workspace:FindFirstChild("EmptyWorld48")
if old then old:Destroy() end

local folder = Instance.new("Folder")
folder.Name   = "EmptyWorld48"
folder.Parent = workspace

local function p(name, size, cf, color, mat, trans, collide)
	local o = Instance.new("Part")
	o.Name          = name
	o.Size          = size
	o.CFrame        = cf
	o.BrickColor    = BrickColor.new(color)
	o.Material      = mat or Enum.Material.SmoothPlastic
	o.Transparency  = trans or 0
	o.Anchored      = true
	o.CanCollide    = collide ~= false
	o.CanTouch      = false
	o.CastShadow    = false
	o.TopSurface    = Enum.SurfaceType.Smooth
	o.BottomSurface = Enum.SurfaceType.Smooth
	o.Parent        = folder
	return o
end

local fullW = HALF_W * 2
local fullD = HALF_D * 2
local Y     = FLOOR_Y

-- Black floor
p("Floor", Vector3.new(fullW, 4, fullD), CFrame.new(CX, Y-2, CZ), "Really black", Enum.Material.SmoothPlastic)

-- Transparent containment walls (visible but see-through)
local wallAlpha = 0.78
p("WallN", Vector3.new(fullW, WALL_H, 2), CFrame.new(CX, Y+WALL_H/2, CZ-HALF_D), "Really black", Enum.Material.Glass, wallAlpha)
p("WallS", Vector3.new(fullW, WALL_H, 2), CFrame.new(CX, Y+WALL_H/2, CZ+HALF_D), "Really black", Enum.Material.Glass, wallAlpha)
p("WallW", Vector3.new(2, WALL_H, fullD), CFrame.new(CX-HALF_W, Y+WALL_H/2, CZ), "Really black", Enum.Material.Glass, wallAlpha)
p("WallE", Vector3.new(2, WALL_H, fullD), CFrame.new(CX+HALF_W, Y+WALL_H/2, CZ), "Really black", Enum.Material.Glass, wallAlpha)

-- Invisible tall containment above walls
p("ContainN", Vector3.new(fullW,CONTAIN_H,1), CFrame.new(CX,Y+CONTAIN_H/2,CZ-HALF_D), "Really black", nil, 1)
p("ContainS", Vector3.new(fullW,CONTAIN_H,1), CFrame.new(CX,Y+CONTAIN_H/2,CZ+HALF_D), "Really black", nil, 1)
p("ContainW", Vector3.new(1,CONTAIN_H,fullD), CFrame.new(CX-HALF_W,Y+CONTAIN_H/2,CZ), "Really black", nil, 1)
p("ContainE", Vector3.new(1,CONTAIN_H,fullD), CFrame.new(CX+HALF_W,Y+CONTAIN_H/2,CZ), "Really black", nil, 1)

-- Thin neon border around the floor edge
local stroke = 1.2
p("BorderN", Vector3.new(fullW,stroke,stroke), CFrame.new(CX,Y+0.2,CZ-HALF_D), "Really black", Enum.Material.SmoothPlastic)
p("BorderS", Vector3.new(fullW,stroke,stroke), CFrame.new(CX,Y+0.2,CZ+HALF_D), "Really black", Enum.Material.SmoothPlastic)
p("BorderW", Vector3.new(stroke,stroke,fullD), CFrame.new(CX-HALF_W,Y+0.2,CZ), "Really black", Enum.Material.SmoothPlastic)
p("BorderE", Vector3.new(stroke,stroke,fullD), CFrame.new(CX+HALF_W,Y+0.2,CZ), "Really black", Enum.Material.SmoothPlastic)

-- ── Goblin #21 ────────────────────────────────────────────────────────────────
local function floorAlignedCF(model, cf, extraLift)
	model:PivotTo(cf)
	local boxCf, size = model:GetBoundingBox()
	local bottomY = boxCf.Position.Y - size.Y / 2
	return cf + Vector3.new(0, FLOOR_Y - bottomY + (extraLift or 0), 0)
end

local function playWalkAnimation(model, animId)
	local humanoid   = model:FindFirstChildWhichIsA("Humanoid", true)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local parent     = humanoid or controller
	if not parent then
		controller = Instance.new("AnimationController")
		controller.Name   = "RuntimeAnimationController"
		controller.Parent = model
		parent = controller
	end
	local animator = parent:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = parent
	end
	local anim = Instance.new("Animation")
	anim.Name        = "RuntimeAnim"
	anim.AnimationId = "rbxassetid://" .. tostring(animId)
	anim.Parent      = parent
	local ok, track  = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok then warn("[World48] Failed to load animation:", track) return end
	track.Looped   = true
	track.Priority = Enum.AnimationPriority.Movement
	track:Play(0.15, 1, 1)
	track.Stopped:Connect(function()
		if model.Parent then track:Play(0.15, 1, 1) end
	end)
end

local function addLabel(model, index)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root then return end

	-- Floating number sign above the goblin
	local sign = Instance.new("Part")
	sign.Name        = "GoblinLabel21"
	sign.Size        = Vector3.new(28, 12, 0.1)
	sign.Transparency = 1
	sign.Anchored    = true
	sign.CanCollide  = false
	sign.CanTouch    = false
	sign.Parent      = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face           = Enum.NormalId.Front
	gui.SizingMode     = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud  = 10
	gui.LightInfluence = 0
	gui.AlwaysOnTop    = false
	gui.Parent         = sign

	local lbl = Instance.new("TextLabel")
	lbl.Size                  = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text                  = tostring(index)
	lbl.TextColor3            = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeTransparency = 1
	lbl.Font                  = Enum.Font.SourceSansBold
	lbl.TextScaled            = true
	lbl.Parent                = gui

	-- Keep sign above the goblin
	local RunService = game:GetService("RunService")
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not model.Parent or not sign.Parent then conn:Disconnect() return end
		local _, sz = model:GetBoundingBox()
		local pivot  = model:GetPivot()
		sign.CFrame  = CFrame.new(pivot.Position + Vector3.new(0, sz.Y * 0.5 + 10, 0))
	end)
end

-- Group formation offsets relative to centre (goblin 21 is front, 22-25 behind)
--   21: front centre
--   22: back-left,  23: back-right
--   24: far-back-left, 25: far-back-right
local GOBLIN_SLOTS = {
	{ index = 21, dx =   0, dz =   0 },
	{ index = 22, dx =  -4, dz =   5 },
	{ index = 23, dx =   4, dz =   5 },
	{ index = 24, dx =  -8, dz =  10 },
	{ index = 25, dx =   8, dz =  10 },
}

local GOBLIN_WALK_ANIM   = 100938432734765   -- walk type 2
local GOBLIN_KICK_ANIM   = 124566055260637   -- inside kick (attack)
local ATTACK_INTERVAL    = 10                -- seconds between attacks
local Debris             = game:GetService("Debris")

local function getAnimator(model)
	local humanoid   = model:FindFirstChildWhichIsA("Humanoid", true)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local parent     = humanoid or controller
	if not parent then return nil end
	local anim = parent:FindFirstChildOfClass("Animator")
	if not anim then
		anim = Instance.new("Animator")
		anim.Parent = parent
	end
	return anim
end

local function loadTrack(model, animId, looped, priority)
	local animator = getAnimator(model)
	if not animator then return nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animId)
	anim.Parent = animator
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok then return nil end
	track.Looped   = looped
	track.Priority = priority or Enum.AnimationPriority.Movement
	return track
end

local function fireGreenBall(model)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root then return end

	local ball = Instance.new("Part")
	ball.Name         = "GoblinBall"
	ball.Shape        = Enum.PartType.Ball
	ball.Size         = Vector3.new(2.5, 2.5, 2.5)
	ball.BrickColor   = BrickColor.new("Bright green")
	ball.Material     = Enum.Material.Neon
	ball.Transparency = 0.08
	ball.CastShadow   = false
	ball.CanTouch     = true
	ball.Anchored     = false
	ball.Parent       = workspace

	local glow = Instance.new("Part")
	glow.Shape        = Enum.PartType.Ball
	glow.Size         = Vector3.new(3.2, 3.2, 3.2)
	glow.BrickColor   = BrickColor.new("Lime green")
	glow.Material     = Enum.Material.Neon
	glow.Transparency = 0.55
	glow.Anchored     = false
	glow.CanCollide   = false
	glow.CanTouch     = false
	glow.CastShadow   = false
	glow.Parent       = workspace
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ball; weld.Part1 = glow; weld.Parent = ball

	local spawnCF = root.CFrame * CFrame.new(0, 0.5, -1)
	ball.CFrame = spawnCF
	glow.CFrame = spawnCF
	ball:ApplyImpulse(root.CFrame.LookVector * 55 * ball.AssemblyMass)

	Debris:AddItem(ball, 4)
	Debris:AddItem(glow, 4)
end

local function startGoblinLoop(model, floorCF)
	local walkTrack = loadTrack(model, GOBLIN_WALK_ANIM, true, Enum.AnimationPriority.Movement)
	if walkTrack then walkTrack:Play(0.15, 1, 1) end

	task.spawn(function()
		while model.Parent do
			task.wait(ATTACK_INTERVAL)
			if not model.Parent then break end

			-- pause walk
			if walkTrack then walkTrack:Stop(0.1) end

			-- play kick + fire ball
			local kickTrack = loadTrack(model, GOBLIN_KICK_ANIM, false, Enum.AnimationPriority.Action)
			if kickTrack then
				kickTrack:Play(0.1, 1, 1)
				fireGreenBall(model)
				kickTrack.Stopped:Wait()
			else
				fireGreenBall(model)
				task.wait(1)
			end

			-- snap back to floor position after kick lifts the model
			if model.Parent then
				model:PivotTo(floorCF)
			end

			-- resume walk
			if walkTrack and model.Parent then walkTrack:Play(0.15, 1, 1) end
		end
	end)
end

-- ── Spawn all 5 goblins ───────────────────────────────────────────────────────
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
	collider.CanTouch = false
	collider.CanQuery = false
	collider.CastShadow = false
	collider.Parent = model
end

task.spawn(function()
	local source = workspace:WaitForChild("goblin1", 15)
	if not source then
		warn("[World48] goblin1 not found in Workspace.")
		return
	end

	source.Archivable = true
	for _, d in source:GetDescendants() do d.Archivable = true end

	for _, slot in ipairs(GOBLIN_SLOTS) do
		local goblin = source:Clone()
		goblin.Name   = "goblin1_world48_" .. slot.index
		goblin.Parent = workspace

		for _, d in goblin:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored  = true
				d.CanCollide = true
				d.AssemblyLinearVelocity  = Vector3.zero
				d.AssemblyAngularVelocity = Vector3.zero
			elseif d:IsA("Humanoid") then
				d.WalkSpeed  = 0
				d.JumpPower  = 0
				d.AutoRotate = false
			end
		end

		goblin:ScaleTo(GOBLIN_SCALE_21)
		local placedCF = floorAlignedCF(goblin,
			CFrame.new(CX + slot.dx, FLOOR_Y + 100, CZ + slot.dz) * GOBLIN_ROTATION,
			GOBLIN_LIFT)
		goblin:PivotTo(placedCF)
		addGoblinCollisionBody(goblin)

		addLabel(goblin, slot.index)

		task.delay(1, function()
			if goblin.Parent then startGoblinLoop(goblin, placedCF) end
		end)

		print("[World48] Goblin #" .. slot.index .. " placed.")
		task.wait(0.05)
	end
end)

print("[EmptyWorld48Builder] Level 48 built — black floor, transparent walls, awaiting goblin #21.")
