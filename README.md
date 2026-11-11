# EverKeep

Plan: RTS game using [github.com/koreyhinton/sharecmd](https://github.com/koreyhinton/sharecmd) game server, macroquad game engine, https://pixelfrog-assets.itch.io/tiny-swords game assets.

Art: the game art isn't included in this repo because its license doesn't allow redistribution. Download the free Tiny Swords pack from https://pixelfrog-assets.itch.io/tiny-swords and unzip it into `assets/`.

Build and run: `src/main.rs` is generated, so run the generator first, then start the game with cargo. The generator expects [orc](https://github.com/koreyhinton/orc) to be cloned next to this repo (`../orc`).

```bash
./build.sh
cargo run
```

License: code is AGPL-3.0 (see LICENSE). Game art is not covered and remains under its own license.

