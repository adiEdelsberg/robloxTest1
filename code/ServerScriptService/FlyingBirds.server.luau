-- Place in ServerScriptService/FlyingBirds.server.luau
-- Boots the high-level flying bird NPC system.

local ServerStorage = game:GetService("ServerStorage")

local FlyingBirdSystem = ServerStorage:WaitForChild("FlyingBirdSystem")
local ServerBirdService = require(FlyingBirdSystem:WaitForChild("ServerBirdService"))

local service = ServerBirdService.new()
service:start()
