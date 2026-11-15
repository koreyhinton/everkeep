#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Pos Hitbox

cat << EOF

    let ${v}Rect = Rect::new(
        ${!pos}.x + ${!hitbox}.x,
        ${!pos}.y + ${!hitbox}.y,
        ${!hitbox}.w,
        ${!hitbox}.h,
    );

EOF
