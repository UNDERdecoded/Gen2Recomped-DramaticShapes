local engine = "0.7.5"
package.preload["src.core.Version"] = function()
  return { engine = engine }
end

local draws, made = {}, 0
local current
love = {
  getVersion = function() return 12, 0, 0 end,
  system = { getOS = function() return "iOS" end },
  graphics = {
    getCanvas = function() return current end,
    setCanvas = function(c) current = c end,
    getBlendMode = function() return "alpha", "alphamultiply" end,
    setBlendMode = function() end,
    setShader = function() end,
    setColor = function() end,
    clear = function() end,
    draw = function(...)
      draws[#draws + 1] = { ... }
    end,
  },
}

local function canvas(w, h)
  return {
    getDimensions = function() return w, h end,
    setFilter = function() end,
    release = function() end,
  }
end

local V = {
  require = function(name)
    assert(name == "PixelCanvas")
    return { new = function(w, h)
      made = made + 1
      return true, canvas(w, h)
    end }
  end,
}

local Orientation = assert(loadfile("lib/WorldCanvasOrientation.lua"))(V)
assert(Orientation.needsFlip(), "old iOS/Metal engine was not detected")

local source = canvas(320, 640)
local out = Orientation.present(source, "world")
assert(out ~= source and made == 1, "old iOS frame was not copied")
local d = draws[#draws]
assert(d[1] == source and d[2] == 0 and d[3] == 640
       and d[5] == 1 and d[6] == -1,
  "compatibility copy did not invert the Canvas exactly once")

engine = "0.7.6"
package.loaded["src.core.Version"] = nil
assert(not Orientation.needsFlip(), "fixed engine would be double-flipped")
assert(Orientation.present(source, "world") == source,
  "fixed engine did not receive the original Canvas")

engine = "0.7.5"
package.loaded["src.core.Version"] = nil
love.system.getOS = function() return "Android" end
assert(not Orientation.needsFlip(), "Android was mistaken for Metal/iOS")

love.system.getOS = function() return "iOS" end
love.getVersion = function() return 11, 5, 0 end
assert(not Orientation.needsFlip(), "LÖVE 11 iOS was incorrectly flipped")

print("world canvas orientation regression: ok")
