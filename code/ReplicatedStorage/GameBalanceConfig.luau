--[[
	GameBalanceConfig

	This is the one place to tune the main game logic.

	Change ACTIVE_MODE to choose which values the game uses:
		"debug" = current testing values, very generous/easy.
		"test"  = production values with faster starter movement for QA.
		"prod"  = realistic public-game values, slower progression.

	The rest of the game reads Balance.Player, Balance.Shop, Balance.StageTargets,
	and so on. You do not need to edit the other scripts for normal balancing.
]]

local ACTIVE_MODE = "debug"

local PROFILES = {}

PROFILES.debug = {
	Gameplay = {
		-- RespawnAtLastVisitedWorld:
		-- false = every respawn returns to the starter island by the spin wheel.
		-- true = after the player enters a world, future respawns return to that last visited world.
		RespawnAtLastVisitedWorld = false,
	},

	Player = {
		-- How much Cash each player starts with when they join the server.
		StartingCash = 1000000,
	},

	Movement = {
		-- JumpPower by JumpBoost tier. Tier 0 is normal jump.
		JumpPowers = { [0] = 50, [1] = 85, [2] = 120, [3] = 155, [4] = 190, [5] = 225 },

		-- WalkSpeed by SpeedBoost tier. Debug starts at 6x normal speed for fast testing.
		WalkSpeeds = { [0] = 96, [1] = 104, [2] = 112, [3] = 120, [4] = 128, [5] = 136 },
	},

	Skateboard = {
		-- Set true to give every player the skateboard at game start.
		StartWithPlayer = false,

		-- Seconds of active riding time after winning a skateboard. Timer pauses while off the board.
		DurationSeconds = 180,

		-- WalkSpeed while mounted on the skateboard.
		Speed = 58,

		-- JumpPower while mounted on the skateboard.
		JumpPower = 210,

		-- Extra HipHeight added while riding so the board sits under the player.
		HipHeight = 1.2,
	},

	Shop = {
		-- How many seconds a purchased speed/jump boost lasts.
		BoostDuration = 60,

		-- Cash price for each shop upgrade button.
		ItemPrices = {
			speed1 = 1,
			speed2 = 1,
			speed3 = 1,
			speed4 = 1,
			speed5 = 1,
			jump1 = 1,
			jump2 = 1,
			jump3 = 1,
			jump4 = 1,
			jump5 = 1,
		},
	},

	SpinWheel = {
		-- Seconds a player must wait between spins.
		CooldownSeconds = 10,

		-- Cash awarded by the regular cash prize slice.
		CashPrize = 5000,

		-- Cash awarded by the jackpot prize slice.
		JackpotCash = 25000,
	},

	Ball = {
		-- Cash awarded when a thrown ball hits another player.
		MoneyPerPlayerHit = 10,
	},

	NPCRewards = {
		-- Default cash per NPC hit if an NPC definition does not override moneyPerHit.
		BaseMoneyPerHit = 1000000,

		-- Default cash when an NPC is defeated if an NPC definition does not override moneyOnDefeat.
		BaseMoneyOnDefeat = 30,
	},

	StageTargets = {
		-- How many defeats/catches/eaten fruit are needed to clear each stage.
		Playground = 1,
		EmptyWorld1 = 1,
		EmptyWorld2 = 1,
		EmptyWorld3 = 1,
		EmptyWorld4 = 3,
		Pizza = 1,
		Galactic = 1,
		Jungle = 1,
		Sports = 1,
		Tennis = 1,
		GameStation = 1,
		CoffeeShop = 1,
		BurgerHouse = 1,
		NewPizzaPlace = 1,
		SwimmingPool = 1,
		DinosaurPark = 1,
		DinoBeach = 1,
		FlyingDinoForest = 1,
		CherryGrove = 1,
		GalacticOrchard = 1,
		SkyVault = 1,
		StormTower = 1,
		FrostBasin = 1,
		EmberHold = 1,
		NovaSpire = 1,
		MagmaCore = 1,
		StormCircuit = 1,
		ShadowVault = 1,
		ApexNexus = 1,
		CloudDrift = 1,
		CoralReef = 1,
		BubbleBounce = 1,
		ZenGarden = 1,
		CrystalSpires = 1,
		NeonTriangle = 1,
		WideCanyon = 1,
		NarrowPass = 1,
		DiamondGate = 1,
		HourglassVault = 1,
		MovementLab = 1,
		FightArena = 1,
		EmptyWorld43 = 4,
	},

	StageCarpets = {
		-- How many valid jumps on a completion carpet are needed where carpet logic is used.
		JumpsNeeded = 2,
	},

	CatchRewards = {
		-- Bird cash rewards.
		BirdSmall = 75,
		BirdNormal = 150,
		BirdGiant = 350,

		-- Dino catch rewards by world.
		DinosaurParkSmall = 90,
		DinosaurPark = 180,
		DinosaurParkGiant = 420,
		DinoBeachSmall = 95,
		DinoBeach = 190,
		DinoBeachGiant = 440,
		FlyingDinoForestSmall = 110,
		FlyingDinoForest = 210,
		FlyingDinoForestGiant = 470,

		-- Giant dino riding rewards.
		Cherry = 240,
		GalacticFruit = 420,
	},
}

