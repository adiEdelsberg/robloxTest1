-- PostProcessing.client
-- Place in StarterPlayerScripts or map through Rojo as a client script.
-- Creates cinematic post effects once, then keeps them tuned from VisualConfig.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualConfig = require(ReplicatedStorage:WaitForChild("Visuals"):WaitForChild("VisualConfig"))
local Post = VisualConfig.Post

local function getEffect(className, name)
	local effect = Lighting:FindFirstChild(name)
	if effect and not effect:IsA(className) then
		effect:Destroy()
		effect = nil
	end
	if not effect then
		effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
	end
	return effect
end

local bloom = getEffect("BloomEffect", "PremiumBloom")
bloom.Intensity = Post.Bloom.Intensity
bloom.Size = Post.Bloom.Size
bloom.Threshold = Post.Bloom.Threshold

local color = getEffect("ColorCorrectionEffect", "PremiumColor")
color.Brightness = Post.ColorCorrection.Brightness
color.Contrast = Post.ColorCorrection.Contrast
color.Saturation = Post.ColorCorrection.Saturation
color.TintColor = Post.ColorCorrection.TintColor

local dof = getEffect("DepthOfFieldEffect", "PremiumDepthOfField")
dof.FarIntensity = Post.DepthOfField.FarIntensity
dof.FocusDistance = Post.DepthOfField.FocusDistance
dof.InFocusRadius = Post.DepthOfField.InFocusRadius
dof.NearIntensity = Post.DepthOfField.NearIntensity

local rays = getEffect("SunRaysEffect", "PremiumSunRays")
rays.Intensity = Post.SunRays.Intensity
rays.Spread = Post.SunRays.Spread

print("[PostProcessing] Premium post effects ready.")
