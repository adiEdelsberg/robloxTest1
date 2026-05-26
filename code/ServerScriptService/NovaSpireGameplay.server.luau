-- NovaSpireGameplay.server.luau
-- World 25: Nova Spire
-- Players climb the spire with jumpers and touch the top finish platform.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local WORLD_NAME = "Nova Spire"

local CX = -2860
local CZ = 2900
local FLOOR_Y = 1
local HW = 60
local HD = 60
local WALL_H = 140
local WALL_T = 4
local WALL_TRANS = 0.58

local DOOR_HALF = 25
local DOOR_H = 16
local FINISH_Y = FLOOR_Y + WALL_H - 10

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)

local remValue = gameEvents and gameEvents:FindFirstChild("NovaSpireRemaining")
if not remValue then
	remValue = Instance.new("NumberValue")
	remValue.Name = "NovaSpireRemaining"
	remValue.Value = 0
	remValue.Parent = gameEvents or ReplicatedStorage
end

local totValue = gameEvents and gameEvents:FindFirstChild("NovaSpireTotal")
if not totValue then
	totValue = Instance.new("NumberValue")
	totValue.Name = "NovaSpireTotal"
	totValue.Value = 0
	totValue.Parent = gameEvents or ReplicatedStorage
end

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET = (Balance.StageTargets and Balance.StageTargets.NovaSpire) or 1

local playerScored
task.spawn(function()
	playerScored = gameEvents and gameEvents:WaitForChild("PlayerScored", 30)
end)

local alive = false
local worldFolder = nil
local finishDebounce = {}
local padDebounce = {}
local coreDebounce = {}
local coreProgress = {}
local activeConns = {}

local function mkp(name, size, cframeOrPos, color, material, transparency, noCollide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	if typeof(cframeOrPos) == "CFrame" then
		p.CFrame = cframeOrPos
	else
		p.Position = cframeOrPos
	end
	p.BrickColor = BrickColor.new(color)
	p.Material = material
	p.Anchored = true
	p.CanCollide = not noCollide
	p.CanTouch = true
	p.CastShadow = false
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = worldFolder
	return p
end

local function solid(name, size, pos, color)
	return mkp(name, size, pos, color, Enum.Material.SmoothPlastic, 0)
end

local function neon(name, size, pos, color, transparency, noCollide)
	return mkp(name, size, pos, color, Enum.Material.Neon, transparency or 0.05, noCollide ~= false)
end

local function ball(name, size, pos, color, transparency, noCollide)
	local p = mkp(name, Vector3.one * size, pos, color, Enum.Material.Neon, transparency or 0.05, noCollide ~= false)
	p.Shape = Enum.PartType.Ball
	return p
end

local function cylinder(name, size, cframe, color, material, transparency, noCollide)
	local p = mkp(name, size, cframe, color, material or Enum.Material.Neon, transparency or 0.05, noCollide ~= false)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function addConn(conn)
	table.insert(activeConns, conn)
	return conn
end

local function getPlayerFromHit(hit)
	local character = hit and hit.Parent
	if not character then return nil end
	return Players:GetPlayerFromCharacter(character)
end

local function buildWall(isZWall, fixedCoord, alongMin, alongMax, yMin, yMax, holes)
	local yPts = { yMin, yMax }
	for _, h in ipairs(holes) do
		table.insert(yPts, h.yBot)
		table.insert(yPts, h.yTop)
	end
	table.sort(yPts)

	local uy = { yPts[1] }
	for i = 2, #yPts do
		if yPts[i] - uy[#uy] > 0.02 then
			table.insert(uy, yPts[i])
		end
	end

	for bi = 1, #uy - 1 do
		local yBot = uy[bi]
		local yTop = uy[bi + 1]
		local yH = yTop - yBot
		local yMid = (yBot + yTop) / 2
		local active = {}
		for _, h in ipairs(holes) do
			if h.yBot <= yBot + 0.01 and h.yTop >= yTop - 0.01 then
				table.insert(active, { h.alongMin, h.alongMax })
			end
		end
		table.sort(active, function(a, b) return a[1] < b[1] end)

		local cur = alongMin
		for _, hole in ipairs(active) do
			if hole[1] > cur then
				local len = hole[1] - cur
				local mid = cur + len / 2
				if isZWall then
					mkp("Wall", Vector3.new(WALL_T, yH, len), Vector3.new(fixedCoord, yMid, mid), "Dark indigo", Enum.Material.Glass, WALL_TRANS)
				else
					mkp("Wall", Vector3.new(len, yH, WALL_T), Vector3.new(mid, yMid, fixedCoord), "Dark indigo", Enum.Material.Glass, WALL_TRANS)
				end
			end
			cur = math.max(cur, hole[2])
		end
		if cur < alongMax then
			local len = alongMax - cur
			local mid = cur + len / 2
			if isZWall then
				mkp("Wall", Vector3.new(WALL_T, yH, len), Vector3.new(fixedCoord, yMid, mid), "Dark indigo", Enum.Material.Glass, WALL_TRANS)
			else
				mkp("Wall", Vector3.new(len, yH, WALL_T), Vector3.new(mid, yMid, fixedCoord), "Dark indigo", Enum.Material.Glass, WALL_TRANS)
			end
		end
	end
end

local function launchPlayer(player, velocity, duration)
	if player:GetAttribute("SkyDescentBoundsActive") then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local bv = Instance.new("BodyVelocity")
	bv.Velocity = velocity
	bv.MaxForce = Vector3.new(
		math.abs(velocity.X) > 0.1 and math.huge or 0,
		math.huge,
		math.abs(velocity.Z) > 0.1 and math.huge or 0
	)
	bv.P = math.huge
	bv.Parent = hrp
	Debris:AddItem(bv, duration or 0.22)
end

local function makePulse(part, low, high, seconds)
	local tweenOut = TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = high })
	local tweenIn = TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = low })
	addConn(tweenOut.Completed:Connect(function()
		if part.Parent then tweenIn:Play() end
	end))
	addConn(tweenIn.Completed:Connect(function()
		if part.Parent then tweenOut:Play() end
	end))
	tweenOut:Play()
