-- Voxel world mode: THE GEN 3 PALING PROFILE -- a fence stated as posts.
--
-- Hand-authored by this mod and read only from here.  Nothing below is
-- extracted, derived or copied from the ROM; nothing here reaches gameplay,
-- collision, warps, scripts or encounters.  An entry can only ever change
-- how a cell LOOKS.  It is the Gen 3 counterpart of the `figures` and
-- `mounted` blocks in data/voxel_heights.lua and it is a separate file for
-- the same reason data/gen3_terraces.lua is: an authored SHAPE matched per
-- tileset is a different kind of statement from a class table.
--
-- ---------------------------------------------------------------------------
-- WHY A FENCE HAS TO BE MODELLED AND CANNOT BE CARVED
-- ---------------------------------------------------------------------------
--
-- Six measured refusals stand behind this file and every one of them was
-- right (NOTES.md g3-railrun-264, g3-post-265, g3-postrun-266, g3-rail-267
-- (a) and (b), and g3-rank-263 before them).  The short form:
--
--   * MauvilleCity's property line round the Game Corner renders as a FLAT
--     BROWN STRIP on its north-south arms -- 130 px^2 of standing surface
--     for three cells -- while its east-west arms render as a proper march
--     of posts.  One fence, one tileset, two answers.
--   * The difference is not positional and it is not a recoverable 8px unit.
--     It is that `Gen3.classAt`'s scenery carve admits 657 (east-west) and
--     refuses 648/650 (north-south) on a `solid < 0.35` ceiling, so the
--     north-south arms fall to `wall`, `buildVolume` founds a run over them,
--     and `ChunkMesher.heightAt` reads the run before the tile's own shape.
--   * Every exact derivation of a better ceiling from the drawing leaks:
--     409 metatiles / 3,395 cells for "splits into two identical 8px halves
--     on one axis", 390 metatiles / 3,485 cells for "one 8px half is exactly
--     empty", 618 four-connected runs over 31,230 cells for "a byte-identical
--     role row implies a shared class".
--
-- AND THE REASON THE CARVE CANNOT WIN IS IN THE ART ITSELF.  Emerald draws a
-- fence line TWICE, in two orthogonal views, and the two views say different
-- kinds of thing:
--
--   metatile 657, the EAST-WEST arm, is an ELEVATION.  Its drawn ROWS are
--     HEIGHT.  Two posts stand side by side across the cell with three wholly
--     empty columns between them and four empty rows above them, so a
--     per-pixel carve reading rows as height gets a rank of posts for free --
--     which is exactly why that arm looks right today.
--   metatile 650, the NORTH-SOUTH arm, is a PLAN.  Its drawn ROWS are DEPTH.
--     Two posts stand one BEHIND another down the cell, and because a post is
--     taller than the eight pixels between it and the next one, the two
--     overlap on screen into one unbroken 5px bar.  There is no gap in it to
--     carve, on this map or on Route 117, and slicing it into 8px units and
--     standing each at its own depth would be INVENTING the gaps -- the
--     four-instance "a drawing smeared over a box that was resized" failure
--     in its purest form.
--
-- The mod has exactly two readings of a drawn row -- "height" (the standee
-- branch of `Structures.buildObject`) and "depth" (its `plan` branch, and
-- `buildRelief`) -- and a receding fence needs a THIRD: the drawn row is
-- DEPTH, and the object's HEIGHT is drawn somewhere else in the same tileset.
-- That third reading is what this file states.  It is not a classifier and it
-- has no threshold in it; it is a figure with the two drawings named.
--
-- ---------------------------------------------------------------------------
-- WHAT AN ENTRY SAYS
-- ---------------------------------------------------------------------------
--
--   post   the POST, authored: `w` across the line, `d` through it, `h` tall.
--          This is the only invented number in the file and it is small: the
--          width and the height are read straight off the face drawing (five
--          columns, eleven rows, below), and the depth is read off the plan
--          drawing's own post head.  A log is round, so its plan is a disc
--          and only its width is ever drawn.
--   face   THE ELEVATION the post's four side faces wear: the metatile that
--          draws this fence face-on, the drawn COLUMN its west post starts
--          at, and the drawn ROWS that are the post's body.  Drawn row `y1`
--          is the post's foot and `y0` its head, mapped 1:1 onto world y --
--          one drawn row per world unit, never repeated, never stretched.
--   top    THE PLAN the post's lid wears: the metatile that draws this fence
--          receding, and the corner of the `w` x `d` rect that is one post's
--          drawn head.  This is the round cut end of the log, which is drawn
--          nowhere else.
--   pieces metatile -> the list of POST ORIGINS inside the 16x16 cell, as
--          {x, z} in cell-local pixels.  This is the whole placement, and it
--          is where the five-instance "a Gen 3 cell is TWO tile rows and TWO
--          tile columns" trap lives: a cell of fence carries TWO posts, not
--          one, and a piece that lists one post is a piece where the drawing
--          shows one.
--
-- Anything not listed in `pieces` is not a paling and this file never looks
-- at it.  There is no predicate here and nothing is inferred from `solid`,
-- from a role row, or from a behaviour byte.
return {
  version = 1,

  -- ---------------------------------------------------------------------
  -- FENCES THAT LIVE IN A **PRIMARY** TILESET
  -- ---------------------------------------------------------------------
  --
  -- A Gen 3 pair is `TILESET_<primary>_<secondary>`, and a metatile below 512
  -- belongs to the PRIMARY -- so it is the same drawing in every pair built
  -- on that primary.  The Mauville log paling above is a SECONDARY fence: its
  -- pieces are 640..698, they exist in one pair, and they appear on three
  -- maps.  The white rail fence below is a PRIMARY fence: its pieces are
  -- 306..330, they belong to gTileset_General, and they appear on FIFTEEN
  -- maps in every pair built on `03DF704`.  Keying it per pair would mean
  -- listing forty-odd pair ids and would silently miss the next one; keying
  -- it on the primary is the fact itself.
  --
  -- Swept over all 518 maps, every map that places any of these twelve
  -- metatiles has primary `03DF704` and no other -- so this table cannot
  -- reach a pair where the same ids mean something else.
  -- ---------------------------------------------------------------------
  -- OVERHEAD FIGURES: art on a cell's ABOVE-PLAYER layer that belongs to the
  -- object standing in the cell IN FRONT of it.
  -- ---------------------------------------------------------------------
  --
  -- (g3-crown-278.)  Emerald draws anything taller than one cell across TWO
  -- cells: the body in the cell you stand next to, and the part that rises
  -- past the top of that cell on the ABOVE-PLAYER layer of the cell behind.
  -- The mod already stands the body -- that is the sprite carve, and
  -- g3-planter-269 brought the Game Corner's pots down onto the carpet -- but
  -- the upper half stays painted flat on the wall it was drawn over, because
  -- `Gen3.bakeLinear` composites layer 1 and layer 2 into one tile and the
  -- wall wears that tile.
  --
  -- WHY THIS IS AUTHORED AND NOT DERIVED, AND THE MEASUREMENT IS FINAL.
  -- g3-frond-277 scored every run cell in Hoenn that carries above-player art
  -- -- 3,537 cells on 197 maps -- by BANDINESS, `n2 / (occupied rows x 16)`,
  -- which is exactly "is every row this art occupies a FULL row?" and is what
  -- separates a wall band from a thing standing against it.  A mode at
  -- exactly 1.00 and then a ramp with NO GAP ANYWHERE.  The sharpest extra
  -- clauses available leave 245 cells on 81 maps, and the crown is in the
  -- densest part of that: metatile 559 scores 0.736, the SAME to four
  -- decimals as BattleFrontier_BattleFactoryLobby's wall band, in a bucket
  -- that also holds FortreeCity_Gym's 26 wall light fittings and the two
  -- cable car stations' window brackets.  Every cut that admits the plant
  -- strips Fortree Gym.  So the cells are NAMED, and no discriminator is
  -- needed at all.
  --
  -- WHAT AN ENTRY SAYS, and it is three metatile ids and nothing else:
  --
  --   meta   the cell whose ABOVE-PLAYER layer carries the figure.
  --   under  what that cell wears once the figure is lifted off it.  It must
  --          be `meta`'s own LAYER 1 and the loader CHECKS THAT AT RUNTIME,
  --          pixel by pixel: `under` composited must equal `meta` composited
  --          everywhere `meta`'s above-player mask is clear, and `under` must
  --          have no above-player art of its own.  A figure that fails is
  --          dropped rather than half-applied, so a wrong id here leaves the
  --          wall exactly as it is instead of painting a hole in it.
  --   south  how many cells FORWARD the body stands.  1 everywhere so far:
  --          Emerald's overhead art always belongs to the cell in front.
  --
  -- EVERY OTHER NUMBER IS MEASURED FROM THE OBJECT IT STANDS ON.  The
  -- figure's height, its depth band and the drawn rows it occupies are read
  -- at build time from the standee already in `S.objectQuads` for the cell in
  -- front and from the above-player mask itself -- so the crown cannot drift
  -- from the pot it sits on, and a declared height cannot drift from a drawn
  -- extent.  (The crown's own rows 0..2 are fully transparent; nothing states
  -- 13 anywhere, it is what the mask measures.)
  -- ---------------------------------------------------------------------------
  -- HULLS -- one drawing a map lays down TWICE, overlapping, as one block
  -- ---------------------------------------------------------------------------
  --
  -- (g3-ketch-280.)  Emerald draws a tall thing across several cells, and it
  -- will happily draw TWO tall things across one block of cells when they
  -- overlap -- a second copy of the same art, offset, with the near copy
  -- painted over the far one.  Read cell by cell that block is unreadable:
  -- its masks come back nearly solid and the classifier calls it terrain.
  -- Read as a whole it is completely legible, because the offset is exact.
  --
  -- A figure here states three things and nothing else:
  --   `art`    the UNOCCLUDED drawing, as a block of metatiles.  Its outer
  --            frame must be background (open water, an empty floor), which
  --            is what makes the silhouette exact instead of a threshold.
  --   `block`  the COMPOSITE the map lays down, as a block of metatiles.
  --   `copies` where the drawing sits inside that composite, in DRAWN ROWS
  --            and columns, front-most last.
  --
  -- The pass rebuilds the composite's silhouette from the atlas and refuses
  -- the figure unless it is EXACTLY the union of the drawing at those
  -- offsets, texel for texel.  So `copies` is a claim that gets checked, and
  -- a wrong number leaves the map as it is rather than smearing a boat.
  --
  -- `depth` is the body's thickness in voxels.  5 is `PINNED_DEPTH.prop` --
  -- what the pinned pool already gives the unoccluded placements of this
  -- same drawing -- and it is here so the pair matches its own siblings, not
  -- because anything in the drawing states a depth.  NOTHING in the drawing
  -- states a depth: see the pass's own comment on the single view.
  hulls = {
    ["TILESET_03DF704_03DF764"] = {
      figures = {
        {
          -- SLATEPORT'S MOORED SAILING BOATS, south-east of Stern's
          -- Shipyard.  The user: "same with the ships that overlap next to
          -- the shipyard".
          --
          -- The map draws this boat FOUR times.  Three are the `art` block
          -- below, standing alone at (36..38, 37..38), (34..36, 44..46) and
          -- (35..37, 48..49), and the pinned prop pool already builds them
          -- (2384, 1681 and 1681 quads).  The fourth is the `block` below at
          -- (33..35, 35..38) -- twelve metatiles of its own that are the
          -- same boat drawn twice, sixteen pixels apart:
          --
          --     composite non-background texels, rows 8..63 : 1806
          --     union of the drawing at dy = 8 and dy = 24  : 1806
          --     symmetric difference                        :    0
          --
          -- Sixteen pixels is one cell, so the near boat is one cell south
          -- of the far one and the drawing says so exactly.
          --
          -- COLOUR agrees on 1756 of those 1806.  The other 50 are a shading
          -- retouch on the far boat's deck where the near hull crosses it;
          -- both boats here wear the unoccluded drawing, so the retouch is
          -- not reproduced.  It exists to make a 2D seam read, and at two
          -- depths there is no seam.
          name = "moored sailing boat",
          art = {
            w = 3, h = 3,
            meta = { 824, 825, 826,
                     832, 833, 834,
                     840, 841, 842 },
          },
          block = {
            w = 3, h = 4,
            meta = { 838, 839, 872,
                     846, 847, 880,
                     854, 855, 888,
                     862, 863, 896 },
          },
          -- far boat first, near boat last: the drawing paints the near one
          -- over the far one, and this pass stands them at the depths that
          -- ordering implies.
          copies = { { dx = 0, dy = 8 }, { dx = 0, dy = 24 } },
          depth = 5,
        },
      },
    },
  },

  -- ---------------------------------------------------------------------------
  -- BASINS -- A FOUNTAIN IS A RING IN PLAN, AND ITS PLAN IS WHAT IS DRAWN
  -- ---------------------------------------------------------------------------
  --
  -- (g3-basin-311.)  MOTIVATED BY THE WATER FOUNTAIN IN THE MIDDLE OF
  -- RUSTBORO CITY -- RustboroCity (27..29, 38..40), the 3x3 island of paving
  -- in the square outside the Pokemon Center.  Nine metatiles, laid once each,
  -- and it renders today as a lumpy low slab: the height field over its six
  -- tile columns reads 16 16 32 32 16 16 with four SKIP tiles along its south
  -- edge, on a street that is itself 16.  A kerb one course high with a bite
  -- out of one corner, and no water in it anywhere.
  --
  -- WHY THIS IS AUTHORED, AND WHY THE PREVIOUS REFUSAL WAS RIGHT TO REFUSE.
  -- The object crosses all nine cells and its edge is a CURVE that cuts them
  -- diagonally, so no per-cell height class can describe it -- a class gives
  -- one height to a whole cell, and the corner cells are part fountain and
  -- part street.  That refusal asked for four numbers Emerald does not state,
  -- and those four numbers are now supplied; they are the only stated numbers
  -- in this figure and each is marked STATED below.  Everything else is
  -- DERIVED, measured off the drawing, and the measurements are here.
  --
  -- THE DRAWING IS A PLAN, AND IT IS AN EXACT OCTAGON.  Composited over the
  -- nine metatiles the art is a 48x48 block; carved against this map's own
  -- floor colours (Gen3.shapeDataForMap) its silhouette is:
  --
  --     rows  0.. 1   nothing
  --     row      2    x 11..36      the north edge, 26 across
  --     rows  3..11   widening one pixel a side a row   the north chamfers
  --     rows 12..33   x  1..46      the east and west edges, 22 rows
  --     rows 34..45   narrowing one pixel a side a row  the south chamfers
  --     row     45    x 13..34      the south edge, 22 across
  --
  -- and the octagon `|x-23.5| <= 22.5 and |z-23.5| <= 22.5 and the two summed
  -- <= 34` reproduces rows 2..33 of that TEXEL FOR TEXEL -- THIRTY-TWO of the
  -- forty-four drawn rows, both north chamfers and both straight sides, every
  -- one EXACT.  It differs nowhere else except by FORESHORTENING, and by one
  -- pixel at the north edge and two at the south: the near kerb's own front
  -- face is the one place in this drawing where a row is height rather than
  -- depth, and it costs the plan two rows out of forty-four.
  --
  -- So the refusal's "the art is a PLAN, not an elevation" is exactly right
  -- and is the reason this works: a plan is what a ring wants.  What could not
  -- be done was to put a plan through a per-cell height class.  Stating the
  -- plan as a polygon and standing it costs no classifier and no threshold.
  --
  -- WHAT AN ENTRY SAYS:
  --
  --   block    the metatiles the figure is drawn on, as a w x h block, row
  --            major.  The pass requires all of them, laid in that shape, and
  --            builds nothing anywhere they are not.
  --   outer    the kerb's OUTER plan, as a half-extent and an L1 (diagonal)
  --            limit about the block's own centre.  Both DERIVED above.
  --   inner    the water's plan -- the same octagon inset by the kerb's width.
  --   jet      the spout's plan radius, about the same centre.
  --   kerb     how high the kerb stands on the street.  STATED.
  --   water    where the water surface sits.  STATED.
  --   crown    where the jet tops out.  STATED.
  --   face     the moulding PROFILE: one drawn column and the drawn rows that
  --            are the kerb's front face, read bottom-up, one drawn row per
  --            world pixel.  Same contract as a paling's `face`.
  --   lip      the drawn rows that are the INSIDE of the kerb, above water.
  --   plume    the drawn rows that are the jet's own body.
  --
  -- Every horizontal surface -- the kerb's top, the water, the jet's crown --
  -- wears the drawing's own texel at that plan position, 1:1, because the
  -- drawing IS the plan.  Nothing is stretched and nothing is repeated; the
  -- one exception is called out in Structures.buildGen3Basins and is a single
  -- pixel of rim.
  basins = {
    -- RUSTBORO CITY'S FOUNTAIN.  These nine metatiles on THIS PAIR are the
    -- fountain and nothing else: swept over all 518 maps, pair
    -- TILESET_03DF704_03DF734 (gTileset_General over gTileset_Rustboro) lays
    -- 824/825/826/832/833/834/840/841/842 exactly NINE TIMES IN HOENN, all
    -- nine on RustboroCity, one cell each -- this fountain.  The seven other
    -- maps built on gTileset_Rustboro (Route104, Route104_Prototype,
    -- Route116, PetalburgWoods, FarawayIsland_Entrance, SouthernIsland_
    -- Exterior and SouthernIsland_Interior) place none of them.
    --
    -- METATILE IDS ARE PER PAIR and these nine numbers are busy elsewhere:
    -- 1,187 other cells in Hoenn carry one of them on some OTHER pair, and
    -- the same 3x3 block of ids is SLATEPORT'S MOORED SAILING BOAT on
    -- TILESET_03DF704_03DF764, twenty rows above this one in this very file.
    -- Keying on the pair is therefore not a convenience, it is the whole
    -- correctness argument, and it is why there is no map id anywhere here.
    ["TILESET_03DF704_03DF734"] = {
      figures = {
        {
          name = "rustboro city fountain",
          block = {
            w = 3, h = 3,
            meta = { 824, 825, 826,
                     832, 833, 834,
                     840, 841, 842 },
          },

          -- THE KERB'S OUTER PLAN.  DERIVED: `half` is the drawn silhouette's
          -- own east and west edges, x = 1 and x = 46 on all twenty-two rows
          -- 12..33, about the block centre 23.5.  `diag` is the chamfer: the
          -- north edge runs x 11..36 on row 2, and 12.5 + 21.5 = 34.  Checked
          -- against every drawn row -- exact on all of 2..33.
          outer = { half = 22.5, diag = 34 },

          -- THE WATER'S PLAN, and it is the outer octagon inset by the kerb.
          -- DERIVED: on the thirteen rows 14..26 the drawing measures exactly
          -- SEVEN stone pixels from the silhouette to the first water pixel,
          -- on BOTH sides, every row -- so the kerb is 7 across and
          -- 22.5 - 7 = 15.5.  The water's own north chamfer then satisfies
          -- dx + dz = 25 EXACTLY on rows 7..12, which is where `diag` comes
          -- from; it is not 34 - 7*sqrt(2) = 24.1 and it is not fitted, it is
          -- read.  (The kerb is thus a shade narrower across a chamfer than
          -- across a flat, 6.4 against 7, which is what the artist drew.)
          inner = { half = 15.5, diag = 25 },

          -- THE SPOUT'S PLAN.  DERIVED: the stone island in the middle of the
          -- water measures 12 across (x 18..29) on row 25, and the two rows
          -- below it measure 8 and 4 -- that is one disc's own foreshortened
          -- front edge, not a taper -- so the spout is a disc of radius 6 on
          -- the block's own centre.  Row 27's four pixels are x 22..25, whose
          -- midpoint is 23.5: the drawing puts the spout dead centre.
          jet = { radius = 6 },

          -- ---- THE FOUR STATED NUMBERS, AND THEY ARE THE ONLY ONES -------
          --
          -- Emerald states no height for this object anywhere.  These four
          -- are supplied, not measured, and are marked so here and again at
          -- every use in Structures.buildGen3Basins.
          --
          -- kerb = 12   STATED.  The walker is 32 tall; this mod's furniture
          --             vocabulary is 8 = knee (32/4) and 16 = waist (32/2),
          --             and a public fountain kerb sits between them -- at
          --             the same 12 this mod ALREADY states for `tabletop`
          --             in JOINERY_H (lib/Structures.lua).  Reusing a number
          --             the mod already stands by rather than inventing one.
          -- steps = 1   STATED.  One kerb course.  The drawing shows a single
          --             moulded rim, not a tiered plinth, and the pass
          --             refuses any other value rather than guessing at what
          --             a second course would be made of.
          -- water = 9   STATED, as kerb 12 less a drop of 3.  Deep enough to
          --             read as water held in a basin, shallow enough that
          --             the basin does not look empty from a low camera.
          -- crown = 19  STATED, as water 9 plus a jet of 10 -- below kerb
          --             plus half a walker, so it never occludes the player's
          --             head.  CORROBORATED, and this is the only check the
          --             drawing can offer: the central stone runs drawn rows
          --             8..27, twenty rows, against a stated 19.  One pixel.
          kerb  = 12,
          steps = 1,
          water = 9,
          crown = 19,

          -- THE MOULDING, as a PROFILE: one drawn column, read bottom-up, one
          -- drawn row per world pixel.  DERIVED: column 24 is the block's own
          -- centre, where the near kerb is seen square-on and nothing stands
          -- in front of it, and rows 35..45 are its whole drawn front face --
          -- dark lip, two light courses, the shadowed astragal, and the
          -- ground line.  ELEVEN rows for a kerb stated at twelve; the pass
          -- does NOT stretch them to fit (see its note on the twelfth pixel).
          -- All eight faces of the ring wear this one profile, which is a
          -- rotation and not a smear: an octagonal kerb is the same moulding
          -- the whole way round, and the paling's log post is read the same
          -- way for the same reason.
          face = { col = 24, y0 = 35, y1 = 45 },

          -- THE INSIDE OF THE KERB, the three pixels of it that stand above
          -- the water.  DERIVED: rows 5..7 of column 24 are the only place in
          -- the drawing where the inside of the ring is drawn at all -- the
          -- far kerb's dark inner lip, its grey wall, and the waterline --
          -- and there are exactly three of them, which is exactly the stated
          -- drop.  Read top-down: row 5 is the lip at y = 11, row 7 the
          -- waterline at y = 9.
          lip = { col = 24, y0 = 5, y1 = 7 },

          -- THE JET'S BODY.  DERIVED: rows 18..27 of column 24 -- TEN drawn
          -- rows, which is exactly the ten world pixels the stated crown asks
          -- for, so this maps 1:1 with nothing left over and nothing
          -- repeated.  Row 27 is the spout's foot at the waterline (y = 9)
          -- and row 18 its head (y = 18).  The rows above 18 are the plume's
          -- highlights and are what the jet's LID wears, in plan, from the
          -- drawing's own texels.
          plume = { col = 24, y0 = 18, y1 = 27 },
        },
      },
    },
  },

  overhead = {
    -- (the hull figures above are a different statement: those name a whole
    --  drawing and where a composite block places copies of it; these name
    --  one metatile whose above-player layer belongs to the cell in front.)
    -- MauvilleCity_GameCorner's three potted plants, (5,1) (6,1) (7,1).
    -- Reported twice: "the bushes are floating and their tops are showing
    -- flat on the wall", then "the plants in the back are missing their tops
    -- and theyre flat on the wall instead of being on top of the plant".
    --
    -- THE FIGURE HAS EXACTLY ONE SITE AND CANNOT LEAK.  Metatile 559 on this
    -- pair is placed on ONE MAP in all 518, swept -- this one, three cells.
    -- Compare the palings, which had to cover 132 cells on 3 maps and 426 on
    -- 12.
    ["TILESET_03DF884_03DFB84"] = {
      figures = {
        {
          name = "game corner potted plant crown",
          meta = 559,
          under = 538,
          south = 1,
        },
      },
    },
  },

  primaries = {
    -- fences authored on a pair's PRIMARY tileset
    ["03DF704"] = {
      palings = {
        {
          -- -----------------------------------------------------------
          -- THE GENERAL WHITE RAIL FENCE
          -- -----------------------------------------------------------
          --
          -- In-game: SlateportCity's promenade and market rails (111 cells),
          -- Route 123's field boundaries (75), Route 110's cycling road
          -- verges (73), Route 117 (49), both Battle Frontier approaches
          -- (51), Route 115, Route 104, Route 111, PetalburgWoods, Route 112,
          -- MauvilleCity.  443 blocked cells on 15 maps; the twelve pieces below cover 426 of
          -- them (metatile 308 is refused -- see the piece list).
          --
          -- IT IS NOT THE LOG PALING AND MUST NOT CONVERGE WITH IT.  Metatile
          -- 329 draws two posts AND TWO FULL-WIDTH HORIZONTAL RAILS (drawn
          -- rows 5..8 and 12..13); metatile 657 draws two posts and nothing
          -- between them.  Every texel below comes from 329 and 320, so a
          -- Slateport rail looks like a Slateport rail.
          name = "general white rail fence",

          -- THE POST.  Every number read off the drawing:
          --   w = 4   drawn columns 2..5 of 329, the run between the rails
          --   d = 4   drawn columns 2..5 of 320 -- the fence's own body in
          --           plan.  Columns 6..7 of 320 are NOT the fence: they are
          --           rgb(65,74,106), the same dark the fence's ground shadow
          --           is drawn in, they bulge only EAST (in 322 as well as in
          --           320, never west), and they are the CAST SHADOW.  A
          --           silhouette that took them would have made the post two
          --           pixels fatter on one side only.
          --   h = 12  drawn rows 3..14 of 329 in those columns
          -- and w == d, which is what a square post should measure and is the
          -- first place the two views agree.
          post = { w = 4, d = 4, h = 12 },

          -- THE ELEVATION and THE PLAN, and they agree three times over:
          --   pitch     329's posts are at columns 2..5 and 10..13 -- 8.
          --             320 repeats exactly at 8 rows.
          --   width     329's post is 4 columns.  320's body is 4 columns.
          --   top face  329 draws the post's top at rows 3..4 in
          --             rgb(189,205,230)/rgb(255,255,255); 320 draws exactly
          --             the same two lit colours at rows 1..2 and 9..10 --
          --             the same post top, once as the top of an elevation
          --             and once as a plan.
          face = { meta = 329, x = 2, y0 = 3, y1 = 14 },
          top  = { meta = 320, x = 2, z = 0 },

          -- THE RAILS -- the element the log paling does not have, and the
          -- reason this is a second figure rather than a second list.
          --
          -- A rail is CONTINUOUS where a post is DISCRETE, so its unit is the
          -- cell rather than the 8px station, and it is stated as a SPAN.
          -- Each rail's height comes from the drawn rows of its FACE, and its
          -- depth from the drawn rows of its TOP: in 329's between-post
          -- columns the upper rail is rows 5..6 in the lit shades (its top
          -- surface, seen from above) over rows 7..8 in the body shade (its
          -- front face), which is a rail 2 pixels tall and 2 pixels deep.
          --
          --   rail A (upper)  face rows 7..8   -> world y 6..8   DERIVED
          --                   top  rows 5..6   -> depth 2        DERIVED
          --   rail B (lower)  face rows 12..13 -> world y 1..3   DERIVED
          --                   depth 2                            STATED
          --
          -- Rail B's depth is the ONE number in this file that the drawing
          -- does not state.  Its top face is drawn inside rail A's shadow --
          -- row 12 between the posts is rgb(65,74,106), the shadow colour,
          -- not a lit top -- so there is no lit run to measure it by, and it
          -- is copied from rail A.  Said plainly rather than dressed up.
          rails = {
            { face = { 7, 8 },   top = { 5, 6 } },
            { face = { 12, 13 }, depth = 2 },
          },

          -- WHERE THE POSTS AND THE RAILS GO, PIECE BY PIECE.
          --
          -- A north-south lane hugs one side of its cell -- drawn columns
          -- 2..5 on the west-drawn pieces, 10..13 on the east-drawn ones --
          -- and carries a post at each 8px station, z = 4 and z = 12.  An
          -- east-west run carries a post at x = 2 and x = 10, both at z = 12.
          -- Both stations are taken from the fence's own GROUND SHADOW: the
          -- full-width dark band at drawn rows 12..13 of 329, 328, 330, 312,
          -- 314 and 306 lies in the ground plane, so it states a DEPTH even
          -- in an elevation, and it is the same convention (and the same
          -- offsets) the log paling already ships with, so the two fences
          -- meet on one grid where a map draws both.
          --
          -- The alternative reading is in the plan's lit post tops, at rows
          -- 1..2 and 9..10, which would put the stations at z = 0 and z = 8.
          -- Those are the tops of posts drawn PROUD of the ground -- Emerald
          -- draws a tall thing higher up the cell, which is why a tree needs
          -- two cells -- and taking them as a footprint would put the fence
          -- four pixels north of its own shadow.  Only a frame can settle it.
          --
          -- A rail SPAN is { axis, lane, from, to } in cell-local pixels:
          -- `axis` is the direction it runs, `lane` the cross-axis offset it
          -- shares with the posts, and `from`..`to` the piece's own occupied
          -- columns or rows.  The rail is centred in the post's depth rather
          -- than proud of it, because the drawing shows the posts OCCLUDING
          -- it -- rows 5..8 of 329 are the rail's colours only between the
          -- posts and the post's body colour across them.
          pieces = {
            -- north-south, running through the cell
            [320] = { posts = { { 2, 4 }, { 2, 12 } },
                      rails = { { "z", 2, 0, 16 } } },
            [322] = { posts = { { 10, 4 }, { 10, 12 } },
                      rails = { { "z", 10, 0, 16 } } },
            -- north-south, the NORTH end of a line: drawn row 0 is empty --
            -- the line BEGINS in this cell -- and the two post tops are at
            -- rows 1..2 and 9..10 exactly as in 320/322, so both stations
            -- carry a post and only the rail is shortened at the top.
            [313] = { posts = { { 2, 4 }, { 2, 12 } },
                      rails = { { "z", 2, 1, 16 } } },
            [321] = { posts = { { 10, 4 }, { 10, 12 } },
                      rails = { { "z", 10, 1, 16 } } },
            -- north-south, the SOUTH end of a line: the drawing closes with
            -- the same full-width ground shadow an east-west run ends on, at
            -- rows 12..14, so the last post is the z = 12 station and the
            -- rail stops on it.
            [306] = { posts = { { 2, 4 }, { 2, 12 } },
                      rails = { { "z", 2, 0, 14 } } },
            [307] = { posts = { { 10, 4 }, { 10, 12 } },
                      rails = { { "z", 10, 0, 14 } } },

            -- east-west, running through the cell: two posts across and both
            -- rails the full width.
            [329] = { posts = { { 2, 12 }, { 10, 12 } },
                      rails = { { "x", 12, 0, 16 } } },
            -- (metatile 308 is the same east-west run WITH A BAND drawn
            -- above it -- rows 0..1 full width, material `manmade`, and the
            -- role table gives it `face = 2`, so those two rows are a drawn
            -- FACE and not ground: the low kerb the fence stands on at the
            -- Battle Frontier's west approach and on Route 110's causeway.
            -- It is REFUSED, all 13 cells of it on 2 maps.  Claiming the
            -- cell paints its art back as ground, and that would delete a
            -- step this round has not measured -- on a map g3-causeway-273
            -- has just rebuilt.  A fence with a kerb under it needs the kerb
            -- modelled too, and that is not this round.)

            -- the corners.  328 brings the north-south lane down the WEST of
            -- the cell and turns EAST; 330 is its mirror.  Each carries the
            -- lane's own two posts AND the east-west post, so a boundary
            -- reads as one fence through the turn instead of stopping at it.
            [328] = { posts = { { 2, 4 }, { 2, 12 }, { 10, 12 } },
                      rails = { { "z", 2, 0, 12 }, { "x", 12, 2, 16 } } },
            [330] = { posts = { { 10, 4 }, { 10, 12 }, { 2, 12 } },
                      rails = { { "z", 10, 0, 12 }, { "x", 12, 0, 14 } } },
            -- ...and the two that turn SOUTH: 312 runs east-west and drops a
            -- lane out of the cell's south-west, 314 out of its south-east.
            [312] = { posts = { { 2, 12 }, { 10, 12 } },
                      rails = { { "x", 12, 2, 16 }, { "z", 2, 12, 16 } } },
            [314] = { posts = { { 2, 12 }, { 10, 12 } },
                      rails = { { "x", 12, 0, 14 }, { "z", 10, 12, 16 } } },
          },
        },
      },
    },
  },

  tilesets = {
    -- fences authored on a PAIR'S OWN SECONDARY tileset
    -- ---------------------------------------------------------------------
    -- THE MAUVILLE LOG PALING
    -- ---------------------------------------------------------------------
    --
    -- In-game: the property line round MauvilleCity's Game Corner and Bike
    -- Shop, and the same fence again on Route 111 and Route 117.  This pair
    -- (general primary + Mauville secondary) is the only one in Hoenn that
    -- carries these metatiles as this fence -- swept over all 518 maps, the
    -- eleven pieces below appear on MauvilleCity (79 cells), Route 111 (26)
    -- and Route 117 (27) and nowhere else.  Metatile ids are PER PAIR, so
    -- 650 in an interior pair is an unrelated drawing and is untouched.
    ["TILESET_03DF704_03DF77C"] = {
      palings = {
        {
          name = "mauville log paling",

          -- Read off metatile 657 (the east-west arm): its west post is
          -- drawn in columns 1..5 -- five wide -- over rows 4..14 -- eleven
          -- tall -- with rows 4 and 14 narrowed to three columns for the
          -- log's rounded ends.  Eleven is also the height the arm that
          -- ALREADY LOOKS RIGHT stands at today (the sprite carve gives it
          -- `lowY - ly` = 14 - 4 = 10 plus its own row), so the model does
          -- not move the half of this fence that is already correct.
          --
          -- Depth is read off metatile 650 (the north-south arm): each 8px
          -- station carries the post's drawn head over rows 4..7, four
          -- pixels through.  Post pitch is 8 and post depth is 4, so the
          -- gap between two posts one behind another is 4 -- which is the
          -- same gap 657 draws between two posts side by side (5 wide at a
          -- pitch of 8, three columns of background).  The two views agree.
          post = { w = 5, d = 4, h = 11 },
          face = { meta = 657, x = 1, y0 = 4, y1 = 14 },
          top  = { meta = 650, x = 9, z = 4 },

          -- WHERE THE POSTS STAND, PIECE BY PIECE.
          --
          -- A north-south lane hugs one side of its cell -- columns 1..5 on
          -- the west-drawn pieces, 9..13 on the east-drawn ones -- and
          -- carries a post at each 8px station, z = 4 and z = 12, which is
          -- where 650 draws its two heads.  An east-west run carries a post
          -- at x = 1 and x = 9, both at z = 12, which is where 657 draws its
          -- feet (row 14) and where 640/642 draw the fence's base band (rows
          -- 12..15).  So along a line in either direction the posts fall at a
          -- pitch of exactly 8 and a corner closes without a gap.
          pieces = {
            -- north-south, running through the cell
            [648] = { { 1, 4 }, { 1, 12 } },   -- lane on the WEST of the cell
            [650] = { { 9, 4 }, { 9, 12 } },   -- lane on the EAST of the cell

            -- north-south, the SOUTH end of a line.  The drawing (rows 0..13
            -- a plain 5px bar, row 14 the rounded end) shows no post head at
            -- all -- past the last post you are looking along the rail -- so
            -- the rank is continued rather than broken: a fence does not skip
            -- its last post, and a gap here would read as a missing one.
            [689] = { { 9, 4 }, { 9, 12 } },
            [690] = { { 1, 4 }, { 1, 12 } },

            -- north-south, the NORTH end of a line: rows 0..3 are empty --
            -- the line BEGINS in this cell -- and its one drawn head is at
            -- rows 12..15, so one post and no more.
            [697] = { { 9, 12 } },
            [698] = { { 1, 12 } },

            -- east-west, running through the cell: two posts across.
            [657] = { { 1, 12 }, { 9, 12 } },

            -- east-west, the two ends of a run.  Same two posts with the
            -- base band drawn under them; they are the metatiles the report
            -- calls "the cap sitting on the end as a round disc", because
            -- `Gen3.classAt` sends them to `cylinder` and buildCylinders
            -- lathes them.  A fence end is a post, not a bollard.
            [640] = { { 1, 12 }, { 9, 12 } },
            [642] = { { 1, 12 }, { 9, 12 } },

            -- the corners.  656 draws the north-south lane in its WEST half
            -- and an east-west post in its EAST half; 658 is the mirror.
            -- Each carries BOTH lines' posts so a property line reads as one
            -- continuous fence instead of stopping at every turn.
            [656] = { { 1, 4 }, { 1, 12 }, { 9, 12 } },
            [658] = { { 9, 4 }, { 9, 12 }, { 1, 12 } },
          },
        },
      },
    },
  },
}
