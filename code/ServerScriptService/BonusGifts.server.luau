local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CashService = require(script.Parent:WaitForChild("CashService"))
local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local folder = workspace:FindFirstChild("BonusSurpriseGifts")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "BonusSurpriseGifts"
	folder.Parent = workspace
else
	folder:ClearAllChildren()
end

local giftEvent = ReplicatedStorage:FindFirstChild("BonusGiftEvent")
if giftEvent and not giftEvent:IsA("RemoteEvent") then
	giftEvent:Destroy()
	giftEvent = nil
end
if not giftEvent then
	giftEvent = Instance.new("RemoteEvent")
	giftEvent.Name = "BonusGiftEvent"
	giftEvent.Parent = ReplicatedStorage
end

local TOUCH_COOLDOWN = 0.8
local GIFT_Y = 3.4
local DROP_HEIGHT = 95
local DROP_SECONDS = 4.2
local DROP_INTERVAL_MIN = 14
local DROP_INTERVAL_MAX = 28
local GIFT_LIFETIME_SECONDS = 50
local MAX_ACTIVE_GIFTS = 4
local JUMP_POWERS = Balance.Movement.JumpPowers
local WALK_SPEEDS = Balance.Movement.WalkSpeeds

local GIFT_SPOTS = {
	{ name = "Playground Start", pos = Vector3.new(-34, GIFT_Y, 18), color = "Bright yellow" },
	{ name = "Pizza Bridge", pos = Vector3.new(26, GIFT_Y, 104), color = "Bright orange" },
	{ name = "Pizza Road", pos = Vector3.new(-38, GIFT_Y, 208), color = "Hot pink" },
	{ name = "Galactic Bridge", pos = Vector3.new(32, GIFT_Y, 328), color = "Royal purple" },
	{ name = "Galactic Road", pos = Vector3.new(-38, GIFT_Y, 462), color = "Cyan" },
	{ name = "Jungle Bridge", pos = Vector3.new(34, GIFT_Y, 584), color = "Bright green" },
	{ name = "Jungle Road", pos = Vector3.new(-42, GIFT_Y, 706), color = "Lime green" },
	{ name = "Sports Bridge", pos = Vector3.new(44, GIFT_Y, 832), color = "New Yeller" },
	{ name = "Tennis Bridge", pos = Vector3.new(-38, GIFT_Y, 1058), color = "Bright blue" },
	{ name = "Game Station Bridge", pos = Vector3.new(38, GIFT_Y, 1270), color = "Really red" },
	{ name = "Coffee Door", pos = Vector3.new(-72, GIFT_Y, 1505), color = "Bright orange" },
	{ name = "Burger Connector", pos = Vector3.new(176, GIFT_Y, 1700), color = "Bright yellow" },
	{ name = "New Pizza Connector", pos = Vector3.new(532, GIFT_Y, 1700), color = "Really red" },
	{ name = "Pool Connector", pos = Vector3.new(882, GIFT_Y, 1700), color = "Cyan" },
	{ name = "Dino Connector", pos = Vector3.new(1232, GIFT_Y, 1700), color = "Bright green" },
	{ name = "Dino Beach Connector", pos = Vector3.new(1584, GIFT_Y, 1700), color = "New Yeller" },
	{ name = "Forest Connector", pos = Vector3.new(1938, GIFT_Y, 1700), color = "Bright green" },
	{ name = "Cherry Connector", pos = Vector3.new(2288, GIFT_Y, 1700), color = "Really red" },
	{ name = "Orchard Connector", pos = Vector3.new(2642, GIFT_Y, 1700), color = "Cyan" },
}

local giftBoosts = {}
local activeDrops = {}

local function getPlayerFromHit(hit)
	local character = hit and hit.Parent
	if not character then return nil end
	return Players:GetPlayerFromCharacter(character)
end

local function notify(player, message)
	giftEvent:FireClient(player, message)
end

local function markGiftBoost(player, attrName)
	giftBoosts[player] = giftBoosts[player] or {}
	giftBoosts[player][attrName] = true
end

