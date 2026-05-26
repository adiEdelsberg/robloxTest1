-- MovementLabGameplay.server.luau  (World 41 — Movement Lab)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

local WORLD_NAME = "Movement Lab"
local CX, CZ     = -2860, 7610
local FLOOR_Y    = 1

-- ── Bootstrap ─────────────────────────────────────────────────────────────────
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)

local function getOrCreate(parent, class, name)
	if not parent then return nil end
	local v = parent:FindFirstChild(name)
	if not v then
		v = Instance.new(class)
		v.Name   = name
		v.Value  = 0
		v.Parent = parent
	end
	return v
end

local remValue = getOrCreate(gameEvents, "NumberValue", "MovementLabRemaining")
local totValue = getOrCreate(gameEvents, "NumberValue", "MovementLabTotal")

local animEvent = gameEvents and gameEvents:FindFirstChild("MovementLabAnim")
if not animEvent or not animEvent:IsA("RemoteEvent") then
	if animEvent then animEvent:Destroy() end
	animEvent = Instance.new("RemoteEvent")
	animEvent.Name   = "MovementLabAnim"
	animEvent.Parent = gameEvents
end

local Balance    = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))
local TARGET = (Balance.StageTargets and Balance.StageTargets.MovementLab) or 1

-- ── Part helpers ──────────────────────────────────────────────────────────────
local worldFolder = nil

local function mkp(name, size, pos, color, mat, trans, noCollide)
	local part = Instance.new("Part")
	part.Name          = name
	part.Size          = size
	part.Position      = pos
	part.BrickColor    = BrickColor.new(color)
	part.Material      = mat or Enum.Material.SmoothPlastic
	part.Anchored      = true
	part.CanCollide    = not noCollide
	part.CanTouch      = true
	part.CastShadow    = false
	part.Transparency  = trans or 0
	part.TopSurface    = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent        = worldFolder
	return part
end

local function neon(name, size, pos, color, trans)
	return mkp(name, size, pos, color, Enum.Material.Neon, trans or 0.1, true)
end

-- ── Pad label (top face) ──────────────────────────────────────────────────────
-- Returns the countdown TextLabel so we can update it later
local function padLabel(pad, num, label)
	local gui = Instance.new("SurfaceGui")
	gui.Face           = Enum.NormalId.Top
	gui.SizingMode     = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud  = 30
	gui.LightInfluence = 0
	gui.Parent         = pad

	-- White background panel for contrast
	local panel = Instance.new("Frame")
	panel.Size                   = UDim2.new(1, -12, 1, -12)
	panel.Position               = UDim2.new(0, 6, 0, 6)
	panel.BackgroundColor3       = Color3.new(1, 1, 1)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel        = 0
	panel.Parent                 = gui
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

	-- Number (top-left corner)
	local numLbl = Instance.new("TextLabel")
	numLbl.Size                   = UDim2.new(0, 48, 0, 48)
	numLbl.Position               = UDim2.new(0, 6, 0, 4)
	numLbl.BackgroundTransparency = 1
	numLbl.Text                   = tostring(num)
	numLbl.TextColor3             = Color3.fromRGB(80, 80, 80)
	numLbl.Font                   = Enum.Font.GothamBlack
	numLbl.TextSize               = 36
	numLbl.TextXAlignment         = Enum.TextXAlignment.Left
	numLbl.Parent                 = panel

	-- Name (centered, large)
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                   = UDim2.new(1, -12, 1, -12)
	nameLbl.Position               = UDim2.new(0, 6, 0, 6)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text                   = label
	nameLbl.TextColor3             = Color3.new(0, 0, 0)
	nameLbl.Font                   = Enum.Font.GothamBlack
	nameLbl.TextScaled             = true
	nameLbl.TextXAlignment         = Enum.TextXAlignment.Center
	nameLbl.TextYAlignment         = Enum.TextYAlignment.Center
	nameLbl.Parent                 = panel

	-- Countdown overlay (hidden by default, appears when pads are disabled)
	local countdownLbl = Instance.new("TextLabel")
	countdownLbl.Size                   = UDim2.new(1, 0, 1, 0)
	countdownLbl.Position               = UDim2.new(0, 0, 0, 0)
	countdownLbl.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
	countdownLbl.BackgroundTransparency = 0.25
	countdownLbl.Text                   = ""
	countdownLbl.TextColor3             = Color3.fromRGB(255, 80, 80)
	countdownLbl.Font                   = Enum.Font.GothamBlack
	countdownLbl.TextScaled             = true
	countdownLbl.TextXAlignment         = Enum.TextXAlignment.Center
	countdownLbl.TextYAlignment         = Enum.TextYAlignment.Center
	countdownLbl.ZIndex                 = 3
	countdownLbl.Visible                = false
	countdownLbl.Parent                 = panel
	Instance.new("UICorner", countdownLbl).CornerRadius = UDim.new(0, 8)

	return countdownLbl
end

-- ── Launch helper ─────────────────────────────────────────────────────────────
local function launchUp(player, power)
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = Vector3.new(0, power or 80, 0)
	bv.MaxForce = Vector3.new(0, math.huge, 0)
	bv.P        = math.huge
	bv.Parent   = hrp
	Debris:AddItem(bv, 0.2)
end

-- ── Movement execution ────────────────────────────────────────────────────────
local function doMovement(player, action)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	if action == "jump" then
		launchUp(player, 100)

	elseif action == "speed" then
		local prev = hum.WalkSpeed
		hum.WalkSpeed = 60
		task.delay(5, function()
			if hum and hum.Parent then hum.WalkSpeed = prev end
		end)

	elseif animEvent then
		animEvent:FireClient(player, action)
	end
