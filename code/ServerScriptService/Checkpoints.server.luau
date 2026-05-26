local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

local oldFolder = workspace:FindFirstChild("Checkpoints")
if oldFolder then
	oldFolder:Destroy()
end

-- Disabled: physical checkpoint pads/zones and checkpoint respawn are removed.
-- Stage completion still stores the highest unlocked order for time machines.
if true then return end

local G = 1

local folder = Instance.new("Folder")
folder.Name = "Checkpoints"
folder.Parent = workspace

-- Checkpoints placed BESIDE each gate (not blocking the path).
-- Main path gates face Z; checkpoints sit at x=14 (right-side wall).
-- Bird-world gates face X; checkpoints sit at z=1724 (behind the gate, off to the side).
local CHECKPOINTS = {
	{ name = "Playground",   order = 1,  pos = Vector3.new(14, G+0.18, 0),     spawn = CFrame.new(0, 6, -6),          rotY = 0,  bounds = { minX = -59, maxX = 59, minZ = -59, maxZ = 59 } },
	{ name = "Empty World 1", order = 17, pos = Vector3.new(-900, G+0.18, 1724), spawn = CFrame.new(-550, 7, 1700),    rotY = 90, bounds = { minX = -900, maxX = -200, minZ = 1420, maxZ = 1980 } },
	{ name = "Storm Dome", order = 18, pos = Vector3.new(-1670, G+0.18, 1724), spawn = CFrame.new(-1320, 7, 1700),     rotY = 90, bounds = { minX = -1670, maxX = -970, minZ = 1420, maxZ = 1980 } },
	{ name = "Volt Abyss", order = 19, pos = Vector3.new(-2440, G+0.18, 1724), spawn = CFrame.new(-2090, 7, 1700),     rotY = 90, bounds = { minX = -2440, maxX = -1740, minZ = 1420, maxZ = 1980 } },
	{ name = "Neon Rift", order = 20, pos = Vector3.new(-3210, G+0.18, 1724), spawn = CFrame.new(-2860, 7, 1700),      rotY = 90, bounds = { minX = -3210, maxX = -2510, minZ = 1420, maxZ = 1980 } },
	{ name = "Sky Vault", order = 21, pos = Vector3.new(-3534, G+0.18, 1724), spawn = CFrame.new(-3500, 7, 1700),      rotY = 90, bounds = { minX = -3534, maxX = -3466, minZ = 1666, maxZ = 1734 } },
	{ name = "Pizza",        order = 2,  pos = Vector3.new(14, G+0.18, 96),    spawn = CFrame.new(0, 6, 142),         rotY = 0,  bounds = { minX = -72, maxX = 72, minZ = 132, maxZ = 268 } },
	{ name = "Galactic",     order = 3,  pos = Vector3.new(14, G+0.18, 314),   spawn = CFrame.new(0, 7, 398),         rotY = 0,  bounds = { minX = -70, maxX = 70, minZ = 385, maxZ = 525 } },
	{ name = "Jungle",       order = 4,  pos = Vector3.new(14, G+0.18, 567),   spawn = CFrame.new(0, 7, 652),         rotY = 0,  bounds = { minX = -70, maxX = 70, minZ = 640, maxZ = 780 } },
	{ name = "Sports",       order = 5,  pos = Vector3.new(14, G+0.18, 814),   spawn = CFrame.new(0, 7, 872),         rotY = 0,  bounds = { minX = -82, maxX = 82, minZ = 860, maxZ = 1020 } },
	{ name = "Tennis",       order = 6,  pos = Vector3.new(14, G+0.18, 1050),  spawn = CFrame.new(0, 7, 1102),        rotY = 0,  bounds = { minX = -70, maxX = 70, minZ = 1090, maxZ = 1230 } },
	{ name = "Game Station", order = 7,  pos = Vector3.new(14, G+0.18, 1260),  spawn = CFrame.new(0, 7, 1312),        rotY = 0,  bounds = { minX = -78, maxX = 78, minZ = 1300, maxZ = 1460 } },
	{ name = "Coffee Shop",  order = 8,  pos = Vector3.new(14, G+0.18, 1490),  spawn = CFrame.new(0, 7, 1558),        rotY = 0,  bounds = { minX = -140, maxX = 140, minZ = 1540, maxZ = 1860 } },
	{ name = "Burger House", order = 9,  pos = Vector3.new(224, G+0.18, 1724), spawn = CFrame.new(224, 7, 1700),      rotY = 90, bounds = { minX = 214, maxX = 490, minZ = 1540, maxZ = 1860 } },
	{ name = "New Pizza Place", order = 10, pos = Vector3.new(566, G+0.18, 1724), spawn = CFrame.new(590, 7, 1700),  rotY = 90, bounds = { minX = 566, maxX = 842, minZ = 1540, maxZ = 1860 } },
	{ name = "Swimming Pool", order = 11, pos = Vector3.new(918, G+0.18, 1724), spawn = CFrame.new(918, 7, 1700),      rotY = 90, bounds = { minX = 918, maxX = 1194, minZ = 1540, maxZ = 1860 } },
	{ name = "Dinosaur Park", order = 12, pos = Vector3.new(1270, G+0.18, 1724), spawn = CFrame.new(1270, 7, 1700),    rotY = 90, bounds = { minX = 1270, maxX = 1546, minZ = 1540, maxZ = 1860 } },
	{ name = "Dino Beach",    order = 13, pos = Vector3.new(1622, G+0.18, 1724), spawn = CFrame.new(1622, 7, 1700),    rotY = 90, bounds = { minX = 1622, maxX = 1898, minZ = 1540, maxZ = 1860 } },
	{ name = "Flying Dino Forest", order = 14, pos = Vector3.new(1974, G+0.18, 1724), spawn = CFrame.new(1974, 7, 1700), rotY = 90, bounds = { minX = 1974, maxX = 2250, minZ = 1540, maxZ = 1860 } },
	{ name = "Cherry Grove", order = 15, pos = Vector3.new(2326, G+0.18, 1724), spawn = CFrame.new(2326, 7, 1700), rotY = 90, bounds = { minX = 2308, maxX = 2620, minZ = 1380, maxZ = 2020 } },
	{ name = "Galactic Orchard", order = 16, pos = Vector3.new(2678, G+0.18, 1724), spawn = CFrame.new(2678, 7, 1700), rotY = 90, bounds = { minX = 2660, maxX = 2980, minZ = 1380, maxZ = 2020 } },
}

