-- Optional Stadium 2 model adapter for Battle Art's staged voxel arena.
-- Battle Art retains the camera, terrain, HUD, animation projection and
-- battle lifecycle; the optional importer owns only its model instances.

local V = ...

local Mat4 = V.require("Mat4")
local BattleArt = V.require("BattleArt")

local StadiumModels = {}

local providerHandle, providerExports, models
local actors = { player = {}, enemy = {} }
local warned = {}

local function warnOnce(key, message)
  if warned[key] then return end
  warned[key] = true
  local log = V.mod and V.mod.log
  if log and log.warn then pcall(log.warn, log, "%s", tostring(message)) end
end

local function findMod(id)
  local finder = V.mod and V.mod.find
  if type(finder) ~= "function" then return nil end
  local ok, handle = pcall(finder, id)
  if ok and handle then return handle end
  ok, handle = pcall(finder, V.mod, id)
  return ok and handle or nil
end

local function connect()
  if models and type(models.newInstance) == "function" then
    return models, providerExports
  end
  local handle = findMod("STADIUM2_IMPORTER")
  local exports = handle and handle.exports or nil
  local candidate = type(exports) == "table" and exports.models or nil
  if type(candidate) ~= "table" or (tonumber(candidate.apiVersion) or 0) < 2
      or type(candidate.newInstance) ~= "function" then
    return nil
  end
  providerHandle, providerExports, models = handle, exports, candidate
  return models, providerExports
end

function StadiumModels.installed()
  return connect() ~= nil
end

local function exportEnabled(exports, name)
  local fn = exports and exports[name]
  if type(fn) ~= "function" then return nil end
  local ok, enabled = pcall(fn)
  if not ok then ok, enabled = pcall(fn, exports) end
  if ok then return enabled end
  return nil
end

function StadiumModels.active()
  local api, exports = connect()
  if not api then return false end
  -- The importer toggles are the single source of truth for Pokemon art in a
  -- staged voxel battle. Both ON selects its scene-neutral model instances;
  -- either OFF releases them and leaves Battle Art's sprite cards in place.
  if exportEnabled(exports, "modelsEnabled") ~= true then return false end
  if exportEnabled(exports, "battleEnabled") ~= true then return false end
  return true
end

local function releaseActor(actor)
  if actor.instance and type(actor.instance.release) == "function" then
    pcall(actor.instance.release, actor.instance)
  end
  for key in pairs(actor) do actor[key] = nil end
end

local function failActor(actor)
  local battler, dex, variant = actor.battler, actor.dex, actor.variant
  releaseActor(actor)
  actor.failedBattler, actor.failedDex, actor.failedVariant =
    battler, dex, variant
end

function StadiumModels.release()
  releaseActor(actors.player)
  releaseActor(actors.enemy)
  StadiumModels.animWasPlaying = false
end

local function dexFor(battle, battler)
  local species = BattleArt.speciesFor(battler)
  if type(species) == "number" then
    local dex = math.floor(species)
    return dex >= 1 and dex <= 251 and dex or nil
  end
  local pokemon = battle and battle.data and battle.data.pokemon
  local def = type(pokemon) == "table" and pokemon[species] or nil
  local dex = def and tonumber(def.dex or def.index)
  dex = dex and math.floor(dex) or nil
  return dex and dex >= 1 and dex <= 251 and dex or nil
end

local function safeCall(object, name, ...)
  local fn = object and object[name]
  if type(fn) ~= "function" then return nil end
  local ok, value, extra = pcall(fn, object, ...)
  if not ok then return nil, value end
  return value, extra
end

local function playIdle(actor)
  if not actor.instance then return false end
  local ok = safeCall(actor.instance, "playContext", "idle", true)
  actor.context = ok and "idle" or actor.context
  return ok and true or false
end

local function playContext(actor, context, loop)
  if not actor.instance then return false end
  local ok = safeCall(actor.instance, "playContext", context, loop)
  if not ok and context == "attack" then
    ok = safeCall(actor.instance, "playContext", "attack_default", loop)
  end
  if not ok and context ~= "idle" then return playIdle(actor) end
  if ok then actor.context = context end
  return ok and true or false
end

