#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} BuildButton TrainButton

cat << EOF

    // the HUD's buttons, stacked in its bottom-right corner (update-hud.sh
    // clicks them and draw-hud.sh draws them, from these same rects)
    let ${!build_button} = Rect::new(screen_width() - 230.0, screen_height() - 54.0, 220.0, 44.0);
    let ${!train_button} = Rect::new(screen_width() - 230.0, screen_height() - 108.0, 220.0, 44.0);

EOF
