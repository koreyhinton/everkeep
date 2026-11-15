#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Pos Explosions ExplosionTexture

cat << EOF

    ${!explosions}.push((
        Emitter::new(EmitterConfig {
            amount: 6,
            texture: Some(${!explosion_texture}.clone()),
            local_coords: false,
            one_shot: true,
            emitting: true,
            lifetime: 0.6,
            lifetime_randomness: 0.2,
            explosiveness: 0.9,
            initial_direction_spread: 2.0 * std::f32::consts::PI,
            initial_velocity: 60.0,
            initial_velocity_randomness: 0.5,
            size: 48.0,
            size_randomness: 0.3,
            atlas: Some(AtlasConfig::new(8, 1, 0..)),
            ..Default::default()
        }),
        ${!pos},
    ));

EOF
