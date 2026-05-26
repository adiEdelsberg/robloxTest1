-- PlaygroundLevel30Shortcut.server.luau
-- East-side playground shortcut room that launches players to level 30.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local skyDescent = require(script.Parent:WaitForChild("SkyDescent"))

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local worldRestartSignal = gameEvents:FindFirstChild("WorldRestartSignal")

local folder = workspace:FindFirstChild("PlaygroundLevel30Shortcut")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "PlaygroundLevel30Shortcut"
folder.Parent = workspace

local GROUND_Y = 1
local DOOR_X = 59
local ROOM_X = 154
local ROOM_Z = 0
local ROOM_W = 62
local ROOM_D = 58
local ROOM_H = 36
local BRIDGE_X1 = 59
local BRIDGE_X2 = 122
local BRIDGE_W = 24

local APEX_NEXUS_BOUNDS = { minX = -2944, maxX = -2776, minZ = 4366, maxZ = 4534 }
local APEX_NEXUS_SPAWN = CFrame.new(-2860, 8, 4450)
local launchDebounce = {}
local CLEAR_MIN = Vector3.new(DOOR_X - 8, GROUND_Y - 2, -18)
local CLEAR_MAX = Vector3.new(ROOM_X + 22, GROUND_Y + 34, 18)

local function part(name, size, cfOrPos, color, material, transparency, canCollide)
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
	p.CanCollide = canCollide ~= false
	p.CanTouch = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function glow(name, size, pos, color, transparency)
	return part(name, size, pos, color, Enum.Material.Neon, transparency or 0.18, false)
end

local function cylinder(name, size, cf, color, transparency)
	local p = part(name, size, cf, color, Enum.Material.Neon, transparency or 0.15, false)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function overlapsClearZone(object)
	local half = object.Size / 2
	local min = object.Position - half
	local max = object.Position + half
	return min.X <= CLEAR_MAX.X and max.X >= CLEAR_MIN.X
		and min.Y <= CLEAR_MAX.Y and max.Y >= CLEAR_MIN.Y
		and min.Z <= CLEAR_MAX.Z and max.Z >= CLEAR_MIN.Z
end

local function shouldKeepCollidable(object)
	if object.Size.Y <= 3 and object.Position.Y <= GROUND_Y + 4 then
		return true
	end
	if object.Name:find("SafetyFloor") or object.Name:find("GapSupport") then
		return true
	end
	if not object:IsDescendantOf(folder) then
		return false
	end
	if object.Name:find("Floor") or object.Name == "Level30ShortcutBridge" or object.Name == "Level30ShortcutLaunchPad" then
		return true
	end
	return false
end

local function clearShortcutCorridor()
	for _, object in workspace:GetDescendants() do
		if object:IsA("BasePart") and object.CanCollide and overlapsClearZone(object) and not shouldKeepCollidable(object) then
			object.CanCollide = false
			object.CanTouch = false
			if object.Transparency >= 0.42 or object.Name:find("Barrier") or object.Name:find("GlassCube") or object.Name:find("StyledWall") or object.Name:find("Gate") then
				object.Transparency = 1
			end
		end
	end
end

local function addStaticSign(name, text, cf, size, color, textColor)
	local sign = part(name, size, cf, "Really black", Enum.Material.Metal, 0.03, false)
	local trim = glow(name .. "Glow", size + Vector3.new(0.35, 0.35, 0.18), cf.Position + cf.LookVector * 0.08, color, 0.58)
	trim.CFrame = cf
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 32
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = sign

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(4, 8, 18)
		label.BackgroundTransparency = 0.08
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = textColor
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0.16
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = gui
	end
end

local function emitLaunchEffects(origin)
	for i = 1, 14 do
		local orb = glow("ApexLaunchBurst", Vector3.one * (1.4 + (i % 3)), origin + Vector3.new(math.random(-9, 9), math.random(4, 16), math.random(-9, 9)), i % 2 == 0 and "Bright yellow" or "Bright violet", 0.1)
		orb.Shape = Enum.PartType.Ball
		Debris:AddItem(orb, 1.6)
	end
	local beam = glow("ApexLaunchBeam", Vector3.new(4, 120, 4), origin + Vector3.new(0, 58, 0), "Bright yellow", 0.45)
	Debris:AddItem(beam, 1.1)
end

local function launchToLevel30(player)
	if launchDebounce[player] then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp then return end

	launchDebounce[player] = true
	player:SetAttribute("InLandingWorld", false)
	player:SetAttribute("CheckpointOrder", 30)
	player:SetAttribute("CheckpointName", "Apex Nexus")
	player:SetAttribute("CompletionAirLaunchActive", true)

	if humanoid then
		humanoid.Sit = false
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	emitLaunchEffects(hrp.Position)
	hrp.AssemblyLinearVelocity = Vector3.new(0, 260, 0)

	task.delay(0.45, function()
		if not player.Parent then return end
		local currentCharacter = player.Character
		local currentHrp = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
		if not currentHrp then return end
		if worldRestartSignal then
			worldRestartSignal:Fire("Apex Nexus")
		end
		skyDescent(currentHrp, APEX_NEXUS_SPAWN, APEX_NEXUS_BOUNDS, 2.2)
		task.delay(2.8, function()
			if player.Parent then
				player:SetAttribute("CompletionAirLaunchActive", false)
			end
		end)
	end)

	task.delay(4, function()
		launchDebounce[player] = nil
	end)
end

