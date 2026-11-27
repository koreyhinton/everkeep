#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units Buildings Objectives

cat << EOF

    // A sim step: check each player's objectives. A player finds the rival's
    // main hall when one of their units comes within SIGHT_RANGE of it
    // (measured to the hall's footprint). Units and buildings are Vecs,
    // checked in order, so every player's sim agrees.
    for ${v}player in 0..2usize {
        if ${!objectives}[${v}player] & OBJ_FIND_RIVAL_HALL == 0 {
            let ${v}found = ${!buildings}.iter().any(|building| {
                building.kind == BuildingKind::MainHall
                    && building.owner != ${v}player
                    && ${!units}.iter().any(|unit| {
                        unit.owner == ${v}player && {
                            let near = unit.pos.clamp(
                                building.pos + vec2(building.hitbox.x, building.hitbox.y),
                                building.pos + vec2(building.hitbox.right(), building.hitbox.bottom()),
                            );
                            unit.pos.distance(near) <= SIGHT_RANGE
                        }
                    })
            });
            if ${v}found {
                ${!objectives}[${v}player] |= OBJ_FIND_RIVAL_HALL;
            }
        }
    }

EOF