end

local function makeLaunchPad(name, pos, velocity, color, cooldown)
	local base = solid(name, Vector3.new(12, 1.2, 12), pos, "Really black")
	local glow = neon(name .. "Glow", Vector3.new(11.2, 0.22, 11.2), pos + Vector3.new(0, 0.72, 0), color, 0.08)
	ball(name .. "Orb", 2.2, pos + Vector3.new(0, 2.8, 0), color, 0.08)
	makePulse(glow, 0.08, 0.5, 0.55)

	addConn(base.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or padDebounce[player] then return end
		padDebounce[player] = true
		launchPlayer(player, velocity, 0.25)
		glow.BrickColor = BrickColor.new("White")
		task.delay(0.15, function()
			if glow.Parent then glow.BrickColor = BrickColor.new(color) end
		end)
		task.delay(cooldown or 0.4, function()
			padDebounce[player] = nil
		end)
	end))
end

local function makeDirectionalArrow(name, pos, angle, color)
	local shaft = neon(name .. "Shaft", Vector3.new(1.3, 0.22, 9), CFrame.new(pos) * CFrame.Angles(0, angle, 0), color, 0.1)
	local head = Instance.new("WedgePart")
	head.Name = name .. "Head"
	head.Size = Vector3.new(5, 0.25, 5)
	head.CFrame = CFrame.new(pos + Vector3.new(math.sin(angle) * 5.7, 0.05, math.cos(angle) * 5.7)) * CFrame.Angles(0, angle, 0)
	head.BrickColor = BrickColor.new(color)
	head.Material = Enum.Material.Neon
	head.Anchored = true
	head.CanCollide = false
	head.CanTouch = true
	head.CastShadow = false
	head.Transparency = 0.1
	head.Parent = worldFolder
	return shaft, head
end

local function makePlatform(name, pos, size, color, glowColor)
	solid(name, size, pos, color)
	neon(name .. "Glow", Vector3.new(size.X - 1, 0.22, size.Z - 1), pos + Vector3.new(0, size.Y / 2 + 0.15, 0), glowColor or "Bright violet", 0.18)
end