PROFILES.prod = {
	Gameplay = {
		-- Production default keeps the starter island as the respawn hub.
		-- Set true if you want players to respawn in the last world they visited.
		RespawnAtLastVisitedWorld = false,
	},

	Player = {
		-- Production starting cash. Low enough that earning and upgrades matter.
		StartingCash = 0,
	},

	Movement = {
		-- Production jump boosts: useful, but not map-breaking.
		JumpPowers = { [0] = 50, [1] = 68, [2] = 86, [3] = 104, [4] = 122, [5] = 140 },

		-- Production speed boosts: noticeable progression without becoming uncontrollable.
		WalkSpeeds = { [0] = 16, [1] = 19, [2] = 22, [3] = 25, [4] = 28, [5] = 32 },
	},

	Skateboard = {
		-- In production, players should win/unlock the skateboard instead of starting with it.
		StartWithPlayer = false,

		-- Production skateboard active riding time. Timer pauses while off the board.
		DurationSeconds = 180,

		-- Production skateboard speed.
		Speed = 42,

		-- Production skateboard jump.
		JumpPower = 95,

		-- Keep the same visual ride height unless the board clips into the ground.
		HipHeight = 1.2,
	},

	Shop = {
		-- Production boost duration.
		BoostDuration = 60,

		-- Production shop prices. Early tiers are affordable; later tiers take stage rewards.
		ItemPrices = {
			speed1 = 150,
			speed2 = 350,
			speed3 = 750,
			speed4 = 1400,
			speed5 = 2500,
			jump1 = 150,
			jump2 = 350,
			jump3 = 750,
			jump4 = 1400,
			jump5 = 2500,
		},
	},

	SpinWheel = {
		-- Production cooldown to stop constant farming.
		CooldownSeconds = 300,

		-- Production regular cash prize.
		CashPrize = 500,

		-- Production jackpot prize.
		JackpotCash = 2500,
	},

	Ball = {
		-- Production PvP hit reward.
		MoneyPerPlayerHit = 5,
	},

	NPCRewards = {
		-- Production default NPC hit reward.
		BaseMoneyPerHit = 10,

		-- Production default NPC defeat reward.
		BaseMoneyOnDefeat = 35,
	},

	StageTargets = {
		-- Production targets: still quick early, longer in later worlds.
		Playground = 2,
		EmptyWorld1 = 2,
		EmptyWorld2 = 2,
		EmptyWorld3 = 2,
		EmptyWorld4 = 2,
		Pizza = 4,
		Galactic = 6,
		Jungle = 6,
		Sports = 8,
		Tennis = 10,
		GameStation = 8,
		CoffeeShop = 4,
		BurgerHouse = 5,
		NewPizzaPlace = 5,
		SwimmingPool = 5,
		DinosaurPark = 4,
		DinoBeach = 5,
		FlyingDinoForest = 5,
		CherryGrove = 6,
		GalacticOrchard = 8,
		SkyVault = 1,
		StormTower = 1,
		FrostBasin = 1,
		EmberHold = 1,
		NovaSpire = 1,
		MagmaCore = 1,
		StormCircuit = 1,
		ShadowVault = 1,
		ApexNexus = 1,
		CloudDrift = 1,
		CoralReef = 1,
		BubbleBounce = 1,
		ZenGarden = 1,
		CrystalSpires = 1,
		NeonTriangle = 1,
		WideCanyon = 1,
		NarrowPass = 1,
		DiamondGate = 1,
		HourglassVault = 1,
		MovementLab = 1,
		FightArena = 1,
		EmptyWorld43 = 4,
	},

	StageCarpets = {
		-- Production carpet requirement.
		JumpsNeeded = 2,
	},

	CatchRewards = {
		-- Production bird rewards.
		BirdSmall = 20,
		BirdNormal = 45,
		BirdGiant = 110,

		-- Production dino rewards by world.
		DinosaurParkSmall = 30,
		DinosaurPark = 60,
		DinosaurParkGiant = 140,
		DinoBeachSmall = 35,
		DinoBeach = 70,
		DinoBeachGiant = 160,
		FlyingDinoForestSmall = 40,
		FlyingDinoForest = 85,
		FlyingDinoForestGiant = 190,

		-- Production giant dino riding rewards.
		Cherry = 90,
		GalacticFruit = 150,
	},
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, childValue in pairs(value) do
		copy[key] = deepCopy(childValue)
	end
	return copy
end

PROFILES.test = deepCopy(PROFILES.prod)
PROFILES.test.Movement.JumpPowers[0] = 60
PROFILES.test.Movement.WalkSpeeds[0] = 48

local selected = PROFILES[ACTIVE_MODE]
if not selected then
	warn("Unknown GameBalanceConfig ACTIVE_MODE: " .. tostring(ACTIVE_MODE) .. ". Falling back to debug.")
	ACTIVE_MODE = "debug"
	selected = PROFILES.debug
end

selected.ActiveMode = ACTIVE_MODE
selected.Profiles = PROFILES

return selected
