local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order          = 40,
	name           = "Hourglass Vault",
	targetKey      = "HourglassVault",
	remainingName  = "HourglassVaultRemaining",
	totalName      = "HourglassVaultTotal",
	cx             = -2860,
	cz             = 7325,
	hw             = 69,
	hd             = 69,
	wallH          = 134,
	shape          = "bowtie",
	primary        = "Bright violet",
	secondary      = "Hot pink",
	accent         = "Institutional white",
	floorColor     = "Really black",
	platformColor  = "Medium stone grey",
	orbitSpeed     = 0.32,
	denseJumpers   = true,
	jumperStyle    = "vaultClockwise",
	obstacleStyle  = "vaultClock",
})
