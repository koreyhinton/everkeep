#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Circ Ship

cat << EOF
    ${!circ}.x_dir = 0.0;
    ${!circ}.y_dir = 0.0;
    ${!ship}.set_animation(0);
    if is_key_down(KeyCode::Right) {
        ${!circ}.x_dir += 1.0;
        ${!ship}.set_animation(2);
    }
    if is_key_down(KeyCode::Left) {
        ${!circ}.x_dir += -1.0;
        ${!ship}.set_animation(1);
    }
    if is_key_down(KeyCode::Down) {
        ${!circ}.y_dir += 1.0;
    }
    if is_key_down(KeyCode::Up) {
        ${!circ}.y_dir += -1.0;
    }
EOF
