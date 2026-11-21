#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Ui GameState Server JoinSent

cat << EOF

    ${!ui}.label(vec2(105.0, 20.0), "Main Menu");
    if ${!ui}.button(vec2(130.0, 90.0), "Play") {
        ${!game_state} = GameState::Starting;
    }
    // Multiplayer needs a lockstep server: --server URL on desktop, or the
    // page's server in the browser
    if ${!server}.is_some() && ${!ui}.button(vec2(40.0, 175.0), "Multiplayer") {
        ${!join_sent} = false;
        ${!game_state} = GameState::Joining;
    }
    #[cfg(not(target_arch = "wasm32"))]
    if ${!ui}.button(vec2(130.0, 260.0), "Quit") {
        std::process::exit(0);
    }

EOF
