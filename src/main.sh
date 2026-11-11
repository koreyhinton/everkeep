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
        let mut x = screen_width() / 2.0;
        let mut y = screen_height() / 2.0;
        loop {
            clear_background(DARKPURPLE);

            if is_key_down(KeyCode::Right) {
                x += 1.0;
            }
            if is_key_down(KeyCode::Left) {
                x -= 1.0;
            }
            if is_key_down(KeyCode::Down) {
                y += 1.0;
            }
            if is_key_down(KeyCode::Up) {
                y -= 1.0;
            }


            let t = get_frame_time();
            ` ./distance.sh ${v}dist_ `

            println!("{${v}dist_D}");

            draw_circle(x, y, 16.0, YELLOW);

            next_frame().await
        }
    }

EOF
