local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Balance           = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local CashService       = require(script.Parent:WaitForChild("CashService"))
local skyDescent        = require(script.Parent:WaitForChild("SkyDescent"))
local SafeLevelSpawn    = require(script.Parent:WaitForChild("SafeLevelSpawn"))

local G   = 84
local WX  = 78
local WZ  = -735
local STAGE_LIFT = 5
local WY  = G + 7.1 + STAGE_LIFT

local IS_DEBUG_MODE = Balance.ActiveMode == "debug" or Balance.ActiveMode == "fallback-debug"
-- Debug-only starter launcher. Change this number to choose which world it sends you to.
-- Use the order values from ReplicatedStorage/WorldOrderConfig.luau.
local DEBUG_WORLD_LAUNCH_ORDER = 49
local DEBUG_WORLD_LAUNCH_ENABLED = true
local STAGE_LAUNCH_DESCENT_SECONDS = 1
local DEBUG_WORLD_LAUNCH_SPAWNS = {
	[1]  = CFrame.new(  0,  7,    0),   -- Playground
	[2]  = CFrame.new(  0,  7,  142),   -- Pizza
	[3]  = CFrame.new(  0,  8,  398),   -- Galactic
	[4]  = CFrame.new(  0,  8,  652),   -- Jungle
	[5]  = CFrame.new(  0,  8,  872),   -- Sports
	[6]  = CFrame.new(  0,  8, 1102),   -- Tennis
	[7]  = CFrame.new(  0,  8, 1312),   -- Game Station
	[8]  = CFrame.new(  0,  8, 1558),   -- Coffee Shop
	[9]  = CFrame.new(224,  8, 1700),   -- Burger House
	[10] = CFrame.new(590,  8, 1700),   -- New Pizza Place
	[11] = CFrame.new(918,  8, 1700),   -- Swimming Pool
	[12] = CFrame.new(1270, 8, 1700),   -- Dinosaur Park
	[13] = CFrame.new(1622, 8, 1700),   -- Dino Beach
	[14] = CFrame.new(1974, 8, 1700),   -- Flying Dino Forest
	[15] = CFrame.new(2326, 8, 1700),   -- Cherry Grove
	[16] = CFrame.new(2678, 8, 1700),   -- Galactic Orchard
	[17] = CFrame.new(-550,  8, 1700),  -- Empty World 1
	[18] = CFrame.new(-1320, 8, 1700),  -- Storm Dome
	[19] = CFrame.new(-2090, 8, 1580),  -- Volt Abyss
	[20] = CFrame.new(-2860, 8, 1700),  -- Neon Rift
	[21] = CFrame.new(-3500, 8, 1700),  -- Sky Vault
	[22] = CFrame.new(-3660, 8, 1700),  -- Storm Tower
	[23] = CFrame.new(-2860, 8, 2162),  -- Frost Basin
	[24] = CFrame.new(-2860, 8, 2550),  -- Ember Hold
	[25] = CFrame.new(-2860, 8, 2900),  -- Nova Spire
	[26] = CFrame.new(-2860, 8, 3200),  -- Prism Peak
	[27] = CFrame.new(-2860, 8, 3500),  -- Magma Core
	[28] = CFrame.new(-2860, 8, 3830),  -- Storm Circuit
	[29] = CFrame.new(-2860, 8, 4130),  -- Shadow Vault
	[30] = CFrame.new(-2860, 8, 4450),  -- Apex Nexus
	[31] = CFrame.new(-2860, 8, 4760),  -- Cloud Drift
	[32] = CFrame.new(-2860, 8, 5060),  -- Coral Reef
	[33] = CFrame.new(-2860, 8, 5340),  -- Bubble Bounce
	[34] = CFrame.new(-2860, 8, 5620),  -- Zen Garden
	[35] = CFrame.new(-2860, 8, 5900),  -- Crystal Spires
	[36] = CFrame.new(-2860, 8, 6185),  -- Neon Triangle
	[37] = CFrame.new(-2860, 8, 6470),  -- Wide Canyon
	[38] = CFrame.new(-2860, 8, 6755),  -- Narrow Pass
	[39] = CFrame.new(-2860, 8, 7040),  -- Diamond Gate
	[40] = CFrame.new(-2860, 8, 7325),  -- Hourglass Vault
	[41] = CFrame.new(-2860, 8, 7610),  -- Movement Lab
	[42] = CFrame.new(-2860, 8, 8100),  -- Fight Arena
	[43] = CFrame.new(-2860, 8, 8410),  -- Empty World 43
}

local eventsFolder = Instance.new("Folder")
eventsFolder.Name   = "SpinWheelEvents"
eventsFolder.Parent = ReplicatedStorage

local spinResult = Instance.new("RemoteEvent")
spinResult.Name   = "SpinResult"
spinResult.Parent = eventsFolder

local JUMP_POWERS = Balance.Movement.JumpPowers
local WALK_SPEEDS = Balance.Movement.WalkSpeeds
local SKATE_SPEED = Balance.Skateboard.Speed
local SKATE_JUMP  = Balance.Skateboard.JumpPower
local START_WITH_SKATEBOARD = Balance.Skateboard.StartWithPlayer
local SKATE_DURATION = Balance.Skateboard.DurationSeconds or 180

local skateEquipped = Instance.new("RemoteEvent")
skateEquipped.Name   = "SkateboardEquipped"
skateEquipped.Parent = eventsFolder

-- Fired to client whenever mounted state changes: arg = bool (true=on board, false=off board)
local skateState = Instance.new("RemoteEvent")
skateState.Name   = "SkateboardState"
skateState.Parent = eventsFolder

-- Client fires this to request a mount/dismount toggle
local skateToggle = Instance.new("RemoteEvent")
skateToggle.Name   = "SkateboardToggle"
skateToggle.Parent = eventsFolder

local function applyStats(player)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if player:GetAttribute("SkateboardMounted") then
		hum.WalkSpeed = SKATE_SPEED
		hum.JumpPower = SKATE_JUMP
	else
		hum.JumpPower = JUMP_POWERS[player:GetAttribute("JumpBoost")  or 0] or 50
		hum.WalkSpeed = WALK_SPEEDS[player:GetAttribute("SpeedBoost") or 0] or 16
	end
end

local function grantCash(player, amount)
	CashService.add(player, amount)
end

