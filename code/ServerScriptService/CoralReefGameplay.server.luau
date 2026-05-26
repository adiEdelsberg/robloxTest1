local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order = 32,
	name = "Coral Reef",
	targetKey = "CoralReef",
	remainingName = "CoralReefRemaining",
	totalName = "CoralReefTotal",
	cx = -2860,
	cz = 5060,
	hw = 64,
	hd = 64,
	wallH = 132,
	shape = "wide",
	primary = "Bright blue",
	secondary = "Hot pink",
	accent = "Bright orange",
	floorColor = "Sand blue",
	platformColor = "Teal",
	orbitSpeed = 0.3,
	jumperStyle = "cornerLoop",
	obstacleStyle = "coralArches",
})
