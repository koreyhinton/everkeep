#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Unit Sprite

cat << EOF

    // after animate-sprite: the unit draws its sprite's current frame
    if let Some(${v}paint) = ${!sprite}.paint_frame.as_ref() {
        ${!unit}.frame = Rect::new(${v}paint.x, ${v}paint.y, ${v}paint.w, ${v}paint.h);
    }

EOF
