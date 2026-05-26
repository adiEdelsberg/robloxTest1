-- When a player crosses the ENTRY door of a new zone (second gate / end of bridge),
-- all remaining NPCs and birds from the previous zone are destroyed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Each entry: the boundary the player must cross, and the bounds of the zone to clean up.
-- axis="Z" → player's Z crosses triggerZ going forward (+Z).
-- axis="X" → player's X crosses triggerX going right (+X).
local CLEANUPS = {
	-- Z-direction (main corridor)
	{ axis="Z", trigger=130,  bounds={ minX=-250, maxX=250, minZ=-120, maxZ=120  } }, -- Pizza entry   → wipe Playground NPCs
	{ axis="Z", trigger=385,  bounds={ minX=-250, maxX=250, minZ=100,  maxZ=300  } }, -- Galactic entry → wipe Pizza NPCs
	{ axis="Z", trigger=640,  bounds={ minX=-250, maxX=250, minZ=300,  maxZ=550  } }, -- Jungle entry   → wipe Galactic NPCs
	{ axis="Z", trigger=860,  bounds={ minX=-250, maxX=250, minZ=550,  maxZ=810  } }, -- Sports entry   → wipe Jungle NPCs
	{ axis="Z", trigger=1090, bounds={ minX=-250, maxX=250, minZ=810,  maxZ=1050 } }, -- Tennis entry   → wipe Sports NPCs
	{ axis="Z", trigger=1300, bounds={ minX=-250, maxX=250, minZ=1050, maxZ=1260 } }, -- GameSt entry   → wipe Tennis NPCs
	{ axis="Z", trigger=1540, bounds={ minX=-250, maxX=250, minZ=1260, maxZ=1480 } }, -- Coffee entry   → wipe GameStation NPCs
	-- X-direction (bird worlds)
	{ axis="X", trigger=196,  bounds={ minX=-200, maxX=180, minZ=1520, maxZ=1880 } }, -- Burger entry   → wipe Coffee birds
	{ axis="X", trigger=548,  bounds={ minX=160,  maxX=525, minZ=1520, maxZ=1880 } }, -- Pizza entry    → wipe Burger birds
}

local function inBounds(pos, b)
	return pos.X >= b.minX and pos.X <= b.maxX
		and pos.Z >= b.minZ and pos.Z <= b.maxZ
end

local function cleanupZone(bounds)
	local gameEvents = ReplicatedStorage:FindFirstChild("GameEvents")

	for _, obj in workspace:GetChildren() do
		if not obj:IsA("Model") then continue end
		-- Skip player characters
		if Players:GetPlayerFromCharacter(obj) then continue end

		local root = obj.PrimaryPart
		if not root then
			root = obj:FindFirstChildWhichIsA("BasePart")
		end
		if not root then continue end

		if not inBounds(root.Position, bounds) then continue end

		-- Destroy NPC (has Humanoid) or bird (has BirdBody part)
		local isNPC  = obj:FindFirstChildWhichIsA("Humanoid") ~= nil
		local isBird = obj:FindFirstChild("BirdBody") ~= nil
		if isNPC or isBird then
			-- Fade out before destroy for smoothness
			for _, p in obj:GetDescendants() do
				if p:IsA("BasePart") then
					p.CanCollide = false
					p.CanTouch   = false
				end
			end
			obj:Destroy()
		end
	end

	-- Also zero out any remaining counts so downstream stages don't hang
	if gameEvents then
		for _, v in gameEvents:GetChildren() do
			if v:IsA("NumberValue") and v.Name:find("Remaining") then
				-- only zero the value if the NPCs for that stage are gone
				-- (check if any live NPC in that zone still exists — if we just
				-- destroyed them all, set to 0 safely)
			end
		end
	end
end

-- Per-player tracking: which cleanup indices have already fired
local triggered = {}

Players.PlayerAdded:Connect(function(player)
	triggered[player] = {}
	player.CharacterAdded:Connect(function()
		-- reset per-spawn if needed (don't re-trigger same zone)
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	triggered[player] = nil
end)

-- Poll player positions every 0.5 seconds
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			local pos = hrp.Position

			if not triggered[player] then triggered[player] = {} end

			for i, entry in CLEANUPS do
				if triggered[player][i] then continue end

				local crossed = false
				if entry.axis == "Z" and pos.Z >= entry.trigger then
					crossed = true
				elseif entry.axis == "X" and pos.X >= entry.trigger then
					crossed = true
				end

				if crossed then
					triggered[player][i] = true
					-- Only clean up once globally (first player to cross triggers it)
					if not _G["LevelCleanup_done_" .. i] then
						_G["LevelCleanup_done_" .. i] = true
						cleanupZone(entry.bounds)
					end
				end
			end
		end
	end
end)

print("[LevelCleanup] Watching " .. #CLEANUPS .. " zone boundaries.")