local function makeSkatePart(parent, name, size, color, cf, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.BrickColor = BrickColor.new(color)
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CastShadow = false
	if shape then part.Shape = shape end
	part.CFrame = cf
	part.Parent = parent
	return part
end

-- Builds the physical skateboard model on the character. Does not touch attributes.
-- hipOffset: extra downward shift so the board stays at ground level when HipHeight is raised.
local function buildSkateModel(character, hrp, hipOffset)
	local oldBoard = character:FindFirstChild("PrizeSkateboard")
	if oldBoard then oldBoard:Destroy() end

	local boardModel = Instance.new("Model")
	boardModel.Name = "PrizeSkateboard"
	boardModel.Parent = character

	-- Board faces forward along Z. The hipOffset shifts it down to compensate for
	-- HipHeight being raised after the weld is created, keeping the board at ground level.
	local deckCF = hrp.CFrame * CFrame.new(0, -2.1 - (hipOffset or 0), 0)

	-- Deck: width=1.65(X), height=0.32(Y), length=4.8(Z = forward/back)
	local deck = makeSkatePart(boardModel, "Deck",
		Vector3.new(1.65, 0.32, 4.8),
		"Really black", deckCF, Enum.Material.SmoothPlastic)
	boardModel.PrimaryPart = deck

	-- Dark galactic grip tape on top surface
	makeSkatePart(boardModel, "GripTape",
		Vector3.new(1.3, 0.07, 4.3),
		"Royal purple", deckCF * CFrame.new(0, 0.19, 0), Enum.Material.SmoothPlastic)

	-- Neon comet trail along centre of grip tape
	local stripe = makeSkatePart(boardModel, "Stripe",
		Vector3.new(0.24, 0.08, 3.8),
		"Cyan", deckCF * CFrame.new(0, 0.20, 0), Enum.Material.Neon)
	stripe.Transparency = 0.08

	for _, dot in {
		Vector3.new(-0.46, 0.24, -1.45),
		Vector3.new(0.48, 0.24, -0.76),
		Vector3.new(-0.28, 0.24, 0.18),
		Vector3.new(0.52, 0.24, 0.98),
		Vector3.new(-0.52, 0.24, 1.62),
	} do
		local star = makeSkatePart(boardModel, "GalacticStar",
			Vector3.new(0.16, 0.16, 0.16),
			"New Yeller", deckCF * CFrame.new(dot), Enum.Material.Neon, Enum.PartType.Ball)
		star.Transparency = 0.06
	end

	-- Neon edge trim along both long sides of deck
	for _, x in { -0.86, 0.86 } do
		local edge = makeSkatePart(boardModel, "DeckEdge",
			Vector3.new(0.07, 0.33, 4.75),
			x < 0 and "Cyan" or "Magenta", deckCF * CFrame.new(x, 0, 0), Enum.Material.Neon)
		edge.Transparency = 0.16
	end

	-- Kicktail (rear end, angled upward)
	local tailCF = deckCF * CFrame.new(0, 0.12, 2.05) * CFrame.Angles(0.38, 0, 0)
	makeSkatePart(boardModel, "KickTail",
		Vector3.new(1.65, 0.32, 0.9),
		"Royal purple", tailCF, Enum.Material.SmoothPlastic)

	-- Nose (front end, subtle upward angle)
	local noseCF = deckCF * CFrame.new(0, 0.08, -2.05) * CFrame.Angles(-0.24, 0, 0)
	makeSkatePart(boardModel, "Nose",
		Vector3.new(1.65, 0.32, 0.78),
		"Royal purple", noseCF, Enum.Material.SmoothPlastic)

	-- Trucks and wheels.
	-- Trucks sit at front/back (±Z). Hanger spans left/right (X axis).
	-- Cylinder wheels have their axis along X (left-right) by default — correct for rolling along Z.
	for _, tz in { -1.58, 1.58 } do
		-- Baseplate (bolted to underside of deck)
		makeSkatePart(boardModel, "TruckBase",
			Vector3.new(1.4, 0.15, 0.58),
			"Dark stone grey", deckCF * CFrame.new(0, -0.23, tz), Enum.Material.Metal)

		-- Hanger (T-bar spanning left/right)
		makeSkatePart(boardModel, "TruckHanger",
			Vector3.new(2.1, 0.27, 0.27),
			"Medium stone grey", deckCF * CFrame.new(0, -0.45, tz), Enum.Material.Metal)

		-- Kingpin bushing (orange sphere between baseplate and hanger)
		local bushing = makeSkatePart(boardModel, "Bushing",
			Vector3.new(0.24, 0.24, 0.24),
			"Magenta", deckCF * CFrame.new(0, -0.34, tz),
			Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		bushing.Transparency = 0.08

		for _, wx in { -1.08, 1.08 } do
			-- Wheel: Cylinder, axis along X (left-right), rolls forward/back. No extra rotation needed.
			local wheel = makeSkatePart(boardModel, "Wheel",
				Vector3.new(0.54, 0.85, 0.85),
				wx < 0 and "Cyan" or "Magenta", deckCF * CFrame.new(wx, -0.70, tz),
				Enum.Material.Neon, Enum.PartType.Cylinder)
			wheel.Transparency = 0.04

			-- Dark hub insert
			makeSkatePart(boardModel, "WheelHub",
				Vector3.new(0.56, 0.45, 0.45),
				"Really black", deckCF * CFrame.new(wx, -0.70, tz),
				Enum.Material.Metal, Enum.PartType.Cylinder)

			-- Axle nut (small sphere at outer face of wheel)
			local nutX = wx + (wx > 0 and 0.34 or -0.34)
			makeSkatePart(boardModel, "AxleNut",
				Vector3.new(0.19, 0.19, 0.19),
				"New Yeller", deckCF * CFrame.new(nutX, -0.70, tz),
				Enum.Material.Neon, Enum.PartType.Ball)
		end
	end

	-- Weld all parts to deck
	for _, p in boardModel:GetDescendants() do
		if p:IsA("BasePart") and p ~= deck then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = deck
			weld.Part1 = p
			weld.Parent = p
		end
	end

	-- Weld deck to character root
	local rootWeld = Instance.new("WeldConstraint")
	rootWeld.Name  = "SkateboardRootWeld"
	rootWeld.Part0 = hrp
	rootWeld.Part1 = deck
	rootWeld.Parent = deck
end

local SKATE_HIP_HEIGHT = Balance.Skateboard.HipHeight

local function setSkateboardAvailable(player, available)
	player:SetAttribute("HasSkateboard", available)
	if not available then
		player:SetAttribute("SkateboardTimeRemaining", 0)
	end
end

local function mountSkateboard(player)
	if (player:GetAttribute("SkateboardTimeRemaining") or 0) <= 0 then
		setSkateboardAvailable(player, false)
		return
	end

	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local existingBoard = char:FindFirstChild("PrizeSkateboard")
	if player:GetAttribute("SkateboardMounted") and existingBoard then
		applyStats(player)
		skateState:FireClient(player, true)
		return
	end

	player:SetAttribute("SkateboardMounted", true)
	applyStats(player)

	-- Save the character's current HipHeight so we can restore it exactly on dismount.
	-- Do this before modifying it.
	local baseHipHeight = player:GetAttribute("BaseHipHeight")
	if not baseHipHeight or existingBoard then
		baseHipHeight = hum.HipHeight
		player:SetAttribute("BaseHipHeight", baseHipHeight)
	end
	hum.HipHeight = baseHipHeight + SKATE_HIP_HEIGHT

	-- Wait a couple of frames so Humanoid physics repositions HRP at the new height
	-- before we compute the weld offset. Without this the board spawns underground.
	task.wait(0.08)

	-- Re-acquire references in case character changed during the wait
	char = player.Character
	if not char or not player:GetAttribute("SkateboardMounted") then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- HRP is now SKATE_HIP_HEIGHT above its original position.
	-- Pass that as hipOffset so buildSkateModel compensates and the board
	-- ends up at the same ground-level position as without HipHeight.
	buildSkateModel(char, hrp, SKATE_HIP_HEIGHT)
	skateEquipped:FireClient(player)
	skateState:FireClient(player, true)
end

local function dismountSkateboard(player)
	local char = player.Character
	if not char then return end
	local board = char:FindFirstChild("PrizeSkateboard")
	if board then board:Destroy() end
	local hum = char:FindFirstChildOfClass("Humanoid")
	player:SetAttribute("SkateboardMounted", false)
	applyStats(player)
	-- Restore exactly the HipHeight that was saved on mount, not a hardcoded 0.
	-- Hardcoding 0 buries R15 characters whose default HipHeight is ~1.35.
	if hum then
		hum.HipHeight = player:GetAttribute("BaseHipHeight") or 0
	end
	skateState:FireClient(player, false)
end

local function expireSkateboard(player)
	dismountSkateboard(player)
	setSkateboardAvailable(player, false)
end

local function giveSkateboard(player)
	player:SetAttribute("SkateboardTimeRemaining", SKATE_DURATION)
	setSkateboardAvailable(player, true)
	mountSkateboard(player)
end

skateToggle.OnServerEvent:Connect(function(player)
	if not player:GetAttribute("HasSkateboard") then return end
	if player:GetAttribute("SkateboardMounted") then
		dismountSkateboard(player)
	else
		mountSkateboard(player)
	end
end)

local function applySkateboardPrize(player)
	giveSkateboard(player)
	return "Skateboard! 3 minutes of ride time!"
end

local function watchSkateboardRespawn(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		player:SetAttribute("BallSpread", 0)
		player:SetAttribute("BallDamage", 0)
		if player:GetAttribute("HasSkateboard") and (player:GetAttribute("SkateboardTimeRemaining") or 0) > 0 then
			-- Respawn always mounts
			mountSkateboard(player)
		end
	end)
end

local function setupDefaultSkateboard(player)
	player:SetAttribute("SkateboardTimeRemaining", START_WITH_SKATEBOARD and SKATE_DURATION or 0)
	player:SetAttribute("HasSkateboard", START_WITH_SKATEBOARD)
	player:SetAttribute("SkateboardMounted", false)
	watchSkateboardRespawn(player)
	if START_WITH_SKATEBOARD and player.Character then
		task.defer(mountSkateboard, player)
	end
end

Players.PlayerAdded:Connect(setupDefaultSkateboard)
for _, player in Players:GetPlayers() do
	setupDefaultSkateboard(player)
end

task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(0.25)
		local now = os.clock()
		local dt = now - last
		last = now

		for _, player in Players:GetPlayers() do
			if player:GetAttribute("HasSkateboard") and player:GetAttribute("SkateboardMounted") then
				local remaining = math.max(0, (player:GetAttribute("SkateboardTimeRemaining") or 0) - dt)
				player:SetAttribute("SkateboardTimeRemaining", remaining)
				if remaining <= 0 then
					expireSkateboard(player)
				end
			end
		end
	end
end)

-- Sections are indexed 1-8, starting at top and going clockwise
local PRIZES = {
	{
		name = "Skateboard", color = "Bright orange", icon = "SK8", iconColor = Color3.fromRGB(255, 150, 45),
		apply = applySkateboardPrize,
	},
	{
		name = "Multi-Ball", color = "Bright blue", icon = "x3", iconColor = Color3.fromRGB(65, 170, 255),
		apply = function(p)
			p:SetAttribute("BallSpread", 1)
			return "Multi-Ball! Balls split x3!"
		end,
	},
	{
		name = "Skateboard", color = "Bright orange", icon = "SK8", iconColor = Color3.fromRGB(255, 150, 45),
		apply = applySkateboardPrize,
	},
	{
		name = "$5,000", color = "Bright yellow", icon = "$$$", iconColor = Color3.fromRGB(255, 225, 55),
		apply = function(p)
			grantCash(p, Balance.SpinWheel.CashPrize)
			return "$" .. tostring(Balance.SpinWheel.CashPrize) .. " Cash!"
		end,
	},
	{
		name = "Skateboard", color = "Bright orange", icon = "SK8", iconColor = Color3.fromRGB(255, 150, 45),
		apply = applySkateboardPrize,
	},
	{
		name = "Ball Damage", color = "Royal purple", icon = "DMG", iconColor = Color3.fromRGB(185, 95, 255),
		apply = function(p)
			local cur = p:GetAttribute("BallDamage") or 0
			p:SetAttribute("BallDamage", math.min(cur + 2, 3))
			return "Ball Damage! +2 Damage Tiers!"
		end,
	},
	{
		name = "Skateboard", color = "Bright orange", icon = "SK8", iconColor = Color3.fromRGB(255, 150, 45),
		apply = applySkateboardPrize,
	},
	{
		name = "JACKPOT!", color = "Cyan", icon = "WIN", iconColor = Color3.fromRGB(75, 240, 255),
		apply = function(p)
			grantCash(p, Balance.SpinWheel.JackpotCash)
			return "JACKPOT! $" .. tostring(Balance.SpinWheel.JackpotCash) .. " Cash!"
		end,
	},
}

-- =============================================
-- BUILD WHEEL
-- =============================================
local folder = Instance.new("Folder")
folder.Name   = "SpinWheel"
folder.Parent = workspace

local function part(name, sz, pos, color, mat)
	local p2 = Instance.new("Part")
	p2.Name        = name
	p2.Size        = sz
	p2.Position    = pos
	p2.Anchored    = true
	p2.BrickColor  = BrickColor.new(color)
	p2.Material    = mat or Enum.Material.SmoothPlastic
	p2.CastShadow  = false
	p2.TopSurface  = Enum.SurfaceType.Smooth
	p2.BottomSurface = Enum.SurfaceType.Smooth
	p2.Parent      = folder
	return p2
end

local function ballPart(name, size, pos, color, mat, transparency, canCollide)
	local p2 = part(name, size, pos, color, mat)
	p2.Shape = Enum.PartType.Ball
	p2.Transparency = transparency or 0
	p2.CanCollide = canCollide == true
	return p2
end

local function teleportPlayer(player, cf, order)
	player:SetAttribute("InLandingWorld", false)
	player:SetAttribute("LandingWorldCompleted", true)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local safeCF = SafeLevelSpawn.getCFrame(order, nil, cf)
	skyDescent(hrp, safeCF, SafeLevelSpawn.getBounds(order), STAGE_LAUNCH_DESCENT_SECONDS)
end

local function addStarterButton(name, labelText, position, color, callback)
	local pad = part(name .. "Pad", Vector3.new(16, 0.8, 14), position, color, Enum.Material.Neon)
	pad.Transparency = 0.1
	local button = part(name .. "Button", Vector3.new(10, 2.2, 8), position + Vector3.new(0, 1.5, 0), color, Enum.Material.Neon)
	local beacon = part(name .. "Beacon", Vector3.new(3, 62, 3), position + Vector3.new(0, 32, 0), color, Enum.Material.Neon)
	beacon.Transparency = 0.25
	beacon.CanCollide = false

	local sign = part(name .. "StaticSign", Vector3.new(19, 7, 0.55), position + Vector3.new(0, 8, -7), "Really black", Enum.Material.Metal)
	sign.CanCollide = false
	local signGlow = part(name .. "StaticSignGlow", Vector3.new(20.5, 8.3, 0.18), position + Vector3.new(0, 8, -6.65), color, Enum.Material.Neon)
	signGlow.Transparency = 0.7
	signGlow.CanCollide = false
	for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 36
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = sign
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 0
		text.BackgroundColor3 = Color3.fromRGB(8, 9, 12)
		text.Text = labelText
		text.TextColor3 = BrickColor.new(color).Color
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Color = BrickColor.new(color).Color
		stroke.Thickness = 6
		stroke.Parent = text
	end

	local debounce = {}
	local function fire(player)
		local now = os.clock()
		if debounce[player] and now - debounce[player] < 1 then return end
		debounce[player] = now
		callback(player)
	end

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 24
	click.Parent = button
	click.MouseClick:Connect(fire)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Press"
	prompt.ObjectText = labelText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.Parent = button
	prompt.Triggered:Connect(fire)
end

-- Prize stage on the floating starter world.
part("WheelStageTowerBase", Vector3.new(46, STAGE_LIFT, 40), Vector3.new(WX, G + STAGE_LIFT / 2, WZ), "Really black", Enum.Material.Metal)
part("WheelStageTowerGlowFront", Vector3.new(43, 0.45, 0.45), Vector3.new(WX, G + STAGE_LIFT - 0.15, WZ - 20.4), "Cyan", Enum.Material.Neon).Transparency = 0.18
part("WheelStageTowerGlowBack", Vector3.new(43, 0.45, 0.45), Vector3.new(WX, G + STAGE_LIFT - 0.15, WZ + 20.4), "Hot pink", Enum.Material.Neon).Transparency = 0.22
part("StarterWheelSpawnPad", Vector3.new(14, 0.5, 18), Vector3.new(WX - 35, G + 0.25, WZ), "Bright yellow", Enum.Material.Neon).Transparency = 0.55
part("StarterWheelSpawnPadCore", Vector3.new(10, 0.58, 14), Vector3.new(WX - 35, G + 0.32, WZ), "Cyan", Enum.Material.SmoothPlastic).Transparency = 0.18
addStarterButton("SpinWorldStartGame", "START GAME", Vector3.new(-16, G + 0.5, -728), "Lime green", function(player)
	teleportPlayer(player, CFrame.new(0, 7, 0))
end)
addStarterButton("SpinWorldTimeMachines", "TIME MACHINES", Vector3.new(16, G + 0.5, -728), "Bright yellow", function(player)
	teleportPlayer(player, CFrame.new(0, 7, -112))
end)
if IS_DEBUG_MODE and DEBUG_WORLD_LAUNCH_ENABLED then
	addStarterButton("SpinWorldDebugLauncher", "DEBUG LEVEL " .. tostring(DEBUG_WORLD_LAUNCH_ORDER), Vector3.new(0, G + 0.5, -712), "Really red", function(player)
		teleportPlayer(player, DEBUG_WORLD_LAUNCH_SPAWNS[DEBUG_WORLD_LAUNCH_ORDER] or DEBUG_WORLD_LAUNCH_SPAWNS[19], DEBUG_WORLD_LAUNCH_ORDER)
	end)
end
-- Walkway from playground edge (x≈59) all the way to stair base (x≈WX-40=38)
part("WheelGroundWalkwayFromPlayground", Vector3.new(48, 0.45, 20), Vector3.new(WX - 17, G + 0.22, WZ), "Dark stone grey", Enum.Material.DiamondPlate)
part("WheelGroundWalkwayGlowA", Vector3.new(48, 0.12, 0.35), Vector3.new(WX - 17, G + 0.52, WZ - 10.2), "Cyan", Enum.Material.Neon).Transparency = 0.34
part("WheelGroundWalkwayGlowB", Vector3.new(48, 0.12, 0.35), Vector3.new(WX - 17, G + 0.52, WZ + 10.2), "Hot pink", Enum.Material.Neon).Transparency = 0.42
part("WheelPlatform", Vector3.new(42, 1.2, 36), Vector3.new(WX, G + STAGE_LIFT + 0.6, WZ), "Really black", Enum.Material.DiamondPlate)
part("WheelPlatformTop", Vector3.new(39, 0.28, 33), Vector3.new(WX, G + STAGE_LIFT + 1.34, WZ), "Dark stone grey", Enum.Material.Metal)
local carpet = part("WheelStageCarpet", Vector3.new(22, 0.18, 16), Vector3.new(WX, G + STAGE_LIFT + 1.52, WZ - 3), "Bright red", Enum.Material.SmoothPlastic)
carpet.Transparency = 0.08
part("WheelStageCarpetTrimFront", Vector3.new(23, 0.22, 0.55), Vector3.new(WX, G + STAGE_LIFT + 1.72, WZ - 11.2), "Bright yellow", Enum.Material.Neon).Transparency = 0.08
part("WheelStageCarpetTrimBack", Vector3.new(23, 0.22, 0.55), Vector3.new(WX, G + STAGE_LIFT + 1.72, WZ + 5.2), "Bright yellow", Enum.Material.Neon).Transparency = 0.16
part("WheelStageCarpetTrimL", Vector3.new(0.55, 0.22, 16.2), Vector3.new(WX - 11.4, G + STAGE_LIFT + 1.72, WZ - 3), "Bright yellow", Enum.Material.Neon).Transparency = 0.16
part("WheelStageCarpetTrimR", Vector3.new(0.55, 0.22, 16.2), Vector3.new(WX + 11.4, G + STAGE_LIFT + 1.72, WZ - 3), "Bright yellow", Enum.Material.Neon).Transparency = 0.16
for z = WZ - 16, WZ + 16, 8 do
	part("WheelPlatformEdgeLight", Vector3.new(0.35, 0.32, 6), Vector3.new(WX - 20.7, G + STAGE_LIFT + 1.78, z), "Bright yellow", Enum.Material.Neon).Transparency = 0.2
	part("WheelPlatformEdgeLight", Vector3.new(0.35, 0.32, 6), Vector3.new(WX + 20.7, G + STAGE_LIFT + 1.78, z), "Bright yellow", Enum.Material.Neon).Transparency = 0.2
end
for x = WX - 18, WX + 18, 9 do
	part("WheelPlatformFrontLight", Vector3.new(6, 0.32, 0.35), Vector3.new(x, G + STAGE_LIFT + 1.78, WZ - 18.2), "Cyan", Enum.Material.Neon).Transparency = 0.22
	part("WheelPlatformBackLight", Vector3.new(6, 0.32, 0.35), Vector3.new(x, G + STAGE_LIFT + 1.78, WZ + 18.2), "Hot pink", Enum.Material.Neon).Transparency = 0.25
end

-- Prize-booth backdrop and canopy.
local backWall = part("WheelPrizeBackdrop", Vector3.new(36, 16, 0.7), Vector3.new(WX, G + STAGE_LIFT + 9.6, WZ + 8.4), "Really black", Enum.Material.Metal)
backWall.Transparency = 0.04
part("WheelPrizeBackdropGlow", Vector3.new(33, 12, 0.28), Vector3.new(WX, G + STAGE_LIFT + 9.7, WZ + 8.0), "Bright violet", Enum.Material.Neon).Transparency = 0.82
part("WheelCanopyTop", Vector3.new(40, 1.0, 13), Vector3.new(WX, G + STAGE_LIFT + 18.2, WZ + 1.9), "Really red", Enum.Material.Metal)
part("WheelCanopyLip", Vector3.new(41.5, 1.2, 1.0), Vector3.new(WX, G + STAGE_LIFT + 17.3, WZ - 5.0), "Bright yellow", Enum.Material.Neon).Transparency = 0.14
for x = WX - 18, WX + 18, 12 do
	part("WheelCanopyStripe", Vector3.new(4.6, 1.08, 13.2), Vector3.new(x, G + STAGE_LIFT + 18.35, WZ + 1.9), "Bright orange", Enum.Material.SmoothPlastic).Transparency = 0.02
	ballPart("WheelCanopyBulb", Vector3.new(0.9, 0.9, 0.9), Vector3.new(x, G + STAGE_LIFT + 16.45, WZ - 5.55), "New Yeller", Enum.Material.Neon, 0.04, false)
end
for _, x in { WX - 19, WX + 19 } do
	part("WheelStageColumn", Vector3.new(1.15, 22, 1.15), Vector3.new(x, G + STAGE_LIFT + 9.0, WZ + 2), "Dark stone grey", Enum.Material.Metal)
	part("WheelStageColumnGlow", Vector3.new(0.35, 21.8, 0.35), Vector3.new(x, G + STAGE_LIFT + 9.0, WZ - 4.7), "Cyan", Enum.Material.Neon).Transparency = 0.18
	ballPart("WheelColumnCap", Vector3.new(2.4, 2.4, 2.4), Vector3.new(x, G + STAGE_LIFT + 17.7, WZ + 2), "Bright yellow", Enum.Material.Neon, 0.18, false)
end
for _, x in { WX - 15.5, WX + 15.5 } do
	part("WheelPrizePedestal", Vector3.new(5, 1.1, 5), Vector3.new(x, G + STAGE_LIFT + 2.1, WZ - 4), "Really black", Enum.Material.Metal)
	ballPart("WheelPrizeOrb", Vector3.new(3.2, 3.2, 3.2), Vector3.new(x, G + STAGE_LIFT + 4.4, WZ - 4), x < WX and "Cyan" or "Hot pink", Enum.Material.Neon, 0.35, false)
end

-- Grand front staircase. Faces -X toward the playground (playground is at x≈0, wheel at x=78).
local stairCount = 12
for i = 0, stairCount - 1 do
	local alpha = (i + 1) / stairCount
	local stepX = WX - 40 + i * 1.9   -- descends toward -X (playground side)
	local stepY = G + alpha * (STAGE_LIFT + 1.35)
	local step = part("WheelFrontStair", Vector3.new(2.2, 0.42, 20), Vector3.new(stepX, stepY, WZ), "Smoky grey", Enum.Material.DiamondPlate)
	step.CanCollide = true
	part("WheelFrontStairLight", Vector3.new(0.35, 0.12, 18), Vector3.new(stepX - 1.0, stepY + 0.25, WZ), "Bright yellow", Enum.Material.Neon).Transparency = 0.18
end
part("WheelFrontStairLanding", Vector3.new(5, 0.5, 24), Vector3.new(WX - 18.5, G + STAGE_LIFT + 1.58, WZ), "Dark stone grey", Enum.Material.DiamondPlate)
part("WheelFrontStairRailL", Vector3.new(27, 0.45, 0.45), Vector3.new(WX - 29, G + STAGE_LIFT / 2 + 3.3, WZ - 11.5), "Cyan", Enum.Material.Neon).Transparency = 0.16
part("WheelFrontStairRailR", Vector3.new(27, 0.45, 0.45), Vector3.new(WX - 29, G + STAGE_LIFT / 2 + 3.3, WZ + 11.5), "Cyan", Enum.Material.Neon).Transparency = 0.16
for x = WX - 40, WX - 18, 5.5 do
	part("WheelFrontStairPostL", Vector3.new(0.45, 6.2, 0.45), Vector3.new(x, G + 3.2, WZ - 11.5), "Really black", Enum.Material.Metal)
	part("WheelFrontStairPostR", Vector3.new(0.45, 6.2, 0.45), Vector3.new(x, G + 3.2, WZ + 11.5), "Really black", Enum.Material.Metal)
end

-- Base pedestal and upright support
part("WheelBase",  Vector3.new(13, 0.65, 7.6), Vector3.new(WX, G + STAGE_LIFT + 1.88, WZ), "Really black", Enum.Material.Metal)
part("WheelPoleL", Vector3.new(0.85, 8.3, 0.85), Vector3.new(WX - 5.4, G + STAGE_LIFT + 5.3, WZ + 0.15), "Dark stone grey", Enum.Material.Metal)
part("WheelPoleR", Vector3.new(0.85, 8.3, 0.85), Vector3.new(WX + 5.4, G + STAGE_LIFT + 5.3, WZ + 0.15), "Dark stone grey", Enum.Material.Metal)
part("WheelCrossbar", Vector3.new(12.2, 0.6, 0.6), Vector3.new(WX, WY + 6.35, WZ + 0.15), "Dark stone grey", Enum.Material.Metal)
local wheelMount = part("WheelMount", Vector3.new(4.8, 4.8, 0.45), Vector3.new(WX, WY, WZ + 0.28), "Bright yellow", Enum.Material.Neon)
wheelMount.Transparency = 0.25

-- Invisible rotating anchor. Visual wheel pieces are welded to this vertical face.
local disk = Instance.new("Part")
disk.Name        = "WheelDisk"
disk.Size        = Vector3.new(12.6, 12.6, 0.45)
disk.CFrame      = CFrame.new(WX, WY, WZ)
disk.Anchored    = true
disk.BrickColor  = BrickColor.new("Dark stone grey")
disk.Material    = Enum.Material.SmoothPlastic
disk.Transparency = 1
disk.CanCollide  = false
disk.CastShadow  = false
disk.TopSurface  = Enum.SurfaceType.Smooth
disk.BottomSurface = Enum.SurfaceType.Smooth
disk.Parent      = folder

local function weldTo(anchor, child)
	local w = Instance.new("WeldConstraint")
	w.Part0  = anchor
	w.Part1  = child
	w.Parent = anchor
end

local function addGuiCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addGuiStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.Parent = parent
	return stroke
end

local function addPrizeBadge(sectionPart, prize)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PrizeBadge"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 38
	gui.CanvasSize = Vector2.new(112, 78)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = sectionPart

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 1, -8)
	card.Position = UDim2.new(0, 4, 0, 4)
	card.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	card.BackgroundTransparency = 0.02
	card.BorderSizePixel = 0
	card.Parent = gui
	addGuiCorner(card, 8)
	addGuiStroke(card, prize.iconColor, 2.2, 0.02)

	local iconBack = Instance.new("Frame")
	iconBack.Size = UDim2.new(0, 44, 0, 38)
	iconBack.Position = UDim2.new(0.5, -22, 0, 7)
	iconBack.BackgroundColor3 = prize.iconColor
	iconBack.BackgroundTransparency = 0.06
	iconBack.BorderSizePixel = 0
	iconBack.Parent = card
	addGuiCorner(iconBack, 7)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, -4, 1, -4)
	icon.Position = UDim2.new(0, 2, 0, 2)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBlack
	icon.TextScaled = true
	icon.TextColor3 = Color3.fromRGB(10, 10, 12)
	icon.TextStrokeTransparency = 1
	icon.Text = prize.icon
	icon.Parent = iconBack

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -10, 0, 24)
	name.Position = UDim2.new(0, 5, 0, 48)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.4
	name.Text = prize.name
	name.Parent = card
