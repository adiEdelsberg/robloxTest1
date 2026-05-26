-- EmptyWorld44Builder.server.luau
-- World 44: XL empty room

local CX, CZ  = -2860, 8700
local FLOOR_Y = 1
local SIZE    = 300   -- XL floor width/depth

local folder = workspace:FindFirstChild("EmptyWorld44World")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name   = "EmptyWorld44World"
folder.Parent = workspace

local function mkp(name, size, cf, color, mat, trans, noCollide)
	local p = Instance.new("Part")
	p.Name          = name
	p.Size          = size
	p.CFrame        = cf
	p.BrickColor    = BrickColor.new(color)
	p.Material      = mat or Enum.Material.SmoothPlastic
	p.Transparency  = trans or 0
	p.Anchored      = true
	p.CanCollide    = not noCollide
	p.CanTouch      = false
	p.CastShadow    = false
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent        = folder
	return p
end

local function neon(name, size, cf, color, trans)
	return mkp(name, size, cf, color, Enum.Material.Neon, trans, true)
end

local H = SIZE / 2

-- Floor
mkp("Floor", Vector3.new(SIZE, 4, SIZE),
	CFrame.new(CX, FLOOR_Y - 1, CZ), "Dark stone grey")

-- Ceiling (glass)
mkp("Ceiling", Vector3.new(SIZE, 2, SIZE),
	CFrame.new(CX, FLOOR_Y + 60, CZ), "Institutional white", Enum.Material.Glass, 0.7, true)

-- Walls
mkp("WallN", Vector3.new(SIZE, 64, 2), CFrame.new(CX,      FLOOR_Y + 32, CZ - H), "Really black", Enum.Material.SmoothPlastic)
mkp("WallS", Vector3.new(SIZE, 64, 2), CFrame.new(CX,      FLOOR_Y + 32, CZ + H), "Really black", Enum.Material.SmoothPlastic)
mkp("WallE", Vector3.new(2, 64, SIZE), CFrame.new(CX + H,  FLOOR_Y + 32, CZ),     "Really black", Enum.Material.SmoothPlastic)
mkp("WallW", Vector3.new(2, 64, SIZE), CFrame.new(CX - H,  FLOOR_Y + 32, CZ),     "Really black", Enum.Material.SmoothPlastic)

-- Neon edge strips on floor
for _, xOff in { -H + 1, H - 1 } do
	neon("EdgeX", Vector3.new(2, 0.2, SIZE), CFrame.new(CX + xOff, FLOOR_Y + 1.1, CZ), "Cyan", 0.2)
end
for _, zOff in { -H + 1, H - 1 } do
	neon("EdgeZ", Vector3.new(SIZE, 0.2, 2), CFrame.new(CX, FLOOR_Y + 1.1, CZ + zOff), "Cyan", 0.2)
end

-- Ceiling neon ring
for _, xOff in { -H + 1, H - 1 } do
	neon("CeilEdgeX", Vector3.new(2, 0.3, SIZE), CFrame.new(CX + xOff, FLOOR_Y + 59, CZ), "Bright violet", 0.3)
end
for _, zOff in { -H + 1, H - 1 } do
	neon("CeilEdgeZ", Vector3.new(SIZE, 0.3, 2), CFrame.new(CX, FLOOR_Y + 59, CZ + zOff), "Bright violet", 0.3)
end

-- Grid lines on floor
local GRID = 50
for i = -2, 2 do
	neon("GridX", Vector3.new(SIZE - 2, 0.15, 0.4), CFrame.new(CX, FLOOR_Y + 1.05, CZ + i * GRID), "Electric blue", 0.5)
	neon("GridZ", Vector3.new(0.4, 0.15, SIZE - 2), CFrame.new(CX + i * GRID, FLOOR_Y + 1.05, CZ), "Electric blue", 0.5)
end

-- Corner pillars
for _, xOff in { -H + 5, H - 5 } do
	for _, zOff in { -H + 5, H - 5 } do
		mkp("Pillar", Vector3.new(6, 58, 6),
			CFrame.new(CX + xOff, FLOOR_Y + 30, CZ + zOff), "Really black", Enum.Material.Metal)
		neon("PillarGlow", Vector3.new(6.5, 58, 6.5),
			CFrame.new(CX + xOff, FLOOR_Y + 30, CZ + zOff), "Cyan", 0.7)
	end
end

print("[EmptyWorld44] XL room built at CZ=" .. CZ)
