#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Squares Circ GameOver

cat << EOF

    let ${v}CircRect = Rect {
        x: ${!circ}.x - ${!circ}.size / 2.0,
        y: ${!circ}.y - ${!circ}.size / 2.0,
        w: ${!circ}.size,
        h: ${!circ}.size,
    };

    for sq in &${!squares} {

        let sq_rect = Rect {
            x: sq.x - sq.size / 2.0,
            y: sq.y - sq.size / 2.0,
            w: sq.size,
            h: sq.size,
        };

        if ${v}CircRect.overlaps(&sq_rect) {
            ${!game_over} = true;
            break;
        }
    }
EOF
