local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order = 33,
	name = "Bubble Bounce",
	targetKey = "BubbleBounce",
	remainingName = "BubbleBounceRemaining",
	totalName = "BubbleBounceTotal",
	cx = -2860,
	cz = 5340,
	hw = 69,
	hd = 69,
	wallH = 134,
	shape = "octagon",
	primary = "Cyan",
	secondary = "Toothpaste",
	accent = "Institutional white",
	floorColor = "Bright blue",
	platformColor = "Pastel blue",
	orbitSpeed = 0.4,
	jumperStyle = "octagonHop",
	obstacleStyle = "bubbleOrbs",
})
