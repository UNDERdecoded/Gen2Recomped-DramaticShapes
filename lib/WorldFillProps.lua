-- Camera-facing trees and rocks on the WORLD FILL outside loaded map meshes.
--
-- Placement is derived only from the map id and the 16px world-cell position:
-- the same tile always receives the same silhouette, offset and size, so a
-- redraw or camera move can never make the distant landscape shimmer.

local V = ...

local Mat4 = V.require("Mat4")
local Voxel3D = V.require("Voxel3D")
local Voxel = V.require("VoxelState")
local FirstPerson = V.require("FirstPerson")
local WorldUnderlay = V.require("WorldUnderlay")
local biomes = V.data("world_fill_biomes")

local WorldFillProps = {}

local STEP = 16
local HEIGHT = 0
local MARGIN = 0

-- Alpha-island bounds in the supplied transparent sheets. Coordinates are
-- inclusive source pixels. Their native size already supplies three useful
-- stature classes; SCALE converts those illustration pixels to world pixels.
local SETS = {
  forest = {
    image = "assets/world-fill/grassyforest.png", scale = 0.19,
    bounds = { { 6, 8, 152, 187 }, { 167, 52, 280, 189 },
               { 291, 112, 363, 187 } },
  },
  field = {
    image = "assets/world-fill/fieldsafari.png", scale = 0.19,
    bounds = { { 4, 3, 149, 184 }, { 165, 31, 289, 180 },
               { 305, 70, 396, 180 } },
  },
  rocky = {
    image = "assets/world-fill/rockycave.png", scale = 0.21,
    bounds = { { 8, 6, 137, 152 }, { 148, 48, 241, 156 },
               { 263, 77, 337, 156 } },
  },
}

local textures = {}
local cards = {}
local merged = { key = nil, mesh = nil, count = 0 }

local function biomeFor(map)
  local def = map and map.def
  local id = map and map.id or (def and def.id)
  if not id then return nil end
  if biomes.rocky[id] then return "rocky" end
  if biomes.field[id] then return "field" end
  if biomes.forest[id] then return "forest" end
  if id:find("SAFARI_ZONE_", 1, true) == 1 then return "field" end
  local tileset = def and def.tileset
  if tileset == "CAVERN" then return "rocky" end
  if tileset == "FOREST" then return "forest" end
  return nil
end

-- Small integer hash with exact arithmetic in Lua's safe integer range.
local function hash(seed, x, z, salt)
  local h = (seed or 0) * 97 + x * 73856093 + z * 19349663
            + (salt or 0) * 83492791
  h = h % 2147483647
  if h < 0 then h = h + 2147483647 end
  return h
end

local function mapSeed(map)
  local text = tostring((map and (map.id or (map.def and map.def.id))) or "")
  local out = 7
  for i = 1, #text do out = (out * 33 + text:byte(i)) % 2147483647 end
  return out
end

local function choice(map, gx, gz)
  local seed = mapSeed(map)
  -- Only the two larger variants (1 = big, 2 = medium); skip the smallest.
  -- The variant mixes two hash streams with different salts so adjacent cells
  -- do not band or form checkerboard rows.
  local a = hash(seed, gx, gz, 1)
  local b = hash(seed, gx, gz, 7)
  local mixed = (a + b * 31) % 2147483647
  local variant = (mixed % 2) + 1                      -- 1 or 2
  local scale = variant == 1 and 1.5 or 1.0            -- big vs medium
  -- Slight per-card yaw: -1, 0 or +1 degree about the vertical, so cards on
  -- the same plane do not z-fight. Picked from a separate hash stream.
  local deg = (hash(seed, gx, gz, 3) % 3) - 1         -- -1, 0, +1
  local rot = math.rad(deg)
  return variant, scale, 0, 0, variant == 1 and 1 or 0, rot
end

local function textureFor(kind)
  if textures[kind] ~= nil then return textures[kind] or nil end
  local made
  local ok = pcall(function()
    made = V.mod.assets:image(SETS[kind].image)
    made:setFilter("linear", "linear")
    made:setWrap("clamp", "clamp")
  end)
  textures[kind] = (ok and made) or false
  return textures[kind] or nil
end

local function cardFor(kind, variant)
  local key = kind .. ":" .. variant
  if cards[key] ~= nil then return cards[key] or nil end
  local set = SETS[kind]
  local image = textureFor(kind)
  if not (set and image) then cards[key] = false return nil end
  local iw, ih = image:getDimensions()
  local b = set.bounds[variant]
  local sw, sh = b[3] - b[1] + 1, b[4] - b[2] + 1
  local w, h = sw * set.scale, sh * set.scale
  local x0, x1 = 8 - w / 2, 8 + w / 2
  local inset = 0.12
  local u0, u1 = (b[1] + inset) / iw, (b[3] + 1 - inset) / iw
  local v0, v1 = (b[2] + inset) / ih, (b[4] + 1 - inset) / ih
  cards[key] = {
    { x0, 0, 0, u0, v1 }, { x1, 0, 0, u1, v1 },
    { x1, h, 0, u1, v0 }, { x0, h, 0, u0, v0 },
  }
  return cards[key]
end

local function loadedRects(state)
  local out = {}
  local function add(map, ox, oz)
    if not map then return end
    local w = (map.widthCells or ((map.def and map.def.width or 0) * 2)) * 16
    local h = (map.heightCells or ((map.def and map.def.height or 0) * 2)) * 16
    out[#out + 1] = { (ox or 0) - MARGIN, (oz or 0) - MARGIN,
                      (ox or 0) + w + MARGIN, (oz or 0) + h + MARGIN }
  end
  add(state and state.map, 0, 0)
  for _, nb in ipairs(state and state.neighbors or {}) do
    add(nb.map, nb.ox, nb.oy)
  end
  return out
