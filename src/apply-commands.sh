#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Commands Player Units Buildings Gold NextId Grid

cat << EOF

    // Apply one player's commands to the sim. Every player runs this with the
    // same commands in the same order, so it may only depend on them and on
    // the sim state. Commands come from the network: positions are clamped,
    // and a player can only order their own units and buildings, with their
    // own gold. Grid is the pathfinding grid: a hall blocks the cells under
    // its footprint, and a Move (or a new hall in the way) marks units to get
    // a new path (main.sh finds paths after the commands).
    for ${v}cmd in ${!commands}.iter() {
        match ${v}cmd {
            Command::PlaceHall { x: ${v}x, y: ${v}y } => {
                let ${v}pos = vec2(
                    (*${v}x).clamp(0, WORLD_W as i32) as f32,
                    (*${v}y).clamp(0, WORLD_H as i32) as f32,
                );
                let ${v}rect = Rect::new(
                    ${v}pos.x + HALL_HITBOX.x,
                    ${v}pos.y + HALL_HITBOX.y,
                    HALL_HITBOX.w,
                    HALL_HITBOX.h,
                );
                let ${v}on_building = ${!buildings}.iter().any(|building| {
                    Rect::new(
                        building.pos.x + building.hitbox.x,
                        building.pos.y + building.hitbox.y,
                        building.hitbox.w,
                        building.hitbox.h,
                    )
                    .overlaps(&${v}rect)
                });
                // the footprint's cells: all in the world, none blocked (by a
                // tree or another hall), and no unit standing in one
                let ${v}in_world = ${v}rect.x >= 0.0
                    && ${v}rect.y >= 0.0
                    && ${v}rect.right() <= WORLD_W
                    && ${v}rect.bottom() <= WORLD_H;
                let ${v}x0 = (${v}rect.x / CELL).floor().max(0.0) as usize;
                let ${v}y0 = (${v}rect.y / CELL).floor().max(0.0) as usize;
                let ${v}x1 = ((${v}rect.right() / CELL).ceil().max(0.0) as usize).min(${!grid}.w);
                let ${v}y1 = ((${v}rect.bottom() / CELL).ceil().max(0.0) as usize).min(${!grid}.h);
                let mut ${v}on_trees = false;
                for ${v}cy in ${v}y0..${v}y1 {
                    for ${v}cx in ${v}x0..${v}x1 {
                        ${v}on_trees = ${v}on_trees || ${!grid}.blocked[${v}cy * ${!grid}.w + ${v}cx];
                    }
                }
                let ${v}on_unit = ${!units}.iter().any(|unit| {
                    let cx = (unit.pos.x / CELL).floor();
                    let cy = (unit.pos.y / CELL).floor();
                    cx >= ${v}x0 as f32 && cx < ${v}x1 as f32 && cy >= ${v}y0 as f32 && cy < ${v}y1 as f32
                });
                let ${v}blocked = ${v}on_building || !${v}in_world || ${v}on_trees || ${v}on_unit;
                if !${v}blocked && ${!gold}[${!player}] >= HALL_COST {
                    ${!gold}[${!player}] -= HALL_COST;
                    ${!buildings}.push(Building {
                        id: ${!next_id},
                        owner: ${!player},
                        kind: BuildingKind::MainHall,
                        pos: ${v}pos,
                        hitbox: HALL_HITBOX,
                        selected: false,
                    });
                    ${!next_id} += 1;
                    for ${v}cy in ${v}y0..${v}y1 {
                        for ${v}cx in ${v}x0..${v}x1 {
                            ${!grid}.blocked[${v}cy * ${!grid}.w + ${v}cx] = true;
                        }
                    }
                    // walking units may have a path through it now
                    for ${v}unit in ${!units}.iter_mut() {
                        if ${v}unit.pos != ${v}unit.target {
                            ${v}unit.repath = true;
                        }
                    }
                }
            }
            Command::TrainPawn { hall: ${v}hall } => {
                // the pawn steps out just in front of the hall, spread a little
                // so pawns trained one after another don't stack
                let ${v}spawn = ${!buildings}
                    .iter()
                    .find(|building| building.id == *${v}hall && building.owner == ${!player})
                    .map(|building| building.pos + vec2(((${!next_id} % 5) as f32 - 2.0) * 40.0, 48.0));
                // on the nearest open cell to that spot (by distance, then
                // index), never under a hall or in the trees: the spot
                // itself if its cell is open, else that cell's center
                let mut ${v}spot: Option<Vec2> = None;
                if let Some(${v}want) = ${v}spawn {
                    let ${v}want = ${v}want.clamp(Vec2::ZERO, vec2(WORLD_W - 1.0, WORLD_H - 1.0));
                    let ${v}want_x = ((${v}want.x / CELL) as usize).min(${!grid}.w.saturating_sub(1));
                    let ${v}want_y = ((${v}want.y / CELL) as usize).min(${!grid}.h.saturating_sub(1));
                    let mut ${v}best = (usize::MAX, usize::MAX);
                    for ${v}cy in ${v}want_y.saturating_sub(8)..(${v}want_y + 9).min(${!grid}.h) {
                        for ${v}cx in ${v}want_x.saturating_sub(8)..(${v}want_x + 9).min(${!grid}.w) {
                            let ${v}i = ${v}cy * ${!grid}.w + ${v}cx;
                            let ${v}d = ${v}cx.abs_diff(${v}want_x).pow(2) + ${v}cy.abs_diff(${v}want_y).pow(2);
                            if !${!grid}.blocked[${v}i] && (${v}d, ${v}i) < ${v}best {
                                ${v}best = (${v}d, ${v}i);
                                ${v}spot = Some(if ${v}d == 0 {
                                    ${v}want
                                } else {
                                    vec2((${v}cx as f32 + 0.5) * CELL, (${v}cy as f32 + 0.5) * CELL)
                                });
                            }
                        }
                    }
                }
                if let Some(${v}pos) = ${v}spot {
                    if ${!gold}[${!player}] >= PAWN_COST {
                        ${!gold}[${!player}] -= PAWN_COST;
                        ${!units}.push(Unit {
                            id: ${!next_id},
                            owner: ${!player},
                            pos: ${v}pos,
                            target: ${v}pos,
                            dir: Vec2::ZERO,
                            speed: UNIT_SPEED,
                            hitbox: UNIT_HITBOX,
                            selected: false,
                            flip: false,
                            running: false,
                            frame: Rect::new(0.0, 0.0, 0.0, 0.0),
                            path: vec![],
                            repath: false,
                        });
                        ${!next_id} += 1;
                    }
                }
            }
            Command::Move { units: ${v}ids, x: ${v}x, y: ${v}y } => {
                let ${v}at = vec2(
                    (*${v}x).clamp(0, WORLD_W as i32) as f32,
                    (*${v}y).clamp(0, WORLD_H as i32) as f32,
                );
                // a group spreads into a 3-wide grid around the point
                let ${v}count = ${v}ids.len().min(${!units}.len());
                for (${v}i, ${v}id) in ${v}ids[..${v}count].iter().enumerate() {
                    let ${v}offset = vec2(
                        ((${v}i % 3) as f32 - 1.0) * MOVE_SPACING,
                        (${v}i / 3) as f32 * MOVE_SPACING,
                    );
                    let ${v}target = (${v}at + ${v}offset).clamp(Vec2::ZERO, vec2(WORLD_W, WORLD_H));
                    for ${v}unit in ${!units}.iter_mut() {
                        if ${v}unit.id == *${v}id && ${v}unit.owner == ${!player} {
                            ${v}unit.target = ${v}target;
                            ${v}unit.path.clear();
                            ${v}unit.repath = true;
                        }
                    }
                }
            }
        }
    }

EOF
