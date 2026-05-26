local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local BOUNDS = { minX = 566, maxX = 842, minZ = 1552, maxZ = 1848 }
local BoundaryService = require(ServerStorage:WaitForChild("WorldBoundaryService"))
local GATE_X = 860
local GATE_Z = 1700
local NEEDED = Balance.StageTargets.NewPizzaPlace
local CASH_SMALL = Balance.CatchRewards.BirdSmall
local CASH_NORMAL = Balance.CatchRewards.BirdNormal
local CASH_GIANT = Balance.CatchRewards.BirdGiant

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")
local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local newPizzaRemaining = Instance.new("NumberValue")
newPizzaRemaining.Name = "NewPizzaChefsRemaining"
newPizzaRemaining.Parent = gameEvents

local newPizzaTotal = Instance.new("NumberValue")
newPizzaTotal.Name = "NewPizzaChefsTotal"
newPizzaTotal.Parent = gameEvents

local catchesThisArea = 0
local gateOpen = false
local activeBirds = {}

local BIRDS = {
	{ name = "Slice Bird", body = "Bright orange", wing = "Bright yellow" },
	{ name = "Cheese Bird", body = "Bright yellow", wing = "New Yeller" },
	{ name = "Pepperoni Bird", body = "Really red", wing = "Bright orange" },
	{ name = "Oven Bird", body = "Dark stone grey", wing = "Bright red" },
	{ name = "Sauce Bird", body = "Bright red", wing = "Really red" },
	{ name = "Crust Bird", body = "Brick yellow", wing = "Institutional white" },
	{ name = "Dough Bird", body = "Institutional white", wing = "Cyan" },
	{ name = "Mozza Bird", body = "New Yeller", wing = "Bright orange" },
	{ name = "Olive Bird", body = "Really black", wing = "Medium stone grey" },
	{ name = "Mushroom Bird", body = "Medium stone grey", wing = "Institutional white" },
	{ name = "Pineapple Bird", body = "Bright yellow", wing = "Bright orange" },
	{ name = "Garlic Bird", body = "Institutional white", wing = "New Yeller" },
	{ name = "Box Bird", body = "Bright blue", wing = "Hot pink" },
	{ name = "Neon Bird", body = "Hot pink", wing = "Bright yellow" },
	{ name = "Spicy Bird", body = "Really red", wing = "Bright yellow" },
	{ name = "Crater Bird", body = "Brown", wing = "Bright orange" },
	{ name = "Planet Bird", body = "Royal purple", wing = "Institutional white" },
	{ name = "Final Slice Bird", body = "Really black", wing = "Bright red" },
	{ name = "Giant Slice Bird", body = "Bright orange", wing = "Bright yellow", scale = 1.65 },
	{ name = "Giant Cheese Bird", body = "Bright yellow", wing = "New Yeller", scale = 1.65 },
	{ name = "Giant Oven Bird", body = "Dark stone grey", wing = "Bright red", scale = 1.65 },
	{ name = "Giant Neon Bird", body = "Hot pink", wing = "Bright yellow", scale = 1.65 },
	{ name = "Giant Planet Bird", body = "Royal purple", wing = "Institutional white", scale = 1.65 },
	{ name = "Tiny Pepperoni Bird", body = "Really red", wing = "Bright orange", scale = 0.39 },
	{ name = "Tiny Crust Bird", body = "Brick yellow", wing = "Institutional white", scale = 0.39 },
	{ name = "Tiny Dough Bird", body = "Institutional white", wing = "Cyan", scale = 0.39 },
	{ name = "Tiny Olive Bird", body = "Really black", wing = "Medium stone grey", scale = 0.39 },
	{ name = "Tiny Garlic Bird", body = "Institutional white", wing = "New Yeller", scale = 0.39 },
}

