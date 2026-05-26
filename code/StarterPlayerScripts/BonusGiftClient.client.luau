local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local event = ReplicatedStorage:WaitForChild("BonusGiftEvent", 30)
if not event then return end

local gui = Instance.new("ScreenGui")
gui.Name = "BonusGiftHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Size = UDim2.new(0, 300, 0, 44)
label.Position = UDim2.new(0.5, 0, 0, 132)
label.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.TextSize = 20
label.TextColor3 = Color3.fromRGB(255, 245, 150)
label.TextStrokeTransparency = 0.45
label.TextTransparency = 1
label.Visible = false
label.Parent = gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 220, 80)
stroke.Thickness = 2
stroke.Transparency = 1
stroke.Parent = label

local token = 0

event.OnClientEvent:Connect(function(message)
	token += 1
	local myToken = token
	label.Text = "BONUS GIFT: " .. tostring(message)
	label.Visible = true
	label.Position = UDim2.new(0.5, 0, 0, 132)
	label.BackgroundTransparency = 0.08
	label.TextTransparency = 0
	stroke.Transparency = 0.1

	TweenService:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 118),
	}):Play()

	task.delay(2.2, function()
		if myToken ~= token then return end
		TweenService:Create(label, TweenInfo.new(0.25), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.25), {
			Transparency = 1,
		}):Play()
		task.delay(0.28, function()
			if myToken == token then
				label.Visible = false
			end
		end)
	end)
end)
