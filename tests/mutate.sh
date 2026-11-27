#!/bin/bash

# Mutation tests: checks that the tests fail when the game is broken or
# missing, not just that they pass when it works.
#
# Each mutant is a copy of the repo's scripts with one sed edit to one or
# more files, then the tests are generated and run against that copy:
#   missing   the whole snippet prints nothing, as before it was written (the
#             test-first state). Killed by any failure, a compile error too.
#   bug       one behavior broken. It must still compile, and killed only by
#             a failing test (a compile error is BROKEN: fix the sed).
# A mutant survives (bad) when every test passes. Exits 1 unless every mutant
# is killed.
#
# This lives in tests/ because tests/multiplayer.test.sh greps the repo root
# and src/ for its websocket variable, which the sed below names.
#
# Mutants are built in target/mutants/crate, a copy of the crate that is kept
# between runs so cargo only recompiles test files a mutant changed. It
# shares the repo's target directory, so the dependencies aren't built twice,
# under its own package name (everkeep-mutant) so it never touches the real
# crate's test binaries.

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error, script must not be sourced. Run it without sourcing it" >&2
    return 1
fi

RN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${RN_DIR}" || exit 1
. ./orc-env.sh

RN_CRATE="${RN_DIR}/target/mutants/crate"
RN_LOGS="$(mktemp -d)"
trap 'rm -rf "${RN_LOGS}"' EXIT
export CARGO_TARGET_DIR="${RN_DIR}/target"

# mutants: a kind (missing or bug), a name, the files to edit (relative to
# the repo, space-separated), and the sed script to apply to each
MT_KINDS=()
MT_NAMES=()
MT_FILES=()
MT_SEDS=()
mutant() { MT_KINDS+=("$1"); MT_NAMES+=("$2"); MT_FILES+=("$3"); MT_SEDS+=("$4"); }

# ---- not implemented: each snippet the integration tests inline ----
for snippet in hud-layout update-hud update-placement update-select update-orders \
    apply-commands update-units update-scroll draw-world draw-placement draw-minimap \
    draw-hud update-unit-frame world-reset world-checksum net-recv net-turn-msg \
    update-objectives draw-objectives draw-drag-box; do
    mutant missing "${snippet}.sh not written" "src/${snippet}.sh" '/^cat << EOF$/,/^EOF$/d'
done
mutant missing "orc websockets not wired in" "orc-env.sh build-web.sh src/main.sh" '/ORC_WS/d'

# ---- HUD and placement ----
mutant bug "Build Main Hall doesn't start placing" src/update-hud.sh \
    '/= Some(BuildingKind::MainHall);/d'
mutant bug "Train Pawn doesn't queue a pawn" src/update-hud.sh \
    '/Command::TrainPawn { hall:/d'
mutant bug "a press on the HUD places the hall" src/update-placement.sh \
    's/ && \${v}on_map//'
mutant bug "the hall is placed in screen space, not world space" src/update-placement.sh \
    's/ + \${!view}\.\([xy]\))/)/'
mutant bug "the ghost is opaque" src/draw-placement.sh \
    's/Color::new(1\.0, 1\.0, 1\.0, 0\.5)/WHITE/'
mutant bug "the ghost doesn't follow the mouse" src/draw-placement.sh \
    's/\${v}mouse_x + HALL_TEXTURE_OFFSET/400.0 + HALL_TEXTURE_OFFSET/'
mutant bug "the HUD shows the starting gold, not the gold left" src/draw-hud.sh \
    's/format!("Gold: {}", \${!gold})/format!("Gold: {}", START_GOLD)/'
mutant bug "Train Pawn shows without a hall selected" src/draw-hud.sh \
    's/"Train Pawn", \${v}hall,/"Train Pawn", true,/'
mutant bug "the HUD doesn't show what's selected" src/draw-hud.sh \
    's/^\( *\)"\(1 Pawn\|Main Hall\)"\.to_string()/\1"Nothing selected".to_string()/; s/format!("{} Pawns", \${v}pawns)/"Nothing selected".to_string()/'
