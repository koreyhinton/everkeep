# EverKeep

Plan: RTS game using [github.com/koreyhinton/sharecmd](https://github.com/koreyhinton/sharecmd) game server, macroquad game engine, https://pixelfrog-assets.itch.io/tiny-swords game assets.

Art: the game art isn't included in this repo because its license doesn't allow redistribution. Download the free Tiny Swords pack from https://pixelfrog-assets.itch.io/tiny-swords and unzip it into `assets/`.

# Gameplay

A starter RTS. Press Space (or Play) to start, and Escape to pause.

- You start with one pawn and 500 gold, shown in the HUD along the bottom.
- **Build Main Hall** (bottom-right, 200 gold): a see-through hall follows the mouse. Left-click to place it, or right-click to cancel.
- Drag a box around your hall to select it, then **Train Pawn** (50 gold) to add a pawn next to it.
- Drag a box around units to select them (units win over buildings), and right-click to move them. The view scrolls to follow them across the world, and the minimap in the HUD's bottom-left shows the whole world and where you're looking.

## Multiplayer

Two players can play over [sharecmd](https://github.com/koreyhinton/sharecmd)'s lockstep server. Every order (placing a hall, training a pawn, moving) is a command. Each client sends its commands for a turn to the server, and both clients run both players' commands on the same turn. With the same seed from the server, both simulations stay in step. The HUD shows a checksum of the game state, which should match in both windows.

Start the server from a sharecmd checkout (its `build.sh` also needs `../orc`):

```bash
./build.sh
go run . -mode server -addr :8080
```

Then start two clients and choose **Multiplayer** in each:

```bash
cargo run -- --server http://localhost:8080
```

The Multiplayer button only shows on desktop when `--server` is given. In the browser it connects to port 8080 on the page's host, or to `?server=URL`.

The websocket and HTTP code comes from orc's Rust ws library (`ORC_WS`, set in `orc-env.sh`), adapted from sharecmd's Rust demo client.

## Build and run

`src/main.rs` is generated, so run the generator first, then start the game with cargo. The generator expects [orc](https://github.com/koreyhinton/orc) to be cloned next to this repo (`../orc`). The orc library versions it asks for are set in `orc-env.sh`; if the build fails with `invalid orc animation version specified`, check out the orc version that matches, or update `orc-env.sh` (and the code) to the version you have.

```bash
./build.sh
cargo run
```

## Tests

```bash
./test.sh
```

`test.sh` runs `build.sh`, generates each `tests/*.test.sh` into a `tests/*.rs` file (gitignored, like `main.rs`), then runs `cargo test`. Like the build, it expects orc at `../orc`. The tests don't open a window or need the game art: they stub out macroquad's draw calls and check what would have been drawn.

To run one test, run `./test.sh` once to generate the test files, then pass a name filter to cargo:

```bash
cargo test --test lockstep same_seed
```

### Mutation tests

```bash
./tests/mutate.sh
```

These check the inverse: that the tests fail when the game is wrong. Each mutant is a copy of the scripts with one `sed` edit. It either removes a snippet entirely (as if it were never written, the state the tests were first written against) or adds one bug, such as a hall that costs nothing or a minimap that ignores units. The tests run against each copy, and every mutant must make at least one test fail. A mutant that survives means a gap in the tests; the script prints which test killed each mutant. It takes about 30 seconds and shares `target/` with the normal build. Add a mutant to `tests/mutate.sh` when you add a feature.

On Linux, the `audio` feature needs ALSA's development files to build (`sudo apt install libasound2-dev`).

CI (`.github/workflows/rust.yml`) checks out orc's `main` next to this repo and runs `./test.sh` on pushes and pull requests to `main`.

## Web build

Add the wasm target once with rustup, then build. `build-web.sh` runs the generator, builds `everkeep.wasm`, and copies it and orc ws's browser plugin (`orc_ws.js`) next to `index.html`.

```bash
rustup target add wasm32-unknown-unknown
./build-web.sh
python3 -m http.server
```

Then open http://localhost:8000. Opening `index.html` straight from disk won't work because browsers block loading the wasm file from `file://`.

License: code is AGPL-3.0 (see LICENSE). Game art is not covered and remains under its own license.

## Macroquad book game

Before the RTS, this repo was used to work through the macroquad book, which produced a small shooter game. It can be referenced as a simple, complete example of the code style used here. See [macroquad_book_changelog.md](macroquad_book_changelog.md) for the commits, the chapter each one covers, and how to check out and run the finished game.
