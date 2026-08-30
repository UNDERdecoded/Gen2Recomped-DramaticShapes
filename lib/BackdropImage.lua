local V = ...

local BackdropImage = {}
local cache = {}

function BackdropImage.load(folder, file)
  if not file then return nil end
  local rel = ("assets/battle/front-static/%s/%s"):format(folder, file)
  if cache[rel] ~= nil then return cache[rel] or nil end
  local made
  local ok = pcall(function()
    made = V.mod.assets:image(rel)
    made:setFilter("linear", "linear")
    made:setWrap("clamp", "clamp")
  end)
  cache[rel] = (ok and made) or false
  return cache[rel] or nil
end

return BackdropImage
