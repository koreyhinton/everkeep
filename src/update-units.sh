#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units DeltaT

cat << EOF

    // walk each unit through its path's waypoints, then to its target
    for ${v}unit in ${!units}.iter_mut() {
        let ${v}next = ${v}unit.path.first().copied().unwrap_or(${v}unit.target);
        let ${v}to_next = ${v}next - ${v}unit.pos;
        if ${v}to_next.length() <= ${v}unit.speed * ${!delta_t} {
            // close enough to arrive this step: snap instead of overshooting,
            // and head for the next waypoint, if any
            ${v}unit.pos = ${v}next;
            let ${v}waypoint = !${v}unit.path.is_empty();
            if ${v}waypoint {
                ${v}unit.path.remove(0);
            } else {
                ${v}unit.dir = Vec2::ZERO;
            }
            ${v}unit.running = ${v}waypoint;
        } else {
            ${v}unit.dir = ${v}to_next.normalize();
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
