#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Circ Bullets Squares DeltaT

cat << EOF
    if is_key_pressed(KeyCode::Space) {
        ${!bullets}.push(Shape {
            x: ${!circ}.x,
            y: ${!circ}.y - 24.0,
            x_dir: 0.0,
            y_dir: 0.0,
            speed: ${!circ}.speed * 2.0,
            size: 32.0,
            collided: false
        });
    }

    for bullet in &mut ${!bullets} {
        bullet.y -= bullet.speed * ${!delta_t};
    }

    ${!bullets}.retain(|bullet| bullet.y > 0.0 - bullet.size / 2.0);
    ${!squares}.retain(|square| !square.collided);
    ${!bullets}.retain(|bullet| !bullet.collided);

EOF
