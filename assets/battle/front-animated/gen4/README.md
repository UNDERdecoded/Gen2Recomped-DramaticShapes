# Generation 4 animated front sprites

Source: Diamond and Pearl sprites from Bulbagarden Archives. Run:

```powershell
python tools/import_gen4_extended_and_shiny_sprites.py --root .
```

The importer preserves the established Kanto files and imports #152-#386,
using bare, male, then female archive priority. Deoxys uses Speed Forme
(`386S`). It also builds the complete shiny collection in `shiny/`.

Generated artwork is ignored by Git and is not covered by the mod's MIT
license. Verify that you have the right to use and distribute it.