end

-- ── Global pad cooldown ───────────────────────────────────────────────────────
local allPads   = {}   -- { part = Part, countdownLbl = TextLabel }
local globalLocked = false
local lockGeneration = 0

local COOLDOWN = 3

local function setAllPadsDisabled(disabled, secondsLeft)
	for _, entry in ipairs(allPads) do
		if entry.part.Parent then
			entry.part.Transparency    = disabled and 0.5 or 0
			entry.part.BrickColor      = BrickColor.new(disabled and "Medium stone grey" or "White")
			entry.countdownLbl.Visible = disabled
			entry.countdownLbl.Text    = disabled and tostring(secondsLeft) or ""
		end
	end
end

local function startCooldown()
	lockGeneration += 1
	local myGen = lockGeneration
	globalLocked = true
	for s = COOLDOWN, 1, -1 do
		if lockGeneration ~= myGen then return end
		setAllPadsDisabled(true, s)
		task.wait(1)
	end
	if lockGeneration == myGen then
		globalLocked = false
		setAllPadsDisabled(false, 0)
	end
end

-- ── World build ───────────────────────────────────────────────────────────────
local function buildWorld()
	if worldFolder then worldFolder:Destroy() end
	allPads        = {}
	globalLocked   = false
	lockGeneration = 0

	worldFolder = Instance.new("Folder")
	worldFolder.Name   = "MovementLabWorld"
	worldFolder.Parent = workspace

	-- Floor
	mkp("Floor", Vector3.new(140, 4, 140), Vector3.new(CX, FLOOR_Y - 1, CZ), "Dark stone grey")

	-- Grid lines on floor
	for i = -3, 3 do
		neon("GridX", Vector3.new(136, 0.2, 0.5), Vector3.new(CX, FLOOR_Y + 1.1, CZ + i * 20), "Electric blue", 0.3)
		neon("GridZ", Vector3.new(0.5, 0.2, 136), Vector3.new(CX + i * 20, FLOOR_Y + 1.1, CZ), "Electric blue", 0.3)
	end

	-- Walls
	mkp("WallN", Vector3.new(140, 80, 2), Vector3.new(CX, FLOOR_Y + 41, CZ - 70), "Electric blue", Enum.Material.Glass, 0.55)
	mkp("WallS", Vector3.new(140, 80, 2), Vector3.new(CX, FLOOR_Y + 41, CZ + 70), "Electric blue", Enum.Material.Glass, 0.55)
	mkp("WallE", Vector3.new(2, 80, 140), Vector3.new(CX + 70, FLOOR_Y + 41, CZ), "Electric blue", Enum.Material.Glass, 0.55)
	mkp("WallW", Vector3.new(2, 80, 140), Vector3.new(CX - 70, FLOOR_Y + 41, CZ), "Electric blue", Enum.Material.Glass, 0.55)

	-- ── Movement pads ─────────────────────────────────────────────────────────
	local TILE_W   = 16
	local TILE_PAD = 4
	local COLS     = 4
	local TILE_H   = 0.6

	local PADS = {
		{ label = "SUPER JUMP", action = "jump"   },
		{ label = "WAVE",       action = "wave"   },
		{ label = "DANCE",      action = "dance"  },
		{ label = "DANCE 2",    action = "dance2" },
		{ label = "DANCE 3",    action = "dance3" },
		{ label = "SPEED",      action = "speed"  },
		{ label = "POINT",      action = "point"  },
		{ label = "SPIN",       action = "spin"   },
		{ label = "SALUTE",     action = "salute" },
		{ label = "SHRUG",      action = "shrug"  },
		{ label = "CHEER",      action = "cheer"  },
		{ label = "LAUGH",      action = "laugh"  },
		{ label = "MARCH",      action = "march"  },
		{ label = "SPIN X",     action = "spinx"  },
		{ label = "SPIN Y",     action = "spiny"  },
	}

	local gridW  = COLS * TILE_W + (COLS - 1) * TILE_PAD
	local startX = CX - gridW / 2 + TILE_W / 2
	local numRows = math.ceil(#PADS / COLS)
	local gridD  = numRows * TILE_W + (numRows - 1) * TILE_PAD
	local startZ = CZ - gridD / 2 + TILE_W / 2

	for i, info in ipairs(PADS) do
		local col  = (i - 1) % COLS
		local row  = math.floor((i - 1) / COLS)
		local px   = startX + col * (TILE_W + TILE_PAD)
		local pz   = startZ + row * (TILE_W + TILE_PAD)
		local tileY = FLOOR_Y + 1 + TILE_H / 2

		local tile = mkp("MovePad", Vector3.new(TILE_W, TILE_H, TILE_W),
			Vector3.new(px, tileY, pz), "White", Enum.Material.SmoothPlastic, 0)

		local countdownLbl = padLabel(tile, i, info.label)
		table.insert(allPads, { part = tile, countdownLbl = countdownLbl })

		local action = info.action
		tile.Touched:Connect(function(hit)
			if globalLocked then return end
			local char   = hit.Parent
			local player = Players:GetPlayerFromCharacter(char)
			if not player then return end
			task.spawn(startCooldown)
			doMovement(player, action)
		end)
	end

	if remValue then remValue.Value = TARGET end
	if totValue then totValue.Value = TARGET end
	print("[MovementLabGameplay] Built with", #PADS, "movement pads.")
end

buildWorld()
print("[MovementLabGameplay] Ready.")
