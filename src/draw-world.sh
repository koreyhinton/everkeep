#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units Buildings View HallTextures PawnTextures

cat << EOF

    // draw buildings and units back to front (by the y of their feet), in
    // screen space. HallTextures is per owner; PawnTextures is per owner,
    // then [idle, run].
    let mut ${v}order: Vec<(f32, bool, usize)> = vec![]; // (y, is a unit, index)
    for (${v}i, ${v}building) in ${!buildings}.iter().enumerate() {
        ${v}order.push((${v}building.pos.y, false, ${v}i));
    }
    for (${v}i, ${v}unit) in ${!units}.iter().enumerate() {
        ${v}order.push((${v}unit.pos.y, true, ${v}i));
    }
    ${v}order.sort_by(|a, b| a.0.total_cmp(&b.0));
    for (_, ${v}is_unit, ${v}i) in ${v}order.iter() {
        if *${v}is_unit {
            let ${v}unit = &${!units}[*${v}i];
            // feet sit at (96, 128) in each 192x192 frame. No frame until
            // the unit's sprite has animated once, so skip it until then.
            if ${v}unit.frame.w > 0.0 {
                draw_texture_ex(
                    &${!pawn_textures}[${v}unit.owner.min(1)][${v}unit.running as usize],
                    ${v}unit.pos.x - 96.0 - ${!view}.x,
                    ${v}unit.pos.y - 128.0 - ${!view}.y,
                    WHITE,
                    DrawTextureParams {
                        source: Some(${v}unit.frame),
                        flip_x: ${v}unit.flip,
                        ..Default::default()
                    },
                );
            }
        } else {
            let ${v}building = &${!buildings}[*${v}i];
            draw_texture(
                &${!hall_textures}[${v}building.owner.min(1)],
                ${v}building.pos.x + HALL_TEXTURE_OFFSET.x - ${!view}.x,
                ${v}building.pos.y + HALL_TEXTURE_OFFSET.y - ${!view}.y,
                WHITE,
            );
        }
    }

    // a white rectangle around each selected hitbox, padded a little
    let ${v}pad = 4.0;
    for ${v}unit in ${!units}.iter().filter(|unit| unit.selected) {
        draw_rectangle_lines(
            ${v}unit.pos.x + ${v}unit.hitbox.x - ${v}pad - ${!view}.x,
            ${v}unit.pos.y + ${v}unit.hitbox.y - ${v}pad - ${!view}.y,
            ${v}unit.hitbox.w + 2.0 * ${v}pad,
            ${v}unit.hitbox.h + 2.0 * ${v}pad,
            2.0,
            WHITE,
        );
    }
    for ${v}building in ${!buildings}.iter().filter(|building| building.selected) {
        draw_rectangle_lines(
            ${v}building.pos.x + ${v}building.hitbox.x - ${v}pad - ${!view}.x,
            ${v}building.pos.y + ${v}building.hitbox.y - ${v}pad - ${!view}.y,
            ${v}building.hitbox.w + 2.0 * ${v}pad,
            ${v}building.hitbox.h + 2.0 * ${v}pad,
            2.0,
            WHITE,
        );
    }

EOF
