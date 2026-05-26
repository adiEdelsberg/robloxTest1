-- Jump-pad balls for the bird-catching worlds.
-- Each ball sits half-buried in the ground. Stepping on it launches you sky-high.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LAUNCH_POWER  = 195   -- studs/sec upward (reaches ~96 studs before gravity)
local LATERAL_KEEP  = 0.25  -- fraction of lateral velocity to preserve
local COOLDOWN      = 1.0   -- seconds before same player can bounce again
local BALL_RADIUS   = 6     -- studs

-- Center is at BALL_RADIUS/2 above ground so the ball is half buried
local BASE_Y = BALL_RADIUS * 0.5   -- = 3  (top of ball at y=9)

local cooldowns = {}

local folder = Instance.new("Folder")
folder.Name   = "BirdJumpBalls"
folder.Parent = workspace

local COFFEE_COLORS = { "Bright orange", "Cyan", "Institutional white", "Hot pink", "Bright yellow" }
local BURGER_COLORS = { "Bright red", "Bright yellow", "Bright orange", "Lime green", "Cyan" }
local PIZZA_COLORS  = { "Hot pink", "Bright red", "Cyan", "Bright orange", "Royal purple" }
local POOL_COLORS   = { "Cyan", "Bright blue", "Institutional white", "Hot pink", "Bright yellow" }

local COFFEE_BALLS = {
	{ -100, 1600, 1 }, {  100, 1600, 2 }, { -60, 1700, 3 }, {  60, 1700, 4 },
	{ -120, 1800, 5 }, {  120, 1800, 1 }, {   0, 1650, 2 }, { -40, 1760, 3 },
	{   40, 1760, 4 }, {   0, 1560, 5 },
	{ -130, 1660, 1 }, { 130, 1660, 2 }, { -88, 1850, 3 }, { 88, 1850, 4 },
	{ -18, 1728, 5 }, { 18, 1728, 1 },
}
local BURGER_BALLS = {
	{ 240, 1600, 1 }, { 460, 1600, 2 }, { 280, 1700, 3 }, { 420, 1700, 4 },
	{ 240, 1800, 5 }, { 460, 1800, 1 }, { 350, 1650, 2 }, { 300, 1760, 3 },
	{ 400, 1760, 4 }, { 350, 1560, 5 },
	{ 222, 1660, 1 }, { 478, 1660, 2 }, { 262, 1850, 3 }, { 438, 1850, 4 },
	{ 332, 1728, 5 }, { 368, 1728, 1 },
}
local PIZZA_BALLS = {
	{ 590, 1600, 1 }, { 820, 1600, 2 }, { 630, 1700, 3 }, { 780, 1700, 4 },
	{ 590, 1800, 5 }, { 820, 1800, 1 }, { 704, 1650, 2 }, { 660, 1760, 3 },
	{ 748, 1760, 4 }, { 704, 1560, 5 },
	{ 572, 1660, 1 }, { 838, 1660, 2 }, { 612, 1850, 3 }, { 796, 1850, 4 },
	{ 686, 1728, 5 }, { 722, 1728, 1 },
}
local POOL_BALLS = {
	{ 942, 1600, 1 }, { 1170, 1600, 2 }, { 980, 1700, 3 }, { 1130, 1700, 4 },
	{ 942, 1800, 5 }, { 1170, 1800, 1 }, { 1056, 1650, 2 }, { 1012, 1760, 3 },
	{ 1100, 1760, 4 }, { 1056, 1560, 5 },
	{ 924, 1660, 1 }, { 1188, 1660, 2 }, { 962, 1850, 3 }, { 1148, 1850, 4 },
	{ 1038, 1728, 5 }, { 1074, 1728, 1 },
}

