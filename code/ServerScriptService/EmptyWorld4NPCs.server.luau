-- EmptyWorld4NPCs.server.luau
-- Level 20 is currently a visual test room: no color-square mission, no extra NPCs.
-- Keep only the shared progress values so the rest of the game can still reference them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10) or ReplicatedStorage

local function numberValue(name, value)
	local existing = gameEvents:FindFirstChild(name)
	if existing and existing:IsA("NumberValue") then
		existing.Value = value
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local created = Instance.new("NumberValue")
	created.Name = name
	created.Value = value
	created.Parent = gameEvents
	return created
end

numberValue("EmptyWorld4NPCsRemaining", 0)
numberValue("EmptyWorld4NPCsTotal", 0)

local oldSquares = workspace:FindFirstChild("EmptyWorld4Squares")
if oldSquares then
	oldSquares:Destroy()
end

print("[EmptyWorld4NPCs] Level 20 gameplay visuals disabled; goblin import remains only.")
