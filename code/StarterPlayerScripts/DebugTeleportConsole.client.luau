-- DebugTeleportConsole.client.luau
-- Wires up the in-world numpad teleport console.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance           = require(ReplicatedStorage:WaitForChild("GameBalanceConfig"))

local IS_DEBUG = Balance.ActiveMode == "debug" or Balance.ActiveMode == "test" or Balance.ActiveMode == "fallback-debug"
if not IS_DEBUG then return end

local player     = Players.LocalPlayer
local WorldOrder = require(ReplicatedStorage:WaitForChild("WorldOrderConfig"))
local MAX_LEVEL  = #WorldOrder.Worlds
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 30)
local remote = gameEvents and gameEvents:WaitForChild("DebugTeleport", 15)

local SPAWN_POSITIONS = {
	[1]  = CFrame.new(  0,  7,    0),
	[2]  = CFrame.new(  0,  7,  142),
	[3]  = CFrame.new(  0,  8,  398),
	[4]  = CFrame.new(  0,  8,  652),
	[5]  = CFrame.new(  0,  8,  872),
	[6]  = CFrame.new(  0,  8, 1102),
	[7]  = CFrame.new(  0,  8, 1312),
	[8]  = CFrame.new(  0,  8, 1558),
	[9]  = CFrame.new(224,  8, 1700),
	[10] = CFrame.new(590,  8, 1700),
	[11] = CFrame.new(918,  8, 1700),
	[12] = CFrame.new(1270, 8, 1700),
	[13] = CFrame.new(1622, 8, 1700),
	[14] = CFrame.new(1974, 8, 1700),
	[15] = CFrame.new(2326, 8, 1700),
	[16] = CFrame.new(2678, 8, 1700),
	[17] = CFrame.new(-550,  8, 1700),
	[18] = CFrame.new(-1320, 8, 1700),
	[19] = CFrame.new(-2090, 8, 1700),
	[20] = CFrame.new(-2860, 8, 1700),
	[21] = CFrame.new(-3500, 8, 1700),
	[22] = CFrame.new(-3660, 8, 1700),
	[23] = CFrame.new(-2860, 8, 2162),
	[24] = CFrame.new(-2860, 8, 2550),
	[25] = CFrame.new(-2860, 8, 2900),
	[26] = CFrame.new(-2860, 8, 3200),
	[27] = CFrame.new(-2860, 8, 3500),
	[28] = CFrame.new(-2860, 8, 3830),
	[29] = CFrame.new(-2860, 8, 4130),
	[30] = CFrame.new(-2860, 8, 4450),
	[31] = CFrame.new(-2860, 8, 4760),
	[32] = CFrame.new(-2860, 8, 5060),
	[33] = CFrame.new(-2860, 8, 5340),
	[34] = CFrame.new(-2860, 8, 5620),
	[35] = CFrame.new(-2860, 8, 5900),
	[36] = CFrame.new(-2860, 8, 6185),
	[37] = CFrame.new(-2860, 8, 6470),
	[38] = CFrame.new(-2860, 8, 6755),
	[39] = CFrame.new(-2860, 8, 7040),
	[40] = CFrame.new(-2860, 8, 7325),
	[41] = CFrame.new(-2860, 8, 7610),
	[42] = CFrame.new(-2860, 8, 8100),
	[43] = CFrame.new(-2860, 8, 8410),
	[44] = CFrame.new(-2860, 8, 8700),
	[45] = CFrame.new(-2860, 8, 9150),
	[46] = CFrame.new(-2860, 8, 9800),
	[47] = CFrame.new(-2860, 8, 11250),
}

-- Wait for parts to replicate
local folder = workspace:WaitForChild("DebugTeleportConsole", 15)
if not folder then return end
local body = folder:WaitForChild("ConsoleFace", 10)
if not body then return end
local gui = body:WaitForChild("TeleportConsoleGui", 10)
if not gui then return end
local bg = gui:WaitForChild("BG", 10)
if not bg then return end

-- ── Layout constants ──────────────────────────────────────────────────────────
-- PW=14 studs * 30 px/stud = 420px wide, PH=22*30 = 660px tall
local W = 420
local PAD = 10
local BTN_GAP = 6
local BTN_W = math.floor((W - PAD*2 - BTN_GAP*2) / 3)  -- 3 columns
local BTN_H = 60

-- ── Title ─────────────────────────────────────────────────────────────────────
local titleLbl = Instance.new("TextLabel")
titleLbl.Size                   = UDim2.new(1, 0, 0, 44)
titleLbl.Position               = UDim2.new(0, 0, 0, 4)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                   = "🛠  TELEPORT"
titleLbl.TextColor3             = Color3.fromRGB(255, 80, 80)
titleLbl.Font                   = Enum.Font.GothamBlack
titleLbl.TextSize               = 22
titleLbl.Parent                 = bg