local function makeBall(x, z, colorName, innerColor)
	-- Main ball: center at BASE_Y so the top hemisphere sticks out of the ground
	local ball = Instance.new("Part")
	ball.Name        = "JumpBall"
	ball.Shape       = Enum.PartType.Ball
	ball.Size        = Vector3.new(BALL_RADIUS*2, BALL_RADIUS*2, BALL_RADIUS*2)
	ball.Position    = Vector3.new(x, BASE_Y, z)
	ball.BrickColor  = BrickColor.new(colorName)
	ball.Material    = Enum.Material.Neon
	ball.Transparency = 0.10
	ball.Anchored    = true
	ball.CanCollide  = true
	ball.CastShadow  = false
	ball.Parent      = folder

	-- Outer glow shell (purely visual, no collision)
	local glow = Instance.new("Part")
	glow.Name        = "JumpBallGlow"
	glow.Shape       = Enum.PartType.Ball
	glow.Size        = Vector3.new(BALL_RADIUS*2+2, BALL_RADIUS*2+2, BALL_RADIUS*2+2)
	glow.Position    = Vector3.new(x, BASE_Y, z)
	glow.BrickColor  = BrickColor.new(colorName)
	glow.Material    = Enum.Material.Neon
	glow.Transparency = 0.58
	glow.Anchored    = true
	glow.CanCollide  = false
	glow.CastShadow  = false
	glow.Parent      = folder

	-- Inner bright core
	local core = Instance.new("Part")
	core.Name        = "JumpBallCore"
	core.Shape       = Enum.PartType.Ball
	core.Size        = Vector3.new(BALL_RADIUS, BALL_RADIUS, BALL_RADIUS)
	core.Position    = Vector3.new(x, BASE_Y, z)
	core.BrickColor  = BrickColor.new(innerColor or "Institutional white")
	core.Material    = Enum.Material.Neon
	core.Transparency = 0.22
	core.Anchored    = true
	core.CanCollide  = false
	core.CastShadow  = false
	core.Parent      = folder

	-- Flat ring on the ground around the ball
	local ring = Instance.new("Part")
	ring.Name        = "JumpBallRing"
	ring.Shape       = Enum.PartType.Cylinder
	ring.Size        = Vector3.new(0.3, BALL_RADIUS*2+5, BALL_RADIUS*2+5)
	ring.CFrame      = CFrame.new(x, 0.15, z) * CFrame.Angles(0, 0, math.rad(90))
	ring.BrickColor  = BrickColor.new(colorName)
	ring.Material    = Enum.Material.Neon
	ring.Transparency = 0.55
	ring.Anchored    = true
	ring.CanCollide  = false
	ring.CastShadow  = false
	ring.Parent      = folder

	-- Squish animation on launch
	local function squishAnim()
		task.spawn(function()
			local squish = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(ball, squish, {
				Size = Vector3.new(BALL_RADIUS*2.5, BALL_RADIUS*1.2, BALL_RADIUS*2.5)
			}):Play()
			task.wait(0.11)
			local pop = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(ball, pop, {
				Size = Vector3.new(BALL_RADIUS*2, BALL_RADIUS*2, BALL_RADIUS*2)
			}):Play()
		end)
	end

	-- Touch handler: player steps on top → launch upward
	ball.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Only launch when player is on top of the ball (above center)
		if hrp.Position.Y < BASE_Y then return end

		if cooldowns[player] then return end
		cooldowns[player] = true
		task.delay(COOLDOWN, function() cooldowns[player] = nil end)

		squishAnim()

		local vel = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(
			vel.X * LATERAL_KEEP,
			LAUNCH_POWER,
			vel.Z * LATERAL_KEEP
		)
	end)
end

local function spawnWorldBalls(ballDefs, colorPalette)
	for _, def in ballDefs do
		local colorName  = colorPalette[def[3]]
		local innerNames = { "Institutional white", "Bright yellow", "Cyan", "Hot pink", "Bright orange" }
		local innerName  = innerNames[((def[3]) % #innerNames) + 1]
		makeBall(def[1], def[2], colorName, innerName)
	end
end

spawnWorldBalls(COFFEE_BALLS, COFFEE_COLORS)
spawnWorldBalls(BURGER_BALLS, BURGER_COLORS)
spawnWorldBalls(PIZZA_BALLS,  PIZZA_COLORS)
spawnWorldBalls(POOL_BALLS,   POOL_COLORS)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
end)

print("[BirdWorldJumpBalls] Spawned " .. (#COFFEE_BALLS + #BURGER_BALLS + #PIZZA_BALLS + #POOL_BALLS) .. " ground jump pads across bird worlds.")
