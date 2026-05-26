local G = 1

local oldFolder = workspace:FindFirstChild("BridgeChasm")
if oldFolder then
	oldFolder:Destroy()
end

local folder = Instance.new("Folder")
folder.Name   = "BridgeChasm"
folder.Parent = workspace

-- Z-axis bridges (between north/south worlds, centered at x=0 unless cx is set)
local Z_BRIDGES = {
	{ name = "PlaygroundPizza",   z1 = 59,   z2 = 132,  color = "Cyan"          },
	{ name = "PizzaGalactic",     z1 = 268,  z2 = 385,  color = "Bright violet" },
	{ name = "GalacticJungle",    z1 = 525,  z2 = 640,  color = "Bright green"  },
	{ name = "JungleSports",      z1 = 780,  z2 = 860,  color = "Bright yellow" },
	{ name = "SportsTennis",      z1 = 1020, z2 = 1090, color = "Lime green"    },
	{ name = "TennisGameStation", z1 = 1231, z2 = 1300, color = "Cyan"          },
	{ name = "GameStationCoffee",   z1 = 1460, z2 = 1540, color = "Bright orange" },
	-- South wing: Neon Rift → Frost Basin → Ember Hold → Nova Spire (all at cx=-2860)
	{ name = "NeonRiftFrostBasin",  z1 = 1976, z2 = 2142, color = "Cyan",          cx = -2860 },
	{ name = "FrostBasinEmberHold", z1 = 2266, z2 = 2486, color = "Bright orange", cx = -2860 },
	{ name = "EmberHoldNovaSpire",      z1 = 2616, z2 = 2836, color = "Bright violet", cx = -2860 },
	{ name = "NovaSpirePrismPeak",      z1 = 2964, z2 = 3141, color = "Cyan",          cx = -2860 },
	{ name = "PrismPeakMagmaCore",      z1 = 3259, z2 = 3431, color = "Bright orange", cx = -2860 },
	{ name = "MagmaCoreStormCircuit",   z1 = 3569, z2 = 3771, color = "Hot pink",      cx = -2860 },
	{ name = "StormCircuitShadowVault", z1 = 3889, z2 = 4066, color = "Dark stone grey", cx = -2860 },
	{ name = "ShadowVaultApexNexus",    z1 = 4194, z2 = 4366, color = "Bright yellow", cx = -2860 },
	{ name = "ApexNexusCloudDrift",     z1 = 4534, z2 = 4691, color = "Institutional white", cx = -2860 },
	{ name = "CloudDriftCoralReef",     z1 = 4829, z2 = 4996, color = "Cyan",          cx = -2860 },
	{ name = "CoralReefBubbleBounce",   z1 = 5124, z2 = 5271, color = "Hot pink",      cx = -2860 },
	{ name = "BubbleBounceZenGarden",   z1 = 5409, z2 = 5556, color = "Lime green",    cx = -2860 },
	{ name = "ZenGardenCrystalSpires",  z1 = 5684, z2 = 5831, color = "Cyan",           cx = -2860 },
	{ name = "CrystalSpiresNeonTri",    z1 = 5969, z2 = 6116, color = "Hot pink",       cx = -2860 },
	{ name = "NeonTriWideCanyon",       z1 = 6254, z2 = 6401, color = "Bright orange",  cx = -2860 },
	{ name = "WideCanyonNarrowPass",    z1 = 6539, z2 = 6686, color = "Lime green",     cx = -2860 },
	{ name = "NarrowPassDiamondGate",   z1 = 6824, z2 = 6971, color = "Bright yellow",  cx = -2860 },
	{ name = "DiamondGateHourglass",    z1 = 7109, z2 = 7256, color = "Bright violet",  cx = -2860 },
	{ name = "HourglassMovementLab",    z1 = 7394, z2 = 7540, color = "Electric blue",   cx = -2860 },
	{ name = "MovementLabFightArena",   z1 = 7680, z2 = 7990, color = "Bright red",       cx = -2860 },
	{ name = "FightArenaEmpty43",       z1 = 8210, z2 = 8340, color = "Lime green",       cx = -2860 },
	{ name = "Empty43Empty44",          z1 = 8480, z2 = 8550, color = "Bright violet",    cx = -2860 },
	{ name = "Empty44Empty45",          z1 = 8860, z2 = 8990, color = "Hot pink",         cx = -2860 },
}

