# Generation 3 animated back sprites

Run `python tools/import_gen3_extended_back_sprites.py --root .` to preserve
the established Kanto collection and import Emerald backs #152-#386, using
bare, male, then female archive priority. Deoxys uses Emerald Speed Forme
(`386S`) in the ordinary `deoxys.png` species slot.

Emerald has no animated Defense Forme back. The importer converts FireRed's
static `386D` sprite into a valid one-frame `deoxys-d.png` atlas and publishes
`DEOXYS_D` and `DEOXYS_DEFENSE` metadata aliases for form-aware mods.

Generated artwork is ignored by Git and is not covered by the mod's MIT
license. Verify that you have the right to use and distribute it.
