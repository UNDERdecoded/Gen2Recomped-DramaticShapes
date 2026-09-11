# Hoenn Voxel Plan — Phase A inventory, class list, Route 110 design

Status document for extending DRAMATIC_SHAPE's voxel pipeline to Emerald.
Written against `Structures.SHAPE_REV = "g3-reach-75"`.  Everything marked
SHIPPED exists in the tree today and has 229/229 tests green; everything
marked GAP is proposed, not written.

A note on where profiles live: the spec says "voxel_heights.lua profiles".
Gen 3 deliberately does NOT share that file — Gen 2 collision classes and
Gen 3 behaviour bytes are two unrelated numberings that overlap end to end
($02 is tall grass here and a wall class there), so Gen 3 profiles live in
`data/gen3_shapes.lua` (behaviour table + per-tileset overlays + per-map
overlays + metatile pins).  Same resolution order as the spec requires:
authored pin > structure/scenery detection > behaviour+collision fallback >
wall.  That file is the Phase C target.

---

## Phase A — inventory

518 maps resolve tilesets; 82 outdoor; **73 distinct tilesets**.  The census
(name → maps using it) is reproducible with `/tmp/t/inv2.lua`; the rows that
drive the priority list:

| Tileset | Maps | Covers | Profile today |
|---|---|---|---|
| gTileset_General | 227 (all 82 outdoor) | primary of every exterior | behaviour table only (correct: it is the shared half) |
| gTileset_Building | 267 interiors | every indoor primary | kitchen/furniture pins (Brendan/May) |
| gTileset_PokemonCenter | 34 | every Center | counter pins SHIPPED |
| gTileset_Cave | 44 | Granite, Desert Ruins, Victory Rd… | `rock_plateau` SHIPPED (g3-rock-64) |
| gTileset_SecretBase* | 24+24 | secret bases | GAP (low priority) |
| gTileset_Shop | 23 | every Mart | GAP: shelf rows |
| gTileset_BattleFrontier* | ~70 | frontier | GAP (post-QA-list) |
| gTileset_Lavaridge | 13 | Mt Chimney, Jagged Pass, Fiery Path | GAP: exterior slope maps |
| gTileset_Pacifidlog | 14 | Pacifidlog, **SkyPillar_Outside**, Seafloor rooms | log class ships; Sky Pillar GAP |
| gTileset_Underwater | 12 | dive maps | stub `{}` — flat water volume, per spec "do not block on underwater" |
| gTileset_Fortree | 4 | Fortree, Routes 119/120 | course=32 map override ships |
| gTileset_Mauville | 6 | Route 110 | causeway ships |
| gTileset_Sootopolis | 1 | the crater | tent_roof, cliff rim, gate pins ship |
| gTileset_Slateport | 3 | harbour | stalls, lighthouse, boats ship |
| gTileset_MeteorFalls | 5 | Meteor Falls | `rock_plateau` SHIPPED (g3-rock-64) |
| gTileset_TrickHousePuzzle | 8 | Trick House | GAP |
| one-off gyms/museums (12 tilesets) | 1–2 each | interiors | gym shell/fabric ships; furniture pins per room GAP |

Gen 1 class analogy mapping is already done structurally: `Gen3.classAt`
translates behaviour+collision+layer into the SAME class vocabulary
TileShape has always had, so every Gen 1 class applies to Hoenn art with no
per-tile table.  The flagged gaps are the classes below.

## Phase B — class list (existing vs proposed)

Units: cell = 16px, course = 16, wall = 16, roof = 28 (unchanged).

SHIPPED classes already covering spec items (heights from TileShape):
`ground 0, water -2/-4, ledge 6, fence 10, sign 12, wall 16, terrace 16,
roof 28, cylinder 16, canopy 32, stump 16, can 9, shell 32, counter 8,
post (per-pixel), prop/billboard (per-pixel slab), signpost 16,
bridge 4+lift·16, log 2, slope (neighbour-derived), waterfall,
stair_e/w/n + stair_down_e/w` — plus non-class machinery the spec names as
primitives: `run.face` (a cliff IS the drop, continuous texture, no
re-striping), drawn-terrace reconstruction (longest-chain levels), tent
roofs (gable+hips, profile-gated), stall decks (awning slab + skirt fascia
+ post pins), under-deck continuation plates.

PROPOSED new classes (Phase B patch, in priority order):

1. ~~`stair_s`, `stair_down_s`~~ — **superseded by `flights`, SHIPPED
   `g3-flight-62` as `Structures.buildGen3Flights`.**  The measurement that
   changed the design: Emerald's interior staircases are not one-cell
   flights at all.  A Pokémon Center's is a 2×3 block of six metatiles, and
   pinning those six `stair_w` (the obvious cheap fix — tried, rendered,
   rejected) gives six independent 16px flights side by side: shredded
   corrugation, visibly worse than the flat slab it replaced.
   What ships instead re-grounds the whole REGION as a ramp of 8px
   tile-column steps (Center 1F measures 16/11/5/0 west-to-east), and lets
   the mesher's ordinary side-band fold cut the risers from each column's
   own art.  No new hull, no new class — a profile list
   (`flights = {{ dir, tiles }}`) rewrites shapes that already resolved, so
   TileShape, voxel_heights and every unknown-tile fallback are untouched.
   Direction is read off the drawing: the treads are horizontal luminance
   bands in column groups (x0-6, x8-14, x16-30), each starting three rows
   lower than the group west of it — a flight climbing west, into the wall.
   Still open: the DESCENDING half (Center 2F, 664/665/672/673/680/681).
   A well cut below an interior floor needs the room plane to close around
   the hole.  Until that is built 2F stays flat, with 672 pinned `ground`
   so it at least stops standing up as a 12px tabletop in mid-staircase.
2. `pillar` — SHIPPED `g3-pier-61` as `Structures.buildGen3Pillars`.
   Timber is found by colour (the only warm mass in a blue-grey sea
   palette), split into the vertical column runs the art draws, and each
   run stood up as its own square post from the water surface to the deck
   it carries.  Two guards earn their keep and should be kept when
   Pacifidlog and Sky Pillar reuse this: a post occupies at most HALF its
   cell's height and touches NEITHER cell edge — without both, Route 110's
   brown cliff tile 400 (inked down all 16 rows, hard against x=0) reads
   as a 4px post standing in the sea beside every deck it adjoins.
   Scope is open water only; shoreline abutments (864/867/872/875 — half
   post, half grass, half deck) are left to the terrace passes, because
   vacating one to water sinks the beach it is drawn on.
3. ~~`deck_edge`~~ — **NOT NEEDED; the real defect was underneath, and it
   is fixed in `g3-underspan-63`.**  Rendered and looked at, the parapet
   the kerb footing builds is already right: the cycling road's edge rows
   fold as a fascia band of the drawn blue-grey parapet, and Fortree's
   walkway ends and the harbour lips do the same.  A class would have been
   machinery for a problem that was not there.
   What WAS there: the under-span vote could only see a deck cell's four
   neighbours, so it answered for the EDGE of a span and went blank in its
   middle.  On the three-cell-wide cycling road the centre column's
   neighbours are all deck — 55 of Route 110's 185 elevated cells and 253
   of its low crossings laid no ground at all and showed a black hole
   straight through the mesh, framed by the plates their own edges laid.
   The fix carries the resolved surface INWARD across deck cells,
   breadth-first (so a span crossed by another takes the surface of the
   edge nearest it), and only where the carried surface really is below
   that deck.  Route 110 goes 242 → 552 under-deck cells, every deck cell
   covered; Fortree 20, Pacifidlog 38, Route 119 16, all verified as no
   visible change beyond the holes closing.
4. `awning` — formalise the stall pass trigger as a class instead of a
   profile list, so Safari Zone tents and Magma/Aqua camp canvas reuse it.
   Peaked variant (`tent`) = same slab with a ridge (two half-slabs), door
   flap cell stays air.
5. `cliff_band` (replaces cliff_2/cliff_3 idea) — NOT new geometry: a pin
   that forces `run.face` treatment at authored top height, for the few
   exterior slopes where the elevation field lies (Jagged Pass is one
   continuous scree — the detector will want region evidence it cannot
   have).  Height field on the pin: `{ class="cliff_band", top=3 }` courses.
6. `floor_hole` — interior stairwell well (down-stairs excavate).  Exists
   for gen1/2 (`stair_down_*`); Gen 3 interiors need the pin plumbed
   through `gen3_shapes.metatiles`.

Explicitly NOT adding: `plateau_top` (rim-once-then-body already does
this via run.face + terrace tops), `hover_path` (bridge+lift IS it),
`dock` (deck at lift 0 over water — bridge with lift 1 covers it),
`treehouse` (Fortree ships on course=32 + ordinary buildings).

## Route 110 hover-path design (mostly SHIPPED, remainder listed)

Shipped model, validated in-game and offline:
- The route's elevation field is traffic control, not terrain (no cliff is
  drawn anywhere).  `maps.Route110 = { causeway = true }`: land flattens to
  the datum (sea keeps its recess), and EVERY bridge-behaviour cell takes
  its full ROM lift (`MB_BRIDGE_OVER_OCEAN` = 2 courses → deck top 36px),
  so causeway and crossings sit flush instead of the crossing hovering.
- Under every span the world continues: each bridge cell lays a plate at
  the commonest flat neighbour's height wearing its art (sea between
  piers); a span over another span continues the LOWER deck.
- Occlusion/standing: entities carry the cartridge's own elevation
  (MULTI keeps the level you arrived with).  `groundAt` picks deck vs
  datum from it — a walker passes under while a biker rides over.
- Mesh cache: any Gen3/data change MUST bump `Structures.SHAPE_REV` or the
  disk cache serves stale geometry (this bit us; treat as checklist item).

Remaining for Route 110 DONE:
- [x] `pillar` uprights at the drawn pier cells — SHIPPED `g3-pier-61`.
      18 piers, 23 posts.  **The finding that closes this item honestly:
      the ELEVATED cycling road has no drawn supports.**  Every cell
      adjoining a 36px deck on this map is timber-free (measured); the only
      timber in the water is the plank crossings' own posts — metatile 797
      (a pair, with its cross-brace), 840/841/842/843 (one post, span end)
      and 776/780 (posts under a deck drawn in the same cell).  Inventing
      columns under the flyover would be exactly the Stadium-style
      invention the spec forbids, so none are built there.
      Before: 797 stood as one solid 10px BLOCK of pier art in open sea
      (`railLooksLikeFence` rejects it — the timber is 8 rows, the test
      wants 10) and 840/841 lay painted flat on the water.
- [x] Deck fascia — the kerb-footed parapet renders correctly; no class
      needed.  The holes UNDER the span were the real defect and are
      closed in `g3-underspan-63` (see Phase B item 3).
