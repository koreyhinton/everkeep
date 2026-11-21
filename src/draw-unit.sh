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
    draw_texture_ex(
        ${v}texture,
        ${!unit}.pos.x - 96.0,
        ${!unit}.pos.y - 128.0,
        WHITE,
        DrawTextureParams {
            source: Some(Rect::new(
                // todo: instead use the get or zero method used in animate-sprite and just do that once and access the values directly:
                ${!sprite}.paint_frame.as_ref().unwrap().x,
                ${!sprite}.paint_frame.as_ref().unwrap().y,
                ${!sprite}.paint_frame.as_ref().unwrap().w,
                ${!sprite}.paint_frame.as_ref().unwrap().h,
            )),
            flip_x: ${!unit}.flip,
            ..Default::default()
        },
    );

EOF
