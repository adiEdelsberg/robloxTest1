-- EmptyWorld4Builder.server.luau
-- Level 20 (Neon Rift) — Enchanted Forest: winding nature trail, pond, stream,
-- stone ruins, campfire, mushroom clusters, wildflowers, fireflies.

local CX, CZ    = -2860, 1700
local FLOOR_Y   = 1
local HALF_W    = 350
local HALF_D    = 280
local CONTAIN_H = 400
local Y         = FLOOR_Y
local fullW     = HALF_W * 2
local fullD     = HALF_D * 2

local old = workspace:FindFirstChild("EmptyWorld4")
if old then old:Destroy() end

local folder = Instance.new("Folder")
folder.Name   = "EmptyWorld4"
folder.Parent = workspace

math.randomseed(77)

local function p(name, size, cf, color, mat, trans, collide)
	local o = Instance.new("Part")
	o.Name          = name
	o.Size          = size
	o.CFrame        = cf
	o.BrickColor    = BrickColor.new(color)
	o.Material      = mat or Enum.Material.SmoothPlastic
	o.Transparency  = trans or 0
	o.Anchored      = true
	o.CanCollide    = collide ~= false
	o.CanTouch      = false
	o.CastShadow    = false
	o.TopSurface    = Enum.SurfaceType.Smooth
	o.BottomSurface = Enum.SurfaceType.Smooth
	o.Parent        = folder
	return o
end