local function makeMovingPlatform(name, y, radius, startAngle, speed, color)
	local plat = solid(name, Vector3.new(24, 2.2, 12), Vector3.new(CX + math.cos(startAngle) * radius, y, CZ + math.sin(startAngle) * radius), color)
	local glow = neon(name .. "Glow", Vector3.new(23, 0.25, 11), plat.Position + Vector3.new(0, 1.22, 0), "Cyan", 0.18)
	local angle = startAngle
	addConn(RunService.Heartbeat:Connect(function(dt)
		if not plat.Parent or not glow.Parent then return end
		angle += dt * speed
		local cf = CFrame.new(CX + math.cos(angle) * radius, y, CZ + math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0)
		plat.CFrame = cf
		glow.CFrame = cf * CFrame.new(0, 1.22, 0)
	end))
end

local function activateCore(player, index, corePart, auraPart)
	if coreDebounce[player] then return end
	coreDebounce[player] = true
	local current = coreProgress[player] or 0
	if current + 1 ~= index then
		launchPlayer(player, Vector3.new(0, 45, 0), 0.16)
		task.delay(0.35, function()
			coreDebounce[player] = nil
		end)
		return
	end

	coreProgress[player] = index
	corePart.BrickColor = BrickColor.new("Lime green")
	auraPart.BrickColor = BrickColor.new("Lime green")
	auraPart.Transparency = 0.05

	local burst = ball("CoreBurst", 7, corePart.Position, "Lime green", 0.25)
	TweenService:Create(burst, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * 18,
		Transparency = 1,
	}):Play()
	Debris:AddItem(burst, 0.45)

	if index < 3 then
		launchPlayer(player, Vector3.new(0, 82 + index * 8, 0), 0.22)
	else
		launchPlayer(player, Vector3.new(0, 148, 0), 0.26)
	end

	task.delay(0.45, function()
		coreDebounce[player] = nil
	end)
end

local function makeCore(index, pos, color)
	local base = solid("CorePad" .. index, Vector3.new(18, 1.5, 18), pos - Vector3.new(0, 1.6, 0), "Really black")
	local aura = cylinder("CoreAura" .. index, Vector3.new(0.35, 17, 17), CFrame.new(pos - Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.Neon, 0.18)
	local core = ball("NovaCore" .. index, 5.2, pos + Vector3.new(0, 3.4, 0), color, 0.05)
	local labelPlate = neon("CoreNumber" .. index, Vector3.new(5, 0.2, 5), pos + Vector3.new(0, 0.1, 0), "Institutional white", 0.25)

	makePulse(aura, 0.18, 0.62, 0.7)
	addConn(base.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then activateCore(player, index, core, aura) end
	end))
	addConn(core.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then activateCore(player, index, core, aura) end
	end))

	return labelPlate
end

