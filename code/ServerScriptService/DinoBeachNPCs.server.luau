local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local BOUNDS = { minX = 1622, maxX = 1898, minZ = 1552, maxZ = 1848 }
local BoundaryService = require(ServerStorage:WaitForChild("WorldBoundaryService"))
local GATE_X = 1916
local GATE_Z = 1700
local NEEDED = Balance.StageTargets.DinoBeach
local CASH_SMALL = Balance.CatchRewards.DinoBeachSmall
local CASH_NORMAL = Balance.CatchRewards.DinoBeach
local CASH_GIANT = Balance.CatchRewards.DinoBeachGiant

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local stageHits = gameEvents:WaitForChild("StageHits")
local stageNeeded = gameEvents:WaitForChild("StageNeeded")
local playerScored
task.spawn(function() playerScored = gameEvents:WaitForChild("PlayerScored", 30) end)

local beachRemaining = Instance.new("NumberValue")
beachRemaining.Name = "DinoBeachDinosRemaining"
beachRemaining.Parent = gameEvents

local beachTotal = Instance.new("NumberValue")
beachTotal.Name = "DinoBeachDinosTotal"
beachTotal.Parent = gameEvents

local catchesThisArea = 0
local gateOpen = false
local activeDinos = {}

local DINOS = {
	{ name = "Surf Raptor", body = "Cyan", accent = "Bright yellow", scale = 0.85, style = "raptor" },
	{ name = "Sand Trike", body = "Brick yellow", accent = "Institutional white", scale = 1.02, style = "trike" },
	{ name = "Coral Rex", body = "Hot pink", accent = "Cyan", scale = 1.0, style = "rex" },
	{ name = "Shell Stego", body = "Bright blue", accent = "Institutional white", scale = 1.0, style = "spike" },
	{ name = "Lifeguard Rex", body = "Really red", accent = "Bright yellow", scale = 1.08, style = "rex" },
	{ name = "Palm Raptor", body = "Bright green", accent = "Bright orange", scale = 0.9, style = "raptor" },
	{ name = "Wave Trike", body = "Cyan", accent = "Bright blue", scale = 1.05, style = "trike" },
	{ name = "Tiny Surf Raptor", body = "Cyan", accent = "Bright yellow", scale = 0.55, style = "raptor" },
	{ name = "Tiny Sand Rex", body = "Light orange", accent = "Really black", scale = 0.55, style = "rex" },
	{ name = "Tiny Shell Stego", body = "Pastel Blue", accent = "Institutional white", scale = 0.55, style = "spike" },
	{ name = "Giant Beach Rex", body = "Bright orange", accent = "Cyan", scale = 1.65, style = "rex" },
	{ name = "Giant Wave Trike", body = "Bright blue", accent = "Institutional white", scale = 1.65, style = "trike" },
	{ name = "Giant Coral Stego", body = "Hot pink", accent = "Bright yellow", scale = 1.65, style = "spike" },
}

beachTotal.Value = #DINOS
beachRemaining.Value = #DINOS

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
	effectPart.Name = "BeachDinoCashEffect"
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
	sound.PlaybackSpeed = 0.9
	sound.Parent = effectPart
	sound:Play()
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 90), Color3.fromRGB(80, 220, 255))
	particles.Lifetime = NumberRange.new(0.45, 0.85)
	particles.Speed = NumberRange.new(7, 14)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rate = 0
	particles.Parent = effectPart
	particles:Emit(34)
	local popup = Instance.new("BillboardGui")
	popup.Size = UDim2.new(0, 130, 0, 44)
	popup.StudsOffset = Vector3.new(0, 3, 0)
	popup.Parent = effectPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. amount
	label.TextColor3 = Color3.fromRGB(255, 230, 90)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = popup
	TweenService:Create(popup, TweenInfo.new(0.9), { StudsOffset = Vector3.new(0, 6, 0) }):Play()
	task.delay(1.15, function() if effectPart.Parent then effectPart:Destroy() end end)
end