-- Angle-oriented segment helper (aligns part's Z axis along the A→B direction)
local function segment(name, x1,z1, x2,z2, width, height, yOff, color, mat, trans, collide)
	local dx  = x2-x1; local dz = z2-z1
	local len = math.sqrt(dx*dx + dz*dz)
	local ang = math.atan2(dx, dz)
	return p(name, Vector3.new(width, height, len),
		CFrame.new((x1+x2)/2, Y+yOff, (z1+z2)/2) * CFrame.Angles(0, ang, 0),
		color, mat, trans or 0, collide)
end

-- ── Invisible containment ─────────────────────────────────────────────────────
p("ContainN", Vector3.new(fullW,CONTAIN_H,1), CFrame.new(CX,Y+CONTAIN_H/2,CZ-HALF_D), "Medium stone grey", nil, 1)
p("ContainS", Vector3.new(fullW,CONTAIN_H,1), CFrame.new(CX,Y+CONTAIN_H/2,CZ+HALF_D), "Medium stone grey", nil, 1)
p("ContainW", Vector3.new(1,CONTAIN_H,fullD), CFrame.new(CX-HALF_W,Y+CONTAIN_H/2,CZ), "Medium stone grey", nil, 1)
p("ContainE", Vector3.new(1,CONTAIN_H,fullD), CFrame.new(CX+HALF_W,Y+CONTAIN_H/2,CZ), "Medium stone grey", nil, 1)

-- ── TERRAIN BASE — layered ground ─────────────────────────────────────────────
-- Deep soil
p("Soil",     Vector3.new(fullW,8,fullD), CFrame.new(CX,Y-4,CZ),   "Reddish brown", Enum.Material.Ground)
-- Primary forest floor (dark earthy green)
p("GrassBase",Vector3.new(fullW,1.2,fullD), CFrame.new(CX,Y+0.6,CZ),"Earth green",  Enum.Material.Grass)
-- Brighter central meadow clearing
p("Meadow",   Vector3.new(380,0.8,320), CFrame.new(CX+40,Y+1.2,CZ-10),"Bright green",Enum.Material.Grass)
-- Mossy NW quadrant (dense canopy feel)
p("MossNW",   Vector3.new(280,0.7,220), CFrame.new(CX-150,Y+1.1,CZ-100),"Sand green", Enum.Material.Grass)
-- Dry SE patch (sunlit clearing)
p("DrySE",    Vector3.new(200,0.65,180), CFrame.new(CX+160,Y+1.05,CZ+140),"Khaki",   Enum.Material.Ground)
-- Muddy SW (near stream outflow)
p("MudSW",    Vector3.new(160,0.65,130), CFrame.new(CX-190,Y+1.0,CZ+155),"Brown",    Enum.Material.Ground)
-- Sandy NE sun patch
p("SandNE",   Vector3.new(140,0.6,110), CFrame.new(CX+190,Y+1.0,CZ-170),"Sand yellow",Enum.Material.Sand)

-- ── GENTLE HILLOCKS ───────────────────────────────────────────────────────────
local hills = {
	{ CX-195, CZ-155, 130, 85, 5 },
	{ CX+175, CZ-185, 110, 75, 4 },
	{ CX-235, CZ+105, 100, 72, 3.5 },
}
for i, h in ipairs(hills) do
	p("HillBase"..i, Vector3.new(h[3],h[5],h[4]),
		CFrame.new(h[1],Y+h[5]/2,h[2]), "Earth green", Enum.Material.Grass)
	p("HillTop"..i, Vector3.new(h[3]*0.55,h[5]*0.6,h[4]*0.55),
		CFrame.new(h[1],Y+h[5]+h[5]*0.3,h[2]), "Bright green", Enum.Material.Grass)
	-- Rocky face on one side
	p("HillRock"..i, Vector3.new(h[3]*0.3,h[5]*0.7,h[4]*0.25),
		CFrame.new(h[1]+h[3]*0.25,Y+h[5]*0.35,h[2]-h[4]*0.2) * CFrame.Angles(0,0.3,0.15),
		"Dark stone grey", Enum.Material.Rock)
end

-- ── WINDING NATURE TRAIL ─────────────────────────────────────────────────────
-- Main trail: SW entry → centre house → NE exit (organic S-curve)
local TW = 12   -- trail width

local mainTrail = {
	{ -3175, 1895 }, { -3105, 1838 }, { -3035, 1793 },
	{ -2965, 1762 }, { -2905, 1732 }, { -2862, 1700 },
	{ -2820, 1663 }, { -2765, 1615 }, { -2705, 1578 },
	{ -2635, 1530 }, { -2560, 1492 },
}
for i = 1, #mainTrail - 1 do
	local a, b = mainTrail[i], mainTrail[i+1]
	-- Worn earth edge (wider, slightly lower)
	segment("TrailEdge"..i, a[1],a[2], b[1],b[2], TW+6, 0.5, 1.08, "Dark orange", Enum.Material.Ground, 0, false)
	-- Central dirt surface
	segment("Trail"..i,     a[1],a[2], b[1],b[2], TW,   0.5, 1.2,  "Sand yellow", Enum.Material.Ground, 0, false)
	-- Pebble texture strip down the middle
	segment("TrailPebble"..i,a[1],a[2],b[1],b[2], TW*0.35,0.25,1.34,"Fossil",    Enum.Material.Pebble,  0, false)
end

-- Branch to campfire
local campTrail = { { -3035, 1793 }, { -3062, 1858 }, { -3090, 1924 } }
for i = 1, #campTrail - 1 do
	local a, b = campTrail[i], campTrail[i+1]
	segment("CampEdge"..i,  a[1],a[2],b[1],b[2], TW+4, 0.5, 1.08, "Dark orange", Enum.Material.Ground, 0, false)
	segment("CampTrail"..i, a[1],a[2],b[1],b[2], TW-2, 0.5, 1.2,  "Sand yellow", Enum.Material.Ground, 0, false)
end

-- Branch to pond
local pondTrail = { { -2820, 1663 }, { -2802, 1732 }, { -2793, 1808 } }
for i = 1, #pondTrail - 1 do
	local a, b = pondTrail[i], pondTrail[i+1]
	segment("PondEdge"..i,  a[1],a[2],b[1],b[2], TW+4, 0.5, 1.08, "Dark orange", Enum.Material.Ground, 0, false)
	segment("PondTrail"..i, a[1],a[2],b[1],b[2], TW-2, 0.5, 1.2,  "Sand yellow", Enum.Material.Ground, 0, false)
end

-- Stepping stones along the main trail
local stepStones = {
	{-3162,1892}, {-3098,1840}, {-3028,1797}, {-2958,1765},
	{-2898,1736}, {-2853,1704}, {-2828,1667}, {-2768,1618},
	{-2708,1582}, {-2640,1534}, {-2570,1496},
}
for i, s in ipairs(stepStones) do
	local sz1 = 4 + math.random(0,4)
	local sz2 = 4 + math.random(0,3)
	p("Step"..i, Vector3.new(sz1,0.45,sz2),
		CFrame.new(s[1],Y+1.45,s[2]) * CFrame.Angles(0,math.random()*math.pi*2,0),
		"Medium stone grey", Enum.Material.Slate, 0, true)
end

-- ── STREAM ────────────────────────────────────────────────────────────────────
-- Flows from NE highlands, winds south-west to feed the pond
local streamPts = {
	{ -2645, 1455 }, { -2692, 1528 }, { -2732, 1602 },
	{ -2762, 1682 }, { -2791, 1762 }, { -2798, 1832 },
}
for i = 1, #streamPts - 1 do
	local a, b = streamPts[i], streamPts[i+1]
	-- Muddy banks
	segment("StreamBank"..i,  a[1],a[2],b[1],b[2], 26,0.9, 1.08, "Brown",     Enum.Material.Ground, 0, false)
	-- Sandy inner bank
	segment("StreamSand"..i,  a[1],a[2],b[1],b[2], 18,0.7, 1.15, "Sand yellow",Enum.Material.Sand,  0, false)
	-- Water surface
	segment("StreamWater"..i, a[1],a[2],b[1],b[2], 10,0.3, 1.32, "Dark blue", Enum.Material.Glass,  0.22, false)
	-- Water shimmer
	segment("StreamShimmer"..i,a[1],a[2],b[1],b[2],8,0.1, 1.36, "Cyan",      Enum.Material.Neon,   0.75, false)
end

-- ── POND ─────────────────────────────────────────────────────────────────────
local PX, PZ = -2802, 1855
p("PondBed",    Vector3.new(110,1,90),  CFrame.new(PX,Y+0.7,PZ),  "Brown",     Enum.Material.Ground, 0)
p("PondSand",   Vector3.new(98,0.8,78), CFrame.new(PX,Y+1.05,PZ), "Sand yellow",Enum.Material.Sand,   0, false)
p("PondWater",  Vector3.new(90,0.35,70),CFrame.new(PX,Y+1.30,PZ), "Dark blue", Enum.Material.Glass,  0.18, false)
p("PondShimmer",Vector3.new(86,0.1,66), CFrame.new(PX,Y+1.36,PZ), "Cyan",      Enum.Material.Neon,   0.72, false)
p("PondDeep",   Vector3.new(50,0.1,38), CFrame.new(PX,Y+1.37,PZ), "Navy blue", Enum.Material.Neon,   0.8,  false)

-- Lily pads
local lilies = {
	{PX-22,PZ-16,11,9},{PX+20,PZ-22,9,7},{PX-12,PZ+20,13,10},
	{PX+27,PZ+12,8,6}, {PX-32,PZ+6,10,8},{PX+10,PZ-9,7,5},
	{PX-5, PZ+30,9,7}, {PX+32,PZ-8,6,5},
}
for i, lp in ipairs(lilies) do
	p("Lily"..i,       Vector3.new(lp[3],0.28,lp[4]), CFrame.new(lp[1],Y+1.42,lp[2]), "Earth green",  Enum.Material.SmoothPlastic, 0, false)
	p("LilyFlower"..i, Vector3.new(2.2,2,2.2),         CFrame.new(lp[1],Y+2.5,lp[2]),  "Hot pink",     Enum.Material.Neon,          0.1, false)
	p("LilyCenter"..i, Vector3.new(1,1,1),              CFrame.new(lp[1],Y+3.0,lp[2]),  "Bright yellow",Enum.Material.Neon,          0,   false)
end
-- Cattails
for i, c in ipairs({ {PX-46,PZ-26},{PX-48,PZ+32},{PX+44,PZ-20},{PX+46,PZ+24},{PX+5,PZ-42} }) do
	p("CattailStem"..i, Vector3.new(1.2,16,1.2),  CFrame.new(c[1],Y+9,c[2]),   "Brown",       Enum.Material.Wood)
	p("CattailHead"..i, Vector3.new(2.2,6,2.2),   CFrame.new(c[1],Y+17.5,c[2]),"Reddish brown",Enum.Material.SmoothPlastic)
	p("CattailLeaf"..i, Vector3.new(0.6,12,0.4),  CFrame.new(c[1]+2,Y+8,c[2]) * CFrame.Angles(0,0,math.rad(-18)), "Earth green", Enum.Material.SmoothPlastic, 0, false)
end
-- Pond rocks
for i, r in ipairs({ {PX-50,PZ-12},{PX-46,PZ+32},{PX+46,PZ-28},{PX+48,PZ+18},{PX-8,PZ-42},{PX+22,PZ+40} }) do
	local rw=8+math.random(0,6); local rh=3+math.random(0,4); local rd=7+math.random(0,5)
	p("PondRock"..i, Vector3.new(rw,rh,rd),
		CFrame.new(r[1],Y+rh/2+1,r[2]) * CFrame.Angles(0,math.random()*math.pi*2,math.random()*0.3-0.15),
		"Dark stone grey", Enum.Material.Rock)
end

-- ── MUSHROOM CLUSTERS ─────────────────────────────────────────────────────────
local shroomData = {
	{ CX-108, CZ+78,  "Really red",    "Hot pink"      },
	{ CX-290, CZ-80,  "Bright orange", "Bright yellow" },
	{ CX+100, CZ+200, "Bright violet", "Cyan"          },
	{ CX+220, CZ+80,  "Cyan",          "White"         },
	{ CX-320, CZ+180, "Sand green",    "Lime green"    },
	{ CX+260, CZ-60,  "Magenta",       "Hot pink"      },
	{ CX-80,  CZ-240, "Bright yellow", "White"         },
	{ CX+50,  CZ+240, "Really red",    "Bright orange" },
	{ CX-200, CZ-190, "Teal",          "Cyan"          },
	{ CX+160, CZ-100, "Lime green",    "White"         },
}
for ci, mc in ipairs(shroomData) do
	local count = math.random(2, 5)
	for j = 1, count do
		local ox = math.random(-18, 18)
		local oz = math.random(-18, 18)
		local sh = 3 + math.random(0, 7)
		local cw = 4 + math.random(0, 5)
		local x, z = mc[1]+ox, mc[2]+oz
		-- White speckled stem
		p("Stem"..ci.."_"..j,  Vector3.new(1.4,sh,1.4),
			CFrame.new(x,Y+1.2+sh/2,z), "Institutional white", Enum.Material.SmoothPlastic, 0, true)
		-- Coloured glowing cap
		p("Cap"..ci.."_"..j,   Vector3.new(cw,cw*0.38,cw),
			CFrame.new(x,Y+1.2+sh+cw*0.12,z), mc[3], Enum.Material.Neon, 0.05, false)
		-- Under-cap glow
		p("Glow"..ci.."_"..j,  Vector3.new(cw*0.65,0.3,cw*0.65),
			CFrame.new(x,Y+1.2+sh,z), mc[4], Enum.Material.Neon, 0.45, false)
	end
end

-- ── STONE RUINS (NW corner, half buried in hillside) ─────────────────────────
local RX, RZ = -3105, 1535
-- Main wall standing
p("RuinWall1",   Vector3.new(52,24,3.5), CFrame.new(RX,Y+13,RZ),                   "Dark stone grey", Enum.Material.Cobblestone)
-- Broken leaning piece
p("RuinWall2",   Vector3.new(24,15,3.5),
	CFrame.new(RX+40,Y+8.5,RZ) * CFrame.Angles(0,0,math.rad(9)),                    "Dark stone grey", Enum.Material.Cobblestone)
-- Toppled slab
p("RuinSlab",    Vector3.new(32,3.5,5),
	CFrame.new(RX-6,Y+2.75,RZ+9)  * CFrame.Angles(0,math.rad(18),0),               "Medium stone grey",Enum.Material.Cobblestone)
-- Low crumbled rubble pile
p("Rubble1",     Vector3.new(18,5,14),  CFrame.new(RX+25,Y+3,RZ+6)  * CFrame.Angles(0,math.rad(22),0.1), "Dark stone grey",Enum.Material.Rock)
p("Rubble2",     Vector3.new(12,4,10),  CFrame.new(RX-18,Y+2.5,RZ+5)* CFrame.Angles(0,math.rad(-10),0),  "Medium stone grey",Enum.Material.Rock)
-- Mossy overlay (semi-transparent green sheets)
p("WallMoss1",   Vector3.new(52,10,0.6),CFrame.new(RX,Y+5.5,RZ-1.4),               "Earth green",  Enum.Material.Grass, 0.3, false)
p("WallMoss2",   Vector3.new(22,14,0.6),CFrame.new(RX-6,Y+15,RZ-1.4),              "Bright green", Enum.Material.Grass, 0.55, false)
-- Small doorway arch suggestion
p("ArchL",       Vector3.new(4.5,20,3.5),CFrame.new(RX-32,Y+11,RZ),               "Dark stone grey", Enum.Material.Cobblestone)
p("ArchR",       Vector3.new(4.5,20,3.5),CFrame.new(RX-20,Y+11,RZ),               "Dark stone grey", Enum.Material.Cobblestone)
p("ArchLintel",  Vector3.new(16,4,4),   CFrame.new(RX-26,Y+22,RZ),                "Dark stone grey", Enum.Material.Cobblestone)
-- Ivy on arch
p("ArchIvy1",    Vector3.new(5,16,0.5), CFrame.new(RX-32,Y+12,RZ-2) * CFrame.Angles(0,0,-0.08), "Earth green", Enum.Material.Grass, 0.35, false)
p("ArchIvy2",    Vector3.new(4,12,0.5), CFrame.new(RX-20,Y+14,RZ-2) * CFrame.Angles(0,0,0.06),  "Bright green",Enum.Material.Grass, 0.45, false)

-- ── CAMPFIRE ─────────────────────────────────────────────────────────────────
local FX, FZ = -3092, 1928
-- Cleared patch
p("FirePatch",  Vector3.new(40,0.5,40),  CFrame.new(FX,Y+1.1,FZ),  "Brown",         Enum.Material.Ground, 0, false)
p("FireGravel", Vector3.new(26,0.5,26),  CFrame.new(FX,Y+1.18,FZ), "Dark stone grey",Enum.Material.Pebble, 0, false)
-- Stone ring
for i = 1, 10 do
	local ang = (i-1)*math.pi*2/10
	local r = 9
	local sw = 3+math.random(0,2); local sh = 2+math.random(0,2); local sd = 3+math.random(0,2)
	p("CampStone"..i, Vector3.new(sw,sh,sd),
		CFrame.new(FX+math.cos(ang)*r, Y+sh/2+1.2, FZ+math.sin(ang)*r) * CFrame.Angles(0,math.random()*math.pi,0),
		"Dark stone grey", Enum.Material.Rock)
end
-- Ash bed
p("Ash",       Vector3.new(9,0.35,9),   CFrame.new(FX,Y+1.52,FZ),  "Dark stone grey",Enum.Material.SmoothPlastic, 0, false)
-- Log seats around fire
for i, ls in ipairs({ {FX+18,FZ,0},{FX-18,FZ,0},{FX,FZ+18,90},{FX,FZ-18,90} }) do
	p("Seat"..i, Vector3.new(14,3,4.5),
		CFrame.new(ls[1],Y+2.7,ls[2]) * CFrame.Angles(0,math.rad(ls[3]+math.random(-8,8)),0),
		"Reddish brown", Enum.Material.Wood)
end
-- Fire layers (layered neon for depth)
p("FireLog1",   Vector3.new(8,1.2,2.5), CFrame.new(FX,Y+1.9,FZ)  * CFrame.Angles(0,math.rad(30),0),  "Reddish brown",Enum.Material.Wood)
p("FireLog2",   Vector3.new(8,1.2,2.5), CFrame.new(FX,Y+1.9,FZ)  * CFrame.Angles(0,math.rad(-40),0), "Brown",        Enum.Material.Wood)
p("Ember",      Vector3.new(6,1.2,6),   CFrame.new(FX,Y+2.2,FZ),  "Bright orange", Enum.Material.Neon, 0.5, false)
p("Flame1",     Vector3.new(5,5,5),     CFrame.new(FX,Y+4,FZ),    "Bright orange", Enum.Material.Neon, 0.05,false)
p("Flame2",     Vector3.new(3.5,7,3.5), CFrame.new(FX,Y+6,FZ),    "Bright yellow", Enum.Material.Neon, 0.1, false)
p("Flame3",     Vector3.new(2,5,2),     CFrame.new(FX,Y+8.5,FZ),  "White",         Enum.Material.Neon, 0.3, false)
p("FireGlow",   Vector3.new(22,0.3,22), CFrame.new(FX,Y+1.55,FZ), "Bright orange", Enum.Material.Neon, 0.65,false)
p("FireGlow2",  Vector3.new(40,0.2,40), CFrame.new(FX,Y+1.52,FZ), "Bright yellow", Enum.Material.Neon, 0.82,false)

-- ── FALLEN LOGS ───────────────────────────────────────────────────────────────
local logDat = {
	{ CX-178, CZ+78,  62, 5, 28  },
	{ CX+198, CZ-138, 52, 4, 15  },
	{ CX-98,  CZ+218, 46, 4, 42  },
	{ CX+138, CZ+178, 58, 5, -20 },
	{ CX-278, CZ-58,  42, 4, 70  },
	{ CX+240, CZ+120, 36, 3, -55 },
}
for i, l in ipairs(logDat) do
	local lw = l[4]
	p("Log"..i,      Vector3.new(lw,lw,l[3]),
		CFrame.new(l[1],Y+lw/2+1.2,l[2]) * CFrame.Angles(0,math.rad(l[5]),0),
		"Reddish brown", Enum.Material.Wood)
	-- Moss on top
	p("LogMoss"..i,  Vector3.new(lw+0.5,0.5,l[3]),
		CFrame.new(l[1],Y+lw+1.5,l[2])   * CFrame.Angles(0,math.rad(l[5]),0),
		"Earth green",   Enum.Material.Grass, 0.2, false)
	-- Mushroom on log
	local mx, mz = l[1]+math.random(-8,8), l[2]+math.random(-8,8)
	p("LogShroom"..i,Vector3.new(0.8,2.5,0.8),
		CFrame.new(mx,Y+lw+2,mz), "Institutional white",Enum.Material.SmoothPlastic, 0, false)
	p("LogShroomCap"..i,Vector3.new(2.8,1,2.8),
		CFrame.new(mx,Y+lw+3.5,mz),"Really red",Enum.Material.Neon, 0.1, false)
end

-- ── WILDFLOWER MEADOW (NE sunlit area) ────────────────────────────────────────
local flowerColors = { "Hot pink","Bright yellow","Bright violet","Really red","White","Lime green","Cyan","Bright orange" }
for i = 1, 55 do
	local fx = CX + 100 + math.random(0,200)
	local fz = CZ - 240 + math.random(0,200)
	local fc = flowerColors[math.random(1,#flowerColors)]
	local fh = 1.5 + math.random(0,3)
	-- Stem
	p("Stem_M"..i,   Vector3.new(0.6,fh,0.6),
		CFrame.new(fx,Y+1.2+fh/2,fz),  "Bright green", Enum.Material.SmoothPlastic, 0, false)
	-- Petals (neon)
	p("Flower_M"..i, Vector3.new(2,2,2),
		CFrame.new(fx,Y+1.2+fh+1,fz),  fc, Enum.Material.Neon, 0.08, false)
end

-- ── ROCKY OUTCROPS ────────────────────────────────────────────────────────────
local rocks = {
	{ CX-318, CZ-198, 30,18,22 }, { CX+288, CZ+178, 24,15,19 },
	{ CX-258, CZ+222, 20,12,15 }, { CX+252, CZ-212, 26,13,20 },
	{ CX+312, CZ-82,  16,9, 12 }, { CX-312, CZ+162, 22,12,16 },
	{ CX-60,  CZ-265, 18,10,14 }, { CX+188, CZ+242, 14,8, 11 },
}
for i, r in ipairs(rocks) do
	p("Rock"..i, Vector3.new(r[3],r[4],r[5]),
		CFrame.new(r[1],Y+r[4]/2+1,r[2]) * CFrame.Angles(math.random()*0.5-0.25,math.random()*math.pi,math.random()*0.3-0.15),
		"Dark stone grey", Enum.Material.Rock)
	p("RockSmall"..i, Vector3.new(r[3]*0.5,r[4]*0.55,r[5]*0.48),
		CFrame.new(r[1]+r[3]*0.38,Y+r[4]*0.28+1,r[2]-r[5]*0.28) * CFrame.Angles(math.random()*0.6,math.random()*math.pi,0),
		"Medium stone grey", Enum.Material.Granite)
end

-- ── LEAF PILES ────────────────────────────────────────────────────────────────
local leafCols = {"Bright orange","Bright red","Brown","Sand yellow","Reddish brown","Dark orange"}
for i = 1, 28 do
	local lx = CX + (math.random()-0.5)*fullW*0.78
	local lz = CZ + (math.random()-0.5)*fullD*0.78
	p("Leaf"..i, Vector3.new(math.random(6,18),0.5,math.random(6,15)),
		CFrame.new(lx,Y+1.62,lz) * CFrame.Angles(0,math.random()*math.pi,0),
		leafCols[math.random(1,#leafCols)], Enum.Material.SmoothPlastic, 0.12, false)
end

-- ── PUDDLES (scattered rain pools) ───────────────────────────────────────────
local puddles = {
	{CX-120,CZ+118,26,18},{CX+155,CZ+75,18,13},{CX-248,CZ-35,14,10},
	{CX+80, CZ-195,12,10},{CX-180,CZ+190,20,14},
}
for i, q in ipairs(puddles) do
	p("Puddle"..i,    Vector3.new(q[3],0.5,q[4]),   CFrame.new(q[1],Y+1.05,q[2]), "Brown",    Enum.Material.Ground, 0, false)
	p("PuddleWater"..i,Vector3.new(q[3]-2,0.15,q[4]-2),CFrame.new(q[1],Y+1.22,q[2]),"Dark blue",Enum.Material.Glass, 0.28, false)
end

-- ── FIREFLIES ─────────────────────────────────────────────────────────────────
for i = 1, 35 do
	local fx = CX + (math.random()-0.5)*fullW*0.82
	local fz = CZ + (math.random()-0.5)*fullD*0.82
	local fy = Y + 3 + math.random()*14
	local fc = math.random() < 0.55 and "Lime green" or (math.random() < 0.5 and "Bright yellow" or "Cyan")
	p("Firefly"..i, Vector3.new(0.35,0.35,0.35), CFrame.new(fx,fy,fz), fc, Enum.Material.Neon, 0, false)
end

-- ── HANGING LANTERNS along the trail ─────────────────────────────────────────
local lanterns = {
	{-3122,1878},{-2992,1802},{-2902,1748},
	{-2842,1688},{-2768,1622},{-2685,1556},
}
for i, lp in ipairs(lanterns) do
	local px, pz = lp[1]-9, lp[2]
	p("LPost"..i,  Vector3.new(1.2,14,1.2), CFrame.new(px,Y+8,pz),        "Dark stone grey",Enum.Material.Metal)
	p("LArm"..i,   Vector3.new(7,0.7,0.7),  CFrame.new(px+3.5,Y+14.8,pz), "Dark stone grey",Enum.Material.Metal, 0, false)
	p("LChain"..i, Vector3.new(0.5,3,0.5),  CFrame.new(px+6.8,Y+13,pz),   "Dark stone grey",Enum.Material.Metal, 0, false)
	p("LBox"..i,   Vector3.new(3.5,4.5,3.5),CFrame.new(px+6.8,Y+10.5,pz), "Dark orange",    Enum.Material.Wood,  0.15)
	p("LGlass"..i, Vector3.new(3,4,3),      CFrame.new(px+6.8,Y+10.5,pz), "Bright yellow",  Enum.Material.Neon,  0.08, false)
	p("LPool"..i,  Vector3.new(10,0.2,10),  CFrame.new(px+6.8,Y+7.8,pz),  "Bright yellow",  Enum.Material.Neon,  0.82, false)
end

-- ── HOUSE CLEARING (cobble plaza around goblin1House) ────────────────────────
p("HouseGround",  Vector3.new(140,0.7,140), CFrame.new(CX,Y+1.05,CZ), "Brown",          Enum.Material.Ground, 0, false)
p("HouseGravel",  Vector3.new(118,0.65,118),CFrame.new(CX,Y+1.15,CZ), "Dark stone grey",Enum.Material.Pebble, 0, false)
p("HouseCobble",  Vector3.new(90, 0.7, 90), CFrame.new(CX,Y+1.2,CZ),  "Fossil",         Enum.Material.Cobblestone, 0, false)
-- Decorative glowing ring of stones around the house
for i = 1, 16 do
	local ang = (i-1)*math.pi*2/16
	local r   = 52
	p("PlazaRing"..i, Vector3.new(2.5,0.5,9),
		CFrame.new(CX+math.cos(ang)*r,Y+1.45,CZ+math.sin(ang)*r) * CFrame.Angles(0,ang,0),
		"Cyan", Enum.Material.Neon, 0.28, false)
end
-- Corner accent stones
for i, corner in ipairs({ {CX-48,CZ-48},{CX+48,CZ-48},{CX-48,CZ+48},{CX+48,CZ+48} }) do
	p("PlazaCorner"..i, Vector3.new(6,2,6),
		CFrame.new(corner[1],Y+2,corner[2]), "Dark stone grey", Enum.Material.Cobblestone)
end

print("[EmptyWorld4Builder] Enchanted forest terrain built for Level 20 — trail, pond, stream, ruins, campfire, mushrooms.")
