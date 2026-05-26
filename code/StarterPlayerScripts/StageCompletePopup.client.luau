-- StageCompletePopup.client.luau
-- Small pulsing sign that appears when a stage is complete.
-- Clicking it teleports the player to the next gate.
-- Clears automatically when player arrives at the gate.

if true then return end

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

local V3 = Vector3.new
local C3 = Color3.fromRGB

local gameEvents  = ReplicatedStorage:WaitForChild("GameEvents")
local notify      = gameEvents:WaitForChild("GateOpenNotify")
local teleportRem = gameEvents:WaitForChild("TeleportToGate")

local CLEAR_DIST = 30

local GATE_WAYPOINTS = {
	Playground             = { pos = V3(   0, 5,   61), color = C3(220,  50,  50), next = "Pizza Place"       },
	Pizza                  = { pos = V3(   0, 5,  272), color = C3(255, 130,   0), next = "Galactic"           },
	Galactic               = { pos = V3(   0, 5,  524), color = C3(120,   0, 210), next = "Jungle"             },
	Jungle                 = { pos = V3(   0, 5,  781), color = C3( 50, 180,  50), next = "Sports"             },
	Sports                 = { pos = V3(   0, 5, 1021), color = C3(255, 210,  60), next = "Tennis"             },
	Tennis                 = { pos = V3(   0, 5, 1231), color = C3(150, 255,  85), next = "Game Station"       },
	["Game Station"]       = { pos = V3(   0, 5, 1460), color = C3( 80, 220, 255), next = "Coffee Shop"        },
	["Coffee Shop"]        = { pos = V3( 156, 5, 1700), color = C3(255, 180,  60), next = "Burger House"       },
	["Burger House"]       = { pos = V3( 508, 5, 1700), color = C3(255, 220,  70), next = "New Pizza Place"    },
	["New Pizza Place"]    = { pos = V3( 860, 5, 1700), color = C3(255, 120,  80), next = "Swimming Pool"      },
	["Swimming Pool"]      = { pos = V3(1212, 5, 1700), color = C3( 80, 220, 255), next = "Dinosaur Park"      },
	["Dinosaur Park"]      = { pos = V3(1564, 5, 1700), color = C3(100, 255, 110), next = "Dino Beach"         },
	["Dino Beach"]         = { pos = V3(1916, 5, 1700), color = C3(255, 230,  90), next = "Flying Dino Forest" },
	["Flying Dino Forest"] = { pos = V3(2268, 5, 1700), color = C3(100, 255, 110), next = "Cherry Grove"       },
	["Cherry Grove"]       = { pos = V3(2620, 5, 1700), color = C3(255,  80,  80), next = "Galactic Orchard"   },
	["Galactic Orchard"]   = { pos = V3(2980, 5, 1700), color = C3( 80, 240, 255), next = "Empty World 1"      },
}

local frameConn  = nil
local activeGui  = nil

local function clearPopup()
	if frameConn then frameConn:Disconnect(); frameConn = nil end
	if activeGui and activeGui.Parent then
		activeGui:Destroy()
		activeGui = nil
	end
end

