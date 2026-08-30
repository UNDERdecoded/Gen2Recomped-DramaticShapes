-- Nature set used to decorate the WORLD FILL beyond a loaded map.
--
-- Keep this routing explicit: a new route can be tuned here without touching
-- the renderer, and towns/ordinary rooms deliberately fall through to nil.

local forest = {
  PALLET_TOWN = true, VIRIDIAN_CITY = true, PEWTER_CITY = true,
  CERULEAN_CITY = true, VERMILION_CITY = true, LAVENDER_TOWN = true,
  CELADON_CITY = true, FUCHSIA_CITY = true, SAFFRON_CITY = true,
  CINNABAR_ISLAND = true,
  ROUTE_1 = true, ROUTE_2 = true, ROUTE_5 = true, ROUTE_6 = true,
  ROUTE_7 = true, ROUTE_8 = true, ROUTE_22 = true,
  ROUTE_24 = true, ROUTE_25 = true,
  VIRIDIAN_FOREST = true,
}

local field = {
  ROUTE_11 = true, ROUTE_12 = true, ROUTE_13 = true, ROUTE_14 = true,
  ROUTE_15 = true, ROUTE_16 = true, ROUTE_17 = true, ROUTE_18 = true,
  SAFARI_ZONE_CENTER = true, SAFARI_ZONE_EAST = true,
  SAFARI_ZONE_NORTH = true, SAFARI_ZONE_WEST = true,
}

local rocky = {
  ROUTE_3 = true, ROUTE_4 = true, ROUTE_9 = true, ROUTE_10 = true,
  ROUTE_23 = true, INDIGO_PLATEAU = true,
}

return {
  forest = forest,
  field = field,
  rocky = rocky,
}
