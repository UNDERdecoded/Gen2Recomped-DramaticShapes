-- SpriteBillboards: the frame box a card is cut from.
package.path = "/tmp/work/?.lua;/tmp/work/?/init.lua;" .. package.path
local MOD = "/tmp/modwork/DRAMATIC_SHAPE/"
_G.love = require("tests.love_stub")

-- capture what geometry the card builder produces
local captured
love.graphics.newMesh = function(fmt, verts) captured = verts; return { release = function() end } end

local V = {}
local modules = {}
function V.require(name)
  local hit = modules[name]; if hit ~= nil then return hit end
  local v = assert(loadfile(MOD .. "lib/" .. name .. ".lua"))(V); modules[name] = v; return v
end
function V.data(name) return assert(loadfile(MOD .. "data/" .. name .. ".lua"))(V) end

local sheets = {}
package.loaded["src.render.Assets"] = {
  image = function(path) return sheets[path] end,
  register = function() end,
}
local function sheet(w, h)
  return { getDimensions = function() return w, h end }
end

local pass, fail = 0, 0
local function eq(a, b, what)
  if math.abs(a - b) < 1e-6 then pass = pass + 1
  else fail = fail + 1
    io.write("  FAIL  ", what, ": got ", tostring(a), ", want ", tostring(b), "\n") end
end
local function ok(c, what)
  if c then pass = pass + 1 else fail = fail + 1; io.write("  FAIL  ", what, "\n") end
end

local SB = V.require("SpriteBillboards")

-- geometry of the card: verts are {x,y,z,u,v,shade}; [1] is bottom-left,
-- [3] is top-right.  Width/height in world px, and the v range says which
-- frame of the sheet it cut.
local function card(def, frame)
  SB.invalidate()
  captured = nil
  SB.mesh(def, frame)
  return captured
end

io.write("gen3 sheets state their frame box\n")

-- the player: 16x32 frames, six of them, on a 16x192 sheet
sheets["p.png"] = sheet(16, 192)
local player = { id = "SPRITE_G3_000", image = "p.png", frames = 6,
                 frameWidth = 16, frameHeight = 32, walker = true }
do
  local c = card(player, 0)
  ok(c ~= nil, "a card is built")
  eq(c[2][1], 16, "the card is 16 world px wide")
  eq(c[3][2], 32, "and 32 tall -- not 16, which cropped it to the hair")
  eq(c[1][5] * 192, 32 - 0.05, "frame 0 bottom edge is 32px down the sheet")
  eq(c[3][5] * 192, 0.05, "frame 0 top edge is the top of the sheet")
end
do
  -- frame 3 is WALK SOUTH.  At 16px rows it landed at y=48, halfway into
  -- frame 1 -- two half sprites at once, facing nowhere.
  local c = card(player, 3)
  eq(c[3][5] * 192, 3 * 32 + 0.05, "frame 3 starts at y=96, not y=48")
  eq(c[1][5] * 192, 4 * 32 - 0.05, "and ends at y=128")
end
eq(SB.halfWidth(player), 8, "a 16-wide sprite is centred on 8")

-- a 32x32 walker in the same cast
sheets["b.png"] = sheet(32, 192)
local big = { id = "SPRITE_G3_004", image = "b.png", frames = 6,
              frameWidth = 32, frameHeight = 32, walker = true }
do
  local c = card(big, 2)
  eq(c[2][1], 32, "a 32-wide sprite gets a 32-wide card")
  eq(c[3][2], 32, "32 tall")
  eq(c[3][5] * 192, 2 * 32 + 0.05, "and still cuts the frame it was asked for")
end
eq(SB.halfWidth(big), 16, "and is centred on 16, not on 8")

-- a 16x16 Gen 3 sprite (there are some)
sheets["s.png"] = sheet(16, 96)
local small = { id = "SPRITE_G3_005", image = "s.png", frames = 6,
                frameWidth = 16, frameHeight = 16, walker = true }
do
  local c = card(small, 4)
  eq(c[3][2], 16, "a 16x16 Gen 3 sprite stays 16 tall")
  eq(c[3][5] * 96, 4 * 16 + 0.05, "cutting frame 4")
end

io.write("gen1/gen2 unchanged\n")

-- a Gen 1 walker states no frame box: 16-wide sheet, 16px rows
sheets["g1.png"] = sheet(16, 96)
local g1 = { id = "SPRITE_RED", image = "g1.png", frames = 6, walker = true }
do
  local c = card(g1, 3)
  eq(c[2][1], 16, "Gen 1 card is 16 wide")
  eq(c[3][2], 16, "and 16 tall, exactly as before")
  eq(c[3][5] * 96, 3 * 16 + 0.05, "cutting frame 3 at 16px rows")
end
eq(SB.halfWidth(g1), 8, "and is centred on 8")

-- the Gen 2 big doll: 32x32, marked big, one frame
sheets["snorlax.png"] = sheet(32, 32)
local snor = { id = "SPRITE_BIG_SNORLAX", image = "snorlax.png", frames = 1 }
do
  local c = card(snor, 0)
  eq(c[2][1], 32, "Snorlax keeps its 32x32 card")
  eq(c[3][2], 32, "full body, not a quarter of it")
end
eq(SB.halfWidth(snor), 16, "centred on 16")

-- the 16-wide mirrored strip stays on its own path (two quads, 32 wide)
sheets["doll.png"] = sheet(16, 32)
local doll = { id = "SPRITE_BIG_DOLL", image = "doll.png", frames = 1 }
do
  local c = card(doll, 0)
  ok(#c == 8, "the mirrored 16x32 strip still builds two quads")
  eq(c[6][1], 32, "spanning 32 world px")
end

io.write(string.format("\n%d passed, %d failed\n", pass, fail))
os.exit(fail == 0 and 0 or 1)
