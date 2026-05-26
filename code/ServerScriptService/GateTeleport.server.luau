-- GateTeleport.server.luau
-- Handles client requests to teleport to a gate position.
-- Disabled: worlds now advance only through WorldRunDoors' 10-second launch flow.
if true then return end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")

local remote = Instance.new("RemoteEvent")
remote.Name   = "TeleportToGate"
remote.Parent = gameEvents

-- pos  = where the player lands (just PAST the gate, inside the next level)
-- look = direction the player faces (further into the next level)
local GATE_DATA = {
	-- Z-axis gates: player travels in +Z, so land past the gate at Z+20, face +Z
	Playground             = { pos = Vector3.new( 460, 84,    0), look = Vector3.new( 560, 84,    0) },
	["Empty World 1"]       = { pos = Vector3.new(   0, 4,  142), look = Vector3.new(   0, 4,  190) },
	Pizza                  = { pos = Vector3.new(   0, 4,  292), look = Vector3.new(   0, 4,  340) },
	Galactic               = { pos = Vector3.new(   0, 4,  544), look = Vector3.new(   0, 4,  590) },
	Jungle                 = { pos = Vector3.new(   0, 4,  800), look = Vector3.new(   0, 4,  850) },
	Sports                 = { pos = Vector3.new(   0, 4, 1040), look = Vector3.new(   0, 4,  1090) },
	Tennis                 = { pos = Vector3.new(   0, 4, 1250), look = Vector3.new(   0, 4, 1300) },
	["Game Station"]       = { pos = Vector3.new(   0, 4, 1480), look = Vector3.new(   0, 4, 1530) },
	-- Side gates at Z=1700: player travels in +X into the next area
	["Coffee Shop"]        = { pos = Vector3.new( 200, 4, 1700), look = Vector3.new( 280, 4, 1700) },
	["Burger House"]       = { pos = Vector3.new( 550, 4, 1700), look = Vector3.new( 630, 4, 1700) },
	["New Pizza Place"]    = { pos = Vector3.new( 900, 4, 1700), look = Vector3.new( 980, 4, 1700) },
	["Swimming Pool"]      = { pos = Vector3.new(1250, 4, 1700), look = Vector3.new(1330, 4, 1700) },
	["Dinosaur Park"]      = { pos = Vector3.new(1600, 4, 1700), look = Vector3.new(1680, 4, 1700) },
	["Dino Beach"]         = { pos = Vector3.new(1950, 4, 1700), look = Vector3.new(2030, 4, 1700) },
	["Flying Dino Forest"] = { pos = Vector3.new(2300, 4, 1700), look = Vector3.new(2380, 4, 1700) },
	["Cherry Grove"]       = { pos = Vector3.new(2650, 4, 1700), look = Vector3.new(2730, 4, 1700) },
	["Galactic Orchard"]   = { pos = Vector3.new(3010, 4, 1700), look = Vector3.new(3090, 4, 1700) },
}

remote.OnServerEvent:Connect(function(player, zoneName)
	local data = GATE_DATA[tostring(zoneName)]
	if not data then return end

	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local spawnPos  = data.pos + Vector3.new(0, 3, 0)
	local lookAtPos = data.look + Vector3.new(0, 3, 0)
	hrp.CFrame = CFrame.lookAt(spawnPos, lookAtPos)
end)
