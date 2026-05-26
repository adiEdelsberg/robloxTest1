-- Place in ServerStorage/FlyingBirdSystem/ServerBirdService.luau
-- Server owns spawning, bird state, flock steering, path selection, and obstacle avoidance.
-- Clients receive compact snapshots and build visuals locally for performance.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local root = script.Parent
local Config = require(root.BirdConfig)
local FlightMath = require(root.FlightMath)
local Rarity = require(root.Rarity)

local ServerBirdService = {}
ServerBirdService.__index = ServerBirdService

local DEFAULT_ZONE_NAME = "SkySpawnZone"
local DEFAULT_LANDING_NAME = "SkyLandingPoint"

function ServerBirdService.new()
	local self = setmetatable({}, ServerBirdService)
	self.rng = Random.new()
	self.birds = {}
	self.zones = {}
	self.landingPoints = {}
	self.nextId = 0
	self.spawnAccumulator = 0
	self.snapshotAccumulator = 0
	self.connections = {}
	self.raycastParams = RaycastParams.new()
	self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.raycastParams.IgnoreWater = true
	return self
end

function ServerBirdService:ensureNetwork()
	local networkFolder = ReplicatedStorage:FindFirstChild(Config.Network.folderName) or Instance.new("Folder")
	networkFolder.Name = Config.Network.folderName
	networkFolder.Parent = ReplicatedStorage

	local event = networkFolder:FindFirstChild(Config.Network.snapshotEventName) or Instance.new("RemoteEvent")
	event.Name = Config.Network.snapshotEventName
	event.Parent = networkFolder
	self.snapshotEvent = event

	local clientConfig = networkFolder:FindFirstChild("BirdConfig")
	if not clientConfig then
		clientConfig = root.BirdConfig:Clone()
		clientConfig.Parent = networkFolder
	end

	local rarity = networkFolder:FindFirstChild("Rarity")
	if not rarity then
		rarity = root.Rarity:Clone()
		rarity.Parent = networkFolder
	end
end

function ServerBirdService:createExampleSetup()
	local zoneFolder = workspace:FindFirstChild("FlyingBirdSpawnZones") or Instance.new("Folder")
	zoneFolder.Name = "FlyingBirdSpawnZones"
	zoneFolder.Parent = workspace

	if #zoneFolder:GetChildren() == 0 then
		local zone = Instance.new("Part")
		zone.Name = DEFAULT_ZONE_NAME
		zone.Size = Vector3.new(220, 4, 220)
		zone.Position = Vector3.new(0, 80, 900)
		zone.Transparency = 1
		zone.Anchored = true
		zone.CanCollide = false
		zone:SetAttribute("Radius", 180)
		zone.Parent = zoneFolder
	end

	local landingFolder = workspace:FindFirstChild("FlyingBirdLandingPoints") or Instance.new("Folder")
	landingFolder.Name = "FlyingBirdLandingPoints"
	landingFolder.Parent = workspace

	if #landingFolder:GetChildren() == 0 then
		for i = 1, 4 do
			local perch = Instance.new("Part")
			perch.Name = DEFAULT_LANDING_NAME .. i
			perch.Size = Vector3.new(5, 0.4, 5)
			perch.Position = Vector3.new(-80 + i * 40, 30 + i * 4, 880 + i * 25)
			perch.Transparency = 1
			perch.Anchored = true
			perch.CanCollide = false
			perch.Parent = landingFolder
		end
	end
end

function ServerBirdService:refreshZones()
	table.clear(self.zones)
	table.clear(self.landingPoints)

	local zoneFolder = workspace:FindFirstChild("FlyingBirdSpawnZones")
	if zoneFolder then
		for _, zone in zoneFolder:GetChildren() do
			if zone:IsA("BasePart") then
				table.insert(self.zones, {
					center = zone.Position,
					radius = zone:GetAttribute("Radius") or math.max(zone.Size.X, zone.Size.Z) * 0.5,
				})
			end
		end
	end

	local landingFolder = workspace:FindFirstChild("FlyingBirdLandingPoints")
	if landingFolder then
		for _, perch in landingFolder:GetChildren() do
			if perch:IsA("BasePart") then
				table.insert(self.landingPoints, perch.Position + Vector3.new(0, 2, 0))
			end
		end
	end
end

