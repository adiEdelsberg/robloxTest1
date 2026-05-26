-- SkyDescent.luau
-- Teleports a player's HRP to a CFrame high in the sky then descends slowly.
-- Character collision is disabled during descent so players don't snag on objects.
-- Steering is allowed, but optional bounds keep the player inside the target world.

local Players = game:GetService("Players")

local SKY_OFFSET    = 110  -- studs above target spawn
local DESCENT_SPEED = 18   -- studs per second downward
local RESTORE_TIMEOUT = 8  -- seconds before collision restores regardless
local LANDING_HEIGHT_OFFSET = 3
local DEFAULT_DESCENT_SECONDS = 1
local LANDING_TRIGGER_GRACE = 2 -- keep jumpers/finish triggers disabled briefly after landing

local function clampToBounds(hrp, bounds)
	if not bounds then return false end
	local pos = hrp.Position
	local minX = bounds.minX + 4
	local maxX = bounds.maxX - 4
	local minZ = bounds.minZ + 4
	local maxZ = bounds.maxZ - 4
	local x = math.clamp(pos.X, minX, maxX)
	local z = math.clamp(pos.Z, minZ, maxZ)
	if x == pos.X and z == pos.Z then return false end

	hrp.CFrame = CFrame.new(x, pos.Y, z) * (hrp.CFrame - pos)
	local velocity = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(
		x ~= pos.X and 0 or velocity.X,
		velocity.Y,
		z ~= pos.Z and 0 or velocity.Z
	)
	return true
end

local function setDescentBounds(player, bounds)
	if not player then return end
	if bounds then
		player:SetAttribute("SkyDescentBoundsActive", true)
		player:SetAttribute("SkyDescentMinX", bounds.minX)
		player:SetAttribute("SkyDescentMaxX", bounds.maxX)
		player:SetAttribute("SkyDescentMinZ", bounds.minZ)
		player:SetAttribute("SkyDescentMaxZ", bounds.maxZ)
	else
		player:SetAttribute("SkyDescentBoundsActive", false)
		player:SetAttribute("SkyDescentMinX", nil)
		player:SetAttribute("SkyDescentMaxX", nil)
		player:SetAttribute("SkyDescentMinZ", nil)
		player:SetAttribute("SkyDescentMaxZ", nil)
	end
end

local function skyDescent(hrp, targetCFrame, bounds, descentSeconds)
	if not hrp or not hrp.Parent then return end
	descentSeconds = descentSeconds or DEFAULT_DESCENT_SECONDS

	local character = hrp.Parent
	local humanoid  = character:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)

	local targetPos = targetCFrame.Position
	local skyPos    = Vector3.new(targetPos.X, targetPos.Y + SKY_OFFSET, targetPos.Z)

	hrp.CFrame = CFrame.fromMatrix(skyPos, targetCFrame.RightVector, targetCFrame.UpVector, targetCFrame.LookVector)
	hrp.AssemblyLinearVelocity = Vector3.zero
	setDescentBounds(player, bounds)

	-- Disable collision on all character parts so the player phases through obstacles
	local collideState = {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			collideState[part] = part.CanCollide
			part.CanCollide = false
		end
	end

	local bv = Instance.new("BodyVelocity")
	local floorY = targetPos.Y + LANDING_HEIGHT_OFFSET
	local descentSpeed = DESCENT_SPEED
	if descentSeconds and descentSeconds > 0 then
		descentSpeed = math.max(1, (skyPos.Y - floorY) / descentSeconds)
	end
	bv.Name     = "SkyDescentVelocity"
	bv.Velocity = Vector3.new(0, -descentSpeed, 0)
	bv.MaxForce = Vector3.new(0, 1e5, 0)  -- Y only: player steers freely on X/Z
	bv.Parent   = hrp

	local function restoreCollision()
		if bv.Parent then bv:Destroy() end
		hrp.AssemblyLinearVelocity = Vector3.zero
		setDescentBounds(player, nil)
		for part, wasCollidable in collideState do
			if part and part.Parent then
				part.CanCollide = wasCollidable
			end
		end
	end

	task.spawn(function()
		-- Phase 1: descend until near floor level
		while bv.Parent and hrp.Parent do
			task.wait(0.1)
			clampToBounds(hrp, bounds)
			if hrp.Position.Y <= floorY then break end
		end
		if bv.Parent then bv:Destroy() end
		if hrp.Parent then
			hrp.CFrame = targetCFrame
		end
		hrp.AssemblyLinearVelocity = Vector3.zero

		for part, wasCollidable in collideState do
			if part and part.Parent then
				part.CanCollide = wasCollidable
			end
		end

		-- Phase 2: wait until humanoid is grounded (not freefalling through geometry)
		-- so collision restores after the player has settled above any surface
		local elapsed = 0
		while elapsed < RESTORE_TIMEOUT and hrp.Parent do
			task.wait(0.1)
			elapsed += 0.1
			clampToBounds(hrp, bounds)
			if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
				break
			end
		end

		for part, wasCollidable in collideState do
			if part and part.Parent then
				part.CanCollide = wasCollidable
			end
		end

		-- Keep descent protection active after touchdown so launch pads touched on landing
		-- cannot bounce the player straight into a finish trigger.
		local graceElapsed = 0
		while graceElapsed < LANDING_TRIGGER_GRACE and hrp.Parent do
			task.wait(0.1)
			graceElapsed += 0.1
			clampToBounds(hrp, bounds)
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		setDescentBounds(player, nil)
	end)
end

return skyDescent