- [ ] Trick House clearing QA (grass/fence props under the deck's shadow).
- [ ] In-game walk video N→S: on-deck, underpass, dismount ramp.

## Cave rock — `rock_plateau`, SHIPPED `g3-rock-64`

The largest untouched family, and the diagnosis was not what the symptom
looked like.  A cave draws sand with dark rounded ridges through it, and
everything unreachable is blocked — so two thirds of Granite Cave 1F
promotes to `wall`, floods into ONE region, and gets measured as a run.
The measurement then finds a vertical PERIOD in it, because the cave
floor's hatch texture repeats every sixteen pixels: `fromRepeat=true,
extent=34, unit=2`.  The rock mass was read as a building's storeys, and
the mesher tiled the run's first two rows down all thirty-four of them.

So it was never a stretched texture; it was the WRONG texture, repeated.
Seen from directly overhead the cave was vertical smears of ridge art
across open sand — which is why looking at a plan render, not just an
angled one, is what found it.

A cave's rock is none of the things a run is for: no storeys, no roof, no
door, no facade.  It is a mass with a top, and the top wears whatever the
drawing puts there, cell by cell.  `Structures.buildGen3RockPlateaus`
drops the run and re-grounds the mass one course up; each cell keeps its
own art and the mesher's ordinary side-band fold cuts the drop where a
corridor meets it.  Granite Cave 419 cells, Meteor Falls 573, Victory Road
1371 — all three rendered against their 2D and matching.

Gated two ways, deliberately: by profile (`rock_plateau` on
gTileset_Cave and gTileset_MeteorFalls), because "blocked mass with a
period in it" also describes a perfectly good building facade; and on
`not S.outdoor`, because these are SECONDARY tilesets and a secondary can
in principle be paired into an exterior layout, where flattening a cliff
to one course would undo the terrace machinery.  Only cells that promoted
to `wall` are taken — props, ledges, water, tabletops and every profile
pin keep the class they resolved to.

## Cave terraces, bridges and stairs — `use_elevation`, SHIPPED `g3-tier-65`

`rock_plateau` gave a cave one floor and one ceiling.  It has two, and the
cartridge says so: Victory Road 1F carries 430 walkable cells at level 3
and 203 at level 4, plus 30 at ELEV_MULTI.  All of it was being thrown
away, because indoor maps discard the elevation field — a good rule, since
indoors Emerald uses elevation for sprite priority and ranking that into
courses stands a step in the middle of a carpet.

A cave is the exception, and the measurement separates the two cases
cleanly.  Non-datum levels in a cave form large connected REGIONS —
Victory Road ten of them, largest 61 cells; Meteor Falls two, largest 22;
Shoal Cave one of 66.  Pokémon Center 1F carries exactly ONE cell at level
4.  That is the priority flag, and it stays discarded.

`use_elevation = true` on the cave profiles gives three things at once:

- **Floors sit on their own tier**, so a terrace's ground is level with the
  cliff edge beside it instead of everything lying on the datum.
- **ELEV_MULTI cells become real decks**, a course over what they span —
  the bridges float.
- **Ramps step.**  Victory Road's flights are metatile 516 in runs of
  three, and `rampHeightAt` already reads them: 16 → 12 → 8 → 4 → 0.  Four
  risers, as deep as a 16px tier allows.

Two follow-on fixes the tiers exposed:

- Rock is footed on the highest floor it TOUCHES and that footing spreads
  inward by NEAREST, not by maximum.  Carrying the maximum looked
  reasonable and was wrong: it flooded the upper tier through every
  connected wall until 1064 of Victory Road's 1361 rock cells stood at 32,
  one uniform ceiling with the terrace edge erased from the middle of the
  map.
- A deck is not a floor to stand rock on.  Counting a crossing as footing
  founded the wall beside it at 32 and stood it to 48 — a tower of rock
  growing out of the bridge, 27 cells of it.

...and one in the walker, which is where the "teleports me on top of the
bridge" report actually lived: `groundAt` decided deck-versus-underpass
from the voxel CLASS, and Victory Road's crossings carry no bridge
behaviour at all — they are ordinary floor metatiles whose only statement
of "deck" is elevation 15.  Thirty perfectly ordinary `ground` cells, and
every walker was lifted onto them.  It now keys on ELEV_MULTI itself, and
answers at the walker's OWN tier rather than at the datum: a cave bridge
spans an upper terrace as readily as a lower one, and answering 0 under
one dropped the walker through the floor they were standing on.

### Follow-up `g3-flush-66` — flush floor, and decks that are really decks

Two reports off the first tier render, both real.

**"Cliff edges sitting higher than the walkable area rather than flush."**
They were not cliff edges.  `rock_plateau` raised every blocked cell, and a
cave's blocked area is not all ridge: Victory Road blocks 1386 cells and
draws **689 of them in the FLOOR's own metatiles** — plain hatched sand,
the backdrop behind a ridge and the pockets it encloses.  Raised with the
ridge, those stood as pale sand plateaus a course over the floor beside
them.  `Gen3.floorMetatiles` already answers this per map (the metatiles
the map itself places on walkable cells, which is floor by definition), so
the split is free: floor art stays FLUSH with its tier, only art the map
does not use as floor rises.  609 of Victory Road's 1131 now sit flush.

**"The bridges aren't floating."**  They were solid plinths of rock with
planks printed on the lid, and the reason is a good one to write down: the
class cache is keyed on `m * 2 + blocked` — the **metatile**, not the cell
— so the ELEV_MULTI rule, sitting after the cache lookup, was unreachable
the moment that same metatile had been asked about anywhere else on the
map.  Victory Road's decks are drawn in the floor's own metatiles, so the
answer was always already cached as `ground` and the rule never once ran.
Any per-cell rule in `classAt` must go ABOVE the lookup and must not write
to it.  (The pre-existing ELEV_SURF rule has the same shape and gets away
with it only because surf metatiles are water everywhere they appear.)

Two consequences followed:

- The under-span pass was outdoor-only, so the moment the crossings
  resolved `bridge` they floated over nothing — daylight under the span and
  a black slot straight through the mesh.  It now runs on any map whose
  elevation field means height.
- `groundHeight` measures a deck from its own four neighbours, which is
  right for a long causeway and wrong for a short crossing: a cave bridge
  from a terrace at 16 over a chasm at 0 to a terrace at 16 had its two END
  cells measure 16 and stand at 36 while its middle measured 0 and stood at
  20 — stepping sixteen pixels down and back up in mid-air, and the exposed
  flank of that step was the black beside every bridge.
  `Structures.levelGen3Decks` levels a short run to the banks it connects
  plus the deck's own plank thickness.  Levelling to the max of what the
  cells already measured was tried first and only spread the error.

**Scoping, and what it deliberately leaves alone.**  Both the deck class
rule and the levelling pass are restricted to `use_elevation` maps.  Tried
unscoped, they moved Route 110, Route 119 and Pacifidlog.  Routes 110 and
120 and Fortree turn out to be unaffected either way (their decks already
reach `bridge` through the behaviour byte) — but **Route 119 is a real
find**: its six river crossings are 22 cells that state only elevation, and
they measure ragged, 52 at the ends and 36 in the middle.  The same mid-air
step.  Enabling the class rule there without the levelling would leave six
hollow, stepped bridges on a map nobody has reported, so Route 119 gets
both together, verified as its own change.  That is the next item after the
waterfalls.

### `g3-underfill-67` — the ground under a span, and a check worth keeping

Report: the deck should be elevated and flat, and the ground texture should
replicate under it where the tiles are voided.  Flat and elevated were
already right after g3-flush-66; the void was real and was on a map I had
not looked at.

**The measurement that found it.**  Rendering a map over a MAGENTA
background and flood-filling from the image border separates "no geometry"
from "dark texture", and any magenta blob not touching the border is a hole
straight through the mesh.  Victory Road 1F, Granite Cave and Meteor Falls
all scored zero at three pitches — and Victory Road **B1F** scored 570px,
a clean slot directly under its bridge.  Worth keeping as a standing check;
it costs one render and it does not depend on my noticing a dark patch.

**The cause.**  The under-span vote considered every flat neighbour, and a
deck's commonest neighbour is usually its own BANK — which sits at deck
level, is not under the span at all, and then fails the `bestH < deckH - 4`
test that follows.  On B1F all eight deck cells voted for the terrace at 16
under a deck at 20, every one was rejected, and with no cell seeded the
inward flood (g3-underspan-63) had nothing to carry.  A hole needs both
failures: the vote picking the wrong surface AND every cell in the run
failing together.

**The fix.**  What is under a bridge is lower than the bridge, so the
candidates are restricted to neighbours below the deck.  Costs nothing
where the old vote already picked one — Route 110's sea is far below its
road, and 110, 119, 120, Fortree and Sootopolis are byte-identical.
Pacifidlog moves by a tile choice under its log walkways, rendered and
checked as no visible change.

Verified after: every cave map swept scores zero interior void px, and
every deck run in every cave measures flat (Victory Road 1F four runs, B1F
two, B2F two, Meteor Falls one).

### `g3-brow-68` — a cliff edge is the top of its own drop

Report: metatile textures stretched on cliff edges, and many cliff edges
sitting a block higher than the walkable terrace they lead up to instead of
flush with it.  Both real, and they turned out to share a cause with a
third thing nobody had reported.

**Flush.**  A ridge that separates a floor at 0 from a terrace at 16 is the
FACE between them: you walk the upper terrace right up to it and look down,
so its top IS the upper terrace.  Giving it the usual course of lift stood
a 16px lip along the brow of every drop.  Whether a given edge happened to
look right before was luck — it depended on which neighbour won the `base`
maximum.  Ridge that borders only one tier is not a cliff edge, it is a
wall in the middle of a floor, and it keeps its lift.

**The stretch.**  The band rule — each 8px course wears one whole tile of
art — is right for a texture that tiles, and cave rock does not: the ridge
tile IS the face, drawn once, brow at the top and foot at the bottom.
Stacked two or four deep it reads as the same lip repeated down the drop.
Rock cells are now marked and map their own tile continuously over the
whole face; where the drop is one course this is the old behaviour to the
pixel, and no other flat cell is touched.

**`run.face` should never have been excluded.**  It marks a measured cliff
face — the right treatment for a drop, and the reason those cells never
showed the stacked-tile smear — but it also keeps the height the run
MEASURED, and in a cave the elevation field is the authority on height, not
the art.  240 of Victory Road 1F's cliff cells and 133 of Meteor Falls'
kept a measured top and stood proud while every cell beside them went
flush.  That is most of "much of the cliff edges".

**And a cave has no tables.**  The furniture detector reads a flat pale
band as a table top, and cave rock has plenty: 6 cells in Victory Road 1F,
16 in B1F, 10 and 16 in the two Meteor Falls rooms — each a 12px slab
standing in the middle of a cliff.  Same misfire that put a tabletop in the
middle of a Pokémon Center staircase.  On a `rock_plateau` tileset the
class is simply not available.

Measured after, over every cave floor: tier-separating ridge cells not
flush with the terrace above went 41 → 1 (Victory Road 1F), 20 → 1 (B1F),
20 → 0 (B2F), 61 → 0 and 47 → 0 (Meteor Falls 1F/B1F).  The two stragglers
sit beside RAMP cells, whose height is an interpolation rather than a tier,
and are an ordering effect in the pass — two cells in the whole family.
Void sweep still zero everywhere; every non-cave map byte-identical.

### Waterfalls — SHIPPED `g3-fall-69`, on an author's decision

The cartridge states no drop.  Measured three ways, across Meteor Falls
1F/B1F, Ever Grande and Route 119, for every MB_WATERFALL column: the
**water** above and below is the same height (-4); the **pools** either
side are both ELEV_SURF; the **shores** ringing both pools are both
ELEV_DEFAULT.  Emerald records no height difference at a waterfall
anywhere — a fall is a drawing plus a movement gate.

So the drop had to be chosen, not derived, and that is an author's call
rather than a bug: **one course per pair of drawn rows**, read from the
cascade's own length (a 4-row fall drops 32px, an 8-row fall 64px), with
the pool above and its banks raised to match.  Which is, exactly,
`step = math.min(8, ...)` — what `Structures.buildFalls` has done since
Gen 2.  The machinery was already right; two things were stopping it.

1. The ELEV_SURF shortcut in `classAt` runs BEFORE the behaviour byte is
   read, and a fall is surf-level by the same logic that makes it one, so
   all 58 of Meteor Falls' fall cells returned `water` and `buildFalls`
   was never handed one.
2. **The reason the first attempt looked worse than flat.**  `buildFalls`
   raises the water above a fall onto its crest, and raises two tiles of
   BANK with it — but it does that by giving those cells a RUN, and the
   rock-plateau base vote reads only `shapeAt`.  So the bank's lift was
   invisible to it, the plateau pass reset those cells to the old datum,
   and what was left was a lake sitting as a slab of water with no shore.
   The vote now reads a neighbour's run height too.

Verified: Meteor Falls and Route 119 both render as a raised upper river
falling down a vertical sheet into the lower pool, banks rising with it,
zero interior void px.

### (superseded) Waterfalls — the cartridge states no drop.  Measured three ways.

Re-opened with a proper measurement instead of a guess, and the answer is
the same one three independent times.  Across Meteor Falls 1F/B1F, Ever
Grande and Route 119, for every MB_WATERFALL column:

- the **water** above and below the fall is at the same height (-4);
- the **pools** either side are both ELEV_SURF (1);
- the **shores** ringing both pools are both ELEV_DEFAULT (3).

Emerald records no height difference at a waterfall anywhere.  A fall is a
drawing plus a movement gate (you need Waterfall to pass it), and nothing
more.  So standing one up vertically means choosing a drop the cartridge
contradicts on three counts — which is the "do not invent Stadium-style
meshes for terrain" line, and is a decision about how far to depart from
the source rather than a bug to fix.  **Open question for the author, not
a defect to close.**  The Gen 2 `buildFalls` route is closed: it infers the
drop from the drawn run length and, applied here, raised Meteor Falls'
upper pool 32px into a plateau of water with the sheet standing proud of it
(tried, rendered, reverted).

The mechanical blocker, if a height is ever chosen: the ELEV_SURF shortcut
in `classAt` runs BEFORE the behaviour byte is read, so all 58 of Meteor
Falls' fall cells return `water` and the `waterfall` class is never
reached.

### (resolved in g3-overpass-71) Route 119's river crossings

Its six crossings are 22 cells that state only ELEV_MULTI, with no bridge
behaviour, and they measure ragged: 52 at the ends, 36 in the middle.  The
fix is the same pair that fixed Victory Road — the deck class rule plus
`levelGen3Decks` — and enabling both outdoors DOES flatten all four of its
deck runs.  It was reverted for one specific reason, worth writing down:

Levelling Route 110's short plank crossings opened **1071px of interior
void** under them.  A crossing levelled to `bank + 4` puts its bank at
exactly `deckH - 4`, which is not strictly BELOW the deck, so the
under-span vote finds no surface and lays no plate.  Levelling must
guarantee a plate under whatever it has just moved before it can go
outdoors.  That is a change to the under-span pass, and it is the next
patch on this thread.

### (superseded) Waterfalls — first diagnosis

Meteor Falls' 58 MB_WATERFALL cells lie flat on the pool.  The blocker is
exact: the ELEV_SURF shortcut in `classAt` runs BEFORE the behaviour byte
is read, and a waterfall is surf-level by the same logic that makes it one
(you ride up it), so every fall cell returns `water` and the `waterfall`
class is never reached.

Letting them through was tried and reverted.  `Structures.buildFalls`
measures a GEN 2 fall, where no elevation exists and the drop has to be
inferred from the drawn run; applied to Hoenn it raised Meteor Falls'
upper pool 32px into a plateau of water with the sheet standing proud of
it — worse than the flat sheet it replaced.  Gen 3 states both banks at
elevation 1, so the drop is not in the water at all.  A Hoenn fall needs
its own build that reads the drop off the FLOOR levels on either side.
That is the next patch on this thread.

### `g3-flushrank-70` — every corridor was a trench

Report: the terrace still sits below the cliff edges around it.  Correct, and
the elevation sheet made it countable: **389 of Victory Road 1F's 474
floor-adjacent walkable cells sat a full course below the rock beside them**
(Granite Cave 144 of 145, Meteor Falls 304 of 373).  Every corridor in every
cave was a trench.

`g3-brow-68` had the right idea and far too narrow a test.  It made a rock cell
flush only when it separated two DIFFERENT tiers — 41 cells on Victory Road —
because it asked whether the cell had a lower walkable neighbour as well as a
higher one.  But the commonest cliff in a cave fronts a terrace with more rock
BEHIND it, so it has only one walkable side, and that test cleared it every
single time.

The distinction that actually holds: a rock cell with walkable floor on **both
sides of an opposite pair** is a DIVIDER — a wall standing in the middle of a
floor, which you are meant to see over, and it keeps its course of lift.
Anything else touching a floor is the front rank of a mass, and its top is the
floor it fronts.

After: 135 / 474 on Victory Road, 52 / 145 in Granite Cave, and what remains is
dividers (raised on purpose) and ledges (+6px, which is what a hoppable ledge
is).  Relief now comes from where the drawing puts it — the tier boundary and
the mass behind the brow — instead of from every corridor being cut a course
deep.  Void sweep zero; every non-cave map byte-identical.

### `g3-overpass-71` — the fall's own crest, and overpasses on every map

**The banks were twice the fall.**  Two faults compounding.  `buildFalls`
measures in TILE space, so Meteor Falls' 5-cell fall is a 10-tile run at 8px a
tile = an 80px drop -- that part is right, and is the one-course-per-row-pair
rule.  But `height` was the tallest fall on the WHOLE MAP, and every pool was
raised to it: an 80px cascade under a lake standing at 96.  Each fall now
carries its own crest to the pool and bank it feeds.

**And the cascade was not cascading.**  On Gen 3 a waterfall cell is BLOCKED --
you need the move to pass it -- so it flooded into a blocked region, and
`buildVolume`, which runs *after* the falls pass, boxed the whole drop flat: the
fall measured 80 and came out a uniform 32px slab with the pool already raised
above it.  That mismatch is exactly "the banks rise as far above the fall again
as the fall is tall".  Gen 3 now runs the falls pass last, after the volume
pass, and the profile down a column reads 80 / 64 / 48 / 32 / 16 / -4.

**Overpasses, everywhere.**  ELEV_MULTI means "do not change the walker's
elevation here", so a run of them is one flat surface at the height of the banks
it connects, and a walker who arrives at a real level passes underneath -- cave
crossing or river bridge, no difference.  Both the class rule and
`levelGen3Decks` now run on every map.  Route 119's six crossings (22 cells that
state only elevation, previously ragged at 52/36) come out flat; Route 110's
548-cell cycling road is over `DECK_LEVEL_MAX` and is never touched, as it must
not be.

**A correction to the previous entry.**  Holding this back was based on a bad
measurement: Route 110 shows 1071px of interior void with the outdoor levelling
ON *and* with it OFF -- it is pre-existing and has nothing to do with decks.
Rendered, the blobs are ~30 one-cell slivers at the BASE OF TREES, where a tall
billboard meets ground lower than the cell behind it.  Logged as its own small
defect.  The under-span vote did still need the two-stage fallback it was given
here (take anything below the deck if nothing clears a full course below it), so
that a levelled crossing can never be left plateless.

## `g3-elev-72` — the ROM's elevation on every map, decided by the map

Surveyed all 518 maps against the cartridge data before changing anything.
Three findings, all measured:

**Behaviour `0x3C` is used NOWHERE in Emerald** — zero cells in the whole
game.  Whatever "the 3c attribute" refers to, it is not a behaviour byte, so
the over/under behaviour was built against the thing that *does* record it:
ELEV_MULTI (15), which means "do not change the walker's elevation here" and
appears on exactly **12 maps**.  If 3C means a field in another encoding, say
which and it can be checked against the same data.

**Layer types are only ever 0, 1 or 2** — NORMAL x167912, COVERED x147604,
SPLIT x196 across the game.  `Gen3.coverAt` already consumes this (`layer ~= 1`
= the top half draws above the player), and it is what picks the cover class on
a blocked cell.  SPLIT is 196 cells game-wide, which is why it has never been
worth its own geometry.

**Elevation is now decided per map, from the map.**  The old rule discarded the
elevation field on every indoor map, because indoors Emerald often uses it for
sprite priority and ranking that into courses stands a step in the middle of a
carpet.  True for bedrooms, wrong for everything else — and the two are
trivially separable, because priority is SCATTERED and a terrace is a REGION.
Largest connected non-datum walkable region, measured over all 518 maps:

| | cells |
|---|---|
| Pokémon Center 1F | 1 |
| Aqua Hideout B1F | 2 |
| Devon Corp 3F | 3 |
| Slateport Fan Club | 4 |
| **— nothing in between —** | |
| Aqua Hideout 1F | 12 |
| Mirage Tower 4F | 20 |
| Battle Pyramid squares | 42–54 |

A threshold of **8** sits in that gap with room on both sides.  So the blanket
indoor rule is gone: a map answers for itself (`Gen3.usesElevation`), a profile
can still force it either way, and **24 indoor maps that were being flattened
now build their real floors** while the bedrooms the old rule existed to protect
are still protected — by evidence from their own data rather than a hand-written
list.  Verified: Aqua Hideout 1F builds its pool and walkway, Mirage Tower 4F
its stepped floors; Centers, Brendan's house, Aqua Hideout B1F and the Fan Club
stay flat.

## Audit against pret/pokeemerald — no change needed, and why

Checked our behaviour table against pret's `include/constants/metatile_behaviors.h`
directly, prompted by the "3c attribute" question.  Result: **the data is already
right, and nothing needed fixing.**  Recording it so the next person does not
re-litigate it.

**`0x3C` is `MB_JUMP_NORTHEAST`** — a diagonal ledge hop.  Confirmed against
pret, and it matches what our table already said.  It is used on **zero cells in
the entire game** (all 518 maps scanned), so it cannot be the mechanism behind
over/under walking.  What Emerald actually uses for that is ELEV_MULTI (15).

**Every bridge behaviour pret defines is present and lifted.**  Cross-checked
name by name: `MB_BRIDGE_OVER_OCEAN` 0x70, `..._POND_LOW/MED/HIGH` 0x71-0x73,
`MB_FORTREE_BRIDGE` 0x78, the four pond edge pieces 0x7A-0x7D, and
`MB_BIKE_BRIDGE_OVER_BARRIER` 0x7F.  All ten resolve to `bridge`, all ten have a
`bridge_lift` entry, and every one that Emerald actually places (0x70 x609,
0x72, 0x73, 0x78, 0x7A-0x7D, 0x7F x6) is covered.  0x74-0x77 are the four
Pacifidlog log pieces and are class `log`.

**A caution about the method.**  `WebFetch` summarises a header through a small
model, and on the second and third queries it returned values shifted by +0x1E
and then contradicted itself on `MB_REGION_MAP`.  It agreed with our table where
the table could be independently verified and disagreed where it could not,
which is the wrong way round to trust.  For exact constants, the ROM data we
already generate is the better authority -- it is the cartridge, not a
paraphrase of a header.

**Overpasses verified on every map that has one.**  ELEV_MULTI appears on 12
maps game-wide.  On 11 -- Fortree, Littleroot, Routes 110/119/120, Meteor Falls
1F, Victory Road 1F/B1F/B2F and both Shoal Cave inner rooms -- every single
ELEV_MULTI cell resolves as a deck (0 failures out of 463 cells).  The twelfth,
BattleFrontier_BattleArenaCorridor, has 66 ELEV_MULTI cells that are BLOCKED
walls carrying MB_NORMAL: the field being used for sprite priority on scenery,
with nothing to walk under.  The class rule requires a walkable cell, so it
correctly leaves all 66 alone.  That is the rule working, not failing.

## `g3-scree-73` — Jagged Pass / Mt Chimney (QA item 2)

The terrace reconstruction needs a drawn CONTOUR to chain into levels, the way
Sootopolis' crater rings give it one.  The volcano's flank has none: it is one
continuous scree of the same rock motif top to bottom.  Given nothing to stop
at, it levelled Jagged Pass almost entirely to its ceiling.  Measured, the modal
WALKABLE height down its 46 rows was **80px on 26 rows and 0 on 9 more, in no
order** — not a descent, a plateau with eighty-pixel pits scattered through the
path you walk down.  (The plan predicted this failure when `cliff_band` was
proposed: "Jagged Pass is one continuous scree — the detector will want region
evidence it cannot have.")

The ROM settles it: **levels=1** for both Jagged Pass and Mt Chimney — every
walkable cell is ELEV_DEFAULT.  One level is the faithful answer, so
`gTileset_Lavaridge` carries `drawn_terraces = false` (covering Jagged Pass, Mt
Chimney, Lavaridge Town and Route 112; Route 111 is a different pair and is
untouched).  The relief the cartridge DOES state still builds: ledges at 6px,
fences at 10, rock walls at 16, tree canopies at 32, and nothing above 32.

### Found doing it — object-base seams, narrowed but NOT fixed

Jagged Pass's void count went 1543 → 3521 with the flat-ground fix in, and the
gaps render out **behind bushes and small rock props**.  Raised terraces were
hiding them; correct flat ground exposes them.  Same family as Route 110's ~30
one-cell slivers at tree bases, so it is confirmed on two maps.

Investigated and narrowed; deliberately not patched on a guess.  What was ruled
OUT, each by measurement:

- **Not missing floor.**  Every tile on Jagged Pass, Route 110, Victory Road and
  Mossdeep has a shape AND a painted ground: 0 tiles with no shape, 0 skipped
  without ground, 0 of class `void`.  The ground plane is complete.
- **Not stamp placement.**  `my` (the height a hull stands at) is omitted by
  four of the seven stamp creation sites and defaults to 0, which looked like
  the culprit — but these hulls stand on ground at 0, so it is correct here.
  `r` defaults to 8 where a 2-cell dome wants 16, and that too is harmless: `r`
  only gates the chunk-boundary keep tests, it does not clip quads.
- **Not caused by the stamps at all.**  Rendering Jagged Pass with the round
  stamps SUPPRESSED puts the void *up*, 3521 → 5267.  The hulls are covering
  holes, not making them.

What is left, located by back-projecting one blob to world coordinates: the gap
sits at cell (1–2, 25) between y=12 and y=19 — around the top-rear of a bush
whose drawn hull has **no back face**, with the terrain behind it (a 10px fence)
lower than the hull's crown.  You see over the fence, through the open back of
the dome.  The fix is hull closure, not placement, and it wants a careful look
at `roundTemplate` rather than a patch written from a hypothesis.  **Next item,
with the diagnosis above to start from.**

## Rethinking cliff / stair / terrace verticality — design, with the
## hypothesis I falsified first

Asked to rebuild cliffs, stairs and terraces as one pass with one rule set.  I
built that rule set as a SHADOW first -- computed alongside the real build,
compared, no behaviour change -- and it does not work.  Recording that before
the design, because the design follows from it.

### The shadow experiment, and why it failed

One rule set, derived from the cave relief rules that had just fixed Victory
Road: walkable floor takes the ROM elevation; blocked cells go flush when drawn
in floor art, lift a course when they are a divider, otherwise take the tier
they front; buried rock steps up from the brow.  Agreement with the shipped
build:

| map | agrees |
|---|---|
| Oldale Town | 64% |
| Granite Cave 1F | 62% |
| Victory Road 1F | 57% |
| Mossdeep City | 52% |
| Jagged Pass | 43% |
| Fortree City | 37% |
| **Sootopolis City** | **13%** |

Three distinct reasons, all of them the rule set being wrong rather than the
build:

1. **A mass does not climb.**  "Buried rock steps up from the brow" grows
   without bound the further in you go (32, 48, 64, 96).  The build keeps a
   mass FLAT one course over its brow, and the build is right.
2. **A brow is not flush outdoors.**  Flushing every blocked cell that fronts a
   floor is right in a cave, where the rock IS the terrain.  Outdoors the cells
   that stand proud are overwhelmingly trees and buildings -- Oldale 36
   cylinders and 7 canopies of 70, Fortree 82 of 108 -- and Route 111's 706
   proud `wall` cells are its desert cliffs, which are *supposed* to stand over
   the route below.  Flushing them flattens the towns.
3. **Sootopolis has no elevation to read.**  Its tiers come from the drawn
   terrace reconstruction (the ROM states one level), so a rule set that starts
   from `groundHeight` cannot see them at all.  Hence 13%.

### What the evidence actually supports

The mechanisms are not wrong.  There are just **seven of them that can set a
terrain height** -- `groundHeight`, `buildDrawnTerraces`, `buildVolume`'s run
measurement, `buildGen3RockPlateaus`, `levelGen3Decks`, `buildFalls`, and the
refound pass -- plus **four for stairs** (`buildStairs`, `buildOutdoorStairs`,
`buildGen3Flights`, and `rampHeightAt`), running in an order where later ones
overwrite earlier ones, with a precedence that emerged from patch order rather
than from a decision.

Every bug this thread has chased was a JURISDICTION error, not a rule error:
the rock plateau overwriting `run.face` heights; `buildVolume` boxing the
cascade `buildFalls` had just measured; deck levelling moving a deck the
under-span vote had already answered for; the rock base vote reading `shapeAt`
while `buildFalls` had written a run.  Same shape of bug, four times.

So the rebuild is **one arbiter, not one rule**:

- A single `top[cell]` field, written in exactly one place, quantised to
  courses.
- Every existing pass becomes a CONTRIBUTOR that proposes a value with a stated
  source, instead of writing `shape.h` / `run.h` directly.
- A written precedence: authored pin > ROM elevation (where real) > drawn
  terrace (where the tileset has contours) > blocked-mass rules > class default.
- One invariant check at the end: terrain tops are course multiples, and
  walkable neighbours differ by at most one course unless a ledge, stair or deck
  sits between them.  It fails loudly rather than shipping.

That last item is worth having on its own, ahead of the refactor, because it
turns "the cliffs still are not perfect" into a number that can be watched --
and it is what would have caught all four jurisdiction bugs at the commit that
introduced them.

### Phased, smallest first

1. The invariant check as a third standing check (with the void and elevation
   sheets).  No behaviour change; establishes the baseline.
2. Convert the terrain contributors to propose-into-`top`, one pass per patch,
   verifying byte-identical output at each step.
3. Convert the stair contributors the same way.
4. Delete the overwrite ordering once nothing depends on it.

## `g3-stand-74` — phase 1 of the rebuild, and what it caught immediately

Phase 1 was meant to be a no-behaviour-change measurement: build the step
invariant, establish a baseline.  It found a shipped bug in its first run.

**The walker was standing on rooftops in every town.**  `Structures.runHeight`
reported any run's top as floor, and a terrace run and a house run are both
"a column with a top".  So wherever a building's footprint overlapped a cell
the cartridge calls walkable ground -- the row in front of a house -- the
player was lifted onto the roof.  Rustboro 42 cells, Mauville 30, Slateport 27,
Lavaridge 14, Oldale 13, Littleroot 10, Mossdeep 16, Petalburg 8.

The two are told apart by what the RUN is, not by the cell: a building states a
roof (`gen3RoofRows`), a pitch (`rise`) or a door; terrain states none of
those.  So a building's run no longer answers as floor for a walkable cell, and
Sootopolis' tiers lift the player exactly as before.

Impossible steps, before -> after: Oldale 19 -> 0, Petalburg 4 -> 0, Rustboro,
Mauville, Mossdeep, Victory Road, Jagged Pass, Route 110 and Fortree all 0.
What remains is small and mostly legitimate: Sootopolis 5 (crater-wall edges
worth a look), Littleroot 4 (a rooftop chimney beside ground), Slateport 1 (an
awning).  **Every map's geometry hash is byte-identical** -- this is a walker
fix and touches no vertex.

Worth stating plainly: this bug had been shipping the whole time, on the first
town in the game, and no amount of looking at renders would have found it,
because the geometry was always right.  It took asking "what does the walker
stand on" as a number.

## `g3-reach-75` — a tier you cannot reach is not a tier

Asked to check the hilly maps.  The invariant found the terrace pass putting
drops across pairs the game lets you WALK between:

| map | impossible steps | worst |
|---|---|---|
| Mt Pyre Exterior | 15 / 644 | 64px onto tall grass |
| Sootopolis City | 5 / 2381 | 96px |
| Lavaridge Town | 6 / 299 | 32px |
| Mt Chimney | 4 / 616 | 32px |
| Route 119 | 3 / 4512 | 32px |

Pinned to `buildDrawnTerraces` by disabling it: Mt Pyre 15 -> 0 and Sootopolis
5 -> 0, while Mt Chimney's 4 stayed (its terraces are already off via the
Lavaridge profile, so those come from run measurement -- a separate thread).

**Emerald's elevation field IS its connectivity rule** -- the game refuses a
step between cells of differing elevation, which is exactly what lets a cliff
top sit beside its own foot.  The reconstruction never consulted it, so it was
free to drop 64px across a pair you can walk along.  It now relaxes its levels
against the ROM's own graph: where two connected cells end up more than one
course apart, the higher comes down.  A ramp is a chain of such pairs, so a
three-cell ramp still permits three courses between its ends -- the constraint
allows exactly what the drawing allows and no more.

Surgical, not a flattening: **25 cells pulled on Mt Pyre, 11 in Sootopolis**,
and both go to zero impossible steps.  Sootopolis' crater is untouched to the
eye -- water, shore ring, terraced town, rim at 48+, exactly as the 2D.

The check itself gained the same rule, and it mattered: Routes 115 and 120 were
reporting 10 and 2 steps that are elevation-separated pairs the game already
forbids.  Not defects.  Counting them would have sent me to fix terrain that is
correct.

Now clean across the hilly set: Mt Pyre, Sootopolis, Routes 111/115/120,
Ever Grande, Mossdeep, Fortree, Victory Road, Jagged Pass, Route 110, Oldale
all **0**.  Remaining: Lavaridge 6, Mt Chimney 4, Route 119 3 -- all on maps
whose heights come from run measurement rather than the terrace pass, which is
the next thread.

## The three standing checks

None of the three depends on anyone noticing something in a screenshot.  Worth
running on every map touched from here on.

**Step invariant** (`/tmp/t/invariant.lua`) -- for every pair of adjacent
walkable cells, ask `VoxelScene.groundAt` -- the function the game itself calls
-- what the walker stands on, and flag any pair more than one course apart with
no ledge, stair, bridge or water between them.  Also flags terrain tops that
are not whole courses.  THE AUTHORITY IS THE WALKER: the first cut of this
check read `shape.h`, then `run.h`, and reported 19 phantom steps in Oldale
that were a house's own run being read for its porch.  Only `groundAt` is the
answer the game acts on.

**Void check** — render over a MAGENTA background and flood-fill from the image
border; any magenta blob not touching the border is a hole straight through the
mesh.  This is what found the 570px slot under Victory Road B1F's bridge and the
1071px that outdoor deck levelling opened under Route 110.  `BG=255,0,255` plus a
`scipy.ndimage.label` pass.

**Elevation sheet** — `HCOL=1` repaints every quad by its own top height instead
of its art, so a region's tier reads at a glance.  Elevation courses are ordered
magnitude, so this is an ORDINAL ramp, one hue light-to-dark, five steps
(`#86b6ef #5598e7 #2a78d6 #1c5cab #0d366b` = water / 0 / 16 / 32 / 48+),
validated for monotone lightness, adjacent-step gaps and light-end contrast.  A
rainbow would be wrong here: the thing being read is order.

The plan view carries a white line wherever a WALKABLE cell meets a BLOCKED one,
which is what makes it answer the question that keeps coming up: **same colour on
both sides of the line means the cliff edge is flush with the terrace it leads up
to; a step across the line means it is standing proud.**  A wall in the middle of
one tier is meant to step; a brow is not.

## Phase D/E notes (constraints honoured)

- All new passes are presentational; nothing touches collision/warps.
- Detection stays region-based: pillars extract from drawn pier tiles
  inside water cells, never inferred from isolation (no random towers).
- Unknown tiles: `classAt` fallback (walkable→ground, water→water,
  blocked→wall) is unchanged and is the safety net the spec requires.

## Phase G — priority-map QA status

1. Route 110 — deck/underpass/heights/pillars/under-span SHIPPED; the
   parapet needs no class (see B3).  Open: Trick House clearing QA and the
   in-game walk video.
2. Jagged Pass / Mt Chimney — heights SHIPPED (g3-scree-73); cable car
   station not looked at.
3. Fortree — walkway course=32 ships; bridges vs houses needs a QA pass.
4. Sootopolis — bowl, tiers, gate, tents, kerbs ship; open: band-corner
   smudges (~10 cells), contour lines fatter than drawn.
5. Sky Pillar exterior — NOT STARTED (gTileset_Pacifidlog).
6. Littleroot / Oldale / Petalburg — baseline good (hash-verified stable).
7. Center + Mart interiors — counters SHIPPED; 1F staircase SHIPPED
   (`flights`, all 34 Centers).  Open: the 2F descending well, and Mart
   shelf rows.
8. Safari Zone tents — NOT STARTED (awning class reuse).
9. Meteor Falls first room — SHIPPED with the whole cave family, see
   below.  Rendered against the 2D: pools, falls, the plank bridge, the
   stalagmite columns and the pink crystal shelf all read correctly.
10. Pacifidlog stilts — logs ship; stilt `pillar` under houses open.

Next patch: Hoenn waterfalls (design above), then Jagged Pass / Mt
Chimney (gTileset_Lavaridge, QA item 2 — the largest untouched exterior
family), then the Center 2F descending well and Safari Zone tents.
Shipped this round: `pillar` (g3-pier-61), `flights` (g3-flight-62, which
replaced the `stair_s` design), under-span coverage (g3-underspan-63),
cave rock (g3-rock-64), cave terraces and bridges (g3-tier-65), flush cave floor and real cave
decks (g3-flush-66), ground under every span (g3-underfill-67), flush cliff brows and
unstacked cliff faces (g3-brow-68).

## Phase G QA — in-game screenshot verification (g3-reach-75)

### The trap that invalidated every in-game shot before this pass

The harness's own save directory shadows the game tree.  LOVE resolves a
mod file from the AppData save dir FIRST and falls back to the game
directory, per file, so a save dir holding four files -- ChunkMesher,
FirstPerson, Structures, VoxelScene -- silently overrode those four and
let everything else (Gen3.lua, data/gen3_shapes.lua) come from the
current tree.  The container's shadow was pinned at `g3-causeway-60`
while the tree was at `g3-reach-75`, so every in-game screenshot taken
this session rendered a fifteen-revision-old Structures against a
current Gen3 -- a mixture that exists nowhere else.

What that looked like, and why it was so convincing: Granite Cave's
whole southern half rendered as long vertical smears.  Three hypotheses
were tested and all three were WRONG, each because the experiment could
not take effect:

  * "it is the tilt-shift pass blurring the near band" -- falsified by
    SHOT_TILTSHIFT=0 (added to the driver for exactly this, and worth
    keeping: the depth-of-field pass genuinely does smear a cave floor
    into something that reads as stretched wall art).
  * "it is the border ring standing as tall facades" -- RING was set to
    0 and the shot came back byte-identical.  That identity was the
    tell: an experiment that changes nothing at all is usually not
    measuring what it thinks it is.
  * "the rock-plateau pass is gated off in-game" -- instrumented
    `buildGen3RockPlateaus` with a log at every gate.  NOTHING printed.
    A function that cannot even report being entered is not being
    called, and the file being run is not the file being edited.

The census line was the evidence in plain sight the whole time.  Offline:
`ground=2488 ledge=32 shell=472` with `laid 419 cell(s) of rock as
plateau` above it.  In-game: `ground=812 ledge=32 shell=472 wall=1676`
and no plateau line.  812 + 1676 = 2488 -- the same cells, classified
two different ways by two different builds.  A census that does not
match the offline one for the same map means the two are not running the
same code; check that before forming any hypothesis about geometry.

RULE, now standing: before trusting an in-game shot, confirm the save
dir's shadow matches the tree.  The `gen3 shapes:` census line for the
map, compared against the offline harness's line for the same map, is
the cheapest check there is and it is conclusive.

Cedric's own machine was never affected -- repo
(`Gen2Recomped/mods/DRAMATIC_SHAPE`) and save dir
(`AppData/Roaming/LOVE/Gen2Recomp`) both carry the current 429127-byte
Structures.  This was a harness-only defect.  His shadow carries FIVE
files (Gen3.lua as well); the container's is now matched to it.

### What the shots show once the right code is running

Taken through the game's own pipeline at SHOT_TILTSHIFT=0 so geometry
is not read through the depth-of-field pass.

  * Granite Cave 1F -- corridors cut into rock, one course of relief,
    boulders as masses, ladders standing.  `wall` 1676 -> 8 after the
    plateau pass runs.  The smeared half is gone.
  * Victory Road 1F -- 1377 cells laid as plateau, 995 of them flush;
    stone terraces, stair flights with real treads, the purple spans
    floating clear of the floor with their shadow cast under them.
  * Meteor Falls 1F -- the cascade falls vertically into a pool at the
    right datum and the banks do NOT stand above the crest.  This is the
    report from earlier in the session, closed visually.
  * Mt Chimney, Jagged Pass -- lava-rock ridges one course up, ledge
    markers reading, cable-car station and rails intact.
  * Mt Pyre (both spots) -- terraces with white stone flights climbing
    between them; grass steps descending as actual courses.
  * Sootopolis, Aqua Hideout -- tiers, kerbs, railings as fences, pools
    recessed below the floor.

### A stretch that was not a stretch

Mt Pyre's tall cliffs read as long vertical streaks and looked like the
"stretched metatile textures on cliff edges" report.  Measured instead
of eyeballed: every side quad on the map spans exactly 8 world px and
carries 8 atlas rows (v range 0.0677 -> 0.0703 over a 3072-row sheet).
There is no stretch anywhere in the mesh; faces are stacked 8px bands,
and consecutive courses even draw from different u columns.  The 2D
reference render settles it -- Mt Pyre's rock is DRAWN as vertical
grain.  The 3D is faithful; the art is stripey.

Note for next time: a first pass at this measured `vspan` rounded to two
decimals, which reported 0.0 for every quad and would have "proved" a
catastrophic texture bug that does not exist.  Atlas v deltas here are
~0.0026; round nothing.

### Invariant sweep at g3-reach-75

0 impossible steps on Mt Pyre (0/644), Jagged Pass (0/447), Victory Road
(0/1071), Granite Cave (0/316), Meteor Falls (0/963), Sootopolis
(0/2381), Aqua Hideout (0/730).  Mt Chimney still 4/616 at 32px, all
four from run measurement rather than the terrace pass -- unchanged and
still open.  229/229 modkit tests green.

## g3-ascent-77 — Mt Chimney had the stair machinery switched off

`gTileset_Lavaridge` carried `drawn_terraces = false`, added earlier on the
grounds that the ROM reports levels=1 for Jagged Pass, Mt Chimney, Lavaridge
and Route 112 -- every walkable cell ELEV_DEFAULT, so one plane was the
faithful answer.  That reasoning is still true of the cartridge and it was
right when a terrace could only ever rise one course.

It was wrong about the STAIRS, and the gate is the whole reason Mt Chimney
looked flat: `buildDrawnTerraces` returns before it scans for `step` cells,
so the flight detector never ran on that tileset at all.  A flight cannot
raise anything unless the ground beyond it rises too -- stairs and terraces
stand or fall together -- so the gate had to come off for either to work.
Ungated, Mt Chimney reads 12 drawn terraces and raises 408 cells, and its
relief goes from one 8px bank everywhere to 96px.

Also widened: the `step` run width cap, 3 -> 8.  Three is right for a cut
between two terraces and wrong for a mountain's main ascent.  The tread-art
test is what keeps ordinary ground out, not the width.

Measured effect (impossible steps, invariant sweep):

  * Lavaridge Town  6 -> 3
  * Mt Chimney      4 -> 4   (unchanged; still the run-measurement four)
  * Jagged Pass     0 -> 0
  * Route 112       0 -> 0, Route 111 0 -> 0 (different pair, untouched)
  * fractional heights 0 across all of them

229/229 modkit green, Gen 1/2 unchanged.

### Found doing it, NOT fixed — the stile that is a slot

Mt Chimney draws five grated step plates (metatile 687) through its ash
banks, at (26,27) (26,29) (26,32) (25,22) (20,24).  Each is a single walkable
cell in a gap through a bank with ordinary ground at the SAME height both
sides, so no tier rule has anything to say about it: no drop to bridge, no
flight to climb.  It stays on the floor with the bank standing over it, which
reads as a slot cut through the ridge.  The drawing lays the plate ON the
bank, to be stepped up onto and down off.

A pass for it was written and backed out, because the height authority is
wrong and the fix would have been a guess.  What was learned:

  * `shape.h` on a wall is the wall's OWN EXTENT, not an absolute top.  At
    (25,27) `shape.h` is 16 while the ground beside it is 32 and the mesh
    puts the bank's top at 40.  Any rule of the form "raise the crossing to
    the height of what flanks it" that reads `shape.h` compares an extent
    against an absolute and silently never fires -- which is exactly what
    the first cut did, on all five plates.
  * `VoxelScene.groundAt` is the authority (it is what the invariant uses)
    but Structures cannot require VoxelScene without a cycle.  A small
    accessor is needed before this pass can be written honestly.
  * A mesh probe selecting quads by `xm >= x0 and xm <= x1` over a 16px cell
    leaks the neighbouring cell's quads at both bounds and reported every
    cell at 40.  Tighten the bounds before trusting that number.

Also still open: `treadArt` cannot see metatile 687 at all.  It requires
horizontally uniform rows, and a grating is drawn with VERTICAL slats inside
a dark frame, so both the frame and the slats break the test.  A grate you
walk along is not a flight you climb, so this may be correct -- but it means
the plates can never be found by the stair path and need the stile rule
above instead.

## g3-crater-78 — a stepped crater rendered as a saucer

Mt Chimney's height field had TWO levels for a mountain the art draws as
seven concentric terraces.  The tier diagnostic added here (set
`VOXEL_TERRACE_DEBUG=1`; it dumps every region, its size, its solved level
and the edges that gave it that level) answered it in one run:

    TERRACE MAP_G24_N12: 45 region(s), 18 edge(s), 0 step cell(s)
      region 4   size 366   level 2   -> above: -

**One region of 366 cells.**  Mt Chimney's rings are not separate components
because the path spirals continuously between them; the only thing that cuts
the flood is a `step` cell, and this map had NONE.  So every ring merged and
took one level.

The crossings are there in the art -- five grated plates, metatile 687, at
(26,27) (26,29) (26,32) (25,22) (20,24), each a single walkable cell wedged
between two blocked bank cells.  `treadArt` rejected all five.  Its test
wants rows uniform ALONG their length, which is what a flight looks like
faced up; a grating is banded top-to-bottom like any tread but SLATTED along
its length, so it measured spread 0.272 against a limit of 0.15.

`plateArt` keeps the banding requirement (range >= 0.30, which 687 passes at
0.328) and drops the uniformity one.  That is far too loose on its own -- ash
bands and rock pass it -- so it is never used on its own.  The caller already
requires the topology of a crossing, and now also requires that the crossing
be DRAWN AS SOMETHING OTHER than the ground running up to it: ordinary floor
showing through a gap in a fence shares its neighbours' metatile and is
rejected.  Topology is the evidence; art only confirms.

    TERRACE MAP_G24_N12: 51 region(s), 28 edge(s), 23 step cell(s)
      region 20  size 91   level 2  -> above: 15(+1S) 9(+4b)
      region 15  size 18   level 3  -> above: 14(+1S) 9(+3b)
      region 9   size 23   level 6  -> above: 4(+3b) 7(+1S) 8(+1b)
      region 4   size 184  level 9  -> above: 5(+2S)
      region 5   size 17   level 11

Five terraces, 2 -> 3 -> 6 -> 9 -> 11, and in-game the five plates read as
staircases with risers climbing between rings.

No inflation elsewhere: Sootopolis unchanged at 55 step cells, Rustboro 10,
Mauville 6, Oldale 0.  229/229 green.  Invariant unchanged or better on every
map swept; fractional heights still 0 everywhere except Route 110's two.

### Still open

  * Mt Pyre 1 impossible step (48px), Sootopolis 1 (32px), Mt Chimney 4,
    Lavaridge 3.
  * Mt Pyre's west edge draws rainbow banding over the water since
    g3-tread-76.  Undiagnosed.
  * Victory Road and the cave family still build one course of relief: they
    go through `buildGen3RockPlateaus`, which lifts rock by a fixed
    ROCK_LIFT, not by what the drawing says.  Their STAIRS climb correctly
    now; their terraces do not.
  * The `facerows` probe overstates disagreement -- it measures one blocked
    run between two walkable cells, and a thick run can span more than one
    tier boundary, so "6 rows drawn -> 9 courses built" may be two boundaries
    summed rather than an error.  It needs to compare ADJACENT tiers before
    its numbers can be trusted as an over-height signal.

## g3-plate-79 — the crossing detector was firing on ordinary ash

`g3-crater-78` found 23 step cells on Mt Chimney.  Seven were real.  The
debug dump (now also lists every step cell and its metatile) named the rest:

    (10,6)m625 (11,6)m639 (12,6)m639 (13,6)m639 (10,11)m625 ... (17,36)m577

Metatiles 625, 639 and 617 are the PLAIN ASH PATH -- 639 and 617 just carry
the dark foot of a bank drawn into the tile, which is banded enough to clear
`plateArt`.  577/578 are the cable car station's doorway.  Sixteen of the
twenty-three were invented, and an invented crossing is not a cosmetic miss:
each one cuts the flood and manufactures a tier, which is precisely "some
places are raised too high" and the glitchy verticality.

Two tests fixed it, and the useful part is WHICH two.

**Chroma, not brightness.**  Measured against the ash path (625):

    metatile 687 / 534  (the grated plates)   chroma 0.0861
    metatile 639 / 617  (ash with a dark band) chroma 0.0023
    metatile 577 / 578  (the station doorway)  chroma 0.3131

Thirty-seven times apart, so the threshold sits comfortably at 0.02.
Brightness alone could NOT have separated them -- the dark band in 639 is a
genuine brightness gap of 0.023 and the plate's is 0.236, only a factor of
ten, and both are real.  Dividing the overall lightness out and comparing
what is left is what makes the two classes separable at all.

**And the cartridge's own word for a door.**  The station doorway is dark
blue on pink ash and clears the chroma test by a mile -- it is exactly the
thing chroma is for, and it is still not something you climb.  Emerald names
it MB_NON_ANIMATED_DOOR, the spec already carries a `doors` table, so the
name is read rather than guessed at.

Result: 7 step cells, all real -- five grated plates (687) at (20,24) (25,22)
(26,27) (26,29) (26,32) and the two-cell south exit flight (534) at (20,41)
(21,41), which g3-crater-78 had also been missing.  The crater still solves
to four terraces (2 -> 3 -> 6 -> 9) and the invariant is unchanged on every
map swept.  229/229 green.

RULE for the next detector: topology proposes, art confirms, and the art test
must be checked against the thing it will see MOST -- ordinary ground -- not
only against the thing it is meant to find.  Both false-positive families
here were ground, and neither would have shown up in a test that only asked
"does this accept the five plates?".

## g3-doorstep-80 — a doorway halfway up a cliff, and a lying reference tool

### The tool was wrong first

`/tmp/t/art2d.lua` reads its crop origin from **`CX0` / `CY0`**.  Every 2D
reference render this session passed `X0=` / `Y0=`, which the script ignored,
so all of them silently rendered the map's TOP-LEFT CORNER instead of the
region asked for.  Only the full-map renders (origin 0,0 anyway) were right.

That is why a crop meant to show Mt Pyre's staircase showed cliff, and one
meant to show Mt Chimney's grated plates showed no yellow anywhere.  Three
"the art says X" statements this session rested on images of the wrong place.
Re-checked, none of the CONCLUSIONS changed -- each had independent evidence
(metatile dumps, mesh measurements, the census lines) -- but the corroborating
pictures were worthless and should not have been cited.  The script now
accepts either spelling.

RULE: a reference tool that silently defaults on a bad argument name is worse
than one that errors.  Before trusting a crop, sample one pixel at a cell
whose metatile is known and check the colour matches.

### The doorway

Mt Pyre's cave mouth at (10,42) is MB_NON_ANIMATED_DOOR, walkable, cut into a
cliff face whose terrace stands three courses above the grass you enter from.
`groundAt` sends a walkable upright cell to `Structures.standHeight`, which
scans outward ring by ring and takes the ring's MAXIMUM -- so the mouth took
the terrace at the top of the cliff, 48, while the grass in front of it sits
at 0.  A doorway floating halfway up a cliff with an impossible 48px step in
front of it.

The function's own comment already said what it should do -- "a door at the
foot of a cliff takes the low ground it opens onto and one at the top takes
the terrace" -- and the code did the opposite.  Fixed by asking the cell in
FRONT first: in Emerald you enter a door from the south, so the south
neighbour wins when it is walkable and flat, then the lowest walkable
neighbour, and only then the old ring scan (which stays as it was for the
case it was right about -- a facade whose own footprint is all that is near).

Mt Pyre 1 impossible step -> 0.  Every other map unchanged.  229/229 green.

### Not a bug after all: Mt Pyre's "rainbow banding"

The banded purple/pink/peach at Mt Pyre's west edge, flagged as a regression
in g3-tread-76, is the SUNSET SKY over the sea, dithered as the sky pipeline
always draws it.  It became visible because the far-west cliff got SHORTER --
correctly, the sea is there -- and stopped hiding it.  Widening the border
ring from 3 to 7 changed nothing, which is what ruled the ring out.  The
earlier build's giant west cliff was the artefact; the sky is the fix showing
through.

## g3-stamp-81 — a whole-Hoenn sweep, and what it found

Chasing single flagged cells was guesswork, so the invariant now runs over
EVERY outdoor map (`/tmp/t/sweepall.sh`, 82 maps, ~80s) and the results are
ranked.  Two things had to be fixed before the numbers meant anything.

### The metric was mostly noise

`non-course` counted 600+ cells across Hoenn and was therefore ignorable --
which is exactly how Mt Pyre's 37 REAL fractional cells got waved through
earlier in this session.  Almost all of it was the SHORE LIP: ground meeting
water is authored 2px low so the waterline reads.  Underwater_Route126 alone
contributed 306.

First attempt exempted `h == -2` and still left 306 there, because the lip
rides on whatever course the ground is at: 62, 46, 30 and 14 are all a course
minus two.  Testing the OFFSET (`(h - lip) % COURSE == 0`) is what works.
Cells whose art was stood up into a stamp are exempt too -- their leftover
shape height is not a surface anything stands on.

    before: ~600 "fractional" cells, unreadable
    after:  21, on two maps

### The prop that was a step

`groundAt` never honoured `S.skip`.  When an object pass lifts a cell's
drawing into a hull it marks the cell skipped, but the leftover SHAPE still
carries the height the drawing had -- so a prop straddling a walkable cell
answered its own height as the floor.  Littleroot's chimney sits across the
eave of the player's house: both its cells are walkable and both answered
24px with the grass in front at 0.  Four of Hoenn's twenty-two impossible
steps were that one chimney, on the first map of the game.

`Structures.stampGround` answers the datum the stamp stands on.  The first
cut returned `s.base or 0`, which was right for the chimney and WRONG for
Sootopolis' terrace posts -- they carry no `base`, so three of them dropped
to the datum with their terrace three courses above: a pass that fixed four
steps and created three, on a map it had no business touching.  Falling back
to `standHeight` instead (the same question a doorway asks) fixes that.

### Where Hoenn stands

    82 outdoor maps, 166,642 adjacent walkable pairs
    18 impossible steps   (was 22)
    21 fractional cells   (was ~600 as measured, ~23 real)

    BattleFrontier_OutsideEast  6  worst 96px   <- the worst left in Hoenn
    MtChimney                   4  worst 32px
    LavaridgeTown               3  worst 32px
    Route119                    3  worst 32px
    SootopolisCity              2  worst 48px   <- 1 of these is new, see above

Littleroot 4 -> 0, Slateport 1 -> 0, Mt Pyre 1 -> 0.  Sootopolis 1 -> 2: the
remaining pair is two adjacent POSTS on a terrace edge resolving to 80 and
32, which is a real 48px step between two prop cells and is not yet fixed.
229/229 green.

## g3-archway-82 — a walkable cell does not stand on what it walks through

The largest verticality defect left in Hoenn was the Battle Frontier's east
gate: a corridor cut through the gate is walkable, and both archway PIERS
handed the walker their own top -- 96px, with the corridor either side at 0.

`runHeight` already refused to put a walker on a BUILDING's run, and that
test asks what the run IS: a roof (`gen3RoofRows`), a pitch (`rise`), a door.
An archway pier states none of them.  It is just a column.

So it now also asks what the run looks like FROM THE CELL: if the top stands
more than a course over its own base, and no floor next door is anywhere near
that top, the cell is a hole through the mass rather than its surface.

Two attempts, and the first one taught the rule:

  * Counting any walkable neighbour's RUN found "company up there" every
    time -- the other cells of the archway carry the same 96px pier run, so
    a pier always looked like a plateau.  Nothing changed at all.
  * Only FLAT GROUND neighbours vote.  Floor is what the question is about,
    and floor is the flat shape the terrace passes write.  With no floor
    next door at all the run's answer stands, rather than being guessed at.

The neighbour test is what keeps a real plateau lifting the player exactly as
before -- its walkable neighbours ARE up there with it.

### Region-wide effect

    82 outdoor maps, 166,642 adjacent walkable pairs

                            before   after
    LavaridgeTown              3       0
    Route119                   3       0
    MtChimney                  4       2
    BattleFrontier_OutsideEast 6       4
    SootopolisCity             2       2
    TOTAL                     18       8

Lavaridge and Route 119 went to zero and Mt Chimney halved on the same fix,
which says the archway was never a Battle Frontier quirk -- walkable cells
standing on masses they walk through was a Hoenn-wide fault with one cause.

229/229 green.  Sootopolis, Mt Chimney, Route 119, Lavaridge and Rustboro
shot and checked: no terrace sank, which was the risk this change carried.

### Still open

  * BattleFrontier_OutsideEast 4: two are the gate mouth (ground outside at
    32, corridor inside at 0 -- possibly correct terrain, not yet judged),
    and one more archway at (64,28) the guard does not catch because it has
    no flat-ground neighbour to argue from.
  * MtChimney 2, SootopolisCity 2 (one of the Sootopolis pair is the post
    regression from g3-stamp-81, still unfixed).
  * Route128 19 fractional cells -- the only real concentration left.

## g3-plaza-83 — the datum is not the default floor

Two fixes, and the second one took three attempts because each early form was
right on the map it was written for and wrong on the region.

### Floor you can stand on outranks the top of a wall

`standHeight`'s ring scan takes the ring's MAXIMUM, and a blocked flat cell is
very often the top of a wall rather than any floor.  Sootopolis has a two-cell
post standing in a gap with an 80px wall crown one cell north: the upper post
took the crown and the lower took the terrace, so the pair stood 48px apart
from each other -- the regression g3-stamp-81 introduced.

Walkable flat cells are floor by definition, so they now get their own pass
before anything blocked is considered.  Sootopolis 2 -> 1, back to its
pre-existing single defect.

### A walkable cell with no run still sits on something

`groundAt`'s last branch answered `s.h > 0 and s.h or 0` -- so a walkable cell
with no run and no height of its own got the WORLD DATUM.  Mt Chimney's cable
car forecourt is a terrace at 32 with a bush on it; the bush's cell carries no
run, so it answered 0 with both neighbours at 32: a 32px hole either side of
one cell, in the middle of a plaza.

  1. Fall back to `standHeight`.  Fixed Mt Chimney and Sootopolis and cost
     EIGHT new steps on Route 115 and three on Route 120 -- net 7 -> 15.  Its
     ring reaches three cells, which on an open route is far enough to find
     an unrelated rise and drag the cell up to it.
  2. Only the four TOUCHING cells vote, and only when they agree.  Routes
     back to 0 -- and Mt Chimney back to 2, because a neighbour with no flat
     shape VETOED the vote, and the bush's neighbours carry runs.
  3. A neighbour with neither a run nor a flat floor ABSTAINS instead of
     vetoing, and a run counts as a floor.  This is the one that holds.

### Where Hoenn stands

    82 outdoor maps, 166,642 adjacent walkable pairs
    5 impossible steps       (22 at the start of this thread)
    21 fractional cells

    BattleFrontier_OutsideEast  4   worst 96px
    SootopolisCity              1   worst 32px

    zeroed since: MtChimney, LavaridgeTown, Route119, Route115, Route120,
    LittlerootTown, SlateportCity, MtPyre_Exterior

229/229 green.  Mt Chimney, Mt Pyre, Sootopolis, Route 120 and Oldale shot
and checked -- nothing sank and nothing towered.

### Still open

  * BattleFrontier_OutsideEast 4: two at the gate mouth (ground outside 32,
    corridor inside 0 -- may be correct terrain, still unjudged), one
    archway at (64,28) with no flat-ground neighbour for the guard to argue
    from, and one unexamined.
  * SootopolisCity 1: (49,33)->(50,33), a walkable strip behind a building
    left at the datum -- the "folded roof cell" family, not the plaza one.
  * Route128 19 fractional cells, the only real concentration left.

## g3-brow-84 — cliff edges flush with the terrace they hang from

A drop is drawn as a brow row and face rows under it, and all of them belong
to the ground ABOVE -- the same terrace, seen edge-on.  The tier flood does
not know that: it floods walkable cells into tiers and then raises the blocked
cells between them, so a face can be handed the tier TWO ROWS UP.

New check `/tmp/t/brow.lua` + `browsweep.sh` measures it: for every blocked
cell with walkable terrace to the north and a real drop to the south, is its
top level with that terrace?  Across 82 outdoor maps, 990 brows.

    before   792 flush,  55 proud
    after    808 flush,  32 proud     (and 23 more brows flush overall)

`clampGen3Brows` walks each column downward carrying a cap -- the height of
the last walkable cell above -- and no blocked terrain cell may stand over it.
Only ever lowered, never raised.

### Three placements, and only the last one works

This pass does nothing but cap what other passes decided, so WHEN it runs is
the whole of it:

  1. Beside the terrace pass: clamped 38 cells on Ever Grande and missed
     every cliff, because upright WALL runs -- most of Hoenn's cliff edges --
     are built by `buildVolume` ninety lines later and did not exist yet.
  2. After buildVolume: clamped 413 and STILL left Ever Grande's meadow cliff
     at 96 with the flowers above it at 16.  Traced with a scan print: at
     that moment the cliff's run was 16.  `buildFalls` raises it to 96
     afterwards, carrying the waterfall's crest along its bank.
  3. Last of the height passes, after falls, kerbs and railings.  Ever Grande
     3 proud -> 0, Route 119 2 -> 0, Sootopolis 19 -> 4.

### What it may clamp

Flat `ground` the terrace pass wrote, and upright WALL runs that are not
buildings (a roof, a pitch or a door means a facade, and a facade is not a
cliff edge).  Trees, props and anything an object pass claimed keep their own
height.

WATER IS NOT A TERRACE.  Water is walkable in Emerald -- that is how Surf
works -- so the first cut capped harbour walls to the sea surface at -4 and
put 26 fractional cells into a map that had none.  Water and waterfall cells
clear the cap instead of setting it.

### The trade, stated plainly

    5 impossible steps    (unchanged)
    53 fractional cells   (was 21)

The 32 new ones are faces that adopted their terrace's OWN off-course height
-- Route 119 walls at 20 because the ground they hang from is at 20.  Flush
is what was asked for and flush is what they are; the oddity is a terrace at
20, which predates this pass.  Route 128's 12 remaining proud brows are the
same thing at +4: its shore ground sits a course minus four, so its cliffs
read proud by four pixels.  Not chased.

229/229 green.  Sootopolis, Ever Grande, Route 119 and Mt Pyre shot: Ever
Grande's meadow now ends in a low cliff to the water instead of a tower.

## g3-elev-85 — height from the cartridge, not from the drawing

### What the elevation grid actually says

Measured, per map, over walkable cells:

    Sootopolis   elev 1 (water, 601) + 3 (land, 908)      1 land level
    Mt Pyre      elev 3 (460)                             1 land level
    Mt Chimney   elev 3 (431)                             1 land level
    Route 119    elev 1, 3, 4 + 15 (bridge deck)          2 + a deck
    Ever Grande  elev 1, 3, 5, 7                          3 land levels

The reconstruction had been reading only the collision bit -- "not walkable"
meant "extrude a wall" -- and inferring height from the art.  On these
tilesets that cannot work: houses, crater rim and cliff face are drawn in the
SAME ROCK, so no art test separates them, and the terrace flood chained a
course per blocked band.  Sootopolis came out running 0 at the lake to 9 at
the rim on a map the cartridge says has one land level.

### The measurement that showed it

The old brow check looked only NORTH-facing and only beside walkable cells.
Rewritten to count EVERY edge between adjacent terrain cells in every
direction (`/tmp/t/edges.lua`), Sootopolis had 681 edges of which only 358
climbed one course -- 312 climbed two to NINE, and the worst ran east-west
where the old check never looked.  (16,0) stepped 0 -> 128 across one cell.

### The fix

`elevation_height` pins four maps.  A walkable cell's z is its ROM elevation,
RANKED (Emerald's values are layer ids -- 1 surf, 3 default, then 4, 5, 7 --
not a linear scale) times COURSE, and the drawn-terrace flood does not run.
Pinned, not detected: detection is what turned every purple rock into a
skyscraper.  Pinned by MAP where the tileset is shared -- gTileset_Facility is
Mt Pyre's secondary and twenty-seven other maps'; gTileset_Fortree covers
Faraway Island's interior as well as the grass routes.

`gradeGen3Terrain` then caps every terrain cell at one course over its lowest
terrain neighbour, iterating.  That is what turns a 6-course tower into a rim
with the face stepping down beneath it, and it works in all four directions.
Buildings, trees, props, fences, bridges and water take no part.

    edges climbing more than one course
                      before   after
    Sootopolis          312      0     (537 of 550 at exactly one)
    Ever Grande          --      0     (830 of 833)
    Route 119            --      0     (610 of 743)
    Mt Pyre              --      0     (449 of 449)

Region-wide: 5 impossible steps (was 5), 47 fractional cells.

### Two traps

  * A duplicate table key silently wins.  `gTileset_EverGrande` already had
    an entry further down gen3_shapes.lua, so the stub I added above it was
    overwritten and the pin read nil while Sootopolis' read true.  Check the
    profile actually resolves before trusting a pin.
  * Capping at exactly `lo + COURSE` copies the neighbour's sub-course offset
    -- a shore lip, a kerb -- and spreads it a cell per round: 437 fractional
    heights across Hoenn where there had been 21.  Snap the target to a
    course, never below `lo`.

### Not done from the spec

  * `cliff_face` as a DECAL: faces are still extruded as volumes, now at the
    right heights.  The fold rule -- sample the face's pixels onto the
    vertical side of the higher cell and emit no volume -- is not written.
  * `crater_rim` and `tall_grass` (clump 8-12) classes not added; `stair_*`
    still art-detected rather than pinned to actual stair metatiles.
  * The QA frames were shot at voxel rung 2.  I could not find a settable
    camera angle and did not verify the pitch is in the 35-50 range.

## g3-flight-86 — the flight machinery, and the wall it hits

Built to the stairs contract:

  * `Structures.flightEnds(map, cx, cy)` -> z0, z1, axis, heading, idx, n.
    Landings are the first NON-stair walkable cells at each end of a run of
    stair cells; their z comes from `groundHeight`, the same ranked-elevation
    table the terraces use, so a flight's top tread and the terrace it serves
    are equal by construction.  Consecutive stair cells on one axis are ONE
    flight: the rise is Hi-Lo of the END landings spread over the run, not a
    course per tile.  Cached per run on S.
  * `VoxelScene.groundAt` takes optional `px,py` (world pixel) and its stair
    branch now interpolates z0 -> z1 by position along the flight, instead of
    returning `standHeight` -- the FOOT -- which is why walking a staircase
    never raised the walker at all.  Both entity call sites pass pixels, so
    NPCs, the follow camera and first person all get it.

229/229 green.

### Why it does not fire yet, proved three ways

The stair branch keys on `s.art == "stair"`, and NOTHING in Gen 3 sets it --
`stair_e`/`stair_w` are Gen 1/2 profile pins.  Getting there needs stair
classes for Gen 3, and all three routes to them are blocked on the maps that
matter:

  1. BEHAVIOUR.  Emerald has no general outdoor stair behaviour.  The whole
     set is MB_STAIRS_OUTSIDE_ABANDONED_SHIP (0x1B), the two escalators and
     MB_LADDER.  Mt Pyre's actual staircase metatiles -- 175 and 207, dumped
     and confirmed as white treads -- carry **MB_NORMAL**.
  2. ELEVATION-SEAM INFERENCE (spec 9, route 3) needs neighbours differing by
     one ranked course.  Sootopolis, Mt Pyre and Mt Chimney have ONE walkable
     land elevation, so there are no seams anywhere on them.
  3. ART.  Available, and what the earlier `plateArt`/`treadArt` work used --
     but it is detection, which the spec rules out.

`flightEnds` finds nothing on Sootopolis, Ever Grande or a Pokemon Center
today for exactly this reason.

### The contradiction, stated once

    map           walkable elevations      land levels
    Sootopolis    1 (water) 3 (land)            1
    Mt Pyre       3                              1
    Mt Chimney    3                              1
    Route 119     1, 3, 4 (+15 deck)             2
    Ever Grande   1, 3, 5, 7                     3

Elevation-only (2B) makes Sootopolis two z values and Mt Pyre exactly ONE --
dead flat, which is what the g3-flight-86 shot shows.  9's contract computes
Lo == Hi == 3 for every flight on both, so rise = 0 and every staircase stays
a painted quad.  That cannot meet 8 (rings, treads, an ocean-side drop) on
those maps, because the cartridge does not contain the information 8 asks to
be rendered.  Ever Grande and Route 119 have real bands and work.

Unresolved: whether one-land-level maps fall back to art-derived relief (a
branch on the DATA, not on map.id), or whether those maps are meant to come
out flat.

## g3-synth-87 — stairs classified by art, levels synthesised from the flights

The contradiction is resolved as directed: where the elevation grid cannot
separate terraces, the FLIGHTS say which is above which.

1. `markGen3Stairs` classifies stairs by ART and by `profile.flights`, never
   by behaviour.  Outdoor MB_NORMAL is expected -- Mt Pyre's treads (175/207)
   are MB_NORMAL and so is every outdoor flight in Hoenn.  Tread art is the
   banded test; grated plates relax uniformity and lean on topology plus "drawn
   as something other than the path either side".
   Found: Mt Pyre 40 cells, Sootopolis 90, Ever Grande 127.
2. `buildGen3SynthLevels` cuts walkable ground at the stair cells, treats each
   flight as an edge between the two terraces it joins, seeds at the water (or
   the outermost terrace) and floods +1 COURSE per flight crossed.  Runs only
   where rank cannot -- a map with two or more land elevations is untouched.
3. `flightEnds` prefers synthZ over `groundHeight`, so a flight's landings
   differ and its rise is real.
4. `groundAt` asks `Structures.stairAt` as well as the tile's own art, because
   Gen 3 tilesets carry no stair art for TileShape to return.

Sprite Z now climbs: on a 96 -> 112 flight `groundAt` answers 97.0 at the low
edge and 111.0 at the high edge, and reverses correctly on a descending one.
Camera follow and first person inherit it through `me.gh`.

### Two seeding bugs, both about what counts as the ground floor

  * Seeding EVERY map-edge terrace put all eight of Mt Pyre's border terraces
    at level 0, so its six real flights had nothing to climb -- 0 tiers raised.
    The outermost terrace (most border contact) is the foot of the mountain;
    seed that one.
  * That still gave 0, because a map's flights need not form ONE connected
    graph: Mt Pyre's six link terraces the outermost cannot reach.  Every
    sub-graph needs its own datum -- seed the largest unassigned component
    that has a flight, flood, repeat.

    Mt Pyre    30 components ->  6 tiers,  836 tiles
    Sootopolis 82 components -> 22 tiers, 2128 tiles
    Mt Chimney 52 components ->  5 tiers, 1060 tiles

### Edges, one course each

    Mt Pyre      707 / 707 at exactly one course
    Ever Grande  828 / 833
    Sootopolis   947 / 956
    Mt Chimney   406 / 511      <- open, see below

229/229 green.

### Open

Mt Chimney still shows 105 edges at 2-3 courses.  It is not pinned
`elevation_height`, so `buildDrawnTerraces` runs there AND synthetic levels do
-- two height systems writing the same cells.  Where synth levels run, the
drawn-terrace flood should stand down.

## g3-rings-88 — sub-graph datums withdrawn, classifier tightened

1. STAIR CLASSIFIER.  A flight is now a BLOB of two or more connected
   candidate cells with walkable non-stair landings on two OPPOSITE sides.
   Grouped as a blob, not an axis run: a Gen 3 staircase is typically TWO WIDE
   AND ONE DEEP (Sootopolis' ring steps are metatiles 580/581 side by side),
   so an axis-run test threw every ring away -- along the climb axis each
   column is one cell, and along the cross axis the landings are the railings.
   Roofs, doors, walls, fences, counters and building runs are rejected.

   LAYER-2 COVER IS NOT A REJECTION.  Rejecting covered cells took Sootopolis
   from 90 candidates to 13 and removed every ring staircase: the ring steps
   are drawn UNDER their railing, so all of them report covered.  Cover says
   something is drawn over a cell, not that the cell is a wall.

2. ONE GRAPH, ONE DATUM.  The sub-graph rule from g3-synth-87 is withdrawn --
   it opened a fresh mountain per island, which is the 22 tiers and the slab
   city.  Seed the water, else the single largest walkable component.  Ranks
   cap at 6; an edge that would climb past it is a false stair and is not
   followed.  A component with no flight inherits the nearest assigned z by a
   multi-source flood over the ground, rather than becoming its own island.

       Sootopolis  22 tiers -> 14, from 82 stair cells (89 candidates)
       Mt Pyre      6 tiers -> 6   (kept, as asked)
       Ever Grande  synth does not run: 3 ranked land levels

3. ONE WRITER PER CELL.  Order is now elevation ground -> mark flights ->
   synthetic levels -> drawn terraces, and the drawn-terrace flood stands down
   entirely when the flights already built levels.

   Edges at exactly one course:
       Mt Pyre      666 / 666
       Ever Grande  893 / 898
       Sootopolis   755 / 764

229/229 green.

### Mt Chimney regressed, and I have not fixed it

    before this patch   406 / 511 edges at one course
    after               542 / 1285, with edges up to SEVEN courses

Its synth produces 0 tiers -- its one flight touches three components, so no
edge is valid -- which means the drawn-terrace flood still runs there and the
"one writer" fix does not engage.  The count of terrain edges also jumped
907 -> 1285, so more cells are being classified as terrain than before;
moving `buildGen3ElevationGround` earlier in the order is the likeliest
cause, since kerbs, falls and the refound pass now run after it rather than
before.  Diagnosed to that point only.  Not shipped as fixed.

Also unaddressed from the brief: items 4 (buildings founded on local terrace
z) and 5 (rock capped at min(GEN3_MAX_LAND, dz of walkable sides) with
face-fold).  Ever Grande still marks 125 stair cells; harmless today because
its ranked elevation wins, but they should not be marked at all.

## g3-tier-89 — a flight is a tier edge; Chimney's quarry closed

    MAP              STAIRS  FLIGHT EDGES  RAISED TIERS  EDGES >1 COURSE
    Sootopolis         53         15            8              0
    Mt Pyre            39          6            6              0
    Ever Grande         0          0            0              0
    Mt Chimney          9          0            0              0

    synth z values   Sootopolis  0 / 16 / 32 / 48   (3 ranks, capped)
                     Mt Pyre     0 / 16 / 32 / 48   (6 tiers kept)

1. THE BLOB TEST IS WITHDRAWN.  Banded art with two open sides found 82
   "stairs" on a crater with ONE land level, because every kerb and gate in
   Sootopolis is banded and has ground either side.  What separates a flight
   from a kerb is whether it is the ONLY WAY BETWEEN two pieces of ground:
   delete the candidate and walk up to 8 cells around it; if the two sides
   rejoin, nothing was separated and it is a lip.  Railings and fences are
   TRANSPARENT to that walk -- a single fence cell between two halves of one
   terrace does not make them two terraces, and treating it as solid is how a
   ring of kerbs came back as a ladder of tiers.  Building/roof/door sides are
   rejected outright.  82 -> 53.

2. HARD CAP.  Three ranks on a map that contains surf water, six otherwise.
   Sootopolis is a crater, not a staircase to the sky; capped at six it still
   stacked thirteen tiers of kerb.  An edge past the cap is dropped, not
   followed.  A component with no valid flight inherits the nearest assigned
   z.  No per-island datum.

3. ONE WRITER, NARROW LICENCE.  `buildGen3ElevationGround` now runs on EVERY
   Gen 3 map -- ranked elevation is the cartridge's own answer -- and
   `buildDrawnTerraces` runs only when synth did NOT and the map has >= 2
   ranked land levels.  Mt Chimney has one land level and no valid flight, so
   it now sits on its flat datum instead of being invented from pixels:

       Mt Chimney edges at one course   542 / 1285  ->  all of them
       edges climbing 2-7 courses            743  ->  0

4. Ever Grande marks 0 stairs: where the cartridge already owns height
   (levels >= 2), the stair pass does not look.

229/229 green.

### Against the 4-panel

  * Chimney -- fixed.  One hillside, ash banks a course high, cable car on its
    deck, no canyon of cubes.
  * Pyre, Ever Grande -- unchanged, as asked.
  * Sootopolis -- a bowl with the lake in it and rings around it, no longer
    slab city, but 53 stairs against a target of 12 and its north-west
    quarter is still busier than the art warrants.

### Still not done

  * Item 4 BUILDINGS: founded on local terrace z + measured facade.  Untouched.
  * Item 5 ROCK: h = min(32, max(COURSE, |zA - zB|)) with face-fold.  Untouched
    -- the edge counts are clean because of the brow clamp and grade pass, not
    because rock height is being computed the way the brief asks.

## g3-found-90 — items 4 and 5, no longer deferred

    MAP           BUILDING RUNS  REFOUNDED  zBASE      FACADE   ROCK CUT  >32px  TALL/FLAT
    Sootopolis        132            64     -2..48     16..64      84       40      61
    Mt Pyre             1             0     48..48     32..32     295      104     270
    Ever Grande        22            16     -2..48     16..48     207       15     203
    Mt Chimney         11             0       0..0     16..80      70        0      70

    edges climbing more than one course: 0 on all four

### 4. Buildings sit on the local floor

`run.base` is a building's datum and it was 0 almost everywhere -- the world
floor -- so a house drew its whole measured facade up from zero whatever
terrace it stood on.  With synthetic rings under it that is an office tower:
a 48px house on Sootopolis' third ring rose 48 above the LAKE.

`foundGen3Buildings` runs AFTER the floor is finished and only READS it.
zBase is the floor of the cells the run stands on and where a run straddles
two terraces it takes the LOWER -- never the max, never an average, because a
facade founded high hangs in the air on its low side.  The measured facade is
preserved and capped at GEN3_MAX_ROWS (96px).  64 of Sootopolis' 132 runs
moved; Mt Chimney's eleven were already on their datum, which is right -- it
has one land level.

### 5. Rock is a short drop

Blocked landscape stood to the height of its own DRAWING.  Emerald paints a
crater wall six rows tall and the volume pass built six rows of rock -- the
Sootopolis spires, and Mt Chimney's brown cubes.

    dz = |zA - zB| over the walkable cells each side (railings skipped)
    h  = min(GEN3_MAX_LAND, max(COURSE, dz))
    dz == 0 or one side only -> h = COURSE, a one-course bank

The top sits on the LOWER floor plus h, so rock is flush with the higher side
and the painted face reads down to the lower.  656 columns cut across the four
maps.  159 of them were taller than GEN3_MAX_LAND; 604 stood tall over ground
that is FLAT on both sides -- pure drawing height, separating nothing.

Order unchanged from the brief: ranked ground -> flights -> synth -> drawn
terraces -> found buildings -> cap rock -> falls/kerbs/rails/clampGen3Brows.
Buildings and rock read the finished floor; neither writes it.

229/229 green.  markGen3Stairs, the rejoin walk and the rank cap were not
touched, as instructed.

### Where it still fails

Sootopolis' north-west quarter still reads as pale slabs rather than streets.
The founder is demonstrably working -- zBase spans -2..48, so it is not using
world 0 and not stacking a synth rank -- and rock there is cut.  What is left
is that the quarter's ground is genuinely high in the synth field and its
houses are short, so roofs at similar z merge into one pale mass at this
camera.  That points back at the 53 stairs and the ring count, which this
ticket was told not to touch.

## g3-bowl-91 — a crater is not a graph

The flight graph was the wrong primitive.  It counts every accepted flight as
+1 from the water, and on Sootopolis most "flights" are kerbs on the SAME
annulus -- so the walk climbed one or two real rings, inheritance painted the
rest of the city at that height, and a 48px house stood on a 16px terrace.
Roofs merged.  The lake read as let into a plaza.

BOWL, from data only:
  outdoor Gen 3, ranked land elevations < 2, >= 20 water cells, and water
  touching fewer than 3 map borders (an interior lake, not a coast).
  Sootopolis qualifies.  Mt Pyre and Mt Chimney do not -- no lake.  Ever
  Grande has ranked bands so synth never runs there.

On a bowl, height is DISTANCE TO WATER, not a graph walk:
  4-connected flood from the water; walkable, stair and railing cells are
  transparent, buildings and blocked rock are not, so the measure follows the
  streets rather than tunnelling through the crater wall.
  ring = min(4, floor(dist / 6));  z = ring * 24
  BOWL_STEP is 24, not a COURSE -- at 16 the rim is shorter than a house and
  the camera cannot see that it is a bowl.

    Sootopolis rings by distance:  r0=148  r1=76  r2=93  r3=143  r4=676 cells
    3272 tiles raised, 0 / 24 / 48 / 72 / 96

A KERB IS NOT A FLIGHT: a marked stair survives only where its two landings
sit on DIFFERENT rings.  50 of Sootopolis' 53 were same-ring lips and were
dropped from the stair set -- without touching markGen3Stairs, the rejoin walk
or the rank cap, as instructed.  The 3 that remain have z0 ~= z1 by
construction, so flightEnds and the groundAt interpolation fire.

Hillsides keep the flight-graph synth untouched: Mt Pyre still 6 tiers at
COURSE=16, Mt Chimney still 0.

### Rock -- my previous table was misleading

The "tall / flat" columns in g3-found-90 counted what the pass FIXED, not what
was left, and I reported them as leftovers.  Measured properly, on the FINAL
state after every pass:

    MAP           rock cells   still too tall   of those, flat both sides
    Sootopolis        417             0                    0
    Mt Pyre           414             0                    0
    Ever Grande       474             0                    0
    Mt Chimney        298             0                    0

The item 5 rule is met.  Mt Chimney's banks are each exactly one course --
there are simply many of them, which is what the drawing says.

229/229 green.

## g3-house-92 -- outdoor Gen 3 houses are houses

The low-angle Sootopolis frame is the spec. What shipped in `g3-bowl-91` was
a downtown of 150px towers over a harbour. The stairs did not do that;
`foundGen3Buildings` did, in two lines:

* the neighbour list was `{0,1},{0,-1},{1,0},{-1,0},{0,0}` -- the `{0,0}`
  meant a run read its OWN cell's synth ring as the floor it stands on, so a
  house on ring 3 was founded at 48 rather than on the street it fronts;
* the facade cap was `GEN3_MAX_ROWS * 8` = 96px, six cells. 48 + 96 = 144.

### What the pass does now

    zBase = STREET = lowest finishedFloor among the walkable, non-water,
            NON-BUILDING four-neighbours of the footprint
    facade = this run's own measured art, capped at 40px outdoors
    zTop  = zBase + facade

`GEN3_MAX_ROWS` is withdrawn for outdoor buildings and stays for interiors.

Two supporting changes the measurements forced:

* **Footprints are collected from every tile key, not from the cell the run
  was first seen at.** A run is one tile column; the two tile columns of a
  cell can hold two different runs, and reading a run's east neighbour from
  the wrong column takes the terrace behind the house instead of its street.
* **A house's inner columns share its street.** The middle column of a
  four-tile house touches nothing but siding -- no walkable cell at all --
  and the lake datum sank it two courses below its own end columns. Runs
  with no land neighbour inherit the lowest street already resolved on the
  runs they touch, iterated to a fixed point; only a run with no founded
  neighbour anywhere falls back to 0.
* **A bowl's street is bounded.** Outdoors, on a bowl, a zBase over 32 is
  leftover ring writing under the houses, not a terrace; those runs are
  pulled to 32 and counted. Ranked-elevation maps (Pyre, Ever Grande) are
  not bowls and are untouched -- Pyre's two runs keep zBase 48.

### Sootopolis, measured

                        before          after
    runs                264             264
    zBase               -2 .. 48        0 .. 32
    facade              16 .. 64        16 .. 40
    zTop                16 .. 96        16 .. 72
    zTop > 72           39              0
    founded on water    52 (noLand)     8 noLand w/ water nb, 6 in-game
    zBase > 32          36              0 (58 clamped)

The four runs with a water neighbour and no land neighbour are the gym and
the mart on the lake island -- Emerald draws that island, so founding them at
0 on it is correct, not a raft.

**58 of 264 runs clamped from zBase > 32.** That is a fifth of the town, not
most of it, so the bowl writer is not a pure ramp -- but it is still putting
129 walkable cells at z=48 in a crater whose streets should be two courses.
The floor is the next pass, not a higher cap.

### Not fixed here, on instruction

`buildGen3BowlLevels` still keeps 17 of 17 candidate flights -- the water-cut
KEEP test drops nothing as a kerb -- and `flightEnds` reports z 0->48 across a
single flight where one ring is 16. Both left alone this pass ("do not touch
markGen3Stairs", "leave synth / flights as they are").

### Checks

* 229 mod tests green (17 / 13 / 39 / 54 / 83 / 23).
* Region sweep: **2 impossible steps** over 82 outdoor maps / 166,642 pairs,
  down from 5.
* Rock leftovers measured on the FINAL state: 0 too-tall on Chimney,
  Sootopolis, Pyre and Ever Grande.
* Low-angle (tilt 3) frames: Sootopolis reads as houses on stone streets
  around a lake with the gym on its island; Chimney's cable-car station is a
  building rather than a minaret; Pyre and Ever Grande unchanged.

`tests/drivers/g3_shots.lua` gained `SHOT_TILT` (0 plan / 1 15deg / 2 35deg /
3 50deg) and `SHOT_DAY`. A plan view hides a tower behind its own roof, which
is how `g3-bowl-91` passed a 4-panel and failed the first frame a player saw.

Note for the harness: after a killed run, `POKEPORT_NO_BOOT_REPORT=1` is
required or the next launch sits on the previous-failure screen and the
driver never runs.

## g3-census-93 -- the metatile census, and roles instead of guesses

Every terrain pass in this mod inferred what a cell was from whatever was to
hand: one pixel's colour, how tall the drawing happened to be, whether the
cell was walkable, how many roof rows a flood found. Each inference was wrong
somewhere -- a purple rock became a skyscraper, house siding became a cliff, a
tree became a clifftop, plain volcanic ash became a staircase -- and each fix
moved the error rather than removing it. This pass replaces the inference
with a measurement.

### What was measured

All 518 Gen 3 maps walked, every metatile placed recorded with the collision
and elevation the blockdata pairs it with, and every metatile's art reduced to
sixteen row materials. **10,943 (tileset, metatile) rows over 72 owning
tilesets.**

Two findings changed the design:

**Elevation is not a height field.** 45% of outdoor cells are blocked at
elevation 0 -- and that set includes the trees. Elevation 0 means "not on a
level", which covers a crater rim and a pine equally. Route 111 reports one
elevation level for a map with a plateau and a basin. Height cannot come from
here, and the passes that tried were reading a layer id as an altitude.

**Collision is not a property of the metatile.** Route 111's desert plateau
and the wall holding it up are both metatile 113 -- 3,490 cells of it blocked
and 2,242 walkable. Asked of a metatile, "is this a cliff" has no answer.
Asked of the art it does, and the blockdata resolves the rest per cell. The
first version of the table baked collision into the role and painted the whole
plateau as cliff face; the second describes the drawing only.

### data/gen3_metatiles.lua

    { art, material, cap, face, kind, motif }

`art` is surface / face / brow / banded, `material` is what it is drawn in,
`cap` and `face` are the rows the drawing turns over at. 104 is
`{"brow","rock",8,8}` -- eight pixels of terrace top over eight of face -- and
112 through 125 are sixteen rows of face. `motif` marks a surface with nothing
faced ever drawn beneath it, which is how Hoenn's trees (468 over 476: all
green, blocked, elevation 0) stop reading as grassy clifftops.

Three tools ship beside it in `tools/`: the census, the generator, and a
role-map renderer that puts the 2D art beside the resolved roles, which is how
each of the mistakes above was actually caught.

### Two new rules

**A tread is periodic.** Emerald draws two 8px steps into one metatile, so a
staircase's row luminance repeats at period eight: 175 reads
`182 202 205 208 250 133 133 133` and then those eight values again, exactly.
The cliff face beside it, 191, wanders and never lines up with itself. The old
art tests counted bands, which both pass, and that is why ash kept passing as a
staircase -- 16 of Mt Chimney's 23 "stairs" were grit. Chimney now marks 7.

**A wall is a wall because there is a door in it.** Material cannot separate a
house from a terrace: Sootopolis' crater terraces are worked white stone and
Petalburg's houses are the General tileset's warm reds, so a material test
called 1,375 cells of Sootopolis landscape "wall" and Petalburg's houses
"rock". The cartridge settles it -- a door is a warp, warps are map data.
`Gen3.buildingsOf` walks the blocked run above each warp and takes the
neighbouring columns while the roofline holds.

    Sootopolis   13 warps -> 13 buildings, 182 cells
    Lilycove     14 -> 13     Rustboro  12 -> 11
    Petalburg     6 ->  6     Chimney    4 ->  1 (the cable-car station)
    Route 111     5 ->  4     Mt Pyre    2 ->  2

Building runs asking for a facade: **Sootopolis 264 -> 86, Ever Grande 45 ->
12.** The runs clamped off leftover ring height went 58 -> 0, because the ring
writing was under the 251 things that were never houses.

### One disagreement fixed

`Structures.finishedFloor` reads `S.synthZ` first; `VoxelScene.groundAt` read
the cell's shape first. At Mt Chimney (14..16, 37) three walkable cells of one
flat corridor all carried synthZ 80, and because the volume pass had left a
"wall" shape on two of them groundAt answered **32, 0 and 80 along a row you
can walk in a straight line**. That is the verticality glitch in the
screenshots, and it was a disagreement between two files rather than a wrong
height in either. `Structures.terraceAt` is now the single answer and groundAt
asks it. A flight is also held to one course: Chimney had one reporting
0 -> 80.

### Result

* **1 impossible step** over 82 outdoor maps / 166,642 pairs. It was 5 at the
  start of the session, 2 after g3-house-92. Only Lilycove, at 32px.
* 229 mod tests green.
* Rock leftovers 0 on Sootopolis, Chimney, Pyre, Ever Grande, Route 111.
* Low-angle frames: Sootopolis reads as houses on masonry terraces round a
  lake, Chimney's crater terraces and cable car intact, Pyre's six tiers and
  Ever Grande's League unchanged.

### What is built and NOT switched on

`Structures.buildGen3TerraceLevels` -- terraces as connected `floor` cut only
at `cliff`, one course per cliff crossed northward, seeded at the water. The
primitives are right and the direction rule is not yet: it gives Sootopolis
seven levels of real relief for the first time but 28 cliff votes contradict
each other, Route 111 disagrees with itself 40 times, and Mt Pyre -- which the
flight graph gets right at six tiers -- collapses to one. "North of a cliff is
higher" is true of Hoenn's south-facing cliff art and not of the map as a
whole; Emerald draws north-facing rims too and this pass reads both the same
way, so a switchback closes a loop with a sign error in it.

The fix is per-metatile FACING, and the role table is the place for it: it
already carries `cap` and `face` and the generator already has the art. That
is the next pass. `POKEPORT_GEN3_TERRACES=1` turns the current one on for
measurement; it is off by default and the shipping height passes are unchanged.

## g3-axis-94 -- a flight's direction is a fact about its art

Reported: stairs that should run north-south are running east-west, especially
in Sootopolis.

`flightEnds` tried both axes and kept the one with the LARGER RISE, reasoning
that a stair cell touches different ground on each axis and the climb must be
the steep one. That reasoning is wrong. The rise either side of a staircase is
whatever the terrace passes happened to leave there, and where a flight runs
along the foot of a slope the PERPENDICULAR pair is the steeper one -- so the
flight turns ninety degrees.

The tread art states the direction and does not equivocate:

    metatile   rows drop  rows rep8   cols drop  cols rep8
    175 Pyre       117.2        0.0        29.8        8.3
    207 Pyre       121.3        0.0         0.0        0.0
    580 Soot        81.1        0.0        25.2        7.2
    581 Soot        85.7        0.0         0.0        0.0

Row luminance repeats EXACTLY at period eight over an 80-120 drop while the
columns stay flat. Horizontal bands, every one: all four climb north-south.
That is the same periodicity test that already separates a tread from ash,
taken along the other axis, so it costs nothing to have.

`axis` is now a seventh field on each role row ("y" north-south, "x"
east-west, empty where the metatile is not a tread), `Gen3.stairAxis` reads
it, and `flightEnds` considers ONLY the axis the art names. Where the art is
silent -- a tileset the role table has never seen -- both axes are tried as
before.

Note the labels: this file calls the north-south axis "z" and VoxelScene reads
anything that is not "x" as the y position, so the table's "y" is the loop's
"z". The mapping is done in one place, in `flightEnds`.

Measured: Mt Chimney had two flights at (17,32) and (18,32) whose art says
north-south and which the old code ran east-west across an 80->96 climb.
Sootopolis' 26 flights were already on the right axis but 14 of its stair
cells resolve to no flight at all, which renders flat -- those want the
terrace pass, not this one.

Sweep holds at **1 impossible step** over 166,642 pairs; 229 tests green.

### Delivery note

The AppData shadow at
`C:\Users\cedri\AppData\Roaming\LOVE\Gen2Recomp\mods\DRAMATIC_SHAPE\lib` holds
five files and LOVE resolves them BEFORE the repo, per file. A stale
Structures.lua there silently overrides a current one in the checkout, which is
what happened here -- and what cost fifteen revisions of wrong conclusions
earlier in this session, when every experiment ran against a stale shadow.
Both trees are written together from now on. Deleting the shadow's lib folder
would remove the hazard entirely.

## g3-terrace-95 -- the ground actually steps

Reported, on a low-angle Sootopolis frame: stairs still facing east-west,
stairs sunken, and most of the ground flat instead of climbing.

All three are one fault. **66% of Sootopolis' walkable cells were at z=0.**
A flight with nothing to climb between reports no rise, so `groundAt` answers
`standHeight` -- the foot -- and the staircase sits a course below the terrace
beside it. That is the "sunken" one. And a flat flight shows its tread art
lying flat, which at a low angle reads as bands running the wrong way. That is
the "east-west" one. The staircases were telling the truth: there was nothing
there to climb.

(Worth stating plainly: `stairCell`, the mesher that draws real stepped
geometry, only knows `stair_e` and `stair_w` and never runs on a Hoenn map at
all -- Gen 3 stair cells carry `class=ground, art=stair`. So no Gen 3 flight
has ever been drawn as steps. That is a separate piece of work.)

### Terraces from the role table, fourth attempt

Three approaches were tried and measured before one worked.

**A graph of votes between terraces.** Correct locally by construction, wrong
globally: Hoenn's switchbacks close loops, one bad sign propagates, and
Sootopolis contradicted itself 44 times and came out with its lake shore three
courses above its rim.

**Per-metatile facing, added to fix that.** A real improvement to the data --
54 south-facing and 38 north-facing brows in the General tileset, read from
whether the surface rows sit above or below the wall rows -- and it cut Route
111's contradictions from 40 to 14. Not enough. The table keeps `facing`; the
graph does not.

**A scanline.** Count the cliff runs between a cell and the sea. No equations,
no seed, no sign errors, and it is the brief's own rule -- one block per edge,
in succession. Two corrections were needed: a run only counts if the ground
either side of it is a DIFFERENT terrace (otherwise every boulder in Route
111's desert read as a wall and the basin hit the 96px cap), and a STAIR
separates the terraces it joins rather than merging them (otherwise no
boundary exists anywhere and the whole town sits at the datum).

Then two more, both found by the step invariant rather than by looking:

* **One level per terrace, always.** Falling back to the per-cell count where
  a component's vote was split gave better histograms and unwalkable ground:
  Route 111 put five adjacent cells of one flat corridor at 16, 96, 96, 64 and
  16, because each column crosses a different number of walls on its way
  south. 519 impossible steps. A terrace is flat in the cartridge and it is
  flat here.
* **Neighbouring terraces differ by one course.** The scanline gives each
  terrace a level independently and nothing said they had to agree. Relaxing
  the higher side down to lower+1 terminates (it only lowers) and lands on the
  tallest assignment that is walkable everywhere.

### Where it runs, and why not everywhere

The relaxation buys walkability with relief, and a mountain is mostly relief.
Measured against both shipping builders:

    Mt Chimney   flight graph 6 tiers    terrace pass 417 of 440 at the datum
    Sootopolis   bowl builder 66% at 0   terrace pass raises 465 more cells

So the terrace pass replaces the BOWL builder and the flight graph keeps
hillsides -- decided by the same water test that already chose between them,
never by a map name. Sootopolis goes from z0=576/z16=131/z32=107/z48=54 to
z0=567/z16=465/z32=24, which is a town on two stone terraces instead of a town
at sea level with a few raised patches.

`POKEPORT_GEN3_TERRACES=0` disables it.

### Also in this revision

`Gen3.stairAxis` and the `axis` field: a flight's direction comes from its
tread banding, not from which pair of landings sits further apart. Mt Chimney
had two flights running east-west across an 80->96 climb against art that says
north-south.

### Checks

* **2 impossible steps** over 82 outdoor maps / 166,642 pairs. Sootopolis, Mt
  Pyre, Route 111, Mt Chimney and Ever Grande are all at zero; the two are
  Lilycove (pre-existing) and Route 117, which gained one 32px step -- its
  pond passes the water test and it takes the terrace pass with it.
* 229 mod tests green.

### Still open

Sootopolis' 61 terraces come out as 3 levels, not the 5 or 6 the art suggests,
because the relaxation flattens what the scanline separates. The scanline is
right and the relaxation is blunt; a smarter one would relax along the
boundary graph in level order rather than pairwise. And Gen 3 flights still
render as flat tread art rather than stepped geometry, because `stairCell` has
no north-south form.

## g3-flight-96 -- staircases that are staircases

Two things were left open at g3-terrace-95. Both are closed.

### 1. The relaxation was constraining the wrong pairs

Holding every terrace within one course of its neighbour flattened Sootopolis
from six levels to three -- the "ground is flat" report with its cause moved
rather than removed. The constraint was applied across CLIFF runs, and that is
exactly backwards: a three-course cliff between two terraces is not a defect,
it is a cliff, and you cannot walk it. Forcing those pairs together pulled
every terrace down toward its lowest neighbour and cascaded.

The constraint belongs where the step invariant looks: on pairs you can
actually cross. Ground touching ground with no wall between must meet; two
terraces joined by a staircase must meet; terraces separated by a wall are
left as far apart as the scanline says.

    Sootopolis   before  z0=567 z16=465 z32=24                    3 levels
                 after   z0=567 z16=233 z32=207 z48=37 z64=20 z80=7   6 levels

Relaxations fell from dozens to 3.

Two smaller faults surfaced with it, both found by the invariant:

* **A staircase had no height at all.** Stair cells are deliberately outside
  every terrace -- they are the join between two, and flooding through them
  merged the terraces they connect. But that left them falling back through
  `flightEnds` to `standHeight`, which answers the LOWEST walkable neighbour:
  zero, beside a terrace at 32. Route 117 (33,0) shows it in one frame. Each
  flight now stands on the lower of the two terraces it joins.
* **A flight is a run, not a cell.** Both the constraint and the footing asked
  a stair cell for its neighbours, and the neighbours of a cell mid-flight are
  more stair cells -- so a two-cell flight linked nothing and footed its two
  halves independently. Sootopolis (20,20) and (20,21) are one staircase and
  came out at 0 and 32.

### 2. No Gen 3 staircase had ever been drawn as steps

`stairCell` knows two classes, `stair_e` and `stair_w`, and steps along X in
both. Gen 3 cells reach it carrying class "ground" and art "stair", so `east`
evaluated false and **every staircase in Hoenn was drawn as a west-facing
east-west flight** -- including Sootopolis', whose treads are horizontal bands
and which climb north-south. That is the whole of the "stairs facing east to
west" report. It was never a height bug; that geometry was the only geometry
there was.

`stairCellNS` is the north-south form: four steps along Z, each a quarter of
the cell's depth and a quarter of the rise, each tread wearing the ART ROW at
its own position along the run rather than a slice across it -- because
Emerald draws a north-south staircase as horizontal bands, one per tread.
`buildStairs` picks between the two from `Gen3.stairAxis` and takes the rise
from `flightEnds` rather than from `s.h`, which is the terrace the flight
stands ON and not the height of the flight. Drawing four steps up to that is
what buried the treads in the terrace.

### Checks

* **1 impossible step** over 82 outdoor maps / 166,642 pairs -- the best this
  session, and now with Sootopolis at six levels rather than one. The
  remaining one is Lilycove's, at 32px, and predates all of this.
* 229 mod tests green.
* Sootopolis, Mt Pyre and Mt Chimney at zero each.
* Low-angle frames: Mt Pyre's switchbacks read as ribbed flights climbing the
  mountain where they were flat bands; Sootopolis' ring steps are stepped
  geometry on terraced ground.

### Still open

`stairCellNS` covers the RISING flight only; a descending Gen 3 stairwell
would still be drawn east-west, and nothing in Hoenn's overworld currently
takes that path. The east-west form still uses `s.h` where the north-south one
uses the flight -- worth unifying next time that code is touched.

## g3-flush-97 -- cliff edges reach the ground they hold up

Reported on a Sootopolis frame: a trench along most terrace and cliff edges,
and some staircases still not lifted.

### The trench

`capGen3Rock` only ever CUT. Its whole test was `was > top` -- rock standing
taller than the drop it separates gets shortened -- because every version of
this file until the terrace pass was working on ground that barely moved, and
the only failure mode was a spire.

With terraces the failure runs the other way. A cliff cell whose own DRAWING
is one course tall, beside ground the terrace pass has since raised to 48,
kept its 16 and sat thirty-two pixels below the edge it is supposed to be
holding up. **317 cells in Sootopolis, 204 on Mt Chimney, 61 on Mt Pyre** were
left behind like that. It is not rock standing too tall; it is rock that never
came up.

A second limit was wrong for the same reason: `GEN3_MAX_LAND` capped the drop
at two courses, so where a terrace stands three or four courses above its
neighbour the rock stopped short and the terrace hung over a gap. The cap is
now the tallest terrace the pass can build.

The top of a cliff is the floor above it. Cut to it, and raise to it.

(`rockleft` still reports 1 cell on Sootopolis and 3 on Mt Chimney as "too
tall". They are not: the tool's threshold is the old 32px, and those are
genuine three-course cliffs.)

### The flat staircases

Eighteen of Sootopolis' forty flights reported both landings on the SAME
terrace, which is why they never rose. The terrace flood was the cause. It ran
through walls, trees and props -- right, because the ground under a house
belongs to the street the house fronts -- but that also FUSES two terraces
that touch only behind a building, and a fused pair has no boundary between
it for the staircase to span.

Two stages now. A terrace is the connected WALKABLE floor: the player's own
connectivity, not the mesher's. Blocked non-cliff cells are absorbed
afterwards into whichever terrace they touch, which keeps the ground whole
under a house without joining what a house merely stands between.

    Sootopolis   terraces 61 -> 80,  flat flights 18 -> 10

The remaining ten are staircases whose two sides really are one terrace -- you
can walk around them -- and lifting those would put a step where the player
can walk on the level.

### Checks

* **1 impossible step** over 82 outdoor maps / 166,642 pairs; the one is
  Lilycove's 32px and predates this work.
* 229 mod tests green.
* Sootopolis, Mt Pyre, Mt Chimney, Ever Grande and Route 111 at zero each.
* Low-angle frames: Sootopolis' terrace edges are flush stepped masonry where
  they were grooved; Mt Pyre unchanged.

## g3-rings-98 -- count the walls to the WATER, not to the map edge

Reported: edges, stairs and terraces still not raised in places, and the Cave
of Origin's forecourt -- clay square, two posts in front -- sunken below the
terrace instead of standing above it.

Measured at the cave, before:

    y=13  fl 0  fl 0  fl 0  fl 0  fl 0  fl 0     <- the forecourt
    y=16  fl 16 fl 16 cl -  cl -  cl -  fl 0     <- the ground beside it

The forecourt sat a course BELOW its own surroundings, so the cave read as a
hole in the town.

### Why

The scanline counted cliff runs straight SOUTH to the map edge. Two faults in
that, and the cave has both.

It measures to the wrong thing. What a terrace's height means in a crater is
how many walls stand between it and the WATER, and the water is in the middle
of Sootopolis, not off its southern edge.

And it answers per COLUMN. The cave's forecourt is ten cells wide east-west;
its columns cross different numbers of walls on their way out, the terrace
takes the majority, and the majority was zero -- while the two-cell terrace
beside it, whose single column crosses one wall, sat a course above.

### Breadth-first from the water instead

Every terrace the water touches is level zero; each boundary crossed is one
course outward. A terrace is as high as the number of walls between it and the
sea, which is the brief's own rule and is also simply true of a crater.

This is a graph, and the FIRST attempt at this pass was a graph that failed --
but that one was a system of equations with a sign on every edge, and Hoenn's
switchbacks made it inconsistent. BFS depth from a fixed source has no signs
and no conflicts. Sootopolis reports **0 outvoted cells and 0 relaxations**
where the scanline reported 195 and 9.

    Sootopolis  scanline  z0=662 z16=300 z32=7   z48=23  z64=23 z80=22 z96=21
                BFS       z0=279 z16=206 z32=265 z48=242 z64=65 z80=1

The cave forecourt now stands at 32 with the ground in front of it at 16.

### And absorb into the HIGHEST terrace, not the first one reached

Blocked cells that are not cliffs -- walls, trees, posts, a cave facade --
belong to a terrace, and which one used to be "whichever the scan reached
first". Beside the Cave of Origin one column of the entrance was absorbed into
the low ground in front and sank a course out of its own facade, taking a post
with it. A facade belongs to the ground it RETAINS, not to the hollow in front
of it. (Where a building is FOUNDED is a separate question and
`foundGen3Buildings` still answers it from the street.)

### Checks

* **1 impossible step** over 82 outdoor maps / 166,642 pairs -- Lilycove's
  32px, unchanged and pre-existing.
* 229 mod tests green.
* Sootopolis, Mt Pyre, Mt Chimney, Route 111 and Ever Grande at zero each.
* Flat flights on Sootopolis 18 -> 12 (the scanline reached 10; the six that
  came back are terraces the BFS separates differently, and all of them are
  walkable either way).

## g3-stand-99 -- a staircase stands on its terrace

Reported: the Pokemon Center's level has stairs going up that are flat, the
terrace they lead to is flat too, and there are dark sunken squares scattered
through the town.

One cause, and it is a lifecycle bug rather than a geometry one.

`cache[map.id] = S` happened only after every pass had run. The accessors that
read that cache -- `Structures.flightEnds`, `Structures.terraceAt` -- are
called BY those passes. So `buildStairs`, which runs at position 3394 of the
build, asked for the flight it was about to draw and got **nil**: it took the
default one-course rise and a base of zero, and built the staircase at the
world floor.

These quads carry absolute world Y; the mesher pushes them unchanged. So a
flight on Sootopolis' third ring was drawn forty-eight pixels beneath the ring
-- in the dark under the town. What you see at the cell is the terrace's own
top surface, which is flat, with a hole in it where `S.ground` was cleared for
a staircase that is not there. That is the flat stairs and the dark squares in
one line.

    stair cells with quads: 40
    quads NOT starting at their terrace:  32  ->  0

S is now published as soon as it is constructed. The build is linear and every
pass already assumes the ones before it have written to S, so letting the
accessors answer during it changes nothing except that they answer.

Three smaller things fell out of the same investigation:

* **`stairCell` and `stairCellNS` take a `base`.** Nothing sets it on Gen 1 or
  Gen 2, where the world floor IS the ground, so those maps are byte-identical.
* **`groundAt` asks the terrace before `standHeight`.** A flight with one
  landing, or two at the same level, still stands somewhere -- and
  `standHeight` answers the LOWEST walkable neighbour, which beside a ring at
  48 is the lake. Sootopolis (45,9) was a stair reading 16 with its lowest
  neighbour at 48.
* **`terraceAt` reads the cache directly rather than calling `forMap`.** It is
  asked once per cell by the offline invariant and once per entity per frame
  in game, and `forMap` will rebuild a map's shapes if they are missing.

### Checks

* Walkable cells a course or more below EVERY walkable neighbour, on
  Sootopolis: **1 -> 0**.
* **1 impossible step** over 82 outdoor maps / 166,642 pairs -- Lilycove's
  32px, unchanged.
* 229 mod tests green.
* Sootopolis, Mt Pyre, Mt Chimney, Route 111 and Ever Grande at zero each.

## g3-shelf-100 -- a blocked top is not a wall

Asked for a height map and a metatile map, colour-coded, to see which cells
are sunken rather than to keep inferring it. That was the right instruction:
the four-panel diagnostic (`tools/gen3_heightmap.lua` -- art, terrace height,
role, flights) answered in one frame what five revisions of reasoning had not.

**Almost the whole town was classified `cliff`.** Sootopolis is raised masonry
with narrow streets cut through it; the masonry is blocked, and every blocked
cell that was not a building or a tree fell into the cliff branch. 1,736 of
its 2,600-odd non-water cells.

That is fatal, because a cliff is a BOUNDARY and not a surface:

* it gets no terrace height of its own -- it is excluded from the absorb
* `capGen3Rock` sizes a column from the floors on either side of it, and the
  middle of a raised mass has none, so those cells were **skipped entirely**
  and kept whatever height their DRAWING happened to carry

So the interior of every stone block in the town sat at the height of a
texture rather than the height of its tier. That is the sunken ground, and it
is also why the terraces did not read as terraces: there was nothing between
the streets but unassigned cells.

### Art cannot settle this, and structure can

The town is built of one white stone. A flat top of it profiles as
`brow/manmade cap=1 face=1` -- one row of stone over one row of mortar --
which is indistinguishable from the wall beside it. 365 cells of terrace top
were being called cliff on a one-pixel distinction that does not exist.

The neighbourhood settles it and needs no palette. **A cliff face is what you
see from the ground in front of it, so it has walkable ground on at least one
side. A blocked cell with none is buried inside a raised mass: it is a top you
cannot stand on.** New role, `shelf`: ground you cannot walk on. It takes a
terrace height like any other ground and never acts as a boundary.

    Sootopolis   cliff 1736 -> 741,  shelf 0 -> 1071
    Mt Pyre      cliff 1398 -> 397,  shelf 0 -> 1001
    Route 111    cliff 2704 -> 858,  shelf 0 -> 1846

`capGen3Rock` gains the matching branch: a terrain cell with no walkable
neighbour is set to its tier instead of skipped. 169 cells on Sootopolis were
still at the wrong height after the absorb and are now flush.

### Checks

* **1 impossible step** over 82 outdoor maps / 166,642 pairs -- Lilycove's
  32px, unchanged through all of this.
* 229 mod tests green.
* Sootopolis, Mt Pyre, Mt Chimney, Route 111 and Ever Grande at zero each.
* The same camera against g3-stand-99 differs by **73.7% of pixels**. The
  previous revision differed by 7%, which is the honest measure of how little
  the last fix actually did and how much this one does.

### Note on method

The last three revisions were each measured with a number and shipped without
a picture, and each time the number was right and the frame barely moved. The
diagnostic panel is now in `tools/` and belongs in front of any further claim
that a shape fix has landed.

## g3-shelf-100 -- the diagnostic, and what it found

Asked for, and built first this time: `tools/gen3_heightmap.lua` renders four
panels over one map -- the 2D art, the terrace level of every cell colour-coded
by course, the role the table resolved, and the DEFECTS. Three defects are
measured rather than eyeballed:

    flat stair          a staircase whose two landings are the same level
    sunken cell         a walkable cell rendered below its own terrace
    cliff top too LOW   a cliff whose top does not reach the ground it retains

Sootopolis, before: **407 cliff tops too low.** The bottom-right panel was
almost solid cyan and it traced every terrace edge in the town. That is the
"many areas are still sunken" report, and it had a cause I had not looked for.

### Only FLAT shapes were being raised

The terrace pass rewrote `sh.h = z` for flat ground and left everything else
alone. So the ground rose and everything standing on it stayed at the world
floor: railings at h=10 beside a terrace at 48, wall cells, blocked ground.
`heightAt` is an absolute top and the mesher renders each column against its
neighbours, so what a 10px fence on a 48 terrace wants is h=58 -- it still
shows ten pixels of side. Flat ground takes the terrace as its top; everything
else takes the terrace PLUS the height its own drawing had.

**3,740 standing tiles now rise with their terrace.**

### Three findings behind that

* **A railing is not a cliff.** `Gen3.roleAt` calls any blocked,
  non-building, worked-stone cell a cliff, and Sootopolis edges most of its
  terraces with railings -- 192 of them were treated as terrain, kept out of
  every terrace, never absorbed and never lifted. They are now `rail`: not
  standable, still a BOUNDARY (calling them props merged the terraces either
  side and flattened the town to three levels), and absorbed and lifted like
  anything else standing on a terrace.
* **Only walkable neighbours could vote for a cliff's height.** After
  absorption a terrace edge is often bounded by a wall or a post rather than
  open street, so those cliffs got no vote at all. A cell that HAS a terrace
  has a floor, whether or not you may stand on it.
* **Landscape runs never rose.** `heightAt` prefers `run.h`, and only
  door-rooted runs are refounded. A garden wall or a masonry buttress kept a
  base of zero. Shifted once per run object, not per tile.

### Result, and what is still wrong

    cliff tops too low   407 -> 170
    terrace levels        3  -> 7   (z0=323 z16=1042 z32=631 z48=299 z64=37 z80=6 z96=10)
    sunken walkable cells  0
    impossible steps       1 over 82 maps / 166,642 pairs (Lilycove, pre-existing)
    229 mod tests green

**170 cliff tops are still low and 20 of Sootopolis' 40 flights are still
flat** -- the red cells in the defect panel, including the ones by the Pokemon
Center. Those two are not fixed. The remaining low tops are cells `capGen3Rock`
declines for reasons I have not yet isolated; the flat flights are staircases
whose two ends the terrace BFS gives the same level.

One thing tried and reverted, recorded so it is not tried again: scoping
`gradeGen3Terrain` to walkable cells recovers 16 cliff tops and costs Mt
Chimney a 32px impossible step. Not worth it.

## g3-revert-102 / g3-rail-103 -- a regression withdrawn, and the railings

### The regression

g3-shelf-100 raised every NON-FLAT shape by its terrace: `nu.h = old.h + z`.
By the defect metric that was a large win (407 sunken cliff tops down to 170)
and it was shipped on that metric alone, without a render. It is a bad
regression. `heightAt` is an absolute top and the mesher draws a terrain
column from its NEIGHBOUR'S height up to it, so a 10px railing beside lower
ground became a 58px slab -- Sootopolis came out as a field of tall thin
spikes. **g3-revert-102 withdraws it**, returning to g3-stand-99's geometry,
which is the last state that was actually looked at.

Two method failures produced this, both worth recording:

* A number moved in the right direction and I stopped there. The defect
  counter measures whether a cliff top REACHES its terrace; it says nothing
  about what the column between them looks like.
* The renders are not deterministic. Two runs of byte-identical code differed
  by 64% of pixels, so several before/after comparisons in the preceding
  revisions were worth less than they were presented as. `SHOT_SETTLE=800` or
  more, and diff the images rather than eyeballing them.

Measured on the restored build, which is better than the shelf-100 write-up
implied: **7 terrace levels** (z0=672 z16=485 z32=156 z48=253 z64=135 z80=147
z96=212) and **30 of 39 staircases stepping**.

### The railings, done the other way

The railings really were sunken -- 192 of them at ten pixels above the LAKE
while the terrace they edge stood three courses up -- and they are most of
the sunken edge in the frame. The fix is the one the staircases already got:
move the QUADS, not the height. `buildRails` emits absolute world Y from zero;
it now takes the terrace as a base, and the cell's shape carries `base` so the
ground the mesher paints under the claimed cell lands on the same shelf.

Rendered, diffed against the revert (45,967 pixels changed), and looked at:
no spikes, and the kerbs follow their shelves.

    impossible steps   1 over 82 maps / 166,642 pairs (Lilycove, pre-existing)
    229 mod tests green

### Still open, and honestly stated

Seven of Sootopolis' 39 staircases are still flat. All seven have genuinely
SEPARATE terraces either side -- none connect around -- so all seven ought to
step, and the level assignment is what is wrong rather than the stair
detection. A flat flight also renders climbing north whatever way it runs,
because `north` comes from `z1 > z0` and both are nil when there is no rise;
that is the "facing the wrong direction" report and it is downstream of the
same thing.

Four ways of forcing those to step were tried and all made the map worse:
raising the inland side cascaded to 634 cells at the 96px cap; removing the
relaxation's ground-touch constraint unlocked stepping but that constraint was
also the only thing compressing the field; tightening the cliff-run walk did
nothing; rank compression did nothing because the field was never clipped.
None shipped.

## g3-grade-104 -- the height field as a constraint system

Audited tile by tile, as asked, with `tools/gen3_chunk_audit.py`: it prints
the CURRENT 3D level on every cell of a chunk over that chunk's 2D art, with
stairs and cliffs tinted. The chunk north of the Pokemon Center said this:

    (38,6) level 6   directly beside   (40,5) level 2
    a staircase at (45,7) running from level 1 to level 3

A 64px wall through a town street, and a flight climbing two courses. Both
PASS the step invariant, because you cannot walk across either -- which is
exactly why they survived so long. The invariant asks whether the player can
walk; it does not ask what the town looks like.

### Two rules, and they have to be solved together

    ADJACENT terraces differ by at most the boundary between them.
    A STAIRCASE-joined pair differs by exactly one course.
    A CLIFF that draws N stacked ledges IS N courses.

Applied turn about, the first two fight: rule 2 raises a terrace, rule 1 pulls
it straight back down against a third, rule 2 raises it again. Twenty-four
rounds of that left 21 adjacent pairs over a course apart and 11 staircases
still not a step.

Let rule 1 settle completely first -- it only ever lowers, so it terminates --
then make only those steps rule 1 will not undo. A staircase can step by
raising its upper terrace OR by lowering its lower one; try both, take
whichever keeps every neighbour inside its boundary, and leave the flight flat
if neither works. Flat is then an answer about the map rather than a fight
nobody won.

    adjacent pairs over their boundary   21 -> 0
    staircases not exactly one course    11 -> 9
    Sootopolis levels                    z0=633 z16=777 z32=501 z48=148 z64=1

### Stacked faces are stacked levels

A boundary was worth one course whatever it drew, so a cliff Emerald paints as
three stacked ledges came out the same height as a single kerb. The art counts
them: a BROW metatile is a cap over a face -- the top of one course -- and 27
of Sootopolis' runs stack two or more. A boundary's weight is now its brow
count, minimum one, and a multi-ledge cliff is grown to its full drawn height
wherever the rest of the map allows.

One trap in that, found by the invariant: two terraces can be joined in
several places at once -- a staircase here, a three-ledge cliff there -- and
taking the WIDEST weight let the cliff licence a two-course gap across the
staircase. (12,21) came out a flight footed at level 2 with its upper landing
at 4, which is an impossible step. The TIGHTEST connection governs: if a
staircase joins them they are one course apart, whatever else stands between
them somewhere else.

### Checks

* **1 impossible step** over 82 outdoor maps / 166,642 pairs -- Lilycove's
  32px, pre-existing.
* 229 mod tests green.
* Sootopolis, Mt Pyre, Mt Chimney, Route 111 and Ever Grande at zero each.
* Rendered at SHOT_SETTLE=800 and looked at: no spikes, terraces step, kerbs
  follow their shelves.

### Still open

Nine of Sootopolis' 39 staircases remain flat -- pairs where neither raising
the upper terrace nor lowering the lower one fits the rest of the field. That
is now a reported number rather than an accident, and the chunk audit will
show exactly which.

## g3-course-105 -- what one course of cliff actually looks like

Going tile by tile through Sootopolis' cliff cells, sorted by how often each
metatile appears, gave the vocabulary directly:

    737  x172  the terrace BODY   lum 206 189 179 165 159 158 ... smooth
    723  x51   raised sand body   lum 210 200 191 188 182 177 ... smooth
    577  x29   the terrace EDGE   lum 220 211 [106] 229 229 255 208 169
                                      ... 169 [81] 133 133
    114  x14   the crater's rust wall, sixteen rows of face, flat
    580  x22   the treads, periodic at eight
    729  x --  the street, smooth and bright

The previous revision weighted a cliff run by its count of "brow" metatiles,
and 737 is a brow -- a one-pixel cap over a mottled block -- so **the raised
body was being counted as ledges**. 172 cells of it.

A ledge is a hard SHADOW LINE: one row far darker than the rows either side.
577 has two, bracketing one course of masonry; 737, 723, 729 and 580 have
none. One test separates all of them, and it is now the `ledge` field on every
row of data/gen3_metatiles.lua.

**And a front face counts as well.** The crater's rust wall and Mt Chimney's
ash banks have no shadow line for the opposite reason -- there is no top edge
in the cell, the whole cell IS the vertical face. `Gen3.courseAt` counts both:
a drawn ledge, or a pure `face` metatile of twelve rows or more. Counting
those up a run is what makes a cliff drawn three faces tall come out three
courses tall.

    Sootopolis boundary weights: 175 at one course, 1 at two, 2 at four, 1 at five

### Checks

* **1 impossible step** over 82 outdoor maps / 166,642 pairs (Lilycove, pre-existing).
* 229 mod tests green; adjacent pairs over their boundary: 1 of 179.
* Rendered at SHOT_SETTLE=800 and looked at.

### Honest limits

Only four of Sootopolis' 179 terrace boundaries come out taller than one
course. Where a staircase ALSO joins the same two terraces the tightest
connection wins and the pair stays one apart, which is right -- a flight of
stairs between them means they are one step apart whatever a cliff elsewhere
draws -- but it does mean the tall rims are mostly on boundaries with no
staircase.

And the terrace pass runs only on BOWLS, so Mt Pyre, Mt Chimney and Route 111
never see any of this; they still use the flight graph. The brown and ash
front faces are counted by `Gen3.courseAt` but only reach the height field on
a map that takes this path. Extending it to hillsides was measured earlier as
a regression and has not been redone since the constraint solver landed --
that is the obvious next thing to retry.

Ten of Sootopolis' 39 staircases are still flat.

## g3-stack-106 -- one course per cell, stairs and cliffs alike

Two corrections, both the same shape.

**Each STAIR CELL is a course.** A staircase boundary was worth one course
however long it ran, so a flight drawn as two stacked treads -- (45,9) over
(45,10) -- climbed the same single step as a one-cell kerb. Count the treads.

**Each CLIFF CELL is a course.** The previous revision counted only cells
carrying a drawn shadow line or a full front face, and that left Sootopolis
with four multi-course boundaries out of 179. The crater is drawn as stacked
cells and every one of them is a step down, whether or not the middle of a run
happens to carry a shadow line of its own.

    boundary weights, before   1c:175  2c:1  4c:2  5c:1
    boundary weights, after    1c:118  2c:34 3c:8  4c:9  5c:5  6c:2  7c:1  8c:1  10c:1
    Sootopolis levels          z0=633 z16=727 z32=403 z48=254 z64=18 z80=25

A staircase's weight is also now authoritative where before the tightest
connection won outright: two terraces can be joined in several places, and a
one-course kerb somewhere else must not shorten the flight you actually climb.
A cliff drawn elsewhere still cannot WIDEN the gap past what the flight says.

### Checks

* **1 impossible step** over 82 outdoor maps / 166,642 pairs (Lilycove,
  pre-existing). Sootopolis, Pyre, Chimney, Route 111, Ever Grande at zero.
* 229 mod tests green.
* Rendered at SHOT_SETTLE=800, diffed against the previous revision (499,941
  pixels changed) and looked at: no spikes, visibly deeper terracing.
* Chunk audit re-read tile by tile: adjacent cells differ by one, the flight
  at (45,9)-(45,10) climbs from level 1 to level 2, no wild jumps left in the
  frame.

### Honest limits

Requiring an EXACT climb on every staircase and every cliff at once is
over-constrained -- Hoenn's terraces close loops, and some pairs cannot have
their exact gap without breaking another. 21 of 179 boundaries and 18 stair
pairs settle for a gap that is not their drawn one. More iterations do not
help; it converges there. Reporting it rather than hiding it.

The terrace pass still runs only on BOWLS, so Mt Pyre, Mt Chimney and Route
111 do not benefit from any of this. That remains the largest single thing
left undone.
