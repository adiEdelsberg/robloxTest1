local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local BOUNDS = { minX = -138, maxX = 138, minZ = 1552, maxZ = 1848 }
local BoundaryService = require(ServerStorage:WaitForChild("WorldBoundaryService"))
local GATE_X = 156
local GATE_Z = 1700
local NEEDED = Balance.StageTargets.CoffeeShop
local CASH_SMALL = Balance.CatchRewards.BirdSmall
local CASH_NORMAL = Balance.CatchRewards.BirdNormal
local CASH_GIANT = Balance.CatchRewards.BirdGiant

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")
local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local coffeeRemaining = Instance.new("NumberValue")
coffeeRemaining.Name = "CoffeeBaristasRemaining"
coffeeRemaining.Parent = gameEvents

local coffeeTotal = Instance.new("NumberValue")
coffeeTotal.Name = "CoffeeBaristasTotal"
coffeeTotal.Parent = gameEvents

local catchesThisArea = 0
local gateOpen = false
local activeBirds = {}

-- Chair near the exit door to Burger House (door at x=156, z=1700)
do
	local cx, cy, cz = 147, 1, 1688  -- beside the door, slightly inward
	local chairColor = "Reddish brown"
	local legColor = "Dark orange"

	local function chairPart(name, size, pos)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Anchored = true
		p.CanCollide = true
		p.CastShadow = false
		p.BrickColor = BrickColor.new(chairColor)
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = workspace
		return p
	end
	local function legPart(name, pos)
		local p = chairPart(name, Vector3.new(0.28, 1.6, 0.28), pos)
		p.BrickColor = BrickColor.new(legColor)
		return p
	end

	-- Seat
	chairPart("ChairSeat", Vector3.new(2.4, 0.28, 2.4), Vector3.new(cx, cy + 1.8, cz))
	-- Backrest
	chairPart("ChairBack", Vector3.new(2.4, 1.6, 0.22), Vector3.new(cx, cy + 2.9, cz + 1.1))
	-- Back support pillar
	local bs = chairPart("ChairBackSupport", Vector3.new(0.22, 0.6, 0.22), Vector3.new(cx, cy + 2.06, cz + 1.1))
	bs.BrickColor = BrickColor.new(legColor)
	-- 4 legs
	legPart("ChairLegFL", Vector3.new(cx - 0.9, cy + 0.8, cz - 0.9))
	legPart("ChairLegFR", Vector3.new(cx + 0.9, cy + 0.8, cz - 0.9))
	legPart("ChairLegBL", Vector3.new(cx - 0.9, cy + 0.8, cz + 0.9))
	legPart("ChairLegBR", Vector3.new(cx + 0.9, cy + 0.8, cz + 0.9))
	-- Small cushion on seat
	local cushion = chairPart("ChairCushion", Vector3.new(2.1, 0.2, 2.1), Vector3.new(cx, cy + 1.99, cz))
	cushion.BrickColor = BrickColor.new("Bright orange")
	cushion.Material = Enum.Material.Fabric
end

