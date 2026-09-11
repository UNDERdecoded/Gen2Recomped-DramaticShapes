# Generation 3 animated front sprites

Run `python tools/import_gen3_extended_front_sprites.py --root .` to preserve
the established Kanto collection and import Emerald fronts #152-#386, using
bare, male, then female archive priority. Deoxys uses Emerald Speed Forme
(`386S`) in the ordinary `deoxys.png` species slot.

Emerald has no animated Defense Forme front. The importer converts FireRed's
static `386D` sprite into a valid one-frame `deoxys-d.png` atlas and publishes
`DEOXYS_D` and `DEOXYS_DEFENSE` metadata aliases for form-aware mods.

Raw sources are retained in packaging-excluded `_source`. Generated artwork
is ignored by Git and is not covered by the mod's MIT license.