mutant bug "the minimap ignores units" src/draw-minimap.sh \
    's/\${v}unit\.pos\.\([xy]\) \* \${v}scale/0.0/'
mutant bug "the minimap's view outline is 1.0 thick" src/draw-minimap.sh \
    's/^        2\.0,$/        1.0,/'
mutant bug "the minimap's view outline is on fractional pixels" src/draw-minimap.sh \
    's/\(let \${v}view_[a-z]* = .*\)\.round();/\1;/'
mutant bug "the drag box outline is 1.0 thick" src/draw-drag-box.sh \
    's/, 2\.0, WHITE);/, 1.0, WHITE);/'
mutant bug "the drag box outline is on fractional pixels" src/draw-drag-box.sh \
    's/\.round()//g'
mutant bug "the minimap ignores the view" src/draw-minimap.sh \
    's/\${!view}\.[xy]/0.0/g'

# ---- selection and orders ----
mutant bug "buildings are selected along with units" src/update-select.sh \
    's/selected = !\${v}any_unit && /selected = /'
mutant bug "a press on the HUD starts a drag" src/update-select.sh \
    's/if \${v}mouse_y < screen_height() - HUD_H {/if true {/'
mutant bug "the other player's units can be selected" src/update-select.sh \
    's/unit\.selected = \${v}unit\.owner == \${!me} && /unit.selected = /'
mutant bug "a drag only selects units it encloses" src/update-select.sh \
    's/\${v}box\.overlaps(&\${v}rect)/${v}box.contains(${v}rect.point()) \&\& ${v}box.contains(${v}rect.point() + ${v}rect.size())/'
mutant bug "a drag selects a building by its footprint, not its picture" src/update-select.sh \
    's/\${v}box\.overlaps(&\${v}picture)/${v}box.overlaps(\&Rect::new(${v}building.pos.x + ${v}building.hitbox.x, ${v}building.pos.y + ${v}building.hitbox.y, ${v}building.hitbox.w, ${v}building.hitbox.h))/'
mutant bug "a click acts like a drag" src/update-select.sh \
    's/let \${v}click = .*;/let ${v}click = false;/'
mutant bug "a drag acts like a click" src/update-select.sh \
    's/let \${v}click = .*;/let ${v}click = true;/'
mutant bug "a click picks the last unit, not the one in front" src/update-select.sh \
    's/ && \${v}unit\.pos\.y >= \${v}front//'
mutant bug "a click on the hall's roof misses it" src/update-select.sh \
    's/\${v}picture\.contains(\${v}point)/${v}picture.contains(${v}point) \&\& ${v}point.y >= ${v}building.pos.y + HALL_HITBOX.y/'
mutant bug "a click can pick the other player's unit" src/update-select.sh \
    's/if \${v}unit\.owner == \${!me} && \${v}rect\.contains/if ${v}rect.contains/'
mutant bug "the drag is in screen space, not world space" src/update-select.sh \
    's/\(\.min(\${v}end_[xy])\) + \${!view}\.[xy],/\1,/'
mutant bug "right-click orders no units" src/update-orders.sh \
    's/units: \${v}ids,/units: vec![],/'

# ---- the sim ----
mutant bug "a hall costs nothing" src/apply-commands.sh \
    '/-= HALL_COST;/d'
mutant bug "a pawn costs nothing" src/apply-commands.sh \
    '/-= PAWN_COST;/d'
mutant bug "a hall is built without the gold" src/apply-commands.sh \
    's/ && \${!gold}\[\${!player}\] >= HALL_COST//'
mutant bug "halls can overlap" src/apply-commands.sh \
    's/if !\${v}blocked && /if /'
mutant bug "a player can move the other player's units" src/apply-commands.sh \
    's/ && \${v}unit\.owner == \${!player} {/ {/'
mutant bug "a player can train at the other player's hall" src/apply-commands.sh \
    's/building\.id == \*\${v}hall && building\.owner == \${!player}/building.id == *${v}hall/'
