#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} GrassTexture

cat << EOF

    // tile the plain grass tile (center of the tilemap's top-left 3x3 block)
    let ${v}tile = 64.0;
    let mut ${v}y = 0.0;
    while ${v}y < screen_height() {
        let mut ${v}x = 0.0;
        while ${v}x < screen_width() {
            draw_texture_ex(
                &${!grass_texture},
                ${v}x,
                ${v}y,
                WHITE,
                DrawTextureParams {
                    source: Some(Rect::new(${v}tile, ${v}tile, ${v}tile, ${v}tile)),
                    ..Default::default()
                },
            );
            ${v}x += ${v}tile;
        }
        ${v}y += ${v}tile;
    }

EOF
