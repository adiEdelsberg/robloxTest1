local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local BOUNDS = { minX = 1974, maxX = 2250, minZ = 1552, maxZ = 1848 }
local BoundaryService = require(ServerStorage:WaitForChild("WorldBoundaryService"))
local GATE_X = 2268
local GATE_Z = 1700
local NEEDED = Balance.StageTargets.FlyingDinoForest
local CASH_SMALL = Balance.CatchRewards.FlyingDinoForestSmall
local CASH_NORMAL = Balance.CatchRewards.FlyingDinoForest
local CASH_GIANT = Balance.CatchRewards.FlyingDinoForestGiant

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")
local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local forestRemaining = Instance.new("NumberValue")
forestRemaining.Name = "FlyingDinoForestDinosRemaining"
forestRemaining.Parent = gameEvents

local forestTotal = Instance.new("NumberValue")
forestTotal.Name = "FlyingDinoForestDinosTotal"
forestTotal.Parent = gameEvents

local catchesThisArea = 0
local gateOpen = false
local activeDinos = {}

local DINOS = {
	{ name = "Forest Ptero", body = "Bright green", wing = "Lime green" },
	{ name = "Canopy Glider", body = "Earth green", wing = "Bright yellow" },
	{ name = "Night Wing", body = "Really black", wing = "Royal purple" },
	{ name = "Amber Flyer", body = "Bright orange", wing = "Bright yellow" },
	{ name = "Moss Wing", body = "Reddish brown", wing = "Bright green" },
	{ name = "Glow Crest", body = "Cyan", wing = "Royal purple" },
	{ name = "Vine Screecher", body = "Lime green", wing = "Cyan" },
	{ name = "Tiny Forest Ptero", body = "Bright green", wing = "Bright yellow", scale = 0.55 },
	{ name = "Tiny Night Wing", body = "Really black", wing = "Cyan", scale = 0.55 },
	{ name = "Tiny Amber Flyer", body = "Bright orange", wing = "Institutional white", scale = 0.55 },
	{ name = "Giant Canopy King", body = "Earth green", wing = "Bright orange", scale = 1.65 },
	{ name = "Giant Moon Ptero", body = "Royal purple", wing = "Cyan", scale = 1.65 },
	{ name = "Giant Ancient Flyer", body = "Dark stone grey", wing = "Bright green", scale = 1.65 },
}

forestTotal.Value = #DINOS
forestRemaining.Value = #DINOS

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

local function cashForDino(data)
	local scale = data.scale or 1
	if scale >= 1.5 then return CASH_GIANT end
	if scale <= 0.6 then return CASH_SMALL end
	return CASH_NORMAL
end

local function showCatchReward(player, model)
	if not player then return end
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	local amount = model:GetAttribute("CashReward") or CASH_NORMAL
	if cash then cash.Value += amount end

	local effectPart = Instance.new("Part")
	effectPart.Name = "FlyingDinoCashEffect"
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.CFrame = model:GetPivot()
	effectPart.Anchored = true
	effectPart.CanCollide = false
	effectPart.CanTouch = false
	effectPart.Transparency = 1
	effectPart.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12221967"
	sound.Volume = 0.95
	sound.PlaybackSpeed = 1.05
	sound.Parent = effectPart
	sound:Play()

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 255, 110), Color3.fromRGB(170, 100, 255))
	particles.Lifetime = NumberRange.new(0.45, 0.85)
	particles.Speed = NumberRange.new(7, 15)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rate = 0
	particles.Parent = effectPart
	particles:Emit(36)

	local popup = Instance.new("BillboardGui")
	popup.Size = UDim2.new(0, 140, 0, 44)
	popup.StudsOffset = Vector3.new(0, 3, 0)
	popup.Parent = effectPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. amount
	label.TextColor3 = Color3.fromRGB(120, 255, 110)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = popup
	TweenService:Create(popup, TweenInfo.new(0.9), { StudsOffset = Vector3.new(0, 6, 0) }):Play()
	task.delay(1.15, function() if effectPart.Parent then effectPart:Destroy() end end)
end

