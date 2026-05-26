local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order = 34,
	name = "Zen Garden",
	targetKey = "ZenGarden",
	remainingName = "ZenGardenRemaining",
	totalName = "ZenGardenTotal",
	cx = -2860,
	cz = 5620,
	hw = 64,
	hd = 64,
	wallH = 130,
	shape = "cross",
	primary = "Lime green",
	secondary = "Bright yellow",
	accent = "White",
	floorColor = "Earth green",
	platformColor = "Medium stone grey",
	orbitSpeed = 0.18,
	jumperStyle = "crossLane",
	obstacleStyle = "zenSpinners",
})
