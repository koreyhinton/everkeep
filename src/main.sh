#!/bin/bash

v=${1:-mn_}
# maps
export ${v}dist_x_Vel=vel
export ${v}dist_x_T=t
export ${v}dist_y_Vel=vel
export ${v}dist_y_T=t
export ${v}dist_x_D=x
export ${v}dist_y_D=y
export ${v}dist_x_Dir=x_dir
export ${v}dist_y_Dir=y_dir


cat << EOF

    #![allow(non_snake_case)]

    use macroquad::prelude::*;

    #[macroquad::main("EverKeep")]
    async fn main() {
        let vel: f32 = 200.0;
        let mut x = screen_width() / 2.0;
        let mut y = screen_height() / 2.0;
        loop {
            clear_background(DARKPURPLE);

            let t = get_frame_time();

            let mut x_dir: f32 = 0.0;
            let mut y_dir: f32 = 0.0;

            if is_key_down(KeyCode::Right) {
                x_dir = 1.0;
            }
            if is_key_down(KeyCode::Left) {
                x_dir = -1.0;
            }
            if is_key_down(KeyCode::Down) {
                y_dir = 1.0;
            }
            if is_key_down(KeyCode::Up) {
                y_dir = -1.0;
            }

            if x_dir != 0.0 {
                ` ./distance.sh ${v}dist_x_ `
            }
            if y_dir != 0.0 {
                ` ./distance.sh ${v}dist_y_ `
            }

            println!("{x}, {y}");

            draw_circle(x, y, 16.0, YELLOW);

            next_frame().await
        }
    }

EOF
