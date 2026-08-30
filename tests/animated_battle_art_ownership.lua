local atlas = {
  image = "test-atlas.png",
  autoColumns = 2,
  durations = { 50, 50 },
}
local frames = {}

local function setting(value)
  return { get = function() return value end }
end

local BattleArt = {
  setting = setting("animated"),
  frontAnimationSetting = setting("gen2"),
  backAnimationSetting = setting("gen2"),
  playerAnimationSetting = setting("rom"),
  ownsSpeciesArt = function() return true end,
  ownsShinyArt = function() return false end,
  speciesFor = function(battler) return battler.mon.species end,
  speciesAlias = function(species) return species end,
  isShiny = function() return false end,
  displayMode = function() return "color" end,
  releaseSpeciesOverrides = function() end,
  applyTrainers = function() end,
  playerSide = function() return "back" end,
  prepareData = function()
    local frame = { index = #frames + 1 }
    frames[#frames + 1] = frame
    return frame
  end,
}

love = {
  image = {
    newImageData = function(width)
      if type(width) == "string" then
        return { getDimensions = function() return 2, 1 end }
      end
      return { paste = function() end }
    end,
  },
}

local V = {
  require = function(name)
    assert(name == "BattleArt")
    return BattleArt
  end,
  data = function(name)
    if name == "animated_battle_sprites_gen2" then
      return { SPECIES_TEST = { front = atlas } }
    end
    return {}
  end,
  mod = { assets = { path = function(_, path) return path end } },
}

local AnimatedBattleArt = assert(loadfile("lib/AnimatedBattleArt.lua"))(V)
local rom, foreign, nativePicAnim = {}, {}, {}
local enemy = {
  mon = { species = "SPECIES_TEST" },
  sprite = rom,
  picAnim = nativePicAnim,
}
local battle = { enemy = enemy }

AnimatedBattleArt.update(battle, 0)
assert(enemy.sprite == frames[1], "Battle Art did not claim the first frame")
assert(AnimatedBattleArt.ownsFrame(enemy) == true,
  "claimed frame was not reported as owned")
assert(enemy.picAnim == nil,
  "native Crystal pic animation remained active under replacement art")

enemy.sprite = foreign
enemy.picAnim = nativePicAnim
assert(AnimatedBattleArt.reassert(enemy),
  "capture-time ownership could not reclaim a managed battler")
assert(enemy.sprite == frames[1],
  "capture-time ownership did not restore the selected frame")
assert(enemy.picAnim == nil,
  "capture-time ownership did not suppress the native animation sheet")

for tick = 1, 180 do
  enemy.sprite = foreign
  assert(AnimatedBattleArt.ownsFrame(enemy) == false,
    "foreign refresh was not visible to the ownership audit")
  AnimatedBattleArt.update(battle, 1 / 60)
  assert(AnimatedBattleArt.ownsFrame(enemy) == true,
    "a foreign sprite refresh reset animation ownership at tick " .. tick)
end

AnimatedBattleArt.finish(battle)
assert(enemy.sprite == rom, "finishing did not restore the original sprite")
assert(enemy.picAnim == nativePicAnim,
  "finishing did not restore the native Crystal pic animation")
assert(AnimatedBattleArt.ownsFrame(enemy) == nil,
  "finished battler remained managed")

print("animated battle-art ownership regression: ok")
