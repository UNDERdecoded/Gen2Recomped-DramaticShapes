-- Interiors: metatile pins, and the elevation that is not height.
-- Runs against the REAL Brendan's House layouts out of the extracted data.
-- The engine tree this suite runs against.  Defaults to the current
-- directory, so the suite runs from a repository checkout on any
-- machine; override with ENGINE=... to point it somewhere else.  It
-- used to name a scratch directory that exists only on one
-- contributor's box, which meant this suite loaded src/* from THAT
-- tree no matter what MOD said.
local ENGINE = os.getenv("ENGINE") or "."
package.path = ENGINE .. "/?.lua;" .. ENGINE .. "/?/init.lua;" .. package.path
-- The mod under test.  Defaults to the tree this suite ships in, so the
-- suite runs from a checkout on any machine; override with MOD=... to
-- point it somewhere else.  It used to name a scratch directory that
-- exists only on one contributor's box, so four of the six suites were
-- silently measuring a stale copy -- and reported green while the tree
-- they were meant to cover was failing.
local MOD = os.getenv("MOD") or "mods/DRAMATIC_SHAPE"
if MOD:sub(-1) ~= "/" then MOD = MOD .. "/" end
local GEN = "/mnt/user-data/uploads/Gen2Recomp/emerald/data/generated/"
_G.love = require("tests.love_stub")

local V = {}
local mods, dats = {}, {}
function V.require(n)
  local h = mods[n]; if h ~= nil then return h end
  local v = assert(loadfile(MOD .. "lib/" .. n .. ".lua"))(V); mods[n] = v; return v
end
function V.data(n)
  local h = dats[n]; if h ~= nil then return h end
  local v = assert(loadfile(MOD .. "data/" .. n .. ".lua"))(V); dats[n] = v; return v
end

local tilesets = assert(loadfile(GEN .. "tilesets.lua"))()
local mapts    = assert(loadfile(GEN .. "map_tilesets.lua"))()
local consts   = assert(loadfile(GEN .. "constants.lua"))()
local layouts  = assert(loadfile(GEN .. "map_layouts.lua"))()
_G.Game = { data = { tilesets = tilesets, map_tilesets = mapts,
                     constants = consts, maps = {} } }

local pass, fail = 0, 0
local function eq(a, b, w)
  if a == b then pass = pass + 1 else fail = fail + 1
    io.write("  FAIL  ", w, ": got ", tostring(a), " want ", tostring(b), "\n") end
end
local function ok(c, w)
  if c then pass = pass + 1 else fail = fail + 1; io.write("  FAIL  ", w, "\n") end
end

local Map = require("src.world.Map")
local PAIR = "TILESET_03DF884_03DFAF4"
local function houseMap(layoutIndex, mapId)
  local lay = layouts[layoutIndex]
  local def = { id = mapId, width = lay.width, height = lay.height,
                blocks = lay.blocks, collisionCells = lay.collisionCells,
                elevationCells = lay.elevationCells, border = lay.border,
                borderBlock = 0, tileset = PAIR }
  local m = Map.new(def, tilesets[PAIR])
  m.id = mapId
  return m
end

local Gen3 = V.require("Gen3")
local TileShape = V.require("TileShape")

io.write("Brendan's House 1F -- the kitchen and the dining set\n")
local m1 = houseMap(54, "MAP_G01_N00")
local ctx1 = Gen3.forMap(m1)
ok(ctx1 ~= nil, "the 1F context builds")
eq(ctx1.mapName, "LittlerootTown_BrendansHouse_1F", "and names the map")
eq(ctx1.secondaryName, "gTileset_BrendansMaysHouse", "and its tileset")
ok(ctx1.pins ~= nil, "so the metatile pins resolve")

local shapes1 = TileShape.forMap(m1)
local function classAtCell(map, shapes, cx, cy)
  local tx, ty = cx * 2, cy * 2
  local s = TileShape.at(map, shapes, Gen3.tileAt(map, tx, ty), tx, ty)
  return s and s.class, s
end

-- the kitchen front row, y=2: fridge, sink, worktop, cabinet, cabinet
do
  local want = { [0] = "appliance", [1] = "sink", [2] = "worktop",
                 [3] = "cabinet", [4] = "cabinet" }
  for x, w in pairs(want) do
    local c, s = classAtCell(m1, shapes1, x, 2)
    eq(c, w, ("kitchen cell (%d,2) is a %s"):format(x, w))
    ok(s and s.authored == true,
       ("...and is AUTHORED so it leaves the wall flood (%d,2)"):format(x))
  end