newPizzaTotal.Value = #BIRDS
newPizzaRemaining.Value = #BIRDS

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

	local effectPart = Instance.new("Part")
	effectPart.Name = "BirdCashEffect"
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.CFrame = model:GetPivot()
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
	local cx = GATE_X - 10
	local cz = GATE_Z
	local carpet = Instance.new("Part")
	carpet.Name = "PizzaLaunchCarpet"
	carpet.Size = Vector3.new(8, 0.25, 13)
	carpet.CFrame = CFrame.new(cx, 1.15, cz)
	carpet.Anchored = true
	carpet.BrickColor = BrickColor.new("Hot pink")
	carpet.Material = Enum.Material.Neon
	carpet.Transparency = 0.12
	carpet.Parent = workspace

	local border = Instance.new("SelectionBox")
	border.Adornee = carpet
	border.Color3 = Color3.fromRGB(255, 120, 220)
	border.LineThickness = 0.08
	border.SurfaceTransparency = 0.78
	border.Parent = carpet

	local inner = Instance.new("Part")
	inner.Size = Vector3.new(6, 0.08, 10.5)
	inner.CFrame = carpet.CFrame + Vector3.new(0, 0.18, 0)
	inner.Anchored = true
	inner.CanCollide = false
	inner.BrickColor = BrickColor.new("Cyan")
	inner.Material = Enum.Material.Neon
	inner.Transparency = 0.35
	inner.Parent = carpet

	for _, zo in { -4, 0, 4 } do
		local stripe = Instance.new("Part")
		stripe.Size = Vector3.new(6.4, 0.1, 0.35)
		stripe.CFrame = carpet.CFrame * CFrame.new(0, 0.28, zo)
		stripe.Anchored = true
		stripe.CanCollide = false
		stripe.BrickColor = BrickColor.new("New Yeller")
		stripe.Material = Enum.Material.Neon
		stripe.Transparency = 0.18
		stripe.Parent = carpet
	end

	for _, xo in { -3.1, 3.1 } do
		for _, zo in { -5.6, 5.6 } do
			local gem = Instance.new("Part")
			gem.Shape = Enum.PartType.Ball
			gem.Size = Vector3.new(0.75, 0.75, 0.75)
			gem.CFrame = carpet.CFrame * CFrame.new(xo, 0.48, zo)
			gem.Anchored = true
			gem.CanCollide = false
			gem.BrickColor = BrickColor.new("New Yeller")
			gem.Material = Enum.Material.Neon
			gem.Transparency = 0.05
			gem.Parent = carpet
		end
	end

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
	newPizzaRemaining.Value = 0
	do local _ne = gameEvents:FindFirstChild("GateOpenNotify"); if _ne then _ne:FireAllClients("Pizza Galaxy") end end
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
	newPizzaRemaining.Value = math.max(0, newPizzaRemaining.Value - 1)
	if not gateOpen then stageHits.Value = catchesThisArea end
	showCatchReward(player, model)
	if player and playerScored then playerScored:Fire(player, "New Pizza Place") end
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanTouch = false
			TweenService:Create(object, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.28, function() if model.Parent then model:Destroy() end end)
	if not gateOpen and (catchesThisArea >= NEEDED or newPizzaRemaining.Value <= 0) then
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
			local targetPivot = CFrame.new(math.random(BOUNDS.minX, BOUNDS.maxX), 9 + math.random() * 11, math.random(BOUNDS.minZ, BOUNDS.maxZ))
			local value = Instance.new("CFrameValue")
			value.Value = startPivot
			local conn = value.Changed:Connect(function(cf2)
				if model.Parent then model:PivotTo(cf2) end
			end)
			local tweenDuration
				if scale <= 0.5 then tweenDuration = math.random(18, 28) / 10
				elseif scale >= 1.5 then tweenDuration = math.random(80, 120) / 10
				else tweenDuration = math.random(42, 64) / 10 end
				local tween = TweenService:Create(value, TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = targetPivot })
			tween:Play()
			tween.Completed:Wait()
			conn:Disconnect()
			value:Destroy()
			task.wait(0.1)
		end
	end)
end

local function spawnNewPizzaBirds()
	stageNeeded.Value = NEEDED
	stageHits.Value = 0
	math.randomseed(tick() + 10021)
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

task.spawn(spawnNewPizzaBirds)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "New Pizza Place" then return end
		for model in activeBirds do
			activeBirds[model] = nil
			if model.Parent then model:Destroy() end
		end
		catchesThisArea = 0
		gateOpen = false
		newPizzaRemaining.Value = #BIRDS
		spawnNewPizzaBirds()
	end)
end)