end

local plate = Instance.new("Part")
plate.Name       = "VerticalWheelPlate"
plate.Shape      = Enum.PartType.Cylinder
plate.Size       = Vector3.new(0.45, 12.9, 12.9)
plate.CFrame     = CFrame.new(WX, WY, WZ) * CFrame.Angles(0, math.rad(90), 0)
plate.Anchored   = false
plate.BrickColor = BrickColor.new("Really black")
plate.Material   = Enum.Material.SmoothPlastic
plate.CastShadow = false
plate.Parent     = folder
weldTo(disk, plate)

local glowPlate = Instance.new("Part")
glowPlate.Name         = "WheelUnderGlow"
glowPlate.Shape        = Enum.PartType.Cylinder
glowPlate.Size         = Vector3.new(0.2, 13.8, 13.8)
glowPlate.CFrame       = CFrame.new(WX, WY, WZ - 0.18) * CFrame.Angles(0, math.rad(90), 0)
glowPlate.Anchored     = false
glowPlate.BrickColor   = BrickColor.new("Bright yellow")
glowPlate.Material     = Enum.Material.Neon
glowPlate.Transparency = 0.55
glowPlate.CastShadow   = false
glowPlate.Parent       = folder
weldTo(disk, glowPlate)

local faceGlow = Instance.new("Part")
faceGlow.Name         = "WheelFaceGlow"
faceGlow.Shape        = Enum.PartType.Cylinder
faceGlow.Size         = Vector3.new(0.12, 12.1, 12.1)
faceGlow.CFrame       = CFrame.new(WX, WY, WZ - 0.46) * CFrame.Angles(0, math.rad(90), 0)
faceGlow.Anchored     = false
faceGlow.BrickColor   = BrickColor.new("Cyan")
faceGlow.Material     = Enum.Material.Neon
faceGlow.Transparency = 0.88
faceGlow.CanCollide   = false
faceGlow.CastShadow   = false
faceGlow.Parent       = folder
weldTo(disk, faceGlow)

