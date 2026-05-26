local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage:FindFirstChild("GameBalanceConfig") or script.Parent:FindFirstChild("GameBalanceFallback"))

local IS_PROD = Balance.ActiveMode == "prod"

local function shouldRemoveCarpet(object)
	if not object:IsA("BasePart") then return false end
	if IS_PROD and object.Name:find("Carpet") then return true end
	return object.Name:find("CompletionCarpet") and not object.Name:find("DevCompletionCarpet")
end

local function removeOldCarpet(object)
	if shouldRemoveCarpet(object) then
		object.CanTouch = false
		object.CanCollide = false
		object.Transparency = 1
		object:Destroy()
	end
end

for _, object in workspace:GetDescendants() do
	removeOldCarpet(object)
end

workspace.DescendantAdded:Connect(removeOldCarpet)
