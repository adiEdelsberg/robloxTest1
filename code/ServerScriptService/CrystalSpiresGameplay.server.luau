local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order          = 35,
	name           = "Crystal Spires",
	targetKey      = "CrystalSpires",
	remainingName  = "CrystalSpiresRemaining",
	totalName      = "CrystalSpiresTotal",
	cx             = -2860,
	cz             = 5900,
	hw             = 69,
	hd             = 69,
	wallH          = 134,
	shape          = "crystal",
	primary        = "Cyan",
	secondary      = "Toothpaste",
	accent         = "Institutional white",
	floorColor     = "Bright blue",
	platformColor  = "Pastel blue",
	orbitSpeed     = 0.28,
	denseJumpers   = true,
	jumperStyle    = "crystalClimb",
	obstacleStyle  = "crystalSpikes",
})
