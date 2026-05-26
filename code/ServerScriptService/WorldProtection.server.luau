-- WorldProtection.server.luau
-- 1. Disables workspace streaming so parts don't disappear by distance.
-- 2. Warns if any world folder gets unexpectedly destroyed (for debugging).

-- Disable streaming so world parts are always visible to all clients.
workspace.StreamingEnabled = false

-- List of world folders built by builder scripts.
local WORLD_FOLDERS = {
	"Playground",
	"PizzaPlace",
	"Checkpoints",
	"WorldJumpBlockers",
	"WorldReentryRespawn",
}

-- Monitor each folder; if destroyed, print a warning with the call stack.
local function watchFolder(name)
	-- Wait up to 10 seconds for the folder to be created.
	local folder = workspace:WaitForChild(name, 10)
	if not folder then
		warn("[WorldProtection] Folder never created:", name)
		return
	end

	folder.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			warn("[WorldProtection] WORLD FOLDER DESTROYED:", name,
				"\nThis should not happen. Check for a script calling :Destroy() on it.")
		end
	end)
end

for _, name in WORLD_FOLDERS do
	task.spawn(watchFolder, name)
end

print("[WorldProtection] Streaming disabled. Watching", #WORLD_FOLDERS, "world folders.")
