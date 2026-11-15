#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} House HouseTexture

cat << EOF

    // house pos is its bottom-center; the texture is 128x192
    draw_texture(
        &${!house_texture},
        ${!house}.pos.x - 64.0,
        ${!house}.pos.y - 192.0,
        WHITE,
    );

EOF
