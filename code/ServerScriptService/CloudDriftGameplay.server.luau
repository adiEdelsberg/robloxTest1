local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order = 31,
	name = "Cloud Drift",
	targetKey = "CloudDrift",
	remainingName = "CloudDriftRemaining",
	totalName = "CloudDriftTotal",
	cx = -2860,
	cz = 4760,
	hw = 69,
	hd = 69,
	wallH = 136,
	shape = "hourglass",
	primary = "Institutional white",
	secondary = "Cyan",
	accent = "Bright yellow",
	floorColor = "Pastel blue",
	platformColor = "Light blue",
	orbitSpeed = 0.22,
	jumperStyle = "hourglassRun",
	obstacleStyle = "cloudSteps",
})
