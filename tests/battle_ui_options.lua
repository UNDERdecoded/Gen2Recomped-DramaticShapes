local settings = {}
local V = {
  require = function(name)
    if name == "ModSetting" then
      return { new = function(key, label, values, labels)
        local setting = { key = key, label = label,
                          values = values, labels = labels, index = 1 }
        function setting:get() return self.values[self.index] end
        function setting:setIndex(index) self.index = index end
        settings[key] = setting
        return setting
      end }
    end
    error(name)
  end,
}

local UiBackplates = assert(loadfile("lib/UiBackplates.lua"))(V)
assert(settings.hudColor.values[1] == "INVERTED",
  "HUD COLOR does not default to INVERTED")
assert(table.concat(settings.arenaFill.values, ",") == "OFF,WHITE,PNG",
  "ARENA FILL exposes choices outside this release")
assert(settings.backdropOffset.values[1] == 100,
  "BG Y-OFFSET does not default to 100 PX")
assert(settings.bossBg.values[1] == "OFF",
  "BOSS BG does not default to OFF")
assert(settings.textboxFill.values[1] == "WHITE",
  "TEXTBOX FILL changed its established default")
settings.textboxFill:setIndex(4)
assert(not UiBackplates.textboxUsesFrost(),
  "TEXTBOX FILL: OFF still requests frosted glass")

local function source(path)
  local file = assert(io.open(path, "rb"))
  local body = assert(file:read("*a"))
  file:close()
  return body
end

local main = source("main.lua")
for _, setting in ipairs({ "hudColor", "arenaFill", "backdropOffset",
                           "textboxFill" }) do
  assert(main:find("{ UiBackplates." .. setting .. ",", 1, true),
    setting .. " is missing from the in-game options schema")
end
local boss = assert(main:find("{ UiBackplates.bossBg,", 1, true))
local textbox = assert(main:find("{ UiBackplates.textboxFill,", boss, true))
assert(main:sub(boss, textbox - 1):find("managerOnly = true", 1, true),
  "BOSS BG is not restricted to the mod-specific options page")
assert(not main:find("{ BattleArt.backPlacementSetting,", 1, true),
  "dead BACK PLACEMENT is exposed in the options schema")

local scene = source("lib/BattleScene.lua")
assert(scene:find("Voxel3D.backdrop(artImage", 1, true),
  "PNG arena selection is not connected to the battle scene")
local overworld = source("lib/OverworldBattle.lua")
assert(overworld:find("not UiBackplates.hudUsesColor()", 1, true),
  "HUD COLOR is not connected to staged HUD rendering")
assert(overworld:find("UiBackplates.textboxMode()", 1, true),
  "TEXTBOX FILL is not connected to battle text rendering")
local frostChecks = 0
for _ in overworld:gmatch("UiBackplates%.textboxUsesFrost%(%)") do
  frostChecks = frostChecks + 1
end
assert(frostChecks == 2,
  "TEXTBOX FILL does not govern both snapped and fallback frosted panels")

print("battle UI options regression: ok")