local function addDinoBody(model, data, cf, scale)
	local body = part(model, "DinoBody", scaled(Vector3.new(8.8, 4.6, 5.2), scale), data.body, cf, Enum.Material.Neon, Enum.PartType.Ball)
	body.CanTouch = true
	part(model, "DinoNeck", scaled(Vector3.new(2.5, 3.4, 2.4), scale), data.body, cf * CFrame.new(3.7 * scale, 1.8 * scale, 0), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "DinoHead", scaled(Vector3.new(4.2, 3.0, 3.0), scale), data.body, cf * CFrame.new(6.0 * scale, 2.7 * scale, 0), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "DinoSnout", scaled(Vector3.new(2.6, 1.3, 1.8), scale), data.body, cf * CFrame.new(8.0 * scale, 2.45 * scale, 0), Enum.Material.Neon)
	part(model, "Tail", scaled(Vector3.new(5.8, 1.4, 1.4), scale), data.body, cf * CFrame.new(-5.6 * scale, 0.7 * scale, 0), Enum.Material.Neon)
	for _, z in { -1.65, 1.65 } do
		part(model, "LegFront" .. tostring(z), scaled(Vector3.new(1.1, 3.4, 1.1), scale), data.body, cf * CFrame.new(2.3 * scale, -2.3 * scale, z * scale), Enum.Material.Neon)
		part(model, "LegBack" .. tostring(z), scaled(Vector3.new(1.1, 3.4, 1.1), scale), data.body, cf * CFrame.new(-2.6 * scale, -2.3 * scale, z * scale), Enum.Material.Neon)
		part(model, "FootFront" .. tostring(z), scaled(Vector3.new(2.0, 0.7, 1.4), scale), data.accent, cf * CFrame.new(3.0 * scale, -4.1 * scale, z * scale), Enum.Material.Neon)
		part(model, "FootBack" .. tostring(z), scaled(Vector3.new(2.0, 0.7, 1.4), scale), data.accent, cf * CFrame.new(-1.9 * scale, -4.1 * scale, z * scale), Enum.Material.Neon)
	end
	part(model, "LeftEye", scaled(Vector3.new(0.45, 0.45, 0.22), scale), "Really black", cf * CFrame.new(7.15 * scale, 3.28 * scale, -1.12 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "RightEye", scaled(Vector3.new(0.45, 0.45, 0.22), scale), "Really black", cf * CFrame.new(7.15 * scale, 3.28 * scale, 1.12 * scale), Enum.Material.Neon, Enum.PartType.Ball)
	part(model, "BeachSunglasses", scaled(Vector3.new(0.35, 0.65, 2.75), scale), data.accent, cf * CFrame.new(7.28 * scale, 3.28 * scale, 0), Enum.Material.Neon)
	if data.style == "trike" then
		part(model, "Frill", scaled(Vector3.new(0.6, 3.4, 5.2), scale), data.accent, cf * CFrame.new(4.65 * scale, 2.78 * scale, 0), Enum.Material.Neon)
		part(model, "NoseHorn", scaled(Vector3.new(1.7, 0.45, 0.45), scale), "Institutional white", cf * CFrame.new(9.15 * scale, 2.85 * scale, 0), Enum.Material.Neon)
	elseif data.style == "spike" then
		for i = 0, 5 do
			part(model, "ShellPlate" .. i, scaled(Vector3.new(0.55, 1.9, 2.4), scale), data.accent, cf * CFrame.new((2.2 - i * 1.45) * scale, 3.0 * scale, 0), Enum.Material.Neon)
		end
	else
		part(model, "SurfBrow", scaled(Vector3.new(2.2, 0.28, 2.8), scale), data.accent, cf * CFrame.new(6.95 * scale, 3.75 * scale, 0), Enum.Material.Neon)
		for tooth = -2, 2 do
			part(model, "Tooth" .. tooth, scaled(Vector3.new(0.28, 0.7, 0.22), scale), "Institutional white", cf * CFrame.new(8.88 * scale, 1.78 * scale, tooth * 0.42 * scale), Enum.Material.Neon)
		end
	end
	local hitbox = part(model, "DinoCatchHitbox", scaled(Vector3.new(12, 8, 8), scale), data.body, cf * CFrame.new(1.2 * scale, 0.2 * scale, 0), Enum.Material.ForceField)
	hitbox.Transparency = 1
	hitbox.CanTouch = true
	return body, hitbox
end

local function spawnGateCarpet()
	local cx = GATE_X - 9
	local carpet = Instance.new("Part")
	carpet.Name = "DinoBeachLaunchCarpet"
	carpet.Size = Vector3.new(10, 0.4, 40)
	carpet.CFrame = CFrame.new(cx, 1.2, GATE_Z)
	carpet.BrickColor = BrickColor.new("Bright yellow")
	carpet.Material = Enum.Material.Neon
	carpet.Transparency = 0.28
	carpet.Anchored = true
	carpet.Parent = workspace

	local glow = Instance.new("Part")
	glow.Size = Vector3.new(7, 0.12, 36)
	glow.CFrame = CFrame.new(cx, 1.45, GATE_Z)
	glow.BrickColor = BrickColor.new("Cyan")
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
	beachRemaining.Value = 0
	do local event = gameEvents:FindFirstChild("GateOpenNotify"); if event then event:FireAllClients("Dino Beach") end end
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
	beachRemaining.Value = math.max(0, beachRemaining.Value - 1)
	if not gateOpen then stageHits.Value = catchesThisArea end
	if player and playerScored then playerScored:Fire(player, "Dino Beach") end
	showCatchReward(player, model)
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanTouch = false
			TweenService:Create(object, TweenInfo.new(0.25), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.28, function() if model.Parent then model:Destroy() end end)
	if not gateOpen and (catchesThisArea >= NEEDED or beachRemaining.Value <= 0) then openGate() end
end

local function spawnDino(data, index)
	local model = Instance.new("Model")
	model.Name = data.name
	model.Parent = workspace
	model:SetAttribute("CashReward", cashForDino(data))
	local scale = data.scale or 1
	local cf = CFrame.new(math.random(BOUNDS.minX, BOUNDS.maxX), 5.1 + math.max(0, scale - 1) * 1.5, math.random(BOUNDS.minZ, BOUNDS.maxZ))
	local body, hitbox = addDinoBody(model, data, cf, scale)
	model.PrimaryPart = body
	activeDinos[model] = true
	BoundaryService.bindModel(model, BOUNDS, { margin = 8, minY = 4, maxY = 24 })
	body.Touched:Connect(function(hit) local player = getCatchingPlayer(hit); if player then catchDino(model, player) end end)
	hitbox.Touched:Connect(function(hit) local player = getCatchingPlayer(hit); if player then catchDino(model, player) end end)
	task.spawn(function()
		while activeDinos[model] and model.Parent do
			local value = Instance.new("CFrameValue")
			value.Value = model:GetPivot()
			local conn = value.Changed:Connect(function(cf2) if model.Parent then model:PivotTo(cf2) end end)
			local target = CFrame.new(math.random(BOUNDS.minX, BOUNDS.maxX), 5.1 + math.max(0, scale - 1) * 1.5, math.random(BOUNDS.minZ, BOUNDS.maxZ)) * CFrame.Angles(0, math.rad(math.random(-20, 20)), 0)
			local speed = scale >= 1.5 and math.random(56, 78) / 10 or scale <= 0.6 and math.random(18, 28) / 10 or math.random(32, 48) / 10
			local tween = TweenService:Create(value, TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = target })
			tween:Play()
			tween.Completed:Wait()
			conn:Disconnect()
			value:Destroy()
			task.wait(math.random(8, 18) / 20)
		end
	end)
end

local function spawnBeachDinos()
	stageNeeded.Value = NEEDED
	stageHits.Value = 0
	math.randomseed(tick() + 13021)
	for index, dino in DINOS do
		spawnDino(dino, index)
	end
	task.spawn(function()
		while not gateOpen do
			task.wait(0.06)
			for model in activeDinos do
				if not model.Parent then continue end
				local body = model:FindFirstChild("DinoBody")
				if not body then continue end
				for _, player in Players:GetPlayers() do
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - body.Position).Magnitude < 10 then
						catchDino(model, player)
					end
				end
			end
		end
	end)
end

task.spawn(spawnBeachDinos)

task.spawn(function()
	local signal = gameEvents:WaitForChild("WorldRestartSignal", 30)
	if not signal then return end
	signal.Event:Connect(function(wName)
		if wName ~= "Dino Beach" then return end
		for model in activeDinos do
			activeDinos[model] = nil
			if model.Parent then model:Destroy() end
		end
		catchesThisArea = 0
		gateOpen = false
		beachRemaining.Value = #DINOS
		spawnBeachDinos()
	end)
end)
