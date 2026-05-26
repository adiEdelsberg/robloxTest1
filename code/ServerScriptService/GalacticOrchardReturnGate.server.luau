-- GalacticOrchardReturnGate.server.luau
-- Adds a room-16 return launcher that sends players back to room 8 / Coffee Shop.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local skyDescent = require(script.Parent:WaitForChild("SkyDescent"))

local folder = workspace:FindFirstChild("GalacticOrchardReturnGate")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "GalacticOrchardReturnGate"
folder.Parent = workspace

local GROUND_Y = 1
local GATE_X = 2980
local GATE_Z = 1700
local ROOM_X = 3056
local ROOM_W = 58
local ROOM_D = 62
local ROOM_H = 36
local BRIDGE_X1 = GATE_X
local BRIDGE_X2 = ROOM_X - ROOM_W / 2
local BRIDGE_W = 24
local COFFEE_SPAWN = CFrame.new(0, 8, 1558)
local COFFEE_BOUNDS = { minX = -140, maxX = 140, minZ = 1540, maxZ = 1860 }
local launchDebounce = {}
local CLEAR_MIN = Vector3.new(GATE_X - 12, GROUND_Y - 2, GATE_Z - 42)
local CLEAR_MAX = Vector3.new(ROOM_X + ROOM_W / 2 + 8, GROUND_Y + 34, GATE_Z + 42)

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
	if not object:IsDescendantOf(folder) then return false end
	return object.Name:find("Floor") ~= nil
		or object.Name == "GalacticOrchardReturnBridge"
		or object.Name == "GalacticOrchardReturnLaunchPad"
end

local function clearReturnCorridor()
	for _, object in workspace:GetDescendants() do
		if object:IsA("BasePart") and object.CanCollide and overlapsClearZone(object) and not shouldKeepCollidable(object) then
			object.CanCollide = false
			object.CanTouch = false
			if object.Transparency >= 0.98 or object.Name:find("Barrier") or object.Name:find("GlassCube") or object.Name:find("JumpBlocker") then
				object.Transparency = 1
			end
		end
	end
end

local function addStaticSign(name, text, cf, size, color, textColor)
	local sign = part(name, size, cf, "Really black", Enum.Material.Metal, 0.03, false)
	local trim = glow(name .. "Glow", size + Vector3.new(0.35, 0.35, 0.18), cf.Position + cf.RightVector * 0.08, color, 0.58)
	trim.CFrame = cf
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 32
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = sign

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(7, 8, 18)
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

local function emitReturnEffects(origin)
	for i = 1, 16 do
		local orb = glow("OrchardReturnBurst", Vector3.one * (1.2 + (i % 4)), origin + Vector3.new(math.random(-10, 10), math.random(3, 18), math.random(-10, 10)), i % 2 == 0 and "Bright orange" or "Cyan", 0.1)
		orb.Shape = Enum.PartType.Ball
		Debris:AddItem(orb, 1.5)
	end
	local beam = glow("OrchardReturnBeam", Vector3.new(4, 115, 4), origin + Vector3.new(0, 56, 0), "Bright orange", 0.45)
	Debris:AddItem(beam, 1.1)
end

local function launchToRoom8(player)
	if launchDebounce[player] then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp then return end

	launchDebounce[player] = true
	player:SetAttribute("InLandingWorld", false)
	player:SetAttribute("CheckpointOrder", 8)
	player:SetAttribute("CheckpointName", "Coffee Shop")
	player:SetAttribute("CompletionAirLaunchActive", true)

	if humanoid then
		humanoid.Sit = false
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	emitReturnEffects(hrp.Position)
	hrp.AssemblyLinearVelocity = Vector3.new(0, 245, 0)

	task.delay(0.45, function()
		if not player.Parent then return end
		local currentCharacter = player.Character
		local currentHrp = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
		if not currentHrp then return end
		skyDescent(currentHrp, COFFEE_SPAWN, COFFEE_BOUNDS, 1.6)
		task.delay(2.2, function()
			if player.Parent then
				player:SetAttribute("CompletionAirLaunchActive", false)
			end
		end)
	end)

	task.delay(4, function()
		launchDebounce[player] = nil
	end)
end

part("GalacticOrchardReturnBridge", Vector3.new(BRIDGE_X2 - BRIDGE_X1, 1, BRIDGE_W), Vector3.new((BRIDGE_X1 + BRIDGE_X2) / 2, GROUND_Y + 0.15, GATE_Z), "Really black", Enum.Material.Metal, 0)
glow("GalacticOrchardReturnBridgeGlow", Vector3.new(BRIDGE_X2 - BRIDGE_X1 - 4, 0.18, BRIDGE_W - 4), Vector3.new((BRIDGE_X1 + BRIDGE_X2) / 2, GROUND_Y + 0.75, GATE_Z), "Bright orange", 0.52)
for _, z in { GATE_Z - BRIDGE_W / 2, GATE_Z + BRIDGE_W / 2 } do
	part("GalacticOrchardReturnBridgeWall", Vector3.new(BRIDGE_X2 - BRIDGE_X1, 18, 1.2), Vector3.new((BRIDGE_X1 + BRIDGE_X2) / 2, GROUND_Y + 9, z), "Bright orange", Enum.Material.ForceField, 0.66)
