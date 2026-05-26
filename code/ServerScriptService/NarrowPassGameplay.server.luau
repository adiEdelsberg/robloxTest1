local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order          = 38,
	name           = "Narrow Pass",
	targetKey      = "NarrowPass",
	remainingName  = "NarrowPassRemaining",
	totalName      = "NarrowPassTotal",
	cx             = -2860,
	cz             = 6755,
	hw             = 54,
	hd             = 76,
	wallH          = 134,
	shape          = "pinched",
	primary        = "Lime green",
	secondary      = "Bright green",
	accent         = "White",
	floorColor     = "Earth green",
	platformColor  = "Mint",
	orbitSpeed     = 0.35,
	denseJumpers   = true,
	jumperStyle    = "pinchedDash",
	obstacleStyle  = "pinballBumpers",
})
