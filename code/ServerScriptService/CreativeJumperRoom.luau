-- CreativeJumperRoom.luau
-- Shared builder for easy one-hit jumper rooms. Each room has a distinct
-- visible shell shape, forgiving helper pads, and a top finish platform.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local CreativeJumperRoom = {}

local function getOrCreateNumber(parent, name)
	local value = parent and parent:FindFirstChild(name)
	if not value then
		value = Instance.new("NumberValue")
		value.Name = name
		value.Value = 0
		value.Parent = parent or ReplicatedStorage
	end
	return value
end

local function formatFolderName(name)
	return name:gsub("%s+", "") .. "World"
end

local function launchPlayer(player, velocity, duration)
	if player:GetAttribute("SkyDescentBoundsActive") then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local bv = Instance.new("BodyVelocity")
	bv.Name = "CreativeJumperLaunch"
	bv.Velocity = velocity
	bv.MaxForce = Vector3.new(
		math.abs(velocity.X) > 0.1 and 1e5 or 0,
		1e5,
		math.abs(velocity.Z) > 0.1 and 1e5 or 0
	)
	bv.P = 1e4
	bv.Parent = hrp
	Debris:AddItem(bv, duration or 0.24)
end

local function buildSurfaceLabel(parent, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 26
	gui.LightInfluence = 0
	gui.Parent = parent

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	bg.BackgroundTransparency = 0.08
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0.62, 0)
	title.Position = UDim2.new(0, 6, 0.06, 0)
	title.BackgroundTransparency = 1
	title.Text = text
	title.TextColor3 = color
	title.TextStrokeTransparency = 0.25
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = bg

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0.25, 0)
	sub.Position = UDim2.new(0, 6, 0.7, 0)
	sub.BackgroundTransparency = 1
	sub.Text = "REACH THE TOP"
	sub.TextColor3 = Color3.fromRGB(235, 245, 255)
	sub.TextStrokeTransparency = 0.45
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.Parent = bg
end