for i = 0, 15 do
	local angle = math.rad(i * 22.5)
	local sx = WX + math.sin(angle) * 2.7
	local sy = WY + math.cos(angle) * 2.7
	local spoke = Instance.new("Part")
	spoke.Name = "WheelGoldSpoke"
	spoke.Size = Vector3.new(0.18, 5.8, 0.16)
	spoke.CFrame = CFrame.new(sx, sy, WZ - 0.62) * CFrame.Angles(0, 0, -angle)
	spoke.Anchored = false
	spoke.BrickColor = BrickColor.new(i % 2 == 0 and "Bright yellow" or "Cyan")
	spoke.Material = Enum.Material.Neon
	spoke.Transparency = 0.62
	spoke.CanCollide = false
	spoke.CastShadow = false
	spoke.Parent = folder
	weldTo(disk, spoke)
end

-- 8 colored prize sections (radially arranged on disk face)
local SEC_R = 3.05   -- center radius of each section
for i = 0, 7 do
	local angle = math.rad(i * 45)          -- clockwise from top
	local sx = WX + math.sin(angle) * SEC_R
	local sy = WY + math.cos(angle) * SEC_R

	local sec = Instance.new("Part")
	sec.Name        = "Sec" .. (i + 1)
	sec.Size        = Vector3.new(2.2, 5.55, 0.18)
	sec.CFrame      = CFrame.new(sx, sy, WZ - 0.28) * CFrame.Angles(0, 0, -angle)
	sec.Anchored    = false
	sec.BrickColor  = BrickColor.new(PRIZES[i + 1].color)
	sec.Material    = Enum.Material.SmoothPlastic
	sec.Transparency = 0
	sec.CastShadow  = false
	sec.Parent      = folder
	weldTo(disk, sec)

	local shine = Instance.new("Part")
	shine.Name = "PrizeSectionShine"
	shine.Size = Vector3.new(0.18, 5.15, 0.08)
	shine.CFrame = CFrame.new(sx - math.sin(angle) * 0.52, sy - math.cos(angle) * 0.52, WZ - 0.48) * CFrame.Angles(0, 0, -angle)
	shine.Anchored = false
	shine.BrickColor = BrickColor.new("White")
	shine.Material = Enum.Material.Neon
	shine.Transparency = 0.64
	shine.CanCollide = false
	shine.CastShadow = false
	shine.Parent = folder
	weldTo(disk, shine)

	-- Prize name label (BillboardGui faces camera regardless of spin – readable at all angles)
	local bb = Instance.new("BillboardGui")
	bb.Enabled     = false
	bb.Size        = UDim2.new(0, 95, 0, 22)
	bb.StudsOffset = Vector3.new(0, 0, -0.3)
	bb.AlwaysOnTop = false
	bb.Parent      = sec
	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = PRIZES[i + 1].name
	lbl.TextColor3             = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextScaled             = true
	lbl.Parent                 = bb
	addPrizeBadge(sec, PRIZES[i + 1])
