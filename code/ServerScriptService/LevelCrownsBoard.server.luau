-- LevelCrownsBoard.server.luau
-- Physical board placed beside the leaderboard showing per-level crown counts.
-- Each row: level number, level name, crown count for the player who has the most,
-- plus total crowns earned for that level across the whole server session.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldOrder        = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))

-- ── Position (to the right of StarterLeaderboard) ─────────────────────────────
local BOARD_CX = 138     -- StarterLeaderboard is at CX=78, width=52 → place at 78+52+8
local BOARD_Y  = 84 + 5 + 1
local BOARD_CZ = -695

local BOARD_W  = 64
local BOARD_H  = 36
local BOARD_T  = 0.5

local MAX_ROWS = 8   -- levels shown at once; board cycles through pages

-- ── Physical structure ─────────────────────────────────────────────────────────
local folder = Instance.new("Folder")
folder.Name   = "LevelCrownsBoard"
folder.Parent = workspace

local function makePart(name, size, pos, color, mat, trans)
	local p = Instance.new("Part")
	p.Name         = name
	p.Size         = size
	p.Position     = pos
	p.BrickColor   = BrickColor.new(color)
	p.Material     = mat or Enum.Material.SmoothPlastic
	p.Anchored     = true
	p.CanCollide   = true
	p.CastShadow   = false
	p.Transparency = trans or 0
	p.TopSurface   = Enum.SurfaceType.Smooth
	p.BottomSurface= Enum.SurfaceType.Smooth
	p.Parent       = folder
	return p
end

local backing = makePart("BoardBacking",
	Vector3.new(BOARD_W + 2.2, BOARD_H + 2.2, BOARD_T),
	Vector3.new(BOARD_CX, BOARD_Y + BOARD_H / 2 + 1, BOARD_CZ),
	"Really black", Enum.Material.Metal)

