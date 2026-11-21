#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units DeltaT

cat << EOF

    // walk each unit toward its target
    for ${v}unit in ${!units}.iter_mut() {
        let ${v}to_target = ${v}unit.target - ${v}unit.pos;
        if ${v}to_target.length() <= ${v}unit.speed * ${!delta_t} {
            // close enough to arrive this step: snap instead of overshooting
            ${v}unit.pos = ${v}unit.target;
            ${v}unit.dir = Vec2::ZERO;
            ${v}unit.running = false;
        } else {
            ${v}unit.dir = ${v}to_target.normalize();
            ${v}unit.pos += ${v}unit.dir * (${v}unit.speed * ${!delta_t});
            ${v}unit.running = true;
            if ${v}unit.dir.x < 0.0 {
                ${v}unit.flip = true;
            } else if ${v}unit.dir.x > 0.0 {
                ${v}unit.flip = false;
            }
        }
    }

EOF
