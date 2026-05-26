-- Fallback debug balance used if ReplicatedStorage.GameBalanceConfig is missing in Studio.
return {
	Gameplay = { RespawnAtLastVisitedWorld = false },
	Player = { StartingCash = 1000000 },
	Movement = {
		JumpPowers = { [0] = 50, [1] = 85, [2] = 120, [3] = 155, [4] = 190, [5] = 225 },
		WalkSpeeds = { [0] = 96, [1] = 104, [2] = 112, [3] = 120, [4] = 128, [5] = 136 },
	},
	Skateboard = { StartWithPlayer = false, DurationSeconds = 180, Speed = 58, JumpPower = 210, HipHeight = 1.2 },
	Shop = {
		BoostDuration = 60,
		ItemPrices = { speed1 = 1, speed2 = 1, speed3 = 1, speed4 = 1, speed5 = 1, jump1 = 1, jump2 = 1, jump3 = 1, jump4 = 1, jump5 = 1 },
	},
	SpinWheel = { CooldownSeconds = 10, CashPrize = 5000, JackpotCash = 25000 },
	Ball = { MoneyPerPlayerHit = 10 },
	NPCRewards = { BaseMoneyPerHit = 1000000, BaseMoneyOnDefeat = 30 },
	StageTargets = {
		Playground = 1, EmptyWorld1 = 3, Pizza = 1, Galactic = 1, Jungle = 1, Sports = 1, Tennis = 1, GameStation = 1,
		CoffeeShop = 1, BurgerHouse = 1, NewPizzaPlace = 1, SwimmingPool = 1,
		DinosaurPark = 1, DinoBeach = 1, FlyingDinoForest = 1, CherryGrove = 1, GalacticOrchard = 1,
		MovementLab = 1, FightArena = 1, EmptyWorld43 = 4,
	},
	StageCarpets = { JumpsNeeded = 2 },
	CatchRewards = {
		BirdSmall = 75, BirdNormal = 150, BirdGiant = 350,
		DinosaurParkSmall = 90, DinosaurPark = 180, DinosaurParkGiant = 420,
		DinoBeachSmall = 95, DinoBeach = 190, DinoBeachGiant = 440,
		FlyingDinoForestSmall = 110, FlyingDinoForest = 210, FlyingDinoForestGiant = 470,
		Cherry = 240, GalacticFruit = 420,
	},
	ActiveMode = "fallback-debug",
}
