#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} World Map Players Seed

cat << EOF

    // a new game: START_GOLD each, and one pawn for each of the first
    // Players players (1 offline, 2 online). Seed (shared by the server
    // online) shuffles the Map's spawn spots, so every player sees the same
    // layout: player 0 starts at the first spot, player 1 at the second,
    // each spread up to 100 px. SplitMix64: the same on every platform and
    // Rust version. Offline there's no rival, so an idle red hall stands at
    // player 1's spot, for the first objective (find the rival's main hall).
    ${!world}.units.clear();
    ${!world}.buildings.clear();
    ${!world}.gold = [START_GOLD; 2];
    ${!world}.placing = None;
    ${!world}.drag_start = None;
    ${!world}.outbox.clear();
    ${!world}.next_id = 0;
    ${!world}.objectives = [0; 2];
    let mut ${v}rng: u64 = ${!seed} as u64;

    // shuffle the spawn spots (Fisher-Yates)
    let mut ${v}spots: Vec<usize> = (0..${!map}.spawns.len()).collect();
    for ${v}i in (1..${v}spots.len()).rev() {
        ${v}rng = ${v}rng.wrapping_add(0x9E3779B97F4A7C15);
        let mut ${v}z = ${v}rng;
        ${v}z = (${v}z ^ (${v}z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        ${v}z = (${v}z ^ (${v}z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ${v}z ^= ${v}z >> 31;
        ${v}spots.swap(${v}i, (${v}z % (${v}i as u64 + 1)) as usize);
    }

    for ${v}owner in 0..2usize {
        // whole pixels, like a placed hall
        let mut ${v}offset = [0.0f32; 2];
        for ${v}axis in 0..2 {
            ${v}rng = ${v}rng.wrapping_add(0x9E3779B97F4A7C15);
            let mut ${v}z = ${v}rng;
            ${v}z = (${v}z ^ (${v}z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
            ${v}z = (${v}z ^ (${v}z >> 27)).wrapping_mul(0x94D049BB133111EB);
            ${v}z ^= ${v}z >> 31;
            ${v}offset[${v}axis] = (${v}z % 200) as f32 - 100.0;
        }
        let ${v}pos = ${!map}.spawns[${v}spots[${v}owner]] + vec2(${v}offset[0], ${v}offset[1]);
        let ${v}playing = ${v}owner < ${!players} as usize;
        if ${v}playing {
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
        } else {
            ${!world}.buildings.push(Building {
                id: ${!world}.next_id,
                owner: ${v}owner,
                kind: BuildingKind::MainHall,
                pos: ${v}pos,
                hitbox: HALL_HITBOX,
                selected: false,
            });
        }
        ${!world}.next_id += 1;
    }

    // start with this player's pawn in the middle of the map area
    let ${v}mine = ${!world}.units.iter().find(|unit| unit.owner == ${!world}.me).map(|unit| unit.pos);
    let ${v}area = vec2(screen_width(), screen_height() - HUD_H);
    ${!world}.view = (${v}mine.unwrap_or(Vec2::ZERO) - ${v}area / 2.0)
        .clamp(Vec2::ZERO, (vec2(WORLD_W, WORLD_H) - ${v}area).max(Vec2::ZERO));

EOF