mutant bug "positions aren't clamped to the world" src/apply-commands.sh \
    's/(\*\${v}\([xy]\))\.clamp(0, WORLD_[WH] as i32)/(*${v}\1)/'
mutant bug "a new pawn appears far from its hall" src/apply-commands.sh \
    's/building\.pos + vec2(.*, 48\.0))/building.pos + vec2(400.0, 0.0))/'
mutant bug "units never move" src/update-units.sh \
    '/\${v}unit\.pos += /d'
mutant bug "units overshoot instead of stopping at their target" src/update-units.sh \
    '/\${v}unit\.pos = \${v}unit\.target;/d'
mutant bug "the view doesn't scroll right" src/update-scroll.sh \
    '/\${!view}\.x = \${v}unit\.pos\.x - (\${v}map_w - SCROLL_MARGIN);/d'
mutant bug "spawn spots aren't shuffled" src/world-reset.sh \
    '/\${v}spots\.swap(/d'
mutant bug "both players start at the same spawn spot" src/world-reset.sh \
    's/spawns\[\${v}spots\[\${v}owner\]\]/spawns[${v}spots[0]]/'
mutant bug "the spawn ignores the seed" src/world-reset.sh \
    's/let mut \${v}rng: u64 = \${!seed} as u64;/let mut ${v}rng: u64 = 0;/'
mutant bug "the checksum ignores positions" src/world-checksum.sh \
    '/\${v}unit\.\(pos\|target\)\.[xy]\.to_bits(),/d'

# ---- objectives ----
mutant bug "a player's own hall counts as the rival's" src/update-objectives.sh \
    's/building\.owner != \${v}player/building.owner == ${v}player/'
mutant bug "sight range is ignored" src/update-objectives.sh \
    's/<= SIGHT_RANGE/<= 1e9/'
mutant bug "the other player's units find the hall" src/update-objectives.sh \
    's/unit\.owner == \${v}player \&\& {/true \&\& {/'
mutant bug "offline has no rival hall" src/world-reset.sh \
    's/let \${v}playing = .*;/let ${v}playing = true;/'
mutant bug "the checksum ignores objectives" src/world-checksum.sh \
    '/\${!world}\.objectives\[[01]\],/d'
mutant bug "the check mark is never drawn" src/draw-objectives.sh \
    's/if \${v}done {/if false {/'
mutant bug "the map name isn't drawn" src/draw-objectives.sh \
    '/draw_text(\${!map_name}/d'
mutant bug "a done objective isn't greyed" src/draw-objectives.sh \
    's/if \${v}done { GRAY } else { WHITE }/WHITE/'

# ---- drawing ----
mutant bug "selection rects ignore the view" src/draw-world.sh \
    's/ - \${v}pad - \${!view}\.\([xy]\),/ - ${v}pad,/'
mutant bug "running units draw the idle sheet" src/draw-world.sh \
    's/\[\${v}unit\.running as usize\]/[0]/'
mutant bug "every unit draws in blue" src/draw-world.sh \
    's/pawn_textures}\[\${v}unit\.owner\.min(1)\]/pawn_textures}[0]/'
mutant bug "units ignore flip" src/draw-world.sh \
    's/flip_x: \${v}unit\.flip,/flip_x: false,/'
mutant bug "a unit never takes its sprite's frame" src/update-unit-frame.sh \
    '/\${!unit}\.frame = /d'

# ---- the lockstep server's messages ----
mutant bug "a turn message doesn't advance the turn" src/net-turn-msg.sh \
    '/\${!next_send} += 1;/d'
mutant bug "turns from the server are dropped" src/net-recv.sh \
    '/\${!confirmed}\.insert/d'
mutant bug "the start message is ignored" src/net-recv.sh \
    '/\${!started} = Some/d'
mutant bug "the end message is ignored" src/net-recv.sh \
    '/\${!end_reason} = Some/d'