-- ── Level display ─────────────────────────────────────────────────────────────
local display = Instance.new("Frame")
display.Size             = UDim2.new(1, -PAD*2, 0, 80)
display.Position         = UDim2.new(0, PAD, 0, 50)
display.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
display.BorderSizePixel  = 0
display.Parent           = bg
Instance.new("UICorner", display).CornerRadius = UDim.new(0, 8)

local numLbl = Instance.new("TextLabel")
numLbl.Size                   = UDim2.new(0.55, 0, 1, 0)
numLbl.Position               = UDim2.new(0, 10, 0, 0)
numLbl.BackgroundTransparency = 1
numLbl.Text                   = "_"
numLbl.TextColor3             = Color3.fromRGB(255, 235, 70)
numLbl.Font                   = Enum.Font.GothamBlack
numLbl.TextSize               = 48
numLbl.TextXAlignment         = Enum.TextXAlignment.Left
numLbl.TextYAlignment         = Enum.TextYAlignment.Center
numLbl.Parent                 = display

local nameLbl = Instance.new("TextLabel")
nameLbl.Size                   = UDim2.new(0.42, 0, 1, 0)
nameLbl.Position               = UDim2.new(0.57, 0, 0, 0)
nameLbl.BackgroundTransparency = 1
nameLbl.Text                   = ""
nameLbl.TextColor3             = Color3.fromRGB(140, 190, 255)
nameLbl.Font                   = Enum.Font.GothamBold
nameLbl.TextSize               = 13
nameLbl.TextWrapped            = true
nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
nameLbl.TextYAlignment         = Enum.TextYAlignment.Center
nameLbl.Parent                 = display

-- ── Numpad ────────────────────────────────────────────────────────────────────
-- Rows: [1 2 3] [4 5 6] [7 8 9] [← 0 GO]
local NUMPAD_TOP = 140

local function makeKey(label, col, row, bgColor, textColor)
	local x = PAD + (col - 1) * (BTN_W + BTN_GAP)
	local y = NUMPAD_TOP + (row - 1) * (BTN_H + BTN_GAP)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0, BTN_W, 0, BTN_H)
	btn.Position         = UDim2.new(0, x, 0, y)
	btn.BackgroundColor3 = bgColor or Color3.fromRGB(30, 35, 70)
	btn.BorderSizePixel  = 0
	btn.Text             = label
	btn.TextColor3       = textColor or Color3.fromRGB(255, 255, 255)
	btn.Font             = Enum.Font.GothamBlack
	btn.TextSize         = 26
	btn.Parent           = bg
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local keys = {
	makeKey("1", 1, 1), makeKey("2", 2, 1), makeKey("3", 3, 1),
	makeKey("4", 1, 2), makeKey("5", 2, 2), makeKey("6", 3, 2),
	makeKey("7", 1, 3), makeKey("8", 2, 3), makeKey("9", 3, 3),
}
local keyDel = makeKey("⌫", 1, 4, Color3.fromRGB(60, 20, 20), Color3.fromRGB(255, 120, 120))
local key0   = makeKey("0", 2, 4)
local keyGo  = makeKey("GO", 3, 4, Color3.fromRGB(160, 30, 30), Color3.fromRGB(255, 255, 255))

-- ── State ─────────────────────────────────────────────────────────────────────
local input = ""

local STARTER_CF = CFrame.new(0, 7, 0)

local function updateDisplay()
	if input == "" then
		numLbl.Text       = "_"
		nameLbl.Text      = ""
		numLbl.TextColor3 = Color3.fromRGB(80, 80, 100)
	else
		local n = tonumber(input)
		numLbl.Text       = input
		numLbl.TextColor3 = Color3.fromRGB(255, 235, 70)
		if n and SPAWN_POSITIONS[n] then
			nameLbl.Text       = WorldOrder.getName(n) or ""
			nameLbl.TextColor3 = Color3.fromRGB(140, 190, 255)
		else
			nameLbl.Text       = "→ Starter"
			nameLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
	end
end

local function pressDigit(d)
	if #input >= 3 then return end  -- max 3 digits
	input = input .. d
	updateDisplay()
end

local function pressDelete()
	if #input > 0 then
		input = input:sub(1, -2)
		updateDisplay()
	end
end

local function pressGo()
	local n  = tonumber(input)
	if remote then
		remote:FireServer(n)
	else
		local cf = (n and SPAWN_POSITIONS[n]) or STARTER_CF
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = cf + Vector3.new(0, 3, 0)
		end
	end
	input = ""
	updateDisplay()
end

-- Wire digit keys
local digits = {"1","2","3","4","5","6","7","8","9"}
for i, btn in ipairs(keys) do
	local d = digits[i]
	btn.MouseButton1Click:Connect(function() pressDigit(d) end)
end
key0.MouseButton1Click:Connect(function()  pressDigit("0") end)
keyDel.MouseButton1Click:Connect(pressDelete)
keyGo.MouseButton1Click:Connect(pressGo)

updateDisplay()
