-- A companion mod's modules are optional. Missing one must not take
-- DRAMATIC_SHAPE down with it.
--
-- The failure this pins: ds_fp_ceiling spliced `V.require("Ceiling")` into
-- main.lua, then uninstalled itself and deleted lib/Ceiling.lua, leaving the
-- splice behind. `V.require` raised, main.lua never finished, and the entire
-- mod refused to load -- over a feature that had removed itself.
package.path = "/tmp/work/?.lua;/tmp/work/?/init.lua;" .. package.path
local MOD = "/tmp/modwork/DRAMATIC_SHAPE/"
_G.love = require("tests.love_stub")
package.loaded["src.core.Logger"] = { info = function() end,
                                      warn = function() end }

-- Extract main.lua's loader block and run it against a fake `mod`, so the
-- test exercises the REAL code without booting the whole mod.
local src = assert(io.open(MOD .. "main.lua")):read("*a")
local block = src:match("(local COMPANION = .-\nend\n)\n%-%- The explicit form")
  or src:match("(local COMPANION = .-\n)%-%- The explicit form")
assert(block, "could not find the companion loader in main.lua")
local optional = src:match("(function V%.optional%(name%).-\nend\n)")
assert(optional, "could not find V.optional in main.lua")

local pass, fail = 0, 0
local function ok(c, w)
  if c then pass = pass + 1 else fail = fail + 1; io.write("  FAIL  ", w, "\n") end
end

local function loader(files)
  local env = setmetatable({}, { __index = _G })
  env.mod = { path = "mods/DRAMATIC_SHAPE",
              read = function(_, rel) return files[rel] end }
  env.V = { mod = env.mod, path = "mods/DRAMATIC_SHAPE" }
  env.chunkFor = function(rel)
    local s = files[rel]
    if not s then error(("DRAMATIC_SHAPE: %s is missing -- reinstall the mod"):format(rel), 0) end
    return assert(load(s, "@" .. rel))
  end
  local chunk = assert(load(block .. "\n" .. optional, "@loader", "t", env))
  chunk()
  return env.V
end

io.write("companion modules are optional\n")

-- 1. every companion absent: the mod must still load, and calls must be safe
do
  local V = loader({})
  local okc, Ceiling = pcall(V.require, "Ceiling")
  ok(okc, "a missing companion does not raise" ..
     (okc and "" or (": " .. tostring(Ceiling))))
  if okc then
    ok(type(Ceiling) == "table", "it resolves to a table")
    local okd = pcall(function() Ceiling.draw({}, function() end) end)
    ok(okd, "and a spliced Ceiling.draw(...) call site is a safe no-op")
    local okf = pcall(function() return Ceiling.anything end)
    ok(okf, "as is reading any field off it")
  end
  for _, n in ipairs({ "Flora", "Backdrop", "SkyLayer", "Jump" }) do
    local o = pcall(V.require, n)
    ok(o, n .. " is optional too")
  end
end

-- 2. a companion that IS present must be used, not stubbed
do
  local V = loader({ ["lib/Ceiling.lua"] = "return { draw = function() return 42 end }" })
  local C = V.require("Ceiling")
  ok(C.draw() == 42, "a companion that is present is loaded normally")
end

-- 3. a companion that is present but BROKEN must not take the mod down
do
  local V = loader({ ["lib/Ceiling.lua"] = "this is not lua" })
  local okc, C = pcall(V.require, "Ceiling")
  ok(okc, "a companion that will not compile does not raise")
  ok(okc and pcall(function() C.draw() end),
     "and still answers a safe no-op")
end
do
  local V = loader({ ["lib/Flora.lua"] = "error('boom')" })
  local okc, F = pcall(V.require, "Flora")
  ok(okc, "a companion that throws while loading does not raise")
  ok(okc and pcall(function() F.draw() end), "and still answers a safe no-op")
end

-- 4. OUR OWN missing module must still be loud -- that is a packaging fault
do
  local V = loader({})
  local okc, err = pcall(V.require, "ChunkMesher")
  ok(not okc, "a missing module of OUR OWN still raises")
  ok(okc == false and tostring(err):find("is missing", 1, true) ~= nil,
     "with the reinstall message")
end

-- 5. V.optional never stubs and never raises
do
  local V = loader({})
  local okc, v = pcall(V.optional, "Nope")
  ok(okc and v == nil, "V.optional answers nil for something absent")
  local V2 = loader({ ["lib/Yes.lua"] = "return { n = 7 }" })
  local ok2, v2 = pcall(V2.optional, "Yes")
  ok(ok2 and v2 and v2.n == 7, "and loads it when it is there")
end

io.write(string.format("\n%d passed, %d failed\n", pass, fail))
os.exit(fail == 0 and 0 or 1)
