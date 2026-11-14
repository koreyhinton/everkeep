#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Ui Sq Bull Expl Circ Score GameState

cat << EOF

    ${!ui}.label(vec2(80.0, -34.0), "Main Menu");
    if ${!ui}.button(vec2(65.0, 25.0), "Play") {
        ${!sq}.clear();
        ${!bull}.clear();
        ${!expl}.clear();
        ${!circ}.x = screen_width() / 2.0;
        ${!circ}.y = screen_height() / 2.0;
        ${!score} = 0;
        ${!game_state} = GameState::Playing;
    }
    #[cfg(not(target_arch = "wasm32"))]
    if ${!ui}.button(vec2(65.0, 125.0), "Quit") {
        std::process::exit(0);
    }

EOF
