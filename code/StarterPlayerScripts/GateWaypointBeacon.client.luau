-- GateWaypointBeacon.client.luau
-- On stage complete: shows an enticing pulsing notification chip at the
-- bottom of the screen with a live distance counter and directional arrow.
-- No overlay — game is fully playable. Clears when player walks through gate.

if true then return end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

local V3 = Vector3.new
local C3 = Color3.fromRGB

-- =============================================
-- GATE WAYPOINTS
-- =============================================
local GATE_WAYPOINTS = {
	Playground             = { pos = V3(   0, 5,   61), color = C3(220,  50,  50), next = "Pizza Place"         },
	Pizza                  = { pos = V3(   0, 5,  272), color = C3(255, 130,   0), next = "Galactic"             },
	Galactic               = { pos = V3(   0, 5,  524), color = C3(120,   0, 210), next = "Jungle"               },
	Jungle                 = { pos = V3(   0, 5,  781), color = C3( 50, 180,  50), next = "Sports"               },
	Sports                 = { pos = V3(   0, 5, 1021), color = C3(255, 210,  60), next = "Tennis"               },
	Tennis                 = { pos = V3(   0, 5, 1231), color = C3(150, 255,  85), next = "Game Station"         },
	["Game Station"]       = { pos = V3(   0, 5, 1460), color = C3( 80, 220, 255), next = "Coffee Shop"          },
	["Coffee Shop"]        = { pos = V3( 156, 5, 1700), color = C3(255, 180,  60), next = "Burger House"         },
	["Burger House"]       = { pos = V3( 508, 5, 1700), color = C3(255, 220,  70), next = "New Pizza Place"      },
	["New Pizza Place"]    = { pos = V3( 860, 5, 1700), color = C3(255, 120,  80), next = "Swimming Pool"        },
	["Swimming Pool"]      = { pos = V3(1212, 5, 1700), color = C3( 80, 220, 255), next = "Dinosaur Park"        },
	["Dinosaur Park"]      = { pos = V3(1564, 5, 1700), color = C3(100, 255, 110), next = "Dino Beach"           },
	["Dino Beach"]         = { pos = V3(1916, 5, 1700), color = C3(255, 230,  90), next = "Flying Dino Forest"   },
	["Flying Dino Forest"] = { pos = V3(2268, 5, 1700), color = C3(100, 255, 110), next = "Cherry Grove"         },
	["Cherry Grove"]       = { pos = V3(2620, 5, 1700), color = C3(255,  80,  80), next = "Galactic Orchard"     },
	["Galactic Orchard"]   = { pos = V3(2980, 5, 1700), color = C3( 80, 240, 255), next = "Empty World 1"        },
}

local CLEAR_DIST = 28

-- =============================================
-- ACTIVE STATE
-- =============================================
local beaconParts  = {}
local beaconConn   = nil
local pulseConn    = nil
local hudGui       = nil

local function clearBeacon()
	if beaconConn then beaconConn:Disconnect(); beaconConn = nil end
	if pulseConn  then pulseConn:Disconnect();  pulseConn  = nil end
	for _, p in beaconParts do
		if p and p.Parent then p:Destroy() end
	end
	beaconParts = {}
	if hudGui and hudGui.Parent then hudGui:Destroy(); hudGui = nil end
end

