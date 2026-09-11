local captured
local setting = { get = function() return "battle_art" end }
local V = {
  require = function(name)
    if name == "ModSetting" then
      return { new = function(key, label, values, labels)
        captured = { key = key, label = label,
                     values = values, labels = labels }
        return setting
      end }
    elseif name == "BattleArt" then
      return { setting = { get = function() return "rom" end } }
    elseif name == "AnimatedBattleArt" then
      return {}
    end
    error(name)
  end,
}

assert(loadfile("lib/InterfaceSprites.lua"))(V)
assert(captured.values[1] == "battle_art"
  and captured.labels[1] == "BATTLE ART",
  "fresh installs do not default interface sprites to Battle Art")

local file = assert(io.open("main.lua", "rb"))
local main = assert(file:read("*a"))
file:close()
local first = assert(main:find("{ InterfaceSprites.setting,", 1, true))
local last = assert(main:find("{ WorldUnderlay.setting,", first, true))
assert(main:sub(first, last - 1):find("full = true", 1, true),
  "INTERFACE SPRITES is hidden by VOXEL: FULL")

print("interface-sprite defaults regression: ok")