local function addFlyingDinoBody(model, data, cf, scale, index)
	local body = part(model, "FlyingDinoBody", scaled(Vector3.new(7.6, 3.5, 4.5), scale), data.body, cf, Enum.Material.Neon, Enum.PartType.Ball)
	body.CanTouch = true
	part(model, "LongNeck", scaled(Vector3.new(2.2, 2.4, 1.5), scale), data.body, cf * CFrame.new(3.6 * scale, 0.95 * scale, 0), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "CrestHead", scaled(Vector3.new(3.5, 2.4, 2.4), scale), data.body, cf * CFrame.new(5.6 * scale, 1.65 * scale, 0), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "BeakSnout", scaled(Vector3.new(2.8, 0.9, 1.25), scale), data.wing, cf * CFrame.new(7.6 * scale, 1.45 * scale, 0), Enum.Material.Neon)
	part(model, "TailStreamer", scaled(Vector3.new(5.2, 0.8, 0.8), scale), data.body, cf * CFrame.new(-5.4 * scale, 0.25 * scale, 0), Enum.Material.Neon)

	part(model, "LeftWing", scaled(Vector3.new(0.5, 0.22, 10.5), scale), data.wing, cf * CFrame.new(0, 0.2 * scale, -5.2 * scale) * CFrame.Angles(math.rad(5), math.rad(-10), 0), Enum.Material.Neon)
	part(model, "RightWing", scaled(Vector3.new(0.5, 0.22, 10.5), scale), data.wing, cf * CFrame.new(0, 0.2 * scale, 5.2 * scale) * CFrame.Angles(math.rad(-5), math.rad(10), 0), Enum.Material.Neon)
	part(model, "LeftWingTip", scaled(Vector3.new(0.42, 0.2, 5.2), scale), data.wing, cf * CFrame.new(-1.4 * scale, -0.2 * scale, -10.0 * scale) * CFrame.Angles(0, math.rad(22), 0), Enum.Material.Neon)
	part(model, "RightWingTip", scaled(Vector3.new(0.42, 0.2, 5.2), scale), data.wing, cf * CFrame.new(-1.4 * scale, -0.2 * scale, 10.0 * scale) * CFrame.Angles(0, math.rad(-22), 0), Enum.Material.Neon)

	part(model, "LeftEye", scaled(Vector3.new(0.36, 0.36, 0.18), scale), "Really black", cf * CFrame.new(6.25 * scale, 2.08 * scale, -0.92 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "RightEye", scaled(Vector3.new(0.36, 0.36, 0.18), scale), "Really black", cf * CFrame.new(6.25 * scale, 2.08 * scale, 0.92 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "HeadCrest", scaled(Vector3.new(0.7, 1.9, 0.35), scale), data.wing, cf * CFrame.new(4.95 * scale, 2.95 * scale, 0), Enum.Material.Neon)

	if index % 3 == 0 then
		part(model, "GlowThroat", scaled(Vector3.new(1.3, 0.55, 1.5), scale), "Cyan", cf * CFrame.new(4.9 * scale, 0.72 * scale, 0), Enum.Material.Neon, Enum.PartType.Ball)
	elseif index % 3 == 1 then
		for i = 0, 3 do
			part(model, "BackSpike" .. i, scaled(Vector3.new(0.35, 0.9, 0.28), scale), data.wing, cf * CFrame.new((1.8 - i * 1.4) * scale, 2.0 * scale, 0), Enum.Material.Neon)
		end
	else
		part(model, "TailGlow", scaled(Vector3.new(1.0, 1.0, 1.0), scale), data.wing, cf * CFrame.new(-8.0 * scale, 0.3 * scale, 0), Enum.Material.Neon, Enum.PartType.Ball)
	end

	local sparks = Instance.new("ParticleEmitter")
	sparks.Color = ColorSequence.new(BrickColor.new(data.wing).Color, Color3.fromRGB(255, 255, 255))
	sparks.LightEmission = 1
	sparks.Lifetime = NumberRange.new(0.55, 1.0)
	sparks.Rate = 10 * scale
	sparks.Speed = NumberRange.new(1.5 * scale, 4 * scale)
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.32 * scale), NumberSequenceKeypoint.new(1, 0) })
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Parent = body

	local hitbox = part(model, "FlyingDinoCatchHitbox", scaled(Vector3.new(11, 7, 14), scale), data.body, cf, Enum.Material.ForceField)
	hitbox.Transparency = 1
	hitbox.CanTouch = true
	return body, hitbox
end

local function spawnGateCarpet()
	local cx = GATE_X - 9
	local carpet = Instance.new("Part")
	carpet.Name = "FlyingDinoForestLaunchCarpet"
	carpet.Size = Vector3.new(10, 0.4, 40)
	carpet.CFrame = CFrame.new(cx, 1.2, GATE_Z)
	carpet.BrickColor = BrickColor.new("Bright green")
	carpet.Material = Enum.Material.Neon
	carpet.Transparency = 0.28
	carpet.Anchored = true
	carpet.Parent = workspace

	local glow = Instance.new("Part")
	glow.Size = Vector3.new(7, 0.12, 36)
	glow.CFrame = CFrame.new(cx, 1.45, GATE_Z)
	glow.BrickColor = BrickColor.new("Lime green")
	glow.Material = Enum.Material.Neon
	glow.Transparency = 0.65
	glow.Anchored = true
	glow.CanCollide = false
	glow.Parent = workspace

	local carpetCooldown = {}
	task.spawn(function()
		while carpet.Parent do
			task.wait(0.1)
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local pos = hrp.Position
					if pos.X > GATE_X - 22 and pos.X < GATE_X + 6
						and math.abs(pos.Z - GATE_Z) < 22 and pos.Y < 18 then
						local now = os.clock()
						if not carpetCooldown[player] or now - carpetCooldown[player] >= 2 then
							carpetCooldown[player] = now
							hrp.AssemblyLinearVelocity = Vector3.new(90, 28, 0)
						end
					end
				end
			end
		end
	end)