local function buildBigRoomNumber(parent, order, worldName, color, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 10
	gui.LightInfluence = 0
	gui.Parent = parent

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(3, 6, 16)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	for i = 0, 8 do
		local streak = Instance.new("Frame")
		streak.Size = UDim2.new(0, 7, 2.1, 0)
		streak.Position = UDim2.new(0, i * 90 - 50, -0.55, 0)
		streak.Rotation = -18
		streak.BackgroundColor3 = color
		streak.BackgroundTransparency = 0.82
		streak.BorderSizePixel = 0
		streak.Parent = bg
	end

	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(0.64, 0, 0.055, 0)
	tag.Position = UDim2.new(0.18, 0, 0.055, 0)
	tag.BackgroundTransparency = 1
	tag.Text = "W O R L D"
	tag.TextColor3 = color
	tag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tag.TextStrokeTransparency = 0.25
	tag.Font = Enum.Font.GothamBold
	tag.TextScaled = true
	tag.Parent = bg

	local number = Instance.new("TextLabel")
	number.Size = UDim2.new(1, 0, 0.88, 0)
	number.Position = UDim2.new(0, 0, 0.09, 0)
	number.BackgroundTransparency = 1
	number.Text = tostring(order or "?")
	number.TextColor3 = color
	number.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	number.TextStrokeTransparency = 0
	number.Font = Enum.Font.GothamBlack
	number.TextScaled = true
	number.Parent = bg

	local numberStroke = Instance.new("UIStroke")
	numberStroke.Color = Color3.fromRGB(255, 255, 255)
	numberStroke.Thickness = 5
	numberStroke.Transparency = 0.15
	numberStroke.Parent = number

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(0.82, 0, 0.012, 0)
	divider.Position = UDim2.new(0.09, 0, 0.925, 0)
	divider.BackgroundColor3 = color
	divider.BorderSizePixel = 0
	divider.Parent = bg

	local footer = Instance.new("TextLabel")
	footer.Size = UDim2.new(0.9, 0, 0.055, 0)
	footer.Position = UDim2.new(0.05, 0, 0.935, 0)
	footer.BackgroundTransparency = 1
	footer.Text = string.upper(worldName or "")
	footer.TextColor3 = Color3.fromRGB(235, 245, 255)
	footer.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	footer.TextStrokeTransparency = 0.35
	footer.Font = Enum.Font.GothamBlack
	footer.TextScaled = true
	footer.Parent = bg
end

function CreativeJumperRoom.start(config)
	local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))
	if not config.allowUnlisted and not WorldOrder.getOrder(config.name) then
		warn(string.format("[CreativeJumperRoom] %s is not in WorldOrderConfig; skipping build.", tostring(config.name)))
		return
	end

	local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
	local remValue = getOrCreateNumber(gameEvents, config.remainingName)
	local totalValue = getOrCreateNumber(gameEvents, config.totalName)
	local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
	local target = (Balance.StageTargets and Balance.StageTargets[config.targetKey]) or 1

	local playerScored
	task.spawn(function()
		playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30)
	end)

	local worldFolder = nil
	local alive = false
	local activeConns = {}
	local padDebounce = {}
	local finishDebounce = {}

	local cx = config.cx
	local cz = config.cz
	local floorY = config.floorY or 1
	local hw = config.hw or 64
	local hd = config.hd or 64
	local wallH = config.wallH or 132
	local topY = floorY + wallH - 9
	local primary = config.primary or "Cyan"
	local secondary = config.secondary or "Bright yellow"
	local accent = config.accent or "Institutional white"

	local function addConn(conn)
		table.insert(activeConns, conn)
		return conn
	end

	local function part(name, size, cfOrPos, color, material, transparency, noCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		if typeof(cfOrPos) == "CFrame" then
			p.CFrame = cfOrPos
		else
			p.Position = cfOrPos
		end
		p.BrickColor = BrickColor.new(color)
		p.Material = material or Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		p.Anchored = true
		p.CanCollide = noCollide ~= true
		p.CanTouch = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = worldFolder
		return p
	end

	local function neon(name, size, cfOrPos, color, transparency, noCollide)
		return part(name, size, cfOrPos, color, Enum.Material.Neon, transparency or 0.08, noCollide ~= false)
	end

	local function ball(name, size, pos, color, transparency)
		local p = neon(name, Vector3.one * size, pos, color, transparency or 0.08, true)
		p.Shape = Enum.PartType.Ball
		return p
	end

	local function shellPanel(name, a, b)
		local dx = b.X - a.X
		local dz = b.Y - a.Y
		local len = math.sqrt(dx * dx + dz * dz)
		if len < 1 then return end
		local midX = cx + (a.X + b.X) / 2
		local midZ = cz + (a.Y + b.Y) / 2
		local angle = math.atan2(dx, dz)
		local panel = part(name, Vector3.new(0.7, wallH, len), CFrame.new(midX, floorY + wallH / 2, midZ) * CFrame.Angles(0, angle, 0), primary, Enum.Material.Glass, 0.58, true)
		neon(name .. "Edge", Vector3.new(1.2, wallH + 4, 1.2), Vector3.new(cx + a.X, floorY + wallH / 2, cz + a.Y), secondary, 0.18, true)
		return panel
	end

	local function shapePoints(shape)
		if shape == "diamond" then
			return { Vector2.new(0, -hd), Vector2.new(hw, 0), Vector2.new(0, hd), Vector2.new(-hw, 0) }
		elseif shape == "triangle" then
			return { Vector2.new(0, -hd), Vector2.new(hw, hd), Vector2.new(-hw, hd) }
		elseif shape == "hex" then
			local points = {}
			for i = 0, 5 do
				local a = math.rad(30 + i * 60)
				table.insert(points, Vector2.new(math.cos(a) * hw, math.sin(a) * hd))
			end
			return points
		elseif shape == "octagon" then
			local points = {}
			for i = 0, 7 do
				local a = math.rad(22.5 + i * 45)
				table.insert(points, Vector2.new(math.cos(a) * hw, math.sin(a) * hd))
			end
			return points
		elseif shape == "hourglass" then
			return {
				Vector2.new(-hw, -hd), Vector2.new(hw, -hd), Vector2.new(hw * 0.35, 0),
				Vector2.new(hw, hd), Vector2.new(-hw, hd), Vector2.new(-hw * 0.35, 0),
			}
		elseif shape == "wide" then
			return { Vector2.new(-hw, -hd * 0.7), Vector2.new(hw, -hd * 0.7), Vector2.new(hw, hd * 0.7), Vector2.new(-hw, hd * 0.7) }
		elseif shape == "narrow" then
			return { Vector2.new(-hw * 0.55, -hd), Vector2.new(hw * 0.55, -hd), Vector2.new(hw * 0.55, hd), Vector2.new(-hw * 0.55, hd) }
		elseif shape == "cross" then
			return {
				Vector2.new(-hw * 0.34, -hd), Vector2.new(hw * 0.34, -hd), Vector2.new(hw * 0.34, -hd * 0.34),
				Vector2.new(hw, -hd * 0.34), Vector2.new(hw, hd * 0.34), Vector2.new(hw * 0.34, hd * 0.34),
				Vector2.new(hw * 0.34, hd), Vector2.new(-hw * 0.34, hd), Vector2.new(-hw * 0.34, hd * 0.34),
				Vector2.new(-hw, hd * 0.34), Vector2.new(-hw, -hd * 0.34), Vector2.new(-hw * 0.34, -hd * 0.34),
			}
		elseif shape == "crystal" then
			return {
				Vector2.new(0, -hd), Vector2.new(hw * 0.46, -hd * 0.56), Vector2.new(hw, -hd * 0.28),
				Vector2.new(hw * 0.62, hd * 0.12), Vector2.new(hw * 0.78, hd * 0.76), Vector2.new(0, hd),
				Vector2.new(-hw * 0.78, hd * 0.76), Vector2.new(-hw * 0.62, hd * 0.12), Vector2.new(-hw, -hd * 0.28),
				Vector2.new(-hw * 0.46, -hd * 0.56),
			}
		elseif shape == "trapezoid" then
			return { Vector2.new(-hw * 0.42, -hd), Vector2.new(hw * 0.42, -hd), Vector2.new(hw, hd), Vector2.new(-hw, hd) }
		elseif shape == "zigzag" then
			return {
				Vector2.new(-hw, -hd), Vector2.new(-hw * 0.12, -hd), Vector2.new(hw * 0.22, -hd * 0.42),
				Vector2.new(hw, -hd * 0.42), Vector2.new(hw * 0.48, hd * 0.12), Vector2.new(hw, hd),
				Vector2.new(hw * 0.08, hd), Vector2.new(-hw * 0.18, hd * 0.42), Vector2.new(-hw, hd * 0.42),
				Vector2.new(-hw * 0.46, -hd * 0.1),
			}
		elseif shape == "pinched" then
			return {
				Vector2.new(-hw * 0.72, -hd), Vector2.new(hw * 0.72, -hd), Vector2.new(hw * 0.38, -hd * 0.14),
				Vector2.new(hw * 0.72, hd), Vector2.new(-hw * 0.72, hd), Vector2.new(-hw * 0.38, hd * 0.14),
			}
		elseif shape == "kite" then
			return { Vector2.new(0, -hd), Vector2.new(hw * 0.86, -hd * 0.06), Vector2.new(0, hd), Vector2.new(-hw * 0.48, hd * 0.18) }
		elseif shape == "bowtie" then
			return {
				Vector2.new(-hw, -hd), Vector2.new(0, -hd * 0.28), Vector2.new(hw, -hd),
				Vector2.new(hw * 0.36, 0), Vector2.new(hw, hd), Vector2.new(0, hd * 0.28),
				Vector2.new(-hw, hd), Vector2.new(-hw * 0.36, 0),
			}
		end
		return { Vector2.new(-hw, -hd), Vector2.new(hw, -hd), Vector2.new(hw, hd), Vector2.new(-hw, hd) }
	end

	local function makePad(name, pos, velocity, color, size)
		local base = part(name, size or Vector3.new(13, 1.1, 13), pos, "Really black", Enum.Material.SmoothPlastic, 0)
		neon(name .. "Glow", Vector3.new((size and size.X or 13) - 1, 0.25, (size and size.Z or 13) - 1), pos + Vector3.new(0, 0.68, 0), color, 0.08, true)
		ball(name .. "GuideOrb", 2.1, pos + Vector3.new(0, 3.0, 0), color, 0.12)
		addConn(base.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or padDebounce[player] then return end
			padDebounce[player] = true
			launchPlayer(player, velocity, 0.25)
			task.delay(0.28, function()
				padDebounce[player] = nil
			end)
		end))
	end

	local function makeMovingHelper(name, y, radius, speed)
		local platform = part(name, Vector3.new(26, 2, 13), Vector3.new(cx + radius, y, cz), secondary, Enum.Material.SmoothPlastic, 0)
		local glow = neon(name .. "Glow", Vector3.new(25, 0.25, 12), platform.Position + Vector3.new(0, 1.15, 0), primary, 0.18, true)
		local angle = 0
		addConn(RunService.Heartbeat:Connect(function(dt)
			if not platform.Parent then return end
			angle += dt * speed
			local cf = CFrame.new(cx + math.cos(angle) * radius, y, cz + math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
			platform.CFrame = cf
			if glow.Parent then
				glow.CFrame = cf + Vector3.new(0, 1.15, 0)
			end
		end))
	end

	local function completeForPlayer(player)
		if not alive or not player or finishDebounce[player] then return end
		if player:GetAttribute("SkyDescentBoundsActive") then return end
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if math.abs(hrp.Position.X - cx) > hw - 4 or math.abs(hrp.Position.Z - cz) > hd - 4 then return end
		if hrp.Position.Y < topY - 6 then return end

		finishDebounce[player] = true
		remValue.Value = math.max(0, remValue.Value - 1)
		if playerScored then
			playerScored:Fire(player, config.name)
		end
		task.delay(6, function()
			finishDebounce[player] = nil
		end)
	end

	local function makeSpinner(name, y, length, thickness, speed, color, axis)
		local bar = neon(name, Vector3.new(length, thickness, thickness), Vector3.new(cx, y, cz), color, 0.2, false)
		bar.CanCollide = true
		local angle = 0
		addConn(RunService.Heartbeat:Connect(function(dt)
			if not bar.Parent then return end
			angle += dt * speed
			if axis == "Z" then
				bar.CFrame = CFrame.new(cx, y, cz) * CFrame.Angles(0, 0, angle)
			else
				bar.CFrame = CFrame.new(cx, y, cz) * CFrame.Angles(0, angle, 0)
			end
		end))
	end

	local function makeObstacleSet(style)
		if style == "lavaRings" then
			for i, radius in ipairs({ 18, 32, 46 }) do
				neon("LavaRing" .. i .. "N", Vector3.new(radius, 1.2, 1.2), Vector3.new(cx, floorY + 12 + i * 11, cz - radius * 0.34), "Bright red", 0.12, false)
				neon("LavaRing" .. i .. "S", Vector3.new(radius, 1.2, 1.2), Vector3.new(cx, floorY + 12 + i * 11, cz + radius * 0.34), "Bright orange", 0.12, false)
			end
			makeSpinner("LavaCoreSpinner", floorY + 58, 58, 1.4, 0.9, secondary, "Y")
		elseif style == "electricSlalom" then
			for i = 1, 7 do
				local side = i % 2 == 0 and -1 or 1
				neon("ElectricSlalom" .. i, Vector3.new(2, 26, 2), Vector3.new(cx + side * hw * 0.35, floorY + 12 + i * 12, cz - hd * 0.45 + i * hd * 0.13), "Cyan", 0.08, false)
			end
			makeSpinner("ElectricSweep", floorY + 72, 52, 1.2, -1.15, primary, "Y")
		elseif style == "shadowBlades" then
			for i = 1, 5 do
				makeSpinner("ShadowBlade" .. i, floorY + 22 + i * 17, 36 + i * 3, 1.1, 0.55 + i * 0.08, i % 2 == 0 and primary or secondary, "Y")
			end
		elseif style == "apexPillars" then
			for i = 1, 8 do
				local a = i / 8 * math.pi * 2
				part("ApexPillar" .. i, Vector3.new(7, 34 + (i % 3) * 8, 7), Vector3.new(cx + math.cos(a) * hw * 0.42, floorY + 16 + (i % 3) * 4, cz + math.sin(a) * hd * 0.42), primary, Enum.Material.Metal, 0.05)
			end
			if config.removeTopObstacle == false then
				makeSpinner("ApexTopCompass", floorY + 96, 60, 1.2, 0.75, secondary, "Y")
			end
		elseif style == "cloudSteps" then
			for i = 1, 9 do
				local x = ((i % 3) - 1) * hw * 0.28
				local z = -hd * 0.42 + i * hd * 0.1
				ball("CloudStep" .. i, 9 + (i % 2) * 3, Vector3.new(cx + x, floorY + 8 + i * 10, cz + z), "Institutional white", 0.36)
			end
		elseif style == "coralArches" then
			for i = 1, 5 do
				local z = cz - hd * 0.44 + i * hd * 0.18
				part("CoralArchL" .. i, Vector3.new(4, 28, 4), Vector3.new(cx - hw * 0.32, floorY + 14 + i * 8, z), secondary, Enum.Material.SmoothPlastic, 0)
				part("CoralArchR" .. i, Vector3.new(4, 28, 4), Vector3.new(cx + hw * 0.32, floorY + 14 + i * 8, z), secondary, Enum.Material.SmoothPlastic, 0)
				neon("CoralArchTop" .. i, Vector3.new(hw * 0.64, 2, 3), Vector3.new(cx, floorY + 29 + i * 8, z), primary, 0.16, false)
			end
		elseif style == "bubbleOrbs" then
			for i = 1, 12 do
				local a = i / 12 * math.pi * 2
				ball("BubbleOrb" .. i, 6 + (i % 3) * 2, Vector3.new(cx + math.cos(a) * hw * 0.46, floorY + 12 + i * 8, cz + math.sin(a) * hd * 0.46), i % 2 == 0 and primary or secondary, 0.48)
			end
		elseif style == "zenSpinners" then
			for i = 1, 4 do
				makeSpinner("ZenWindmill" .. i, floorY + 26 + i * 21, 42, 1.1, (i % 2 == 0 and -0.65 or 0.65), i % 2 == 0 and primary or secondary, "Z")
			end
		elseif style == "crystalSpikes" then
			for i = 1, 10 do
				local a = i / 10 * math.pi * 2
				local spike = neon("CrystalSpike" .. i, Vector3.new(5, 24 + (i % 4) * 7, 5), Vector3.new(cx + math.cos(a) * hw * 0.5, floorY + 12 + (i % 4) * 3, cz + math.sin(a) * hd * 0.5), primary, 0.1, false)
				spike.CFrame *= CFrame.Angles(0, a, math.rad(12))
			end
		elseif style == "neonBeams" then
			for i = 1, 7 do
				local beam = neon("NeonBeam" .. i, Vector3.new(hw * 1.35, 1.1, 1.1), Vector3.new(cx, floorY + 18 + i * 13, cz - hd * 0.45 + i * hd * 0.14), i % 2 == 0 and primary or secondary, 0.1, false)
				beam.CFrame *= CFrame.Angles(0, math.rad(i * 17), 0)
			end
		elseif style == "canyonBridges" then
			for i = 1, 6 do
				local z = cz - hd * 0.5 + i * hd * 0.17
				part("CanyonBridge" .. i, Vector3.new(hw * (i % 2 == 0 and 1.1 or 0.7), 2, 8), Vector3.new(cx + (i % 2 == 0 and -hw * 0.1 or hw * 0.12), floorY + 12 + i * 15, z), config.platformColor or "Nougat", Enum.Material.WoodPlanks, 0.02)
			end
		elseif style == "pinballBumpers" then
			for i = 1, 12 do
				local row = math.floor((i - 1) / 4)
				local col = (i - 1) % 4
				ball("PinballBumper" .. i, 7, Vector3.new(cx - hw * 0.36 + col * hw * 0.24, floorY + 18 + row * 27, cz - hd * 0.3 + row * hd * 0.22), i % 2 == 0 and primary or secondary, 0.1)
			end
		elseif style == "goldenGates" then
			for i = 1, 5 do
				local y = floorY + 18 + i * 17
				neon("GoldenGateTop" .. i, Vector3.new(hw * 1.15, 2, 2), Vector3.new(cx, y + 14, cz - hd * 0.45 + i * hd * 0.16), secondary, 0.12, false)
				part("GoldenGateL" .. i, Vector3.new(3, 28, 3), Vector3.new(cx - hw * 0.46, y, cz - hd * 0.45 + i * hd * 0.16), primary, Enum.Material.Metal, 0.02)
				part("GoldenGateR" .. i, Vector3.new(3, 28, 3), Vector3.new(cx + hw * 0.46, y, cz - hd * 0.45 + i * hd * 0.16), primary, Enum.Material.Metal, 0.02)
			end
		elseif style == "vaultClock" then
			for i = 1, 8 do
				local a = i / 8 * math.pi * 2
				makeSpinner("ClockHand" .. i, floorY + 16 + i * 12, 32 + (i % 3) * 8, 1.1, 0.35 + i * 0.05, i % 2 == 0 and primary or secondary, i % 2 == 0 and "Y" or "Z")
				ball("ClockMarker" .. i, 3, Vector3.new(cx + math.cos(a) * hw * 0.52, floorY + 20 + i * 8, cz + math.sin(a) * hd * 0.52), accent, 0.18)
			end
		end
	end

	local function buildRoom()
		worldFolder = Instance.new("Folder")
		worldFolder.Name = formatFolderName(config.name)
		worldFolder.Parent = workspace

		part("Floor", Vector3.new(hw * 2, 4, hd * 2), Vector3.new(cx, floorY - 2, cz), config.floorColor or "Really black", Enum.Material.SmoothPlastic, 0)
		neon("FloorGlow", Vector3.new(hw * 2 - 4, 0.15, hd * 2 - 4), Vector3.new(cx, floorY + 0.08, cz), primary, 0.72, true)

		local points = shapePoints(config.shape)
		for i, point in ipairs(points) do
			local nextPoint = points[(i % #points) + 1]
			shellPanel("ShapeWall" .. i, point, nextPoint)
		end

		for i = 1, #points do
			local a = i / #points * math.pi * 2
			ball("ShapeStar" .. i, 1.25, Vector3.new(cx + math.cos(a) * hw * 0.72, floorY + 6 + (i % 3) * 4, cz + math.sin(a) * hd * 0.72), accent, 0.18)
		end

		local jumperStyles = {
			spiral = {
				{ y = floorY + 0.8, x = 0, z = -hd * 0.5, vy = 78, hx = hw * 0.28, hz = hd * 0.12 },
				{ y = floorY + 18, x = hw * 0.34, z = -hd * 0.28, vy = 78, hx = -hw * 0.05, hz = hd * 0.28 },
				{ y = floorY + 36, x = hw * 0.28, z = hd * 0.16, vy = 76, hx = -hw * 0.32, hz = hd * 0.08 },
				{ y = floorY + 54, x = -hw * 0.24, z = hd * 0.28, vy = 74, hx = -hw * 0.1, hz = -hd * 0.28 },
				{ y = floorY + 72, x = -hw * 0.36, z = -hd * 0.08, vy = 72, hx = hw * 0.28, hz = -hd * 0.12 },
				{ y = floorY + 90, x = -hw * 0.06, z = -hd * 0.34, vy = 68, hx = hw * 0.12, hz = hd * 0.2 },
				{ y = floorY + 106, x = hw * 0.12, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			switchback = {
				{ y = floorY + 0.8, x = -hw * 0.42, z = -hd * 0.48, vy = 78, hx = hw * 0.5, hz = hd * 0.04 },
				{ y = floorY + 18, x = hw * 0.42, z = -hd * 0.32, vy = 76, hx = -hw * 0.5, hz = hd * 0.12 },
				{ y = floorY + 36, x = -hw * 0.4, z = -hd * 0.14, vy = 74, hx = hw * 0.5, hz = hd * 0.12 },
				{ y = floorY + 54, x = hw * 0.4, z = hd * 0.04, vy = 72, hx = -hw * 0.48, hz = hd * 0.12 },
				{ y = floorY + 72, x = -hw * 0.36, z = hd * 0.22, vy = 70, hx = hw * 0.38, hz = hd * 0.04 },
				{ y = floorY + 90, x = hw * 0.26, z = hd * 0.4, vy = 68, hx = -hw * 0.16, hz = -hd * 0.12 },
				{ y = floorY + 106, x = 0, z = hd * 0.04, vy = 64, hx = 0, hz = 0 },
			},
			centerBurst = {
				{ y = floorY + 0.8, x = 0, z = 0, vy = 88, hx = 0, hz = -hd * 0.34 },
				{ y = floorY + 20, x = 0, z = -hd * 0.34, vy = 78, hx = hw * 0.34, hz = hd * 0.1 },
				{ y = floorY + 38, x = hw * 0.34, z = -hd * 0.16, vy = 76, hx = -hw * 0.34, hz = hd * 0.3 },
				{ y = floorY + 56, x = -hw * 0.34, z = hd * 0.14, vy = 74, hx = hw * 0.34, hz = hd * 0.18 },
				{ y = floorY + 74, x = hw * 0.24, z = hd * 0.36, vy = 70, hx = -hw * 0.24, hz = -hd * 0.28 },
				{ y = floorY + 92, x = 0, z = hd * 0.1, vy = 68, hx = 0, hz = 0 },
				{ y = floorY + 108, x = 0, z = 0, vy = 62, hx = 0, hz = 0 },
			},
			ridge = {
				{ y = floorY + 0.8, x = -hw * 0.44, z = 0, vy = 78, hx = hw * 0.18, hz = -hd * 0.22 },
				{ y = floorY + 18, x = -hw * 0.22, z = -hd * 0.24, vy = 76, hx = hw * 0.2, hz = hd * 0.34 },
				{ y = floorY + 36, x = 0, z = hd * 0.18, vy = 74, hx = hw * 0.2, hz = -hd * 0.34 },
				{ y = floorY + 54, x = hw * 0.22, z = -hd * 0.2, vy = 72, hx = hw * 0.16, hz = hd * 0.32 },
				{ y = floorY + 72, x = hw * 0.42, z = hd * 0.18, vy = 70, hx = -hw * 0.26, hz = hd * 0.1 },
				{ y = floorY + 90, x = hw * 0.14, z = hd * 0.42, vy = 68, hx = -hw * 0.12, hz = -hd * 0.22 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			cornerLoop = {
				{ y = floorY + 0.8, x = -hw * 0.42, z = -hd * 0.42, vy = 80, hx = hw * 0.26, hz = 0 },
				{ y = floorY + 18, x = hw * 0.42, z = -hd * 0.42, vy = 78, hx = 0, hz = hd * 0.26 },
				{ y = floorY + 36, x = hw * 0.42, z = hd * 0.42, vy = 76, hx = -hw * 0.26, hz = 0 },
				{ y = floorY + 54, x = -hw * 0.42, z = hd * 0.42, vy = 74, hx = hw * 0.24, hz = -hd * 0.28 },
				{ y = floorY + 72, x = 0, z = 0, vy = 72, hx = 0, hz = -hd * 0.28 },
				{ y = floorY + 90, x = 0, z = -hd * 0.3, vy = 68, hx = 0, hz = hd * 0.18 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			hourglassRun = {
				{ y = floorY + 0.8, x = -hw * 0.36, z = -hd * 0.46, vy = 78, hx = hw * 0.26, hz = hd * 0.2 },
				{ y = floorY + 18, x = hw * 0.36, z = -hd * 0.46, vy = 76, hx = -hw * 0.26, hz = hd * 0.28 },
				{ y = floorY + 36, x = 0, z = -hd * 0.08, vy = 76, hx = 0, hz = hd * 0.28 },
				{ y = floorY + 54, x = -hw * 0.34, z = hd * 0.3, vy = 74, hx = hw * 0.3, hz = 0 },
				{ y = floorY + 72, x = hw * 0.34, z = hd * 0.3, vy = 72, hx = -hw * 0.2, hz = -hd * 0.2 },
				{ y = floorY + 90, x = 0, z = 0, vy = 68, hx = 0, hz = 0 },
				{ y = floorY + 106, x = 0, z = hd * 0.28, vy = 64, hx = 0, hz = -hd * 0.12 },
			},
			octagonHop = {
				{ y = floorY + 0.8, x = 0, z = -hd * 0.5, vy = 80, hx = hw * 0.22, hz = hd * 0.1 },
				{ y = floorY + 18, x = hw * 0.34, z = -hd * 0.34, vy = 78, hx = hw * 0.02, hz = hd * 0.26 },
				{ y = floorY + 36, x = hw * 0.5, z = 0, vy = 76, hx = -hw * 0.22, hz = hd * 0.2 },
				{ y = floorY + 54, x = hw * 0.34, z = hd * 0.34, vy = 74, hx = -hw * 0.3, hz = 0 },
				{ y = floorY + 72, x = 0, z = hd * 0.5, vy = 72, hx = -hw * 0.22, hz = -hd * 0.18 },
				{ y = floorY + 90, x = -hw * 0.34, z = hd * 0.16, vy = 68, hx = hw * 0.2, hz = -hd * 0.12 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			crossLane = {
				{ y = floorY + 0.8, x = 0, z = -hd * 0.46, vy = 78, hx = 0, hz = hd * 0.34 },
				{ y = floorY + 18, x = 0, z = 0, vy = 78, hx = -hw * 0.34, hz = 0 },
				{ y = floorY + 36, x = -hw * 0.42, z = 0, vy = 76, hx = hw * 0.42, hz = 0 },
				{ y = floorY + 54, x = hw * 0.42, z = 0, vy = 74, hx = -hw * 0.2, hz = hd * 0.3 },
				{ y = floorY + 72, x = 0, z = hd * 0.42, vy = 72, hx = 0, hz = -hd * 0.24 },
				{ y = floorY + 90, x = 0, z = 0, vy = 68, hx = hw * 0.12, hz = 0 },
				{ y = floorY + 106, x = hw * 0.16, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			crystalClimb = {
				{ y = floorY + 0.8, x = -hw * 0.18, z = -hd * 0.52, vy = 80, hx = hw * 0.28, hz = hd * 0.18 },
				{ y = floorY + 18, x = hw * 0.18, z = -hd * 0.34, vy = 78, hx = -hw * 0.34, hz = hd * 0.16 },
				{ y = floorY + 36, x = -hw * 0.3, z = -hd * 0.12, vy = 76, hx = hw * 0.44, hz = hd * 0.1 },
				{ y = floorY + 54, x = hw * 0.38, z = hd * 0.04, vy = 74, hx = -hw * 0.22, hz = hd * 0.22 },
				{ y = floorY + 72, x = hw * 0.12, z = hd * 0.32, vy = 72, hx = -hw * 0.32, hz = -hd * 0.08 },
				{ y = floorY + 90, x = -hw * 0.22, z = hd * 0.24, vy = 68, hx = hw * 0.18, hz = -hd * 0.16 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			triangleHop = {
				{ y = floorY + 0.8, x = 0, z = -hd * 0.5, vy = 80, hx = hw * 0.34, hz = hd * 0.26 },
				{ y = floorY + 20, x = hw * 0.42, z = hd * 0.1, vy = 78, hx = -hw * 0.42, hz = hd * 0.2 },
				{ y = floorY + 38, x = -hw * 0.42, z = hd * 0.1, vy = 76, hx = hw * 0.22, hz = -hd * 0.24 },
				{ y = floorY + 56, x = 0, z = -hd * 0.2, vy = 74, hx = 0, hz = hd * 0.38 },
				{ y = floorY + 74, x = hw * 0.28, z = hd * 0.32, vy = 72, hx = -hw * 0.28, hz = 0 },
				{ y = floorY + 92, x = -hw * 0.28, z = hd * 0.32, vy = 68, hx = hw * 0.2, hz = -hd * 0.2 },
				{ y = floorY + 108, x = 0, z = 0, vy = 62, hx = 0, hz = 0 },
			},
			canyonLadder = {
				{ y = floorY + 0.8, x = -hw * 0.46, z = -hd * 0.4, vy = 78, hx = hw * 0.32, hz = 0 },
				{ y = floorY + 18, x = -hw * 0.08, z = -hd * 0.4, vy = 76, hx = hw * 0.32, hz = hd * 0.18 },
				{ y = floorY + 36, x = hw * 0.34, z = -hd * 0.18, vy = 74, hx = -hw * 0.42, hz = hd * 0.12 },
				{ y = floorY + 54, x = -hw * 0.34, z = hd * 0.02, vy = 72, hx = hw * 0.42, hz = hd * 0.12 },
				{ y = floorY + 72, x = hw * 0.34, z = hd * 0.24, vy = 70, hx = -hw * 0.22, hz = hd * 0.08 },
				{ y = floorY + 90, x = -hw * 0.04, z = hd * 0.4, vy = 68, hx = hw * 0.08, hz = -hd * 0.2 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			pinchedDash = {
				{ y = floorY + 0.8, x = 0, z = -hd * 0.54, vy = 80, hx = 0, hz = hd * 0.28 },
				{ y = floorY + 18, x = 0, z = -hd * 0.22, vy = 78, hx = -hw * 0.22, hz = hd * 0.12 },
				{ y = floorY + 36, x = -hw * 0.26, z = 0, vy = 76, hx = hw * 0.52, hz = 0 },
				{ y = floorY + 54, x = hw * 0.26, z = 0, vy = 74, hx = -hw * 0.52, hz = hd * 0.12 },
				{ y = floorY + 72, x = 0, z = hd * 0.22, vy = 72, hx = 0, hz = hd * 0.22 },
				{ y = floorY + 90, x = 0, z = hd * 0.46, vy = 68, hx = 0, hz = -hd * 0.22 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			gateArc = {
				{ y = floorY + 0.8, x = -hw * 0.32, z = -hd * 0.48, vy = 78, hx = hw * 0.28, hz = hd * 0.14 },
				{ y = floorY + 18, x = hw * 0.08, z = -hd * 0.32, vy = 76, hx = hw * 0.26, hz = hd * 0.18 },
				{ y = floorY + 36, x = hw * 0.42, z = -hd * 0.08, vy = 74, hx = -hw * 0.22, hz = hd * 0.26 },
				{ y = floorY + 54, x = hw * 0.18, z = hd * 0.28, vy = 72, hx = -hw * 0.34, hz = 0 },
				{ y = floorY + 72, x = -hw * 0.28, z = hd * 0.3, vy = 70, hx = hw * 0.18, hz = -hd * 0.18 },
				{ y = floorY + 90, x = -hw * 0.06, z = hd * 0.04, vy = 68, hx = hw * 0.1, hz = 0 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
			vaultClockwise = {
				{ y = floorY + 0.8, x = 0, z = -hd * 0.5, vy = 78, hx = hw * 0.38, hz = hd * 0.04 },
				{ y = floorY + 18, x = hw * 0.46, z = -hd * 0.2, vy = 76, hx = -hw * 0.12, hz = hd * 0.38 },
				{ y = floorY + 36, x = hw * 0.22, z = hd * 0.42, vy = 76, hx = -hw * 0.4, hz = 0 },
				{ y = floorY + 54, x = -hw * 0.36, z = hd * 0.28, vy = 74, hx = -hw * 0.04, hz = -hd * 0.36 },
				{ y = floorY + 72, x = -hw * 0.46, z = -hd * 0.18, vy = 72, hx = hw * 0.36, hz = -hd * 0.12 },
				{ y = floorY + 90, x = -hw * 0.04, z = -hd * 0.34, vy = 68, hx = hw * 0.14, hz = hd * 0.22 },
				{ y = floorY + 106, x = 0, z = 0, vy = 64, hx = 0, hz = 0 },
			},
		}
		local levels = config.levels or jumperStyles[config.jumperStyle or ""] or {
			{ y = floorY + 0.8, x = 0, z = -hd * 0.5, vy = 76, hx = hw * 0.16, hz = hd * 0.18 },
			{ y = floorY + 18, x = -hw * 0.34, z = -hd * 0.34, vy = 76, hx = hw * 0.26, hz = hd * 0.16 },
			{ y = floorY + 36, x = hw * 0.3, z = -hd * 0.12, vy = 74, hx = -hw * 0.22, hz = hd * 0.18 },
			{ y = floorY + 54, x = -hw * 0.24, z = hd * 0.1, vy = 74, hx = hw * 0.24, hz = hd * 0.15 },
			{ y = floorY + 72, x = hw * 0.22, z = hd * 0.3, vy = 72, hx = -hw * 0.18, hz = -hd * 0.1 },
			{ y = floorY + 90, x = -hw * 0.1, z = hd * 0.46, vy = 68, hx = hw * 0.1, hz = -hd * 0.18 },
			{ y = floorY + 106, x = hw * 0.12, z = 0, vy = 64, hx = 0, hz = 0 },
		}

		for index, level in ipairs(levels) do
			local color = index % 2 == 0 and secondary or primary
			local padPos = Vector3.new(cx + level.x, level.y, cz + level.z)
			makePad("HelperPad" .. index, padPos, Vector3.new(level.hx, level.vy, level.hz), color)
			part("CatchPlatform" .. index, Vector3.new(20, 1.4, 20), padPos + Vector3.new(level.hx * 0.1, 10, level.hz * 0.1), config.platformColor or "Medium stone grey", Enum.Material.SmoothPlastic, 0.08)
		end

		makePad("RecoveryPadWest", Vector3.new(cx - hw * 0.42, floorY + 0.8, cz + hd * 0.18), Vector3.new(hw * 0.18, 82, 0), primary, Vector3.new(12, 1.1, 12))
		makePad("RecoveryPadEast", Vector3.new(cx + hw * 0.42, floorY + 0.8, cz + hd * 0.18), Vector3.new(-hw * 0.18, 82, 0), secondary, Vector3.new(12, 1.1, 12))

		if config.denseJumpers then
			local floorStepX = hw * 0.42
			local floorStepZ = hd * 0.42
			for _, dx in { -floorStepX, 0, floorStepX } do
				for _, dz in { -floorStepZ, 0, floorStepZ } do
					local color = (math.abs(dx) < 0.1 and math.abs(dz) < 0.1) and accent or primary
					makePad(
						string.format("TowerFloorPad_%d_%d", math.floor(dx), math.floor(dz)),
						Vector3.new(cx + dx, floorY + 0.9, cz + dz),
						Vector3.new(0, 96, 0),
						color,
						Vector3.new(10, 1, 10)
					)
				end
			end

			local sideTiers = {
				{ y = floorY + 18, vy = 86, color = primary },
				{ y = floorY + 36, vy = 88, color = secondary },
				{ y = floorY + 54, vy = 90, color = accent },
				{ y = floorY + 72, vy = 88, color = primary },
				{ y = floorY + 90, vy = 82, color = secondary },
				{ y = floorY + 106, vy = 74, color = accent },
			}
			local sideOffsets = { -0.58, -0.24, 0.24, 0.58 }
			for tierIndex, tier in ipairs(sideTiers) do
				local padY = tier.y
				local padColor = tier.color
				for offsetIndex, offset in ipairs(sideOffsets) do
					local verticalBias = (offsetIndex % 2 == 0) and 4 or -4
					makePad(
						string.format("TowerWallPad_W_%d_%d", tierIndex, offsetIndex),
						Vector3.new(cx - hw * 0.82, padY, cz + hd * offset),
						Vector3.new(hw * 0.12, tier.vy + verticalBias, 0),
						padColor,
						Vector3.new(11, 1, 9)
					)
					makePad(
						string.format("TowerWallPad_E_%d_%d", tierIndex, offsetIndex),
						Vector3.new(cx + hw * 0.82, padY, cz - hd * offset),
						Vector3.new(-hw * 0.12, tier.vy + verticalBias, 0),
						padColor,
						Vector3.new(11, 1, 9)
					)
					makePad(
						string.format("TowerWallPad_N_%d_%d", tierIndex, offsetIndex),
						Vector3.new(cx + hw * offset, padY, cz - hd * 0.82),
						Vector3.new(0, tier.vy + verticalBias, hd * 0.12),
						padColor,
						Vector3.new(9, 1, 11)
					)
					makePad(
						string.format("TowerWallPad_S_%d_%d", tierIndex, offsetIndex),
						Vector3.new(cx - hw * offset, padY, cz + hd * 0.82),
						Vector3.new(0, tier.vy + verticalBias, -hd * 0.12),
						padColor,
						Vector3.new(9, 1, 11)
					)
				end
			end
		end

		makeObstacleSet(config.obstacleStyle)

		makeMovingHelper("GentleOrbitHelper", floorY + 66, math.min(hw, hd) * 0.35, config.orbitSpeed or 0.32)
		if config.removeTopObstacle == false then
			makeMovingHelper("UpperOrbitHelper", floorY + 96, math.min(hw, hd) * 0.24, (config.orbitSpeed or 0.32) * 1.22)
		end
		if config.removeTopJumper == false then
			makePad("FinalLiftPad", Vector3.new(cx, floorY + 112, cz), Vector3.new(0, 78, 0), secondary, Vector3.new(16, 1.2, 16))
		end

		if config.removeTopFinishVisuals == false then
			part("FinishLanding", Vector3.new(36, 2, 36), Vector3.new(cx, topY - 1, cz), "Really black", Enum.Material.SmoothPlastic, 0)
			neon("FinishRing", Vector3.new(32, 0.55, 32), Vector3.new(cx, topY + 0.2, cz), "Lime green", 0.08, true)
			ball("FinishBeacon", 6, Vector3.new(cx, topY + 8, cz), "Lime green", 0.12)
		end

		local trigger = Instance.new("Part")
		trigger.Name = "FinishTrigger"
		trigger.Size = Vector3.new(hw * 1.75, 10, hd * 1.75)
		trigger.Position = Vector3.new(cx, topY + 4, cz)
		trigger.Transparency = 1
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.CanTouch = true
		trigger.Parent = worldFolder
		addConn(trigger.Touched:Connect(function(hit)
			completeForPlayer(Players:GetPlayerFromCharacter(hit.Parent))
		end))
		addConn(RunService.Heartbeat:Connect(function()
			if not alive then return end
			for _, player in Players:GetPlayers() do
				completeForPlayer(player)
			end
		end))

		do
			local panelW = math.max(54, hd * 1.9)
			local panelH = math.max(82, wallH - 8)
			local panelPos = Vector3.new(cx - hw + 0.8, floorY + wallH / 2 + 1, cz)
			local panelColor = BrickColor.new(primary).Color
			local numberPanel = part("BigRoomNumberPanel", Vector3.new(0.8, panelH, panelW), panelPos, "Really black", Enum.Material.Metal, 0.02, true)
			numberPanel.CanCollide = false
			neon("BigRoomNumberGlowTop", Vector3.new(1.1, 1.2, panelW + 2), panelPos + Vector3.new(0, panelH / 2 + 0.8, 0), primary, 0.12, true)
			neon("BigRoomNumberGlowBottom", Vector3.new(1.1, 1.2, panelW + 2), panelPos - Vector3.new(0, panelH / 2 + 0.8, 0), primary, 0.12, true)
			neon("BigRoomNumberGlowLeft", Vector3.new(1.1, panelH + 2, 1.2), panelPos + Vector3.new(0, 0, panelW / 2 + 0.8), secondary, 0.12, true)
			neon("BigRoomNumberGlowRight", Vector3.new(1.1, panelH + 2, 1.2), panelPos - Vector3.new(0, 0, panelW / 2 + 0.8), secondary, 0.12, true)
			buildBigRoomNumber(numberPanel, config.order, config.name, panelColor, Enum.NormalId.Right)
		end

		local sign = part("SignPart", Vector3.new(36, 8, 0.5), Vector3.new(cx + hw + 5, floorY + 17, cz), "Really black", Enum.Material.Metal, 0, true)
		buildSurfaceLabel(sign, string.format("%02d  %s", config.order, string.upper(config.name)), BrickColor.new(primary).Color)
	end

	local function destroyRoom()
		for _, conn in activeConns do
			conn:Disconnect()
		end
		table.clear(activeConns)
		if worldFolder and worldFolder.Parent then
			worldFolder:Destroy()
		end
		worldFolder = nil
		table.clear(padDebounce)
		table.clear(finishDebounce)
	end

	task.spawn(function()
		local signal = gameEvents and gameEvents:WaitForChild("WorldRestartSignal", 30)
		if signal then
			signal.Event:Connect(function(worldName)
				if worldName ~= config.name then return end
				destroyRoom()
				alive = true
				remValue.Value = target
				totalValue.Value = target
				buildRoom()
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		padDebounce[player] = nil
		finishDebounce[player] = nil
	end)

	alive = true
	remValue.Value = target
	totalValue.Value = target
	buildRoom()
	print(string.format("[CreativeJumperRoom] Built %02d %s (%s).", config.order, config.name, config.shape or "box"))
end

return CreativeJumperRoom
