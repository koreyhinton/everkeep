# Macroquad book changelog

Before starting the RTS, everkeep was used to work through [Game development in Rust with Macroquad](https://mq.agical.se/) (the "macroquad book"). The result is a small, complete shooter: a ship dodges and shoots falling enemies, with points, a high score, game states, a starfield shader, particle explosions, sprites, audio, a menu, and a loading screen.

It follows the book chapter by chapter, but written imperatively (no closures or methods where the book uses them) and generated from bash snippets with [orc](https://github.com/koreyhinton/orc).

## Running the book game

Check out the last book commit and build as described in the [README](README.md):

```bash
git checkout 879ec22
./build.sh
cargo run
```

The book's assets (not the Tiny Swords pack) need to be in `assets/` for chapter 11 onward. At `879ec22`, `FORCE_VISIBLE_LOAD_SCREEN` is `true`, so the loading screen stays up for at least 2 seconds.

License: the book game's `src/starfield-shader.glsl` (from `e88e2df` through `879ec22`) is not covered by the repo's AGPL-3.0 license. It is the Starfield Tutorial shader by Martijn Steinrucken (The Art of Code), licensed under [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/).

## Commits

Oldest first. The "ex" numbers in the commit messages follow the book's chapters, except where noted.

| Commit | Message | Book chapter | Notes |
|---|---|---|---|
| `1b2933f` | macroquad bk ex1 w/ orc sh gen | 1. Your first Macroquad app | Sets up `build.sh` and the orc snippet generator |
| `64f038d` | macroquad bk ex2: mv circl w/ arr keys | 2. Fly away | |
| `b649805` | macroquad bk ex3: smooth circl | 3. Smooth movement | |
| `de99ce3` | macroquad bk improve ex3 | 3. Smooth movement | Diagonal input adds up; clamps the circle to the screen |
| `333575c` | macroquad bk ex4: falling sq | 4. Falling squares | |
| `7b9c4cd` | macroquad bk ex5: collision | 5. Collision | |
| `84f01e1` | macroquad bk ex5: imperative refactor | 5. Collision | Replaces `impl Shape` methods with the `update-game-over-collision.sh` snippet |
| `1c2694d` | macroquad bk ex6: bullet hell | 6. Bullet hell | |
| `5e00ba4` | macroquad bk ex6: points | 7. Points | Labeled ex6, but is chapter 7 |
| `1628695` | macroquad bk ex6 web build | Release: build for the web | Web build, `index.html`, `quad-storage` for the high score, `.cargo/config.toml` linker fix |
| `def54c2` | macroquad bk ex8: game state | 8. Game state | Separate update and draw `match`es; `CrashFrame` state for one-time game-over work |
| `e88e2df` | macroquad bk ex9: starfield shader | 9. Starfield shader | |
| `0384a33` | macroquad bk ex10: particle explosions | 10. Particle explosions | Builds the `EmitterConfig` inline instead of a `particle_explosion()` function |
| `a62f730` | macroquad bk ex11: graphics 1 of 3 | 11.1 Spaceship and bullets | |
| `600e399` | macroquad bk ex11: graphics 2 of 3 | 11.2 Graphical explosions | |
| `4ac4b68` | macroquad bk ex11: graphics 3 of 3 | 11.3 Animated enemies | |
| `833936f` | macroquad bk ex12: music and sound effects | 12. Music and sound effects | |
| `6a05e85` | macroquad bk ex13: graphical menu | 13. Graphical menu | |
| `36ba997` | macroquad bk imperative ex13 | 13. Graphical menu | Uses `Window::begin`/`end` instead of the `root_ui().window()` closure; renames the snippet to `draw-ui.sh` |
| `fb1db15` | macroquad bk remaining implementation | 14. Resources, 14.2 Coroutines and storage | `Resources` struct loaded by coroutines behind a pie-spinner loading screen; no global `storage` |
| `879ec22` | macroquad bk cleanup load error instead of panic | 14.1 Resources and errors | `?` instead of `unwrap()`; `main` returns `Result` |