local function syncSide(battle, side)
  local actor = actors[side]
  local battler = battle and battle[side]
  local dex = dexFor(battle, battler)
  local variant = BattleArt.isShiny(battler) and "shiny" or "normal"
  if actor.instance and actor.battler == battler and actor.dex == dex
      and actor.variant == variant then return actor end
  if actor.failedBattler == battler and actor.failedDex == dex
      and actor.failedVariant == variant then return actor end

  releaseActor(actor)
  actor.battler, actor.dex, actor.variant = battler, dex, variant
  if not (battler and dex) then return actor end

  local api = connect()
  if not api then return actor end
  local called, instance, err = pcall(api.newInstance, dex, variant, {
    textureFilter = "nearest",
    anisotropy = 4,
    flipY = false,
    anchorTravel = true,
  })
  if not called then err, instance = instance, nil end
  if type(instance) ~= "table" then
    actor.failedBattler, actor.failedDex, actor.failedVariant =
      battler, dex, variant
    warnOnce(("load:%s:%d:%s"):format(side, dex, variant),
      ("Stadium 2 %s model %03d (%s) unavailable: %s; using Battle Art")
        :format(side, dex, variant, tostring(err)))
    return actor
  end

  actor.instance = instance
  actor.callbackFrame = side == "enemy" and 4 or 0
  actor.context = "idle"
  actor.lastGrow, actor.lastFainted, actor.lastPicKind = false, false, nil
  playIdle(actor)
  return actor
end

function StadiumModels.sync(battle)
  if not StadiumModels.active() then
    StadiumModels.release()
    return false
  end
  syncSide(battle, "player")
  syncSide(battle, "enemy")
  return true
end

local function updatePresentation(battle, side, actor)
  if not actor.instance then return end
  local battler = battle and battle[side]
  local grow = battler and safeCall(battle, "growInScale", battler) or nil
  if grow and not actor.lastGrow then playContext(actor, "entrance", false) end
  actor.lastGrow = grow and true or false

  local fainted = battler and battler.fainted and true or false
  local faintFx = battler and safeCall(battle, "fxFaintActive", battler) or false
  if (faintFx or fainted) and not actor.lastFainted then
    playContext(actor, "faint", false)
  end
  actor.lastFainted = fainted or faintFx or false

  local picFx = battler and battle.picFx and battle.picFx[battler] or nil
  local kind = picFx and picFx.kind or nil
  if kind == "blink" and actor.lastPicKind ~= "blink" then actor.flash = 0.12 end
  actor.lastPicKind = kind
end

function StadiumModels.update(battle, dt)
  if not StadiumModels.sync(battle) then return false end

  for _, side in ipairs({ "player", "enemy" }) do
    updatePresentation(battle, side, actors[side])
  end

  local playing = battle and battle.animPlaying and true or false
  if playing and not StadiumModels.animWasPlaying then
    local def = battle.data and battle.data.moves and battle.data.moves[battle.animName]
    local side = battle.animAttackerIsPlayer and "player" or "enemy"
    local actor = actors[side]
    local move = def and tonumber(def.index or def.number)
    local ok = actor.instance and move
      and safeCall(actor.instance, "playMove", move, false)
    if actor.instance and not ok then playContext(actor, "attack", false) end
    if ok then actor.context = "attack" end
  end
  StadiumModels.animWasPlaying = playing

  dt = math.max(0, tonumber(dt) or 0)
  for _, side in ipairs({ "player", "enemy" }) do
    local actor = actors[side]
    if actor.instance then
      actor.flash = math.max(0, (actor.flash or 0) - dt)
      actor.callbackFrame = (actor.callbackFrame or 0) + dt * 30
      local updated, err = safeCall(actor.instance, "update", dt, {
        callbackFrame = math.floor(actor.callbackFrame),
        species = actor.dex,
        dynamicObjectEnabled = true,
        dynamicObjectUpdateEnabled = true,
      })
      if updated == nil and err then
        warnOnce("update:" .. side,
          ("Stadium 2 %s model update failed: %s; using Battle Art")
            :format(side, tostring(err)))
        failActor(actor)
      elseif safeCall(actor.instance, "isFinished")
          and actor.context ~= "idle" and actor.context ~= "faint" then
        playIdle(actor)
      end
    end
  end
  return true
end

local function atan2(y, x)
  if math.atan2 then return math.atan2(y, x) end
  if x > 0 then return math.atan(y / x) end
  if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
  if y > 0 then return math.pi / 2 end
  if y < 0 then return -math.pi / 2 end
  return 0
end

