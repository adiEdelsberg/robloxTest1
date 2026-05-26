-- StarterLeaderboard.server.luau
-- Builds a large leaderboard board near the starter spin-wheel area.
-- Displays every player's Crown and Trophy counts, sorted by Trophies desc.
-- Refreshes every 3 seconds.

local Players = game:GetService("Players")

-- ── Position (beside the spin wheel stage) ────────────────────────────────────
-- Spin wheel is at WX=78, WZ=-735, stage top at Y ≈ 96 (G=84 + STAGE_LIFT=5 + platform ~7)
local BOARD_CX = 78
local BOARD_Y  = 84 + 5 + 1    -- ground + stage lift + slight raise
local BOARD_CZ = -695           -- in front of the stage, facing players

local BOARD_W  = 52
local BOARD_H  = 36
local BOARD_T  = 0.5

local MAX_ROWS = 8   -- max player rows shown

-- ── Build physical board ──────────────────────────────────────────────────────
local folder = Instance.new("Folder")
folder.Name   = "StarterLeaderboard"
folder.Parent = workspace

local function makePart(name, size, pos, color, mat, trans)
	local p = Instance.new("Part")
	p.Name        = name
	p.Size        = size
	p.Position    = pos
	p.BrickColor  = BrickColor.new(color)
	p.Material    = mat or Enum.Material.SmoothPlastic
	p.Anchored    = true
	p.CanCollide  = true
	p.CastShadow  = false
	p.Transparency = trans or 0
	p.TopSurface  = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent      = folder
	return p
end

-- Frame / backing
local backing = makePart("BoardBacking",
	Vector3.new(BOARD_W + 2.2, BOARD_H + 2.2, BOARD_T),
	Vector3.new(BOARD_CX, BOARD_Y + BOARD_H / 2 + 1, BOARD_CZ),
	"Really black", Enum.Material.Metal)

