-- SkyVaultNature.server.luau
-- Decorates Level 20 (Neon Rift) with Nature Pack assets.

local CX      = -2860
local CZ      = 1700
local FLOOR_Y = 1
local HALF_W  = 300
local HALF_D  = 240

-- Find the nature pack by partial name match
local pack
for _, obj in ipairs(workspace:GetChildren()) do
	if obj.Name:lower():find("nature", 1, true) then
		pack = obj
		print("[SkyVaultNature] Found pack: " .. obj.Name)
		break
	end
end

if not pack then
	warn("[SkyVaultNature] No model with 'Nature' in its name found in Workspace. Make sure you inserted the nature pack.")
	return
end

local folder = workspace:FindFirstChild("SkyVaultNature")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name   = "SkyVaultNature"
folder.Parent = workspace

-- Collect asset sources: direct children that are Models or Parts
pack.Archivable = true
local assets = {}
for _, child in ipairs(pack:GetDescendants()) do
	if (child:IsA("Model") or child:IsA("BasePart")) and child.Parent == pack then
		child.Archivable = true
		for _, d in child:GetDescendants() do d.Archivable = true end
		table.insert(assets, child)
	end
end

-- Fallback: if pack itself is one big model, use it directly
if #assets == 0 and (pack:IsA("Model") or pack:IsA("BasePart")) then
	table.insert(assets, pack)
end

print("[SkyVaultNature] Asset pool size: " .. #assets)

if #assets == 0 then
	warn("[SkyVaultNature] Nature pack has no usable children.")
	return
end

local function anchorAll(m)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = true
			d.AssemblyLinearVelocity = Vector3.zero
			d.AssemblyAngularVelocity = Vector3.zero
		end
	end
	if m:IsA("BasePart") then
		m.Anchored = true
	end
end

local function floorPlace(clone, x, z, yaw)
	-- Temporarily place high up, measure bottom, then drop to floor
	local cf = CFrame.new(x, FLOOR_Y + 200, z) * CFrame.Angles(0, yaw, 0)
	if clone:IsA("Model") then
		local pp = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
		if not pp then return end
		clone.PrimaryPart = pp
		clone:PivotTo(cf)
		local boxCf, size = clone:GetBoundingBox()
		local bottomY = boxCf.Position.Y - size.Y / 2
		local lift = FLOOR_Y - bottomY
		clone:PivotTo(cf + Vector3.new(0, lift, 0))
	elseif clone:IsA("BasePart") then
		clone.CFrame = cf
		local bottomY = clone.Position.Y - clone.Size.Y / 2
		local lift = FLOOR_Y - bottomY
		clone.CFrame = cf + Vector3.new(0, lift, 0)
	end
end

-- goblin1House is at the centre (CX, CZ); place nature in rings around it
local INNER_R = 60   -- min distance from house centre
local OUTER_R = 220  -- max distance

math.randomseed(13)

local placed = 0
for i = 1, 80 do
	local source = assets[math.random(1, #assets)]
	local clone  = source:Clone()
	clone.Parent = folder
	anchorAll(clone)

	local scale = 0.4 + math.random() * 0.8
	if clone:IsA("Model") then
		pcall(function() clone:ScaleTo(scale) end)
	end

	-- Random point in an annulus around the house
	local angle = math.random() * math.pi * 2
	local r     = INNER_R + math.random() * (OUTER_R - INNER_R)
	local x     = CX + math.cos(angle) * r
	local z     = CZ + math.sin(angle) * r

	-- Clamp inside room bounds
	x = math.clamp(x, CX - HALF_W + 15, CX + HALF_W - 15)
	z = math.clamp(z, CZ - HALF_D + 15, CZ + HALF_D - 15)

	local yaw = math.random() * math.pi * 2

	floorPlace(clone, x, z, yaw)
	placed += 1
end

-- Move pack to ServerStorage so it's hidden from players but still clonable
pack.Parent = game:GetService("ServerStorage")

print(string.format("[SkyVaultNature] Placed %d nature pieces inside Level 20 (Neon Rift).", placed))
