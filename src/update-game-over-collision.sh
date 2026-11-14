#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} SquareRect CircRect GameState

cat << EOF

    if ${!circ_rect}.overlaps(&${!square_rect}) {
        ${!game_state} = GameState::CrashFrame;
        break;
    }

EOF
