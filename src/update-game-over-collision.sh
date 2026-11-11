#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} SquareRect CircRect GameOver

cat << EOF

    if ${!circ_rect}.overlaps(&${!square_rect}) {
        ${!game_over} = true;
        break;
    }

EOF
