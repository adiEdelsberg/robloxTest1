-- BridgeEffect.client.luau
-- When a level finishes, pulses the bridge leading to the next world with
-- blinking neon, a glowing floor, traveling sparkles, and a floating beacon.
-- All effects are local-only (no server replication).

local Players      = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Map world name (from WorldRunDoors) → bridge name (from BridgeChasm)
local WORLD_TO_BRIDGE = {
	["Playground"]          = "PlaygroundPizza",
	["Pizza"]               = "PizzaGalactic",
	["Galactic"]            = "GalacticJungle",
	["Jungle"]              = "JungleSports",
	["Sports"]              = "SportsTennis",
	["Tennis"]              = "TennisGameStation",
	["Game Station"]        = "GameStationCoffee",
	["Coffee Shop"]         = "CoffeeBurger",
	["Burger House"]        = "BurgerNewPizza",
	["New Pizza Place"]     = "NewPizzaPool",
	["Swimming Pool"]       = "PoolDinoPark",
	["Dinosaur Park"]       = "DinoParkBeach",
	["Dino Beach"]          = "BeachForest",
	["Flying Dino Forest"]  = "ForestCherry",
	["Cherry Grove"]        = "CherryOrchard",
	["Hourglass Vault"]     = "HourglassMovementLab",
	["Movement Lab"]        = "MovementLabFightArena",
	["Fight Arena"]         = "FightArenaEmpty43",
	-- "Galactic Orchard" has no next bridge
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function lerp(a, b, t) return a + (b - a) * t end

local function lerpColor(c1, c2, t)
	return Color3.new(
		lerp(c1.R, c2.R, t),
		lerp(c1.G, c2.G, t),
		lerp(c1.B, c2.B, t)
	)
end

local function makeLocalPart(size, cf, color, mat, trans)
	local p = Instance.new("Part")
	p.Size        = size
	p.CFrame      = cf
	p.Color       = color
	p.Material    = mat or Enum.Material.Neon
	p.Transparency = trans or 0
	p.Anchored    = true
	p.CanCollide  = false
	p.CastShadow  = false
	p.Parent      = workspace
	return p
end

-- ── Active-effect state ───────────────────────────────────────────────────────

local stopEffect = function() end   -- overwritten each time an effect starts

local function clearEffect()
	stopEffect()
	stopEffect = function() end
end

-- ── Main effect builder ───────────────────────────────────────────────────────

local function startBridgeEffect(bridgeName, duration)
	clearEffect()

	-- Wait for BridgeChasm folder
	local bridgeFolder = workspace:WaitForChild("BridgeChasm", 10)
	if not bridgeFolder then return end
	local metaFolder = bridgeFolder:FindFirstChild("BridgeMeta")

	-- Gather tagged parts
	local neonParts   = {}   -- pulsing neon
	local floorParts  = {}   -- SmoothPlastic floors (for SelectionBox)
	local origTrans   = {}   -- original LocalTransparencyModifier per neon part

	for _, part in bridgeFolder:GetChildren() do
		if not part:IsA("BasePart") then continue end
		if part:GetAttribute("BridgeName") ~= bridgeName then continue end
		if part.Material == Enum.Material.Neon then
			table.insert(neonParts, part)
			origTrans[part] = part.LocalTransparencyModifier
		elseif part.Material == Enum.Material.SmoothPlastic then
			table.insert(floorParts, part)
		end
	end
	if #neonParts == 0 then return end

	-- Bridge centre & axis from metadata
	local bridgeCF   = CFrame.new(0, 5, 0)
	local bridgeAxis = "Z"
	if metaFolder then
		local meta = metaFolder:FindFirstChild(bridgeName)
		if meta then
			bridgeCF   = meta.Value
			bridgeAxis = meta:GetAttribute("Axis") or "Z"
		end
	end
	local centerPos = bridgeCF.Position

	-- ── 1. SelectionBox glow on floor parts ─────────────────────────────────
	local selBoxes = {}
	for _, fp in floorParts do
		local sel = Instance.new("SelectionBox")
		sel.Adornee            = fp
		sel.Color3             = Color3.fromRGB(255, 240, 80)
		sel.LineThickness      = 0.10
		sel.SurfaceTransparency = 0.78
		sel.Parent             = fp
		table.insert(selBoxes, sel)
	end

	-- ── 2. Floating beacon above bridge centre ───────────────────────────────
	local beaconAnchor = makeLocalPart(
		Vector3.new(0.1, 0.1, 0.1),
		CFrame.new(centerPos + Vector3.new(0, 14, 0)),
		Color3.new(1,1,1), Enum.Material.SmoothPlastic, 1)

	local beaconGui = Instance.new("BillboardGui")
	beaconGui.Size         = UDim2.new(0, 220, 0, 64)
	beaconGui.StudsOffset  = Vector3.new(0, 0, 0)
	beaconGui.AlwaysOnTop  = false
	beaconGui.Parent       = beaconAnchor

	local beaconBg = Instance.new("Frame")
	beaconBg.Size                  = UDim2.new(1, 0, 1, 0)
	beaconBg.BackgroundColor3      = Color3.fromRGB(5, 15, 5)
	beaconBg.BackgroundTransparency = 0.15
	beaconBg.BorderSizePixel       = 0
	beaconBg.Parent                = beaconGui
	Instance.new("UICorner", beaconBg).CornerRadius = UDim.new(0, 12)
	local beaconStroke = Instance.new("UIStroke")
	beaconStroke.Color       = Color3.fromRGB(80, 255, 120)
	beaconStroke.Thickness   = 2.5
	beaconStroke.Transparency = 0.05
	beaconStroke.Parent      = beaconBg

	local beaconLabel = Instance.new("TextLabel")
	beaconLabel.Size                  = UDim2.new(1, -12, 0.6, 0)
	beaconLabel.Position              = UDim2.new(0, 6, 0, 4)
	beaconLabel.BackgroundTransparency = 1
	beaconLabel.Text                  = "NEXT LEVEL ▶"
	beaconLabel.TextScaled            = true
	beaconLabel.Font                  = Enum.Font.GothamBlack
	beaconLabel.TextColor3            = Color3.fromRGB(100, 255, 130)
	beaconLabel.TextStrokeTransparency = 0.35
	beaconLabel.Parent                = beaconBg

	local beaconSub = Instance.new("TextLabel")
	beaconSub.Size                  = UDim2.new(1, -12, 0.35, 0)
	beaconSub.Position              = UDim2.new(0, 6, 0.62, 0)
	beaconSub.BackgroundTransparency = 1
	beaconSub.Text                  = "Cross the bridge!"
	beaconSub.TextScaled            = true
	beaconSub.Font                  = Enum.Font.GothamMedium
	beaconSub.TextColor3            = Color3.fromRGB(200, 255, 210)
	beaconSub.TextStrokeTransparency = 0.55
	beaconSub.Parent                = beaconBg

	-- ── 3. Traveling sparkle orbs along the bridge ───────────────────────────
	local NUM_SPARKS = 6
	local sparks = {}
	-- Find the bridge length along its axis for sparkle travel
	local bridgeLen = 80   -- rough default; actual length varies
	for _, part in floorParts do
		local s = part.Size
		local candidate = bridgeAxis == "Z" and s.Z or s.X
		if candidate > bridgeLen then bridgeLen = candidate end
	end

	for i = 1, NUM_SPARKS do
		local sz = math.random(6, 12) * 0.1   -- 0.6 – 1.2 studs
		local spark = makeLocalPart(
			Vector3.new(sz, sz, sz),
			CFrame.new(centerPos),
			Color3.fromRGB(120 + math.random(0, 135), 255, 120 + math.random(0, 135)),
			Enum.Material.Neon, 0.15)
		spark.Shape = Enum.PartType.Ball
		sparks[i] = {
			part   = spark,
			phase  = (i - 1) / NUM_SPARKS,   -- 0..1, staggered
			speed  = 0.18 + math.random() * 0.12,
			height = 1.5 + math.random() * 2.5,
			side   = (math.random() < 0.5) and -1 or 1,
		}
	end

	-- ── 4. Per-frame animation loop ──────────────────────────────────────────
	local startTime = os.clock()
	local endTime   = startTime + duration

	local heartbeat = RunService.Heartbeat:Connect(function()
		local now     = os.clock()
		local elapsed = now - startTime
		local frac    = math.clamp((endTime - now) / duration, 0, 1)  -- 1→0

		-- Pulse speed & intensity ramp up as time runs out
		local speed     = 2.5 + (1 - frac) * 9
		local pulse     = 0.5 + 0.5 * math.sin(elapsed * speed)
		local flashBoost = (frac < 0.25) and (math.sin(elapsed * 22) * 0.5 + 0.5) or 0

		-- Neon part pulse: dim ↔ bright, colour-shift between bridge colour and white
		local colA = Color3.fromRGB(255, 240, 80)
		local colB = Color3.fromRGB(80, 255, 200)
		local currentCol = lerpColor(colA, colB, pulse)
		for _, part in neonParts do
			part.LocalTransparencyModifier = math.max(0, pulse * 0.85 - flashBoost * 0.6)
		end

		-- SelectionBox colour cycles
		for _, sel in selBoxes do
			sel.Color3 = currentCol
			sel.LineThickness = 0.08 + pulse * 0.10
		end

		-- Beacon bob & text colour
		if beaconAnchor and beaconAnchor.Parent then
			local bob = math.sin(elapsed * 2.4) * 1.2
			beaconAnchor.CFrame = CFrame.new(centerPos + Vector3.new(0, 14 + bob, 0))
			beaconStroke.Color  = lerpColor(
				Color3.fromRGB(80, 255, 120),
				Color3.fromRGB(255, 230, 60),
				pulse)
			beaconLabel.TextColor3 = lerpColor(
				Color3.fromRGB(100, 255, 130),
				Color3.fromRGB(255, 255, 100),
				pulse)
		end

		-- Sparkle travel along bridge axis
		for _, s in sparks do
			local t = ((elapsed * s.speed + s.phase) % 1)   -- 0→1 along bridge
			local along = (t - 0.5) * bridgeLen              -- -len/2 → +len/2
			local sideOff = s.side * (bridgeAxis == "Z" and 6 or 14)
			local yBounce = math.abs(math.sin(t * math.pi)) * s.height + 2

			local pos
			if bridgeAxis == "Z" then
				pos = Vector3.new(sideOff, centerPos.Y + yBounce, centerPos.Z + along)
			else
				pos = Vector3.new(centerPos.X + along, centerPos.Y + yBounce, sideOff + 1700)
			end
			s.part.CFrame = CFrame.new(pos)
			-- Fade in/out at bridge ends
			local edgeFade = math.sin(t * math.pi)
			s.part.LocalTransparencyModifier = math.max(0, 1 - edgeFade * (0.9 - pulse * 0.4))
		end
	end)

	-- ── Cleanup closure ───────────────────────────────────────────────────────
	stopEffect = function()
		heartbeat:Disconnect()
		-- Restore neon parts
		for part, orig in origTrans do
			part.LocalTransparencyModifier = orig
		end
		-- Remove SelectionBoxes
		for _, sel in selBoxes do
			pcall(function() sel:Destroy() end)
		end
		-- Remove local parts
		if beaconAnchor and beaconAnchor.Parent then beaconAnchor:Destroy() end
		for _, s in sparks do
			if s.part and s.part.Parent then s.part:Destroy() end
		end
	end

	-- Auto-stop when grace ends
	task.delay(duration + 0.5, clearEffect)
end

-- ── Listen for level-complete events ─────────────────────────────────────────

task.spawn(function()
	local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end
	local graceEvent = gameEvents:WaitForChild("LevelGraceCountdown", 30)
	if not graceEvent then return end

	graceEvent.OnClientEvent:Connect(function(worldName, seconds)
		local bridgeName = WORLD_TO_BRIDGE[worldName]
		if not bridgeName then
			clearEffect()  -- last level, nothing to highlight
			return
		end
		startBridgeEffect(bridgeName, seconds)
	end)
end)
