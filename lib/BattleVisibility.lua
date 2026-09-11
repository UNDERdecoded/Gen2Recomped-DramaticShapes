local BattleVisibility = {}

local function picHidden(battle, side, battler)
  -- Gen2recomp's battle screen owns a persistent per-side latch. A successful
  -- catch sets picHidden.enemy before the throw animation starts and leaves it
  -- set after the ball runner and its sprites are gone. This is the durable
  -- state the native pics layer uses; lockedBall below is only the temporary
  -- resting-ball drawing and cannot represent the rest of the catch dialogue.
  if battle.picHidden and battle.picHidden[side] then return true end
  local pf = battle.picFx and battle.picFx[battler]
  return pf and pf.hidden or false
end

local function fxHidden(battle, battler)
  if type(battle.fxHidden) ~= "function" then return false end
  local ok, hidden = pcall(battle.fxHidden, battle, battler)
  return ok and hidden or false
end

local function caughtOutcome(battle)
  local model = battle.battle
  return model and model.over == true and model.outcome == "caught"
end

function BattleVisibility.sideVisible(battle, side)
  if side == "enemy" then
    if battle.showEnemyTrainer and battle.trainerPic then return true end
    return (battle.enemy and battle.enemy.sprite and not battle.enemyHidden
            and not battle.enemySendingOut and not battle.lockedBall
            and not caughtOutcome(battle)
            and not picHidden(battle, "enemy", battle.enemy)
            and not fxHidden(battle, battle.enemy)) and true or false
  end
  if battle.showPlayerBack and battle.playerBackPic then return true end
  local hide = battle.safari or battle.demo
  return (battle.player and battle.player.sprite and not hide
          and not battle.sendingOut
          and not picHidden(battle, "player", battle.player)
          and not fxHidden(battle, battle.player)) and true or false
end

function BattleVisibility.animationLayerVisible(battle)
  return not (battle and battle.introBalls)
end

return BattleVisibility
