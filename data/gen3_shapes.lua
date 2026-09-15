-- Voxel world mode: THE GEN 3 SHAPE PROFILE.
--
-- Hand-authored by this mod and read only from here.  Nothing below is
-- extracted, derived or copied from the ROM; nothing here reaches gameplay,
-- collision or scripts.  An entry can only ever change how a cell LOOKS.
--
-- This is the Gen 3 counterpart of `collision` in data/voxel_heights.lua, and
-- it is deliberately a SEPARATE table rather than more rows in that one.  Gen
-- 2 collision classes and Gen 3 behaviour bytes are two unrelated numberings
-- that overlap end to end -- $02 is tall grass here and a wall class there --
-- so merging them would not make a bigger table, it would make a wrong one.
-- And it would be wrong SILENTLY, which is the failure mode this mod has paid
-- for more than once.
--
-- ---------------------------------------------------------------------------
-- WHAT A BEHAVIOUR BYTE IS
-- ---------------------------------------------------------------------------
--
-- Every Gen 3 metatile carries a 16-bit attributes word.  Its low byte is the
-- BEHAVIOUR: one of 240 named values saying what kind of surface this is.
-- Bits 12-15 are the LAYER TYPE.  Bits 8-11 are unused in Emerald -- there is
-- no terrain-type and no encounter-type field here, whatever FireRed does.
--
-- The behaviour says what a cell IS, not whether you can walk on it.
-- Passability is the map CELL's business (the blockdata word's collision
-- bits), because in Gen 3 the same metatile is a wall in one place and a
-- doorway in another -- a house front and its door are one tile.  So
-- MB_NORMAL tells you almost nothing on its own, and most of the world is
-- MB_NORMAL: the rows below are the cells that DO announce themselves, and
-- Gen3.classAt handles the rest from the collision bit and the layer type.
--
-- Every behaviour Emerald actually defines has a row.  The 75 MB_UNUSED_*
-- values do not, and that is the whole of what is missing.
--
-- Classes are this mod's own vocabulary (lib/TileShape.lua, FALLBACK_HEIGHTS)
-- with three added for Gen 3:
--
--   bridge   a DECK: flat, thin, standing at its cell's own elevation with a
--            fascia down its open sides.
--   log      a floating raft, riding barely clear of the water.
--   slope    a ramp between two elevations, taking its rise from the cells on
--            either side rather than from a height of its own.
-- ---------------------------------------------------------------------------

