#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Squares EnemyFrame

cat << EOF
    
    for square in &${!squares} {
        draw_texture_ex(
            &enemy_small_texture,
            square.x - square.size / 2.0,
            square.y - square.size / 2.0,
            WHITE,
            DrawTextureParams {
                dest_size: Some(vec2(square.size, square.size)),
                source: Some(${!enemy_frame}.source_rect),
                ..Default::default()
            },
        );
    }
EOF