function ServerBirdService:spawnBird()
	if #self.zones == 0 then return end
	self.nextId += 1

	local definition = Rarity.pickWeighted(Config.Birds, self.rng)
	local zone = self.zones[self.rng:NextInteger(1, #self.zones)]
	local position = FlightMath.randomPointInZone(zone, self.rng, Config.Server.minAltitude, Config.Server.maxAltitude)
	local target = FlightMath.randomPointInZone(zone, self.rng, Config.Server.minAltitude, Config.Server.maxAltitude)
	local behaviorName, behavior = FlightMath.pickBehavior(Config.Behaviors, self.rng)

	self.birds[self.nextId] = {
		id = self.nextId,
		typeId = definition.id,
		definition = definition,
		zone = zone,
		position = position,
		target = target,
		direction = FlightMath.safeUnit(target - position),
		velocity = definition.cruiseSpeed,
		behaviorName = behaviorName,
		behavior = behavior,
		stateUntil = os.clock() + self.rng:NextNumber(2.5, 7),
		landingUntil = 0,
	}
end

function ServerBirdService:chooseTarget(bird)
	local behaviorName, behavior = FlightMath.pickBehavior(Config.Behaviors, self.rng)
	bird.behaviorName = behaviorName
	bird.behavior = behavior
	bird.stateUntil = os.clock() + self.rng:NextNumber(2.5, 7)

	if behaviorName == "Land" and #self.landingPoints > 0 and self.rng:NextNumber() < Config.Server.landingChance then
		bird.target = self.landingPoints[self.rng:NextInteger(1, #self.landingPoints)]
		bird.landingUntil = os.clock() + self.rng:NextNumber(1.4, 3)
	else
		bird.target = FlightMath.randomPointInZone(bird.zone, self.rng, Config.Server.minAltitude, Config.Server.maxAltitude)
	end
end

function ServerBirdService:flockVector(bird)
	local separation = Vector3.zero
	local alignment = Vector3.zero
	local cohesion = Vector3.zero
	local neighbors = 0

	for _, other in self.birds do
		if other ~= bird then
			local offset = other.position - bird.position
			local distance = offset.Magnitude
			if distance < 55 then
				neighbors += 1
				alignment += other.direction
				cohesion += other.position
				if distance < 22 then
					separation -= offset.Unit / math.max(distance, 1)
				end
			end
		end
	end

	if neighbors == 0 then
		return Vector3.zero
	end

	alignment = FlightMath.safeUnit(alignment / neighbors, bird.direction)
	cohesion = FlightMath.safeUnit((cohesion / neighbors) - bird.position, bird.direction)
	return separation * 3 + alignment * 0.7 + cohesion * 0.35
end

function ServerBirdService:updateBird(bird, dt)
	local now = os.clock()
	if bird.landingUntil > now and (bird.target - bird.position).Magnitude < 8 then
		bird.direction = FlightMath.steer(bird.direction, Vector3.new(0.2, 0, 1), 0.5, dt)
		return
	end

	if now >= bird.stateUntil or (bird.target - bird.position).Magnitude < 12 then
		self:chooseTarget(bird)
	end

	local desired = FlightMath.safeUnit(bird.target - bird.position, bird.direction)
	if bird.behaviorName == "Circle" then
		local around = desired:Cross(Vector3.yAxis)
		desired = FlightMath.safeUnit(desired * 0.5 + around * 0.8 + Vector3.new(0, bird.behavior.vertical, 0), desired)
	elseif bird.behaviorName == "Dive" then
		desired = FlightMath.safeUnit(desired + Vector3.new(0, bird.behavior.vertical, 0), desired)
	end

	desired += self:flockVector(bird)
	desired = FlightMath.avoidObstacles(bird.position, FlightMath.safeUnit(desired, bird.direction), self.raycastParams, Config.Server.avoidanceDistance)
	bird.direction = FlightMath.steer(bird.direction, desired, bird.behavior.turnStrength, dt)
	bird.position += bird.direction * bird.definition.cruiseSpeed * bird.behavior.speedScale * dt

	if bird.position.Y < Config.Server.minAltitude then
		bird.direction = FlightMath.safeUnit(bird.direction + Vector3.new(0, 0.8, 0), Vector3.yAxis)
	end
end

function ServerBirdService:sendSnapshot()
	local snapshot = table.create(#self.birds)
	for _, bird in self.birds do
		table.insert(snapshot, {
			id = bird.id,
			typeId = bird.typeId,
			position = bird.position,
			direction = bird.direction,
			behavior = bird.behaviorName,
		})
	end
	self.snapshotEvent:FireAllClients(snapshot)
end

function ServerBirdService:start()
	self:ensureNetwork()
	self:createExampleSetup()
	self:refreshZones()

	while #self.birds < math.min(8, Config.Server.maxBirds) do
		self:spawnBird()
	end

	table.insert(self.connections, RunService.Heartbeat:Connect(function(dt)
		self.spawnAccumulator += dt
		self.snapshotAccumulator += dt

		if self.spawnAccumulator >= Config.Server.spawnTick then
			self.spawnAccumulator = 0
			self:refreshZones()
			if #self.birds < Config.Server.maxBirds then
				self:spawnBird()
			end
		end

		for _, bird in self.birds do
			self:updateBird(bird, dt)
		end

		if self.snapshotAccumulator >= Config.Server.snapshotRate then
			self.snapshotAccumulator = 0
			self:sendSnapshot()
		end
	end))
end

function ServerBirdService:destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	table.clear(self.birds)
end

return ServerBirdService
