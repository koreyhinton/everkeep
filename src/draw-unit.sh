#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Unit Sprite IdleTexture RunTexture

cat << EOF

    // unit pos is its feet; feet sit at (96, 128) in each 192x192 frame
    let ${v}frame = ${!sprite}.frame();
    let ${v}texture = if ${!sprite}.current_animation() == 0 {
        &${!idle_texture}
    } else {
        &${!run_texture}
    };
    draw_texture_ex(
        ${v}texture,
        ${!unit}.pos.x - 96.0,
        ${!unit}.pos.y - 128.0,
        WHITE,
        DrawTextureParams {
            source: Some(${v}frame.source_rect),
            flip_x: ${!unit}.flip,
            ..Default::default()
        },
    );

EOF
