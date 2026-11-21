#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units View Outbox Me

cat << EOF

    // a right press on the map orders this player's selected units there
    if is_mouse_button_pressed(MouseButton::Right) {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        let ${v}ids: Vec<u32> = ${!units}
            .iter()
            .filter(|unit| unit.selected && unit.owner == ${!me})
            .map(|unit| unit.id)
            .collect();
        if !${v}ids.is_empty() && ${v}mouse_y < screen_height() - HUD_H {
            ${!outbox}.push(Command::Move {
                units: ${v}ids,
                x: (${v}mouse_x + ${!view}.x).round() as i32,
                y: (${v}mouse_y + ${!view}.y).round() as i32,
            });
        }
    }

EOF
