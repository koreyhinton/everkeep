#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Buildings Gold Placing Outbox Me BuildButton TrainButton

cat << EOF

    // HUD buttons act on a left press. "Train Pawn" is only there while one
    // of this player's halls is selected.
    let ${v}hall = ${!buildings}
        .iter()
        .find(|building| building.selected && building.owner == ${!me} && building.kind == BuildingKind::MainHall)
        .map(|building| building.id);
    if is_mouse_button_pressed(MouseButton::Left) {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        let ${v}mouse = vec2(${v}mouse_x, ${v}mouse_y);
        if ${!build_button}.contains(${v}mouse) && ${!gold} >= HALL_COST {
            ${!placing} = Some(BuildingKind::MainHall);
        }
        if let Some(${v}hall_id) = ${v}hall {
            if ${!train_button}.contains(${v}mouse) {
                ${!outbox}.push(Command::TrainPawn { hall: ${v}hall_id });
            }
        }
    }

EOF
