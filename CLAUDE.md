# everkeep

An RTS game in Rust with macroquad. The Rust source is generated: bash scripts print Rust code, assembled with [orc](https://github.com/koreyhinton/orc) (cloned at `../orc`).

## Build and run

```bash
./build.sh   # runs src/main.sh, formats with rustfmt, writes src/main.rs
cargo run
```

- `src/main.rs` is generated and gitignored. Never edit it; edit the `.sh` files and run `./build.sh`.
- `build.sh` keeps the last good `main.rs` if rustfmt fails.
- `main.sh` prints `#![allow(non_snake_case)]` because orc names like `mn_join_Post` aren't snake case.
- `./test.sh` generates `tests/*.test.sh` into `tests/*.rs` (gitignored) and runs `cargo test`. Run `. ./orc-env.sh` before generating one test file by hand.
- `src/models.sh` prints the game's constants and types (World, Unit, Command, ...). `main.sh` and the tests both print it, so snippets compile against the same definitions everywhere.

## Assembling code with orc

- `src/main.sh` is the app. It prints the program and inlines snippets with backticks: `` ` ./update-units.sh ${v}units_ ` ``.
- Snippets (`src/*.sh`) print straight-line Rust that works anywhere it's inlined. Follow orc's rules in `../orc/CLAUDE.md`.
- `v` is the bash namespace variable. `main.sh` sets `v=${1:-mn_}`, and each snippet takes its namespace as `v=$1`.
- Map a snippet's inputs to Rust names in `main.sh` with exports (`export ${v}units_Units=world.units`). Inside the snippet, bind them with `. ${NSMAP}/bind ${v} Units DeltaT` and use them as `${!units}`, `${!delta_t}`.
- Outputs left unmapped get the namespaced name (`mn_join_Post`).
- App snippets don't need orc's interface header comment. That's only for reusable snippets added to the orc library.
- orc libraries used: animation (`ORC_ANIMATE`), the Rust ws client (`ORC_WS`) and A* pathfinding (`ORC_PATHFINDING`), all set in `orc-env.sh`. Their `models.sh` run between heredocs in `main.sh` (and pathfinding's in the tests too, since `World` holds a `PathGrid`) so a version mismatch stops the build.
- Snippets never call other snippets, so `main.sh` calls orc's `find-path.sh` itself, then `apply-path.sh`, for each unit marked `repath` after a turn's commands. The tests repeat that loop.

## The sim is lockstep

Multiplayer runs both players' sims on each machine (see README "Multiplayer"), so they must stay identical.

- Input snippets only push `Command`s to `world.outbox`. `apply-commands.sh` is the only place that changes units, buildings, gold or `next_id`. `update-objectives.sh` is the only place that sets `world.objectives`, each player's completed `OBJ_` bits. `world.grid` (the pathfinding grid) starts from the map's trees in `world-reset.sh`, and `apply-commands.sh` blocks a new hall's cells. Offline, `main.sh` loops the outbox straight back as the current turn's commands.
- Sim snippets (`apply-commands.sh`, orc's `find-path.sh`, `apply-path.sh`, `update-units.sh`, `update-objectives.sh`, `world-reset.sh`) run in fixed `TICK_SECS` steps and may only depend on commands and sim state: no frame time, mouse, screen size (except `world-reset.sh`'s starting view), clock or `HashMap` order.
- Selection, placing, the drag and the view are local and never go through commands.
- `tests/lockstep.test.sh` checks determinism and the command rules.

## Don't use `v` as a name

`bind` turns each name into a lowercase shell variable (`Vel` becomes `vel`). A bind name of `V` would create a shell variable `v` and overwrite the namespace, so later `${v}...` names in that snippet would come out wrong.

- Don't bind a name that lowercases to `v`, or to anything else the snippet uses in bash (`priv`, `bind_*`).
- Don't name a Rust variable `v`. Use a descriptive name such as `vel`, so it maps to a bind name that's safe.
