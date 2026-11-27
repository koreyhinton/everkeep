#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units View Me

cat << EOF

    // follow this player's walking units that are on screen: keep each one
    // SCROLL_MARGIN inside the map area (the screen above the HUD), then keep
    // the view in the world. Units off screen aren't followed, so looking
    // elsewhere (with the minimap) doesn't snap back to them.
    let ${v}map_w = screen_width();
    let ${v}map_h = screen_height() - HUD_H;
    for ${v}unit in ${!units}.iter() {
        let ${v}on_screen = ${v}unit.pos - ${!view};
        let ${v}visible = ${v}on_screen.x >= 0.0
            && ${v}on_screen.x <= ${v}map_w
            && ${v}on_screen.y >= 0.0
            && ${v}on_screen.y <= ${v}map_h;
        if ${v}unit.owner == ${!me} && ${v}unit.running && ${v}visible {
            if ${v}on_screen.x > ${v}map_w - SCROLL_MARGIN {
                ${!view}.x = ${v}unit.pos.x - (${v}map_w - SCROLL_MARGIN);
            }
            if ${v}on_screen.x < SCROLL_MARGIN {
                ${!view}.x = ${v}unit.pos.x - SCROLL_MARGIN;
            }
            if ${v}on_screen.y > ${v}map_h - SCROLL_MARGIN {
                ${!view}.y = ${v}unit.pos.y - (${v}map_h - SCROLL_MARGIN);
            }
            if ${v}on_screen.y < SCROLL_MARGIN {
                ${!view}.y = ${v}unit.pos.y - SCROLL_MARGIN;
            }
        }
    }
    ${!view}.x = ${!view}.x.clamp(0.0, (WORLD_W - ${v}map_w).max(0.0));
    ${!view}.y = ${!view}.y.clamp(0.0, (WORLD_H - ${v}map_h).max(0.0));

EOF
