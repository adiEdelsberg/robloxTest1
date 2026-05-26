-- Removes obsolete gate/carpet objects from older level scripts.
-- Progression is handled by WorldRunDoors: complete the target, wait 10 seconds,
-- then launch to the next world.

local OBSOLETE_NAMES = {
	BridgeGate = true,
	BridgeGateBlocker = true,
	PizzaGate = true,
	PizzaGateBlocker = true,
	GalacticGate = true,
	GateBlocker = true,
	JumpPad = true,
	JungleGate = true,
	SportsGate = true,
	SportsGateBlocker = true,
	SportsJumpPad = true,
	TennisGate = true,
	TennisGateBlocker = true,
	TennisJumpPad = true,
	GameStationGate = true,
	GameStationGateBlocker = true,
	CoffeeGate = true,
	CoffeeGateBlocker = true,
	BurgerGate = true,
	BurgerGateBlocker = true,
	NewPizzaGate = true,
	NewPizzaGateBlocker = true,
	PoolGate = true,
	PoolGateBlocker = true,
	DinosaurGate = true,
	DinosaurGateBlocker = true,
	DinoBeachGate = true,
	DinoBeachGateBlocker = true,
	FlyingDinoForestGate = true,
	FlyingDinoForestGateBlocker = true,
	GiantDinoCherryGate = true,
	GiantDinoCherryGateBlocker = true,
	GalacticFruitGate = true,
	GalacticFruitGateBlocker = true,

	BurgerLaunchCarpet = true,
	CoffeeLaunchCarpet = true,
	DinoBeachLaunchCarpet = true,
	DinosaurLaunchCarpet = true,
	FlyingDinoForestLaunchCarpet = true,
	GalacticFruitCarpet = true,
	CherryGroveCarpet = true,
	PizzaLaunchCarpet = true,
	PoolLaunchCarpet = true,
}

local function isObsoleteGateObject(object)
	if OBSOLETE_NAMES[object.Name] then
		return true
	end
	if object:IsA("BasePart") then
		return object.Name:find("GateBlocker") ~= nil
			or object.Name:find("LaunchCarpet") ~= nil
	end
	return false
end

local function removeIfObsolete(object)
	if not isObsoleteGateObject(object) then return end
	task.defer(function()
		if object.Parent then
			object:Destroy()
		end
	end)
end

for _, object in workspace:GetDescendants() do
	removeIfObsolete(object)
end

workspace.DescendantAdded:Connect(removeIfObsolete)

print("[ObsoleteGateCleanup] Old gate and launch-carpet objects are disabled.")
