local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local gameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local dinoRemote = gameEvents:WaitForChild("GiantDinoRideAction")

local ACTION_NAME = "GiantDinoBite"
local moveKeys = {
	[Enum.KeyCode.W] = Vector2.new(0, 1),
	[Enum.KeyCode.S] = Vector2.new(0, -1),
	[Enum.KeyCode.A] = Vector2.new(-1, 0),
	[Enum.KeyCode.D] = Vector2.new(1, 0),
	[Enum.KeyCode.Up] = Vector2.new(0, 1),
	[Enum.KeyCode.Down] = Vector2.new(0, -1),
	[Enum.KeyCode.Left] = Vector2.new(-1, 0),
	[Enum.KeyCode.Right] = Vector2.new(1, 0),
}
local pressed = {}
local thumbstick = Vector2.zero
local hiddenGuis = {}

local function setGuiVisible(guiObject, visible)
	if guiObject:IsA("ScreenGui") then
		guiObject.Enabled = visible
	else
		guiObject.Visible = visible
	end
end

local function getGuiVisible(guiObject)
	if guiObject:IsA("ScreenGui") then
		return guiObject.Enabled
	end
	return guiObject.Visible
end

local function findHudObject(name)
	local direct = player.PlayerGui:FindFirstChild(name)
	if direct then return direct end
	for _, gui in player.PlayerGui:GetChildren() do
		local found = gui:FindFirstChild(name, true)
		if found then return found end
	end
	return nil
end

local function bite()
	if player:GetAttribute("RidingGiantDino") then
		dinoRemote:FireServer("Bite")
	end
end

local function onAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		bite()
	end
	return Enum.ContextActionResult.Sink
end

local function getCameraMoveDirection()
	local input = Vector2.zero
	for keyCode, vector in moveKeys do
		if pressed[keyCode] then
			input += vector
		end
	end
	if thumbstick.Magnitude > input.Magnitude then
		input = thumbstick
	end

	if input.Magnitude <= 0.05 then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local fallback = humanoid and humanoid.MoveDirection or Vector3.zero
		return Vector3.new(fallback.X, 0, fallback.Z)
	end

	input = input.Unit
	local look = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local flatRight = Vector3.new(right.X, 0, right.Z)
	if flatLook.Magnitude < 0.001 then flatLook = Vector3.zAxis end
	if flatRight.Magnitude < 0.001 then flatRight = Vector3.xAxis end
	return (flatLook.Unit * input.Y + flatRight.Unit * input.X)
end

local DROP_ACTION = "GiantDinoDrop"

local function refreshBinding()
	if player:GetAttribute("RidingGiantDino") then
		ContextActionService:BindAction(ACTION_NAME, onAction, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
		ContextActionService:SetTitle(ACTION_NAME, "BITE")
		ContextActionService:SetPosition(ACTION_NAME, UDim2.new(0.78, 0, 0.62, 0))
		ContextActionService:BindAction(DROP_ACTION, function(_, state)
			if state == Enum.UserInputState.Begin then
				dinoRemote:FireServer("Drop")
			end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
		ContextActionService:SetTitle(DROP_ACTION, "DROP")
		ContextActionService:SetPosition(DROP_ACTION, UDim2.new(0.62, 0, 0.62, 0))
		for _, guiName in { "SkateHUD", "ActiveBoosts" } do
			local gui = findHudObject(guiName)
			if gui and hiddenGuis[gui] == nil then
				hiddenGuis[gui] = getGuiVisible(gui)
				setGuiVisible(gui, false)
			end
		end
	else
		ContextActionService:UnbindAction(ACTION_NAME)
		ContextActionService:UnbindAction(DROP_ACTION)
		for gui, wasEnabled in hiddenGuis do
			if gui.Parent then
				setGuiVisible(gui, wasEnabled)
			end
		end
		hiddenGuis = {}
	end
end

player:GetAttributeChangedSignal("RidingGiantDino"):Connect(refreshBinding)
UserInputService.JumpRequest:Connect(bite)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if moveKeys[input.KeyCode] then
		pressed[input.KeyCode] = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if moveKeys[input.KeyCode] then
		pressed[input.KeyCode] = nil
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		thumbstick = input.Position.Magnitude > 0.12 and Vector2.new(input.Position.X, input.Position.Y) or Vector2.zero
	end
end)
local lookSendTimer = 0
RunService.RenderStepped:Connect(function(dt)
	if not player:GetAttribute("RidingGiantDino") then return end
	lookSendTimer += dt
	if lookSendTimer < 0.05 then return end
	lookSendTimer = 0
	dinoRemote:FireServer("Look", camera.CFrame.LookVector)
	local moveDirection = getCameraMoveDirection()
	dinoRemote:FireServer("Move", moveDirection.Magnitude > 0.05 and moveDirection.Unit or Vector3.zero)
end)
refreshBinding()
