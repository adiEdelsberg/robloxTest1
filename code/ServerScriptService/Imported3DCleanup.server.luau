-- Imported3DCleanup.server.luau
-- Keep only selected imported 3Ds visible while removing old imported test copies.

local KEEP_EXACT = {
	goblin1 = true,
	World43Imported_goblin2 = true,
}

local REMOVE_EXACT = {
	goblin2 = true,
	goblin3 = true,
	goblin4 = true,
	giblin4 = true,
	World47_goblin1 = true,
	hero = true,
	goblin_extra = true,
	hero_extra = true,
	hero_extra2 = true,
	hero_extra3 = true,
	hero_extra4 = true,
	hero_extra5 = true,
	hero_extra6 = true,
	Room46_goblin3 = true,
	Room46_hero = true,
	World47_goblin2 = true,
	World47_goblin3 = true,
	World47_hero = true,
	World47_goblin_extra = true,
	World47_hero_extra = true,
	World43Imported_goblin1 = true,
	Level42Imported_Sketchfab_Scene = true,
	Sketchfab_Scene = true,
	sketchfab_scene = true,
	Sketchfab_model = true,
	sketchfab_model = true,
}

local REMOVE_PREFIXES = {
	"World47_goblin2",
	"World47_goblin3",
	"World47_hero",
	"World47_goblin_extra",
	"World47_hero_extra",
	"World43Imported_goblin1",
	"Level42Imported_",
	"Room46_goblin3",
	"Room46_hero",
}

local function isInsideKeptModel(object)
	local current = object
	while current and current ~= workspace do
		if KEEP_EXACT[current.Name] then
			return true
		end
		current = current.Parent
	end
	return false
end

local function shouldRemove(object)
	if isInsideKeptModel(object) then
		return false
	end
	if REMOVE_EXACT[object.Name] then
		return true
	end
	for _, prefix in ipairs(REMOVE_PREFIXES) do
		if object.Name:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

local function cleanup()
	for _, object in ipairs(workspace:GetDescendants()) do
		if shouldRemove(object) then
			local model = object:IsA("Model") and object or object:FindFirstAncestorWhichIsA("Model")
			if model and not KEEP_EXACT[model.Name] then
				model:Destroy()
			else
				object:Destroy()
			end
		end
	end
end

cleanup()
for _, delaySeconds in ipairs({ 2, 5, 10, 20, 40, 60 }) do
	task.delay(delaySeconds, cleanup)
end