end
-- the wall band above it must NOT be pinned -- it has to stay in the flood
do
  local c, s = classAtCell(m1, shapes1, 0, 1)
  eq(c, "wall", "the unit's upper door stays part of the wall")
  eq(s.authored, false, "and UNAUTHORED, so the wall still measures as one run")
end
-- the dining set
do
  eq(classAtCell(m1, shapes1, 3, 6), "tabletop", "the table cloth is a table")
  eq(classAtCell(m1, shapes1, 2, 6), "chair", "with a chair beside it")
  eq(classAtCell(m1, shapes1, 5, 6), "chair", "and one on the other side")
  local _, s = classAtCell(m1, shapes1, 2, 6)
  ok(s.art == "top", "a chair's art rides its top face -- it is drawn from above")
  ok(s.h > 0 and s.h <= 10, "at seat height (" .. tostring(s.h) .. ")")
  ok(m1:isWalkableCell(2, 6), "and the chair cell is PASSABLE, as Emerald leaves it")
end
-- the fridge is taller than the worktop, and both are uprights
do
  local _, fridge = classAtCell(m1, shapes1, 0, 2)
  local _, top    = classAtCell(m1, shapes1, 2, 2)
  ok(fridge.h > top.h, "the fridge stands taller than the counter (" ..
     fridge.h .. " > " .. top.h .. ")")
  eq(fridge.art, "upright", "and folds its face-on art up its south side")
end

io.write("Brendan's House 2F -- the bed, the TV, and the step that isn't there\n")
local m2 = houseMap(55, "MAP_G01_N01")
local ctx2 = Gen3.forMap(m2)
eq(ctx2.mapName, "LittlerootTown_BrendansHouse_2F", "the 2F map is named")
eq(ctx2.outdoor, false, "and known to be indoors")

-- THE REGRESSION: two cells of this bedroom carry elevation 4, which ranked
-- into a 16px slab standing in the middle of the carpet.
do
  local raised = 0
  for cy = 0, m2.def.height - 1 do
    for cx = 0, m2.def.width - 1 do
      if ctx2.groundHeight(cx, cy) ~= 0 then raised = raised + 1 end
    end
  end
  eq(raised, 0, "no cell indoors is raised -- elevation is sprite priority here")
  ok(ctx2.elevationAt(0, 5) == 4,
     "even though the map really does carry elevation 4 there")
end

local shapes2 = TileShape.forMap(m2)
do
  eq(classAtCell(m2, shapes2, 1, 4), "bed", "the bed is a bed")
  local _, s = classAtCell(m2, shapes2, 1, 4)
  ok(s.art == "top", "drawn from above")
  ok(s.h > 0 and s.h < 12, "and low (" .. tostring(s.h) .. ")")
  -- (3,2) IS THE GAME SYSTEM, metatile 614 -- not the television.  The
-- label below said "television" from before the two were told apart:
-- the real set is metatile 2 of gTileset_Building (MB_TELEVISION),
-- and class `tv` is the white box beside it.  Reported from play,
-- "make the gamesystem a 2d sprite", so 614/615 are pinned `cutout`
-- and build one world pixel thick.  The assertion follows the pin.
  eq(classAtCell(m2, shapes2, 3, 2), "cutout", "the game system is a flat sprite")
  local _, t = classAtCell(m2, shapes2, 3, 2)
  ok(t.authored == true, "authored, so it does not drag the wall forward")
  eq(classAtCell(m2, shapes2, 0, 2), "chair", "and the stool is a stool")
end
-- the rug must stay flat
do
  local c, s = classAtCell(m2, shapes2, 5, 4)
  eq(c, "ground", "the carpet is still flat ground")
  eq(s.h, 0, "at the datum")
end

io.write("gen1/gen2 untouched\n")
do
  local g1ts = { id = "OVERWORLD", blocks = { { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 } },
                 tilesPerRow = 16, imageWidth = 128, imageHeight = 48,
                 walkable = { 0 }, waterTiles = {}, grassTile = 3 }
  local g1 = Map.new({ id = "PALLET_TOWN", width = 1, height = 1, blocks = { 0 },
                       borderBlock = 0, tileset = "OVERWORLD" }, g1ts)
  g1.id = "PALLET_TOWN"
  local sh = TileShape.forMap(g1)
  ok(sh.gen3 == nil, "a Gen 1 map has no Gen 3 context")
  eq(sh.count, 96, "and its tile-id space is unchanged")
  eq(sh[3].class, "grass", "and its derived pins still fire")
end

io.write(string.format("\n%d passed, %d failed\n", pass, fail))
os.exit(fail == 0 and 0 or 1)
