#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} BuildButton TrainButton Minimap

cat << EOF

    // the HUD's buttons, stacked in its bottom-right corner (update-hud.sh
    // clicks them and draw-hud.sh draws them, from these same rects)
    let ${!build_button} = Rect::new(screen_width() - 230.0, screen_height() - 54.0, 220.0, 44.0);
    let ${!train_button} = Rect::new(screen_width() - 230.0, screen_height() - 108.0, 220.0, 44.0);
    // the minimap: the whole world, scaled to fit the HUD's height, in its
    // bottom-left (draw-minimap.sh draws it; update-orders.sh and
    // update-minimap-view.sh take clicks on it)
    let ${!minimap} = Rect::new(
        8.0,
        screen_height() - HUD_H + 8.0,
        WORLD_W * (HUD_H - 16.0) / WORLD_H,
        HUD_H - 16.0,
    );

EOF
