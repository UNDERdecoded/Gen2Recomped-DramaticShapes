-- Compatibility for the iOS/Metal Canvas orientation fixed by the engine in
-- 0.7.6.  Older LÖVE 12 iOS builds composite a render-pipeline world Canvas
-- upside-down; ordinary UI is drawn later and is therefore unaffected.

local V = ...

local PixelCanvas = V.require("PixelCanvas")
local Orientation = {}

local ENGINE_FIX = { 0, 7, 6 }
local targets = {}

local function versionParts(value)
  local out = {}
  for n in tostring(value or ""):gmatch("%d+") do
    out[#out + 1] = tonumber(n)
    if #out == 3 then break end
  end
  return out
end

local function beforeFix(value)
  local got = versionParts(value)
  if #got == 0 then return true end
  for i = 1, 3 do
    local a, b = got[i] or 0, ENGINE_FIX[i]
    if a ~= b then return a < b end
  end
  return false
end

local function engineVersion()
  local ok, Version = pcall(require, "src.core.Version")
  if ok and type(Version) == "table" then return Version.engine end
end

function Orientation.needsFlip()
  if not (love and love.system and love.system.getOS
          and love.system.getOS() == "iOS" and love.getVersion) then
    return false
  end
  local major = love.getVersion()
  return type(major) == "number" and major >= 12
         and beforeFix(engineVersion())
end

local function targetFor(slot, w, h)
  local held = targets[slot]
  if held and held.w == w and held.h == h then return held.canvas end
  local ok, canvas = PixelCanvas.new(w, h)
  if not (ok and canvas) then return nil end
  pcall(canvas.setFilter, canvas, "nearest", "nearest")
  if held and held.canvas and held.canvas.release then
    pcall(held.canvas.release, held.canvas)
  end
  targets[slot] = { canvas = canvas, w = w, h = h }
  return canvas
end

-- Pre-flip a finished world image for an old iOS compositor.  Engine 0.7.6
-- and newer performs this exact negative-Y blit itself, so those versions
-- receive the original Canvas and cannot be double-flipped.
function Orientation.present(canvas, slot)
  if not (canvas and Orientation.needsFlip()) then return canvas end
  local ok, w, h = pcall(canvas.getDimensions, canvas)
  if not (ok and w and h and w > 0 and h > 0) then return canvas end
  local target = targetFor(slot or "world", w, h)
  if not target or target == canvas then return canvas end

  local g = love.graphics
  local prevCanvas = g.getCanvas and g.getCanvas() or nil
  local prevBlend, prevAlpha = g.getBlendMode()
  local drew = pcall(function()
    g.setCanvas(target)
    g.setShader()
    g.setBlendMode("replace", "premultiplied")
    g.setColor(1, 1, 1, 1)
    g.clear(0, 0, 0, 0)
    g.draw(canvas, 0, h, 0, 1, -1)
  end)
  if prevCanvas then g.setCanvas(prevCanvas) else g.setCanvas() end
  g.setShader()
  g.setBlendMode(prevBlend or "alpha", prevAlpha)
  g.setColor(1, 1, 1, 1)
  return drew and target or canvas
end

function Orientation.invalidate()
  for slot, held in pairs(targets) do
    if held.canvas and held.canvas.release then
      pcall(held.canvas.release, held.canvas)
    end
    targets[slot] = nil
  end
end

return Orientation