local function applyMovementStats(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if player:GetAttribute("SkateboardMounted") then return end
	humanoid.WalkSpeed = WALK_SPEEDS[player:GetAttribute("SpeedBoost") or 0] or WALK_SPEEDS[0]
	humanoid.JumpPower = JUMP_POWERS[player:GetAttribute("JumpBoost") or 0] or JUMP_POWERS[0]
end

local function giveReward(player)
	local roll = math.random(1, 100)
	if roll <= 45 then
		local amount = math.random(125, 450)
		CashService.add(player, amount)
		return "+$" .. tostring(amount)
	elseif roll <= 62 then
		local tier = math.min(5, math.max(player:GetAttribute("SpeedBoost") or 0, math.random(1, 3)))
		player:SetAttribute("SpeedBoost", tier)
		markGiftBoost(player, "SpeedBoost")
		applyMovementStats(player)
		return "Speed surprise!"
	elseif roll <= 79 then
		local tier = math.min(5, math.max(player:GetAttribute("JumpBoost") or 0, math.random(1, 3)))
		player:SetAttribute("JumpBoost", tier)
		markGiftBoost(player, "JumpBoost")
		applyMovementStats(player)
		return "Jump surprise!"
	elseif roll <= 91 then
		player:SetAttribute("BallSpread", 1)
		markGiftBoost(player, "BallSpread")
		return "Multi-ball surprise!"
	else
		local tier = math.min(3, (player:GetAttribute("BallDamage") or 0) + 1)
		player:SetAttribute("BallDamage", tier)
		markGiftBoost(player, "BallDamage")
		return "Damage surprise!"
	end
end

local function makePart(parent, name, size, cf, color, material, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.BrickColor = BrickColor.new(color)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = canCollide == true
	part.CanTouch = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function burstAt(position, color)
	local effect = makePart(folder, "BonusGiftEffect", Vector3.new(1, 1, 1), CFrame.new(position), "Institutional white", Enum.Material.Neon, 1, false)
	effect.CanTouch = false

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12221967"
	sound.Volume = 0.75
	sound.PlaybackSpeed = 1.45
	sound.Parent = effect
	sound:Play()

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(BrickColor.new(color).Color, Color3.fromRGB(255, 255, 255))
	particles.Lifetime = NumberRange.new(0.45, 0.9)
	particles.Speed = NumberRange.new(12, 22)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rate = 0
	particles.LightEmission = 0.8
	particles.Parent = effect
	particles:Emit(36)

	task.delay(1.2, function()
		if effect.Parent then effect:Destroy() end
	end)
end

local function activeDropCount()
	local count = 0
	for model in activeDrops do
		if model.Parent then
			count += 1
		else
			activeDrops[model] = nil
		end
	end
	return count
end

local function tweenModelTo(model, targetPivot, seconds, easingStyle, easingDirection)
	local pivot = Instance.new("CFrameValue")
	pivot.Value = model:GetPivot()
	local conn = pivot.Changed:Connect(function(value)
		if model.Parent then
			model:PivotTo(value)
		end
	end)
	local tween = TweenService:Create(
		pivot,
		TweenInfo.new(seconds, easingStyle or Enum.EasingStyle.Sine, easingDirection or Enum.EasingDirection.InOut),
		{ Value = targetPivot }
	)
	tween:Play()
	tween.Completed:Connect(function()
		conn:Disconnect()
		pivot:Destroy()
	end)
	return tween
end

local function fadeAndDestroy(model)
	if not model.Parent then return end
	activeDrops[model] = nil
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			object.CanTouch = false
			TweenService:Create(object, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		elseif object:IsA("ParticleEmitter") or object:IsA("Trail") then
			object.Enabled = false
		elseif object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
			TweenService:Create(object, TweenInfo.new(0.35), { Brightness = 0 }):Play()
		end
	end
	task.delay(0.4, function()
		if model.Parent then
			model:Destroy()
		end
	end)
end

local function createGift(spot, index)
	local model = Instance.new("Model")
	model.Name = "BonusGift_" .. tostring(index)
	model.Parent = folder

	local startPos = spot.pos + Vector3.new(0, DROP_HEIGHT, 0)
	local landPos = spot.pos
	local accent = BrickColor.new(spot.color).Color

	local box = makePart(model, "GiftBox", Vector3.new(5.8, 4.6, 5.8), CFrame.new(startPos), spot.color, Enum.Material.Neon, 0.02, false)
	box:SetAttribute("BaseTransparency", box.Transparency)
	local ribbonA = makePart(model, "GiftRibbonA", Vector3.new(6.4, 4.95, 0.62), CFrame.new(startPos), "Institutional white", Enum.Material.Neon, 0.02, false)
	ribbonA:SetAttribute("BaseTransparency", ribbonA.Transparency)
	local ribbonB = makePart(model, "GiftRibbonB", Vector3.new(0.62, 4.98, 6.4), CFrame.new(startPos), "Institutional white", Enum.Material.Neon, 0.02, false)
	ribbonB:SetAttribute("BaseTransparency", ribbonB.Transparency)
	local lid = makePart(model, "GiftLid", Vector3.new(6.8, 0.85, 6.8), CFrame.new(startPos + Vector3.new(0, 2.7, 0)), "Bright yellow", Enum.Material.Neon, 0, false)
	lid:SetAttribute("BaseTransparency", lid.Transparency)
	local bowA = makePart(model, "GiftBowA", Vector3.new(2.8, 0.55, 1.25), CFrame.new(startPos + Vector3.new(-1.35, 3.35, 0)) * CFrame.Angles(0, 0, math.rad(24)), "Institutional white", Enum.Material.Neon, 0.04, false)
	bowA:SetAttribute("BaseTransparency", bowA.Transparency)
	local bowB = makePart(model, "GiftBowB", Vector3.new(2.8, 0.55, 1.25), CFrame.new(startPos + Vector3.new(1.35, 3.35, 0)) * CFrame.Angles(0, 0, math.rad(-24)), "Institutional white", Enum.Material.Neon, 0.04, false)
	bowB:SetAttribute("BaseTransparency", bowB.Transparency)
	local canopy = makePart(model, "GiftParachute", Vector3.new(11, 1.0, 11), CFrame.new(startPos + Vector3.new(0, 10, 0)), "Institutional white", Enum.Material.Neon, 0.18, false)
	canopy.Shape = Enum.PartType.Ball
	canopy:SetAttribute("BaseTransparency", canopy.Transparency)
	for _, offset in {
		Vector3.new(-2.7, 0, -2.7),
		Vector3.new(2.7, 0, -2.7),
		Vector3.new(-2.7, 0, 2.7),
		Vector3.new(2.7, 0, 2.7),
	} do
		local cord = makePart(model, "GiftParachuteCord", Vector3.new(0.16, 8.2, 0.16), CFrame.new(startPos + Vector3.new(offset.X, 6.0, offset.Z)), "Institutional white", Enum.Material.Neon, 0.08, false)
		cord:SetAttribute("BaseTransparency", cord.Transparency)
	end
	local ring = makePart(model, "GiftLandingRing", Vector3.new(12, 0.18, 12), CFrame.new(startPos - Vector3.new(0, 2.55, 0)), spot.color, Enum.Material.Neon, 0.35, false)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = ring.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring:SetAttribute("BaseTransparency", ring.Transparency)
	local trigger = makePart(model, "GiftTrigger", Vector3.new(9, 8, 9), CFrame.new(startPos), spot.color, Enum.Material.ForceField, 1, false)
	trigger:SetAttribute("BaseTransparency", 1)
	trigger.CanTouch = false

	model.PrimaryPart = box

	local light = Instance.new("PointLight")
	light.Color = accent
	light.Brightness = 2.8
	light.Range = 24
	light.Parent = box

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new(accent, Color3.fromRGB(255, 255, 255))
	sparkle.LightEmission = 0.95
	sparkle.Lifetime = NumberRange.new(1.0, 1.8)
	sparkle.Speed = NumberRange.new(0.8, 2.4)
	sparkle.SpreadAngle = Vector2.new(90, 90)
	sparkle.Rate = 12
	sparkle.Parent = box

	local trailAttachmentTop = Instance.new("Attachment")
	trailAttachmentTop.Position = Vector3.new(0, 3, 0)
	trailAttachmentTop.Parent = box
	local trailAttachmentBottom = Instance.new("Attachment")
	trailAttachmentBottom.Position = Vector3.new(0, -3, 0)
	trailAttachmentBottom.Parent = box
	local trail = Instance.new("Trail")
	trail.Color = ColorSequence.new(accent, Color3.fromRGB(255, 255, 255))
	trail.LightEmission = 0.75
	trail.Lifetime = 0.7
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Attachment0 = trailAttachmentTop
	trail.Attachment1 = trailAttachmentBottom
	trail.Parent = box

	local available = false
	local touchCooldown = {}
	activeDrops[model] = true

	trigger.Touched:Connect(function(hit)
		if not available then return end
		local player = getPlayerFromHit(hit)
		if not player then return end
		if touchCooldown[player] then return end
		touchCooldown[player] = true
		task.delay(TOUCH_COOLDOWN, function()
			touchCooldown[player] = nil
		end)

		available = false
		trigger.CanTouch = false
		local message = giveReward(player)
		notify(player, message)
		burstAt(model:GetPivot().Position + Vector3.new(0, 2, 0), spot.color)

		TweenService:Create(box, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(7.2, 5.6, 7.2),
		}):Play()
		task.delay(0.22, function()
			fadeAndDestroy(model)
		end)
	end)

	local landingTween = tweenModelTo(model, CFrame.new(landPos), DROP_SECONDS, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	landingTween.Completed:Connect(function()
		if not model.Parent then return end
		trigger.CanTouch = true
		available = true
		burstAt(landPos + Vector3.new(0, 1.5, 0), spot.color)
		task.delay(GIFT_LIFETIME_SECONDS, function()
			if available and model.Parent then
				available = false
				fadeAndDestroy(model)
			end
		end)
	end)
end

task.spawn(function()
	local nextIndex = 0
	task.wait(3)
	while true do
		if activeDropCount() < MAX_ACTIVE_GIFTS then
			nextIndex += 1
			local spot = GIFT_SPOTS[math.random(1, #GIFT_SPOTS)]
			createGift(spot, nextIndex)
		end
		task.wait(math.random(DROP_INTERVAL_MIN, DROP_INTERVAL_MAX))
	end
end)

Players.PlayerAdded:Connect(function(player)
	giftBoosts[player] = {}
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		local boosts = giftBoosts[player]
		if not boosts then return end
		for attrName in boosts do
			player:SetAttribute(attrName, 0)
			boosts[attrName] = nil
		end
	end)
end)

for _, player in Players:GetPlayers() do
	giftBoosts[player] = giftBoosts[player] or {}
end

Players.PlayerRemoving:Connect(function(player)
	giftBoosts[player] = nil
end)

print("[BonusGifts] Sky-drop surprise gifts enabled across " .. tostring(#GIFT_SPOTS) .. " route spots.")
