-- Fallback debug balance used by client UI if ReplicatedStorage.GameBalanceConfig is missing.
return {
	Gameplay = { RespawnAtLastVisitedWorld = false },
	Shop = {
		BoostDuration = 60,
		ItemPrices = { speed1 = 1, speed2 = 1, speed3 = 1, speed4 = 1, speed5 = 1, jump1 = 1, jump2 = 1, jump3 = 1, jump4 = 1, jump5 = 1 },
	},
	ActiveMode = "fallback-debug",
}
