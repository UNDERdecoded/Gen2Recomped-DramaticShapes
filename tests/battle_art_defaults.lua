local settings = {}
local V = {
  require = function(name)
    if name == "ModSetting" then
      return { new = function(key, label, values, labels, defaultIndex)
        local setting = { key = key, label = label,
                          values = values, labels = labels,
                          index = defaultIndex or 1 }
        function setting:get() return self.values[self.index] end
        function setting:setIndex(index) self.index = index end
        settings[key] = setting
        return setting
      end }
    end
    error(name)
  end,
  data = function() return {} end,
}

local BattleArt = assert(loadfile("lib/BattleArt.lua"))(V)
assert(settings.battleArt.values[1] == "animated"
  and settings.battleArt.labels[1] == "ANIMATED",
  "fresh installs do not default Battle Art to animated")
assert(settings.battleArt.values[2] == "static"
  and settings.battleArt.values[3] == "rom",
  "Battle Art retained an unexpected mode ladder")
assert(settings.trainerArtSet.values[1] == "rom"
  and settings.trainerArtSet.labels[1] == "ROM",
  "fresh installs do not default opponent trainer art to ROM")
assert(BattleArt.playerArtSetting:get() == "gen2",
  "fresh installs do not default static player art to Gen 2")
assert(BattleArt.playerAnimationSetting:get() == "gen2",
  "fresh installs do not default animated player art to Gen 2")

assert(not BattleArt.mirrorsPlayerSprite(),
  "default selected back sprites are incorrectly mirrored")
settings.playerView:setIndex(1)
assert(BattleArt.mirrorsPlayerSprite(),
  "Battle Art front sprites no longer mirror toward the opponent")
settings.frontFlip:setIndex(2)
assert(not BattleArt.mirrorsPlayerSprite(),
  "DEFAULT front orientation is not preserved")

print("battle-art defaults regression: ok")
