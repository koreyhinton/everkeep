#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Squares DeltaT

cat << EOF
    if rand::gen_range(0, 99) >= 95 {
        let size = rand::gen_range(16.0, 64.0);
        ${!squares}.push(Shape {
            size,
            speed: rand::gen_range(50.0, 150.0),
            x: rand::gen_range(size / 2.0, screen_width() - size / 2.0),
            y: -size,
            x_dir: 0.0,
            y_dir: 1.0,
            collided: false,
        });
    }

    for square in &mut ${!squares} {
        square.y += square.speed * ${!delta_t};
    }

    // cleanup squares that moved off the screen
    ${!squares}.retain(|square| square.y < screen_height() + square.size);
EOF
