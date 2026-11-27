#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Minimap View DragStart

cat << EOF

    // holding the left button on the minimap centers the view on the world
    // point under the mouse, so a click jumps there and a drag pans. A box
    // drag (DragStart, begun on the map) that crosses the minimap doesn't.
    let (${v}mouse_x, ${v}mouse_y) = mouse_position();
    let ${v}mouse = vec2(${v}mouse_x, ${v}mouse_y);
    if is_mouse_button_down(MouseButton::Left) && ${!drag_start}.is_none() && ${!minimap}.contains(${v}mouse) {
        let ${v}point = (${v}mouse - ${!minimap}.point()) * (WORLD_W / ${!minimap}.w);
        let ${v}area = vec2(screen_width(), screen_height() - HUD_H);
        ${!view} = (${v}point - ${v}area / 2.0)
            .clamp(Vec2::ZERO, (vec2(WORLD_W, WORLD_H) - ${v}area).max(Vec2::ZERO));
    }

EOF
