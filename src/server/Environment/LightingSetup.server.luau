-- LightingSetup.server
-- Server-owned baseline lighting. Clients can still add post-processing locally.
-- Map this script into ServerScriptService with Rojo when using the src tree.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualConfig = require(ReplicatedStorage:WaitForChild("Visuals"):WaitForChild("VisualConfig"))
local L = VisualConfig.Lighting

Lighting.ClockTime = L.ClockTime
Lighting.Brightness = L.Brightness
Lighting.ExposureCompensation = L.ExposureCompensation
Lighting.Ambient = L.Ambient
Lighting.OutdoorAmbient = L.OutdoorAmbient
Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale
Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale
Lighting.Technology = Enum.Technology.Future
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.35

local atmosphere = Lighting:FindFirstChild("PremiumAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "PremiumAtmosphere"
atmosphere.Density = L.Atmosphere.Density
atmosphere.Offset = L.Atmosphere.Offset
atmosphere.Color = L.Atmosphere.Color
atmosphere.Decay = L.Atmosphere.Decay
atmosphere.Glare = L.Atmosphere.Glare
atmosphere.Haze = L.Atmosphere.Haze
atmosphere.Parent = Lighting

print("[LightingSetup] Future cinematic lighting applied.")
