# Generation 1 shiny front sprites

This local collection uses the Japanese Pokemon Yellow Game Boy Color front
sprites, National Dex 001 Bulbasaur through 151 Mew, as visually distinct
Gen 1 shiny art. Gen 1 fronts are single-frame PNGs despite living beneath the
animated collection.

```powershell
python tools/import_yellow_jp_shiny_front_sprites.py --root .
```

Source titles follow `Spr 1y NNN GBC JP.png` on Bulbagarden Archives. The
importer preserves each PNG byte-for-byte and renames it to the shared species
slug. Artwork is ignored by Git and is not covered by the mod's MIT license.
