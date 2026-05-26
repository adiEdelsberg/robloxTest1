local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order          = 37,
	name           = "Wide Canyon",
	targetKey      = "WideCanyon",
	remainingName  = "WideCanyonRemaining",
	totalName      = "WideCanyonTotal",
	cx             = -2860,
	cz             = 6470,
	hw             = 76,
	hd             = 54,
	wallH          = 134,
	shape          = "zigzag",
	primary        = "Bright orange",
	secondary      = "Bright red",
	accent         = "Bright yellow",
	floorColor     = "Reddish brown",
	platformColor  = "Nougat",
	orbitSpeed     = 0.22,
	denseJumpers   = true,
	jumperStyle    = "canyonLadder",
	obstacleStyle  = "canyonBridges",
})
