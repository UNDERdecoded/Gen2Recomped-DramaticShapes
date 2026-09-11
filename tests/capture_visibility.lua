local Visibility = assert(loadfile("lib/BattleVisibility.lua"))()
local enemy = { sprite = {} }
local battle = { enemy = enemy, fxHidden = function() return false end }

assert(Visibility.sideVisible(battle, "enemy"),
  "ordinary enemy lost its billboard")
battle.picFx = { [enemy] = { hidden = true } }
assert(not Visibility.sideVisible(battle, "enemy"),
  "Gen 2's return-to-ball effect kept the enemy billboard")
battle.picFx[enemy].hidden = nil
battle.lockedBall = {}
assert(not Visibility.sideVisible(battle, "enemy"),
  "successful capture reappeared beside its resting ball")
battle.lockedBall = nil
assert(Visibility.sideVisible(battle, "enemy"),
  "breakout did not restore the enemy billboard")

-- Gen2recomp clears the animation/ball drawing before the caught dialogue is
-- finished. Its native pics layer keeps the enemy absent with picHidden; the
-- staged billboard must read the same persistent latch.
battle.picHidden = { enemy = true, player = false }
assert(not Visibility.sideVisible(battle, "enemy"),
  "caught enemy reappeared after the Gen 2 ball stopped rendering")
battle.picHidden.enemy = false
battle.battle = { over = true, outcome = "caught" }
assert(not Visibility.sideVisible(battle, "enemy"),
  "caught enemy ignored the Gen 2 model's settled outcome")
battle.battle = nil
assert(Visibility.sideVisible(battle, "enemy"),
  "ordinary enemy stayed hidden after catch state cleared")

-- The Gen 2 screen has no Gen 1 fxHidden method. Absence is a normal host
-- difference, not a reason to reject an otherwise-visible billboard.
battle.fxHidden = nil
assert(Visibility.sideVisible(battle, "enemy"),
  "Gen 2 battle without fxHidden lost the enemy billboard")

battle.introBalls = true
assert(not Visibility.animationLayerVisible(battle),
  "the intro's engine animation layer can duplicate the ROM monster")
battle.introBalls = nil
assert(Visibility.animationLayerVisible(battle),
  "battle animations stayed hidden after the intro message")

print("capture visibility regression: ok")
