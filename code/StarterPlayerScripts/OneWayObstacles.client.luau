-- OneWayObstacles.client.luau
-- Makes solid obstacle parts in levels 23-40 one-way:
-- players can pass through from below and land on top.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local WorldOrder        = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local player = Players.LocalPlayer

-- Build the set of world folder names for levels 23-40
local TARGET_FOLDERS = {}
for _, world in ipairs(WorldOrder.Worlds) do
	if world.order >= 23 and world.order <= 40 then
		local folderName = world.name:gsub("%s+", "") .. "World"
		TARGET_FOLDERS[folderName] = true
	end
end

-- Parts whose names indicate structural geometry (not obstacles)
local function isStructural(part)
	local n = part.Name
	return n == "Wall"    or n == "Floor"   or n == "Ceiling"
		or n == "Roof"    or n == "Base"     or n == "Ground"
		or n:find("Wall")    ~= nil
		or n:find("Border")  ~= nil
		or n:find("Post")    ~= nil
		or n:find("Backing") ~= nil
		or n:find("Pedestal") ~= nil
end

-- Active parts to manage this frame: array of BasePart
local managedParts = {}
local managedSet   = {}   -- part → true, prevents duplicates

local function registerPart(p)
	if managedSet[p] then return end
	if not p:IsA("BasePart") then return end
	if not p.CanCollide then return end
	if isStructural(p) then return end
	managedSet[p] = true
	table.insert(managedParts, p)
end

local function scanFolder(folder)
	for _, desc in folder:GetDescendants() do
		registerPart(desc)
	end
	-- also catch parts added later (e.g. spawning obstacles)
	folder.DescendantAdded:Connect(function(desc)
		task.defer(function()
			if desc.Parent then registerPart(desc) end
		end)
	end)
end

local function onChildAdded(child)
	if TARGET_FOLDERS[child.Name] then
		task.delay(0.2, function()
			if child.Parent then scanFolder(child) end
		end)
	end
end

-- Scan folders already in workspace
for _, child in workspace:GetChildren() do
	onChildAdded(child)
end
workspace.ChildAdded:Connect(onChildAdded)

-- ── Per-frame one-way collision ───────────────────────────────────────────────
-- A part's collision is enabled only when the player's root is at or above
-- the part's top surface (so you can stand on it), and disabled otherwise
-- (so you can jump through from below).
RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local playerY = hrp.Position.Y

	local i = 1
	while i <= #managedParts do
		local p = managedParts[i]
		if not p or not p.Parent then
			-- Part was destroyed; remove from list
			managedSet[p] = nil
			table.remove(managedParts, i)
		else
			local topY = p.Position.Y + p.Size.Y * 0.5
			-- Enable collision only when player center is above the top surface
			p.CanCollide = (playerY >= topY - 0.5)
			i += 1
		end
	end
end)
