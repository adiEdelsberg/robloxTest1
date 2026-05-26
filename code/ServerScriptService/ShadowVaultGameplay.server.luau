local Builder = require(script.Parent:WaitForChild("CreativeJumperRoom"))

Builder.start({
	order = 29,
	name = "Shadow Vault",
	targetKey = "ShadowVault",
	remainingName = "ShadowVaultRemaining",
	totalName = "ShadowVaultTotal",
	cx = -2860,
	cz = 4130,
	hw = 64,
	hd = 64,
	wallH = 138,
	shape = "triangle",
	primary = "Really black",
	secondary = "Bright violet",
	accent = "Cyan",
	floorColor = "Black",
	platformColor = "Dark indigo",
	orbitSpeed = 0.28,
	jumperStyle = "centerBurst",
	obstacleStyle = "shadowBlades",
})
