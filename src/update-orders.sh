#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units View Outbox Me Minimap

cat << EOF

    // a right press on the map, or on the minimap, orders this player's
    // selected units there (on the minimap, to the world point it shows)
    if is_mouse_button_pressed(MouseButton::Right) {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        let ${v}mouse = vec2(${v}mouse_x, ${v}mouse_y);
        let ${v}on_map = ${v}mouse_y < screen_height() - HUD_H;
        let ${v}on_minimap = ${!minimap}.contains(${v}mouse);
        let ${v}at = if ${v}on_minimap {
            (${v}mouse - ${!minimap}.point()) * (WORLD_W / ${!minimap}.w)
        } else {
            ${v}mouse + ${!view}
        };
        let ${v}ids: Vec<u32> = ${!units}
            .iter()
            .filter(|unit| unit.selected && unit.owner == ${!me})
            .map(|unit| unit.id)
            .collect();
        if !${v}ids.is_empty() && (${v}on_map || ${v}on_minimap) {
            ${!outbox}.push(Command::Move {
                units: ${v}ids,
                x: ${v}at.x.round() as i32,
                y: ${v}at.y.round() as i32,
            });
        }
    }

EOF
