#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Squares

cat << EOF
    for square in &${!squares} {
        draw_rectangle(
            square.x - square.size / 2.0,
            square.y - square.size / 2.0,
            square.size,
            square.size,
            GREEN
        );
    }
EOF
