-- Makes decorative door, bridge, rail, fence, and pole hardware non-blocking.
-- World containment stays owned by WorldBarriers / WorldGlassCubes.

local NON_BLOCKING_PATTERNS = {
	"Arch",
	"BridgeFence",
	"BridgePost",
	"BridgeRail",
	"Curb",
	"DoorGlow",
	"DoorSign",
	"EntrySign",
	"ExitSign",
	"Fence",
	"Post",
	"Rail",
	"Sign",
	"Threshold",
	"TopBeam",
	"TwoSideSign",
}

local KEEP_BLOCKING_PATTERNS = {
	"Barrier",
	"Contain",
	"Floor",
	"GateBlocker",
	"Wall",
}

local function nameHasAny(name, patterns)
	for _, pattern in patterns do
		if name:find(pattern) then
			return true
		end
	end
	return false
end

local function shouldDisableCollision(part)
	if not part:IsA("BasePart") then return false end
	local name = part.Name
	if nameHasAny(name, KEEP_BLOCKING_PATTERNS) then return false end
	return nameHasAny(name, NON_BLOCKING_PATTERNS)
end

local function disableIfDecor(part)
	if not shouldDisableCollision(part) then return end
	part.CanCollide = false
	part.CanTouch = false
end

for _, object in workspace:GetDescendants() do
	disableIfDecor(object)
end

workspace.DescendantAdded:Connect(function(object)
	task.defer(disableIfDecor, object)
end)

print("[NonBlockingPathDecor] Decorative path hardware collision disabled.")
