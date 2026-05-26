-- NPCController.server
-- Server-side fantasy NPC controller: stats, aggro, movement, attacks, and
-- RemoteEvent VFX hooks. It does not replace existing game systems.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NPCConfig = require(ReplicatedStorage:WaitForChild("NPC"):WaitForChild("NPCConfig"))
local AnimationController = require(ReplicatedStorage:WaitForChild("NPC"):WaitForChild("AnimationController"))

local remotes = ReplicatedStorage:FindFirstChild("NPCVFX") or Instance.new("Folder")
remotes.Name = "NPCVFX"
remotes.Parent = ReplicatedStorage

local vfxRemote = remotes:FindFirstChild("FantasyNPCVFX") or Instance.new("RemoteEvent")
vfxRemote.Name = "FantasyNPCVFX"
vfxRemote.Parent = remotes

local NPCController = {}
NPCController.__index = NPCController
NPCController.Active = {}

local function nearestPlayer(position, range)
	local bestPlayer, bestDist
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local dist = (root.Position - position).Magnitude
			if dist <= range and (not bestDist or dist < bestDist) then
				bestPlayer, bestDist = player, dist
			end
		end
	end
	return bestPlayer, bestDist
end

function NPCController.new(model, enemyId)
	local config = NPCConfig.Get(enemyId)
	local self = setmetatable({}, NPCController)
	self.Model = model
	self.Config = config
	self.Root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	self.Humanoid = model:FindFirstChildWhichIsA("Humanoid")
	self.Health = config.Health
	self.LastAttack = 0
	self.Animation = AnimationController.new(model, config)
	table.insert(NPCController.Active, self)
	self:_bind()
	return self
end

function NPCController:_bind()
	if self.Humanoid then
		self.Humanoid.MaxHealth = self.Config.Health
		self.Humanoid.Health = self.Config.Health
		self.Humanoid.WalkSpeed = self.Config.WalkSpeed
	end
	self.Animation:Play("Idle")
end

function NPCController:Step(dt)
	if not self.Model.Parent or not self.Root then return end
	local targetPlayer, distance = nearestPlayer(self.Root.Position, self.Config.AggroRange)
	if not targetPlayer then
		self.Animation:Play("Idle")
		return
	end

	local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end

	local direction = targetRoot.Position - self.Root.Position
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude > self.Config.AttackRange then
		local move = flat.Unit * self.Config.WalkSpeed * dt
		local nextPos = self.Root.Position + move
		self.Model:PivotTo(CFrame.lookAt(nextPos, Vector3.new(targetRoot.Position.X, nextPos.Y, targetRoot.Position.Z)))
		self.Animation:Play("Run")
	else
		self:Attack(targetPlayer, distance)
	end
end

function NPCController:Attack(player)
	if os.clock() - self.LastAttack < self.Config.AttackCooldown then return end
	self.LastAttack = os.clock()
	self.Animation:AttackPose(0.26)
	vfxRemote:FireAllClients("AttackSwipe", self.Root.Position, self.Config.Style.Accent)

	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid:TakeDamage(self.Config.Damage)
		vfxRemote:FireClient(player, "CameraShake", self.Root.Position, self.Config.Style.Eye)
	end
end

function NPCController:TakeDamage(amount)
	self.Health -= amount
	vfxRemote:FireAllClients("Impact", self.Root.Position, self.Config.Style.Eye)
	if self.Health <= 0 then
		self:Destroy()
	end
end

function NPCController:Destroy()
	self.Animation:Destroy()
	self.Model:Destroy()
end

RunService.Heartbeat:Connect(function(dt)
	for i = #NPCController.Active, 1, -1 do
		local npc = NPCController.Active[i]
		if not npc.Model.Parent then
			table.remove(NPCController.Active, i)
		else
			npc:Step(dt)
		end
	end
end)

return NPCController
