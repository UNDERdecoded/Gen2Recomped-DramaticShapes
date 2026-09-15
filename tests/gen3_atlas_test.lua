-- The Gen 3 atlas: does the composite actually contain PIXELS?
--
-- The bug this exists for reported total success -- "composited ... into one
-- 256x560 texture" -- while every surface in the world textured from a black
-- image, because the composite ran through whatever shader the scene had
-- bound. Counting non-transparent pixels is the only check that would have
-- caught it.
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

_G.love = require("tests.love_stub")

-- an ImageData with REAL storage, so the bake can be inspected
local made = {}
love.image = love.image or {}
love.image.newImageData = function(w, h)
  local px = {}
  local o
  o = {
    getWidth = function() return w end,
    getHeight = function() return h end,
    getDimensions = function() return w, h end,
    setPixel = function(_, x, y, r, g, b, a)
      px[y * w + x] = { r, g, b, a }
    end,
    getPixel = function(_, x, y)
      local c = px[y * w + x]
      if not c then return 0, 0, 0, 0 end
      return c[1], c[2], c[3], c[4]
    end,
    release = function() end,
    _px = px, _w = w, _h = h,
  }
  made[#made + 1] = o
  return o
end
love.graphics.newImage = function(d)
  return { __data = d, getWidth = function() return d._w end,
           getHeight = function() return d._h end,
           getDimensions = function() return d._w, d._h end,
           setFilter = function() end, release = function() end }
end
-- if anything reaches for a canvas or a draw during the bake, fail loudly
love.graphics.newCanvas = function() error("the atlas must not use a canvas", 2) end
love.graphics.draw = function() error("the atlas must not draw", 2) end
love.graphics.setCanvas = function() error("the atlas must not bind a canvas", 2) end

local V = {}
local modules, dataFiles = {}, {}
function V.require(n)
  local h = modules[n]; if h ~= nil then return h end
  local v = assert(loadfile(MOD .. "lib/" .. n .. ".lua"))(V); modules[n] = v; return v
end
function V.data(n)
  local h = dataFiles[n]; if h ~= nil then return h end
  local v = assert(loadfile(MOD .. "data/" .. n .. ".lua"))(V); dataFiles[n] = v; return v
end

local pass, fail = 0, 0
local function ok(c, what)
  if c then pass = pass + 1 else fail = fail + 1; io.write("  FAIL  ", what, "\n") end
end
local function eq(a, b, what)
  if a == b then pass = pass + 1 else fail = fail + 1
    io.write("  FAIL  ", what, ": got ", tostring(a), " want ", tostring(b), "\n") end
end

-- ---- a synthetic pair: 4 metatiles, real 4bpp pixels, real palettes -------
local N = 4
local meta, attrs = {}, {}
for m = 0, N - 1 do
  for t = 0, 7 do
    -- The two layers must be DISTINGUISHABLE on the sheet or the test cannot
    -- see the second one land. Bottom layer paints the cell's top row only
    -- (quadrants 0,1); the top layer paints the bottom row (quadrants 6,7)
    -- and only on metatile 1. So metatile 0 ends half covered and metatile 1
    -- fully covered -- and the difference is exactly the layer-2 bake.
    local tile = 0
    if t <= 1 then tile = 1                      -- bottom layer, top row
    elseif m == 1 and t >= 6 then tile = 1 end   -- top layer, bottom row
    local word = tile + 1 * 4096
    meta[#meta + 1] = string.char(word % 256, math.floor(word / 256) % 256)
  end
  -- metatile 1 is layer type 0 (NORMAL) so its top half is above-player art
  local a = 0x00 + 0 * 4096
  attrs[#attrs + 1] = string.char(a % 256, math.floor(a / 256) % 256)
end
-- tile 1 is solid colour index 5 (tile 0 left blank/transparent)
local tilePixels = string.rep("\0", 32) .. string.rep(string.char(0x55), 32)
  .. string.rep("\0", 32 * 510)
local palettes = {}
for p = 1, 16 do
  local row = {}
  for c = 1, 16 do row[c] = { 10 * c, 20, 30 } end
  palettes[p] = row
end
local primary = {
  id = "TS", tiles = tilePixels, metatiles = table.concat(meta),
  attributes = table.concat(attrs), palettes = palettes,
  tileCount = 512, metatileCount = N,
}
_G.Game = { data = { map_tilesets = { TS = primary },
                     constants = { gen3Layout = { tilesInPrimary = 512,
                       metatilesInPrimary = N, palettesInPrimary = 6,
                       metatileLayers = 2 } } } }

local W, H = 2, 2
local grid, coll, elev = { 0, 1, 2, 3 }, { 0, 0, 0, 0 }, { 3, 3, 3, 3 }
local blocks = {}
for i = 1, W * H do
  local word = grid[i] + coll[i] * 1024 + elev[i] * 4096
  blocks[i] = string.char(word % 256, math.floor(word / 256) % 256)
end
local tsDef = { id = "TS_PAIR", primaryKey = "TS", blockTiles = 2,
                blockCells = 1, metatileCount = N, collision = {}, walkable = {} }
local def = { id = "MAP_G00_N09", width = W, height = H,
              blocks = table.concat(blocks), collisionCells = coll,
              elevationCells = elev, borderBlock = 0, tileset = "TS_PAIR" }
local Map = require("src.world.Map")
local map = Map.new(def, tsDef)
map.id = "MAP_G00_N09"

io.write("gen3 atlas\n")

local Gen3 = V.require("Gen3")
local img = Gen3.atlas(map)
ok(img ~= nil, "an atlas is produced")

if img then
  local d = img.__data
  local w, h = d._w, d._h
  ok(w > 0 and h > 0, "with real dimensions (" .. w .. "x" .. h .. ")")

  local drawn, black = 0, 0
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local r, g, b, a = d:getPixel(x, y)
      if a and a > 0 then
        drawn = drawn + 1
        if r == 0 and g == 0 and b == 0 then black = black + 1 end
      end
    end
  end
  -- THE CHECK. A composite that ran through the scene shader reported
  -- success and left every pixel black or absent.
  ok(drawn > 0, "and CONTAINS PIXELS (" .. drawn .. " opaque)")
  ok(black < drawn, "which are not all black (" .. black .. " black of " ..
     drawn .. ")")

  -- metatile 1 is the only one with layer-2 art, so the second bake must
  -- have added pixels the first did not
  -- THE LAYOUT IS LINEAR 8px TILES, not 16px cells. A metatile's four
  -- quadrants are the four consecutive synthetic tile ids 4m..4m+3, each an
  -- ordinary 8x8 tile at `(t % perRow) * 8`. Counting a metatile means
  -- counting its four quadrants -- and asserting that addressing here is what
  -- pins the layout every pass in Structures and Buildings assumes.
  local info = Gen3.atlasInfoFor(map.tileset)
  eq(info.perRow, 16, "the sheet states an 8px tile stride")
  eq(w, info.width, "and the bake is exactly that wide")
  eq(h, info.height, "and exactly that tall")
  eq(map.tileset.tilesPerRow, info.perRow,
     "the tileset record was described, so every reader sees the truth")
  local function opaqueInTile(t)
    local ox = (t % info.perRow) * 8
    local oy = math.floor(t / info.perRow) * 8
    local n = 0
    for y = oy, oy + 7 do
      for x = ox, ox + 7 do
        local _, _, _, a = d:getPixel(x, y)
        if a and a > 0 then n = n + 1 end
      end
    end
    return n
  end
  local function opaqueIn(id)
    local n = 0
    for q = 0, 3 do n = n + opaqueInTile(id * 4 + q) end
    return n
  end
  -- the four quadrants of a cell never straddle a sheet row
  local straddle = false
  for m = 0, info.metatiles - 1 do
    local a = math.floor((m * 4) / info.perRow)
    local b = math.floor((m * 4 + 3) / info.perRow)
    if a ~= b then straddle = true end
  end
  ok(not straddle, "no metatile's quadrants straddle a sheet row")
  local m0, m1 = opaqueIn(0), opaqueIn(1)
  eq(m0, 128, "metatile 0 has its bottom layer only (the cell's top row)")
  eq(m1, 256, "metatile 1 has bottom AND top composited into one cell")
  ok(m1 > m0, "so the second layer demonstrably landed (" .. m1 .. " > " ..
     m0 .. ")")
end

-- and it must be cached, not rebuilt per frame
local again = Gen3.atlas(map)
ok(again == img, "the atlas is cached, not rebuilt every frame")

io.write(string.format("\n%d passed, %d failed\n", pass, fail))
os.exit(fail == 0 and 0 or 1)
