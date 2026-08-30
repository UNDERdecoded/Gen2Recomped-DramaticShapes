# Generation 5 animated front sprites

Source reference: [Pokémon Database sprite archive](https://pokemondb.net/sprites)

The importer downloads individual files using the documented asset pattern,
for example `https://img.pokemondb.net/sprites/black-white/anim/normal/pikachu.gif`.

```powershell
python tools/import_animated_sprites.py --set gen5 --root .
python tools/import_gen5_extended_normal_sprites.py --root .
```

The first command imports Kanto. The extension command preserves those files
and adds Chikorita through Deoxys to the front/back atlases and shared metadata.
Generated artwork is ignored by Git and is not covered by the mod's MIT
license. Verify that you have the right to use and distribute it.