end

-- 8 dividers between sections
local DIV_R = 3.15
for i = 0, 7 do
	local angle = math.rad(i * 45 + 22.5)
	local dx = WX + math.sin(angle) * DIV_R
	local dy = WY + math.cos(angle) * DIV_R

	local div = Instance.new("Part")
	div.Name       = "Div"
	div.Size       = Vector3.new(0.14, 6.75, 0.26)
	div.CFrame     = CFrame.new(dx, dy, WZ - 0.18) * CFrame.Angles(0, 0, -angle)
	div.Anchored   = false
	div.BrickColor = BrickColor.new("Black")
	div.Material   = Enum.Material.Neon
	div.Transparency = 0.1
	div.CastShadow = false
	div.Parent     = folder
	weldTo(disk, div)
end

-- Perimeter bulbs make the vertical wheel read like a carnival prize wheel.
for i = 0, 23 do
	local angle = math.rad(i * 15)
	local bx = WX + math.sin(angle) * 6.55
	local by = WY + math.cos(angle) * 6.55
	local bulb = Instance.new("Part")
	bulb.Name = "RimBulb"
	bulb.Shape = Enum.PartType.Ball
	bulb.Size = Vector3.new(0.52, 0.52, 0.52)
	bulb.CFrame = CFrame.new(bx, by, WZ - 0.55)
	bulb.Anchored = false
	bulb.BrickColor = (i % 2 == 0) and BrickColor.new("Bright yellow") or BrickColor.new("White")
	bulb.Material = Enum.Material.Neon
	bulb.CastShadow = false
	bulb.Parent = folder
	weldTo(disk, bulb)
