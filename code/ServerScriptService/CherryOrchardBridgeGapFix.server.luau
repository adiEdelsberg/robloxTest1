-- CherryOrchardBridgeGapFix.server.luau
-- Extra support under the room 15 -> 16 bridge so no seam can drop players.

local folder = workspace:FindFirstChild("BridgeGapFixes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "BridgeGapFixes"
	folder.Parent = workspace
end

local old = folder:FindFirstChild("CherryOrchardGapSupport")
if old then
	old:Destroy()
end

local support = Instance.new("Part")
support.Name = "CherryOrchardGapSupport"
support.Size = Vector3.new(112, 1.6, 124)
support.Position = Vector3.new(2640, 1.2, 1700)
support.Anchored = true
support.CanCollide = true
support.CanTouch = false
support.CastShadow = false
support.Material = Enum.Material.SmoothPlastic
support.BrickColor = BrickColor.new("Really black")
support.Transparency = 0.08
support.TopSurface = Enum.SurfaceType.Smooth
support.BottomSurface = Enum.SurfaceType.Smooth
support.Parent = folder

local glow = Instance.new("Part")
glow.Name = "CherryOrchardGapSupportGlow"
glow.Size = Vector3.new(106, 0.16, 116)
glow.Position = Vector3.new(2640, 2.05, 1700)
glow.Anchored = true
glow.CanCollide = false
glow.CanTouch = false
glow.CastShadow = false
glow.Material = Enum.Material.Neon
glow.BrickColor = BrickColor.new("Cyan")
glow.Transparency = 0.74
glow.TopSurface = Enum.SurfaceType.Smooth
glow.BottomSurface = Enum.SurfaceType.Smooth
glow.Parent = folder

print("[CherryOrchardBridgeGapFix] Closed bridge gap between rooms 15 and 16.")
