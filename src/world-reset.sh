#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} World Players Seed

cat << EOF

    // a new game: START_GOLD each, and one pawn for each of the first
    // Players players (1 offline, 2 online), player 0 near the world's
    // top-left and player 1 near its bottom-right. Spawn points come from
    // Seed (shared by the server online), so every player sees the same
    // layout. SplitMix64: the same on every platform and Rust version.
    ${!world}.units.clear();
    ${!world}.buildings.clear();
    ${!world}.gold = [START_GOLD; 2];
    ${!world}.placing = None;
    ${!world}.drag_start = None;
    ${!world}.outbox.clear();
    ${!world}.next_id = 0;
    let mut ${v}rng: u64 = ${!seed} as u64;
    for ${v}owner in 0..(${!players} as usize).min(2) {
        let mut ${v}offset = [0.0f32; 2];
        for ${v}axis in 0..2 {
            ${v}rng = ${v}rng.wrapping_add(0x9E3779B97F4A7C15);
            let mut ${v}z = ${v}rng;
            ${v}z = (${v}z ^ (${v}z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
            ${v}z = (${v}z ^ (${v}z >> 27)).wrapping_mul(0x94D049BB133111EB);
            ${v}z ^= ${v}z >> 31;
            ${v}offset[${v}axis] = (${v}z % 200) as f32 - 100.0;
        }
        let ${v}base = if ${v}owner == 0 {
            vec2(500.0, 400.0)
        } else {
            vec2(WORLD_W - 500.0, WORLD_H - 400.0)
        };
        let ${v}pos = ${v}base + vec2(${v}offset[0], ${v}offset[1]);
        ${!world}.units.push(Unit {
            id: ${!world}.next_id,
            owner: ${v}owner,
            pos: ${v}pos,
            target: ${v}pos,
            dir: Vec2::ZERO,
            speed: UNIT_SPEED,
            hitbox: UNIT_HITBOX,
            selected: false,
            flip: false,
            running: false,
            frame: Rect::new(0.0, 0.0, 0.0, 0.0),
        });
        ${!world}.next_id += 1;
    }

    // start with this player's pawn in the middle of the map area
    let ${v}mine = ${!world}.units.iter().find(|unit| unit.owner == ${!world}.me).map(|unit| unit.pos);
    let ${v}map = vec2(screen_width(), screen_height() - HUD_H);
    ${!world}.view = (${v}mine.unwrap_or(Vec2::ZERO) - ${v}map / 2.0)
        .clamp(Vec2::ZERO, (vec2(WORLD_W, WORLD_H) - ${v}map).max(Vec2::ZERO));

EOF