end

for i = 0, 23 do
	local angle = math.rad(i * 15 + 7.5)
	local bx = WX + math.sin(angle) * 5.95
	local by = WY + math.cos(angle) * 5.95
	local bulb = Instance.new("Part")
	bulb.Name = "InnerRimBulb"
	bulb.Shape = Enum.PartType.Ball
	bulb.Size = Vector3.new(0.28, 0.28, 0.28)
	bulb.CFrame = CFrame.new(bx, by, WZ - 0.64)
	bulb.Anchored = false
	bulb.BrickColor = (i % 2 == 0) and BrickColor.new("Cyan") or BrickColor.new("Hot pink")
	bulb.Material = Enum.Material.Neon
	bulb.Transparency = 0.1
	bulb.CastShadow = false
	bulb.Parent = folder
	weldTo(disk, bulb)
end

-- Center hub (neon peg)
local hub = Instance.new("Part")
hub.Shape      = Enum.PartType.Cylinder
hub.Size       = Vector3.new(0.75, 2.45, 2.45)
hub.CFrame     = CFrame.new(WX, WY, WZ - 0.62) * CFrame.Angles(0, math.rad(90), 0)
hub.Anchored   = false
hub.BrickColor = BrickColor.new("Bright red")
hub.Material   = Enum.Material.Neon
hub.CastShadow = false
hub.Parent     = folder
weldTo(disk, hub)

