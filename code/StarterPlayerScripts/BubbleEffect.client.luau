-- BubbleEffect.client.luau
-- Plays local visual effects when a player bubble launches or pops.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local function spawnPopBurst(position)
	-- Expanding ring flash
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Ball
	ring.Size = Vector3.new(5, 5, 5)
	ring.CFrame = CFrame.new(position)
	ring.BrickColor = BrickColor.new("Cyan")
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.25
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Parent = workspace
	TweenService:Create(ring,
		TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(26, 26, 26), Transparency = 1 }
	):Play()
	Debris:AddItem(ring, 0.6)

	-- Particle emitter burst
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.1
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80,  220, 255)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(180, 245, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Speed          = NumberRange.new(20, 45)
	emitter.SpreadAngle    = Vector2.new(180, 180)
	emitter.Lifetime       = NumberRange.new(0.7, 1.6)
	emitter.Size           = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.5),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency   = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.RotSpeed = NumberRange.new(-220, 220)
	emitter.Rate     = 0
	emitter.Parent   = anchor
	emitter:Emit(90)

	-- Second emitter: slower glowing fragments
	local emitter2 = Instance.new("ParticleEmitter")
	emitter2.Color        = ColorSequence.new(Color3.fromRGB(160, 255, 255))
	emitter2.LightEmission = 0.9
	emitter2.Speed         = NumberRange.new(5, 18)
	emitter2.SpreadAngle   = Vector2.new(180, 180)
	emitter2.Lifetime      = NumberRange.new(1.2, 2.5)
	emitter2.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter2.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter2.Rate   = 0
	emitter2.Parent = anchor
	emitter2:Emit(40)

	Debris:AddItem(anchor, 3)
end

task.spawn(function()
	local gameEvents  = ReplicatedStorage:WaitForChild("GameEvents", 30)
	if not gameEvents then return end
	local bubbleEvent = gameEvents:WaitForChild("BubbleEvent", 30)
	if not bubbleEvent then return end

	bubbleEvent.OnClientEvent:Connect(function(eventType, position)
		if eventType == "Pop" then
			spawnPopBurst(position)
		end
		-- "Launch" could trigger a whoosh sound in future; nothing visual needed from client
	end)
end)
