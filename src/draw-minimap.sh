#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units Buildings View Minimap Tiles

cat << EOF

    // the whole world, scaled down into the HUD's bottom-left: buildings,
    // units (blue for player 0, red for player 1) and the view's outline
    let ${v}map = ${!minimap};
    let ${v}scale = ${v}map.w / WORLD_W;
    let ${v}colors = [Color::from_rgba(80, 140, 255, 255), Color::from_rgba(255, 90, 80, 255)];
    draw_rectangle(${v}map.x, ${v}map.y, ${v}map.w, ${v}map.h, Color::from_rgba(70, 110, 60, 255));
    // trees, as darker green tiles (clipped to the world)
    for (${v}row, ${v}line) in ${!tiles}.iter().enumerate() {
        for (${v}col, ${v}tile) in ${v}line.chars().enumerate() {
            let ${v}x = ${v}col as f32 * TILE;
            let ${v}y = ${v}row as f32 * TILE;
            if ${v}tile == 'T' && ${v}x < WORLD_W && ${v}y < WORLD_H {
                draw_rectangle(
                    ${v}map.x + ${v}x * ${v}scale,
                    ${v}map.y + ${v}y * ${v}scale,
                    TILE.min(WORLD_W - ${v}x) * ${v}scale,
                    TILE.min(WORLD_H - ${v}y) * ${v}scale,
                    Color::from_rgba(35, 70, 40, 255),
                );
            }
        }
    }
    for ${v}building in ${!buildings}.iter() {
        draw_rectangle(
            ${v}map.x + ${v}building.pos.x * ${v}scale - 3.0,
            ${v}map.y + ${v}building.pos.y * ${v}scale - 3.0,
            6.0,
            6.0,
            ${v}colors[${v}building.owner.min(1)],
        );
    }
    for ${v}unit in ${!units}.iter() {
        draw_circle(
            ${v}map.x + ${v}unit.pos.x * ${v}scale,
            ${v}map.y + ${v}unit.pos.y * ${v}scale,
            1.5,
            ${v}colors[${v}unit.owner.min(1)],
        );
    }
    // the view's outline, on whole pixels: draw_rectangle_lines draws each
    // side thickness / 2 inside the rect, so a thinner or fractional side can
    // fall between pixel centers and not show. Each edge is rounded on its
    // own so the box doesn't jitter as the view scrolls.
    let ${v}view_x = (${v}map.x + ${!view}.x * ${v}scale).round();
    let ${v}view_y = (${v}map.y + ${!view}.y * ${v}scale).round();
    let ${v}view_right = (${v}map.x + (${!view}.x + screen_width()) * ${v}scale).round();
    let ${v}view_bottom = (${v}map.y + (${!view}.y + screen_height() - HUD_H) * ${v}scale).round();
    draw_rectangle_lines(
        ${v}view_x,
        ${v}view_y,
        ${v}view_right - ${v}view_x,
        ${v}view_bottom - ${v}view_y,
        2.0,
        WHITE,
    );

EOF
