# everkeep

An RTS game in Rust with macroquad. The Rust source is generated: bash scripts print Rust code, assembled with [orc](https://github.com/koreyhinton/orc) (cloned at `../orc`).

## Build and run

```bash
./build.sh   # runs src/main.sh, formats with rustfmt, writes src/main.rs
cargo run
```

- `src/main.rs` is generated and gitignored. Never edit it; edit the `.sh` files and run `./build.sh`.
- `build.sh` keeps the last good `main.rs` if rustfmt fails.
- `main.sh` prints `#![allow(non_snake_case)]` because orc names like `mn_dist_D` aren't snake case.

## Assembling code with orc

- `src/main.sh` is the app. It prints the program and inlines snippets with backticks: `` ` ./distance.sh ${v}dist_ ` ``.
- Snippets (`src/*.sh`) print straight-line Rust that works anywhere it's inlined. Follow orc's rules in `../orc/CLAUDE.md`.
- `v` is the bash namespace variable. `main.sh` sets `v=${1:-mn_}`, and each snippet takes its namespace as `v=$1`.
- Map a snippet's inputs to Rust names in `main.sh` with exports (`export ${v}dist_Vel=vel`). Inside the snippet, bind them with `. ${NSMAP}/bind ${v} Vel T D` and use them as `${!vel}`, `${!t}`, `${!d}`.
- Outputs left unmapped get the namespaced name (`mn_dist_D`).
- App snippets don't need orc's interface header comment. That's only for reusable snippets added to the orc library.

## Don't use `v` as a name

`bind` turns each name into a lowercase shell variable (`Vel` becomes `vel`). A bind name of `V` would create a shell variable `v` and overwrite the namespace, so later `${v}...` names in that snippet would come out wrong.

- Don't bind a name that lowercases to `v`, or to anything else the snippet uses in bash (`priv`, `bind_*`).
- Don't name a Rust variable `v`. Use a descriptive name such as `vel`, so it maps to a bind name that's safe.
