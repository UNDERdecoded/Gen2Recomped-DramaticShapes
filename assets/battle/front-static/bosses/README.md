# Independent boss battle backgrounds

`BOSS BG: ON` may override whichever illustrated collection `ARENA FILL`
selects. It does nothing with `ARENA FILL: OFF` or `WHITE`, and it never changes
ordinary rival battles: Oak's Lab, Route 2, Route 24/25, SS Anne, Pokemon Tower,
and Silph Co continue to use their location art.

The current encounter routing covers:

- Brock, Misty, Lt. Surge, Erika, Koga, Sabrina, Blaine, Silph Co Giovanni,
  Rocket Hideout B4F Giovanni, and Viridian Gym Giovanni. Rocket Hideout uses
  `rocketboss.jpg`, Silph uses `silphboss.jpg`, and his Gym uses
  `viridianboss.png`.
- Every Gym except Saffron has a matching general-location plate for ordinary
  trainers and boss-off fallback. Blaine uniquely replaces
  `gen6/cinnabargym.jpg` with `blaine.jpg`; Giovanni replaces
  `gen6/viridiangym.png` with `viridianboss.png`. Saffron ordinary trainers and
  boss-off Sabrina retain voxel; Sabrina alone uses `saffrongym.jpg`.
- Lorelei, Bruno, Agatha, Lance, and the Champion room.
- Canonical static Zapdos (Power Plant), Articuno (Seafoam B4F), Moltres
  (Victory Road 2F), and Mewtwo (Cerulean Cave B1F). Species and map must both
  match, so a trainer or party member of the same species cannot trigger one.

`mew.jpg` is retained supplied art for future ROM/content routing; Gen 1 has no
canonical Mew map encounter. `cinnabargym.jpg` is now the common Gym plate in
the `gen6` collection, while Blaine uses his trainer-specific `blaine.jpg`.

Like the general collection, every image is a perspective-authored 800x800
scene with foreground room for widescreen cover cropping.
