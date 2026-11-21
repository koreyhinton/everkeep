#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Unit Sprite IdleTexture RunTexture

cat << EOF

    // unit pos is its feet; feet sit at (96, 128) in each 192x192 frame
    let ${v}texture = if ${!sprite}.animation.id == "idle" {
        &${!idle_texture}
    } else {
        &${!run_texture}
    };
    // no paint frame until animate-sprite's first update (starting a game
    // with Space draws before it), so skip the unit for that frame
    if let Some(${v}paint) = ${!sprite}.paint_frame.as_ref() {
        draw_texture_ex(
            ${v}texture,
            ${!unit}.pos.x - 96.0,
            ${!unit}.pos.y - 128.0,
            WHITE,
            DrawTextureParams {
                source: Some(Rect::new(${v}paint.x, ${v}paint.y, ${v}paint.w, ${v}paint.h)),
                flip_x: ${!unit}.flip,
                ..Default::default()
            },
        );
    }

EOF