end

local function outsideLoaded(x, z, rects)
  for _, r in ipairs(rects) do
    if x >= r[1] and x <= r[3] and z >= r[2] and z <= r[4] then
      return false
    end
  end
  return true
end

local function scaledBillboard(px, pz, scale, b, rot)
  b = b or FirstPerson.cardBlend()
  rot = rot or 0
  local yaw = b > 0 and (FirstPerson.cardYaw(px + 8, pz + 8) * b) or 0
  local pitch = (Voxel.angle - math.pi / 2) * (1 - b)
  -- Mat4.billboard's local pivot is x=8. Keep that foot-centre fixed while
  -- scaling; a plain B*S would move every non-1x prop sideways. The small
  -- rotateY(rot) tips the card a hair about the vertical so co-planar cards
  -- never z-fight.
  local aroundFeet = Mat4.mul(Mat4.translate(8, 0, 0),
    Mat4.mul(Mat4.rotateY(rot),
      Mat4.mul(Mat4.scale(scale, scale, scale), Mat4.translate(-8, 0, 0))))
  return Mat4.mul(Mat4.billboard(px, pz, HEIGHT, yaw, pitch, false),
                  aroundFeet)
end

local function transformed(m, p)
  local x, y, z = p[1], p[2], p[3]
  return m[1] * x + m[2] * y + m[3] * z + m[4],
         m[5] * x + m[6] * y + m[7] * z + m[8],
         m[9] * x + m[10] * y + m[11] * z + m[12]
end

local function appendVertex(verts, model, p)
  local x, y, z = transformed(model, p)
  verts[#verts + 1] = { x, y, z, p[4], p[5], 1 }
end

local function meshKey(state, kind, cgx, cgz, radius, blend, rects)
  local parts = { kind, tostring(state.map.id), cgx, cgz, radius,
                  math.floor((Voxel.angle or 0) * 2048),
                  math.floor((blend or 0) * 1024), FirstPerson.signature() }
  for _, r in ipairs(rects) do
    parts[#parts + 1] = table.concat(r, ",")
  end
  return table.concat(parts, "|")
end

local function mergedMesh(state, kind, cgx, cgz, radius, rects, blend)
  local key = meshKey(state, kind, cgx, cgz, radius, blend, rects)
  if merged.key == key then return merged.mesh, merged.count end

  local verts, count = {}, 0
  for gz = cgz - radius, cgz + radius do
    for gx = cgx - radius, cgx + radius do
      local variant, scale, jx, jz, _, rot = choice(state.map, gx, gz)
      local centerX = gx * STEP + STEP / 2 + jx
      local centerZ = gz * STEP + STEP / 2 + jz
      if outsideLoaded(centerX, centerZ, rects) then
        local card = cardFor(kind, variant)
        if card then
          local model = scaledBillboard(centerX - 8, centerZ - 8, scale, blend, rot)
          appendVertex(verts, model, card[1])
          appendVertex(verts, model, card[2])
          appendVertex(verts, model, card[3])
          appendVertex(verts, model, card[1])
          appendVertex(verts, model, card[3])
          appendVertex(verts, model, card[4])
          count = count + 1
        end
      end
    end
  end

  local made = Voxel3D.newMesh(verts)
  if merged.mesh and merged.mesh.release then pcall(merged.mesh.release, merged.mesh) end
  merged.key, merged.mesh, merged.count = key, made, count
  return made, count
end

local function radiusFor(vw, vh, freeCamera)
  local baseRadius = math.max(10,
    math.ceil(math.max(vw or 0, vh or 0) / STEP) + 5)
  if freeCamera then baseRadius = math.max(baseRadius, 14) end
  -- Margin so the billboard ring extends slightly past the viewport edges;
  -- radiusFor sizes from max(vw,vh) (one axis), but viewport corners sit
  -- ~1.41x farther from centre, so without it trees cull at the corners.
  local MARGIN = 4
  return math.floor(baseRadius * 0.5) + MARGIN
end

function WorldFillProps.draw(state, cx, cz, vw, vh)
  if not (state and state.map and WorldUnderlay.natureEnabled()) then return 0 end
  local kind = biomeFor(state.map)
  if not kind then return 0 end
  local texture = textureFor(kind)
  if not texture then return 0 end

  -- The normal diorama only needs the nearby fringe; first person can look
  -- along the fill plane, so retain several extra rows toward its horizon.
  local radius = radiusFor(vw, vh, FirstPerson.cardBlend() > 0.5)
  local cgx, cgz = math.floor((cx or 0) / STEP), math.floor((cz or 0) / STEP)
  local rects = loadedRects(state)
  local blend = FirstPerson.cardBlend()
  local mesh, count = mergedMesh(state, kind, cgx, cgz, radius, rects, blend)
  if not mesh then return 0 end

  Voxel3D.glass(false)
  Voxel3D.seams(false)
  Voxel3D.draw(mesh, texture, nil)
  Voxel3D.seams(true)
  Voxel3D.glass(true)
  return count
end

function WorldFillProps.clear()
  if merged.mesh and merged.mesh.release then pcall(merged.mesh.release, merged.mesh) end
  textures = {}
  cards = {}
  merged = { key = nil, mesh = nil, count = 0 }
end

WorldFillProps.biomeFor = biomeFor
WorldFillProps.choice = choice
WorldFillProps.outsideLoaded = outsideLoaded
WorldFillProps.loadedRects = loadedRects
WorldFillProps.radiusFor = radiusFor
WorldFillProps.SETS = SETS

return WorldFillProps
