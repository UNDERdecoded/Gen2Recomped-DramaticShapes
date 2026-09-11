local function source(path)
  local file = assert(io.open(path, "rb"))
  local body = assert(file:read("*a"))
  file:close()
  return body
end

local interface = source("lib/InterfaceSprites.lua")
assert(interface:find("function InterfaceSprites.installDexList()", 1, true),
  "Pokedex list ROM rendering is not adapted")
assert(not interface:find("dexListStates", 1, true)
  and not interface:find("advance(dexList", 1, true),
  "Pokedex list resumed animated playback")
local listDraw = assert(interface:find("function InterfaceSprites.installDexList()", 1, true))
local entryDraw = assert(interface:find("function InterfaceSprites.installDex()", listDraw, true))
local listBlock = interface:sub(listDraw, entryDraw - 1)
assert(listBlock:find('love.graphics.setColor(1, 1, 1, 1)', 1, true)
  and listBlock:find('love.graphics.rectangle("fill", 6, 6, 58, 60)', 1, true),
  "Pokedex list preview does not restore its white paper backdrop")
local fill = assert(listBlock:find(
  'love.graphics.rectangle("fill", 6, 6, 58, 60)', 1, true))
local previewGuard = assert(listBlock:find("if preview then", 1, true))
assert(fill < previewGuard,
  "Pokedex list preview turns black on an empty entry")
assert(listBlock:find(
  'love.graphics.rectangle("fill", 64, 5, 1, 126)', 1, true),
  "Pokedex left panels are missing their shared white divider")
assert(interface:find("InterfaceSprites.installDex()", 1, true),
  "selected Pokedex entry page lost its animated playback")
assert(interface:find("function InterfaceSprites.installDex()", 1, true),
  "selected Pokedex entry animation implementation was removed")

local V = {
  require = function(name)
    if name == "ModSetting" then
      return { new = function()
        return { get = function() return "battle_art" end }
      end }
    elseif name == "BattleArt" or name == "AnimatedBattleArt" then
      return {}
    end
    error(name)
  end,
}
local pixels = {}
for y = 0, 4 do
  for x = 0, 4 do pixels[y * 5 + x] = { 0, 0, 0, 0 } end
end
pixels[1 * 5 + 1] = { 0, 0, 0, 1 }
pixels[1 * 5 + 2] = { 1, 1, 1, 1 }
pixels[2 * 5 + 1] = { 0.5, 0.5, 0.5, 1 }
local data = {
  getDimensions = function() return 5, 5 end,
  mapPixel = function(_, fn)
    for y = 0, 4 do for x = 0, 4 do
      pixels[y * 5 + x] = { fn(x, y, table.unpack(pixels[y * 5 + x])) }
    end end
  end,
}
love = { graphics = { newImage = function()
  return { setFilter = function() end }
end } }
local InterfaceSprites = assert(loadfile("lib/InterfaceSprites.lua"))(V)
local preview = assert(InterfaceSprites.prepareDexListData(data))
assert(pixels[1 * 5 + 2][4] == 0,
  "Pokedex list retained opaque white ROM fill")
assert(preview.x == 35 and preview.y == 34
  and preview.x % 1 == 0 and preview.y % 1 == 0,
  "Pokedex list visible bounds are not integer-centered")

print("interface Pokedex static-list regression: ok")