local hubGem = Instance.new("Part")
hubGem.Shape = Enum.PartType.Ball
hubGem.Name = "WheelHubGem"
hubGem.Size = Vector3.new(1.25, 1.25, 1.25)
hubGem.CFrame = CFrame.new(WX, WY, WZ - 1.02)
hubGem.Anchored = false
hubGem.BrickColor = BrickColor.new("Cyan")
hubGem.Material = Enum.Material.Neon
hubGem.Transparency = 0.05
hubGem.CastShadow = false
hubGem.Parent = folder
weldTo(disk, hubGem)

-- Outer neon rim
local rim = Instance.new("Part")
rim.Shape      = Enum.PartType.Cylinder
rim.Size       = Vector3.new(0.35, 13.35, 13.35)
rim.CFrame     = CFrame.new(WX, WY, WZ - 0.42) * CFrame.Angles(0, math.rad(90), 0)
rim.Anchored   = false
rim.BrickColor = BrickColor.new("Bright yellow")
rim.Material   = Enum.Material.Neon
rim.Transparency = 0.72
rim.CastShadow = false
rim.CanCollide = false
rim.Parent     = folder
weldTo(disk, rim)

-- Fixed pointer at the top of the vertical wheel.
local ptr = Instance.new("WedgePart")
ptr.Size       = Vector3.new(1.4, 0.8, 2.0)
ptr.CFrame     = CFrame.new(WX, WY + 7.35, WZ - 0.65) * CFrame.Angles(math.rad(90), 0, math.rad(180))
ptr.Anchored   = true
ptr.BrickColor = BrickColor.new("Bright red")
ptr.Material   = Enum.Material.Neon
ptr.CastShadow = false
ptr.Parent     = folder

