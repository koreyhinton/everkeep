#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Commands Player Units Buildings Gold NextId

cat << EOF

    // Apply one player's commands to the sim. Every player runs this with the
    // same commands in the same order, so it may only depend on them and on
    // the sim state. Commands come from the network: positions are clamped,
    // and a player can only order their own units and buildings, with their
    // own gold.
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
                let ${v}blocked = ${!buildings}.iter().any(|building| {
                    Rect::new(
                        building.pos.x + building.hitbox.x,
                        building.pos.y + building.hitbox.y,
                        building.hitbox.w,
                        building.hitbox.h,
                    )
                    .overlaps(&${v}rect)
                });
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
                }
            }
            Command::TrainPawn { hall: ${v}hall } => {
                // the pawn steps out just in front of the hall, spread a little
                // so pawns trained one after another don't stack
                let ${v}spawn = ${!buildings}
                    .iter()
                    .find(|building| building.id == *${v}hall && building.owner == ${!player})
                    .map(|building| building.pos + vec2(((${!next_id} % 5) as f32 - 2.0) * 40.0, 48.0));
                if let Some(${v}pos) = ${v}spawn {
                    if ${!gold}[${!player}] >= PAWN_COST {
                        ${!gold}[${!player}] -= PAWN_COST;
                        let ${v}pos = ${v}pos.clamp(Vec2::ZERO, vec2(WORLD_W, WORLD_H));
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
                        }
                    }
                }
            }
        }
    }

EOF
