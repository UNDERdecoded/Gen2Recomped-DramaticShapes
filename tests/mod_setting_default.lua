local stored
local V = {
  mod = {
    id = "TEST",
    options = {
      get = function() return stored end,
    },
  },
}

local ModSetting = assert(loadfile("lib/ModSetting.lua"))(V)
local setting = ModSetting.new("art", "ART",
  { "gen1", "gen2", "gen3" }, { "GEN 1", "GEN 2", "GEN 3" }, 2)

assert(setting:get() == "gen2", "default index was not used for an empty save")
assert(setting:schema("test").default == "gen2",
  "schema default does not match the runtime default")

stored = "gen3"
setting.index = nil
assert(setting:get() == "gen3", "a saved value was replaced by the default")

stored = "unknown"
setting.index = nil
assert(setting:get() == "gen2", "invalid saved value did not use the fallback")

print("mod-setting default regression: ok")
