-- BallDispensers.server.luau
-- Places a ball-dispenser vending machine in every world area.
-- Touch the machine to get a free ball of the area's type.
-- Per-player cooldown (1s debug / 12s prod); machine darkens and shows a countdown.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance  = require(ReplicatedStorage:WaitForChild("GameBalanceConfig"))
local COOLDOWN = Balance.ActiveMode == "debug" and 1 or 12

-- Ball type → neon color for the dispenser face
local TYPE_COLOR = {
	Normal     = BrickColor.new("Bright red"),
	Split      = BrickColor.new("Bright orange"),
	Heavy      = BrickColor.new("Bright violet"),
	Speed      = BrickColor.new("Cyan"),
	SplitChild = BrickColor.new("Bright yellow"),
	Fireball   = BrickColor.new("Really red"),
	DinoBlast  = BrickColor.new("Really red"),
}

-- One dispenser per world area.
-- pos = floor-level center (machine sits on top, so machine center is pos + V3(0,1.5,0))
-- type = ball type dispensed
local DISPENSERS = {
	-- Playground (3 dispensers)
	{ pos = Vector3.new(  0, 1, -40),   type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(-40, 1,  10),   type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new( 40, 1,  10),   type = "Speed",   label = "SPEED BALL"  },
	-- Pizza (4 dispensers)
	{ pos = Vector3.new(-55, 1, 155),   type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 55, 1, 155),   type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new(-45, 1, 240),   type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 45, 1, 240),   type = "Split",   label = "SPLIT BALL"  },
	-- Galactic (4 dispensers)
	{ pos = Vector3.new(-55, 1, 415),   type = "Heavy",   label = "HEAVY BALL"  },
	{ pos = Vector3.new( 55, 1, 415),   type = "Heavy",   label = "HEAVY BALL"  },
	{ pos = Vector3.new(-45, 1, 510),   type = "Heavy",   label = "HEAVY BALL"  },
	{ pos = Vector3.new( 45, 1, 510),   type = "Heavy",   label = "HEAVY BALL"  },
	-- Jungle (4 dispensers)
	{ pos = Vector3.new(-55, 3, 665),   type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 55, 3, 665),   type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new(-55, 3, 760),   type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 55, 3, 760),   type = "Speed",   label = "SPEED BALL"  },
	-- Sports (4 dispensers)
	{ pos = Vector3.new(-72, 2, 890),   type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new( 72, 2, 890),   type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(-72, 2, 990),   type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 72, 2, 990),   type = "Speed",   label = "SPEED BALL"  },
	-- Tennis (4 dispensers)
	{ pos = Vector3.new(-62, 2, 1110),  type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new( 62, 2, 1110),  type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(-62, 2, 1210),  type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 62, 2, 1210),  type = "Speed",   label = "SPEED BALL"  },
	-- Game Station (4 dispensers)
	{ pos = Vector3.new(-70, 3, 1320),  type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new( 70, 3, 1320),  type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(-70, 3, 1445),  type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 70, 3, 1445),  type = "Speed",   label = "SPEED BALL"  },
	-- Coffee Shop (5 dispensers)
	{ pos = Vector3.new(-120, 3, 1580), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 120, 3, 1580), type = "Heavy",   label = "HEAVY BALL"  },
	{ pos = Vector3.new(-120, 3, 1700), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 120, 3, 1700), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new(   0, 3, 1840), type = "Heavy",   label = "HEAVY BALL"  },
	-- Burger House (5 dispensers)
	{ pos = Vector3.new( 230, 3, 1560), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 480, 3, 1560), type = "Heavy",   label = "HEAVY BALL"  },
	{ pos = Vector3.new( 230, 3, 1840), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 480, 3, 1840), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 355, 3, 1700), type = "Heavy",   label = "HEAVY BALL"  },
	-- New Pizza Place (5 dispensers)
	{ pos = Vector3.new( 580, 3, 1560), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 835, 3, 1560), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new( 580, 3, 1840), type = "Heavy",   label = "HEAVY BALL"  },
	{ pos = Vector3.new( 835, 3, 1840), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 710, 3, 1700), type = "Speed",   label = "SPEED BALL"  },
	-- Swimming Pool (4 dispensers)
	{ pos = Vector3.new( 930, 3, 1570), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new(1180, 3, 1570), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new( 930, 3, 1840), type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(1180, 3, 1840), type = "Speed",   label = "SPEED BALL"  },
	-- Dinosaur Park (4 dispensers)
	{ pos = Vector3.new(1285, 3, 1570), type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(1535, 3, 1570), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new(1285, 3, 1840), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new(1535, 3, 1840), type = "Normal",  label = "NORMAL BALL" },
	-- Dino Beach (4 dispensers)
	{ pos = Vector3.new(1635, 3, 1570), type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(1885, 3, 1570), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new(1635, 3, 1840), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new(1885, 3, 1840), type = "Normal",  label = "NORMAL BALL" },
	-- Flying Dino Forest (4 dispensers)
	{ pos = Vector3.new(1985, 3, 1570), type = "Split",   label = "SPLIT BALL"  },
	{ pos = Vector3.new(2235, 3, 1570), type = "Speed",   label = "SPEED BALL"  },
	{ pos = Vector3.new(1985, 3, 1840), type = "Normal",  label = "NORMAL BALL" },
	{ pos = Vector3.new(2235, 3, 1840), type = "Split",   label = "SPLIT BALL"  },
	-- Cherry Grove (4 dispensers, elevated)
	{ pos = Vector3.new(2335, 36, 1590), type = "Normal", label = "NORMAL BALL" },
	{ pos = Vector3.new(2595, 36, 1590), type = "Split",  label = "SPLIT BALL"  },
	{ pos = Vector3.new(2335, 36, 1990), type = "Speed",  label = "SPEED BALL"  },
	{ pos = Vector3.new(2595, 36, 1990), type = "Normal", label = "NORMAL BALL" },
	-- Galactic Orchard (4 dispensers, elevated)
	{ pos = Vector3.new(2670, 36, 1590), type = "Heavy",  label = "HEAVY BALL"  },
	{ pos = Vector3.new(2960, 36, 1590), type = "Speed",  label = "SPEED BALL"  },
	{ pos = Vector3.new(2670, 36, 1990), type = "Split",  label = "SPLIT BALL"  },
	{ pos = Vector3.new(2960, 36, 1990), type = "Heavy",  label = "HEAVY BALL"  },
	-- Volt Abyss sky arena (cx=460, cz=1500; X:110..810, Z:1220..1780; floor Y=80)
	{ pos = Vector3.new(-2340, 1, 1465), type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-1840, 1, 1465), type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-2340, 1, 1935), type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-1840, 1, 1935), type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-2090, 1, 1640), type = "Fireball", label = "🔥 FIREBALL" },
	-- Storm Dome sky arena (cx=460, cz=750; X:110..810, Z:470..1030; floor Y=80)
	{ pos = Vector3.new(-1570, 1, 1465),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-1070, 1, 1465),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-1570, 1, 1935),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-1070, 1, 1935),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-1320, 1, 1640),  type = "Fireball", label = "🔥 FIREBALL" },
	-- EmptyWorld1 sky arena (floor Y=80)
	{ pos = Vector3.new(-800, 1, 1945),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-300, 1, 1945),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-800, 1, 1445), type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-300, 1, 1445), type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(-550, 1, 1640),  type = "Fireball", label = "🔥 FIREBALL" },
	-- Test Level sky arena (cx=460, cz=-750; X:110..810, Z:-1030..-470)
	{ pos = Vector3.new(160, 80, -940),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(760, 80, -940),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(160, 80, -560),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(760, 80, -560),  type = "Fireball", label = "🔥 FIREBALL" },
	{ pos = Vector3.new(460, 80, -690),  type = "Fireball", label = "🔥 FIREBALL" },
}