end

local function openGate()
	if gateOpen then return end
	gateOpen = true
	forestRemaining.Value = 0
	do local event = gameEvents:FindFirstChild("GateOpenNotify"); if event then event:FireAllClients("Flying Dino Forest") end end
	stageHits.Value = NEEDED
	spawnGateCarpet()
end

local function getCatchingPlayer(hit)
	local character = hit.Parent
	return character and Players:GetPlayerFromCharacter(character)
end

local function catchDino(model, player)
	if not activeDinos[model] then return end
	if gateOpen then return end
	activeDinos[model] = nil
	catchesThisArea += 1
	forestRemaining.Value = math.max(0, forestRemaining.Value - 1)
	if not gateOpen then stageHits.Value = catchesThisArea end
	if player and playerScored then playerScored:Fire(player, "Flying Dino Forest") end
	showCatchReward(player, model)
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanTouch = false
			TweenService:Create(object, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.28, function() if model.Parent then model:Destroy() end end)
	if not gateOpen and (catchesThisArea >= NEEDED or forestRemaining.Value <= 0) then openGate() end
end

local function spawnDino(data, index)
	local model = Instance.new("Model")
	model.Name = data.name
	model.Parent = workspace
	model:SetAttribute("CashReward", cashForDino(data))
	local scale = data.scale or 1
	local tiers = {18, 23, 28, 42, 50, 62, 74, 86, 96}
	local cf = CFrame.new(math.random(BOUNDS.minX, BOUNDS.maxX), tiers[((index - 1) % #tiers) + 1] + math.max(0, scale - 1) * 4, math.random(BOUNDS.minZ, BOUNDS.maxZ))
	local body, hitbox = addFlyingDinoBody(model, data, cf, scale, index)
	model.PrimaryPart = body
	activeDinos[model] = true
	BoundaryService.bindModel(model, BOUNDS, { margin = 8, minY = 12, maxY = 112 })
	body.Touched:Connect(function(hit) local player = getCatchingPlayer(hit); if player then catchDino(model, player) end end)
	hitbox.Touched:Connect(function(hit) local player = getCatchingPlayer(hit); if player then catchDino(model, player) end end)
	task.spawn(function()
		while activeDinos[model] and model.Parent do
			local value = Instance.new("CFrameValue")
			value.Value = model:GetPivot()
			local conn = value.Changed:Connect(function(cf2) if model.Parent then model:PivotTo(cf2) end end)
			local target = CFrame.new(math.random(BOUNDS.minX, BOUNDS.maxX), 16 + math.random() * 84, math.random(BOUNDS.minZ, BOUNDS.maxZ))
			local duration = scale <= 0.6 and math.random(18, 30) / 10 or scale >= 1.5 and math.random(80, 124) / 10 or math.random(36, 62) / 10
			local tween = TweenService:Create(value, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = target })
			tween:Play()
			tween.Completed:Wait()
			conn:Disconnect()
			value:Destroy()
			task.wait(0.1)
		end
	end)
end

local function spawnForestDinos()
	stageNeeded.Value = NEEDED
	stageHits.Value = 0
	math.randomseed(tick() + 14021)
	for index, dino in DINOS do
		spawnDino(dino, index)
	end
	task.spawn(function()
		while not gateOpen do
			task.wait(0.06)
			for model in activeDinos do
				if not model.Parent then continue end
				local body = model:FindFirstChild("FlyingDinoBody")
				if not body then continue end
				for _, player in Players:GetPlayers() do
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - body.Position).Magnitude < 11 then
						catchDino(model, player)
					end
				end
			end
		end
	end)
end

task.spawn(spawnForestDinos)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Flying Dino Forest" then return end
		for model in activeDinos do
			activeDinos[model] = nil
			if model.Parent then model:Destroy() end
		end
		catchesThisArea = 0
		gateOpen = false
		forestRemaining.Value = #DINOS
		spawnForestDinos()
	end)
end)