local checkpointByOrder = {}
for _, checkpoint in CHECKPOINTS do
	checkpoint.order = WorldOrder.getOrder(checkpoint.name) or checkpoint.order
	checkpointByOrder[checkpoint.order] = checkpoint
end

local allDebounces = {} -- [player] = debounce table, for cleanup on leave

local function makeLabel(parent, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 190, 0, 42)
	gui.StudsOffset = Vector3.new(0, 2.2, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end

local function activateCheckpoint(player, checkpoint)
	local currentOrder = player:GetAttribute("CheckpointOrder") or 0
	if checkpoint.order < currentOrder then return end
	player:SetAttribute("CheckpointOrder", checkpoint.order)
	player:SetAttribute("CheckpointName", checkpoint.name)
end

for _, checkpoint in CHECKPOINTS do
	local pad = Instance.new("Part")
	pad.Name = checkpoint.name:gsub("%s+", "") .. "Checkpoint"
	pad.Size = Vector3.new(6, 0.35, 11)   -- narrow side profile; long axis parallel to gate
	pad.CFrame = CFrame.new(checkpoint.pos) * CFrame.Angles(0, math.rad(checkpoint.rotY or 0), 0)
	pad.Anchored = true
	pad.BrickColor = BrickColor.new("Cyan")
	pad.Material = Enum.Material.Neon
	pad.Transparency = 0.24
	pad.Parent = folder

	local stroke = Instance.new("SelectionBox")
	stroke.Adornee = pad
	stroke.Color3 = Color3.fromRGB(255, 255, 255)
	stroke.LineThickness = 0.06
	stroke.SurfaceTransparency = 0.82
	stroke.Parent = pad

	makeLabel(pad, checkpoint.name .. " Checkpoint")

	local debounce = {}
	allDebounces[#allDebounces + 1] = debounce
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		local now = os.clock()
		if debounce[player] and now - debounce[player] < 1 then return end
		debounce[player] = now
		activateCheckpoint(player, checkpoint)
	end)

	local bounds = checkpoint.bounds
	if bounds then
		local trigger = Instance.new("Part")
		trigger.Name = checkpoint.name:gsub("%s+", "") .. "CheckpointZone"
		trigger.Size = Vector3.new(bounds.maxX - bounds.minX, 18, bounds.maxZ - bounds.minZ)
		trigger.CFrame = CFrame.new((bounds.minX + bounds.maxX) / 2, G + 9, (bounds.minZ + bounds.maxZ) / 2)
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.CanTouch = true
		trigger.Transparency = 1
		trigger.Parent = folder

		trigger.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then return end
			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end
			activateCheckpoint(player, checkpoint)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	-- DataLoaded is set by PlayerDataService after it restores saved progress.
	-- We wait for it before spawning so the player lands at their real checkpoint,
	-- not the default order=1 spawn.  Five-second timeout guards against DataStore outages.
	player.CharacterAdded:Connect(function(character)
		if not player:GetAttribute("DataLoaded") then
			local deadline = os.clock() + 5
			while not player:GetAttribute("DataLoaded") and os.clock() < deadline do
				task.wait(0.05)
			end
			-- Fallback: if DataService never responded, seed defaults so the
			-- player at least spawns somewhere sensible.
			if not player:GetAttribute("DataLoaded") then
				player:SetAttribute("CheckpointOrder", 1)
				player:SetAttribute("CheckpointName", "Playground")
				player:SetAttribute("DataLoaded", true)
			end
		end

		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not hrp then return end
		task.wait(0.15)
		if player:GetAttribute("UseStarterRespawn") then return end
		if player:GetAttribute("InLandingWorld") then return end
		local order = player:GetAttribute("CheckpointOrder") or 1
		local checkpoint = checkpointByOrder[order] or checkpointByOrder[1]
		hrp.CFrame = checkpoint.spawn
		hrp.AssemblyLinearVelocity = Vector3.zero
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up all per-checkpoint debounce entries for this player
	for _, debounce in allDebounces do
		debounce[player] = nil
	end
	allDebounces[player] = nil
end)

print("[Checkpoints] Built successfully!")