end

part("GalacticOrchardReturnGateFloor", Vector3.new(34, 1, 44), Vector3.new(GATE_X + 8, GROUND_Y + 0.05, GATE_Z), "Really black", Enum.Material.Metal, 0)
glow("GalacticOrchardReturnGateFloorGlow", Vector3.new(28, 0.14, 38), Vector3.new(GATE_X + 8, GROUND_Y + 0.68, GATE_Z), "Bright orange", 0.62)
part("GalacticOrchardReturnGateLeft", Vector3.new(3, 30, 3), Vector3.new(GATE_X + 1, GROUND_Y + 15, GATE_Z - 18), "Dark stone grey", Enum.Material.Metal, 0, false)
part("GalacticOrchardReturnGateRight", Vector3.new(3, 30, 3), Vector3.new(GATE_X + 1, GROUND_Y + 15, GATE_Z + 18), "Dark stone grey", Enum.Material.Metal, 0, false)
part("GalacticOrchardReturnGateTop", Vector3.new(3, 3, 39), Vector3.new(GATE_X + 1, GROUND_Y + 30, GATE_Z), "Dark stone grey", Enum.Material.Metal, 0, false)
glow("GalacticOrchardReturnGateArchGlow", Vector3.new(0.8, 0.8, 41), Vector3.new(GATE_X + 1, GROUND_Y + 32, GATE_Z), "Bright orange", 0.06)

part("GalacticOrchardReturnRoomFloor", Vector3.new(ROOM_W, 1, ROOM_D), Vector3.new(ROOM_X, GROUND_Y - 0.35, GATE_Z), "Really black", Enum.Material.SmoothPlastic, 0)
part("GalacticOrchardReturnRoomBackWall", Vector3.new(1, ROOM_H, ROOM_D), Vector3.new(ROOM_X + ROOM_W / 2, GROUND_Y + ROOM_H / 2, GATE_Z), "Bright orange", Enum.Material.Glass, 0.62)
part("GalacticOrchardReturnRoomNorthWall", Vector3.new(ROOM_W, ROOM_H, 1), Vector3.new(ROOM_X, GROUND_Y + ROOM_H / 2, GATE_Z - ROOM_D / 2), "Bright orange", Enum.Material.Glass, 0.62)
part("GalacticOrchardReturnRoomSouthWall", Vector3.new(ROOM_W, ROOM_H, 1), Vector3.new(ROOM_X, GROUND_Y + ROOM_H / 2, GATE_Z + ROOM_D / 2), "Bright orange", Enum.Material.Glass, 0.62)
part("GalacticOrchardReturnRoomRoof", Vector3.new(ROOM_W, 1, ROOM_D), Vector3.new(ROOM_X, GROUND_Y + ROOM_H, GATE_Z), "Bright orange", Enum.Material.Glass, 0.74)

local pad = cylinder("GalacticOrchardReturnLaunchPad", Vector3.new(0.7, 22, 22), CFrame.new(ROOM_X, GROUND_Y + 0.9, GATE_Z) * CFrame.Angles(0, 0, math.rad(90)), "Bright orange", 0.16)
cylinder("GalacticOrchardReturnLaunchRing", Vector3.new(0.45, 32, 32), CFrame.new(ROOM_X, GROUND_Y + 1.2, GATE_Z) * CFrame.Angles(0, 0, math.rad(90)), "Cyan", 0.5)
glow("GalacticOrchardReturnIdleBeam", Vector3.new(2.1, 70, 2.1), Vector3.new(ROOM_X, GROUND_Y + 36, GATE_Z), "Bright orange", 0.72)
addStaticSign(
	"GalacticOrchardReturnStaticSign",
	"RETURN\nROOM 8",
	CFrame.new(ROOM_X + 25, GROUND_Y + 10.5, GATE_Z),
	Vector3.new(0.55, 9, 27),
	"Bright orange",
	Color3.fromRGB(255, 185, 80)
)

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Launch"
prompt.ObjectText = "Return to Room 8"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.HoldDuration = 0.15
prompt.MaxActivationDistance = 18
prompt.Parent = pad
prompt.Triggered:Connect(launchToRoom8)

pad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		launchToRoom8(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	launchDebounce[player] = nil
end)

task.spawn(function()
	for _ = 1, 20 do
		clearReturnCorridor()
		task.wait(0.5)
	end
end)

workspace.DescendantAdded:Connect(function(object)
	if object:IsA("BasePart") then
		task.defer(function()
			if object.Parent and object.CanCollide and overlapsClearZone(object) and not shouldKeepCollidable(object) then
				object.CanCollide = false
				object.CanTouch = false
			end
		end)
	end
end)

print("[GalacticOrchardReturnGate] Built room 16 return gate to room 8.")
