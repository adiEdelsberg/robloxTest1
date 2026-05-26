-- EmptyWorld2Builder.server.luau
-- Builds "Storm Dome" — a sky arena with a black floor and lightning-yellow grid.
-- Center: cx=460, cz=750  |  Bounds: X=110..810, Z=470..1030  |  floorY=80

local WorldFramework = require(script.Parent:WaitForChild("WorldFramework"))

WorldFramework.build({
	name      = "EmptyWorld2",
	cx        = -1320,
	cz        = 1700,
	halfW     = 350,
	halfD     = 280,
	floorY      = 1,
	floorThick  = 3,
	floorColor  = "Really black",
	gridColor   = "New Yeller",
	gridStep    = 18,
	gridAlpha   = 0.15,
	wallH       = 32,
	wallThick   = 1.0,
	wallColor   = "Smoky grey",
	wallAlpha   = 0.35,
	containH    = 400,
	northGap    = 0,
	southGap    = 0,
	eastGap     = 25,
	westGap     = 25,
})