local borderColor = "Cyan"
local bT = 0.35
makePart("BorderTop",   Vector3.new(BOARD_W + 2.4, bT, bT), Vector3.new(BOARD_CX, BOARD_Y + BOARD_H + 1.3,           BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1
makePart("BorderBot",   Vector3.new(BOARD_W + 2.4, bT, bT), Vector3.new(BOARD_CX, BOARD_Y + 1.3,                     BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1
makePart("BorderLeft",  Vector3.new(bT, BOARD_H + 2.4, bT), Vector3.new(BOARD_CX - BOARD_W/2 - 1.1, BOARD_Y + BOARD_H/2 + 1, BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1
makePart("BorderRight", Vector3.new(bT, BOARD_H + 2.4, bT), Vector3.new(BOARD_CX + BOARD_W/2 + 1.1, BOARD_Y + BOARD_H/2 + 1, BOARD_CZ - 0.2), borderColor, Enum.Material.Neon).Transparency = 0.1

makePart("PostLeft",  Vector3.new(0.9, BOARD_H/2 + 2, 0.9), Vector3.new(BOARD_CX - BOARD_W/2 - 1, BOARD_Y - BOARD_H/4 + 1, BOARD_CZ), "Dark stone grey", Enum.Material.Metal)
makePart("PostRight", Vector3.new(0.9, BOARD_H/2 + 2, 0.9), Vector3.new(BOARD_CX + BOARD_W/2 + 1, BOARD_Y - BOARD_H/4 + 1, BOARD_CZ), "Dark stone grey", Enum.Material.Metal)

-- ── SurfaceGui ─────────────────────────────────────────────────────────────────
local gui = Instance.new("SurfaceGui")
gui.Name          = "LevelCrownsGui"
gui.Face          = Enum.NormalId.Front
gui.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
gui.PixelsPerStud = 28
gui.LightInfluence= 0
gui.Parent        = backing

local bg = Instance.new("Frame")
bg.Size                   = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3       = Color3.fromRGB(4, 10, 22)
bg.BackgroundTransparency = 0.04
bg.BorderSizePixel        = 0
bg.Parent                 = gui

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundColor3 = Color3.fromRGB(8, 25, 50)
titleBar.BackgroundTransparency = 0.05
titleBar.BorderSizePixel  = 0
titleBar.Parent           = bg

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                   = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                   = "👑  LEVEL CROWNS  👑"
titleLabel.TextColor3             = Color3.fromRGB(100, 230, 255)
titleLabel.TextStrokeTransparency = 0.4
titleLabel.Font                   = Enum.Font.GothamBlack
titleLabel.TextSize               = 24
titleLabel.Parent                 = titleBar

-- Column headers
local PW = BOARD_W * 28
local headerRow = Instance.new("Frame")
headerRow.Size             = UDim2.new(1, -16, 0, 30)
headerRow.Position         = UDim2.new(0, 8, 0, 54)
headerRow.BackgroundColor3 = Color3.fromRGB(10, 40, 70)
headerRow.BackgroundTransparency = 0.1
headerRow.BorderSizePixel  = 0
headerRow.Parent           = bg
Instance.new("UICorner", headerRow).CornerRadius = UDim.new(0, 4)

local function makeHeaderLbl(text, x, w, align)
	local l = Instance.new("TextLabel")
	l.Size                   = UDim2.new(0, w, 1, 0)
	l.Position               = UDim2.new(0, x, 0, 0)
	l.BackgroundTransparency = 1
	l.Text                   = text
	l.TextColor3             = Color3.fromRGB(120, 200, 255)
	l.Font                   = Enum.Font.GothamBold
	l.TextSize               = 14
	l.TextXAlignment         = align or Enum.TextXAlignment.Left
	l.Parent                 = headerRow
end

makeHeaderLbl("#",      4,   36,  Enum.TextXAlignment.Center)
makeHeaderLbl("LEVEL",  44,  PW - 44 - 90)
makeHeaderLbl("TOP PLAYER", PW - 220, 130)
makeHeaderLbl("👑",     PW - 90,  82, Enum.TextXAlignment.Center)

-- Row pool
local ROW_H     = 32
local ROW_START = 88

local rowFrames = {}
for i = 1, MAX_ROWS do
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, -16, 0, ROW_H - 3)
	row.Position         = UDim2.new(0, 8, 0, ROW_START + (i - 1) * ROW_H)
	row.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(10, 18, 36) or Color3.fromRGB(6, 12, 26)
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel  = 0
	row.Visible          = false
	row.Parent           = bg
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

	local function cell(text, x, w, color, align)
		local l = Instance.new("TextLabel")
		l.Size                   = UDim2.new(0, w, 1, 0)
		l.Position               = UDim2.new(0, x, 0, 0)
		l.BackgroundTransparency = 1
		l.Text                   = text
		l.TextColor3             = color or Color3.new(1,1,1)
		l.Font                   = Enum.Font.GothamBold
		l.TextSize               = 15
		l.TextXAlignment         = align or Enum.TextXAlignment.Left
		l.TextYAlignment         = Enum.TextYAlignment.Center
		l.Parent                 = row
		return l
	end

	rowFrames[i] = {
		frame  = row,
		num    = cell("", 4,  36,  Color3.fromRGB(120, 200, 255), Enum.TextXAlignment.Center),
		name   = cell("", 44, PW - 44 - 90, Color3.new(1,1,1)),
		top    = cell("", PW - 220, 130, Color3.fromRGB(200, 200, 200)),
		crowns = cell("", PW - 90,  82,  Color3.fromRGB(255, 220, 60), Enum.TextXAlignment.Center),
	}
end

local pageLabel = Instance.new("TextLabel")
pageLabel.Size                   = UDim2.new(1, 0, 0, 20)
pageLabel.Position               = UDim2.new(0, 0, 1, -22)
pageLabel.BackgroundTransparency = 1
pageLabel.Text                   = ""
pageLabel.TextColor3             = Color3.fromRGB(80, 120, 160)
pageLabel.Font                   = Enum.Font.Gotham
pageLabel.TextSize               = 13
pageLabel.Parent                 = bg

-- ── Data helpers ───────────────────────────────────────────────────────────────
local function getLevelCrown(player, order)
	return player:GetAttribute("LevelCrown_" .. tostring(order)) or 0
end

local currentPage = 1

local function refresh()
	-- Build a list of all levels that have at least 1 crown on any player
	local allLevels = WorldOrder.Worlds  -- ordered table from config

	-- For each level collect: total crowns, top player name + count
	local entries = {}
	for _, worldDef in ipairs(allLevels) do
		local order = worldDef.order
		local topName, topCount, total = "-", 0, 0
		for _, player in Players:GetPlayers() do
			local c = getLevelCrown(player, order)
			total += c
			if c > topCount then
				topCount = c
				topName = player.DisplayName or player.Name
			end
		end
		if total > 0 then
			table.insert(entries, {
				order   = order,
				name    = worldDef.name,
				top     = topName,
				topCount= topCount,
				total   = total,
			})
		end
	end

	-- Sort by total crowns descending
	table.sort(entries, function(a, b) return a.total > b.total end)

	-- Paginate
	local totalPages = math.max(1, math.ceil(#entries / MAX_ROWS))
	if currentPage > totalPages then currentPage = 1 end
	local startIdx = (currentPage - 1) * MAX_ROWS + 1

	for i, r in rowFrames do
		local entry = entries[startIdx + i - 1]
		if entry then
			r.num.Text    = tostring(entry.order)
			r.name.Text   = entry.name
			r.top.Text    = entry.top
			r.crowns.Text = tostring(entry.total)
			r.frame.Visible = true
		else
			r.frame.Visible = false
		end
	end

	if totalPages > 1 then
		pageLabel.Text = string.format("page %d / %d", currentPage, totalPages)
	else
		pageLabel.Text = ""
	end
end

-- Cycle pages every 6 seconds, refresh data every 5 seconds
task.spawn(function()
	while true do
		task.wait(5)
		refresh()
		task.wait(1)
		local allLevels = WorldOrder.Worlds
		local totalWithCrowns = 0
		for _, worldDef in ipairs(allLevels) do
			for _, player in Players:GetPlayers() do
				if getLevelCrown(player, worldDef.order) > 0 then
					totalWithCrowns += 1
					break
				end
			end
		end
		local totalPages = math.max(1, math.ceil(totalWithCrowns / MAX_ROWS))
		currentPage = (currentPage % totalPages) + 1
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.AttributeChanged:Connect(function(attr)
		if attr:sub(1, 11) == "LevelCrown_" then
			refresh()
		end
	end)
	task.wait(1)
	refresh()
end)
Players.PlayerRemoving:Connect(function() task.defer(refresh) end)

refresh()
print("[LevelCrownsBoard] Built.")
