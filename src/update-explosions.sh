#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Square Explosions ExplosionTexture

cat << EOF

    ${!explosions}.push((
        Emitter::new(EmitterConfig {
            amount: ${!square}.size.round() as u32 * 4,
            texture: Some(${!explosion_texture}.clone()),
            local_coords: false,
            one_shot: true,
            emitting: true,
            lifetime: 0.6,
            lifetime_randomness: 0.3,
            explosiveness: 0.65,
            initial_direction_spread: 2.0 * std::f32::consts::PI,
            initial_velocity: 400.0,
            initial_velocity_randomness: 0.8,
            size: 16.0,
            size_randomness: 0.3,
            atlas: Some(AtlasConfig::new(5, 1, 0..)),
            ..Default::default()
        }),
        vec2(${!square}.x, ${!square}.y),
    ));

EOF
