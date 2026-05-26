-- CameraEffects
-- Client module for camera shake and FOV boosts.
-- Usage:
-- local CameraEffects = require(path.CameraEffects)
-- CameraEffects.Shake("HeavyHit")
-- CameraEffects.FOVBoost(78, 0.18)

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VisualConfig = require(ReplicatedStorage:WaitForChild("Visuals"):WaitForChild("VisualConfig"))

local CameraEffects = {}
local rng = Random.new()
local activeShake = nil

local function getCamera()
	return Workspace.CurrentCamera
end

function CameraEffects.FOVBoost(targetFov, duration)
	local camera = getCamera()
	if not camera then return end
	local baseFov = VisualConfig.Camera.BaseFOV
	local up = TweenService:Create(camera, TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = targetFov or VisualConfig.Camera.DashFOV })
	up:Play()
	up.Completed:Once(function()
		if camera then
			TweenService:Create(camera, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = baseFov }):Play()
		end
	end)
end

function CameraEffects.Shake(presetName)
	local preset = presetName == "HeavyHit" and VisualConfig.Camera.HeavyHitShake or VisualConfig.Camera.HitShake
	activeShake = {
		start = os.clock(),
		duration = preset.Duration,
		magnitude = preset.Magnitude,
		frequency = preset.Frequency,
	}
end

RunService:BindToRenderStep("PremiumCameraEffects", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = getCamera()
	if not camera or not activeShake then return end
	local t = os.clock() - activeShake.start
	if t >= activeShake.duration then
		activeShake = nil
		return
	end
	local fade = 1 - (t / activeShake.duration)
	local mag = activeShake.magnitude * fade
	local offset = Vector3.new(
		(rng:NextNumber() - 0.5) * mag,
		(rng:NextNumber() - 0.5) * mag,
		0
	)
	camera.CFrame = camera.CFrame * CFrame.new(offset)
end)

return CameraEffects
