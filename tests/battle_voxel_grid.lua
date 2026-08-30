local function source(path)
  local file = assert(io.open(path, "rb"))
  local body = assert(file:read("*a"))
  file:close()
  return body
end

local scene = source("lib/BattleScene.lua")
assert(not scene:find("VoxelGrid.override = true", 1, true),
  "battle scene still forces the voxel grid on")
assert(scene:find("The same V%-GRID row owns free roam and battles"),
  "battle scene no longer documents shared V-GRID ownership")

local voxel = source("lib/Voxel3D.lua")
local begin = assert(voxel:find("function Voxel3D.beginScene", 1, true))
assert(voxel:find("local grid = VoxelGrid.enabled()", begin, true),
  "scene shader selection no longer reads the V-GRID setting")

print("battle voxel-grid regression: ok")