-- =============================================
-- NOTIFICATION CHIP (the clickable widget)
-- =============================================
local function spawnBeacon(stageName)
	clearBeacon()

	local wp = GATE_WAYPOINTS[stageName]
	if not wp then return end

	local gatePos   = wp.pos
	local col       = wp.color
	local nextStage = wp.next or "Next Area"

	-- =============================================
	-- NOTIFICATION CHIP (no overlay, fully clickable)
	-- =============================================
	hudGui               = Instance.new("ScreenGui")
	hudGui.Name          = "GateNotifChip"
	hudGui.ResetOnSpawn  = false
	hudGui.IgnoreGuiInset = true
	hudGui.DisplayOrder  = 30
	hudGui.Parent        = playerGui

	-- Outer glow frame (slightly larger, same color, blurred by transparency)
	local glow = Instance.new("Frame")
	glow.AnchorPoint           = Vector2.new(0.5, 1)
	glow.Size                  = UDim2.new(0, 420, 0, 92)
	glow.Position              = UDim2.new(0.5, 0, 1, 200)  -- starts off-screen
	glow.BackgroundColor3      = col
	glow.BackgroundTransparency = 0.7
	glow.BorderSizePixel       = 0
	glow.Parent                = hudGui
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 22)

	-- Main chip button (slightly smaller, inset)
	local chip = Instance.new("TextButton")
	chip.AnchorPoint           = Vector2.new(0.5, 0.5)
	chip.Size                  = UDim2.new(1, -10, 1, -10)
	chip.Position              = UDim2.new(0.5, 0, 0.5, 0)
	chip.BackgroundColor3      = Color3.fromRGB(10, 10, 16)
	chip.BackgroundTransparency = 0
	chip.BorderSizePixel       = 0
	chip.Text                  = ""
	chip.AutoButtonColor       = false
	chip.ZIndex                = 2
	chip.Parent                = glow
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 18)

	-- Colored top accent line
	local accent = Instance.new("Frame")
	accent.Size             = UDim2.new(1, -20, 0, 4)
	accent.Position         = UDim2.new(0, 10, 0, 5)
	accent.BackgroundColor3 = col
	accent.BorderSizePixel  = 0
	accent.ZIndex           = 3
	accent.Parent           = chip
	Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

	-- Star badge on the left
	local badge = Instance.new("Frame")
	badge.Size             = UDim2.new(0, 52, 0, 52)
	badge.Position         = UDim2.new(0, 12, 0.5, -26)
	badge.BackgroundColor3 = col
	badge.BorderSizePixel  = 0
	badge.ZIndex           = 3
	badge.Parent           = chip
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 12)
	local badgeLbl = Instance.new("TextLabel")
	badgeLbl.Size                   = UDim2.new(1, 0, 1, 0)
	badgeLbl.BackgroundTransparency = 1
	badgeLbl.Text                   = "⭐"
	badgeLbl.Font                   = Enum.Font.GothamBlack
	badgeLbl.TextScaled             = true
	badgeLbl.TextColor3             = Color3.fromRGB(10, 10, 16)
	badgeLbl.ZIndex                 = 4
	badgeLbl.Parent                 = badge

	-- "LEVEL COMPLETE" title
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                   = UDim2.new(1, -160, 0, 28)
	titleLbl.Position               = UDim2.new(0, 76, 0, 14)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                   = "LEVEL COMPLETE!"
	titleLbl.TextColor3             = Color3.new(1, 1, 1)
	titleLbl.Font                   = Enum.Font.GothamBlack
	titleLbl.TextScaled             = true
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextStrokeTransparency = 0.5
	titleLbl.ZIndex                 = 3
	titleLbl.Parent                 = chip

	-- Next stage sub-label
	local subLbl = Instance.new("TextLabel")
	subLbl.Size                   = UDim2.new(1, -160, 0, 22)
	subLbl.Position               = UDim2.new(0, 76, 0, 42)
	subLbl.BackgroundTransparency = 1
	subLbl.Text                   = "→  " .. nextStage
	subLbl.TextColor3             = col
	subLbl.Font                   = Enum.Font.GothamBold
	subLbl.TextScaled             = true
	subLbl.TextXAlignment         = Enum.TextXAlignment.Left
	subLbl.ZIndex                 = 3
	subLbl.Parent                 = chip

	-- Directional arrow (right side, rotates toward gate)
	local arrowLbl = Instance.new("TextLabel")
	arrowLbl.Name                   = "Arrow"
	arrowLbl.Size                   = UDim2.new(0, 44, 0, 44)
	arrowLbl.Position               = UDim2.new(1, -112, 0.5, -22)
	arrowLbl.BackgroundTransparency = 1
	arrowLbl.Text                   = "▲"
	arrowLbl.TextColor3             = col
	arrowLbl.Font                   = Enum.Font.GothamBlack
	arrowLbl.TextScaled             = true
	arrowLbl.ZIndex                 = 3
	arrowLbl.Parent                 = chip

	-- Distance label (far right)
	local distLbl = Instance.new("TextLabel")
	distLbl.Name                    = "Dist"
	distLbl.Size                    = UDim2.new(0, 70, 1, 0)
	distLbl.Position                = UDim2.new(1, -78, 0, 0)
	distLbl.BackgroundTransparency  = 1
	distLbl.Text                    = "---"
	distLbl.TextColor3              = Color3.fromRGB(200, 210, 230)
	distLbl.Font                    = Enum.Font.GothamBold
	distLbl.TextScaled              = true
	distLbl.TextXAlignment          = Enum.TextXAlignment.Center
	distLbl.ZIndex                  = 3
	distLbl.Parent                  = chip

	-- Slide chip up into view
	local targetY = UDim2.new(0.5, 0, 1, -110)
	TweenService:Create(glow,
		TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = targetY }
	):Play()

	-- Click bounce effect (satisfying feedback)
	local bouncing = false
	chip.Activated:Connect(function()
		if bouncing then return end
		bouncing = true
		-- Flash accent color briefly
		TweenService:Create(chip,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad),
			{ BackgroundColor3 = col }
		):Play()
		task.delay(0.09, function()
			TweenService:Create(chip,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad),
				{ BackgroundColor3 = Color3.fromRGB(10, 10, 16) }
			):Play()
		end)
		-- Scale bounce on glow frame
		TweenService:Create(glow,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad),
			{ Size = UDim2.new(0, 440, 0, 100) }
		):Play()
		task.delay(0.12, function()
			TweenService:Create(glow,
				TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 420, 0, 92) }
			):Play()
			bouncing = false
		end)
	end)

	-- =============================================
	-- PULSE GLOW (border breathes in/out)
	-- =============================================
	local pulseT = 0
	pulseConn = RunService.Heartbeat:Connect(function(dt)
		pulseT += dt
		local pulse = 0.65 + math.sin(pulseT * 2.8) * 0.18
		glow.BackgroundTransparency = pulse
	end)

	-- =============================================
	-- PER-FRAME: HUD updates
	-- =============================================
	beaconConn = RunService.Heartbeat:Connect(function(dt)
		-- Update distance + arrow
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local hrpPos = hrp.Position
		local toGate = V3(gatePos.X - hrpPos.X, 0, gatePos.Z - hrpPos.Z)
		local dist   = math.floor(toGate.Magnitude)

		distLbl.Text = dist .. "m"

		if toGate.Magnitude > 0.5 then
			local dir  = toGate.Unit
			local camF = camera.CFrame.LookVector
			local camR = camera.CFrame.RightVector
			local fwd  = V3(camF.X, 0, camF.Z)
			local rgt  = V3(camR.X, 0, camR.Z)
			if fwd.Magnitude > 0.01 then fwd = fwd.Unit end
			if rgt.Magnitude > 0.01 then rgt = rgt.Unit end
			arrowLbl.Rotation = math.deg(math.atan2(dir:Dot(rgt), dir:Dot(fwd)))
		end

		-- Auto-clear at gate
		if dist <= CLEAR_DIST then
			TweenService:Create(glow,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, 0, 1, 200), Size = UDim2.new(0, 360, 0, 70) }
			):Play()
			task.delay(0.45, clearBeacon)
		end
	end)
