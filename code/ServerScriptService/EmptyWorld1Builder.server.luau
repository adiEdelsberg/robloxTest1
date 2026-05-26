-- EmptyWorld1Builder.server.luau
-- Builds the "Empty World 1" sky arena using the shared WorldFramework.
-- Positioned as a floating arena beside the Playground.
-- Center: (460, 0), floor top at Y=80.
-- Bounds: X=110..810, Z=-280..280  (matches WorldRunDoors and EmptyWorld1NPCs).
--
-- To resize:  change halfW / halfD; WorldRunDoors bounds must match.
-- To recolor: override floorColor / gridColor / wallColor below.

local WorldFramework = require(script.Parent:WaitForChild("WorldFramework"))

WorldFramework.build({
	name      = "EmptyWorld1",

	-- Sky position: beside the Playground, used as the second main level.
	cx        = -550,
	cz        = 1700,

	-- Half-extents -> X: 110..810, Z: -280..280
	halfW     = 350,
	halfD     = 280,

	-- Floor elevated to sky level matching the Keep island surface.
	floorY      = 1,
	floorThick  = 2,
	floorColor  = "Dark indigo",

	-- Neon grid
	gridColor   = "Cyan",
	gridStep    = 14,
	gridAlpha   = 0.25,

	-- Visible perimeter walls
	wallH       = 24,
	wallThick   = 0.8,
	wallColor   = "Dark indigo",
	wallAlpha   = 0.45,

	-- Invisible containment walls (keep dinos and players inside)
	containH    = 400,

	-- No entrance gaps — closed arena
	northGap    = 0,
	southGap    = 0,
	eastGap     = 25,
	westGap     = 25,
})
