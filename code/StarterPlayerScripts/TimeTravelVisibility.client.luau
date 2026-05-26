local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

if Balance.ActiveMode ~= "prod" then
	return
end

local player = Players.LocalPlayer

local function updateObject(object)
	local order = object:GetAttribute("DestinationOrder")
	if typeof(order) ~= "number" and (object:IsA("BillboardGui") or object:IsA("SurfaceGui") or object:IsA("SelectionBox")) and object.Parent then
		order = object.Parent:GetAttribute("DestinationOrder")
	end
	if typeof(order) ~= "number" then return end

	local reachedOrder = player:GetAttribute("CheckpointOrder") or 1
	local visible = order <= reachedOrder

	if object:IsA("BasePart") and (object:GetAttribute("TimeMachinePart") or object:GetAttribute("LaunchMachinePart")) then
		object.LocalTransparencyModifier = visible and 0 or 1
	elseif object:IsA("SurfaceGui") then
		object.Enabled = visible
	elseif object:IsA("ProximityPrompt") then
		object.Enabled = visible
	elseif object:IsA("BillboardGui") then
		object.Enabled = visible
	elseif object:IsA("SelectionBox") then
		object.Visible = visible
	end
end

local function refresh()
	local folder = workspace:FindFirstChild("TimeTravelMachines")
	if not folder then return end
	for _, object in folder:GetDescendants() do
		updateObject(object)
	end
end

player:GetAttributeChangedSignal("CheckpointOrder"):Connect(refresh)

workspace.ChildAdded:Connect(function(child)
	if child.Name == "TimeTravelMachines" then
		child.DescendantAdded:Connect(function(object)
			task.defer(function()
				updateObject(object)
				for _, descendant in object:GetDescendants() do
					updateObject(descendant)
				end
			end)
		end)
		task.defer(refresh)
	end
end)

local folder = workspace:FindFirstChild("TimeTravelMachines")
if folder then
	folder.DescendantAdded:Connect(function(object)
		task.defer(function()
			updateObject(object)
			for _, descendant in object:GetDescendants() do
				updateObject(descendant)
			end
		end)
	end)
end

task.defer(refresh)
