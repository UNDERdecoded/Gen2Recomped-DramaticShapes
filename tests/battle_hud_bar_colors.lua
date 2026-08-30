local function source(path)
  local file = assert(io.open(path, "rb"))
  local body = assert(file:read("*a"))
  file:close()
  return body
end

local hud = source("lib/BattleHud.lua")
assert(not hud:find("withBrightExpBar", 1, true),
  "detached HUD still replaces Gen2's native blue EXP palette")
assert(hud:find("p.rgb *= p.a / hi", 1, true),
  "detached HUD no longer lifts colored bar fills to full brightness")
for _, region in ipairs({ "enemyHP", "playerHP", "playerExp" }) do
  assert(hud:find(region, 1, true),
    region .. " is missing from the final bar-color pass")
end

local overworld = source("lib/OverworldBattle.lua")
assert(not overworld:find("withBrightExpBar", 1, true),
  "HUD capture still substitutes the EXP palette")

print("battle HUD bar-color regression: ok")
