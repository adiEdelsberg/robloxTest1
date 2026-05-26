-- Place in ServerStorage/FlyingBirdSystem/FlightMath.luau
-- Pure movement helpers used by the server simulation.

local FlightMath = {}

function FlightMath.safeUnit(vector, fallback)
	if vector.Magnitude > 0.001 then
		return vector.Unit
	end
	return fallback or Vector3.new(0, 0, -1)
end

function FlightMath.steer(currentDirection, desiredDirection, strength, dt)
	local alpha = math.clamp((strength or 1) * dt, 0, 1)
	return FlightMath.safeUnit(currentDirection:Lerp(FlightMath.safeUnit(desiredDirection, currentDirection), alpha), currentDirection)
end

function FlightMath.randomPointInZone(zone, rng, minAltitude, maxAltitude)
	local radius = zone.radius or 140
	local angle = rng:NextNumber(0, math.pi * 2)
	local distance = math.sqrt(rng:NextNumber()) * radius
	local center = zone.center
	return Vector3.new(
		center.X + math.cos(angle) * distance,
		center.Y + rng:NextNumber(minAltitude, maxAltitude),
		center.Z + math.sin(angle) * distance
	)
end

function FlightMath.pickBehavior(behaviors, rng)
	local total = 0
	for _, behavior in behaviors do
		total += behavior.weight or 1
	end
	local roll = rng:NextNumber(0, total)
	local running = 0
	for name, behavior in behaviors do
		running += behavior.weight or 1
		if roll <= running then
			return name, behavior
		end
	end
	return "Glide", behaviors.Glide
end

function FlightMath.avoidObstacles(position, direction, raycastParams, distance)
	local result = workspace:Raycast(position, direction * distance, raycastParams)
	if not result then
		return direction
	end

	local normal = result.Normal
	local reflected = direction - 2 * direction:Dot(normal) * normal
	return FlightMath.safeUnit(reflected + Vector3.new(0, 0.65, 0), Vector3.new(0, 1, 0))
end

return FlightMath