-- Ball type → physical properties (mirrors BallGame)
table.insert(DISPENSERS, { pos = Vector3.new(-2915, 2, 8370), type = "Normal", label = "NORMAL BALL" })
table.insert(DISPENSERS, { pos = Vector3.new(-2805, 2, 8370), type = "Speed",  label = "SPEED BALL" })
table.insert(DISPENSERS, { pos = Vector3.new(-2860, 2, 8460), type = "Heavy",  label = "HEAVY BALL" })

local BALL_PHYS = {
	Normal    = PhysicalProperties.new(0.5, 0.3, 0.7, 0, 0),
	Split     = PhysicalProperties.new(0.5, 0.3, 0.7, 0, 0),
	Heavy     = PhysicalProperties.new(1.5, 0.2, 0.3, 0, 0),
	Speed     = PhysicalProperties.new(0.1, 0.3, 0.8, 0, 0),
	Fireball  = PhysicalProperties.new(0.6, 0.2, 0.5, 0, 0),
	DinoBlast = PhysicalProperties.new(0.7, 0.1, 0.4, 0, 0),
}
local BALL_MAT = {
	Normal    = Enum.Material.SmoothPlastic,
	Split     = Enum.Material.Neon,
	Heavy     = Enum.Material.SmoothPlastic,
	Speed     = Enum.Material.Neon,
	Fireball  = Enum.Material.Neon,
	DinoBlast = Enum.Material.Neon,
}
local BALL_SIZE = { Normal=2, Split=2.4, Heavy=3.0, Speed=1.4, Fireball=4.5, DinoBlast=7 }
local BALL_COLORS = {
	Normal    = BrickColor.new("Bright red"),
	Split     = BrickColor.new("Bright orange"),
	Heavy     = BrickColor.new("Dark indigo"),
	Speed     = BrickColor.new("Cyan"),
	Fireball  = BrickColor.new("Bright orange"),
	DinoBlast = BrickColor.new("Really red"),
}

