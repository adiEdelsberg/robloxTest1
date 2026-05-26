-- GalacticWorldSelection.server.luau
-- Physical starter-room button + server launch endpoint for the Galactic Worlds selector.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local skyDescent = require(script.Parent:WaitForChild("SkyDescent"))
local SafeLevelSpawn = require(script.Parent:WaitForChild("SafeLevelSpawn"))

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local openEvent = gameEvents:FindFirstChild("OpenGalacticWorldSelection") or Instance.new("RemoteEvent")
openEvent.Name = "OpenGalacticWorldSelection"
openEvent.Parent = gameEvents

local launchEvent = gameEvents:FindFirstChild("LaunchGalacticWorldSelection") or Instance.new("RemoteEvent")
launchEvent.Name = "LaunchGalacticWorldSelection"
launchEvent.Parent = gameEvents

local folder = workspace:FindFirstChild("GalacticWorldSelection")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "GalacticWorldSelection"
folder.Parent = workspace

local G = 84
local BUTTON_POS = Vector3.new(-48, G + 0.5, -728)
local BUTTON_COLOR = "Bright violet"

local WORLD_SPAWNS = {
	[20] = { name = "Neon Rift",       cf = CFrame.new(-2860, 8, 1700), bounds = { minX = -3210, maxX = -2510, minZ = 1420, maxZ = 1980 } },
	[21] = { name = "Sky Vault",       cf = CFrame.new(-3500, 8, 1700), bounds = { minX = -3534, maxX = -3466, minZ = 1666, maxZ = 1734 } },
	[22] = { name = "Storm Tower",     cf = CFrame.new(-3660, 8, 1700), bounds = { minX = -3762, maxX = -3558, minZ = 1604, maxZ = 1796 } },
	[23] = { name = "Frost Basin",     cf = CFrame.new(-2860, 8, 2162), bounds = { minX = -2924, maxX = -2796, minZ = 2136, maxZ = 2264 } },
	[24] = { name = "Ember Hold",      cf = CFrame.new(-2860, 8, 2550), bounds = { minX = -2924, maxX = -2796, minZ = 2486, maxZ = 2614 } },
	[25] = { name = "Nova Spire",      cf = CFrame.new(-2860, 8, 2900), bounds = { minX = -2924, maxX = -2796, minZ = 2836, maxZ = 2964 } },
	[26] = { name = "Prism Peak",      cf = CFrame.new(-2860, 8, 3200), bounds = { minX = -2919, maxX = -2801, minZ = 3141, maxZ = 3259 } },
	[27] = { name = "Magma Core",      cf = CFrame.new(-2860, 8, 3500), bounds = { minX = -2929, maxX = -2791, minZ = 3431, maxZ = 3569 } },
	[28] = { name = "Storm Circuit",   cf = CFrame.new(-2860, 8, 3830), bounds = { minX = -2934, maxX = -2786, minZ = 3771, maxZ = 3889 } },
	[29] = { name = "Shadow Vault",    cf = CFrame.new(-2860, 8, 4130), bounds = { minX = -2924, maxX = -2796, minZ = 4066, maxZ = 4194 } },
	[30] = { name = "Apex Nexus",      cf = CFrame.new(-2860, 8, 4450), bounds = { minX = -2944, maxX = -2776, minZ = 4366, maxZ = 4534 } },
	[31] = { name = "Cloud Drift",     cf = CFrame.new(-2860, 8, 4760), bounds = { minX = -2929, maxX = -2791, minZ = 4691, maxZ = 4829 } },
	[32] = { name = "Coral Reef",      cf = CFrame.new(-2860, 8, 5060), bounds = { minX = -2924, maxX = -2796, minZ = 4996, maxZ = 5124 } },
	[33] = { name = "Bubble Bounce",   cf = CFrame.new(-2860, 8, 5340), bounds = { minX = -2929, maxX = -2791, minZ = 5271, maxZ = 5409 } },
	[34] = { name = "Zen Garden",      cf = CFrame.new(-2860, 8, 5620), bounds = { minX = -2924, maxX = -2796, minZ = 5556, maxZ = 5684 } },
	[35] = { name = "Crystal Spires",  cf = CFrame.new(-2860, 8, 5900), bounds = { minX = -2929, maxX = -2791, minZ = 5831, maxZ = 5969 } },
	[36] = { name = "Neon Triangle",   cf = CFrame.new(-2860, 8, 6185), bounds = { minX = -2929, maxX = -2791, minZ = 6116, maxZ = 6254 } },
	[37] = { name = "Wide Canyon",     cf = CFrame.new(-2860, 8, 6470), bounds = { minX = -2929, maxX = -2791, minZ = 6401, maxZ = 6539 } },
	[38] = { name = "Narrow Pass",     cf = CFrame.new(-2860, 8, 6755), bounds = { minX = -2929, maxX = -2791, minZ = 6686, maxZ = 6824 } },
	[39] = { name = "Diamond Gate",    cf = CFrame.new(-2860, 8, 7040), bounds = { minX = -2929, maxX = -2791, minZ = 6971, maxZ = 7109 } },
	[40] = { name = "Hourglass Vault", cf = CFrame.new(-2860, 8, 7325), bounds = { minX = -2929, maxX = -2791, minZ = 7256, maxZ = 7394 } },
}

