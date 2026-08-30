# Gen 6 arena backgrounds

`ARENA FILL: GEN6` chooses these general-location images by the current map id.
Rival fights use the location in which they occur, except the third rival
encounter: although the engine reports Cerulean City, it uses the time-aware
Route 24 `bridges` family. `BOSS BG` may independently replace this plate for a
matching leader, Elite Four/Champion, or canonical static legendary encounter;
its files live beside this folder in `bosses`.

Every runtime plate is a perspective-authored 800x800 scene with a progressively
defocused near foreground to keep sprites grounded on widescreen. The selected
image uses a centred cover fit, so no aspect ratio exposes a letterbox. A subtle
source-space blur softens low-resolution enlargement while leaving the sprites
and interface sharp. Flat arena fills also hold the battle camera at its solved
opening orbit and pitch; wheel, pinch, or stick-click zoom remains available.

## Time-aware sets

- `city`: Pallet, Viridian, Pewter, Cerulean, Lavender, Celadon, Fuchsia,
  Cinnabar, and Saffron.
- `vermilion`: Vermilion City.
- `grassy`: Routes 1, 6, and 22.
- `rockypath`: Routes 3, 4, and 9.
- `bridges`: Route 24, using one coherent fenced-bridge composition
  relit and recolored for each period.
- `route2`: Route 2 has its own dawn, day, dusk, and night clearing set.
- `route5`: Route 5 has its own rolling-hills dawn/day/dusk/night set.
- `fences`: Routes 7, 8, 11, 14, 15, 16, and 25 use the original rural
  `bridges*` compositions, now recolored and consistently fenced. Route 24
  retains the actual bridge art.

Each complete set contains DAWN, DAY, DUSK, and NIGHT. The previously missing
`grassydawn.jpg`, `rockypathdawn.jpg`, and `vermiliondawn.jpg` are lighting-only
derivatives made from their corresponding DAY/DUSK/NIGHT references. Route 2's
new dawn and dusk plates preserve the geometry of its supplied day/night pair.

## Dedicated routes and outdoor areas

- Route 10, Routes 12-13, Routes 17-19, 21, and 23 use their named files.
- Route 6 uses `grassy`; Routes 7, 8, 11, and 14-16 use `fences`; Route 20
  uses `ocean`.
- Viridian Forest and all four Safari Zone regions use their dedicated art.
- Indigo Plateau exterior uses the Victory Road family.

## Caves

- Diglett's Cave and Underground Paths: `tunnel`.
- Mt. Moon 1F/B1F/B2F: `mtmoon`.
- Rock Tunnel 1F/B1F: `tunnel`.
- Seafoam Islands 1F/B1F-B4F: `seafoam`; fishing encounters are explicitly
  pinned to the same plate.
- Cerulean Cave 1F/2F/B1F: `ceruleancave`; fishing and surfing encounters use
  `seafoamislands`.
- Seafoam has no distinct exterior map in Gen 1. Its entrances, signs,
  surrounding ocean, and outside swimmers belong to `ROUTE_20`, which uses
  `ocean`.
- Victory Road 1F-3F: `victoryroad`.

## Gyms and League

- Every city Gym except Saffron uses its named common room for ordinary
  trainers and as the leader fallback when `BOSS BG` is disabled: `pewtergym`,
  `ceruleangym`, `vermiliongym`, `celadongym`, `fuchsiagym`, `cinnabargym`, and
  `viridiangym`. Saffron's ordinary trainers and boss-off Sabrina retain voxel.
- `BOSS BG` may replace only the matching leader encounter. Blaine replaces
  `cinnabargym` with `bosses/blaine.jpg`; Giovanni replaces `viridiangym` with
  `bosses/viridianboss.png`. Sabrina alone receives `bosses/saffrongym.jpg`.
- Boss-off League rooms retain their voxel arenas. Elite Four/Champion plates
  belong to the independent `bosses` collection.
- Fighting Dojo remains general location art because it contains many trainers.

## Story and enemy locations

- Oak's Lab: `oakslab`.
- Power Plant: `powerplant`.
- Pokémon Mansion 1F-3F/B1F: `pokemonmansion`.
- Pokémon Tower 1F-7F: `pokemontower`.
- Rocket Hideout B1F-B4F/elevator: `rockethideout`.
- Silph Co. 1F-11F/elevator: `silphco`.
- Vermilion Dock and SS Anne bow: `ssanne`.
- SS Anne decks, rooms, kitchen, and captain's room: `inssanne`, shown from
  inside a passenger cabin facing its closed corridor door.

Unknown imported outdoor maps may use `grassy`; unknown indoor maps retain the
normal voxel battle arena. Any missing or invalid image also fails open instead
of producing a black screen.
