-- TestLevelBuilder.server.luau
-- Test Level (-1) sky arena near the Clockwork Keep.
-- Same footprint as EmptyWorld1 (cx=460, cz=-750, halfW=350, halfD=280, floorY=80).

local WorldFramework = require(script.Parent:WaitForChild("WorldFramework"))

WorldFramework.build({
	name      = "TestLevel",
	cx        = 460,
	cz        = -750,
	halfW     = 350,
	halfD     = 280,
	floorY      = 80,
	floorThick  = 2,
	floorColor  = "Dark indigo",
	gridColor   = "Cyan",
	gridStep    = 14,
	gridAlpha   = 0.25,
	wallH       = 24,
	wallThick   = 0.8,
	wallColor   = "Dark indigo",
	wallAlpha   = 0.45,
	containH    = 400,
	northGap    = 0,
	southGap    = 0,
})
