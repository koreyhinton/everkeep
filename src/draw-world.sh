#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units Buildings View HallTextures PawnTextures Tiles TreeTextures Me Light

cat << EOF

    // draw buildings, units and the map's trees back to front (by the y of
    // their feet, or a tree's tile bottom), in screen space. HallTextures is
    // per owner; PawnTextures is per owner, then [idle, run]; TreeTextures
    // are 4 kinds of 8-frame swaying trees, 192 px wide.
    let ${v}building = 0u8;
    let ${v}unit = 1u8;
    let ${v}tree = 2u8;
    let mut ${v}order: Vec<(f32, u8, usize)> = vec![]; // (y, kind, index)
    // under the fog: a rival building once seen, a rival unit only while the
    // fog cell at its feet is at least half lit (Light, from update-fog.sh)
    for (${v}i, ${v}b) in ${!buildings}.iter().enumerate() {
        if ${v}b.owner == ${!me} || ${v}b.seen {
            ${v}order.push((${v}b.pos.y, ${v}building, ${v}i));
        }
    }
    for (${v}i, ${v}u) in ${!units}.iter().enumerate() {
        let ${v}cell = ((${v}u.pos.y / FOG_CELL) as usize).min(FOG_H - 1) * FOG_W
            + ((${v}u.pos.x / FOG_CELL) as usize).min(FOG_W - 1);
        let ${v}in_sight = ${!light}.get(${v}cell).copied().unwrap_or(0.0) >= 0.5;
        if ${v}u.owner == ${!me} || ${v}in_sight {
            ${v}order.push((${v}u.pos.y, ${v}unit, ${v}i));
        }
    }
    // trees near the screen (a tree's picture reaches past its tile on each
    // side, and up to 4 tiles above it); index: row * 4096 + column
    for (${v}row, ${v}line) in ${!tiles}.iter().enumerate() {
        for (${v}col, ${v}tile) in ${v}line.chars().enumerate() {
            let ${v}left = ${v}col as f32 * TILE - ${!view}.x;
            let ${v}bottom = (${v}row + 1) as f32 * TILE - ${!view}.y;
            let ${v}near = ${v}tile == 'T'
                && ${v}left > -2.0 * TILE
                && ${v}left < screen_width() + TILE
                && ${v}bottom > -TILE
                && ${v}bottom < screen_height() + 4.0 * TILE;
            if ${v}near {
                ${v}order.push((${v}bottom + ${!view}.y, ${v}tree, ${v}row * 4096 + ${v}col));
            }
        }
    }
    ${v}order.sort_by(|a, b| a.0.total_cmp(&b.0));
    // trees sway: each is a few frames ahead of its neighbors
    let ${v}sway = (get_time() * 8.0) as usize;
    for (_, ${v}kind, ${v}i) in ${v}order.iter() {
        if *${v}kind == ${v}tree {
            let ${v}col = *${v}i % 4096;
            let ${v}row = *${v}i / 4096;
            let ${v}which = (${v}col * 7 + ${v}row * 3) % 4;
            // Tree1 and Tree2 are 256 px tall, Tree3 and Tree4 192; the trunk
            // stands TREE_BASE px above the picture's bottom
            let ${v}h = if ${v}which < 2 { 256.0 } else { 192.0 };
            let ${v}frame = (${v}sway + ${v}col * 3 + ${v}row * 5) % 8;
            draw_texture_ex(
                &${!tree_textures}[${v}which],
                ${v}col as f32 * TILE + TILE / 2.0 - 96.0 - ${!view}.x,
                (${v}row + 1) as f32 * TILE - ${v}h + TREE_BASE - ${!view}.y,
                WHITE,
                DrawTextureParams {
                    source: Some(Rect::new(${v}frame as f32 * 192.0, 0.0, 192.0, ${v}h)),
                    ..Default::default()
                },
            );
        } else if *${v}kind == ${v}unit {
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
