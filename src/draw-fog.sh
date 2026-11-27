#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Light Explored View FogImage FogTexture

cat << EOF

    // the fog over the world: FogImage is FOG_W x FOG_H black pixels, whose
    // alpha is 1 where never explored, and FOG_DIM, less the light, where
    // explored. FogTexture (linear filtering) is stretched over the world, so
    // the cells blend into soft edges.
    for ${v}i in 0..FOG_W * FOG_H {
        let ${v}explored = ${!explored}.get(${v}i).copied().unwrap_or(false);
        let ${v}lit = ${!light}.get(${v}i).copied().unwrap_or(0.0);
        let ${v}alpha = if ${v}explored { FOG_DIM * (1.0 - ${v}lit) } else { 1.0 };
        ${!fog_image}.bytes[${v}i * 4 + 3] = (${v}alpha * 255.0).round() as u8;
    }
    ${!fog_texture}.update(&${!fog_image});
    draw_texture_ex(
        &${!fog_texture},
        -${!view}.x,
        -${!view}.y,
        WHITE,
        DrawTextureParams {
            dest_size: Some(vec2(WORLD_W, WORLD_H)),
            ..Default::default()
        },
    );

EOF