local function modelMatrix(arena, groundY, battle, side, actor)
  local point = arena and arena[side]
  local target = arena and arena[side == "player" and "enemy" or "player"]
  if not (point and target and actor.instance) then return nil end
  local metrics = safeCall(actor.instance, "metrics")
  if not (metrics and tonumber(metrics.height) and metrics.height > 0) then
    return nil
  end

  local worldHeight = math.max(5, math.min(18,
    14 * math.sqrt(metrics.height / 52.25)))
  local battler = battle and battle[side]
  local grow = battler and safeCall(battle, "growInScale", battler) or 1
  grow = tonumber(grow) or 1
  local k = worldHeight / metrics.height * math.max(0, math.min(1, grow))
  local floor = tonumber(metrics.floor) or 0
  local hover = math.min(math.max(floor, 0), metrics.height * 0.5)
  local yaw = atan2(target[1] - point[1], target[2] - point[2])
  return Mat4.mul(Mat4.translate(point[1], groundY, point[2]),
    Mat4.mul(Mat4.rotateY(yaw),
      Mat4.mul(Mat4.scale(k, k, k), Mat4.translate(0, -(floor - hover), 0))))
end

-- Return only sides that can replace a Pokemon card this frame. Trainer
-- portraits and host-hidden sides remain on Battle Art's established path.
function StadiumModels.placements(arena, groundY, textures, battle)
  if not StadiumModels.sync(battle) then return {} end
  local out = {}
  for _, side in ipairs({ "enemy", "player" }) do
    local texture = textures and textures[side]
    local actor = actors[side]
    if texture and not texture.trainer and actor.instance then
      local matrix = modelMatrix(arena, groundY, battle, side, actor)
      if matrix then
        out[side] = { side = side, actor = actor, instance = actor.instance,
                      modelMatrix = matrix }
      end
    end
  end
  return out
end

function StadiumModels.draw(placement, context, pass)
  if not (placement and placement.instance and context) then return false end
  local actor = placement.actor
  local tint = context.tint or { 1, 1, 1 }
  local shadow
  if context.shadowMap and context.shadowVP then
    shadow = {
      map = context.shadowMap,
      viewProjection = context.shadowVP,
      darkness = context.shadowDark,
      bias = context.shadowBias,
      texel = context.shadowTexel,
    }
  end
  local called, ok, err = pcall(placement.instance.draw, placement.instance, {
    pass = pass,
    modelMatrix = placement.modelMatrix,
    camera = { view = context.view, viewProjection = context.viewProjection },
    light = context.light,
    shadow = shadow,
    tint = { tint[1] or 1, tint[2] or 1, tint[3] or 1, tint[4] or 1 },
    flashAmount = (context.flashing or (actor.flash or 0) > 0) and 0.5 or 0,
    flipWinding = true,
    disableCulling = true,
    skipHandlers = pass == "additive",
  })
  if not called then err, ok = ok, false end
  if not ok then
    warnOnce("draw:" .. placement.side,
      ("Stadium 2 %s model draw failed: %s; using Battle Art")
        :format(placement.side, tostring(err)))
    failActor(actor)
  end
  return ok and true or false
end

-- Battle Art's caster matrix already maps depth to [0,1]; the Stadium API
-- accepts ordinary GL clip z, so undo that conversion at the boundary.
local FROM_UNIT_Z = { 1,0,0,0, 0,1,0,0, 0,0,2,-1, 0,0,0,1 }

function StadiumModels.drawShadow(placement, lightClipVP)
  if not (placement and placement.instance and lightClipVP) then return false end
  local called, ok, err = pcall(placement.instance.drawShadow,
    placement.instance, {
      modelMatrix = placement.modelMatrix,
      lightViewProjection = Mat4.mul(FROM_UNIT_Z, lightClipVP),
    })
  if not called then err, ok = ok, false end
  if not ok then
    warnOnce("shadow:" .. placement.side,
      ("Stadium 2 %s model shadow failed: %s; using card shadow")
        :format(placement.side, tostring(err)))
  end
  return ok and true or false
end

function StadiumModels.uses(placements, side)
  return type(placements) == "table" and placements[side] ~= nil
end

function StadiumModels.status()
  return {
    apiVersion = 1,
    installed = StadiumModels.installed(),
    active = StadiumModels.active(),
    providerId = providerHandle and "STADIUM2_IMPORTER" or nil,
    sides = {
      player = actors.player.instance and true or false,
      enemy = actors.enemy.instance and true or false,
    },
  }
end

return StadiumModels