# copy <from> <to>: the repo's scripts and crate files the tests need
copy_repo() {
    mkdir -p "$2/src" "$2/tests"
    cp "$1"/*.sh "$1/Cargo.toml" "$1/Cargo.lock" "$2/"
    # its own package name, so its builds never overwrite the real crate's in
    # the shared target directory (same name, same version, same hashes)
    sed -i 's/^name = "everkeep"$/name = "everkeep-mutant"/' "$2/Cargo.toml"
    rm -f "$2/src/"*.sh
    cp "$1/src/"*.sh "$2/src/"
    cp "$1/tests/"*.test.sh "$2/tests/"
    # cargo needs the bin target to exist; the tests don't compile it
    [[ -f "$2/src/main.rs" ]] || echo 'fn main() {}' > "$2/src/main.rs"
}

# run_tests <log>: generate every test into the mutant crate (rewriting a file
# only if it changed, so cargo skips the rest) and run them all
run_tests() {
    local f name out
    for f in "${RN_CRATE}/tests/"*.test.sh; do
        name=$(basename "${f}" .test.sh)
        out="${RN_CRATE}/tests/${name//-/_}.rs"
        "${f}" > "${out}.new" 2>> "$1" || return 3
        if cmp -s "${out}.new" "${out}"; then rm "${out}.new"; else mv "${out}.new" "${out}"; fi
    done
    (cd "${RN_CRATE}" && cargo test --test '*' --no-run -q) >> "$1" 2>&1 || return 2
    (cd "${RN_CRATE}" && cargo test --test '*' --no-fail-fast -q) >> "$1" 2>&1 || return 1
    return 0
}

# the real code must pass first, or every mutant would look killed
copy_repo "${RN_DIR}" "${RN_CRATE}"
run_tests "${RN_LOGS}/baseline.log"
if [[ $? -ne 0 ]]; then
    cat "${RN_LOGS}/baseline.log" >&2
    echo "baseline: the unmutated game fails its tests, fix that first" >&2
    exit 1
fi
echo "baseline: passes"

RN_BAD=0
for i in "${!MT_NAMES[@]}"; do
    kind="${MT_KINDS[$i]}"
    name="${MT_NAMES[$i]}"
    log="${RN_LOGS}/mutant-${i}.log"
    copy_repo "${RN_DIR}" "${RN_CRATE}"

    changed=0
    for file in ${MT_FILES[$i]}; do
        sed -i "${MT_SEDS[$i]}" "${RN_CRATE}/${file}"
        cmp -s "${RN_DIR}/${file}" "${RN_CRATE}/${file}" || changed=1
    done
    # a sed that no longer matches would test the real code
    if [[ ${changed} -eq 0 ]]; then
        echo "STALE     ${name}: its sed no longer changes ${MT_FILES[$i]}"
        RN_BAD=$((RN_BAD + 1))
        continue
    fi

    run_tests "${log}"
    ec=$?
    # cargo prints "---- <test> stdout ----" before each failing test's output
    killers=$(sed -n 's/^---- \([a-z0-9_]*\) stdout ----$/\1/p' "${log}" | sort -u | paste -sd ',' | sed 's/,/, /g')
    if [[ ${ec} -eq 1 ]]; then
        echo "killed    ${name}"
        echo "              by: ${killers}"
    elif [[ ${ec} -eq 2 && ${kind} == missing ]]; then
        echo "killed    ${name}"
        echo "              by: compile error (tests can't build without it)"
    elif [[ ${ec} -eq 0 ]]; then
        echo "SURVIVED  ${name}: no test caught it"
        RN_BAD=$((RN_BAD + 1))
    else
        echo "BROKEN    ${name}: the mutant doesn't build or generate"
        grep -E '^error' "${log}" | head -5 | sed 's/^/              /'
        RN_BAD=$((RN_BAD + 1))
    fi
done

# leave the crate as the real code, for the next run's baseline
copy_repo "${RN_DIR}" "${RN_CRATE}"

echo "${#MT_NAMES[@]} mutants, $((${#MT_NAMES[@]} - RN_BAD)) killed, ${RN_BAD} not"
[[ ${RN_BAD} -eq 0 ]]
