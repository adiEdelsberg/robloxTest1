local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order          = 36,
	name           = "Neon Triangle",
	targetKey      = "NeonTriangle",
	remainingName  = "NeonTriangleRemaining",
	totalName      = "NeonTriangleTotal",
	cx             = -2860,
	cz             = 6185,
	hw             = 69,
	hd             = 69,
	wallH          = 134,
	shape          = "trapezoid",
	primary        = "Hot pink",
	secondary      = "Bright violet",
	accent         = "White",
	floorColor     = "Really black",
	platformColor  = "Medium stone grey",
	orbitSpeed     = 0.30,
	denseJumpers   = true,
	jumperStyle    = "triangleHop",
	obstacleStyle  = "neonBeams",
})
