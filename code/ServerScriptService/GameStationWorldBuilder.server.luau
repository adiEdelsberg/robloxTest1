-- Game Station World sits south of Tennis World.
-- Tennis world ends at z=1230. Game bridge: z=1230->1300. Game world: z=1300->1460.

local G = 1

local folder = Instance.new("Folder")
folder.Name = "GameStationWorld"
folder.Parent = workspace

local SMP    = Enum.Material.SmoothPlastic
local NEON   = Enum.Material.Neon
local METAL  = Enum.Material.Metal
local DPLATE = Enum.Material.DiamondPlate
local CONCRETE = Enum.Material.DiamondPlate  -- all concrete → DiamondPlate

local function p(name, size, pos, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or SMP
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local function pcf(name, size, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or SMP
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local function cylinder(name, size, cf, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or SMP
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local function ball(name, pos, size, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Position = pos
	part.BrickColor = BrickColor.new(color)
	part.Material = mat or SMP
	part.Anchored = true
	part.CanCollide = not noCollide
	part.CastShadow = false
	part.Transparency = trans or 0
	part.Parent = folder
	return part
end

local function sign(part, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 560, 0, 110)
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end

local C90Z = CFrame.Angles(0, 0, math.rad(90))

-- Bridge from tennis.
local BZ1, BZ2 = 1230, 1300
local BZC = (BZ1 + BZ2) / 2
p("GameBridgeFloor", Vector3.new(12, 0.45, BZ2 - BZ1), Vector3.new(0, G + 0.23, BZC), "Dark stone grey", DPLATE)
for bz = BZ1 + 5, BZ2 - 5, 10 do
	p("BridgeGlow", Vector3.new(10, 0.12, 0.4), Vector3.new(0, G + 0.52, bz), (bz % 20 == 0) and "Cyan" or "Hot pink", NEON, 0.2, true)
end
for _, x in { -6.3, 6.3 } do
	p("BridgeRail", Vector3.new(0.35, 0.35, BZ2 - BZ1), Vector3.new(x, G + 3.5, BZC), "Cyan", NEON, 0.15)
	for bz = BZ1 + 6, BZ2 - 6, 10 do
		p("BridgePost", Vector3.new(0.45, 3.5, 0.45), Vector3.new(x, G + 1.75, bz), "Really black", METAL)
	end
end

local arch = p("GameStationArchSign", Vector3.new(36, 5, 0.5), Vector3.new(0, G + 13, BZ2), "Really black", SMP, 0, true)
sign(arch, "GAME STATION", Color3.fromRGB(80, 220, 255))
p("GameArchL", Vector3.new(1, 13, 1), Vector3.new(-9, G + 6.5, BZ2), "Really black", METAL)
p("GameArchR", Vector3.new(1, 13, 1), Vector3.new(9, G + 6.5, BZ2), "Really black", METAL)
p("GameArchTop", Vector3.new(20, 1, 1), Vector3.new(0, G + 13, BZ2), "Hot pink", NEON, 0.15)

-- Main world.
local WZ1, WZ2 = 1300, 1460
local WZC = (WZ1 + WZ2) / 2
local HW = 78
p("ConsoleFloor", Vector3.new(HW * 2, 2, WZ2 - WZ1), Vector3.new(0, 0, WZC), "Really black", DPLATE)

for x = -HW, HW, 13 do
	p("GridZ", Vector3.new(0.18, 0.08, WZ2 - WZ1), Vector3.new(x, G + 0.08, WZC), "Cyan", NEON, 0.55, true)
end
for z = WZ1, WZ2, 13 do
	p("GridX", Vector3.new(HW * 2, 0.08, 0.18), Vector3.new(0, G + 0.09, z), "Hot pink", NEON, 0.6, true)
end

local FH, CW = 7, 36
for _, x in { -HW, HW } do
	p("WallSide", Vector3.new(0.6, FH, WZ2 - WZ1), Vector3.new(x, G + FH / 2, WZC), "Dark blue", NEON, 0.45)
	p("ContainSide", Vector3.new(0.5, CW, WZ2 - WZ1), Vector3.new(x, G + CW / 2, WZC), "Really black", SMP, 1)
end
p("WallNorthL", Vector3.new(HW - 7, FH, 0.6), Vector3.new(-(HW + 7) / 2, G + FH / 2, WZ1), "Dark blue", NEON, 0.45)
p("WallNorthR", Vector3.new(HW - 7, FH, 0.6), Vector3.new((HW + 7) / 2, G + FH / 2, WZ1), "Dark blue", NEON, 0.45)
p("WallSouthL", Vector3.new(HW - 8, FH, 0.6), Vector3.new(-(HW + 8) / 2, G + FH / 2, WZ2), "Dark blue", NEON, 0.45)
p("WallSouthR", Vector3.new(HW - 8, FH, 0.6), Vector3.new((HW + 8) / 2, G + FH / 2, WZ2), "Dark blue", NEON, 0.45)
p("ContainNorthL", Vector3.new(HW - 7, CW, 0.5), Vector3.new(-(HW + 7) / 2, G + CW / 2, WZ1), "Really black", SMP, 1)
p("ContainNorthR", Vector3.new(HW - 7, CW, 0.5), Vector3.new((HW + 7) / 2, G + CW / 2, WZ1), "Really black", SMP, 1)
p("ContainSouthL", Vector3.new(HW - 8, CW, 0.5), Vector3.new(-(HW + 8) / 2, G + CW / 2, WZ2), "Really black", SMP, 1)
p("ContainSouthR", Vector3.new(HW - 8, CW, 0.5), Vector3.new((HW + 8) / 2, G + CW / 2, WZ2), "Really black", SMP, 1)

-- Giant controller plaza.
local CX, CZ = 0, WZC
p("ControllerBody", Vector3.new(70, 3, 38), Vector3.new(CX, G + 1.5, CZ), "Dark stone grey", DPLATE)
ball("ControllerGripL", Vector3.new(CX - 34, G + 1.4, CZ + 10), 18, "Smoky grey", DPLATE, 0, false)
ball("ControllerGripR", Vector3.new(CX + 34, G + 1.4, CZ + 10), 18, "Smoky grey", DPLATE, 0, false)
p("TouchPad", Vector3.new(22, 0.35, 14), Vector3.new(CX, G + 3.25, CZ - 4), "Really black", SMP)
p("TouchGlow", Vector3.new(18, 0.08, 10), Vector3.new(CX, G + 3.48, CZ - 4), "Cyan", NEON, 0.35, true)

local function button(name, x, z, color, text)
	local b = cylinder(name, Vector3.new(1.1, 6.5, 6.5), CFrame.new(x, G + 4, z) * C90Z, color, NEON, 0.08, false)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 70, 0, 44)
	gui.StudsOffset = Vector3.new(0, 1.4, 0)
	gui.Parent = b
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end
button("ButtonNorth", 30, CZ - 12, "Bright green", "A")
button("ButtonEast", 42, CZ, "Bright red", "B")
button("ButtonWest", 18, CZ, "Bright blue", "X")
button("ButtonSouth", 30, CZ + 12, "Bright yellow", "Y")

p("DPadH", Vector3.new(22, 1, 7), Vector3.new(CX - 32, G + 3.8, CZ), "Dark stone grey", DPLATE)
p("DPadV", Vector3.new(7, 1, 22), Vector3.new(CX - 32, G + 3.9, CZ), "Dark stone grey", DPLATE)
cylinder("StickL", Vector3.new(1.3, 11, 11), CFrame.new(CX - 14, G + 4.2, CZ + 15) * C90Z, "Dark stone grey", DPLATE)
cylinder("StickR", Vector3.new(1.3, 11, 11), CFrame.new(CX + 12, G + 4.2, CZ + 15) * C90Z, "Dark stone grey", DPLATE)

-- Console tower, game cases, screens, and neon props.
p("ConsoleTower", Vector3.new(18, 34, 12), Vector3.new(-55, G + 17, WZ1 + 34), "Dark stone grey", DPLATE)
p("ConsoleLight", Vector3.new(0.35, 28, 0.35), Vector3.new(-45.8, G + 18, WZ1 + 28), "Cyan", NEON, 0.1, true)
p("DiscSlot", Vector3.new(12, 0.45, 0.4), Vector3.new(-55, G + 24, WZ1 + 27.7), "Institutional white", NEON, 0.35, true)

for i = 0, 4 do
	p("GameCase", Vector3.new(7, 10, 1.2), Vector3.new(45 + i * 5, G + 5, WZ1 + 28 + i * 4), (i % 2 == 0) and "Bright blue" or "Hot pink", SMP)
end

for _, screen in { {-45, WZ2 - 35, "PLAYER 1"}, {45, WZ2 - 35, "BOSS LEVEL"} } do
	local panel = p("Screen", Vector3.new(34, 22, 1), Vector3.new(screen[1], G + 15, screen[2]), "Really black", SMP)
	sign(panel, screen[3], Color3.fromRGB(150, 255, 85))
	p("ScreenGlow", Vector3.new(30, 17, 0.4), Vector3.new(screen[1], G + 15, screen[2] - 0.7), "Cyan", NEON, 0.72, true)
	p("ScreenStand", Vector3.new(4, 9, 3), Vector3.new(screen[1], G + 4.5, screen[2] + 2), "Dark stone grey", METAL)
end

for _, pos in { {-62, 1345}, {-35, 1420}, {54, 1328}, {62, 1408}, {0, 1324}, {-8, 1450} } do
	ball("PixelOrb", Vector3.new(pos[1], G + 6, pos[2]), 5, (pos[1] % 2 == 0) and "Cyan" or "Hot pink", NEON, 0.25, true)
end

local worldSign = p("GameStationWorldSign", Vector3.new(42, 5, 0.5), Vector3.new(0, G + 14, WZ1 + 5), "Really black", SMP, 0, true)
sign(worldSign, "CONTROLLER ARENA", Color3.fromRGB(255, 230, 70))

print("[GameStationWorld] Built successfully!")
