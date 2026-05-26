local TARGET_NAME_PATTERNS = {
	"ArchSign",
	"WorldSign",
	"EntrySign",
	"BridgeSign",
	"CourtSign",
	"MenuBoard",
	"TakeawaySign",
	"CupLogoPanel",
}

local TARGET_TEXT = {
	["GALACTIC BRIDGE"] = true,
	["GALACTIC ZONE"] = true,
	["CRYSTAL DEPTHS"] = true,
	["SPORTS WORLD"] = true,
	["HOLO SPORTS ARENA"] = true,
	["PLASMA COURTS"] = true,
	["GAME STATION"] = true,
	["CONTROLLER ARENA"] = true,
	["NEBULA BREW"] = true,
	["NEBULA\nBREW"] = true,
	["NEBULA BREW  •  COSMIC COFFEE"] = true,
	["BURGER HOUSE"] = true,
	["NEW PIZZA PLACE"] = true,
	["NEW PIZZA"] = true,
}

local function shouldRemoveGui(gui)
	local doorSigns = workspace:FindFirstChild("DoorSigns")
	if doorSigns and gui:IsDescendantOf(doorSigns) then
		return false
	end

	local parent = gui.Parent
	if parent then
		for _, pattern in TARGET_NAME_PATTERNS do
			if parent.Name:find(pattern) then
				return true
			end
		end
	end

	for _, child in gui:GetDescendants() do
		if child:IsA("TextLabel") and TARGET_TEXT[child.Text] then
			return true
		end
	end

	return false
end

local function cleanBigText()
	for _, object in workspace:GetDescendants() do
		if (object:IsA("BillboardGui") or object:IsA("SurfaceGui")) and shouldRemoveGui(object) then
			object:Destroy()
		end
	end
end

task.spawn(function()
	for _ = 1, 12 do
		cleanBigText()
		task.wait(1)
	end
end)

print("[BigLevelTextCleanup] Removed oversized level labels; fixed door signs remain.")