-- X-axis bridges (between east/west bird worlds, centered at z=1700)
local X_BRIDGES = {
	{ name = "CoffeeEmpty",     x1 = -200, x2 = -140,  color = "Bright orange" },
	{ name = "CoffeeBurger",    x1 = 140,  x2 = 214,  color = "Bright yellow" },
	{ name = "BurgerNewPizza",  x1 = 490,  x2 = 566,  color = "Bright red"    },
	{ name = "NewPizzaPool",    x1 = 842,  x2 = 918,  color = "Cyan"          },
	{ name = "PoolDinoPark",    x1 = 1194, x2 = 1270, color = "Bright green"  },
	{ name = "DinoParkBeach",   x1 = 1546, x2 = 1622, color = "Bright yellow" },
	{ name = "BeachForest",     x1 = 1898, x2 = 1974, color = "Bright green"  },
	{ name = "ForestCherry",    x1 = 2250, x2 = 2308, color = "Really red"    },
	{ name = "CherryOrchard",   x1 = 2596, x2 = 2684, color = "Cyan"          },
	{ name = "EmptyStorm",      x1 = -970, x2 = -900,  color = "New Yeller"    },
	{ name = "StormVolt",       x1 = -1740, x2 = -1670, color = "Hot pink"      },
	{ name = "VoltNeon",        x1 = -2510, x2 = -2440, color = "Cyan"          },
	{ name = "NeonSkyVault",       x1 = -3466, x2 = -3210, color = "Bright yellow" },
	{ name = "SkyVaultStormTower", x1 = -3570, x2 = -3530, color = "Cyan"          },
}

local BW_Z = 22   -- Z-axis bridge width (studs in X)
local BW_X = 50   -- X-axis bridge width (studs in Z)

-- Set by each build function so mkpart can tag every part with its bridge name
local _currentBridgeName = ""

local function mkpart(size, cf, color, mat, trans, canCollide)
	local p = Instance.new("Part")
	p.Size          = size
	p.CFrame        = cf
	p.BrickColor    = BrickColor.new(color)
	p.Material      = mat
	p.Transparency  = trans or 0
	p.Anchored      = true
	p.CanCollide    = canCollide ~= false
	p.CanTouch      = false
	p.CastShadow    = false
	p.TopSurface    = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if _currentBridgeName ~= "" then
		p:SetAttribute("BridgeName", _currentBridgeName)
	end
	p.Parent        = folder
	return p
end

local function mkball(size, cf, color, trans)
	local p = mkpart(Vector3.one * size, cf, color, Enum.Material.Neon, trans, false)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Metadata folder read by BridgeEffect.client.luau for beacon placement
local metaFolder = Instance.new("Folder")
metaFolder.Name = "BridgeMeta"
metaFolder.Parent = folder

local function writeMeta(name, cx, cy, cz, axis)
	local v = Instance.new("CFrameValue")
	v.Name  = name
	v.Value = CFrame.new(cx, cy, cz)
	v:SetAttribute("Axis", axis)   -- "Z" or "X"
	v.Parent = metaFolder
end