local function showPopup(zoneName)
	clearPopup()

	local wp        = GATE_WAYPOINTS[zoneName]
	local col       = wp and wp.color or C3(255, 210, 40)
	local nextStage = wp and wp.next  or ""
	local gatePos   = wp and wp.pos

	-- =============================================
	-- SCREEN FLASH on stage complete
	-- =============================================
	local flashGui = Instance.new("ScreenGui")
	flashGui.IgnoreGuiInset = true
	flashGui.DisplayOrder   = 50
	flashGui.ResetOnSpawn   = false
	flashGui.Parent         = playerGui
	local flashFrame = Instance.new("Frame")
	flashFrame.Size                 = UDim2.new(1, 0, 1, 0)
	flashFrame.BackgroundColor3     = col
	flashFrame.BackgroundTransparency = 0.55
	flashFrame.BorderSizePixel      = 0
	flashFrame.Parent               = flashGui
	TweenService:Create(flashFrame,
		TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
	task.delay(0.6, function() flashGui:Destroy() end)

	-- =============================================
	-- SIGN GUI
	-- =============================================
	local gui = Instance.new("ScreenGui")
	gui.Name            = "StageCompleteGui"
	gui.ResetOnSpawn    = false
	gui.IgnoreGuiInset  = true
	gui.DisplayOrder    = 35
	gui.Parent          = playerGui
	activeGui = gui

	-- Outer glow halo (slightly larger, same color)
	local halo = Instance.new("Frame")
	halo.AnchorPoint           = Vector2.new(0.5, 0)
	halo.Size                  = UDim2.new(0, 310, 0, 72)
	halo.Position              = UDim2.new(0.5, 0, -0.15, 0)
	halo.BackgroundColor3      = col
	halo.BackgroundTransparency = 0.78
	halo.BorderSizePixel       = 0
	halo.Parent                = gui
	Instance.new("UICorner", halo).CornerRadius = UDim.new(0, 20)

	-- Main clickable button
	local btn = Instance.new("TextButton")
	btn.AnchorPoint           = Vector2.new(0.5, 0.5)
	btn.Size                  = UDim2.new(1, -10, 1, -10)
	btn.Position              = UDim2.new(0.5, 0, 0.5, 0)
	btn.BackgroundColor3      = Color3.fromRGB(10, 10, 16)
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel       = 0
	btn.Text                  = ""
	btn.AutoButtonColor       = false
	btn.ZIndex                = 2
	btn.Parent                = halo
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 16)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color       = col
	btnStroke.Thickness   = 2
	btnStroke.Transparency = 0.2
	btnStroke.Parent      = btn

	-- Star icon left
	local star = Instance.new("TextLabel")
	star.Size                   = UDim2.new(0, 38, 0, 38)
	star.Position               = UDim2.new(0, 10, 0.5, -19)
	star.BackgroundTransparency = 1
	star.Text                   = "⭐"
	star.Font                   = Enum.Font.GothamBlack
	star.TextScaled             = true
	star.ZIndex                 = 3
	star.Parent                 = btn

	-- Main label "STAGE COMPLETE"
	local mainLbl = Instance.new("TextLabel")
	mainLbl.Size                   = UDim2.new(1, -110, 0, 28)
	mainLbl.Position               = UDim2.new(0, 54, 0, 6)
	mainLbl.BackgroundTransparency = 1
	mainLbl.Text                   = "STAGE COMPLETE"
	mainLbl.TextColor3             = Color3.new(1, 1, 1)
	mainLbl.Font                   = Enum.Font.GothamBlack
	mainLbl.TextScaled             = true
	mainLbl.TextStrokeTransparency = 0.5
	mainLbl.TextXAlignment         = Enum.TextXAlignment.Left
	mainLbl.ZIndex                 = 3
	mainLbl.Parent                 = btn

	-- Sub label "TAP → next stage"
	local subLbl = Instance.new("TextLabel")
	subLbl.Size                   = UDim2.new(1, -110, 0, 20)
	subLbl.Position               = UDim2.new(0, 54, 0, 34)
	subLbl.BackgroundTransparency = 1
	subLbl.Text                   = "TAP  ›  " .. nextStage
	subLbl.TextColor3             = col
	subLbl.Font                   = Enum.Font.GothamBold
	subLbl.TextScaled             = true
	subLbl.TextXAlignment         = Enum.TextXAlignment.Left
	subLbl.ZIndex                 = 3
	subLbl.Parent                 = btn

	-- Arrow (right side, rotates toward gate)
	local arrowLbl = Instance.new("TextLabel")
	arrowLbl.Size                   = UDim2.new(0, 40, 0, 40)
	arrowLbl.Position               = UDim2.new(1, -48, 0.5, -20)
	arrowLbl.BackgroundTransparency = 1
	arrowLbl.Text                   = "▲"
	arrowLbl.TextColor3             = col
	arrowLbl.Font                   = Enum.Font.GothamBlack
	arrowLbl.TextScaled             = true
	arrowLbl.ZIndex                 = 3
	arrowLbl.Parent                 = btn

	-- Slide in from top
	local onScreenPos = UDim2.new(0.5, 0, 0, 10)
	TweenService:Create(halo,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = onScreenPos }
	):Play()

	-- =============================================
	-- BLINK / PULSE ANIMATION
	-- =============================================
	local t = 0
	local blinkState = true

	frameConn = RunService.Heartbeat:Connect(function(dt)
		t += dt

		-- Halo breathes
		halo.BackgroundTransparency = 0.72 + math.sin(t * 3.2) * 0.18

		-- Button scale bob (via Size oscillation)
		local scale = 1 + math.sin(t * 2.6) * 0.018
		btn.Size = UDim2.new(scale, -10, scale, -10)

		-- Stroke blinks between accent and white
		local blink = math.sin(t * 5) > 0
		btnStroke.Color = blink and col or Color3.new(1, 1, 1)
		btnStroke.Transparency = blink and 0.1 or 0.6

		-- Arrow rotation toward gate
		if gatePos then
			local char = player.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local hrpPos = hrp.Position
				local toGate = V3(gatePos.X - hrpPos.X, 0, gatePos.Z - hrpPos.Z)
				local dist   = math.floor(toGate.Magnitude)

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

				-- Auto-clear when player arrives
				if dist <= CLEAR_DIST then
					TweenService:Create(halo,
						TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{ Position = UDim2.new(0.5, 0, -0.2, 0) }
					):Play()
					task.delay(0.38, clearPopup)
				end
			end
		end
	end)

	-- =============================================
	-- CLICK: teleport + flash + dismiss
	-- =============================================
	local clicked = false
	btn.Activated:Connect(function()
		if clicked then return end
		clicked = true

		-- Button flash
		TweenService:Create(btn,
			TweenInfo.new(0.08),
			{ BackgroundColor3 = col }
		):Play()
		task.delay(0.1, function()
			TweenService:Create(btn,
				TweenInfo.new(0.2),
				{ BackgroundColor3 = Color3.fromRGB(10, 10, 16) }
			):Play()
		end)

		-- White screen flash
		local tg = Instance.new("ScreenGui")
		tg.IgnoreGuiInset = true
		tg.DisplayOrder   = 60
		tg.ResetOnSpawn   = false
		tg.Parent         = playerGui
		local tf = Instance.new("Frame")
		tf.Size                 = UDim2.new(1, 0, 1, 0)
		tf.BackgroundColor3     = Color3.new(1, 1, 1)
		tf.BackgroundTransparency = 0
		tf.BorderSizePixel      = 0
		tf.Parent               = tg
		TweenService:Create(tf,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()
		task.delay(0.45, function() tg:Destroy() end)

		-- Teleport via server
		task.delay(0.1, function()
			teleportRem:FireServer(zoneName)
		end)

		-- Slide sign out after teleport
		task.delay(0.5, function()
			TweenService:Create(halo,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, 0, -0.2, 0) }
			):Play()
			task.delay(0.35, clearPopup)
		end)
	end)
end

notify.OnClientEvent:Connect(function(zoneName)
	showPopup(tostring(zoneName))
end)

player.CharacterAdded:Connect(clearPopup)
