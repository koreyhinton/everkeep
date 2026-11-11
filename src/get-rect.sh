#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Shape

cat << EOF

    let ${v}Rect = Rect {
        x: ${!shape}.x - ${!shape}.size / 2.0,
        y: ${!shape}.y - ${!shape}.size / 2.0,
        w: ${!shape}.size,
        h: ${!shape}.size,
    };

EOF