part("Level30ShortcutBridge", Vector3.new(BRIDGE_X2 - BRIDGE_X1, 1, BRIDGE_W), Vector3.new((BRIDGE_X1 + BRIDGE_X2) / 2, GROUND_Y + 0.15, 0), "Really black", Enum.Material.Metal, 0)
glow("Level30ShortcutBridgeGlow", Vector3.new(BRIDGE_X2 - BRIDGE_X1 - 4, 0.18, BRIDGE_W - 4), Vector3.new((BRIDGE_X1 + BRIDGE_X2) / 2, GROUND_Y + 0.75, 0), "Bright yellow", 0.52)
for _, z in { -BRIDGE_W / 2, BRIDGE_W / 2 } do
	part("Level30ShortcutBridgeWall", Vector3.new(BRIDGE_X2 - BRIDGE_X1, 18, 1.2), Vector3.new((BRIDGE_X1 + BRIDGE_X2) / 2, GROUND_Y + 9, z), "Bright yellow", Enum.Material.ForceField, 0.66)
end

part("Level30ShortcutGateLeft", Vector3.new(2.5, 26, 2.5), Vector3.new(DOOR_X + 1, GROUND_Y + 13, -14), "Dark stone grey", Enum.Material.Metal, 0)
part("Level30ShortcutGateRight", Vector3.new(2.5, 26, 2.5), Vector3.new(DOOR_X + 1, GROUND_Y + 13, 14), "Dark stone grey", Enum.Material.Metal, 0)
part("Level30ShortcutGateTop", Vector3.new(2.5, 2.5, 31), Vector3.new(DOOR_X + 1, GROUND_Y + 26, 0), "Dark stone grey", Enum.Material.Metal, 0)
glow("Level30ShortcutGateNeon", Vector3.new(1, 1, 34), Vector3.new(DOOR_X + 2.4, GROUND_Y + 28, 0), "Bright violet", 0.05)

part("Level30ShortcutRoomFloor", Vector3.new(ROOM_W, 1, ROOM_D), Vector3.new(ROOM_X, GROUND_Y - 0.35, ROOM_Z), "Really black", Enum.Material.SmoothPlastic, 0)
part("Level30ShortcutRoomBackWall", Vector3.new(1, ROOM_H, ROOM_D), Vector3.new(ROOM_X + ROOM_W / 2, GROUND_Y + ROOM_H / 2, ROOM_Z), "Bright yellow", Enum.Material.Glass, 0.62)
part("Level30ShortcutRoomNorthWall", Vector3.new(ROOM_W, ROOM_H, 1), Vector3.new(ROOM_X, GROUND_Y + ROOM_H / 2, ROOM_Z - ROOM_D / 2), "Bright yellow", Enum.Material.Glass, 0.62)
part("Level30ShortcutRoomSouthWall", Vector3.new(ROOM_W, ROOM_H, 1), Vector3.new(ROOM_X, GROUND_Y + ROOM_H / 2, ROOM_Z + ROOM_D / 2), "Bright yellow", Enum.Material.Glass, 0.62)
part("Level30ShortcutRoomRoof", Vector3.new(ROOM_W, 1, ROOM_D), Vector3.new(ROOM_X, GROUND_Y + ROOM_H, ROOM_Z), "Bright yellow", Enum.Material.Glass, 0.74)

local launchPad = cylinder("Level30ShortcutLaunchPad", Vector3.new(0.7, 24, 24), CFrame.new(ROOM_X + 8, GROUND_Y + 0.8, ROOM_Z) * CFrame.Angles(0, 0, math.rad(90)), "Bright violet", 0.18)
cylinder("Level30ShortcutLaunchRing", Vector3.new(0.45, 34, 34), CFrame.new(ROOM_X + 8, GROUND_Y + 1.1, ROOM_Z) * CFrame.Angles(0, 0, math.rad(90)), "Bright yellow", 0.55)
glow("Level30ShortcutLaunchBeamIdle", Vector3.new(2.2, 74, 2.2), Vector3.new(ROOM_X + 8, GROUND_Y + 38, ROOM_Z), "Bright violet", 0.72)
addStaticSign(
	"Level30ShortcutStaticSign",
	"LEVEL 30\nAPEX NEXUS\nLAUNCH",
	CFrame.new(ROOM_X + 8, GROUND_Y + 10.5, ROOM_Z - 25),
	Vector3.new(27, 9, 0.55),
	"Bright yellow",
	Color3.fromRGB(255, 235, 120)
)

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Launch"
prompt.ObjectText = "Level 30 Shortcut"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.HoldDuration = 0.15
prompt.MaxActivationDistance = 18
prompt.Parent = launchPad
prompt.Triggered:Connect(launchToLevel30)

launchPad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		launchToLevel30(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	launchDebounce[player] = nil
end)

task.spawn(function()
	for _ = 1, 24 do
		clearShortcutCorridor()
		task.wait(0.5)
	end
end)

workspace.DescendantAdded:Connect(function(object)
	if object:IsA("BasePart") then
		task.defer(function()
			if object.Parent and object.CanCollide and overlapsClearZone(object) and not shouldKeepCollidable(object) then
				object.CanCollide = false
				object.CanTouch = false
				if object.Transparency >= 0.42 or object.Name:find("Barrier") or object.Name:find("GlassCube") or object.Name:find("StyledWall") or object.Name:find("Gate") then
					object.Transparency = 1
				end
			end
		end)
	end
end)

print("[PlaygroundLevel30Shortcut] Built east playground shortcut to level 30.")