return {
  version = 1,
  source = "pret/pokeemerald include/constants/metatile_behaviors.h",

  -- The three added classes, carried here as well so a host whose TileShape
  -- predates them still resolves something rather than dropping the cell.
  classes = {
    bridge = { h = 4, art = "top" },
    log    = { h = 2, art = "top" },
    slope  = { h = 0, art = "top" },
  },

  -- Emerald's four reserved elevations, by name (include/global.fieldmap.h).
  elevation = {
    transition = 0,   -- "matches anything": ramps, stairs, the lip of a cliff
    surf       = 1,   -- the water surface
    default    = 3,   -- ordinary ground -- the datum
    multi      = 15,  -- "do not change the walker's level here": a bridge deck
  },

  -- behaviour byte -> class.  165 rows, covering every
  -- behaviour Emerald defines.
  behaviour = {
    -- ORDINARY GROUND.  MB_NORMAL is most of the world, and what a
  -- normal cell BECOMES is decided by its collision bit and its layer type
  -- rather than here -- see Gen3.classAt.  A cave floor, a mountain top and
  -- an indoor-encounter floor are all just floor to a renderer.
    [0x00] = "ground",      -- MB_NORMAL
    [0x07] = "ground",      -- MB_SHORT_GRASS
    [0x08] = "ground",      -- MB_CAVE
    [0x0A] = "ground",      -- MB_NO_RUNNING
    [0x0B] = "ground",      -- MB_INDOOR_ENCOUNTER
    [0x0C] = "ground",      -- MB_MOUNTAIN_TOP
    [0x1B] = "ground",      -- MB_STAIRS_OUTSIDE_ABANDONED_SHIP
    [0x1C] = "ground",      -- MB_SHOAL_CAVE_ENTRANCE
    [0x48] = "ground",      -- MB_TRICK_HOUSE_PUZZLE_8_FLOOR

    -- SAND.  Deep sand records footprints and slows you down; none of
  -- it changes shape.
    [0x06] = "ground",      -- MB_DEEP_SAND
    [0x21] = "ground",      -- MB_SAND
    [0x25] = "ground",      -- MB_FOOTPRINTS

    -- ICE.  Slippery, and flat: the crack state is a texture, not a
  -- form.
    [0x20] = "ground",      -- MB_ICE
    [0x26] = "ground",      -- MB_THIN_ICE
    [0x27] = "ground",      -- MB_CRACKED_ICE

    -- FORCED MOVEMENT.  The Trick House conveyors and the ice-puzzle
  -- slides -- ordinary floor that walks you across itself.
    [0x40] = "ground",      -- MB_WALK_EAST
    [0x41] = "ground",      -- MB_WALK_WEST
    [0x42] = "ground",      -- MB_WALK_NORTH
    [0x43] = "ground",      -- MB_WALK_SOUTH
    [0x44] = "ground",      -- MB_SLIDE_EAST
    [0x45] = "ground",      -- MB_SLIDE_WEST
    [0x46] = "ground",      -- MB_SLIDE_NORTH
    [0x47] = "ground",      -- MB_SLIDE_SOUTH

    -- INVISIBLE BARRIERS.  These sit on ORDINARY ART -- the
  -- edge of a cliff, the rail of a pier -- and block one direction without
  -- drawing anything at all.  Standing them up would build a wall the game
  -- never draws; what the player actually sees is the ELEVATION step beside
  -- them, and that comes through the height field for free.
    [0x30] = "ground",      -- MB_IMPASSABLE_EAST
    [0x31] = "ground",      -- MB_IMPASSABLE_WEST
    [0x32] = "ground",      -- MB_IMPASSABLE_NORTH
    [0x33] = "ground",      -- MB_IMPASSABLE_SOUTH
    [0x34] = "ground",      -- MB_IMPASSABLE_NORTHEAST
    [0x35] = "ground",      -- MB_IMPASSABLE_NORTHWEST
    [0x36] = "ground",      -- MB_IMPASSABLE_SOUTHEAST
    [0x37] = "ground",      -- MB_IMPASSABLE_SOUTHWEST
    [0xC0] = "ground",      -- MB_IMPASSABLE_SOUTH_AND_NORTH
    [0xC1] = "ground",      -- MB_IMPASSABLE_WEST_AND_EAST

    -- WARPS, HOLES AND ESCALATORS.  Floor you step onto and leave
  -- from.  Berry soil is here too: the plant growing in it is an object
  -- sprite, not part of the metatile.
    [0x0D] = "ground",      -- MB_BATTLE_PYRAMID_WARP
    [0x0E] = "ground",      -- MB_MOSSDEEP_GYM_WARP
    [0x0F] = "ground",      -- MB_MT_PYRE_HOLE
    [0x29] = "ground",      -- MB_LAVARIDGE_GYM_B1F_WARP
    [0x62] = "ground",      -- MB_EAST_ARROW_WARP
    [0x63] = "ground",      -- MB_WEST_ARROW_WARP
    [0x64] = "ground",      -- MB_NORTH_ARROW_WARP
    [0x65] = "ground",      -- MB_SOUTH_ARROW_WARP
    [0x66] = "ground",      -- MB_CRACKED_FLOOR_HOLE
    [0x67] = "ground",      -- MB_AQUA_HIDEOUT_WARP
    [0x68] = "ground",      -- MB_LAVARIDGE_GYM_1F_WARP
    [0x6A] = "ground",      -- MB_UP_ESCALATOR
    [0x6B] = "ground",      -- MB_DOWN_ESCALATOR
    [0x6D] = "ground",      -- MB_WATER_SOUTH_ARROW_WARP
    [0x6E] = "ground",      -- MB_DEEP_SOUTH_WARP
    [0xA0] = "ground",      -- MB_BERRY_TREE_SOIL
    [0xD2] = "ground",      -- MB_CRACKED_FLOOR

    -- GRASS.  Tall, long, and the ash-covered grass of Route 113 --
  -- all of it flat ground wearing standing blades.
    [0x02] = "grass",       -- MB_TALL_GRASS
    [0x03] = "grass",       -- MB_LONG_GRASS
    [0x09] = "grass",       -- MB_LONG_GRASS_SOUTH_EDGE
    [0x24] = "grass",       -- MB_ASHGRASS

    -- WATER.  Every surfable behaviour, plus the four currents, the
  -- seaweed and the reflection strip drawn under a bridge.  Puddles, shallow
  -- water and the Lavaridge hot springs are water as well: they recess, they
  -- reflect, and a puddle meshed as ground is a blue square lying on the
  -- road.
    [0x10] = "water",       -- MB_POND_WATER
    [0x11] = "water",       -- MB_INTERIOR_DEEP_WATER
    [0x12] = "water",       -- MB_DEEP_WATER
    [0x13] = "waterfall",   -- MB_WATERFALL
    [0x14] = "water",       -- MB_SOOTOPOLIS_DEEP_WATER
    [0x15] = "water",       -- MB_OCEAN_WATER
    [0x16] = "water",       -- MB_PUDDLE
    [0x17] = "water",       -- MB_SHALLOW_WATER
    [0x18] = "water",       -- MB_UNUSED_SOOTOPOLIS_DEEP_WATER
    [0x19] = "water",       -- MB_NO_SURFACING
    [0x1A] = "water",       -- MB_UNUSED_SOOTOPOLIS_DEEP_WATER_2
    [0x22] = "water",       -- MB_SEAWEED
    [0x28] = "water",       -- MB_HOT_SPRINGS
    [0x2A] = "water",       -- MB_SEAWEED_NO_SURFACING
    [0x2B] = "water",       -- MB_REFLECTION_UNDER_BRIDGE
    [0x50] = "water",       -- MB_EASTWARD_CURRENT
    [0x51] = "water",       -- MB_WESTWARD_CURRENT
    [0x52] = "water",       -- MB_NORTHWARD_CURRENT
    [0x53] = "water",       -- MB_SOUTHWARD_CURRENT

    -- JUMP LEDGES, all eight directions.  The direction is in the
  -- behaviour's own NAME here -- on Gen 2 it has to be read off the
  -- neighbouring cell's collision class (TileShape's HOP_LIP), which is why
  -- that rule exists at all.
    [0x38] = "ledge",       -- MB_JUMP_EAST
    [0x39] = "ledge",       -- MB_JUMP_WEST
    [0x3A] = "ledge",       -- MB_JUMP_NORTH
    [0x3B] = "ledge",       -- MB_JUMP_SOUTH
    [0x3C] = "ledge",       -- MB_JUMP_NORTHEAST
    [0x3D] = "ledge",       -- MB_JUMP_NORTHWEST
    [0x3E] = "ledge",       -- MB_JUMP_SOUTHEAST
    [0x3F] = "ledge",       -- MB_JUMP_SOUTHWEST

    -- SLOPES.  A muddy slope needs the Acro Bike to climb and a bumpy
  -- one bounces you up it; both are RAMPS between two elevations, and the
  -- cells on either side are what give them their rise.
    [0xD0] = "slope",       -- MB_MUDDY_SLOPE
    [0xD1] = "slope",       -- MB_BUMPY_SLOPE

    -- BRIDGES AND LOG RAFTS.  A bridge cell carries elevation 15
  -- (MULTI_LEVEL) and spans water at elevation 1 -- the one place Emerald
  -- states real stacked geometry outright, and 592 cells of Route 110's
  -- cycling road are exactly that.  Pacifidlog's logs get their own class
  -- because they FLOAT: the town draws every log in three vertical states
  -- and a raft rides barely clear of the sea.
    [0x70] = "bridge",      -- MB_BRIDGE_OVER_OCEAN
    [0x71] = "bridge",      -- MB_BRIDGE_OVER_POND_LOW
    [0x72] = "bridge",      -- MB_BRIDGE_OVER_POND_MED
    [0x73] = "bridge",      -- MB_BRIDGE_OVER_POND_HIGH
    [0x74] = "log",         -- MB_PACIFIDLOG_VERTICAL_LOG_TOP
    [0x75] = "log",         -- MB_PACIFIDLOG_VERTICAL_LOG_BOTTOM
    [0x76] = "log",         -- MB_PACIFIDLOG_HORIZONTAL_LOG_LEFT
    [0x77] = "log",         -- MB_PACIFIDLOG_HORIZONTAL_LOG_RIGHT
    [0x78] = "bridge",      -- MB_FORTREE_BRIDGE
    [0x7A] = "bridge",      -- MB_BRIDGE_OVER_POND_MED_EDGE_1
    [0x7B] = "bridge",      -- MB_BRIDGE_OVER_POND_MED_EDGE_2
    [0x7C] = "bridge",      -- MB_BRIDGE_OVER_POND_HIGH_EDGE_1
    [0x7D] = "bridge",      -- MB_BRIDGE_OVER_POND_HIGH_EDGE_2
    [0x7F] = "bridge",      -- MB_BIKE_BRIDGE_OVER_BARRIER

    -- RAILS.  The Mauville cycling-road barriers and the New Mauville
  -- fences: waist-high, see-through, and not walls.
    -- A RAIL IS A PLANK YOU WALK ALONG, NOT A RAILING YOU WALK PAST.
    --
    -- These four rows said `fence`, and they were unreachable: `fence` is in
    -- `standing` below, so a PASSABLE cell carrying one fell straight back to
    -- `ground`.  51 of Route 119's 55 rail cells are passable -- you walk on
    -- them -- so 51 of them meshed as two courses of solid pavement standing
    -- in the river.
    --
    -- And `fence` was the wrong answer even where it did apply.  Route 119's
    -- rails are the white plank walkways over its water: a narrow deck on
    -- dark posts, drawn end to end in runs, which is a BRIDGE.  The map's
    -- other six crossings already reach `bridge` through the elevation rule
    -- (see Gen3.classAt, ELEV_MULTI) and these are the same structure by
    -- another statement -- the only difference is that the cartridge names
    -- these ones instead of leaving them to the elevation field.
    --
    -- `bridge` is not in `standing`, which is what makes the row apply at
    -- all: a deck is walkable by definition.  Route 119 and the Safari
    -- Zone's south gate are the only maps in Hoenn that carry these.
    [0xD3] = "bridge",      -- MB_ISOLATED_VERTICAL_RAIL
    [0xD4] = "bridge",      -- MB_ISOLATED_HORIZONTAL_RAIL
    [0xD5] = "bridge",      -- MB_VERTICAL_RAIL
    [0xD6] = "bridge",      -- MB_HORIZONTAL_RAIL

    -- DOORS AND LADDERS.  A door is part of the facade and must rise
  -- WITH the wall it is cut into, or every building in Hoenn ends up with a
  -- doorway-shaped notch punched through it.
    [0x60] = "wall",        -- MB_NON_ANIMATED_DOOR
    [0x61] = "wall",        -- MB_LADDER
    [0x69] = "wall",        -- MB_ANIMATED_DOOR
    [0x6C] = "wall",        -- MB_WATER_DOOR
    [0x8B] = "wall",        -- MB_CLOSED_SOOTOPOLIS_DOOR
    [0x8C] = "wall",        -- MB_TRICK_HOUSE_PUZZLE_DOOR
    [0x8D] = "wall",        -- MB_PETALBURG_GYM_DOOR
    [0xBE] = "wall",        -- MB_SECRET_BASE_BREAKABLE_DOOR
    [0xEA] = "wall",        -- MB_SKY_PILLAR_CLOSED_DOOR

    -- FURNITURE.  This is the part Gen 2 cannot express at all --
  -- its collision classes know about counters and bookshelves and nothing
  -- else -- while Emerald names the television, the PC, the vase, the trash
  -- can, the Pokeblock feeder and the slot machine one at a time.
    [0x80] = "counter",     -- MB_COUNTER
    [0x83] = "console",     -- MB_PC
    [0x84] = "console",     -- MB_CABLE_BOX_RESULTS_1
    [0x85] = "wall",        -- MB_REGION_MAP
    [0x86] = "console",     -- MB_TELEVISION
    [0x87] = "prop",        -- MB_POKEBLOCK_FEEDER
    [0x89] = "prop",        -- MB_SLOT_MACHINE

    -- A ROULETTE TABLE IS DRAWN FROM ABOVE, AND `prop` STANDS IT ON EDGE.
    --
    -- MOTIVATED BY THE TWO ROULETTE TABLES ON THE FLOOR OF
    -- MauvilleCity_GameCorner, (14..15, 6..8) AND (18..19, 6..8) -- "the
    -- game tables are appearing vertically instead of on the ground".
    --
    -- `prop` is not a shape.  Every other row in this block names a shape
    -- the mod models -- a counter, a bookcase, a television, a vase -- and
    -- `prop` is what a row says when the cartridge has named an
    -- INTERACTION and the mod has no model for it.  It resolves to the
    -- per-pixel STANDEE pool (`TileShape.ART.prop == "billboard"`,
    -- `Structures.PINNED_DEPTH.prop == 5`), where
    -- `Structures.extractObjects` floods the whole connected cluster and
    -- `Structures.buildVolume` maps every drawn pixel ROW onto a voxel of
    -- HEIGHT (`y = baseY + c.lowY - ly`).  Six cells of roulette table
    -- therefore came out as ONE 32x48px plane standing on its south edge:
    -- measured, the two clusters span y 0..46 in a room whose walls are 32,
    -- and the map draws 15,888 vertical object quads against 454
    -- horizontal.
    --
    -- WHAT THE DRAWING SAYS.  Metatile 546, the table's north-west cell,
    -- mirrors TOP TO BOTTOM about its own row 8.5 at 0.955 of its pixels
    -- (7 row pairs, exact palette-index equality) -- rows 4/13, 5/12, 6/11,
    -- 7/10 and 8/9 are identical and 3/14 differs in one pixel.  That is a
    -- WHEEL SEEN FROM DIRECTLY ABOVE and it cannot be a front face: nothing
    -- drawn face-on in a Gen 3 interior is its own reflection in a
    -- horizontal line, because a standing object has a top, a body and a
    -- base (the slot machine's own 548 reads 0.420, 556 reads 0.607, 564
    -- reads 0.552).  547/554/555 continue the table as the betting grid,
    -- also from above; 562/563 close it with six rows of front apron and
    -- then four rows of the room's own carpet.  That is a table lying on
    -- the floor, drawn top-down, exactly like
    -- MossdeepCity_GameCorner_1F's tables at (2..3, 7) and (7..8, 7) --
    -- which the pixel carve in `Gen3.buildScenery` already calls `tabletop`
    -- because Emerald leaves their behaviour byte MB_NORMAL and the carve
    -- gets to answer.  Mauville's carry MB_ROULETTE, the row below
    -- pre-empted the carve, and the two game corners in Hoenn ended up
    -- modelled as opposites.
    --
    -- AND THE CARTRIDGE SAYS IT TOO, IN THE PLACE THIS MOD ALREADY READS.
    -- `Structures.standGen3Furniture` (g3-carcass-239) established where
    -- Emerald states that a piece of indoor furniture STANDS: the part over
    -- your head goes in the above-player layer of the WALKABLE ROW BEHIND
    -- the object, drawn right across the tile row nearest it
    -- (`stats.bot2 >= 128`).  Asked of every indoor blocked cell in all 518
    -- maps whose class comes from a behaviour row that says `prop` -- which
    -- is these four objects and nothing else in Hoenn -- the answer is
    -- exactly bimodal, with no threshold in it to fit:
    --
    --   MB_SLOT_MACHINE  (2..3, 6..9) and (7..8, 6..9)   128, 128  of 128
    --   MB_ROULETTE      (14..15, 6..8) and (18..19,6..8)  0,   0  of 128
    --
    -- The slot machines have a full lid drawn over the player in the
    -- walkable row at cy = 5 (metatile 548/549, 208 above-player pixels,
    -- bot2 = 128) and are drawn face-on, so they KEEP the standee.  The
    -- roulette tables have nothing above the player anywhere behind them --
    -- the row at cy = 5 is the plain floor metatile 514, bot2 = 0 -- so
    -- they are not drawn face-on and must not be stood up.
    --
    -- `tabletop` is a 12px box wearing its own cell's art on its LID, one
    -- cell of drawing per cell of box, 1:1 (`ChunkMesher`'s non-upright
    -- branch takes `topTile = tile`).  It is deliberately NOT `carcass`:
    -- a carcass folds its picture UP ITS SOUTH FACE, which would put the
    -- roulette wheel on a vertical panel again.  `standGen3Furniture` still
    -- gets to look at these six-cell objects afterwards and declines to
    -- stand them, on the same test, which is the reading confirming itself
    -- rather than a special case.
    --
    -- ALTERNATIVE READING CONSIDERED AND REJECTED: the role table's
    -- `art`/`cap`/`face` fields (546 is "brow" cap 0 face 1, 555 is
    -- "surface" cap 16).  Those describe TERRAIN -- where a drop turns over
    -- from top to wall -- and g3-carcass-239 already measured them as no
    -- discriminator for furniture.  A roulette table is not terrain.
    [0x8A] = "tabletop",    -- MB_ROULETTE
    [0x8E] = "wall",        -- MB_RUNNING_SHOES_INSTRUCTION
    [0x8F] = "wall",        -- MB_QUESTIONNAIRE
    [0xB0] = "console",     -- MB_SECRET_BASE_PC
    [0xB1] = "console",     -- MB_SECRET_BASE_REGISTER_PC
    [0xC5] = "console",     -- MB_PLAYER_ROOM_PC_ON
    [0xC7] = "wall",        -- MB_SECRET_BASE_POSTER
    [0xE0] = "bookcase",    -- MB_PICTURE_BOOK_SHELF
    [0xE1] = "bookcase",    -- MB_BOOKSHELF
    [0xE2] = "bookcase",    -- MB_POKEMON_CENTER_BOOKSHELF
    [0xE3] = "cylinder",    -- MB_VASE
    [0xE4] = "can",         -- MB_TRASH_CAN
    [0xE5] = "bookcase",    -- MB_SHOP_SHELF
    [0xE6] = "wall",        -- MB_BLUEPRINT
    [0xE7] = "console",     -- MB_CABLE_BOX_RESULTS_2
    [0xE8] = "console",     -- MB_WIRELESS_BOX_RESULTS
    [0xE9] = "console",     -- MB_TRAINER_HILL_TIMER

    -- SECRET BASES.  The cave and tree entrance spots, the
  -- decoration footprints and the mats.  270 of the game's 692 metatile
  -- labels are secret-base furniture, which is a large slice of the
  -- vocabulary for a part of the game most players see once.
    [0x01] = "wall",        -- MB_SECRET_BASE_WALL
    [0x90] = "wall",        -- MB_SECRET_BASE_SPOT_RED_CAVE
    [0x91] = "wall",        -- MB_SECRET_BASE_SPOT_RED_CAVE_OPEN
    [0x92] = "wall",        -- MB_SECRET_BASE_SPOT_BROWN_CAVE
    [0x93] = "wall",        -- MB_SECRET_BASE_SPOT_BROWN_CAVE_OPEN
    [0x94] = "wall",        -- MB_SECRET_BASE_SPOT_YELLOW_CAVE
    [0x95] = "wall",        -- MB_SECRET_BASE_SPOT_YELLOW_CAVE_OPEN
    [0x96] = "tree",        -- MB_SECRET_BASE_SPOT_TREE_LEFT
    [0x97] = "tree",        -- MB_SECRET_BASE_SPOT_TREE_LEFT_OPEN
    [0x98] = "tree",        -- MB_SECRET_BASE_SPOT_SHRUB
    [0x99] = "tree",        -- MB_SECRET_BASE_SPOT_SHRUB_OPEN
    [0x9A] = "wall",        -- MB_SECRET_BASE_SPOT_BLUE_CAVE
    [0x9B] = "wall",        -- MB_SECRET_BASE_SPOT_BLUE_CAVE_OPEN
    [0x9C] = "tree",        -- MB_SECRET_BASE_SPOT_TREE_RIGHT
    [0x9D] = "tree",        -- MB_SECRET_BASE_SPOT_TREE_RIGHT_OPEN
    [0xB2] = "prop",        -- MB_SECRET_BASE_SCENERY
    [0xB3] = "ground",      -- MB_SECRET_BASE_TRAINER_SPOT
    [0xB4] = "prop",        -- MB_SECRET_BASE_DECORATION
    [0xB5] = "prop",        -- MB_HOLDS_SMALL_DECORATION
    [0xB7] = "wall",        -- MB_SECRET_BASE_NORTH_WALL
    [0xB8] = "prop",        -- MB_SECRET_BASE_BALLOON
    [0xB9] = "wall",        -- MB_SECRET_BASE_IMPASSABLE
    [0xBA] = "ground",      -- MB_SECRET_BASE_GLITTER_MAT
    [0xBB] = "ground",      -- MB_SECRET_BASE_JUMP_MAT
    [0xBC] = "ground",      -- MB_SECRET_BASE_SPIN_MAT
    [0xBD] = "ground",      -- MB_SECRET_BASE_SOUND_MAT
    [0xBF] = "prop",        -- MB_SECRET_BASE_SAND_ORNAMENT
    [0xC2] = "ground",      -- MB_SECRET_BASE_HOLE
    [0xC3] = "prop",        -- MB_HOLDS_LARGE_DECORATION
    [0xC4] = "prop",        -- MB_SECRET_BASE_TV_SHIELD
    [0xC6] = "prop",        -- MB_SECRET_BASE_DECORATION_BASE
  },

  -- ---------------------------------------------------------------------
  -- CLASSES YOU CANNOT BE STANDING INSIDE.
  --
  -- A behaviour row is a statement about the ART, and the cell's collision
  -- bit is a separate statement about whether you can walk there.  Where the
  -- two disagree the collision bit wins, because it is the one the player
  -- experiences: MB_MOUNTAIN_TOP is the crater wall in Sootopolis and a
  -- walkable rock shelf in Pacifidlog, out of the same behaviour byte.
  --
  -- So a row naming one of these classes only applies to a BLOCKED cell; on
  -- a passable one it falls back to ground.  Without the rule a profile that
  -- makes Sootopolis' rim two courses tall also makes every walkable ledge
  -- in Pacifidlog a 32px block with the player buried in it.
  --
  -- DOORS are the deliberate exception and are listed separately below: a
  -- door cell IS walkable -- you step onto it to warp -- and it has to rise
  -- with the wall it is cut into anyway, or the facade gets a doorway-shaped
  -- hole punched through it.  Gen 1 and Gen 2 reach the same conclusion by a
  -- different route (Structures' door fold).
  standing = {
    wall = true, cliff = true, tree = true, shell = true, column = true,
    bookcase = true, counter = true, console = true, prop = true,
    cylinder = true, can = true, fence = true, billboard = true,
    signpost = true, post = true, planter = true, canopy = true,
    table_ = true, desk = true,
    -- `tabletop` joins the set with MB_ROULETTE above, and it is a no-op on
    -- the cartridge as shipped: all twelve MB_ROULETTE cells in Hoenn --
    -- MauvilleCity_GameCorner (14..15, 6..8) and (18..19, 6..8), the only
    -- twelve there are -- are blocked, so this branch never fires on them.
    -- It is here because the set's whole job is "this class only applies
    -- where the player cannot be", and a `tabletop` on a walkable cell
    -- would raise a 12px riser under the player's feet, which is the one
    -- kind of artefact this file's own comment says the set exists to stop.
    -- No behaviour row resolved to `tabletop` before MB_ROULETTE did, so
    -- nothing else in Hoenn, Kanto, Johto or Prism can reach this line: the
    -- only other `tabletop` in the file is the PIN on gTileset_
    -- BrendansMaysHouse's dining cloth (538/539/546/547), and a pin returns
    -- from `classAt`'s first arm, long before this test.
    tabletop = true,
  },

  -- ---------------------------------------------------------------------
  -- THE FOUR GRASSES, SEPARATED.
  --
  -- Emerald writes four different behaviour bytes on things this mod had
  -- been calling one class, and they are four different DRAWINGS.  The
  -- shape class above stays `grass` for all four -- it is what says "flat
  -- walkable ground" to eight separate passes in Structures, Gen3 and
  -- TileShape, and moving it would move terrain -- so the separation is
  -- here, on the one question the class cannot answer: what, if anything,
  -- does this drawing state is STANDING on the cell.
  --
  -- Measured over all 518 maps, on the shape surface (the atlas with the
  -- tileset's own ground colours carved to alpha 0 -- Gen3.shapeDataForMap),
  -- as opaque pixels out of the cell's 256, and as pixels drawn on the
  -- ABOVE-PLAYER layer out of 256:
  --
  --   beh  what            metatile(s)          cover     above-player
  --   ---- --------------- -------------------- --------- ------------
  --   0x00 the lawn        general m1           0/256     0
  --   0x02 TALL GRASS      general m13          71/256    0
  --        (+ tree fringe) general m454/455     85,86/256 23
  --   0x03 LONG GRASS      Fortree m21          237/256   0
  --   0x09 its south edge  Fortree m520         193/256   0
  --   0x24 ASH GRASS       Fallarbor m522       150/256   0
  --                        JaggedPass m519      256/256   0
  --
  -- 0x02 is the only one of the four with a SPARSE silhouette, and it is
  -- one drawing: general tileset metatile 13, byte for byte the same on
  -- Route 101, 110, 112, 114, 121, Petalburg Woods, Mt Pyre, the Battle
  -- Palace corridor and Verdanturf's Battle Tent -- cover 71/256 and the
  -- row profile 0,1,1,4,5,4,4,4,5,11,5,4,5,9,7,2 identical across six
  -- tileset pairs.  Two dense base bars (rows 9 and 13) with blade strokes
  -- scattered above them: a PLAN of a grass surface that has blades in it.
  --
  -- 0x03/0x09 are not blades at all.  Long grass fills its cell -- 237 of
  -- 256, in colours the lawn never uses -- and its south edge draws the
  -- MASS'S OWN BOTTOM EDGE tapering away over its last four rows
  -- (16,16,16,16,16,16,16,16,16,15,15,12,5,2,0,0).  That is a hedge you
  -- wade into, drawn with a visible front, and standing it as tufts would
  -- build a solid opaque block over Route 119.
  --
  -- 0x24 is ash, not grass.  Route 113's ash grass is SIX GREYS AND NO
  -- GREEN (148/139/115, 172/172/139, 115/115/74, 205/205/164, 90/90/57,
  -- 230/230/205 -- the first, second and fourth of which are exactly the
  -- three colours of the plain ash ground beside it), Jagged Pass's is the
  -- same picture in mauves, and neither has a base bar, a silhouette or a
  -- repeating quadrant.  It is a rougher, deeper layer of ash LYING ON the
  -- ground.  Standing its noise up would grow a grey bristle field over
  -- Route 113: 305 quads a cell of geometry cut from a texture.
  --
  -- So: `tuft` is the only kind that gets geometry.  `mass` and `ash` are
  -- named so that they are visibly DECIDED rather than swept up with 0x02,
  -- and so the next reader can find the measurement that decided them.
  grass_kind = {
    [0x02] = "tuft",   -- MB_TALL_GRASS
    [0x03] = "mass",   -- MB_LONG_GRASS
    [0x09] = "mass",   -- MB_LONG_GRASS_SOUTH_EDGE
    [0x24] = "ash",    -- MB_ASHGRASS
  },

  -- The behaviours that are doors, ladders and shutters -- walkable, and
  -- part of the facade regardless.
  doors = {
    [0x60] = true,   -- MB_NON_ANIMATED_DOOR
    [0x61] = true,   -- MB_LADDER
    [0x69] = true,   -- MB_ANIMATED_DOOR
    [0x6C] = true,   -- MB_WATER_DOOR
    [0x8B] = true,   -- MB_CLOSED_SOOTOPOLIS_DOOR
    [0x8C] = true,   -- MB_TRICK_HOUSE_PUZZLE_DOOR
    [0x8D] = true,   -- MB_PETALBURG_GYM_DOOR
    [0xBE] = true,   -- MB_SECRET_BASE_BREAKABLE_DOOR
    [0xEA] = true,   -- MB_SKY_PILLAR_CLOSED_DOOR
  },

  -- ---------------------------------------------------------------------
  -- HOW FAR A BRIDGE STANDS OVER WHAT IT SPANS, in courses.
  --
  -- Emerald states this outright and it is easy to miss: the bridge
  -- behaviours are an ORDERED HEIGHT INDEX. MetatileBehavior_GetBridgeType
  -- maps MB_BRIDGE_OVER_POND_LOW / _MED / _HIGH to 0 / 1 / 2, which is why
  -- Route 120 carries a low bridge across its southern pond and a high one
  -- across the northern half of the same water.
  -- ---------------------------------------------------------------------
  bridge_lift = {
    [0x70] = 2,   -- MB_BRIDGE_OVER_OCEAN -- Route 110's cycling road
    [0x71] = 1,   -- MB_BRIDGE_OVER_POND_LOW
    [0x72] = 2,   -- MB_BRIDGE_OVER_POND_MED
    [0x73] = 3,   -- MB_BRIDGE_OVER_POND_HIGH
    [0x7A] = 2, [0x7B] = 2,   -- the MED bridge's two edge pieces
    [0x7C] = 3, [0x7D] = 3,   -- and the HIGH bridge's
    [0x7F] = 2,   -- MB_BIKE_BRIDGE_OVER_BARRIER
    [0x78] = 2,   -- MB_FORTREE_BRIDGE -- the rope walk between the houses
  },

  -- HOW MANY COURSES A SPAN RIDES ABOVE THE STOREY IT IS ON.  STATED.
  --
  -- Reported: "the bike path isnt tall enough needs to be about 2 blocks
  -- taller".  This number is the REPORT'S, not a measurement, and it is
  -- written here rather than dressed up as one.  What was looked for and not
  -- found, so nobody re-derives it:
  --
  --   * `bridge_lift` already states the cartridge's own answer and it is the
  --     height the road ALREADY has -- MB_BRIDGE_OVER_OCEAN is 2, and
  --     `Gen3.groundHeight`'s causeway arm and `levelGen3Decks`' elevation
  --     rank independently arrive at the same 32px.  The ROM says two
  --     courses and the road is at two courses.
  --   * the DRAWING states less, not more: the road's south fascia is ONE
  --     cell row of art (metatile 774/777 on Route 110's row 58) against 36px
  --     of exposed side at the height it already stands, and the timber piers
  --     under it are drawn about a cell and a half tall.  Raising the deck
  --     puts MORE side under it than Emerald ever drew, not less.
  --
  -- So there is no derivation here and none is claimed.  It is keyed on
  -- MB_BIKE_BRIDGE_OVER_BARRIER (0x7F) -- Emerald's own word for a bike
  -- bridge that flies over something that would otherwise stop you, and the
  -- one behaviour in Hoenn that names the Seaside Cycling Road and nothing
  -- else: 6 cells, all of them inside the single 598-cell deck run on Route
  -- 110, and no other map in the region lays one.  Route 119's two
  -- MB_BRIDGE_OVER_OCEAN spans (10 and 6 cells), Route 120's rope bridges,
  -- Fortree's walkway, Shoal Cave's two decks and Victory Road's crossings
  -- state no 0x7F and are not touched.
  span_freeboard = {
    [0x7F] = 2,   -- MB_BIKE_BRIDGE_OVER_BARRIER -- the cycling road
  },

  -- ---------------------------------------------------------------------
  -- PER-TILESET AND PER-MAP OVERRIDES
  --
  -- Everything above is true of all of Hoenn.  These are the places where
  -- the ART says something the data does not, and they are deliberately
  -- few: the behaviour byte, the layer type and the elevation field between
  -- them get the whole region standing correctly, and a profile's job is
  -- only to correct a proportion.
  --
  -- Resolution order is primary tileset, then secondary, then the map by
  -- name (lib/Gen3.lua) -- most general to most specific, each overlaying
  -- the last.  Names are pokeemerald's, resolved through data/gen3_maps.lua,
  -- because the engine keys a pair by ROM ADDRESS and an address is a fact
  -- about one cartridge rather than about Hoenn.
  --
  -- Keys a profile may set:
  --   course      pixels per elevation RANK (default 16, one cell).  Emerald
  --               labels its levels rather than counting them -- a map uses
  --               whichever of 0..15 it likes and skips the rest -- so the
  --               mod ranks the levels a map actually uses and spaces the
  --               ranks evenly.  This is the spacing.
  --   behaviour   rows to add or replace for this tileset only; `false`
  --               withdraws a row and sends the cell back to the structural
  --               rule.
  --   bridge_lift as above, per tileset.
  --   cover       the class a blocked cell with above-player art becomes.
  -- ---------------------------------------------------------------------
  tilesets = {

    -- SOOTOPOLIS: a city built down the inside of a volcanic crater.  The
    -- most COVERED-heavy outdoor map in the game -- 2914 of its 3600 cells
    -- against 681 NORMAL -- because almost everything in it is a terrace the
    -- player walks over.  Its verticality is NOT in the elevation field:
    -- only ONE real level appears (3), with everything else 0 or the surf,
    -- so the crater is entirely in the art and the run measurement is what
    -- builds it.  What the profile is for here is the rim: MB_MOUNTAIN_TOP
    -- is the crater WALL, two courses rather than one, or the city sits in a
    -- saucer instead of a caldera.
        -- SLATEPORT: the open-air market.  The awning metatiles -- canopy top
    -- and hanging skirt -- are stood up as floating decks on the drawn
    -- poles (Structures.buildGen3Stalls).
    gTileset_Slateport = {
      stall_awning = { 517, 525, 526, 527, 551, 565, 559, 760, 761, 762 },
    },

    -- EVERY POKEMON CENTER'S STAIRCASE (34 maps share this tileset).
    -- The 1F flight, a 2x3 block in the west wall.  Emerald says nothing
    -- about it: five of its six cells are MB_NORMAL and walkable, so the
    -- steps lay painted flat on the floor, and the sixth -- 648 -- tripped
    -- the furniture detector and stood up as a 12px TABLETOP in the middle
    -- of them.
    --
    -- The drawing says which way it climbs.  Read as luminance, the treads
    -- are horizontal bands in three column groups (x0-6, x8-14, x16-30),
    -- each group starting three rows lower than the one to its west: a
    -- flight climbing WEST, into the wall.  `flights` re-grounds the region
    -- as a ramp of tile-column steps (Structures.buildGen3Flights) so it is
    -- walked up instead of walked over.
    --
    -- The 2F half (664/665/672/673/680/681) is the same well seen from
    -- above and DESCENDS; a hole cut below an interior floor needs the room
    -- plane to close around it, which is not built, so 2F is left flat --
    -- with 672 pinned `ground` below so it at least stops being a slab.
    gTileset_PokemonCenter = {
      flights = {
        { dir = "w", tiles = { 640, 641, 648, 649, 656, 657 } },
      },
    },

gTileset_Sootopolis = {
      behaviour = { [0x0C] = "cliff" },   -- MB_MOUNTAIN_TOP
      -- Every roof in the crater is drawn as a dark CONE over an octagonal
      -- body.  Built as sheds they lean into squat lozenges; this says the
      -- pointed style exists here, and the octagon trim picks which
      -- buildings actually taper (Structures: tent test).
      tent_roof = true,
    },

    -- LAVARIDGE: Mt Chimney, Jagged Pass and the Fiery Path.  The volcano's
    -- flank is drawn as one continuous scree -- the same rock motif the
    -- whole way down, with no contour band for the terrace reconstruction
    -- to chain into levels.  Given nothing to stop at it levelled Jagged
    -- Pass almost entirely to its ceiling: 26 of 46 rows modal 80px, 9 more
    -- at 0, in no order.  A plateau with pits in the path, not a descent.
    --
    -- The ROM states ONE walkable level for both Jagged Pass and Mt Chimney
    -- (levels=1, every walkable cell ELEV_DEFAULT), so one level is the
    -- faithful answer.  The relief that IS stated -- the ledges you hop
    -- down, the rock walls, the cable-car pylons -- still builds.
    -- gTileset_Lavaridge (Jagged Pass, Mt Chimney, Lavaridge, Route 112).
    -- `drawn_terraces = false` USED TO BE HERE, on the grounds that the ROM
    -- reports levels=1 for these maps -- every walkable cell ELEV_DEFAULT --
    -- so one plane was the faithful answer.  That is still true of the
    -- CARTRIDGE, and it is why the flag was right when the terrace pass
    -- could only raise whole tiers by one course each.
    --
    -- It is not right for the STAIRS.  Mt Chimney draws an eight-cell flight
    -- across row 33 and five grated step plates through its ash banks, and
    -- with the pass switched off entirely none of them could climb: the
    -- steps lay flat on flat ground, leading nowhere, which is exactly what
    -- the drawing does not say.  A flight cannot raise anything unless the
    -- ground beyond it rises too, so stairs and terraces stand or fall
    -- together and the gate has to come off for either to work.
    gTileset_Lavaridge = {},

    -- EVER GRANDE: the Victory Road approach and the League plateau, with
    -- 96 cells of waterfall.  Three real levels (3, 5, 7) and 2069 cells of
    -- scenery at elevation 0 -- the cliffs.  Same rim treatment as
    -- Sootopolis: the plateau's edge is a wall of rock, not a kerb.
    gTileset_EverGrande = {
      -- height from the cartridge, not the drawing (see the maps table).
      -- One map uses this tileset, so pinning it here is safe.
      elevation_height = true, drawn_terraces = false,
      behaviour = { [0x0C] = "cliff" },
    },

    -- METEOR FALLS and the caves: MB_CAVE is the mouth, not the floor, and
    -- the rock around it is drawn as one mass.  Nothing to correct -- listed
    -- so the next person does not have to re-derive that.
    -- THE CAVES.  Their blocked rock is a mass with a top, not a building
    -- facade -- see Structures.buildGen3RockPlateaus for the measurement
    -- that made this necessary (Granite Cave 1F read `fromRepeat` with a
    -- 16px period, because the floor's hatch texture has one).
    --
    -- ...and `use_elevation`, which is the OTHER half of a cave.  Indoors
    -- the elevation field is normally discarded, because indoors Emerald
    -- uses it for sprite priority -- which side of a bed you draw on -- and
    -- ranking that into courses stands a step in the middle of a carpet.
    -- A cave is the exception: its levels are real terraces.  Measured, the
    -- difference is unmistakable.  Victory Road 1F carries 206 cells at
    -- level 4 in ten connected REGIONS, the largest 61 cells; Meteor Falls
    -- 36 in two; Shoal Cave 66 in one.  Pokemon Center 1F carries exactly
    -- ONE cell at level 4 -- that is the priority flag, and it stays
    -- discarded.
    --
    -- Turning this on gives three things at once: the walkable floor sits
    -- at its own tier instead of all on the datum, so a terrace's ground is
    -- level with the cliff edge beside it; ELEV_MULTI cells (Victory Road
    -- has 30, Meteor Falls 6) become real bridge decks a course over what
    -- they span; and because entities carry their own elevation, a walker
    -- passes UNDER those bridges instead of being lifted onto them.
    gTileset_MeteorFalls = { rock_plateau = true, use_elevation = true },
    gTileset_Cave = { rock_plateau = true, use_elevation = true },

    -- PACIFIDLOG: a town of rafts.  263 of its 800 cells are
    -- MB_MOUNTAIN_TOP -- the rocky islets the houses stand on -- and 294 are
    -- open ocean.  The logs themselves are already their own class; what
    -- matters here is that the islets stay one course, because a town that
    -- floats should not have cliffs in it.
    gTileset_Pacifidlog = {},

    -- FORTREE: houses in the canopy, joined by rope bridges.  Two real
    -- levels, 3 and 4, and the 52 cells at level 4 ARE the walkway -- the
    -- cartridge even gives the player a higher sprite priority up there so
    -- they draw over the treetops.  One course of separation would put the
    -- walkway INSIDE the canopy it is supposed to cross, so the step is two.
    -- Route 119 and Route 120 share this tileset and are ordinary ground, so
    -- the override is on the CITY (see `maps` below), not here.
    gTileset_Fortree = {
      -- ------------------------------------------------------------------
      -- A TREE HUT IS A BUILDING, AND IT IS FIVE CELLS WIDE.
      --
      -- MOTIVATED BY FORTREE CITY (MAP_G00_N04) AND ITS SIX TREE HUTS:
      -- House1 (8..12, 1..3), House2 (15..19, 1..3), House3 (23..27, 1..3),
      -- House4 (29..34, 0..2), House5 (10..14, 11..13) and the Decoration
      -- Shop (34..39, 11..13).  Reported as huts three cells wide, one
      -- course tall, with their roofs meshed as separate treetops.
      --
      -- Emerald draws each hut as THREE cell rows of one bespoke 5x3 block:
      --
      --     198  548 549 550  198     the green frond roof, three cells
      --     555  556 557 558  559     upper course: bamboo bay | wall | bay
      --     563  564 565 566  567     lower course: bay | wall DOOR wall | bay
      --
      -- over a 5-cell plank veranda (571/572/573/574/575) and its posts.
      -- Every one of the ten ids above is laid SIX times -- once per hut --
      -- and NOWHERE ELSE IN HOENN (measured over all 518 maps: 548/549/550,
      -- 555/559 six each, 563/567 nine each -- House4 and House5 draw a
      -- second veranda row out of 563/567 -- and every occurrence is on
      -- MAP_G00_N04.  The other three maps that pair with this tileset,
      -- Route119, Route120 and FarawayIsland_Interior, place none of them).
      --
      -- WHY THE GENERIC READERS CANNOT SEE IT, and why this table has to.
      -- data/gen3_metatiles.lua reads the four END BAYS and the roof as
      --
      --     [548] [549] [550]          surface green cap 16 face 0 motif F
      --     [555] [559] [563] [567]    surface green cap 16 face 0 motif T
      --
      -- character for character the reading of gTileset_General's own tree,
      -- 198/199 -- leafy texture, drawn green, solid, no drawn face.  That
      -- test is RIGHT everywhere else in Hoenn and is not touched: the
      -- bamboo slats of a hut's end wall really are painted the same yellow-
      -- green as the canopy behind them, and no reading of the sixteen pixel
      -- rows separates them.  Only the cartridge's own layout does -- these
      -- ten ids, in this tileset, always drawn as one block around a warp --
      -- and this file is where the cartridge's own layout is written down.
      --
      -- Gen3.lua's `foliageCell` says the opposite in its own comment ("Its
      -- corner pieces 555/559/563/567 and the forest around them are
      -- `surface / GREEN / cap 16 / face 0`, the same reading as the General
      -- tileset's own tree") and REFUSES these four columns for that reason.
      -- That comment is right about the ART and it stays; what it could not
      -- know is which metatiles are the hut's own.  The rule it states --
      -- "a flank column every row of which is drawn as foliage is not the
      -- building" -- keeps every cell of its blast radius (Route 104's
      -- Petalburg Woods entrance, Route 118's tunnel mouth, Lavaridge's
      -- east column): this list is SEVEN IDS IN ONE TILESET and overrides
      -- it only on them.
      --
      -- NOT A `metatiles` CLASS PIN, deliberately.  A pin names a class and
      -- marks the cell AUTHORED, and an authored cell leaves the structural
      -- flood (see the METATILE PINS header below) -- so pinning the bays
      -- `wall` would give each of them its own 16px box and the five-cell
      -- facade this exists to build would come apart again.  What is needed
      -- is narrower: not "this cell is a wall" but "this cell is not
      -- FOLIAGE, it is part of the building beside it", which leaves the
      -- flood, the run and the height model to decide the rest.
      --
      -- "roof" vs "wall" is the row the id draws, and `foundGen3Buildings`
      -- uses the count of roof rows to split a facade from the pitch on top
      -- of it.  PRESENTATIONAL ONLY: nothing here is read by collision,
      -- warps, elevation flags, scripts or encounters.
      --
      -- Keyed on the SECONDARY tileset, which is the only slot Emerald ever
      -- gives gTileset_Fortree (all four of its maps pair it under
      -- gTileset_General), so ids 548..567 are in the 512..1023 secondary
      -- bank on every one of them.
      building_art = {
        [548] = "roof", [549] = "roof", [550] = "roof",
        [555] = "wall", [559] = "wall", [563] = "wall", [567] = "wall",
      },
    },

    -- UNDERWATER: the seabed.  Every cell of it is under the sea, so the
    -- water class must not fire -- MB_NORMAL down here is the floor you swim
    -- over, and treating the map as water would recess the whole thing and
    -- leave nothing to stand on.
    gTileset_Underwater = {},

  },

  -- ---------------------------------------------------------------------
  -- METATILE PINS: the only way to say "that cell is a fridge".
  --
  -- The behaviour byte cannot say it. Every kitchen unit, every chair, every
  -- table and the wall behind them is MB_NORMAL, because the byte answers
  -- what KIND OF SURFACE a cell is and furniture is not a kind of surface.
  -- The layer type cannot either: it separates wall from furniture across
  -- most of a room but not all of it, and a rule that flattens a few wall
  -- cells is worse than no rule at all.
  --
  -- So interiors are hand-pinned per tileset, exactly the way the Gen 1 and
  -- Gen 2 profiles pin tile ids in data/voxel_heights.lua. A Gen 3 metatile
  -- id is stable within its tileset, and the key here is the tileset's
  -- pokeemerald NAME, resolved through data/gen3_maps.lua.
  --
  -- TWO RULES LEARNED THE HARD WAY:
  --
  -- 1. PIN THE FRONT ROW, NOT THE WALL BAND. Emerald draws a kitchen as two
  --    rows -- the upper doors up in the wall band, the carcasses in the row
  --    below -- and both are blocked. Unpinned they all flood into ONE region
  --    and `buildVolume` measures a single run three cells deep and 48px
  --    tall: the wall dragged forward around the fridge. Pinning the FRONT
  --    row takes it out of the flood, so the wall measures its own two cells
  --    and the units stand out in front of it. Pinning the wall band as well
  --    would be worse than doing nothing -- an authored cell leaves the
  --    flood, so each wall cell would become its own 16px box and the wall
  --    would stop being a wall.
  --
  -- 2. A PINNED CELL NEED NOT BE BLOCKED. Emerald leaves chair cells
  --    PASSABLE -- you walk over them -- so the passability guard that
  --    normally stops a walkable cell becoming furniture is bypassed for a
  --    pin. Stepping onto a chair and standing 8px up is what the drawing
  --    depicts.
  --
  -- Classes: chair / tabletop (drawn from above, art on the top face);
  -- worktop / sink / appliance / cabinet / tv (drawn face-on, art folds up
  -- the south face); bed (from above, low).
  --
  -- 3. A PIN NAMES A CLASS, AND A CLASS IS ONE HEIGHT FOR ONE WHOLE CELL.
  --    That is the limit of this table, and it is worth stating here because
  --    the next thing someone will want to pin is an object whose edge is a
  --    CURVE cutting across cells.  RUSTBORO CITY'S WATER FOUNTAIN --
  --    RustboroCity (27..29, 38..40) -- is exactly that: a grey stone
  --    OCTAGONAL basin inscribed in a 3x3 block, so its corner cells are part
  --    fountain and part street and no single height describes either of
  --    them.  No row below can say it, and a row that tried would raise the
  --    street with it.  It is authored as a SHAPE instead -- a plan polygon
  --    and three drawn profiles -- in data/gen3_palings.lua under `basins`,
  --    which is the file this mod keeps for authored shapes matched per
  --    tileset, and it is built by Structures.buildGen3Basins.
  --    (g3-basin-311.)
  metatiles = {

    -- THE WATER UNDER ROUTE 119'S PLANK WALKWAYS IS STILL WATER.
    --
    -- MOTIVATED BY ROUTE 119'S UPPER RIVER, (10..17, 8) AND (11..15, 11) --
    -- the two rows of pier cells that cross the basin above the waterfall,
    -- part of the same report as the 518/519 pin on gTileset_Fortree below:
    -- "all water at the top of the waterfall should be the same level as the
    -- top of the waterfall".
    --
    -- 245 IS OPEN WATER WITH TWO POSTS STANDING IN IT.  The cell draws the
    -- pale underside of a plank deck across its top rows and two dark piles
    -- dropping from it into darker water; every other pixel is the river's
    -- own animated ripple, and all four of its bottom quadrants sit in one of
    -- the pair's animation runs.  Its NEIGHBOURS along the same walkway --
    -- 237, 241, 242, 251, 252, 253 -- are the same drawing with a rail
    -- behaviour on them (MB_*_RAIL, 0xD3..0xD6) and already resolve `bridge`.
    -- 245 is the one Emerald leaves at MB_NORMAL and BLOCKS, because it is
    -- the gap under the deck rather than the deck, so it fell through to the
    -- structural rule: blocked + MB_NORMAL is a wall, and a wall outdoors is
    -- landscape rock.
    --
    -- MEASURED, before this pin and with 518/519 already water: the 17 cells
    -- of 245 in the basin stood at 0 and 16 while the water either side of
    -- them lay at 12 and 32 -- two rows of rock stubs damming one lake into
    -- three, which is the thing the report is about.  `standGen3Water` floods
    -- by CLASS, so a row of cliff across a body of water is a wall in it.
    --
    -- NOT 250, WHICH IS THE SAME DECK LANDING ON ROCK: half that cell is the
    -- bank's brown stone and `cliff` is what it is.  4 cells, left alone.
    --
    -- DERIVED over all 518 maps: metatile 245 of this primary is laid on 22
    -- cells in the whole of Hoenn and every one is on Route 119 -- the pier
    -- art is in the shared primary but only this route draws it.  (236, 250
    -- and 252 measure 1, 4 and 4 cells, also Route 119 only.)  Nothing
    -- outside Route 119 can move.
    gTileset_General = {
      [245] = "water",
    },

    -- LITTLEROOT TOWN's secondary tileset, which is where Professor Birch's
    -- lab lives (LAYOUT_LITTLEROOT_TOWN is gTileset_General over this one).
    gTileset_Petalburg = {
      -- ---- PROFESSOR BIRCH'S LAB, roof ---------------------------------
      -- The ventilation drum on the lab roof: a 2x2 block of drawing, the
      -- mouth ellipse and the upper barrel in 578/579 and the lower barrel
      -- and its skirt in 586/587. The lower pair sits ON the roof (the
      -- building's first row) and the upper pair is drawn above it in the
      -- walkable row behind, which is how Emerald draws everything tall.
      -- Left unpinned it lay flat: a grey rectangle inset into the roof
      -- with the mouth squashed into a bowl.
      --
      -- ONLY THE UPPER PAIR IS PINNED. The hull is carved from all four
      -- cells of art regardless (a 32px canvas reads the 2x2 block under its
      -- anchor), and pinning the lower pair as well would take them out of
      -- the structural flood -- which is the lab's own roof, and it would
      -- have come away with a two-cell hole where the chimney stands.
      [578] = "chimney", [579] = "chimney",
    },

    -- BRENDAN'S AND MAY'S HOUSE (4 maps: both children's houses, both floors).
    -- Verified against the real layouts: 1F is layout 54 (11x9), 2F is
    -- layout 55 (9x8), both on primary gTileset_Building.
    gTileset_BrendansMaysHouse = {

      -- ---- 1F, the kitchen run along the north wall --------------------
      -- Row 1 is the upper half of each unit and sits IN the wall band; it
      -- is deliberately NOT pinned (see rule 1). Row 2 is the carcass, and
      -- the fold walks north up the column so each box wears its own art low
      -- and the unit above it high.
      [568] = "appliance",  -- fridge: 560 is its upper door
      [569] = "sink",       -- basin over cupboard doors; 561 is the tap
      [570] = "worktop",    -- counter with a pot on it
      [571] = "cabinet",    -- glass-fronted dresser; 563 its upper shelves
      [572] = "cabinet",    -- and its right half

      -- THE LIVING-ROOM TELEVISION, and it was pinned `worktop` -- "the long
      -- white counter that stands out in the room" -- on a first pass that
      -- read it from its position rather than its picture. It is a white
      -- screen in a wood-framed cabinet, two cells wide, and calling it a
      -- kitchen counter stood it 18px tall in the middle of the floor with
      -- its top face to the camera: flat, grey, and no screen anywhere. The
      -- art is unambiguous once you look at it.
      [576] = "tv",
      [577] = "tv",

      -- ---- THE TELEVISION, ALL OF IT ------------------------------------
      -- IN-GAME LOCATION: BrendansHouse_1F (4, 4) and MaysHouse_1F (6, 4) --
      -- the grey CRT beside the white box in the living room -- and
      -- BrendansHouse_2F (4, 1) / MaysHouse_2F (4, 1) in the bedrooms.
      -- Reported as "the computer monitor should be a per pixel 3d model of
      -- the computer same with the 1.5block tall tv".
      --
      -- WHAT WAS WRONG WAS NOT THE MODEL, IT WAS HOW MUCH OF THE PICTURE THE
      -- MODEL HAD.  The television is metatile 2 of the shared primary
      -- gTileset_Building, behaviour 0x86 MB_TELEVISION, so it already
      -- resolves `console` -- the forced per-pixel standee pool -- and
      -- already stands as a real object.  MEASURED on BrendansHouse_1F before
      -- this change: 544 quads, 256 of them the front face, y 0..16, z 71..81.
      -- Sixteen pixels of a drawing that is TWENTY-SEVEN pixels tall.
      --
      -- WHERE THE OTHER ELEVEN ROWS ARE.  DERIVED off the art, cell by cell:
      -- the cabinet's dark top band is the LAST THREE ROWS of the cell above
      -- (metatile 578 in Brendan's living room, 582 in May's) and the two
      -- pale blue speaker panels are the FIRST EIGHT ROWS of the cell below
      -- (586 / 691 downstairs, 605 in both bedrooms).  3 + 16 + 8 = 27.
      -- Those two cells are WALKABLE FLOOR, so their eleven rows were being
      -- painted flat on the floorboards while the middle cell stood up --
      -- which is this project's standing complaint about a picture painted
      -- on a surface instead of a standing object, one cell above and one
      -- cell below every television in these four rooms.
      --
      -- A PIN IS THE WHOLE FIX; NO NEW MACHINERY IS NEEDED.  The forced
      -- billboard region floods over neighbouring cells that share the CLASS
      -- (lib/Structures.lua: "same CLASS, not just billboard art"), so
      -- classing the top and the base `console` too pools all three cells
      -- into one region and `buildObject` cuts ONE silhouette out of the
      -- pooled drawing -- 8-connected, so the cabinet stays whole across the
      -- cell seams -- and `console`'s one-object contract drops the loose
      -- scraps (May's rug edge at the bottom of 691, the floorboard nail
      -- dots).  The claimed cells are repainted with the commonest flat
      -- neighbour, which is the floorboard, so the floor closes behind it.
      --
      -- THESE FOUR IDS ARE THE OBJECT AND NOTHING ELSE, which is what makes
      -- pinning a walkable floor cell safe here.  MEASURED over all 518 maps:
      -- 578, 582 and 586 lay ONE CELL EACH, on one map each, and 605 lays
      -- two -- the same cell of the two bedrooms.  Not one of them is a
      -- generic floor id, and no other cell in Hoenn can move.
      --
      -- 691 IS MAY'S LIVING-ROOM BASE AND IS DELIBERATELY NOT PINNED.  It is
      -- the same drawing as Brendan's 586 and the pin would be the same pin,
      -- and it cannot work: the FLIGHT DETECTOR has already claimed that cell.
      -- Its two pale blue speaker panels are banded light-then-dark like a
      -- run of treads, so `Structures.buildStairs` marks the cell `art =
      -- "stair"`, and the billboard region pools only cells whose art is
      -- `billboard` -- so the pinned cell would sit outside the television's
      -- region and take no part in it.  MEASURED, with the pin in: May's set
      -- stayed 19 world pixels while Brendan's went to 27, and the only
      -- thing the pin changed was to lift that misread cell from h = 0 to
      -- `console`'s h = 16.  MEASURED over all 518 maps with the pin in, it
      -- is also the ONLY pinned cell in Hoenn the flight detector marks --
      -- so no chair pinned below can meet this, and the misreading is a
      -- separate defect in its own right (it is what stands a staircase in
      -- May's living room today, pin or no pin) and not this round's report.
      -- May's television therefore stands 19 and Brendan's 27.
      --
      -- 598 IS DELIBERATELY NOT PINNED, and it is the bedrooms' top three
      -- rows.  It is in the room's WALL BAND: blocked, and MEASURED at 256
      -- of 256 pixels through this map's carve, because a bedroom's floor set
      -- is its floorboards and the wall behind is not in it.  Rule 1 at the
      -- head of this section says why that must stay unpinned -- an authored
      -- cell leaves the flood and the wall stops being a wall -- and the
      -- carve says the pin could not work anyway: there is no background in
      -- that cell for the object to be cut out of.  So the bedroom sets
      -- stand 24 world pixels (1.5 cells, exactly the report's number) and
      -- the living-room sets stand 27; the bedrooms keep three rows of
      -- cabinet top drawn on the wall directly behind the model, where they
      -- line up.
      [578] = "console", [586] = "console",   -- Brendan's 1F, above / below
      [582] = "console",                      -- May's 1F, above (see 691)
      [605] = "console",                      -- both 2F bedrooms, below

      -- ---- 1F, the dining set on the blue rug --------------------------
      -- The cloth is a 2x2 of drawing; the four chairs flank it, and all
      -- four chair cells are passable.
      [538] = "tabletop", [539] = "tabletop",
      [546] = "tabletop", [547] = "tabletop",
      [537] = "chair",    [540] = "chair",
      [545] = "chair",    [548] = "chair",
      -- ...AND THE TWO THIS SET MISSED.  IN-GAME LOCATION: MaysHouse_1F
      -- (5, 6) and (8, 6) -- 2 cells each, both passable.  DERIVED: 704 and
      -- 707 draw the SAME OBJECT as 537/545 and 540/548 -- their layer-2
      -- art (the half of a Gen 3 metatile that carries the furniture, over
      -- the floor on layer 1) is byte-identical to them, which is why the
      -- ids differ at all: the same chair baked over a different floor.
      -- Her room lays two of the four dining chairs from its own ids and
      -- they were left painted on the rug.
      [704] = "chair",    [707] = "chair",

      -- ---- 2F -----------------------------------------------------------
      -- The bed is 3x2 cells of top-down drawing.
      [643] = "bed", [644] = "bed", [645] = "bed",
      [651] = "bed", [652] = "bed", [653] = "bed",

      -- THE GAME SYSTEM, and it is not a television: the handheld on its
      -- stand under the shelf.  IN-GAME LOCATION: BrendansHouse_2F (3, 2)
      -- and, on its own id, MaysHouse_2F (5, 2).
      --
      -- 614 AND 615 ARE ONE DRAWING.  DERIVED: the two carve to the same 89
      -- pixels row for row, in the same four islands (83 of game system and
      -- three 2-pixel floorboard nail dots).  Brendan's cell was pinned and
      -- May's was not, so the same object stood as a 12px model in one
      -- bedroom and was painted flat on the floor in the other.
      --
      -- `cutout` -- "paper: one voxel, pure profile", `PINNED_DEPTH.cutout
      -- = 1` -- because a flat 2D sprite standing where the thing is drawn is
      -- what was asked for, and because `cutout` carries the same one-object
      -- contract `console` does: the drawing is ringed by the floor it stands
      -- on, and the nail dots in that floor must not be extruded with it.
      --
      -- NOT `tv` (12), which is in JOINERY_H and lays the picture on a lid.
      -- That pin was right when the ask was "table height"; this one is a
      -- different ask about a different object, and the two other cells that
      -- carry `tv` -- 576/577, the white cabinet in both living rooms -- keep
      -- it.
      --
      -- THE WALL BAND ABOVE STAYS UNPINNED, and here the measurement says so
      -- rather than only the rule: 613 and 599 carve to 256 of 256 pixels,
      -- because a bedroom's floor set is its floorboards and the wall behind
      -- the shelf is not in it.  A cutout pinned there would stand the whole
      -- cell as a solid 16x16 panel.  So the upper half of the game system
      -- stays drawn on the wall, exactly as before.
      [614] = "cutout", [615] = "cutout",

      -- the stool at the shelves
      [610] = "chair",

      -- ---- MAY'S 2F, which shares this tileset and NONE of the metatiles
      -- above. Her room is drawn from its own set, so every pin written for
      -- Brendan's room missed it and the whole floor came out as wall with
      -- one stray object -- checked against the art, cell by cell.
      --
      -- The bed stands alone in the south-east corner. As the only isolated
      -- blocked cell in the room it was being read as a SIGNPOST: a thin
      -- board on a stick where the bed should be.
      [657] = "bed",

      -- the shelf unit in the north wall band, with its things on it
      [601] = "cabinet",
    },

    -- PROFESSOR BIRCH'S LAB, and the three other rooms drawn from the same
    -- tileset: Route114_LanettesHouse, Route119_WeatherInstitute_1F and _2F.
    -- gTileset_Lab had NO block here at all, so every piece of furniture in
    -- those rooms fell to the structural rule, and indoors that rule is the
    -- blocked-run flood.
    --
    -- MEASURED, on the lab itself: rows 0 and 1 are ONE run of blocked cells
    -- standing at h = 32 -- the computer, the two book desks and the corner
    -- plant flooded in with the plain wall -- and the east wall's run swallows
    -- the chairs at (11..12, 2..3).  That is the report, twice over: "the
    -- books are pulling the wall in in the corner of the lab" and "the plant
    -- is pulling the wall in too".  A run wears its picture UP ITS SOUTH
    -- FACE, so a desk top drawn in plan is stood on its edge and the wall it
    -- is drawn on comes forward with it.
    --
    -- WHY THE DETECTOR CANNOT REACH THEM, so nobody re-derives it: the indoor
    -- furniture detector is gated on "FURNITURE IS A DISCRETE OBJECT; A WALL
    -- IS A RUN" (BOULDER_RUN_MAX = 8, lib/Gen3.lua).  That gate is why the
    -- lab's own free-standing bookcases at (0..3, 6..7) already stand as 32px
    -- carcasses, and why nothing inside a 32-cell wall run ever will.  A pin
    -- is the only instrument that reaches these cells.
    --
    -- ...AND WHICH ROW.  Rule 1 above says pin the FRONT row, not the wall
    -- band, and that rule is about the KITCHEN case -- two blocked rows, both
    -- of them the object.  These benches have ONE blocked row: the bench top
    -- is drawn in the wall band and its legs are drawn in the walkable row
    -- below it (546/563/574, all passable, all left alone).  There is no
    -- front row to pin.  The plain wall ids -- 520, 521, 522, 530, 531, 572 --
    -- are NOT pinned and go on flooding as the wall.  DERIVED: after these
    -- pins the north wall's row 0 still measures one run of 32 across all
    -- thirteen cells.
    --
    -- AND WHAT A PIN COSTS ITS NEIGHBOURS, which is the reason four of the
    -- ids below are here at all.  A pinned cell LEAVES the blocked run
    -- (`if ctx.pins[m] then return false end` in `blockedRun`), so pinning
    -- can drop a neighbouring run under BOULDER_RUN_MAX and re-arm the round
    -- carve on cells nobody asked about.  Measured cell by cell over all four
    -- maps, before and after: the desks, the computer, the green chairs and
    -- the corner plant move nothing but themselves; 584 would flip the lab
    -- bench cells 560 and 576 from `tabletop` to `cylinder`, and 558 would
    -- flip 571 and 587 the same way.  Those four ids already resolve
    -- `tabletop` on all six cells they lay -- they are the workbench units --
    -- so they are PINNED TO THE ANSWER THEY ALREADY HAVE, which both states
    -- what they are and stops it depending on how big the run around them
    -- happens to be.  With them in, the whole block moves 18 cells and not
    -- one other cell in Hoenn.
    gTileset_Lab = {

      -- ---- THE COMPUTER, and the bench it stands on ---------------------
      -- IN-GAME LOCATION: LittlerootTown_ProfessorBirchsLab (3..4, 1) and
      -- Route114_LanettesHouse (7..8, 1) -- 4 cells in Hoenn.  "the computer
      -- in birches lab is showing as a cylinder" was answered last round by
      -- stopping the round carve lathing them; this is the other half, which
      -- is that they were left standing as wall.
      --
      -- `console` is this file's own word for A MACHINE STANDING ON
      -- FURNITURE: the per-pixel standee pool, `PINNED_DEPTH.console = 10`,
      -- with the one-object contract that keeps only the largest connected
      -- drawing "because the drawing is ringed by the furniture it sits on".
      -- That is this object exactly -- a tower and a monitor on a yellow
      -- bench -- and a per-pixel model of it is what was asked for.
      --
      -- NOT `tabletop` like the two book desks below, DERIVED off the carve:
      -- 538 keeps 233 of its 256 pixels and 539 keeps 208, because the
      -- computer fills the cell from row 0 down to the bench top at row 14.
      -- Extruded from above at 12, that whole picture -- monitor, screen and
      -- tower -- would be laid flat on a lid.
      --
      -- The computer's own TOP is drawn in the wall band above it (530/531,
      -- rows 10..15) and stays where it is drawn.  Same compromise the 614
      -- pin already ships and for the same reason: the wall must stay whole.
      -- Pinning 530/531 too would vacate two cells of row 0 and re-open the
      -- hole in the lab's north wall that `blockedRun` was written to close.
      [538] = "console", [539] = "console",

      -- ---- THE TWO BOOK DESKS -------------------------------------------
      -- IN-GAME LOCATION: the lab's (6..7, 1) and (8..9, 1) -- the desk with
      -- the papers and the red book, and the desk with the red book and the
      -- stack of blue ones -- plus 524 again in Lanette's House at (6, 1).
      -- 5 cells in Hoenn.  "the books are pulling the wall in".
      --
      -- DRAWN FROM ABOVE, which is what picks the class: the yellow hatched
      -- top fills rows 4..14 of each cell and the front edge is the single
      -- brown row 15.  The carve agrees and says where the wall stops --
      -- DERIVED, it drops rows 0..3 of 523, 524 and 525 (the wall band) and
      -- keeps 177, 178 and 179 pixels of desk; 526 keeps 203 because the blue
      -- book stack rises into rows 1..3.
      --
      -- `tabletop` is the class for a surface drawn from above with things on
      -- it -- the dining cloth above, MB_ROULETTE, Mossdeep's game tables --
      -- and it is in `JOINERY_H`, so each cell is extruded from its OWN
      -- carved silhouette rather than boxed.  TWELVE is that class's shipped
      -- waist height on 1,561 cells: STATED by the class, not measured here.
      [523] = "tabletop", [524] = "tabletop",
      [525] = "tabletop", [526] = "tabletop",

      -- ---- THE CHAIRS WITH BLUE BACKS ------------------------------------
      -- IN-GAME LOCATION: the lab's (11..12, 2) on 666 and (0, 10..11) on
      -- 584 -- 4 cells.
      --
      -- ONE DRAWING, two ids.  DERIVED: 666 and 584 carve to the same 198
      -- pixels row for row -- the same chair on the wall band and against the
      -- west wall.  Both pairs were being read as part of a wall run.
      --
      -- DRAWN FACE-ON: the blue back fills rows 0..4 and the seat and frame
      -- rows 5..15, edge to edge.  That rules out `chair` -- DERIVED, the
      -- column-top profile is 8,5,6,0,0,0,0,0,0,0,0,0,4,5,6 and its plateau
      -- is 0, so `CHAIR_BACK_H` finds no back to raise and the chair would
      -- come out as an 8px pad, which is the "stool, not a chair" that rule
      -- was written to stop.
      --
      -- `post` is the per-pixel slab that extracts EVERY CELL ON ITS OWN
      -- (Structures' post pool).  That is what these need and `prop` is not:
      -- 584's two cells are stacked at (0, 10) and (0, 11) and their drawings
      -- touch across the cell seam, so pooled they would flood into one
      -- component and stand as a single 32px tower -- the exact failure the
      -- post pool's own comment describes for a fence line.
      --
      -- 562 IS THE SAME CHAIR AND IS DELIBERATELY NOT PINNED.  It lays the
      -- lab's third chair at (12, 3) and five more in Lanette's House, where
      -- they sit INSIDE the west wall's furniture mass.  Measured, pinning it
      -- moves 15 cells nobody asked about: eleven of Lanette's blocked cells
      -- leave their run, and her two bench machines at (6..7, 3..4) fall out
      -- of `tabletop` into `canopy` and `cylinder` -- a tree crown over a lab
      -- bench.  Holding those down needs four more pins in a room this report
      -- is not about, and even then five cells still move.  One chair left in
      -- the run is the smaller error.
      [666] = "post", [584] = "post",

      -- ---- THE GREEN CHAIRS ----------------------------------------------
      -- IN-GAME LOCATION: the lab's (4, 3), (2, 10) and (10, 10) -- three
      -- cells, one per id, and all three PASSABLE (rule 2 above).
      --
      -- DRAWN IN PLAN, and the three ids are the same chair facing three
      -- ways.  DERIVED off the carve's column-top profile, which is the very
      -- reading `CHAIR_BACK_H` makes:
      --
      --   577  -,6,5,4,4,4,4,4,4,4,4,1,0,0,1,-   plateau 4 -> back cols 11..14
      --   585  -,1,0,0,1,4,4,4,4,4,4,4,4,5,6,-   plateau 4 -> back cols 1..4
      --   569  -,-,1,0,0,0,0,0,0,0,0,0,0,1,-,-   plateau 0 -> no back
      --
      -- The first two are profile for profile the shipped dining chairs
      -- 540/548 and 537/545, so they get real backs standing over an 8px
      -- seat.  569 is the one whose back is drawn along the NORTH edge, where
      -- a column profile cannot see it, and it gets the seat alone -- stated
      -- here rather than worked around, because the rule declining IS the
      -- rule, and a per-pixel chair on the floor still beats a picture
      -- painted on it.
      [577] = "chair", [585] = "chair", [569] = "chair",

      -- ---- THE SAME GREEN CHAIRS, THREE IDS THE LAB DOES NOT LAY --------
      -- IN-GAME LOCATION: Route119_WeatherInstitute_1F (10, 5) and (13, 5)
      -- and five more cells on those two ids, plus _2F (0, 4) -- 13 cells
      -- over 3 maps, every one of them passable.
      --
      -- DERIVED, not guessed: 598's layer-2 art is byte-identical to 577's
      -- and 599's and 606's are byte-identical to 585's.  They are the
      -- chairs already pinned above, baked over the Weather Institute's own
      -- floor instead of the lab's, so they carry different ids and every
      -- pin written for the lab missed them.  The pinned pair get real
      -- backs from the column-top profile for the same reason 577 and 585
      -- do -- it is the same drawing.
      [598] = "chair",    -- 577's chair, 5 cells
      [599] = "chair", [606] = "chair",   -- 585's chair, 8 cells

      -- ---- THE POTTED PLANTS ---------------------------------------------
      -- IN-GAME LOCATION: the lab's corner plant at (2, 2) on 580 -- "the
      -- plant is pulling the wall in too instead of being a per pixel round
      -- plant pot" -- and the two on 558 at (3, 12) and (12, 9).
      --
      -- 580 AND 558 ARE THE SAME DRAWING.  DERIVED, twice over: their carved
      -- silhouettes are identical row for row, 173 pixels each, and their
      -- object palettes match count for count (72 dark outline, 31 light
      -- green, 47 dark green, 10 terracotta, 5 brown, 3 pale yellow, 3
      -- yellow).  The only difference between the two cells is the 83 pixels
      -- of BACKGROUND behind them -- wall base for 580, floor for 558.
      --
      -- So this is not a choice of class, it is a correction of one cell's
      -- background.  558 at (3, 12) already resolves `cylinder` off the round
      -- carve and its lathe is right; 580 sits on the wall band, joined the
      -- wall run and came out as wall, and 558's OTHER cell at (12, 9) came
      -- out `tabletop`.  Pinning both ids puts all four plants on the lathe
      -- that one of them already had.  The silhouette states the pot: 15
      -- columns wide at row 3, tapering to 4 at row 14.
      --
      -- The taper gate in `Gen3.buildScenery` is NOT touched -- a pin returns
      -- from `classAt`'s first arm, long before the carve runs -- so Oldale's
      -- table corners and the other 17,895 `cylinder` cells are untouched.
      [580] = "cylinder", [558] = "cylinder",

      -- ---- THE WORKBENCH UNITS, pinned to the answer they already have ---
      -- IN-GAME LOCATION: the lab's (1, 9) and (1, 11) on 560 and 576, its
      -- (11, 9) and (11, 11) on 571 and 587, and 560/576 again in Lanette's
      -- House at (4, 3) and (4, 5).  6 cells in Hoenn, and MEASURED, every
      -- one of the six resolves `tabletop` today off the round carve.
      --
      -- This pin changes nothing by itself -- and that is the point.  Without
      -- it, 584 above drops 560 and 576 out of `tabletop` into `cylinder` and
      -- 558 does the same to 571 and 587, because a pin takes its cell out of
      -- the blocked run and the shrunken run falls under BOULDER_RUN_MAX.
      -- These are boxy benches with a machine and a cup on them, so a lathe
      -- is the wrong answer for them; saying outright what they are is the
      -- right one, and it stops the answer depending on what is pinned beside
      -- them.
      [560] = "tabletop", [576] = "tabletop",
      [571] = "tabletop", [587] = "tabletop",
    },


    -- EVERY ORDINARY HOUSE IN HOENN, which is what this tileset is: 38
    -- layouts, from OldaleTown_House1 to the Rustboro flats and the Safari
    -- Zone rest house.  gTileset_GenericBuilding had no block here at all.
    --
    -- Reported as "instead of having the chairs the way they are raise the
    -- backs of chairs like real 3d chairs".  The backs shipped last round;
    -- what is pinned here is the other half of that report, which is that
    -- THE CHAIRS IN QUESTION WERE NEVER RECOGNISED AS CHAIRS.  Before this
    -- block all 158 cells below resolve plain `ground` and their pictures
    -- are painted flat on the floor.
    --
    -- WHY A PIN AND NOT A RULE.  Two previous rounds measured the
    -- alternative and refused it, and this block does not reopen it: 4,223
    -- walkable indoor MB_NORMAL cells clear a 0.60 carved-silhouette test
    -- and that group contains FLOORS AND RUGS (the Battle Pyramid's floor at
    -- 0.89, a GenericBuilding rug at 0.88, another at 0.62), so no threshold
    -- on the silhouette selects chairs.  These ids are not selected by a
    -- threshold.  They are selected the way `gTileset_Lab`'s were -- by
    -- reading the drawing -- and the reading was made reproducible: every id
    -- below was found by grouping all 2,496 walkable indoor MB_NORMAL
    -- metatiles by their LAYER-2 ART (the half of a Gen 3 metatile that
    -- carries the furniture, with the floor on layer 1 excluded), which
    -- collapses "the same chair over eight different floors" onto one
    -- drawing, and then looking at the 788 distinct drawings that remain.
    --
    -- ALL 158 CELLS ARE PASSABLE (rule 2 above), so none of them is inside a
    -- blocked run and none of them can move a wall.
    gTileset_GenericBuilding = {

      -- ---- THE STANDARD HOENN HOUSE CHAIR, 138 cells over 30 maps -------
      -- IN-GAME LOCATION: OldaleTown_House2 (4, 4) and (7, 4) -- the pair
      -- either side of the dining table -- and the same chair in
      -- OldaleTown_House1, SootopolisCity_House1, VerdanturfTown_WandasHouse,
      -- RustboroCity_Flat1_1F and twenty-five more.
      --
      -- EIGHT IDS, ONE DRAWING PAIR.  DERIVED: 555, 733, 737 and 836 have
      -- byte-identical layer-2 art, and so do 556, 734, 738 and 837.  The
      -- two are mirror images -- the backrest board is drawn on the WEST of
      -- the cushion in one and on the EAST in the other -- which is the same
      -- pairing the shipped dining chairs 537/545 and 540/548 have, and it
      -- is why the chair-back rule finds the back without being told which
      -- side it is on: the column-top profile states it.
      --
      -- Cell counts, MEASURED over all 518 maps:
      --   555  30 cells / 17 maps      556  34 cells / 19 maps
      --   733   9 cells /  6 maps      734  13 cells /  8 maps
      --   737   9 cells /  5 maps      738  27 cells / 14 maps
      --   836   8 cells /  6 maps      837   8 cells /  5 maps
      [555] = "chair", [733] = "chair", [737] = "chair", [836] = "chair",
      [556] = "chair", [734] = "chair", [738] = "chair", [837] = "chair",

      -- ---- THE WOODEN CHAIR, 20 cells over 6 maps ----------------------
      -- IN-GAME LOCATION: SafariZone_RestHouse (2, 5..6) and (5, 5..6),
      -- flanking the 2x2 `tabletop` at (3..4, 5..6), and
      -- PacifidlogTown_House1 (3, 4) and (6, 4) with three more houses.
      --
      -- The same object as the pair above in structure -- a narrow backrest
      -- board up one side and a seat beside it -- drawn as slatted timber
      -- instead of an upholstered cushion.  DERIVED: 564 and 942 share
      -- layer-2 art, and so do 572 and 943; 564/942 carry the board on the
      -- WEST and 572/943 on the EAST, the same mirror pair again.
      --   564   2 cells / 1 map        572   2 cells / 1 map
      --   942   8 cells / 5 maps       943   8 cells / 5 maps
      [564] = "chair", [942] = "chair",
      [572] = "chair", [943] = "chair",

      -- =================================================================
      -- RUSTBORO CITY'S FLATS AND HOUSES, which are drawn from this same
      -- tileset: nine layouts (Flat1_1F/2F, Flat2_1F/2F/3F, House1/2/3 and
      -- the Cutter's House) out of the seventy-three maps it lays.
      --
      -- Reported as "buildings in rustburo need work as well, fridges arent
      -- the 3d shape they should be nor are the bookeshelfes, desks, sinks
      -- etc" and "Beds, wider tables, bed, couch and more need to be fixed
      -- too in rusburo".
      --
      -- WHY NOTHING ABOVE REACHED THEM.  Emerald names its furniture PER
      -- TILESET: the fridge, sink, worktop and glass cabinet already pinned
      -- for LITTLEROOT live in gTileset_BrendansMaysHouse on ids 568..572,
      -- and Rustboro's kitchens draw the same objects out of
      -- gTileset_GenericBuilding on ids of their own.  Every pin written for
      -- Littleroot missed them, so the whole kitchen run fell to the
      -- structural rule and indoors that rule is the blocked-run flood:
      -- MEASURED, all 20 fridge cells, all 42 sink-and-hob cells and all 82
      -- glass-cabinet cells in Hoenn resolve `wall` today and wear their
      -- picture up the face of the wall behind them.
      --
      -- HOW THE IDS WERE FOUND, reproducibly and not by eye: every metatile
      -- this tileset owns was grouped by its LAYER-2 ART -- the half of a Gen
      -- 3 metatile that carries the furniture, with the floor on layer 1
      -- excluded -- which collapses "the same fridge baked over eleven
      -- different floors" onto one drawing.  435 owned metatiles reduce to
      -- 101 distinct blocked drawings that way, and the groups below are what
      -- that reading returned; the id lists are the groups, not a selection
      -- out of them.  It is the same instrument the chair sweep above used.
      --
      -- WHICH ROW IS PINNED.  Rule 1 at the head of this section: the FRONT
      -- row, never the wall band.  Emerald draws each unit here across three
      -- cells -- a thin cap in the wall band, the whole carcass in the row
      -- below it, and a skirt in the walkable row under that -- and the
      -- carcass row is the last BLOCKED one.  MEASURED on the Cutter's House
      -- fridge: 888 (wall band) draws 6 pixel rows, 896 (pinned) draws all
      -- 16, 904 (walkable) draws 8.  Only 896 is pinned.
      --
      -- MEASURED over all 518 maps, before and after: 292 cells change class
      -- and every one of them is a cell laying one of the ids below; 3 more
      -- move as a side effect and are named at the foot of this block.  NO
      -- CELL'S WALKABILITY CHANGES -- 315,712 cells compared, zero drift --
      -- and no cell changes on any map that does not use this tileset, so
      -- the Lab, Brendan's, the Centres, Slateport and Sootopolis blocks are
      -- untouched cell for cell.

      -- ---- THE KITCHEN RUN ----------------------------------------------
      -- THE FRIDGE.  IN-GAME LOCATION: RustboroCity_CuttersHouse (8, 1),
      -- Flat1_1F (10, 1) and Flat2_1F (11, 1), plus seventeen more kitchens
      -- from OldaleTown_House1 to Route123_BerryMastersHouse -- 20 cells
      -- over 20 maps, every one of them blocked and every one of them `wall`
      -- before this pin.  "fridges arent the 3d shape they should be."
      --
      -- `appliance` and THIRTY-TWO are STATED by the class, and the class's
      -- own derivation is two drawn rows at 16 world pixels each.  It holds
      -- here: MEASURED, the object draws 6 + 16 + 8 = 30 pixel rows across
      -- its three cells, which is two cells of fridge and the stated 32px
      -- walker -- a fridge is as tall as a person.  This is the same class
      -- the identical object already carries in Littleroot on 568.
      [640] = "appliance", [696] = "appliance",
      [896] = "appliance", [927] = "appliance",

      -- THE SINK AND THE HOB, which are ONE unit with one lid line across
      -- them -- the same fact 569/570 record for Littleroot, and the reason
      -- both take the same height or there is a full course of step in the
      -- middle of one worktop.  IN-GAME LOCATION: CuttersHouse (9..10, 1),
      -- Flat1_1F (11..12, 1), Flat2_1F (12..13, 1) and eighteen more -- 21
      -- cells each, 42 in all, all blocked, all `wall` before this.
      -- "as well as the sink should be like a counter height."
      --
      -- SIXTEEN, STATED by `sink` and `worktop`, and DERIVED there off the
      -- stated 32px walker: waist is half a standing figure.  The basin's
      -- taps are drawn in the top five rows of 854's own cell rather than in
      -- the wall band, so the tap rises out of the counter top and needs no
      -- second cell.
      [620] = "sink",    [699] = "sink",
      [854] = "sink",    [952] = "sink",
      [621] = "worktop", [700] = "worktop",
      [855] = "worktop", [953] = "worktop",

      -- THE GLASS-FRONTED CABINET, two cells wide.  IN-GAME LOCATION:
      -- CuttersHouse (2..3, 1), RustboroCity_House2 and _House3 (10..11, 1),
      -- Flat2_2F (6..7, 1) and thirty-seven more -- 41 cells per half, 82 in
      -- all, every one blocked and `wall`.  It is the object in the kitchen
      -- frame between the bookshelf and the window.
      --
      -- `cabinet` and THIRTY-TWO, STATED by the class -- the same pin
      -- 571/572 already carry for the identical dresser in Littleroot.
      -- MEASURED here: 870 (wall band) draws 4 rows, 878 draws all 16, 886
      -- (walkable) draws 8 -- 28 rows, which is the two drawn cells the
      -- class's number is derived from.
      [654] = "cabinet", [710] = "cabinet", [878] = "cabinet",
      [655] = "cabinet", [711] = "cabinet", [879] = "cabinet",

      -- THE BASE UNIT WITH A DRAWER -- the low cupboard that stands in the
      -- kitchen run beside the sink, and on its own in a corner where there
      -- is no kitchen.  IN-GAME LOCATION: MauvilleCity_House1 (7, 1), where
      -- it sits between the wall and the sink at (8, 1), and
      -- RustboroCity_Flat1_1F (0, 1), where it is the white two-drawer
      -- cupboard in the north-west corner -- 35 cells over 35 maps, 33 of
      -- them `wall` and two of them (`tabletop` and `cylinder`, one cell
      -- each) already disagreeing with the other thirty-three about what the
      -- same drawing is.
      --
      -- `worktop` and SIXTEEN, STATED: it is a kitchen unit at counter
      -- height, and it has ONE drawn blocked row (MEASURED: 616 draws rows
      -- 1..15 and the walkable cell under it rows 0..6, 22 rows in all), so
      -- the two-row `cabinet` number would be a course too tall by its own
      -- derivation.
      [616] = "worktop", [672] = "worktop", [717] = "worktop",
      [840] = "worktop", [936] = "worktop", [992] = "worktop",

      -- THE CHEST OF DRAWERS, two cells wide, three drawers to a rank.
      -- IN-GAME LOCATION: OldaleTown_House1 (2..3, 1), MauvilleCity_House2
      -- and Route119_House and seventeen more -- 20 cells per half, 40 in
      -- all, every one blocked and `wall`.
      --
      -- AND IT REACHES NO RUSTBORO CELL, said plainly: not one of the nine
      -- Rustboro layouts lays it.  It is pinned because it is the same
      -- carcass in the same tileset as the units above, because the report
      -- names desks, and because leaving it out would leave forty drawer
      -- fronts painted on the wall in twenty houses for no reason but which
      -- town they are in.  MEASURED, it moves its own 40 cells and nothing
      -- else.
      --
      -- `cabinet` and THIRTY-TWO for the two-drawn-row reason: MEASURED, the
      -- wall-band cells 633/634 draw 5 rows and 641/642 draw all 16.
      [641] = "cabinet", [697] = "cabinet", [956] = "cabinet",
      [642] = "cabinet", [698] = "cabinet", [957] = "cabinet",

      -- THE WHITE CABINET BESIDE THE TELEVISION.  IN-GAME LOCATION:
      -- RustboroCity_House1 (1..2, 1) and RustboroCity_House2 and _House3
      -- (6..7, 1) -- 6 cells over 3 maps, all blocked, all `wall`.  In every
      -- one of the three the television (542, already `console`) stands in
      -- the very next cell.
      --
      -- `tv` (12), which despite the name is this file's word for A LID OVER
      -- A FRONT BAND -- see the class note in lib/TileShape.lua -- and is
      -- the pin 576/577 already carry for the SAME OBJECT in the same
      -- position in both children's living rooms in Littleroot: a white
      -- cabinet with a cream lid band along its bottom, standing next to the
      -- set.  Read from the drawing rather than from byte identity: Emerald
      -- redraws it per tileset, so 842's layer-2 art is not 576's byte for
      -- byte, but it is the same object drawn the same way.
      [842] = "tv", [843] = "tv",

      -- ---- THE TABLES ---------------------------------------------------
      -- THE 2x2 DINING TABLE WITH THE FLOOR-LENGTH CLOTH.  IN-GAME LOCATION:
      -- RustboroCity_CuttersHouse (8..9, 4..5) and Flat2_1F (9..10, 3..4),
      -- with four chairs round it, and eleven more houses -- 56 cells over
      -- 13 maps, all blocked.
      --
      -- Reported by frame: the Cutter's House table is LATHED INTO A
      -- CYLINDER today -- a yellow barrel where the table is.  MEASURED,
      -- that is what the mixture of answers looks like: of the 56 cells, 36
      -- resolve `tabletop`, 15 resolve `cylinder` and 5 resolve `canopy` --
      -- a TREE CROWN over a dining table -- and which one a cell gets
      -- depends on how big the blocked run around it happens to be rather
      -- than on what is drawn.  Sixteen ids, four drawings, one answer.
      --
      -- `tabletop` and TWELVE, STATED by the class: a surface drawn from
      -- above with things on it, waist height.  DERIVED that the carve can
      -- see it: 874/875 keep 224 of 256 pixels and 882/883 keep 205, so each
      -- cell extrudes from a full silhouette rather than an outline.
      [588] = "tabletop", [874] = "tabletop",
      [938] = "tabletop", [989] = "tabletop",
      [589] = "tabletop", [875] = "tabletop",
      [939] = "tabletop", [990] = "tabletop",
      [596] = "tabletop", [882] = "tabletop",
      [946] = "tabletop", [997] = "tabletop",
      [597] = "tabletop", [883] = "tabletop",
      [947] = "tabletop", [991] = "tabletop",

      -- THE 2x2 DINING TABLE WITH THE PLAIN TOP AND CORNER LEGS, which is
      -- the one the standard house chair above flanks.  IN-GAME LOCATION:
      -- RustboroCity_House2 and _House3 (5..6, 4..5), Flat1_1F (10..11,
      -- 4..5), Flat2_2F (12..13, 3..4) and thirty-one more -- 135 cells over
      -- 35 maps.
      --
      -- PINNED TO THE ANSWER IT ALREADY HAS, which is the move the
      -- `gTileset_Lab` workbench units above are here for.  MEASURED: 127 of
      -- the 135 cells already resolve `tabletop` and 8 resolve `wall` --
      -- Flat2_2F's four at (12..13, 3..4) among them, where the table stands
      -- against the east wall and was swallowed by its run.  Saying outright
      -- what it is fixes those eight AND stops the other 127 depending on
      -- what is pinned beside them.
      [584] = "tabletop", [586] = "tabletop", [635] = "tabletop",
      [872] = "tabletop", [1011] = "tabletop",
      [587] = "tabletop", [606] = "tabletop", [636] = "tabletop",
      [873] = "tabletop", [1012] = "tabletop",
      [592] = "tabletop", [594] = "tabletop",
      [880] = "tabletop", [1019] = "tabletop",
      [593] = "tabletop", [595] = "tabletop",
      [881] = "tabletop", [1020] = "tabletop",

      -- ---- THE BED ------------------------------------------------------
      -- IN-GAME LOCATION: RustboroCity_Flat1_2F (9, 5) and (9, 6) -- 2
      -- cells, one map, both blocked.  It is the bed on the orange rug in
      -- the room frame, and in 3D it is a flat white slab on a dark box:
      -- MEASURED, 801 resolves `prop` (a standing per-pixel billboard, which
      -- lays a bed on its edge) and 950 resolves `tabletop`.
      --
      -- `bed` and SEVEN, STATED by the class: drawn from above and lying
      -- low.  This is the third and fourth `bed` cell in Hoenn; the other
      -- seven are Brendan's six and May's one and not one of them moves.
      --
      -- THE FOUR CELLS AROUND IT ARE DELIBERATELY NOT PINNED.  The bed is 24
      -- pixels wide and Emerald draws its side rails in the walkable cells
      -- either side -- 570 and 900 carry cols 12..15, 815 and 1021 cols
      -- 0..3.  `Structures.buildGen3Joinery` already grows a `bed` claim
      -- into a neighbouring plain-ground cell whose silhouette MEETS the
      -- claimed one across their shared edge, and its own note says why the
      -- pin list is not the thing to grow.  DERIVED, off the drawings: 801's
      -- rows 9..15 meet 570's col 15 and 815's col 0, and 950's rows 0..11
      -- meet 900's and 1021's, so all four are claimed without a pin.
      [801] = "bed", [950] = "bed",

      -- ---- THE COUCH ----------------------------------------------------
      -- IN-GAME LOCATION: RustboroCity_Flat1_2F (9..11, 2),
      -- RustboroCity_Flat2_3F (11..13, 2) and RustboroCity_House1 (9..10, 2),
      -- with the same seat in SootopolisCity_House3 and _House6,
      -- DewfordTown_Hall and LilycoveCity_PokemonTrainerFanClub -- 18 cells
      -- over 7 maps, EVERY ONE OF THEM PASSABLE (rule 2 above) and every one
      -- of them plain `ground` before this pin.  "couch and more need to be
      -- fixed too."
      --
      -- WHAT IS PINNED IS THE SEAT ROW, AND ONLY THE SEAT ROW.  Emerald
      -- draws this couch 22 pixel rows tall across two map rows: the BACK
      -- and the top of the arms in rows 8..15 of the wall-band cell
      -- (852/823/853 and their twins), and the cushion, the arms and the
      -- front rail in rows 0..13 of the walkable cell below.  The wall band
      -- is not pinned -- rule 1, and here it would take three cells out of a
      -- fourteen-cell north wall -- so the back stays drawn where Emerald
      -- draws it and the seat comes forward onto the floor.  Same compromise
      -- the 530/531 and 613/599 cells already ship, for the same reason.
      --
      -- `counter` and SIXTEEN.  SIXTEEN is `counter`'s own number, DERIVED
      -- there off the stated 32px walker as 32/2, waist, and shipped on 563
      -- cells; here it is the height of the couch BODY, whose 22 drawn rows
      -- are a cell and a bit, with the seat drawn on its lid.  `counter` is
      -- also this file's own word for the object -- lib/TileShape.lua calls
      -- it "half-cell furniture: a service counter, A LOW COUCH".
      --
      -- NOT `chair` (8), and this is measured rather than argued.  8 = 32/4
      -- is the right height for a seat, but `chair` alone reads its
      -- silhouette through `chairMaskOf`, which keeps the PRINCIPAL ISLAND
      -- and closes only the holes that island encloses.  MEASURED off the
      -- carve: this couch does not carve to one island, because the pale
      -- middle of its cushion is also a colour the Rustboro floor is laid in
      -- -- 860 and 861 carve to 76 + 72 pixels and 831 to 112 + 48, with
      -- rows 8..10 eaten open from edge to edge.  Pinned `chair` the front
      -- rail is discarded and a three-cell couch comes out as a 7px-deep
      -- bar.  `counter` reads the plain carve and keeps all 148..162 pixels.
      --
      -- AND NOT `bed`, which is the other low class that reads the plain
      -- carve: `bed` is the one class the joinery pass GROWS across cells,
      -- and the rug edge south of the Flat2_3F couch is plain ground with a
      -- drawing on it, so the couch would have grown into it.
      [651] = "counter", [666] = "counter", [860] = "counter",
      [831] = "counter",
      [652] = "counter", [667] = "counter", [861] = "counter",

      -- ---- THE POTTED PLANTS, one drawing on eight ids -------------------
      -- IN-GAME LOCATION: RustboroCity_Flat1_1F (0..1, 7),
      -- RustboroCity_Flat1_2F (1..2, 7), the Cutter's House (0..1, 8),
      -- House1 (0, 2), (12, 2), (0, 7) and (12, 7), House2 and House3
      -- (0, 8) and (11, 8), Flat2_2F (12..13, 2) -- and the same pot in
      -- twenty-eight more houses.  83 cells over 35 maps, all blocked.
      --
      -- ONE DRAWING, EIGHT IDS: 554, 664, 665, 668, 802, 807, 846 and 847
      -- have byte-identical layer-2 art -- the same pot baked over eight
      -- different floors.  THREE ANSWERS, though: MEASURED, 64 of the 83
      -- cells resolve `cylinder` and are right, 9 resolve `tabletop` and 10
      -- resolve `wall`, and which one a pot gets depends on the run it
      -- happens to stand in.  In Rustboro alone the identical pot is a lathe
      -- in Flat1_2F, a table top in Flat1_1F and the Cutter's House, and
      -- wall in House1 and Flat2_2F.
      --
      -- So this is not a choice of class, it is a correction of a
      -- background -- exactly the `gTileset_Lab` 580/558 case, and the same
      -- fix: pin all eight to the lathe that sixty-four of them already
      -- have.  The silhouette states the pot: MEASURED, 15 columns wide at
      -- row 5, tapering to 8 at row 15, carving to one 158-pixel island.
      [554] = "cylinder", [664] = "cylinder",
      [665] = "cylinder", [668] = "cylinder",
      [802] = "cylinder", [807] = "cylinder",
      [846] = "cylinder", [847] = "cylinder",

      -- THE CROWN ABOVE IT IS DELIBERATELY NOT PINNED.  Emerald draws these
      -- plants over two cells and the leaves are the cell ABOVE the pot --
      -- 546, 656, 657, 660, 793, 794, 835, 838 and 839, another single
      -- drawing on nine ids.  73 of its 83 cells are WALKABLE FLOOR, and no
      -- class in this file's vocabulary says "the upper half of a two-cell
      -- plant": `cylinder` on them would stand a second lathe on the floor
      -- you walk over, and `canopy` would carve a 32px hull from a 2x2 that
      -- is not there (this plant is one cell wide).  The Lab's plants were
      -- single-cell and did not raise the question.  Said out loud rather
      -- than guessed at: the leaves stay drawn flat where they are drawn.

      -- ---- AND WHAT THIS BLOCK MOVES THAT IT DID NOT PIN -----------------
      -- THREE CELLS, all in LilycoveCity_PokemonTrainerFanClub: 770 at
      -- (9, 7), 771 at (10, 7) and 778 at (9, 8), which leave `canopy` and
      -- `cylinder` for `tabletop`.  They are the long white bench along that
      -- room's east wall, and 616 -- pinned `worktop` above -- stands in the
      -- very next cell, so taking it out of the blocked run shrinks that run
      -- under BOULDER_RUN_MAX and re-arms the round carve on its neighbours.
      -- MEASURED, the move is TOWARDS the answer the same drawing already
      -- has elsewhere: 771 resolves `tabletop` on 6 of its 7 cells and 770
      -- and 778 on 1 of their 2 each.  A bench is a top-down surface and
      -- `tabletop` is right for it.
      --
      -- 770/771/772/778/780 WERE TRIED AS PINS and taken out again, which is
      -- worth recording so nobody re-adds them: pinning that bench pulls its
      -- own neighbours 643 and 644 out of THEIR runs and drops them from
      -- `tabletop` to `cylinder` in DewfordTown_Hall and the Fan Club -- a
      -- couch lathed into a barrel, 4 cells, worse than the 3 it fixes.
      -- Holding those down needs 643/644 pinned too, and 643's third cell is
      -- in the Fan Club's own wall band, which rule 1 forbids.  Three cells
      -- moving to the right answer is the smaller error.
      --
      -- ---- AND WHAT COULD NOT BE PINNED FROM THIS FILE ------------------
      -- THE WIDE 3x2 DINING TABLE, and this is the one thing in the report
      -- this round does not fix.  IN-GAME LOCATION:
      -- RustboroCity_Flat1_2F (2..4, 4..5) -- the "wider table" in the room
      -- frame, with a chair west of it and two east -- and
      -- RustboroCity_House1 (3..5, 4..5).  Ids 744/894, 745/895, 746/910,
      -- 752/902, 753/903, 754/911; 29 cells, 4 of them (`745`/`895`'s and
      -- `753`/`903`'s middle column) resolving `wall`, which is the tall box
      -- in the frame.
      --
      -- `tabletop` is unambiguously the right CLASS for it and a pin would
      -- still make it worse, because the class is extruded per pixel from
      -- the map's own carve and IN THESE TWO ROOMS THE CARVE CANNOT SEE THE
      -- TABLE.  MEASURED, the same drawing over two different floors: baked
      -- over Mossdeep's, Dewford's and the Safari rest house's floor (ids
      -- 744/745/746) it carves to 206, 240 and 206 pixels of 256 and stands
      -- as a solid table; baked over Rustboro's pale-yellow check (ids
      -- 894/895/910) it carves to 42, 16 and 42, because the tablecloth is
      -- painted in a colour that floor is laid in.  895's sixteen surviving
      -- pixels are ONE ROW.  Pinned, the middle of the table would stand as
      -- a 1-pixel line and the cell would be flattened to floor under it.
      --
      -- That is a defect in how a thin carve is modelled, not in what the
      -- cell is, and the instrument that would fix it -- a boxed fallback
      -- for a `tabletop` whose carve falls under some fraction of its
      -- drawing -- lives in lib/Structures.lua, which this file does not get
      -- to edit.  Left unpinned and written down instead.
      --
      -- THE FRIDGE AND THE HOB ARE THE SAME STORY ONE STEP LESS SEVERE, and
      -- are pinned anyway: MEASURED, 896 carries 62 pixels after the grain
      -- filter and 855 carries 93, against 254 for the identical fridge in
      -- Littleroot.  What survives on the fridge is its whole OUTLINE --
      -- all four edges, both door seams and both handles -- so it stands as
      -- a fridge-shaped box rather than as a line, and standing in front of
      -- the wall at 32 is the report's ask either way.
    },

    -- SOOTOPOLIS' MYSTERY EVENTS HOUSE, which lays the house chair above on
    -- two ids of its own.  IN-GAME LOCATION:
    -- SootopolisCity_MysteryEventsHouse_1F (6, 4) and (9, 4) -- 4 cells,
    -- both passable.  DERIVED: 528's layer-2 art is byte-identical to
    -- gTileset_GenericBuilding 555's and 529's to 556's.
    gTileset_MysteryEventsHouse = {
      [528] = "chair", [529] = "chair",
    },

    -- EVERY POKEMON CENTER IN HOENN shares this tileset, so one pin set
    -- fixes the lot.  The desk is drawn as one row of counter -- two ends
    -- and a body -- but only the cell the nurse speaks across carries
    -- MB_COUNTER; the rest are MB_NORMAL and blocked, so they flooded into
    -- one region with the alcove wall BEHIND them and stood as a purple
    -- slab from floor to ceiling, the counter art repeating up its face.
    -- Pinned, the desk leaves the flood as waist-high furniture and the
    -- alcove keeps its own wall.
    gTileset_PokemonCenter = {
      [600] = "counter", [545] = "counter", [601] = "counter",

      -- ---- THE STOOLS ROUND THE CENTRE'S TABLES -------------------------
      -- IN-GAME LOCATION: OldaleTown_PokemonCenter_1F (1, 3), (2, 3),
      -- (10, 6), (10, 7), (11, 8) and (12, 8), and the same seats in every
      -- other Centre, Pokemon League and Battle Frontier Centre in Hoenn.
      -- MEASURED over all 518 maps: 550 lays 86 cells and 564 lays 102 --
      -- 188 cells over 34 maps, EVERY ONE OF THEM PASSABLE (rule 2 above),
      -- and every one of them resolving plain `ground` before this pin.
      --
      -- WHY THEY ARE SEATS, from two independent readings.  The ART: each
      -- is a round cushion in three-quarter view -- 564 yellow, 550 peach --
      -- on a grey pedestal foot, which is a stool and is not a floor
      -- pattern.  The LAYOUT: the four at (10..12, 6..8) ring the 2x2
      -- `tabletop` at (11..12, 6..7), which is the dining-set arrangement
      -- this file already pins in both children's living rooms.
      --
      -- `chair` (8) AND NOT `stool` (8): same height, but `chair` is the
      -- class `buildGen3Joinery` extrudes per pixel from the carve, and it
      -- is the class the chair-back rule reads.  A round stool has no back,
      -- and these do not get one: MEASURED over all 188 cells, the
      -- chair-back rule emits ZERO quads on every one of them.
      --
      -- CORRECTING THE REASON THIS BLOCK GAVE (g3-settee-305).  It said the
      -- rule declines because "its column-top profile is flat, exactly like
      -- 610".  It is not flat.  DERIVED, off the dumped carve, 550 and 564
      -- both profile 3,2,1,1,1,1,1,1,1,1,1,1,2,3 -- a plateau at row 1, with
      -- a rounded cap either side of it.  The rule declined only because row
      -- 0 happens to be empty, which is luck and not a reading; one more row
      -- of cap and a cushion would have grown a backrest.  The gate in
      -- `buildGen3Joinery` now refuses on the plateau itself (1 < 3), so the
      -- outcome no longer depends on that.
      --
      -- AND WHAT THE REPORT ACTUALLY SAW ON THESE CUSHIONS was never the
      -- back rule.  On 154 of the 188 cells the carve cuts the cushion in
      -- two and leaves a detached 10 x 1 bar floating at row 1, which the
      -- seat pass stood up as a one-pixel wall across the cushion's north
      -- edge.  That is fixed in `buildGen3Joinery` (`chairMaskOf`), which
      -- keeps a chair's principal island and closes the holes inside it.
      -- These stay pinned `chair`: they are seats, the pin is right, and the
      -- defect was in what the pass did with the drawing.
      [550] = "chair", [564] = "chair",
      -- ...and the 2F staircase's own stray slab.  672 is a stair TREAD --
      -- the same drawing as 1F's 648 -- and the furniture detector reads
      -- its flat pale band as a table top.  Until the descending well is
      -- built (see the `flights` profile above) it is floor, not furniture.
      [672] = "ground",
    },

    -- SLATEPORT CITY's harbour.
    gTileset_Slateport = {

      -- ---- THE MOORED SAILBOATS ---------------------------------------
      -- A 3x3 block of drawing -- hull, mast and a two-tone sail -- sitting
      -- in open water.  Every cell of it is blocked, so unpinned the flood
      -- measured one region and `buildVolume` boxed it: a 48px cube of sea
      -- with a boat printed on its lid, three times over along the quay.
      --
      -- A boat is a THIN thing seen broadside, which is what `prop` says:
      -- the drawing stands as a per-pixel slab, sail and rigging included,
      -- and the water closes behind it.  Pinned on all nine cells rather
      -- than the corner alone, because the billboard pass floods a REGION
      -- of pinned cells and builds one slab from it -- the opposite of the
      -- hull classes, where the corner pin claims its neighbours.
      [824] = "prop", [825] = "prop", [826] = "prop",
      [832] = "prop", [833] = "prop", [834] = "prop",
      [840] = "prop", [841] = "prop", [842] = "prop",

      -- ---- THE HARBOUR LIGHT ------------------------------------------
      -- Two cells wide and four tall, and round the whole way down: lamp
      -- room, gallery, shaft, splayed base.  Its lower half is blocked and
      -- its upper half is drawn on the above-player layer, so it came out
      -- as a 2x2 box with the lamp painted flat on the pavement behind it.
      --
      -- Anchors at both halves.  `canopy` on a top-left corner carves a
      -- 32px hull from the 2x2 under it; two anchors two rows apart are
      -- read as ONE 64px tower (Structures.buildCylinders).  The other six
      -- cells are `cylinder` so the group build knows the drawing is whole
      -- and does not leave a half-empty giant.
      [582] = "canopy",  [583] = "cylinder",
      [590] = "cylinder", [591] = "cylinder",
      [598] = "canopy",  [599] = "cylinder",
      [606] = "cylinder", [607] = "cylinder",

      -- ---- THE MARKET STALLS -----------------------------------------
      -- The pole rows: two bare timber poles drawn per cell, standing on
      -- the pavement.  Per-pixel slabs, so they stand where they are drawn
      -- and the awning deck (stall_awning below) floats at their tops.
      [573] = "post", [620] = "post",
    },

    -- SOOTOPOLIS: the Cave of Origin gate.
    gTileset_Sootopolis = {

      -- ---- THE GATEWAY ------------------------------------------------
      -- Three rows: a lintel spanning the opening, the dark mouth under it,
      -- and a leg either side.  The lintel and the mouth are drawn on the
      -- above-player layer and are WALKABLE -- you pass under the arch --
      -- so they came through as flat ground with the beam painted on the
      -- floor, while the legs stood as solid boxes.  A gate with its beam
      -- lying in the dirt.
      --
      -- `post` is the class for this: it extracts each CELL on its own as a
      -- per-pixel slab, so the legs stand where they are drawn, the lintel
      -- stands across the top, and the mouth stays the air it is.  A pin
      -- may be walkable -- that is the point here.
      [560] = "post", [562] = "post",   -- the legs
      [553] = "post",                   -- the lintel across the opening
      [545] = "post",                   -- the mouth and its jambs

      -- ---- THE BOLLARDS -----------------------------------------------
      -- Four cells south of the gate, each drawing TWO capped posts.  Read
      -- as wall they measured a four-tile run and stood 48px: eight stone
      -- slabs where the map draws eight little posts.
      [640] = "post",
    },

    -- ROUTE 119'S UPPER RIVER IS WATER, AND IT WAS MESHING AS A CLIFF.
    --
    -- MOTIVATED BY ROUTE 119, THE BASIN ABOVE THE WATERFALL AT (17..19, 25)
    -- -- the wide reach the plank walkways cross on their piers -- reported
    -- as "all water at the top of the waterfall should be the same level as
    -- the top of the waterfall".
    --
    -- 518 AND 519 ARE DRAWN AS OPEN WATER.  Both are this secondary's river
    -- surface: 518 is bare ripple, 519 the same ripple with a reed clump
    -- standing in it.  Both animate on LAYER 1 -- all four bottom quadrants
    -- of each cell sit inside one of the pair's six animation runs, which is
    -- Emerald drawing a moving SURFACE rather than something standing on one
    -- (`Gen3.flowerMetatiles`, reading 1, in reverse).  `Gen3.metaRole` calls
    -- both `surface`; the shore rock beside them in the same tileset --
    -- 378, 380, 386, 388 -- it calls `face`.
    --
    -- WHAT THE CARTRIDGE SAYS, AND WHY IT WAS NOT ENOUGH.  Emerald puts
    -- these cells at ELEVATION 1, the surf datum, and BLOCKS them: this is
    -- the reach you cannot surf into, because the walkways are the way
    -- across it.  `Gen3.classAt`'s elevation-1 rule is gated on `not
    -- blocked`, and it has to be: DERIVED over all 518 maps, 2,810 blocked
    -- surf cells resolve `cliff` today and almost all of them are real rock
    -- -- the sea stacks of Routes 124, 127, 126, 125, 129 and 128 (562, 420,
    -- 257, 190, 144 and 129 cells), every one of which `metaRole` calls
    -- `face`.  So a blocked water cell falls past that rule to the behaviour
    -- byte, which is MB_NORMAL here; MB_NORMAL plus blocked is a wall, and a
    -- wall outdoors is landscape rock.
    --
    -- WHAT THAT LOOKED LIKE.  MEASURED on Route 119 before this pin: the 124
    -- basin cells of 518 carry FIVE different heights -- 16, 32, 48, 64 and
    -- 80 -- because the rock passes chain courses up them, while the 19
    -- surfable cells of the same river just below (metatile 368,
    -- MB_OCEAN_WATER) lie flat at 44 and the fall's own lip stands at 48.
    -- One body of standing water drawn as a five-course stair of blue slabs,
    -- with the plank walkways sunk between them.
    --
    -- PINNED RATHER THAN RULED, because no reading separates these two from
    -- the sea stacks without taking those as well: elevation 1 + blocked +
    -- `surface` is 423 cells region-wide, and 292 of them are Mossdeep's and
    -- the sea routes' half-sunk rocks (336/337/344/345) -- rock in water, and
    -- right as they stand.  DERIVED: metatiles 518 and 519 of this pair are
    -- laid on 176 cells in the whole of Hoenn and every one is on Route 119.
    -- Nothing else in the region can move.
    --
    -- `water` is flat and recessed, and `Structures.standGen3Water` floods a
    -- water body and sets the whole of it to ONE surface at the lowest shore
    -- you can stand on.  That single level is what the report asks for.
    gTileset_Fortree = {
      [518] = "water",
      [519] = "water",
    },

  },

  maps = {

    -- ROUTE 111'S SAND RAMPS ARE A FLIGHT, AND THE CARTRIDGE SAYS SO.
    --
    -- `MB_MUDDY_SLOPE` is Emerald's own word for a ramp: without the Acro
    -- Bike it slides the player DOWN one, and always SOUTH, so the cartridge
    -- has stated per cell that the north end is the high end.  Marking those
    -- cells as stair cells (see `markGen3Stairs`) and cutting the terrace
    -- flood at them (see `standable`) was enough to make the desert's north
    -- mesa a terrace at last -- 32 against the sand's 16 -- but a stair MARK
    -- is not a stair SHAPE.  Both cells of each ramp came out at the mesa's
    -- 32 with the whole course of drop landing in one step at the foot, and
    -- metatile 232's pale banded art drawn down the face of it: a bright slot
    -- in the cliff, reported as the mudslide being flat and a hole in the
    -- terrain.
    --
    -- `flights` is the mechanism for exactly this -- "re-grounds the region
    -- so its steps are spaced across the whole run" -- and it wants the
    -- metatile and the direction of climb.  All four muddy-slope cells in
    -- Hoenn are metatile 232 and all four are on this map.
    Route111 = { flights = { { dir = "n", tiles = { 232 } } } },

    -- THE FIERY PATH IS A CAVE ON AN OUTDOOR TILESET.
    --
    -- `rock_plateau` is what gives a cave its rock: the walls stand as a mass
    -- with their own drawing mapped once down the face instead of meshing as
    -- boxes of stretched wall.  It is carried on the TILESET, and every other
    -- cave in Hoenn uses gTileset_Cave or gTileset_MeteorFalls, so every
    -- other cave gets it.  The Fiery Path does not: it is drawn with Route
    -- 112's and Lavaridge's own tileset -- the volcanic one, shared with two
    -- OUTDOOR maps -- so the cave handling never reached it and its interior
    -- meshed as a flat slab with one-course kerbs and vertical smears down
    -- every wall.  Against Granite Cave's rounded rock in the same shot it is
    -- unmistakable.
    --
    -- Keyed on the MAP, not the tileset, because the tileset's other two maps
    -- are outdoors and this is a statement about a cave.  (`buildGen3Rock-
    -- Plateaus` refuses to run outdoors anyway -- belt and braces -- but the
    -- data should say what is true rather than lean on the guard.)
    FieryPath = { rock_plateau = true },

    -- SOOTOPOLIS is a CALDERA WITH NO WAY OUT ON FOOT.  You arrive by Dive
    -- and leave the same way; every cell of its border is crater wall.  The
    -- terrace pass protects a map's border tiers because a route's shelves
    -- join the next route and lifting one steps the seam -- but here there
    -- is no seam, and the rim is the highest ground in the town.  Guarded,
    -- the lip sank to the floor and the bowl came out inside-out.
    SootopolisCity = { terrace_free_edge = true, elevation_height = true,
                       drawn_terraces = false },

    -- ---------------------------------------------------------------------
    -- HEIGHT FROM THE CARTRIDGE, NOT FROM THE DRAWING.
    --
    -- `elevation_height` says: a walkable cell's z is its ROM ELEVATION, and
    -- the drawn-terrace flood does not run.  These four maps are pinned
    -- rather than detected because detection is what turned every purple rock
    -- into a skyscraper -- their tilesets draw houses, crater rim and cliff
    -- face in the same rock, so no art test can separate them, and the flood
    -- chained one course per blocked band until Sootopolis ran 0 at the lake
    -- to 9 at the rim on a map the cartridge says has ONE land level.
    --
    -- What the cartridge actually states, measured:
    --   Sootopolis   elev 1 (water, 601 cells) + 3 (land, 908)   -> 1 land level
    --   Mt Pyre      elev 3 (460)                                -> 1 land level
    --   Ever Grande  elev 1, 3, 5, 7                             -> 3 land levels
    --   Route 119    elev 1, 3, 4 + 15 (bridge deck)             -> 2 + a deck
    --
    -- Pinned by MAP where the tileset is shared: gTileset_Facility is Mt
    -- Pyre's secondary but also twenty-seven other maps, and gTileset_Fortree
    -- covers Faraway Island's interior as well as the grass routes.
    MtPyre_Exterior  = { elevation_height = true, drawn_terraces = false },
    MtPyre_Summit    = { elevation_height = true, drawn_terraces = false },
    Route119         = { elevation_height = true, drawn_terraces = false },


    -- The canopy walk (see gTileset_Fortree above).
    -- FORTREE: a town in the CANOPY.  Its huts stand in the treetops and its
    -- rope walkways cross between them, both at elevation 4, over trees at 3
    -- -- which is why `course` is 32 here rather than 16: "one course of
    -- separation would put the walkway INSIDE the canopy it is supposed to
    -- cross".
    --
    -- `canopy_walk` says the same thing to the tree builder.  A wood's crown
    -- is stacked two cells tall (see `buildCylinders`), which is right where
    -- the only thing above a tree is sky and wrong here: doubling Fortree's
    -- canopy swallowed the walkways and the huts standing in it -- 362 of its
    -- cells, reported as "the bridges in Fortree have been turning into
    -- cylinders" and "some trees aren't the right height, they're supposed to
    -- sit below the huts".
    --
    -- Where the town is IN the canopy, the canopy is one cell tall and the
    -- things built in it sit above it.
    FortreeCity = { course = 32, canopy_walk = true },

    -- Route 110's cycling road: 592 bridge cells at ELEVATION_MULTI_LEVEL
    -- over 1242 ocean cells at the surf level -- the clearest case in the
    -- game of two walkable surfaces stacked in Z on the same XY, and the
    -- reason the bridge lift is measured from the DATUM rather than from the
    -- water underneath it.
    -- ...and its ELEVATION FIELD IS TRAFFIC CONTROL, not terrain: two land
    -- levels stated, no cliff drawn anywhere on the route.  `causeway`
    -- keeps the land on the datum and gives every bridge-behaviour cell its
    -- full lift over it, so the road flies over a flat coastal plain the
    -- way the drawing shows it -- and the crossings sit flush with the
    -- causeway they continue instead of hovering a storey above it.
    Route110 = { causeway = true },

    -- Route 120: a low bridge in the south and a high one in the north over
    -- one pond, which is exactly what bridge_lift exists to tell apart.
    Route120 = {},

    -- Mossdeep: seven distinct levels (0,1,3,4,5,7,9), the richest elevation
    -- set of any town and the best test of the ranking rule -- read as raw
    -- course counts it would be a 96px cliff where the art draws four.
    MossdeepCity = {},

  },
}
