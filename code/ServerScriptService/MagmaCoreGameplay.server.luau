local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order = 27,
	name = "Magma Core",
	targetKey = "MagmaCore",
	remainingName = "MagmaCoreRemaining",
	totalName = "MagmaCoreTotal",
	cx = -2860,
	cz = 3500,
	hw = 69,
	hd = 69,
	wallH = 142,
	shape = "diamond",
	primary = "Bright red",
	secondary = "Bright orange",
	accent = "New Yeller",
	floorColor = "Really black",
	platformColor = "Reddish brown",
	orbitSpeed = 0.34,
	jumperStyle = "spiral",
	obstacleStyle = "lavaRings",
})
