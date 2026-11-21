#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Placing Outbox View

cat << EOF

    // while placing, a left press on the map orders the hall built at the
    // mouse; a right press cancels. A press on the HUD (such as the click on
    // "Build Main Hall" that started placing) doesn't place.
    if ${!placing}.is_some() {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        let ${v}on_map = ${v}mouse_y < screen_height() - HUD_H;
        if is_mouse_button_pressed(MouseButton::Left) && ${v}on_map {
            ${!outbox}.push(Command::PlaceHall {
                x: (${v}mouse_x + ${!view}.x).round() as i32,
                y: (${v}mouse_y + ${!view}.y).round() as i32,
            });
            ${!placing} = None;
        }
        if is_mouse_button_pressed(MouseButton::Right) {
            ${!placing} = None;
        }
    }

EOF