local BIRDS = {
	{ name = "Latte Bird", body = "Bright orange", wing = "Institutional white" },
	{ name = "Espresso Bird", body = "Really black", wing = "Bright orange" },
	{ name = "Mocha Bird", body = "Reddish brown", wing = "Bright yellow" },
	{ name = "Cappuccino Bird", body = "Institutional white", wing = "Cyan" },
	{ name = "Bean Bird", body = "Brown", wing = "Bright orange" },
	{ name = "Steam Bird", body = "Cyan", wing = "Institutional white" },
	{ name = "Cosmic Bird", body = "Hot pink", wing = "Royal purple" },
	{ name = "Cold Brew Bird", body = "Bright blue", wing = "Cyan" },
	{ name = "Frappe Bird", body = "Pastel Blue", wing = "Institutional white" },
	{ name = "Caramel Bird", body = "Gold", wing = "Bright orange" },
	{ name = "Roast Bird", body = "Dark stone grey", wing = "Reddish brown" },
	{ name = "Sugar Bird", body = "Hot pink", wing = "Institutional white" },
	{ name = "Cupcake Bird", body = "Light orange", wing = "Bright yellow" },
	{ name = "Nebula Bird", body = "Royal purple", wing = "Cyan" },
	{ name = "Giant Latte Bird", body = "Bright orange", wing = "Institutional white", scale = 1.65 },
	{ name = "Giant Espresso Bird", body = "Really black", wing = "Bright orange", scale = 1.65 },
	{ name = "Giant Mocha Bird", body = "Reddish brown", wing = "Bright yellow", scale = 1.65 },
	{ name = "Giant Steam Bird", body = "Cyan", wing = "Institutional white", scale = 1.65 },
	{ name = "Giant Nebula Bird", body = "Royal purple", wing = "Cyan", scale = 1.65 },
	{ name = "Tiny Latte Bird", body = "Bright orange", wing = "Institutional white", scale = 0.39 },
	{ name = "Tiny Bean Bird", body = "Brown", wing = "Bright orange", scale = 0.39 },
	{ name = "Tiny Sugar Bird", body = "Hot pink", wing = "Institutional white", scale = 0.39 },
	{ name = "Tiny Steam Bird", body = "Cyan", wing = "Institutional white", scale = 0.39 },
	{ name = "Tiny Cupcake Bird", body = "Light orange", wing = "Bright yellow", scale = 0.39 },
}

coffeeTotal.Value = #BIRDS
coffeeRemaining.Value = #BIRDS

