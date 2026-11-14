# EverKeep

Plan: RTS game using [github.com/koreyhinton/sharecmd](https://github.com/koreyhinton/sharecmd) game server, macroquad game engine, https://pixelfrog-assets.itch.io/tiny-swords game assets.

Art: the game art isn't included in this repo because its license doesn't allow redistribution. Download the free Tiny Swords pack from https://pixelfrog-assets.itch.io/tiny-swords and unzip it into `assets/`.

## Build and run

`src/main.rs` is generated, so run the generator first, then start the game with cargo. The generator expects [orc](https://github.com/koreyhinton/orc) to be cloned next to this repo (`../orc`).

```bash
./build.sh
cargo run
```

## Web build

Run the generator, then build for WebAssembly. Add the wasm target once with rustup first.

```bash
rustup target add wasm32-unknown-unknown
./build.sh
cargo build --release --target wasm32-unknown-unknown
cp target/wasm32-unknown-unknown/release/everkeep.wasm .
python3 -m http.server
```

Then open http://localhost:8000. Opening `index.html` straight from disk won't work because browsers block loading the wasm file from `file://`.

License: code is AGPL-3.0 (see LICENSE). Game art is not covered and remains under its own license. `src/starfield-shader.glsl` is also not covered: it is the Starfield Tutorial shader by Martijn Steinrucken (The Art of Code), licensed under [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/).