-- Neon border strips
local borderColor = "Bright yellow"
local bT = 0.35
makePart("BorderTop",    Vector3.new(BOARD_W + 2.4, bT, bT), Vector3.new(BOARD_CX, BOARD_Y + BOARD_H + 1.3, BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1
makePart("BorderBot",    Vector3.new(BOARD_W + 2.4, bT, bT), Vector3.new(BOARD_CX, BOARD_Y + 1.3,           BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1
makePart("BorderLeft",   Vector3.new(bT, BOARD_H + 2.4, bT), Vector3.new(BOARD_CX - BOARD_W / 2 - 1.1, BOARD_Y + BOARD_H / 2 + 1, BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1
makePart("BorderRight",  Vector3.new(bT, BOARD_H + 2.4, bT), Vector3.new(BOARD_CX + BOARD_W / 2 + 1.1, BOARD_Y + BOARD_H / 2 + 1, BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1

-- Support posts
makePart("PostLeft",  Vector3.new(0.9, BOARD_H / 2 + 2, 0.9), Vector3.new(BOARD_CX - BOARD_W / 2 - 1,  BOARD_Y - BOARD_H / 4 + 1, BOARD_CZ), "Dark stone grey", Enum.Material.Metal)
makePart("PostRight", Vector3.new(0.9, BOARD_H / 2 + 2, 0.9), Vector3.new(BOARD_CX + BOARD_W / 2 + 1,  BOARD_Y - BOARD_H / 4 + 1, BOARD_CZ), "Dark stone grey", Enum.Material.Metal)

-- ── SurfaceGui on the backing ─────────────────────────────────────────────────
local gui = Instance.new("SurfaceGui")
gui.Name         = "LeaderboardGui"
gui.Face         = Enum.NormalId.Front
gui.SizingMode   = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 28
gui.LightInfluence = 0
gui.AlwaysOnTop  = false
gui.Parent       = backing

-- Background
local bg = Instance.new("Frame")
bg.Size                  = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3      = Color3.fromRGB(6, 7, 14)
bg.BackgroundTransparency = 0.04
bg.BorderSizePixel        = 0
bg.Parent                 = gui

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 52)
titleBar.Position         = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 40)
titleBar.BackgroundTransparency = 0.05
titleBar.BorderSizePixel  = 0
titleBar.Parent           = bg

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                  = "🏆  LEADERBOARD  🏆"
titleLabel.TextColor3            = Color3.fromRGB(255, 220, 50)
titleLabel.TextStrokeTransparency = 0.4
titleLabel.Font                  = Enum.Font.GothamBlack
titleLabel.TextSize              = 26
titleLabel.Parent                = titleBar

-- Column headers
local headerRow = Instance.new("Frame")
headerRow.Size             = UDim2.new(1, -16, 0, 32)
headerRow.Position         = UDim2.new(0, 8, 0, 54)
headerRow.BackgroundColor3 = Color3.fromRGB(20, 30, 60)
headerRow.BackgroundTransparency = 0.1
headerRow.BorderSizePixel  = 0
headerRow.Parent           = bg
Instance.new("UICorner", headerRow).CornerRadius = UDim.new(0, 4)

local function makeHeaderLabel(text, xPos, width, align)
	local lbl = Instance.new("TextLabel")
	lbl.Size                  = UDim2.new(0, width, 1, 0)
	lbl.Position              = UDim2.new(0, xPos, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                  = text
	lbl.TextColor3            = Color3.fromRGB(160, 180, 255)
	lbl.Font                  = Enum.Font.GothamBold
	lbl.TextSize              = 15
	lbl.TextXAlignment        = align or Enum.TextXAlignment.Left
	lbl.Parent                = headerRow
end

local PW = BOARD_W * 28   -- total pixel width
makeHeaderLabel("#",       6,   40,  Enum.TextXAlignment.Center)
makeHeaderLabel("PLAYER",  52,  PW - 52 - 180, Enum.TextXAlignment.Left)
makeHeaderLabel("👑 CROWNS",  PW - 180, 90, Enum.TextXAlignment.Center)
makeHeaderLabel("🏆 TROPHIES", PW - 90,  82, Enum.TextXAlignment.Center)

-- Row pool
local ROW_H     = 36
local ROW_START = 90   -- pixels from top

local rowFrames = {}
for i = 1, MAX_ROWS do
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, -16, 0, ROW_H - 4)
	row.Position         = UDim2.new(0, 8, 0, ROW_START + (i - 1) * ROW_H)
	row.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(12, 16, 32) or Color3.fromRGB(8, 10, 22)
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel  = 0
	row.Visible          = false
	row.Parent           = bg
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

	local function makeCell(text, xPos, width, color, align)
		local lbl = Instance.new("TextLabel")
		lbl.Size                  = UDim2.new(0, width, 1, 0)
		lbl.Position              = UDim2.new(0, xPos, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text                  = text
		lbl.TextColor3            = color or Color3.new(1, 1, 1)
		lbl.Font                  = Enum.Font.GothamBold
		lbl.TextSize              = 17
		lbl.TextXAlignment        = align or Enum.TextXAlignment.Left
		lbl.TextYAlignment        = Enum.TextYAlignment.Center
		lbl.Parent                = row
		return lbl
	end

	local rankColors = { Color3.fromRGB(255, 215, 0), Color3.fromRGB(192, 192, 192), Color3.fromRGB(205, 127, 50) }
	rowFrames[i] = {
		frame   = row,
		rank    = makeCell("", 4,  40,  rankColors[i] or Color3.fromRGB(180, 180, 180), Enum.TextXAlignment.Center),
		name    = makeCell("", 50, PW - 50 - 180, Color3.new(1, 1, 1)),
		crowns  = makeCell("", PW - 180, 90,  Color3.fromRGB(255, 215, 0),  Enum.TextXAlignment.Center),
		trophies= makeCell("", PW - 90,  82,  Color3.fromRGB(80, 220, 255), Enum.TextXAlignment.Center),
	}
end

-- Empty state label
local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size                  = UDim2.new(1, 0, 0, 60)
emptyLabel.Position              = UDim2.new(0, 0, 0, ROW_START + 10)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text                  = "No players yet!"
emptyLabel.TextColor3            = Color3.fromRGB(100, 100, 130)
emptyLabel.Font                  = Enum.Font.Gotham
emptyLabel.TextSize              = 18
emptyLabel.Visible               = false
emptyLabel.Parent                = bg

-- ── Refresh logic ─────────────────────────────────────────────────────────────
local function getStatValue(player, statName)
	local stats = player:FindFirstChild("leaderstats")
	local val   = stats and stats:FindFirstChild(statName)
	return val and val.Value or 0
end

local function refresh()
	-- Collect all players with their stats
	local entries = {}
	for _, player in Players:GetPlayers() do
		table.insert(entries, {
			name     = player.DisplayName or player.Name,
			crowns   = getStatValue(player, "Crowns"),
			trophies = getStatValue(player, "Trophies"),
		})
	end

	-- Sort by trophies desc, then crowns desc
	table.sort(entries, function(a, b)
		if a.trophies ~= b.trophies then return a.trophies > b.trophies end
		return a.crowns > b.crowns
	end)

	if #entries == 0 then
		emptyLabel.Visible = true
		for _, r in rowFrames do r.frame.Visible = false end
		return
	end

	emptyLabel.Visible = false
	for i, r in rowFrames do
		local entry = entries[i]
		if entry then
			r.rank.Text     = tostring(i)
			r.name.Text     = entry.name
			r.crowns.Text   = tostring(entry.crowns)
			r.trophies.Text = tostring(entry.trophies)
			r.frame.Visible = true

			-- Gold/silver/bronze tint for top 3
			if i == 1 then
				r.frame.BackgroundColor3 = Color3.fromRGB(60, 50, 10)
			elseif i == 2 then
				r.frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			elseif i == 3 then
				r.frame.BackgroundColor3 = Color3.fromRGB(45, 28, 12)
			else
				r.frame.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(12, 16, 32) or Color3.fromRGB(8, 10, 22)
			end
		else
			r.frame.Visible = false
		end
	end
end

-- Refresh when any player's Crowns or Trophies changes
local function watchPlayer(player)
	local function connectStat(statName)
		local stats = player:WaitForChild("leaderstats", 15)
		if not stats then return end
		local val = stats:WaitForChild(statName, 15)
		if val then val.Changed:Connect(refresh) end
	end
	task.spawn(connectStat, "Crowns")
	task.spawn(connectStat, "Trophies")
end

Players.PlayerAdded:Connect(function(player)
	refresh()
	watchPlayer(player)
end)
Players.PlayerRemoving:Connect(function()
	task.defer(refresh)
end)

for _, player in Players:GetPlayers() do
	watchPlayer(player)
end

-- Periodic fallback refresh every 5 seconds
task.spawn(function()
	while true do
		task.wait(5)
		refresh()
	end
end)

refresh()
print("[StarterLeaderboard] Built.")
