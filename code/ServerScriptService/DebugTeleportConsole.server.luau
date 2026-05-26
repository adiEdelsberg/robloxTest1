-- DebugTeleportConsole.server.luau
-- Builds the physical console. Button logic handled client-side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local IS_DEBUG = Balance.ActiveMode == "debug" or Balance.ActiveMode == "test" or Balance.ActiveMode == "fallback-debug"
if not IS_DEBUG then return end

local G  = 84
-- Left side of spin wheel (WX=78, WZ=-735), near the stairs
local CX = 56
local CY = G
local CZ = -735

local PW, PH, PD = 14, 22, 3

local folder = Instance.new("Folder")
folder.Name   = "DebugTeleportConsole"
folder.Parent = workspace

local function part(name, size, pos, color, mat, trans)
	local p = Instance.new("Part")
	p.Name          = name
	p.Size          = size
	p.Position      = pos
	p.BrickColor    = BrickColor.new(color)
	p.Material      = mat or Enum.Material.SmoothPlastic
	p.Anchored      = true
	p.CanCollide    = true
	p.CastShadow    = false
	p.Transparency  = trans or 0
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent        = folder
	return p
end

part("PedestalBase", Vector3.new(PW + 2, 2, PD + 2),
	Vector3.new(CX, CY + 1, CZ), "Dark stone grey", Enum.Material.Metal)

local body = part("ConsoleFace", Vector3.new(PW, PH, PD),
	Vector3.new(CX, CY + 2 + PH/2, CZ), "Really black", Enum.Material.SmoothPlastic)

local bT = 0.3
local bY = CY + 2 + PH/2
part("BorderTop",   Vector3.new(PW+0.6, bT, bT), Vector3.new(CX, bY+PH/2+0.3, CZ-PD/2-0.1), "Bright red", Enum.Material.Neon)
part("BorderBot",   Vector3.new(PW+0.6, bT, bT), Vector3.new(CX, bY-PH/2-0.3, CZ-PD/2-0.1), "Bright red", Enum.Material.Neon)
part("BorderLeft",  Vector3.new(bT, PH+0.6, bT), Vector3.new(CX-PW/2-0.3, bY, CZ-PD/2-0.1), "Bright red", Enum.Material.Neon)
part("BorderRight", Vector3.new(bT, PH+0.6, bT), Vector3.new(CX+PW/2+0.3, bY, CZ-PD/2-0.1), "Bright red", Enum.Material.Neon)

local gui = Instance.new("SurfaceGui")
gui.Name          = "TeleportConsoleGui"
gui.Face          = Enum.NormalId.Front
gui.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 30
gui.LightInfluence= 0
gui.Parent        = body

local bg = Instance.new("Frame")
bg.Name                   = "BG"
bg.Size                   = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3       = Color3.fromRGB(6, 6, 14)
bg.BackgroundTransparency = 0.05
bg.BorderSizePixel        = 0
bg.Parent                 = gui

print("[DebugTeleportConsole] Built at X=" .. CX .. " Z=" .. CZ)
