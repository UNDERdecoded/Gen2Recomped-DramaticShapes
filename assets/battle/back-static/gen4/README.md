# Generation 4 static back sprites

Run `python tools/import_gen4_extended_and_shiny_sprites.py --root .` to
preserve the established Kanto files, import ordinary Diamond/Pearl backs
#152-#386, and build the Platinum shiny collection #001-#386. The importer
uses bare, male, then female archive priority and falls back from a missing
Platinum file to its shared Diamond/Pearl file. Deoxys uses Speed Forme.

Generated artwork is ignored by Git and is not covered by the mod's MIT
license. Verify that you have the right to use and distribute it.