local function spawnBallAt(pos, ballType)
	local def     = BALL_PHYS[ballType] or BALL_PHYS.Normal
	local sz      = BALL_SIZE[ballType] or 2
	local mat     = BALL_MAT[ballType] or Enum.Material.SmoothPlastic
	local color   = BALL_COLORS[ballType] or BrickColor.new("Bright red")

	local ball = Instance.new("Part")
	ball.Name     = "Ball"
	ball.Shape    = Enum.PartType.Ball
	ball.Size     = Vector3.new(sz, sz, sz)
	ball.Position = pos + Vector3.new(0, 2, 0)
	ball.BrickColor = color
	ball.Material = mat
	ball.CustomPhysicalProperties = def
	ball:SetAttribute("BallType", ballType)
	ball.Parent = workspace

	local tag     = Instance.new("BoolValue")
	tag.Name      = "IsPickable"
	tag.Parent    = ball

	local bb      = Instance.new("BillboardGui")
	bb.Name       = "PickupHint"
	bb.Size       = UDim2.new(0, 130, 0, 34)
	bb.StudsOffset = Vector3.new(0, sz + 0.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent     = ball

	local lbl     = Instance.new("TextLabel")
	lbl.Size      = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text      = ballType:upper() .. " BALL  [E]"
	lbl.TextColor3 = color.Color
	lbl.TextStrokeTransparency = 0
	lbl.Font      = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.Parent    = bb

	-- Auto-remove after 30s if not picked up
	task.delay(30, function()
		if ball.Parent and ball:FindFirstChild("IsPickable") then
			ball:Destroy()
		end
	end)
end

-- =============================================
-- BUILD DISPENSER MACHINE
-- =============================================
local function buildDispenser(def)
	local ballType   = def.type
	local isDinoBlast = ballType == "DinoBlast"
	local bc         = TYPE_COLOR[ballType] or BrickColor.new("Bright red")
	local col        = bc.Color
	local floorY     = def.pos.Y
	local cx, cz     = def.pos.X, def.pos.Z

	-- DinoBlast machine is taller and wider
	local bodyW    = isDinoBlast and 3.2  or 2.2
	local bodyH    = isDinoBlast and 4.5  or 3
	local machineY = floorY + bodyH / 2

	local model = Instance.new("Model")
	model.Name  = "BallDispenser_" .. ballType
	model.Parent = workspace

	local function mp(name, sz, cf, brickColor, mat, transp)
		local p = Instance.new("Part")
		p.Name        = name
		p.Size        = sz
		p.CFrame      = cf
		p.Anchored    = true
		p.CanCollide  = true
		p.CastShadow  = false
		p.BrickColor  = brickColor
		p.Material    = mat or Enum.Material.SmoothPlastic
		p.Transparency = transp or 0
		p.Parent      = model
		return p
	end

	-- Body
	local bodyColor = isDinoBlast and BrickColor.new("Black") or BrickColor.new("Dark stone grey")
	local body = mp("Body",
		Vector3.new(bodyW, bodyH, bodyW),
		CFrame.new(cx, machineY, cz),
		bodyColor
	)
	body.CanTouch = true

	-- Colored face panel (front, toward +Z)
	local faceW = bodyW - 0.4
	local faceH = isDinoBlast and 3.6 or 2.4
	local halfD = bodyW / 2
	local face = mp("Face",
		Vector3.new(faceW, faceH, 0.22),
		CFrame.new(cx, machineY, cz + halfD + 0.01),
		bc, Enum.Material.Neon, isDinoBlast and 0.05 or 0.15
	)
	face.CanCollide = false

	-- Inner inset on face
	mp("FaceInset",
		Vector3.new(faceW - 0.4, faceH - 0.6, 0.18),
		CFrame.new(cx, machineY + 0.1, cz + halfD + 0.02),
		BrickColor.new("Black"), Enum.Material.SmoothPlastic, 0.25
	).CanCollide = false

	-- Top light strip
	local topLight = mp("TopLight",
		Vector3.new(faceW, isDinoBlast and 0.32 or 0.22, 0.22),
		CFrame.new(cx, machineY + bodyH / 2 - 0.3, cz + halfD + 0.01),
		bc, Enum.Material.Neon, 0
	)
	topLight.CanCollide = false

	-- DinoBlast: extra side accent strips
	if isDinoBlast then
		for _, side in { -1, 1 } do
			local strip = mp("SideStrip",
				Vector3.new(0.22, bodyH - 0.4, bodyW + 0.05),
				CFrame.new(cx + side * (bodyW / 2 + 0.01), machineY, cz),
				BrickColor.new("Bright orange"), Enum.Material.Neon, 0.1
			)
			strip.CanCollide = false
		end
		-- Bottom rim glow
		local rim = mp("BottomRim",
			Vector3.new(bodyW + 0.3, 0.28, bodyW + 0.3),
			CFrame.new(cx, floorY + 0.14, cz),
			BrickColor.new("Really red"), Enum.Material.Neon, 0.08
		)
		rim.CanCollide = false
	end

	-- Sample ball on top (bigger for DinoBlast)
	local sampleSz = isDinoBlast and 2.2 or 1
	local sampleBall = mp("SampleBall",
		Vector3.new(sampleSz, sampleSz, sampleSz),
		CFrame.new(cx, floorY + bodyH + sampleSz * 0.5 + 0.4, cz),
		bc, Enum.Material.Neon, isDinoBlast and 0.0 or 0.1
	)
	sampleBall.Shape      = Enum.PartType.Ball
	sampleBall.CanCollide = false

	-- DinoBlast: orbit ring around sample ball
	if isDinoBlast then
		local ring = mp("OrbitRing",
			Vector3.new(3.8, 0.18, 0.18),
			CFrame.new(cx, floorY + bodyH + sampleSz * 0.5 + 0.4, cz),
			BrickColor.new("Bright orange"), Enum.Material.Neon, 0.05
		)
		ring.CanCollide = false
	end

	-- Billboard on front: "FREE BALL" / cooldown timer
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 160, 0, 90)
	bb.StudsOffset = Vector3.new(0, 0, 1.5)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 40
	bb.Parent      = body

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                   = UDim2.new(1, 0, 0, 38)
	nameLbl.Position               = UDim2.new(0, 0, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text                   = def.label
	nameLbl.TextColor3             = col
	nameLbl.TextStrokeTransparency = 0.2
	nameLbl.Font                   = Enum.Font.GothamBlack
	nameLbl.TextScaled             = true
	nameLbl.Parent                 = bb

	local cdLbl = Instance.new("TextLabel")
	cdLbl.Name                    = "CooldownLabel"
	cdLbl.Size                    = UDim2.new(1, 0, 0, 40)
	cdLbl.Position                = UDim2.new(0, 0, 0, 44)
	cdLbl.BackgroundTransparency  = 1
	cdLbl.Text                    = "TOUCH TO GET"
	cdLbl.TextColor3              = Color3.new(1, 1, 1)
	cdLbl.TextStrokeTransparency  = 0.4
	cdLbl.Font                    = Enum.Font.GothamBold
	cdLbl.TextScaled              = true
	cdLbl.Parent                  = bb

	-- =============================================
	-- TOUCH DETECTION + COOLDOWN
	-- =============================================
	local cooldowns = {}   -- [player] = os.clock() of last use

	local function setReady(isReady)
		face.Transparency       = isReady and (isDinoBlast and 0.05 or 0.15) or 0.65
		topLight.Transparency   = isReady and 0    or 0.6
		sampleBall.Transparency = isReady and 0.1  or 0.7
		cdLbl.Text = isReady and "TOUCH TO GET" or "⏳ RECHARGING"
		cdLbl.TextColor3 = isReady and Color3.new(1,1,1) or Color3.fromRGB(200,200,200)
	end

	local function tryDispense(player)
		if not player then return end
		local now = os.clock()
		local last = cooldowns[player]
		if last and (now - last) < COOLDOWN then return end

		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		cooldowns[player] = now
		spawnBallAt(hrp.Position, ballType)

		-- Flash dispenser
		setReady(false)
		TweenService:Create(face, TweenInfo.new(0.12), { Transparency = 0 }):Play()
		task.delay(0.14, function()
			TweenService:Create(face, TweenInfo.new(0.18), { Transparency = 0.65 }):Play()
		end)

		-- Count down globally (show shortest remaining cooldown of any player)
		task.spawn(function()
			for i = COOLDOWN, 1, -1 do
				task.wait(1)
				-- Check if any player is still waiting
				local anyWaiting = false
				for p, t in cooldowns do
					if (os.clock() - t) < COOLDOWN then
						anyWaiting = true
						local remaining = math.ceil(COOLDOWN - (os.clock() - t))
						cdLbl.Text = "⏳ " .. remaining .. "s"
						break
					end
				end
				if not anyWaiting then break end
			end
			-- Check global readiness (all players cooled down)
			local allReady = true
			for p, t in cooldowns do
				if (os.clock() - t) < COOLDOWN then
					allReady = false
					break
				end
			end
			if allReady then setReady(true) end
		end)
	end

	body.Touched:Connect(function(hit)
		local char   = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		tryDispense(player)
	end)

	-- Animate sample ball floating
	local bobT = 0
	RunService.Heartbeat:Connect(function(dt)
		bobT += dt
		sampleBall.CFrame = CFrame.new(cx, machineY + 2.3 + math.sin(bobT * 2.2) * 0.28, cz)
			* CFrame.Angles(0, bobT * 1.4, 0)
	end)

	-- Clean up cooldowns for players who leave
	Players.PlayerRemoving:Connect(function(p)
		cooldowns[p] = nil
	end)

	return model
end

-- Build all dispensers
for _, def in DISPENSERS do
	buildDispenser(def)
end
