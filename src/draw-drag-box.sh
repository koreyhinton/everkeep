#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} DragStart

cat << EOF

    // the in-progress drag box, from the drag start to the mouse
    if let Some(${v}start) = ${!drag_start} {
        if is_mouse_button_down(MouseButton::Left) {
            let (${v}end_x, ${v}end_y) = mouse_position();
            // on whole pixels, with a 1-pixel outline (thickness 2.0: macroquad
            // draws each side thickness / 2 inside the rect, and a thinner
            // or fractional side can fall between pixel centers and not show)
            let ${v}x = ${v}start.x.min(${v}end_x).round();
            let ${v}y = ${v}start.y.min(${v}end_y).round();
            let ${v}w = ${v}start.x.max(${v}end_x).round() - ${v}x;
            let ${v}h = ${v}start.y.max(${v}end_y).round() - ${v}y;
            draw_rectangle(${v}x, ${v}y, ${v}w, ${v}h, Color::new(1.0, 1.0, 1.0, 0.15));
            draw_rectangle_lines(${v}x, ${v}y, ${v}w, ${v}h, 2.0, WHITE);
        }
    }

EOF
