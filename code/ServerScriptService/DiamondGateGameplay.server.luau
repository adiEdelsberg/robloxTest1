local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order          = 39,
	name           = "Diamond Gate",
	targetKey      = "DiamondGate",
	remainingName  = "DiamondGateRemaining",
	totalName      = "DiamondGateTotal",
	cx             = -2860,
	cz             = 7040,
	hw             = 69,
	hd             = 69,
	wallH          = 134,
	shape          = "kite",
	primary        = "Bright yellow",
	secondary      = "New Yeller",
	accent         = "Institutional white",
	floorColor     = "Dark orange",
	platformColor  = "Nougat",
	orbitSpeed     = 0.26,
	denseJumpers   = true,
	jumperStyle    = "gateArc",
	obstacleStyle  = "goldenGates",
})
