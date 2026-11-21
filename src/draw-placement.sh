#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Placing HallTexture

cat << EOF

    // while placing, a see-through hall follows the mouse, where a click
    // would build it (the mouse is the hall's bottom-center)
    if ${!placing}.is_some() {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        draw_texture(
            &${!hall_texture},
            ${v}mouse_x + HALL_TEXTURE_OFFSET.x,
            ${v}mouse_y + HALL_TEXTURE_OFFSET.y,
            Color::new(1.0, 1.0, 1.0, 0.5),
        );
    }

EOF