local function part(name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.BrickColor = BrickColor.new(color)
	p.Material = material or Enum.Material.SmoothPlastic
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function addTextSign(name, text, pos, color)
	local sign = part(name, Vector3.new(24, 7, 0.55), pos, "Really black", Enum.Material.Metal)
	sign.CanCollide = false
	local glow = part(name .. "Glow", Vector3.new(25.8, 8.6, 0.18), pos + Vector3.new(0, 0, 0.35), color, Enum.Material.Neon)
	glow.Transparency = 0.66
	glow.CanCollide = false
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 34
		gui.LightInfluence = 0
		gui.AlwaysOnTop = true
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(5, 7, 14)
		label.Text = text
		label.TextColor3 = BrickColor.new(color).Color
		label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.08
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.Parent = gui
	end
end

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local IS_DEBUG = Balance.ActiveMode == "debug" or Balance.ActiveMode == "fallback-debug"

if IS_DEBUG then
	local pad = part("GalacticWorldsPad", Vector3.new(16, 0.8, 14), BUTTON_POS, BUTTON_COLOR, Enum.Material.Neon)
	pad.Transparency = 0.08
	local button = part("GalacticWorldsButton", Vector3.new(10, 2.2, 8), BUTTON_POS + Vector3.new(0, 1.5, 0), BUTTON_COLOR, Enum.Material.Neon)
	part("GalacticWorldsBeacon", Vector3.new(3, 62, 3), BUTTON_POS + Vector3.new(0, 32, 0), BUTTON_COLOR, Enum.Material.Neon).Transparency = 0.25
	addTextSign("GalacticWorldsStaticSign", "GALACTIC\nWORLDS", BUTTON_POS + Vector3.new(0, 8, -7), BUTTON_COLOR)

	local debounce = {}
	local function openForPlayer(player)
		local now = os.clock()
		if debounce[player] and now - debounce[player] < 0.8 then return end
		debounce[player] = now
		openEvent:FireClient(player, WORLD_SPAWNS)
	end

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 24
	click.Parent = button
	click.MouseClick:Connect(openForPlayer)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Galactic Worlds"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.Parent = button
	prompt.Triggered:Connect(openForPlayer)
end

launchEvent.OnServerEvent:Connect(function(player, order)
	order = tonumber(order)
	local destination = order and WORLD_SPAWNS[order]
	if not destination then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	player:SetAttribute("InLandingWorld", false)
	player:SetAttribute("LandingWorldCompleted", true)
	player:SetAttribute("CheckpointOrder", math.max(player:GetAttribute("CheckpointOrder") or 1, order))
	player:SetAttribute("CheckpointName", destination.name)
	local safeCF = SafeLevelSpawn.getCFrame(order, destination.name, destination.cf, destination.bounds)
	skyDescent(hrp, safeCF, destination.bounds, 1.4)
end)

print("[GalacticWorldSelection] Built starter button and selector endpoint.")
