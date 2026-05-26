-- ExampleGoblinEnemy.server
-- Example spawner for a premium stylized fantasy enemy. Disable this script or
-- move the SpawnExample call into your world logic when you are ready.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NPCController = require(script.Parent:WaitForChild("NPCController"))
local Factory = require(ReplicatedStorage:WaitForChild("Visuals"):WaitForChild("PremiumNPCFactory"))

local function spawnOne(folder, name, cf)
	local model = Factory.CreateWorld43Small({
		Parent = folder,
		Name = name,
		DisplayName = "Forest Goblin",
		CFrame = cf,
		TargetIndex = nil,
		ShirtColor = Color3.fromRGB(92, 48, 31),
		MaxHealth = 42,
	})

	NPCController.new(model, "ForestGoblin")
end

local function spawnExample()
	local folder = workspace:FindFirstChild("FantasyNPCExamples") or Instance.new("Folder")
	folder.Name = "FantasyNPCExamples"
	folder.Parent = workspace

	spawnOne(folder, "ExampleForestGoblinA", CFrame.new(-2898, 5, 8432))
	spawnOne(folder, "ExampleForestGoblinB", CFrame.new(-2822, 5, 8444))
end

-- Comment this out if you only want the framework and no sample spawn.
task.defer(spawnExample)
