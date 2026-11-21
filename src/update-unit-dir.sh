#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Unit Sprite DeltaT IdleAnimation RunAnimation

cat << EOF

    if is_mouse_button_pressed(MouseButton::Left) {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        ${!unit}.target = vec2(${v}mouse_x, ${v}mouse_y);
    }

    let ${v}to_target = ${!unit}.target - ${!unit}.pos;
    if ${v}to_target.length() <= ${!unit}.speed * ${!delta_t} {
        // close enough to arrive this frame: snap instead of overshooting
        ${!unit}.pos = ${!unit}.target;
        ${!unit}.dir = Vec2::ZERO;
        ${!sprite}.animation = &${!idle_animation};
    } else {
        ${!unit}.dir = ${v}to_target.normalize();
        ${!sprite}.animation = &${!run_animation};
        if ${!unit}.dir.x < 0.0 {
            ${!unit}.flip = true;
        } else if ${!unit}.dir.x > 0.0 {
            ${!unit}.flip = false;
        }
    }

EOF
