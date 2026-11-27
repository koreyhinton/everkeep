#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units Buildings Objectives

cat << EOF

    // A sim step: check each player's objectives. A player finds the rival's
    // main hall when it comes into their sight: within SIGHT_RANGE of one of
    // their units (from its feet) or buildings (from its footprint), measured
    // to the hall's footprint, as update-fog.sh draws it. Units and buildings
    // are Vecs, checked in order, so every player's sim agrees.
    for ${v}player in 0..2usize {
        if ${!objectives}[${v}player] & OBJ_FIND_RIVAL_HALL == 0 {
            let mut ${v}eyes: Vec<Rect> = vec![];
            for ${v}unit in ${!units}.iter() {
                if ${v}unit.owner == ${v}player {
                    ${v}eyes.push(Rect::new(${v}unit.pos.x, ${v}unit.pos.y, 0.0, 0.0));
                }
            }
            for ${v}building in ${!buildings}.iter() {
                if ${v}building.owner == ${v}player {
                    ${v}eyes.push(Rect::new(
                        ${v}building.pos.x + ${v}building.hitbox.x,
                        ${v}building.pos.y + ${v}building.hitbox.y,
                        ${v}building.hitbox.w,
                        ${v}building.hitbox.h,
                    ));
                }
            }
            let ${v}found = ${!buildings}.iter().any(|building| {
                let rect = Rect::new(
                    building.pos.x + building.hitbox.x,
                    building.pos.y + building.hitbox.y,
                    building.hitbox.w,
                    building.hitbox.h,
                );
                building.kind == BuildingKind::MainHall
                    && building.owner != ${v}player
                    && ${v}eyes.iter().any(|eye| {
                        // the gap between the rects, 0 if they touch
                        let dx = (eye.x - rect.right()).max(rect.x - eye.right()).max(0.0);
                        let dy = (eye.y - rect.bottom()).max(rect.y - eye.bottom()).max(0.0);
                        vec2(dx, dy).length() <= SIGHT_RANGE
                    })
            });
            if ${v}found {
                ${!objectives}[${v}player] |= OBJ_FIND_RIVAL_HALL;
            }
        }
    }

EOF
