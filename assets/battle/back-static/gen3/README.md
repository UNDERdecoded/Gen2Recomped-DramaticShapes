# Generation 3 static back sprites

Run `python tools/import_gen3_extended_back_sprites.py --root .` to preserve
the established Kanto collection and import Ruby/Sapphire backs #152-#386,
using bare, male, then female archive priority.

Ruby/Sapphire has no static Speed Forme Deoxys, so `deoxys.png` uses its
available Normal Forme (`3r 386`). `deoxys-d.png` uses FireRed Defense Forme
(`3f 386D`) for form-aware compatibility.

Generated artwork is ignored by Git and is not covered by the mod's MIT
license. Verify that you have the right to use and distribute it.
