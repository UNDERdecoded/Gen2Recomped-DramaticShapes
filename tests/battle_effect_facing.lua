package.preload["src.render.PaletteFX"] = function() return {} end
package.preload["src.world.Map"] = function() return {} end

local eye = { 200, 20, 216 }
local billboard = {
  FULL_W = 16,
  FULL_PIC = 56,
  yawToward = function() return math.pi / 2 end,
}
local V = {
  require = function(name)
    if name == "Voxel3D" then return { eye = eye } end
    if name == "BattleBillboard" then return billboard end
    return {}
  end,
}
local Scene = assert(loadfile("lib/BattleScene.lua"))(V)
local anchors = { player = { 27, 96 }, enemy = { 133, 56 } }

local function apply(m, x, y, z)
  return m[1] * x + m[2] * y + m[3] * z + m[4],
         m[5] * x + m[6] * y + m[7] * z + m[8],
         m[9] * x + m[10] * y + m[11] * z + m[12]
end

local arena = { player = { 96, 240 }, enemy = { 96, 192 } }
local model = Scene.fxCard(arena, 10, anchors)
assert(math.abs(model[5]) < 1e-9,
  "camera-facing effect plane shears its horizontal axis")
assert(math.abs(model[3] - 1) < 1e-9 and math.abs(model[11]) < 1e-9,
  "effect plane does not face the camera")

local px, py, pz = apply(model, anchors.player[1] / 160 - 0.5,
  1 - anchors.player[2] / 144, 0)
local ex, ey, ez = apply(model, anchors.enemy[1] / 160 - 0.5,
  1 - anchors.enemy[2] / 144, 0)
assert(math.abs(px - 96) < 1e-3 and math.abs(pz - 240) < 1e-3,
  "player effect column moved off its cell")
assert(math.abs(ex - 96) < 1e-3 and math.abs(ez - 192) < 1e-3,
  "enemy effect column moved off its cell")
assert(math.abs((py - 10) - (10 - ey)) < 1e-3,
  "vertical perspective mismatch is not shared between sides")

local edge = Scene.fxCard(
  { player = { 72, 216 }, enemy = { 120, 216 } }, 10, anchors)
assert(math.abs(edge[5]) < 1e-9 and math.abs(edge[3] - 1) < 1e-9,
  "edge-on fallback is not an upright camera-facing card")

print("battle effect-facing regression: ok")
