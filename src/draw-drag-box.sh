#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} DragStart

cat << EOF

    // the in-progress drag box, from the drag start to the mouse
    if let Some(${v}start) = ${!drag_start} {
        if is_mouse_button_down(MouseButton::Left) {
            let (${v}end_x, ${v}end_y) = mouse_position();
            let ${v}x = ${v}start.x.min(${v}end_x);
            let ${v}y = ${v}start.y.min(${v}end_y);
            let ${v}w = (${v}end_x - ${v}start.x).abs();
            let ${v}h = (${v}end_y - ${v}start.y).abs();
            draw_rectangle(${v}x, ${v}y, ${v}w, ${v}h, Color::new(1.0, 1.0, 1.0, 0.15));
            draw_rectangle_lines(${v}x, ${v}y, ${v}w, ${v}h, 1.0, WHITE);
        }
    }

EOF
