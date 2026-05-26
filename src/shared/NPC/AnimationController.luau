-- AnimationController
-- Lightweight animation facade. Uses Roblox AnimationTracks when animation ids
-- exist, and procedural idle/attack poses when no paid/custom assets are used.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(model, config)
	local self = setmetatable({}, AnimationController)
	self.Model = model
	self.Config = config or {}
	self.Root = model.PrimaryPart
	self.Motors = {}
	self.Tracks = {}
	self.Connections = {}
	self.State = "Idle"
	self.StartTime = os.clock()
	self.LastBob = 0
	self:_loadTracks()
	self:_startProceduralLoop()
	return self
end

function AnimationController:_loadTracks()
	local humanoid = self.Model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	for name, id in pairs(self.Config.Animations or {}) do
		if type(id) == "string" and id ~= "" then
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			self.Tracks[name] = animator:LoadAnimation(anim)
		end
	end
end

function AnimationController:_startProceduralLoop()
	table.insert(self.Connections, RunService.Heartbeat:Connect(function()
		if not self.Model.Parent or not self.Root then return end
		local t = os.clock() - self.StartTime
		local bob = math.sin(t * 2.2) * 0.12
		local bobDelta = bob - self.LastBob
		self.LastBob = bob
		local lean = self.State == "Attack" and math.rad(-8) or math.rad(-2)
		local pivot = self.Model:GetPivot()
		local _, yaw = pivot:ToOrientation()
		self.Model:PivotTo(CFrame.new(pivot.Position + Vector3.new(0, bobDelta, 0)) * CFrame.Angles(lean, yaw, 0))
	end))
end

function AnimationController:Play(state)
	self.State = state
	for name, track in pairs(self.Tracks) do
		if name == state then
			if not track.IsPlaying then track:Play(0.12) end
		elseif track.IsPlaying then
			track:Stop(0.12)
		end
	end
end

function AnimationController:AttackPose(duration)
	self:Play("Attack")
	local root = self.Root
	if root then
		local original = root.CFrame
		TweenService:Create(root, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = original * CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(-10), 0, 0),
		}):Play()
	end
	task.delay(duration or 0.22, function()
		if self.Model.Parent then
			self:Play("Idle")
		end
	end)
end

function AnimationController:Destroy()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	for _, track in pairs(self.Tracks) do
		track:Stop(0)
	end
end

return AnimationController