end

-- =============================================
-- STAGE COMPLETION LISTENERS
-- =============================================
task.spawn(function()
	local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end

	local trackers = {
		{ rem = "BrainrotsRemaining",            name = "Playground",         wait = 10 },
		{ rem = "PizzaBrainrotsRemaining",        name = "Pizza",              wait = 15 },
		{ rem = "GalacticBrainrotsRemaining",     name = "Galactic",           wait = 15 },
		{ rem = "JungleAnimalsRemaining",          name = "Jungle",             wait = 20 },
		{ rem = "SportsPlayersRemaining",          name = "Sports",             wait = 20 },
		{ rem = "TennisPlayersRemaining",          name = "Tennis",             wait = 20 },
		{ rem = "GameStationBotsRemaining",        name = "Game Station",       wait = 20 },
		{ rem = "CoffeeBaristasRemaining",         name = "Coffee Shop",        wait = 25 },
		{ rem = "BurgerCooksRemaining",            name = "Burger House",       wait = 25 },
		{ rem = "NewPizzaChefsRemaining",          name = "New Pizza Place",    wait = 25 },
		{ rem = "PoolBirdsRemaining",              name = "Swimming Pool",      wait = 25 },
		{ rem = "DinosaurDinosRemaining",          name = "Dinosaur Park",      wait = 25 },
		{ rem = "DinoBeachDinosRemaining",         name = "Dino Beach",         wait = 25 },
		{ rem = "FlyingDinoForestDinosRemaining",  name = "Flying Dino Forest", wait = 25 },
		{ rem = "GiantDinoCherriesRemaining",      name = "Cherry Grove",       wait = 25 },
		{ rem = "GalacticFruitsRemaining",         name = "Galactic Orchard",   wait = 25 },
	}

	for _, tr in trackers do
		local val = gameEvents:WaitForChild(tr.rem, tr.wait)
		if not val then continue end
		local last = val.Value
		val.Changed:Connect(function(newVal)
			if last > 0 and newVal <= 0 then
				task.delay(1.8, function()
					spawnBeacon(tr.name)
				end)
			end
			last = newVal
		end)
	end
end)

player.CharacterAdded:Connect(clearBeacon)
