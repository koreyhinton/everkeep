#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Ui Houses Expl Unit Score GameState

cat << EOF

    ${!ui}.label(vec2(105.0, 20.0), "Main Menu");
    if ${!ui}.button(vec2(130.0, 90.0), "Play") {
        ${!houses}.clear();
        ${!expl}.clear();
        ${!unit}.pos = vec2(screen_width() / 2.0, screen_height() / 2.0);
        ${!unit}.target = ${!unit}.pos;
        ${!score} = 0;
        ${!game_state} = GameState::Playing;
    }
    #[cfg(not(target_arch = "wasm32"))]
    if ${!ui}.button(vec2(130.0, 190.0), "Quit") {
        std::process::exit(0);
    }

EOF
