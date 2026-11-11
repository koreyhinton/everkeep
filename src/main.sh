#!/bin/bash

v=${1:-mn_}
# maps
export ${v}dist_Vel=vel
export ${v}dist_T=t

cat << EOF

    #![allow(non_snake_case)]

    use macroquad::prelude::*;

    #[macroquad::main("EverKeep")]
    async fn main() {
        let vel: f32 = 200.0;
        let mut ${v}dist_D: f32 = 0.0;
        loop {
            clear_background(DARKPURPLE);
            let t = get_frame_time();
            ` ./distance.sh ${v}dist_ `

            println!("{${v}dist_D}");

            next_frame().await
        }
    }

EOF
