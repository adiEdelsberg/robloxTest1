local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order = 28,
	name = "Storm Circuit",
	targetKey = "StormCircuit",
	remainingName = "StormCircuitRemaining",
	totalName = "StormCircuitTotal",
	cx = -2860,
	cz = 3830,
	hw = 74,
	hd = 58,
	wallH = 136,
	shape = "narrow",
	primary = "Cyan",
	secondary = "Electric blue",
	accent = "Institutional white",
	floorColor = "Really black",
	platformColor = "Dark stone grey",
	orbitSpeed = 0.46,
	jumperStyle = "switchback",
	obstacleStyle = "electricSlalom",
})
