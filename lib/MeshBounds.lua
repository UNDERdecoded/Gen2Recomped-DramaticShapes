-- Voxel world mode: WHERE a mesh is, so a pass can decline to draw it.
--
-- Every terrain mesh in this mod is one object per map per slot, and every
-- frame draws all of them: the map the player is standing on AND every
-- connected neighbour, in the camera pass and again in the sun's. Nothing
-- ever asked whether a neighbour was on screen.
--
-- MEASURED, with the frame's own view-projection matrix taken out of a real
-- frame and every neighbour's world box tested against it:
--
--   standing in Lilycove   6 connected neighbours, 6 of 6 off screen,
--                          3,169,482 quads of terrain against the city's
--                          own 237,672 -- THIRTEEN TIMES the map you are
--                          looking at, none of it visible
--   standing on Route 119  5 connected neighbours, 5 of 5 off screen,
--                          4,730,470 quads against the route's 2,979,507
--
-- And of the current map's own mesh, 4.2% to 5.8% of its quads are on
-- screen at all -- so this is the cheap half of a much larger idea (chunked
-- meshes; see NOTES g3-governor-286) that needs none of its machinery: a
-- whole map is already one object, and a whole map is exactly what turns
-- out to be off screen.
--
-- WHAT THE BOX IS. Not measured per vertex -- folding a min/max over every
-- corner costs 8% to 17% of the build, and the build is the hitch this
-- round is cutting. It is the map's own footprint plus a fixed PAD, and the
-- PAD is a MEASURED BOUND rather than a guess: over the 81 outdoor maps the
-- emitted geometry never reaches more than 96 world pixels outside the
-- map's own rectangle (32 on a route, 96 where the border ring is deep),
-- which is what `Structures`' RING of twelve tiles allows and no pass can
-- exceed. PAD is twice that. Measured again at 96, 128, 160, 192 and 224:
-- the same neighbours cull at every one of them, so the slack is free.
--
-- A mesh with no box registered is never culled. That is the whole safety
-- story for the grass, the flowers, the figures, the battle cards and the
-- horde's gun -- none of them registers one, and all of them draw exactly
-- as they always did.

-- the mod namespace (see main.lua): V.require loads a sibling module
local V = ...

local Mat4 = V.require("Mat4")

local MeshBounds = {}

-- Twice the largest overhang measured over the 81 outdoor maps. See above.
MeshBounds.PAD = 192

-- Vertical span, likewise generous: the tallest geometry measured over the
-- same 81 maps reaches y = 208 (Sootopolis' rim) and the lowest is the
-- sea's -16, against a shadow pass whose own frustum is 160 tall.
MeshBounds.Y0 = -128
MeshBounds.Y1 = 512

-- WEAK KEYS. A mesh released by the cache (setLive evicting a far map, a
-- slot swapped for a rebuilt one) must not be kept alive by its own
-- bounding box, and a box for a dead mesh must not accumulate over a
-- cross-region walk.
local boxes = setmetatable({}, { __mode = "k" })

function MeshBounds.set(mesh, box)
  if mesh and box then boxes[mesh] = box end
end

function MeshBounds.get(mesh)
  return mesh and boxes[mesh] or nil
end

-- The box for a map's own mesh, in that map's local coordinates (a
-- neighbour is drawn through a translate, which is handed in separately).
function MeshBounds.forMap(map)
  local def = map and map.def
  if not def then return nil end
  local px = tonumber(def.blockPx)
             or ((tonumber(map.tileset and map.tileset.blockTiles) or 4) * 8)
  local w = (tonumber(def.width) or 0) * px
  local h = (tonumber(def.height) or 0) * px
  if w <= 0 or h <= 0 then return nil end
  local p = MeshBounds.PAD
  return { -p, MeshBounds.Y0, -p, w + p, MeshBounds.Y1, h + p }
end

-- Is this mesh's box entirely outside `vp`'s clip volume?
--
-- The standard conservative test: the box is hidden only when all eight
-- corners fall outside the SAME clip plane. A box that straddles two planes
-- without being inside is reported visible, which costs a draw and can
-- never cost a pixel.
--
-- No bitwise operators: LOVE ships LuaJIT 5.1 and `&` is a parse error
-- there, whatever a newer standalone build accepts.
function MeshBounds.hidden(mesh, vp, model)
  if not (mesh and vp) then return false end
  local b = boxes[mesh]
  if not b then return false end
  local m = model and Mat4.mul(vp, model) or vp
  local m1, m2, m3, m4 = m[1], m[2], m[3], m[4]
  local m5, m6, m7, m8 = m[5], m[6], m[7], m[8]
  local m9, m10, m11, m12 = m[9], m[10], m[11], m[12]
  local m13, m14, m15, m16 = m[13], m[14], m[15], m[16]
  local oL, oR, oB, oT, oN, oF = true, true, true, true, true, true
  for i = 0, 7 do
    local x = (i % 2 == 0) and b[1] or b[4]
    local y = (i >= 2 and i <= 3) or i >= 6
    y = y and b[5] or b[2]
    local z = (i < 4) and b[3] or b[6]
    local cx = m1 * x + m2 * y + m3 * z + m4
    local cy = m5 * x + m6 * y + m7 * z + m8
    local cz = m9 * x + m10 * y + m11 * z + m12
    local cw = m13 * x + m14 * y + m15 * z + m16
    if not (cx < -cw) then oL = false end
    if not (cx > cw) then oR = false end
    if not (cy < -cw) then oB = false end
    if not (cy > cw) then oT = false end
    if not (cz < -cw) then oN = false end
    if not (cz > cw) then oF = false end
    if not (oL or oR or oB or oT or oN or oF) then return false end
  end
  return oL or oR or oB or oT or oN or oF
end

return MeshBounds