local ptrGlow = Instance.new("WedgePart")
ptrGlow.Name = "PointerGlow"
ptrGlow.Size = Vector3.new(2.2, 1.1, 2.7)
ptrGlow.CFrame = CFrame.new(WX, WY + 7.3, WZ - 0.86) * CFrame.Angles(math.rad(90), 0, math.rad(180))
ptrGlow.Anchored = true
ptrGlow.BrickColor = BrickColor.new("New Yeller")
ptrGlow.Material = Enum.Material.Neon
ptrGlow.Transparency = 0.42
ptrGlow.CastShadow = false
ptrGlow.Parent = folder

part("PtrPost", Vector3.new(0.45, 2.8, 0.45), Vector3.new(WX, WY + 7.45, WZ + 0.15),
	"Dark stone grey", Enum.Material.Metal)

-- Sign above wheel
local signPost = part("SignPost", Vector3.new(0.4, 5.2, 0.4),
	Vector3.new(WX - 7.2, G + 7.0, WZ + 0.3), "Dark stone grey", Enum.Material.Metal)

local signPart = part("SpinWheelSign", Vector3.new(10, 2.2, 0.3),
	Vector3.new(WX, WY + 8.7, WZ - 0.7), "Really black")
part("SpinWheelSignTopGlow", Vector3.new(10.8, 0.28, 0.38), Vector3.new(WX, WY + 9.98, WZ - 0.88), "Bright yellow", Enum.Material.Neon).Transparency = 0.1
part("SpinWheelSignBottomGlow", Vector3.new(10.8, 0.28, 0.38), Vector3.new(WX, WY + 7.42, WZ - 0.88), "Hot pink", Enum.Material.Neon).Transparency = 0.18
local signBb = Instance.new("BillboardGui")
signBb.Size        = UDim2.new(0, 340, 0, 78)
signBb.StudsOffset = Vector3.new(0, 0, 0)
signBb.Parent      = signPart
local signLbl = Instance.new("TextLabel")
signLbl.Size                   = UDim2.new(1, 0, 1, 0)
signLbl.BackgroundTransparency = 1
signLbl.Text                   = "SPIN WHEEL"
signLbl.TextColor3             = Color3.fromRGB(255, 210, 0)
signLbl.TextStrokeTransparency = 0
signLbl.Font                   = Enum.Font.GothamBlack
signLbl.TextScaled             = true
signLbl.Parent                 = signBb

local subLbl = Instance.new("TextLabel")
subLbl.Size                   = UDim2.new(1, 0, 0.35, 0)
subLbl.Position               = UDim2.new(0, 0, 0.65, 0)
subLbl.BackgroundTransparency = 1
subLbl.Text                   = "Press E to spin! (10 sec cooldown)"
subLbl.TextColor3             = Color3.fromRGB(180, 180, 180)
subLbl.Font                   = Enum.Font.Gotham
subLbl.TextScaled             = true
subLbl.Parent                 = signBb

-- Invisible trigger part for ProximityPrompt
local trigger = Instance.new("Part")
trigger.Name        = "WheelTrigger"
trigger.Size        = Vector3.new(12, 6, 10)
trigger.Position    = Vector3.new(WX, G + STAGE_LIFT + 4, WZ - 8)
trigger.Anchored    = true
trigger.Transparency = 1
trigger.CanCollide  = false
trigger.Parent      = folder

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText            = "SPIN!"
prompt.ObjectText            = "Spin Wheel"
prompt.KeyboardKeyCode       = Enum.KeyCode.E
prompt.MaxActivationDistance = 12
prompt.RequiresLineOfSight   = false
prompt.Parent                = trigger

-- =============================================
-- SPIN LOGIC
-- =============================================
local isSpinning    = false
local spinCooldowns = {}  -- [player] = os.time() of last spin
local COOLDOWN      = Balance.SpinWheel.CooldownSeconds

local function doSpin(prizeIndex)
	-- Rotate so section prizeIndex ends at south (the pointer)
	-- Section i starts at angle (i-1)*45° CW from south
	-- Needed CCW rotation = (360 - (prizeIndex-1)*45) % 360
	local R          = (360 - (prizeIndex - 1) * 45) % 360
	local totalAngle = 5 * 360 + R   -- add 5 full spins for drama

	local duration = 4.0
	local elapsed  = 0
	local startCF  = disk.CFrame

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local t  = math.min(elapsed / duration, 1)
		local et = 1 - (1 - t)^3  -- cubic ease-out deceleration
		disk.CFrame = startCF * CFrame.Angles(0, 0, math.rad(et * totalAngle))
		if t >= 1 then
			conn:Disconnect()
			isSpinning = false
		end
	end)
end

prompt.Triggered:Connect(function(player)
	if isSpinning then return end

	local now     = os.time()
	local last    = spinCooldowns[player] or 0
	local elapsed = now - last

	if elapsed < COOLDOWN then
		local rem  = COOLDOWN - elapsed
		local mins = math.floor(rem / 60)
		local secs = rem % 60
		spinResult:FireClient(player, nil,
			string.format("Come back in %d:%02d!", mins, secs))
		return
	end

	local prizeIndex = math.random(1, #PRIZES)
	local prize      = PRIZES[prizeIndex]

	spinCooldowns[player] = now
	isSpinning            = true

	-- Apply prize and notify client after spin finishes
	task.delay(4.3, function()
		if not player or not player.Parent then return end
		local msg = prize.apply(player)
		spinResult:FireClient(player, {
			name = prize.name,
			color = prize.color,
			icon = prize.icon,
			iconColor = prize.iconColor,
		}, msg)
	end)

	doSpin(prizeIndex)
end)

Players.PlayerRemoving:Connect(function(player)
	spinCooldowns[player] = nil
end)

print("[SpinWheel] Built at (", WX, ",", WZ, ")")
