#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Unit Houses

cat << EOF

    // a white rectangle around each selected hitbox, padded a little
    let ${v}pad = 4.0;
    if ${!unit}.selected {
        draw_rectangle_lines(
            ${!unit}.pos.x + ${!unit}.hitbox.x - ${v}pad,
            ${!unit}.pos.y + ${!unit}.hitbox.y - ${v}pad,
            ${!unit}.hitbox.w + 2.0 * ${v}pad,
            ${!unit}.hitbox.h + 2.0 * ${v}pad,
            2.0,
            WHITE,
        );
    }
    for ${v}house in ${!houses}.iter() {
        if ${v}house.selected {
            draw_rectangle_lines(
                ${v}house.pos.x + ${v}house.hitbox.x - ${v}pad,
                ${v}house.pos.y + ${v}house.hitbox.y - ${v}pad,
                ${v}house.hitbox.w + 2.0 * ${v}pad,
                ${v}house.hitbox.h + 2.0 * ${v}pad,
                2.0,
                WHITE,
            );
        }
    }

EOF
