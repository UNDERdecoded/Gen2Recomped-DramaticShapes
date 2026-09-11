local V = {
  require = function(name)
    if name == "ModSetting" then
      return { new = function(_, _, values)
        local setting = { values = values, index = 1 }
        function setting:get() return self.values[self.index] end
        return setting
      end }
    end
    error(name)
  end,
  data = function() return {} end,
}

local function imageData()
  local pixels = {}
  for y = 0, 4 do
    for x = 0, 4 do pixels[y * 5 + x] = { 0, 0, 0, 0 } end
  end
  for x = 1, 3 do
    pixels[1 * 5 + x] = { 0.2, 0.6, 0.2, 1 }
    pixels[3 * 5 + x] = { 0.2, 0.6, 0.2, 1 }
  end
  pixels[2 * 5 + 1] = { 0.2, 0.6, 0.2, 1 }
  pixels[2 * 5 + 3] = { 0.2, 0.6, 0.2, 1 }
  return {
    getDimensions = function() return 5, 5 end,
    getPixel = function(_, x, y)
      return table.unpack(pixels[y * 5 + x])
    end,
    setPixel = function(_, x, y, r, g, b, a)
      pixels[y * 5 + x] = { r, g, b, a }
    end,
  }
end

love = {
  graphics = {
    newImage = function(data)
      return { data = data, setFilter = function() end }
    end,
  },
}

local BattleArt = assert(loadfile("lib/BattleArt.lua"))(V)
for _, kind in ipairs({ "static PNG", "animated atlas frame" }) do
  local data = imageData()
  local image = assert(BattleArt.prepareData(data, "redpp"))
  local _, _, _, alpha = data:getPixel(2, 2)
  assert(alpha == 0, kind .. " enclosed void was painted white")
  assert(BattleArt.isExternal(image), kind .. " lost its authored-art identity")
end

print("authored sprite transparency regression: ok")