local function buildRoom()
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "NovaSpireWorld"
	worldFolder.Parent = workspace

	local xMin = CX - HW - WALL_T
	local xMax = CX + HW + WALL_T
	local yMin = FLOOR_Y
	local yMax = FLOOR_Y + WALL_H

	solid("Floor", Vector3.new(HW * 2, 4, HD * 2), Vector3.new(CX, FLOOR_Y - 2, CZ), "Really black")
	neon("FloorWash", Vector3.new(HW * 2 - 2, 0.1, HD * 2 - 2), Vector3.new(CX, FLOOR_Y + 0.05, CZ), "Royal purple", 0.86)
	neon("MainPath", Vector3.new(18, 0.18, HD * 2 - 8), Vector3.new(CX, FLOOR_Y + 0.16, CZ), "Cyan", 0.45)
	neon("CoreMap", Vector3.new(HW * 2 - 14, 0.18, 1.2), Vector3.new(CX, FLOOR_Y + 0.2, CZ), "Bright violet", 0.32)
	makeDirectionalArrow("EntryArrow", Vector3.new(CX, FLOOR_Y + 0.35, CZ - 39), 0, "Bright yellow")

	local northDoor = { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H }
	local southDoor = { alongMin = CX - DOOR_HALF, alongMax = CX + DOOR_HALF, yBot = yMin, yTop = yMin + DOOR_H }
	buildWall(true, CX - HW - WALL_T / 2, CZ - HD - WALL_T, CZ + HD + WALL_T, yMin, yMax, {})
	buildWall(true, CX + HW + WALL_T / 2, CZ - HD - WALL_T, CZ + HD + WALL_T, yMin, yMax, {})
	buildWall(false, CZ - HD - WALL_T / 2, xMin, xMax, yMin, yMax, { northDoor })
	buildWall(false, CZ + HD + WALL_T / 2, xMin, xMax, yMin, yMax, { southDoor })

	for i = 1, 18 do
		local a = i / 18 * math.pi * 2
		local r = 32 + (i % 3) * 8
		ball("FloorStar" .. i, 0.65, Vector3.new(CX + math.cos(a) * r, FLOOR_Y + 0.55, CZ + math.sin(a) * r), "Institutional white", 0.35)
	end

	-- Phase 1: launch into the first core.
	makeLaunchPad("StartNovaLauncher", Vector3.new(CX, FLOOR_Y + 0.6, CZ - 34), Vector3.new(0, 88, 42), "Bright violet", 0.35)
	makePlatform("LowerSafePlate", Vector3.new(CX, FLOOR_Y + 22, CZ - 8), Vector3.new(30, 2, 18), "Dark indigo", "Cyan")
	makeCore(1, Vector3.new(CX, FLOOR_Y + 25, CZ + 18), "Bright violet")
	makeLaunchPad("CoreOneBoost", Vector3.new(CX, FLOOR_Y + 25.7, CZ + 30), Vector3.new(-38, 98, 22), "Cyan", 0.35)

	-- Phase 2: moving orbit and side core.
	makePlatform("LeftRestPlate", Vector3.new(CX - 36, FLOOR_Y + 54, CZ + 12), Vector3.new(22, 2, 20), "Dark indigo", "Bright violet")
	makePlatform("RightRestPlate", Vector3.new(CX + 36, FLOOR_Y + 54, CZ + 12), Vector3.new(22, 2, 20), "Dark indigo", "Hot pink")
	makeMovingPlatform("OrbitPlateA", FLOOR_Y + 58, 28, 0, 0.6, "Royal purple")
	makeMovingPlatform("OrbitPlateB", FLOOR_Y + 58, 28, math.pi, 0.6, "Magenta")
	makeCore(2, Vector3.new(CX - 34, FLOOR_Y + 58, CZ + 28), "Hot pink")
	makeLaunchPad("CoreTwoBoost", Vector3.new(CX - 34, FLOOR_Y + 58.8, CZ + 41), Vector3.new(46, 112, -12), "Hot pink", 0.35)
	makeLaunchPad("MissRecoveryA", Vector3.new(CX + 35, FLOOR_Y + 54.8, CZ - 22), Vector3.new(-42, 90, 36), "Bright yellow", 0.35)

	-- Phase 3: rotating cross, final core, and portal.
	local upperY = FLOOR_Y + 91
	local hub = solid("UpperHub", Vector3.new(22, 2, 22), Vector3.new(CX, upperY, CZ), "Really black")
	neon("UpperHubGlow", Vector3.new(21, 0.25, 21), Vector3.new(CX, upperY + 1.2, CZ), "Bright yellow", 0.1)
	-- Arms rotate 8 studs BELOW the hub so they block the approach, not the hub surface
	local armY = upperY - 8
	local armA = solid("RotatingArmA", Vector3.new(66, 2, 7), Vector3.new(CX, armY, CZ), "Dark indigo")
	local armAGlow = neon("RotatingArmAGlow", Vector3.new(64, 0.22, 6.2), Vector3.new(CX, armY + 1.2, CZ), "Cyan", 0.15)
	local armB = solid("RotatingArmB", Vector3.new(7, 2, 66), Vector3.new(CX, armY, CZ), "Dark indigo")
	local armBGlow = neon("RotatingArmBGlow", Vector3.new(6.2, 0.22, 64), Vector3.new(CX, armY + 1.2, CZ), "Bright violet", 0.15)
	local armOrbs = {
		ball("ArmOrb1", 2.3, Vector3.new(CX + 33, upperY + 2, CZ), "Bright yellow", 0.08),
		ball("ArmOrb2", 2.3, Vector3.new(CX - 33, upperY + 2, CZ), "Bright yellow", 0.08),
		ball("ArmOrb3", 2.3, Vector3.new(CX, upperY + 2, CZ + 33), "Bright yellow", 0.08),
		ball("ArmOrb4", 2.3, Vector3.new(CX, upperY + 2, CZ - 33), "Bright yellow", 0.08),
	}
	local armAngle = 0
	addConn(RunService.Heartbeat:Connect(function(dt)
		if not hub.Parent then return end
		armAngle += dt * 0.38
		local rot = CFrame.Angles(0, armAngle, 0)
		armA.CFrame = CFrame.new(CX, armY, CZ) * rot
		armAGlow.CFrame = armA.CFrame * CFrame.new(0, 1.2, 0)
		armB.CFrame = CFrame.new(CX, armY, CZ) * rot * CFrame.Angles(0, math.pi / 2, 0)
		armBGlow.CFrame = armB.CFrame * CFrame.new(0, 1.2, 0)
		local offsets = {
			Vector3.new(33, 2, 0),
			Vector3.new(-33, 2, 0),
			Vector3.new(0, 2, 33),
			Vector3.new(0, 2, -33),
		}
		for i, orb in ipairs(armOrbs) do
			if orb.Parent then
				orb.CFrame = CFrame.new(CX, armY, CZ) * rot * CFrame.new(offsets[i])
			end
		end
	end))
	-- Finish lamp marks the top goal; touching the finish platform clears the level.
	solid("FinishLampPost", Vector3.new(2.2, 12, 2.2), Vector3.new(CX, upperY + 7, CZ), "Really black")
	neon("FinishLampCap", Vector3.new(11, 1, 11), Vector3.new(CX, upperY + 13.4, CZ), "Bright yellow", 0.08)
	local finishLamp = ball("FinishLampGlow", 7, Vector3.new(CX, upperY + 17, CZ), "Bright yellow", 0.12)
	local finishLight = Instance.new("PointLight")
	finishLight.Color = Color3.fromRGB(255, 230, 120)
	finishLight.Brightness = 3.5
	finishLight.Range = 42
	finishLight.Parent = finishLamp

	local trigger = Instance.new("Part")
	trigger.Name = "FinishTrigger"
	trigger.Size = Vector3.new(34, 8, 34)
	trigger.Position = Vector3.new(CX, FINISH_Y + 5, CZ)
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.CanTouch = true
	trigger.Transparency = 1
	trigger.Parent = worldFolder
	addConn(trigger.Touched:Connect(function(hit)
		if not alive then return end
		local player = getPlayerFromHit(hit)
		if player and player:GetAttribute("SkyDescentBoundsActive") then return end
		if not player or finishDebounce[player] then return end
		finishDebounce[player] = true

		remValue.Value = math.max(0, remValue.Value - 1)
		if playerScored then
			playerScored:Fire(player, WORLD_NAME)
		end
		task.delay(6, function()
			finishDebounce[player] = nil
		end)
	end))

	local sp = solid("SignPart", Vector3.new(30, 8, 0.4), Vector3.new(CX + HW + WALL_T + 0.3, FLOOR_Y + 17, CZ), "Really black")
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = sp

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(8, 4, 25)
	bg.BackgroundTransparency = 0.05
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.48, 0)
	title.Position = UDim2.new(0, 0, 0.06, 0)
	title.BackgroundTransparency = 1
	title.Text = "25 - NOVA SPIRE"
	title.TextColor3 = Color3.fromRGB(215, 150, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 26
	title.TextStrokeTransparency = 0.35
	title.Parent = bg

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, 0, 0.38, 0)
	body.Position = UDim2.new(0, 0, 0.56, 0)
	body.BackgroundTransparency = 1
	body.Text = "REACH THE TOP"
	body.TextColor3 = Color3.fromRGB(220, 230, 255)
	body.Font = Enum.Font.GothamBold
	body.TextSize = 18
	body.TextStrokeTransparency = 0.5
	body.Parent = bg
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
	table.clear(finishDebounce)
	table.clear(padDebounce)
	table.clear(coreDebounce)
	table.clear(coreProgress)
end

task.spawn(function()
	local sig = gameEvents and gameEvents:WaitForChild("WorldRestartSignal", 30)
	if sig then
		sig.Event:Connect(function(worldName)
			if worldName ~= WORLD_NAME then return end
			destroyRoom()
			alive = true
			remValue.Value = TARGET
			totValue.Value = TARGET
			buildRoom()
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	finishDebounce[player] = nil
	padDebounce[player] = nil
	coreDebounce[player] = nil
	coreProgress[player] = nil
end)

alive = true
remValue.Value = TARGET
totValue.Value = TARGET
buildRoom()
print("[NovaSpire] World 25 built with ordered core activation logic.")