-- Build a Z-axis galactic bridge (runs along +Z, width along X)
-- b.cx overrides the default centre X of 0 (used for off-axis bridges)
local function buildZBridge(b)
	_currentBridgeName = b.name
	local cx   = b.cx or 0
	local len  = b.z2 - b.z1
	local midZ = (b.z1 + b.z2) / 2
	local floorY = G + 0.25
	writeMeta(b.name, cx, floorY + 5, midZ, "Z")

	-- Main dark floor
	mkpart(Vector3.new(BW_Z, 0.5, len), CFrame.new(cx, floorY, midZ),
		"Really black", Enum.Material.SmoothPlastic)

	-- Galactic floor overlay (subtle neon tint)
	mkpart(Vector3.new(BW_Z - 2, 0.1, len - 2), CFrame.new(cx, floorY + 0.3, midZ),
		b.color, Enum.Material.Neon, 0.88, false)

	-- Edge neon floor strips
	for _, xOff in { -(BW_Z/2 - 0.6), (BW_Z/2 - 0.6) } do
		mkpart(Vector3.new(0.8, 0.2, len), CFrame.new(cx + xOff, floorY + 0.35, midZ),
			b.color, Enum.Material.Neon, 0.15, false)
	end

	-- Centre spine
	mkpart(Vector3.new(0.5, 0.15, len), CFrame.new(cx, floorY + 0.38, midZ),
		"Cyan", Enum.Material.Neon, 0.35, false)

	-- Side diamond-plate side walls (low, decorative)
	for _, xOff in { -BW_Z/2, BW_Z/2 } do
		mkpart(Vector3.new(0.5, 1.2, len), CFrame.new(cx + xOff, floorY + 0.85, midZ),
			"Really black", Enum.Material.DiamondPlate, 0.05, false)
	end

	-- Guard rail bar
	for _, xOff in { -BW_Z/2, BW_Z/2 } do
		mkpart(Vector3.new(0.35, 0.35, len), CFrame.new(cx + xOff, floorY + 3.8, midZ),
			b.color, Enum.Material.Neon, 0.28, false)
	end

	-- Rail posts with orb caps at intervals
	local postStep = 14
	local z = b.z1 + postStep / 2
	while z < b.z2 do
		for _, xOff in { -BW_Z/2, BW_Z/2 } do
			mkpart(Vector3.new(0.45, 3.6, 0.45), CFrame.new(cx + xOff, floorY + 2, z),
				"Dark stone grey", Enum.Material.Metal, 0, false)
			mkball(1.1, CFrame.new(cx + xOff, floorY + 4.0, z), b.color, 0.18)
		end
		-- Star orb in the floor centre
		mkball(0.65, CFrame.new(cx, floorY + 0.5, z), "Institutional white", 0.25)
		z += postStep
	end
end

-- Build an X-axis galactic bridge (runs along +X, width along Z)
local function buildXBridge(b)
	_currentBridgeName = b.name
	local len  = b.x2 - b.x1
	local midX = (b.x1 + b.x2) / 2
	local floorY = G + 0.25
	writeMeta(b.name, midX, floorY + 5, 1700, "X")

	-- Main dark floor
	mkpart(Vector3.new(len, 0.5, BW_X), CFrame.new(midX, floorY, 1700),
		"Really black", Enum.Material.SmoothPlastic)

	-- Galactic floor overlay
	mkpart(Vector3.new(len - 2, 0.1, BW_X - 2), CFrame.new(midX, floorY + 0.3, 1700),
		b.color, Enum.Material.Neon, 0.88, false)

	-- Edge neon floor strips
	for _, zOff in { -(BW_X/2 - 0.6), (BW_X/2 - 0.6) } do
		mkpart(Vector3.new(len, 0.2, 0.8), CFrame.new(midX, floorY + 0.35, 1700 + zOff),
			b.color, Enum.Material.Neon, 0.15, false)
	end

	-- Centre spine
	mkpart(Vector3.new(len, 0.15, 0.5), CFrame.new(midX, floorY + 0.38, 1700),
		"Cyan", Enum.Material.Neon, 0.35, false)

	-- Side walls
	for _, zOff in { -BW_X/2, BW_X/2 } do
		mkpart(Vector3.new(len, 1.2, 0.5), CFrame.new(midX, floorY + 0.85, 1700 + zOff),
			"Really black", Enum.Material.DiamondPlate, 0.05, false)
	end

	-- Guard rail bars
	for _, zOff in { -BW_X/2, BW_X/2 } do
		mkpart(Vector3.new(len, 0.35, 0.35), CFrame.new(midX, floorY + 3.8, 1700 + zOff),
			b.color, Enum.Material.Neon, 0.28, false)
	end

	-- Rail posts with orb caps
	local postStep = 14
	local x = b.x1 + postStep / 2
	while x < b.x2 do
		for _, zOff in { -BW_X/2, BW_X/2 } do
			mkpart(Vector3.new(0.45, 3.6, 0.45), CFrame.new(x, floorY + 2, 1700 + zOff),
				"Dark stone grey", Enum.Material.Metal, 0, false)
			mkball(1.1, CFrame.new(x, floorY + 4.0, 1700 + zOff), b.color, 0.18)
		end
		mkball(0.65, CFrame.new(x, floorY + 0.5, 1700), "Institutional white", 0.25)
		x += postStep
	end
end

for _, b in Z_BRIDGES do buildZBridge(b) end
for _, b in X_BRIDGES do buildXBridge(b) end

print("[BridgeChasm] Galactic bridges built.")