local function part(parent, name, size, color, cf, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.BrickColor = BrickColor.new(color)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.CFrame = cf
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

local function scaled(base, scale)
	return Vector3.new(base.X * scale, base.Y * scale, base.Z * scale)
end

local function addHeadStyle(model, data, cf, scale, index)
	local style = ((index - 1) % 5) + 1
	local headSize = Vector3.new(2.7, 2.7, 2.7)
	if style == 2 then
		headSize = Vector3.new(2.95, 2.35, 2.75)
	elseif style == 5 then
		headSize = Vector3.new(2.25, 2.25, 2.25)
	end

	part(model, "BirdHead", scaled(headSize, scale), data.body, cf * CFrame.new(0, 1.45 * scale, -3.1 * scale), Enum.Material.Neon, Enum.PartType.Ball)

	local eyeColor = style == 4 and "Cyan" or "Really black"
	local eyeSize = style == 5 and Vector3.new(0.34, 0.34, 0.18) or Vector3.new(0.5, 0.5, 0.22)
	part(model, "LeftEye", scaled(eyeSize, scale), eyeColor, cf * CFrame.new(-0.68 * scale, 1.9 * scale, -4.2 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "RightEye", scaled(eyeSize, scale), eyeColor, cf * CFrame.new(0.68 * scale, 1.9 * scale, -4.2 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "LeftEyeShine", scaled(Vector3.new(0.14, 0.14, 0.08), scale), "Institutional white", cf * CFrame.new(-0.79 * scale, 2.02 * scale, -4.35 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "RightEyeShine", scaled(Vector3.new(0.14, 0.14, 0.08), scale), "Institutional white", cf * CFrame.new(0.79 * scale, 2.02 * scale, -4.35 * scale), Enum.Material.Neon, Enum.PartType.Ball)

	local beakColor = style == 4 and data.wing or "Bright yellow"
	local beakSize = style == 2 and Vector3.new(0.95, 0.55, 2.6) or style == 5 and Vector3.new(0.72, 0.42, 1.3) or Vector3.new(1.05, 0.62, 1.85)
	part(model, "Beak", scaled(beakSize, scale), beakColor, cf * CFrame.new(0, 1.22 * scale, -4.6 * scale), Enum.Material.Neon)

	if style == 1 then
		part(model, "LeftCheek", scaled(Vector3.new(0.45, 0.32, 0.16), scale), data.wing, cf * CFrame.new(-0.95 * scale, 1.42 * scale, -4.12 * scale), Enum.Material.Neon, Enum.PartType.Ball)
		part(model, "RightCheek", scaled(Vector3.new(0.45, 0.32, 0.16), scale), data.wing, cf * CFrame.new(0.95 * scale, 1.42 * scale, -4.12 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	elseif style == 2 then
		part(model, "LeftBrow", scaled(Vector3.new(0.75, 0.18, 0.18), scale), data.wing, cf * CFrame.new(-0.62 * scale, 2.25 * scale, -4.15 * scale) * CFrame.Angles(0, 0, math.rad(-14)), Enum.Material.Neon)
		part(model, "RightBrow", scaled(Vector3.new(0.75, 0.18, 0.18), scale), data.wing, cf * CFrame.new(0.62 * scale, 2.25 * scale, -4.15 * scale) * CFrame.Angles(0, 0, math.rad(14)), Enum.Material.Neon)
		part(model, "ThroatPatch", scaled(Vector3.new(1.25, 0.7, 0.16), scale), "Institutional white", cf * CFrame.new(0, 0.75 * scale, -4.02 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	elseif style == 3 then
		for crest = -1, 1 do
			part(model, "CrestFeather" .. tostring(crest + 2), scaled(Vector3.new(0.42, 1.1, 0.28), scale), data.wing, cf * CFrame.new(0.34 * crest * scale, 2.9 * scale, -3.25 * scale) * CFrame.Angles(math.rad(crest * 10), 0, math.rad(crest * 18)), Enum.Material.Neon)
		end
	elseif style == 4 then
		part(model, "GlowHalo", scaled(Vector3.new(0.18, 3.2, 3.2), scale), data.wing, cf * CFrame.new(0, 3.08 * scale, -3.05 * scale) * CFrame.Angles(math.rad(90), 0, 0), Enum.Material.Neon, Enum.PartType.Cylinder)
		part(model, "ChestGem", scaled(Vector3.new(0.75, 0.75, 0.2), scale), "Cyan", cf * CFrame.new(0, 0.7 * scale, -3.95 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	elseif style == 5 then
		part(model, "FaceMask", scaled(Vector3.new(1.85, 0.55, 0.16), scale), data.wing, cf * CFrame.new(0, 1.83 * scale, -4.1 * scale), Enum.Material.Neon)
		part(model, "TinyCrown", scaled(Vector3.new(1.05, 0.35, 0.45), scale), "Bright yellow", cf * CFrame.new(0, 2.68 * scale, -3.25 * scale), Enum.Material.Neon)
	end
end

local function cashForBird(data)
	local scale = data.scale or 1
	if scale >= 1.5 then return CASH_GIANT end
	if scale <= 0.5 then return CASH_SMALL end
	return CASH_NORMAL
end

local function showCatchReward(player, model)
	if not player then return end
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	local amount = model:GetAttribute("CashReward") or CASH_NORMAL
	if cash then
		cash.Value += amount
	end

	local pivot = model:GetPivot()
	local effectPart = Instance.new("Part")
	effectPart.Name = "BirdCashEffect"
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.CFrame = pivot
	effectPart.Anchored = true
	effectPart.CanCollide = false
	effectPart.CanTouch = false
	effectPart.Transparency = 1
	effectPart.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12221967"
	sound.Volume = 0.85
	sound.PlaybackSpeed = 1.15
	sound.Parent = effectPart
	sound:Play()

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 70), Color3.fromRGB(80, 255, 150))
	particles.Lifetime = NumberRange.new(0.45, 0.75)
	particles.Speed = NumberRange.new(8, 14)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rate = 0
	particles.Parent = effectPart
	particles:Emit(26)

	local popup = Instance.new("BillboardGui")
	popup.Size = UDim2.new(0, 120, 0, 40)
	popup.StudsOffset = Vector3.new(0, 3, 0)
	popup.AlwaysOnTop = true
	popup.Parent = effectPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. amount
	label.TextColor3 = Color3.fromRGB(255, 230, 70)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = popup

	TweenService:Create(popup, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 6, 0) }):Play()
	task.delay(0.35, function()
		if label.Parent then
			TweenService:Create(label, TweenInfo.new(0.45), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
	task.delay(1.1, function()
		if effectPart.Parent then effectPart:Destroy() end
	end)
end

local function spawnGateCarpet()
	-- Carpet sits ON the connector bridge (top surface ~y=1.45), just past the gate at x=156
	local carpet = Instance.new("Part")
	carpet.Name = "CoffeeLaunchCarpet"
	carpet.Size = Vector3.new(18, 0.5, 18)
	carpet.Position = Vector3.new(GATE_X + 12, 1.7, GATE_Z)
	carpet.Anchored = true
	carpet.CanCollide = false
	carpet.BrickColor = BrickColor.new("Bright orange")
	carpet.Material = Enum.Material.Neon
	carpet.Transparency = 0.2
	carpet.Parent = workspace

	local glow = Instance.new("Part")
	glow.Size = Vector3.new(14, 0.2, 14)
	glow.Position = Vector3.new(GATE_X + 12, 1.96, GATE_Z)
	glow.Anchored = true
	glow.CanCollide = false
	glow.BrickColor = BrickColor.new("New Yeller")
	glow.Material = Enum.Material.Neon
	glow.Transparency = 0.5
	glow.Parent = workspace

	local launched = {}
	task.spawn(function()
		while carpet.Parent do
			task.wait(0.1)
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if not hrp then continue end
				local pos = hrp.Position
				-- Trigger when player crosses past the gate into the connector
				if pos.X > GATE_X and pos.X < GATE_X + 30
					and math.abs(pos.Z - GATE_Z) < 22 and pos.Y < 16 then
					local now = os.clock()
					if not launched[player] or now - launched[player] >= 3 then
						launched[player] = now
						hrp.AssemblyLinearVelocity = Vector3.new(90, 28, 0)
					end
				end
			end
		end
	end)
end

local function openGate()
	if gateOpen then return end
	gateOpen = true
	coffeeRemaining.Value = 0
	do local _ne = gameEvents:FindFirstChild("GateOpenNotify"); if _ne then _ne:FireAllClients("Nebula Brew") end end
	stageHits.Value = NEEDED
	spawnGateCarpet()
end

local function getCatchingPlayer(hit)
	local character = hit.Parent
	return character and Players:GetPlayerFromCharacter(character)
end

local function catchBird(model, player)
	if not activeBirds[model] then return end
	if gateOpen then return end
	activeBirds[model] = nil
	catchesThisArea += 1
	coffeeRemaining.Value = math.max(0, coffeeRemaining.Value - 1)
	if not gateOpen then stageHits.Value = catchesThisArea end
	showCatchReward(player, model)
	if player and playerScored then playerScored:Fire(player, "Coffee Shop") end

	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanTouch = false
			TweenService:Create(object, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		end
	end

	task.delay(0.28, function()
		if model.Parent then model:Destroy() end
	end)

	if not gateOpen and (catchesThisArea >= NEEDED or coffeeRemaining.Value <= 0) then
		openGate()
	end
end

local function spawnBird(data, index)
	local model = Instance.new("Model")
	model.Name = data.name
	model.Parent = workspace
	model:SetAttribute("CashReward", cashForBird(data))

	local x = math.random(BOUNDS.minX, BOUNDS.maxX)
	local z = math.random(BOUNDS.minZ, BOUNDS.maxZ)
	local scale = data.scale or 1
	local tiers = {12, 14, 16, 38, 42, 46, 75, 85, 95, 100}
	local y = tiers[((index - 1) % #tiers) + 1] + math.max(0, scale - 1) * 4
	local cf = CFrame.new(x, y, z)

	local body = part(model, "BirdBody", scaled(Vector3.new(7.2, 4, 5.2), scale), data.body, cf, Enum.Material.Neon, Enum.PartType.Ball)
	body.CanTouch = true
	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BrickColor.new(data.wing).Color), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) })
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Lifetime = NumberRange.new(0.6, 1.2)
	sparks.Rate = 12 * scale
	sparks.Speed = NumberRange.new(2 * scale, 5 * scale)
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 * scale), NumberSequenceKeypoint.new(1, 0) })
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.RotSpeed = NumberRange.new(-180, 180)
	sparks.Parent = body
	addHeadStyle(model, data, cf, scale, index)
	part(model, "LeftWing", scaled(Vector3.new(0.55, 0.26, 6.6), scale), data.wing, cf * CFrame.new(-4.1 * scale, 0, 0), Enum.Material.Neon)
	part(model, "RightWing", scaled(Vector3.new(0.55, 0.26, 6.6), scale), data.wing, cf * CFrame.new(4.1 * scale, 0, 0), Enum.Material.Neon)
	local catchHitbox = part(model, "BirdCatchHitbox", scaled(Vector3.new(9, 6.5, 8), scale), data.body, cf, Enum.Material.ForceField)
	catchHitbox.Transparency = 1
	catchHitbox.CanTouch = true

	model.PrimaryPart = body
	activeBirds[model] = true
	BoundaryService.bindModel(model, BOUNDS, { margin = 7, minY = 8, maxY = 112 })

	local prompt = Instance.new("BillboardGui")
	prompt.Size = UDim2.new(0, 120, 0, 34)
	prompt.StudsOffset = Vector3.new(0, math.max(2.8, 5.6 * scale), 0)
	prompt.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "CATCH"
	label.TextColor3 = Color3.fromRGB(255, 240, 130)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = prompt

	body.Touched:Connect(function(hit)
		local catchingPlayer = getCatchingPlayer(hit)
		if catchingPlayer then
			catchBird(model, catchingPlayer)
		end
	end)
	catchHitbox.Touched:Connect(function(hit)
		local catchingPlayer = getCatchingPlayer(hit)
		if catchingPlayer then
			catchBird(model, catchingPlayer)
		end
	end)

	task.spawn(function()
		while activeBirds[model] and model.Parent do
			local startPivot = model:GetPivot()
			local targetPivot = CFrame.new(
				math.random(BOUNDS.minX, BOUNDS.maxX),
				9 + math.random() * 10,
				math.random(BOUNDS.minZ, BOUNDS.maxZ)
			)
			local value = Instance.new("CFrameValue")
			value.Value = startPivot
			local conn = value.Changed:Connect(function(cf2)
				if model.Parent then model:PivotTo(cf2) end
			end)
			local tweenDuration
				if scale <= 0.5 then tweenDuration = math.random(18, 28) / 10
				elseif scale >= 1.5 then tweenDuration = math.random(80, 120) / 10
				else tweenDuration = math.random(38, 56) / 10 end
				local tween = TweenService:Create(value, TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = targetPivot })
			tween:Play()
			tween.Completed:Wait()
			conn:Disconnect()
			value:Destroy()
			task.wait(0.1)
		end
	end)
end

local function spawnCoffeeBirds()
	stageNeeded.Value = NEEDED
	stageHits.Value = 0
	math.randomseed(tick() + 7821)
	for index, bird in BIRDS do
		spawnBird(bird, index)
	end
	task.spawn(function()
		while not gateOpen do
			task.wait(0.06)
			for model in activeBirds do
				if not model.Parent then continue end
				local body = model:FindFirstChild("BirdBody")
				if not body then continue end
				local birdPos = body.Position
				for _, player in Players:GetPlayers() do
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - birdPos).Magnitude < 9 then
						catchBird(model, player)
					end
				end
			end
		end
	end)
end

task.spawn(spawnCoffeeBirds)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Coffee Shop" then return end
		for model in activeBirds do
			activeBirds[model] = nil
			if model.Parent then model:Destroy() end
		end
		catchesThisArea = 0
		gateOpen = false
		coffeeRemaining.Value = #BIRDS
		spawnCoffeeBirds()
	end)
end)
