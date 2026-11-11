#!/bin/bash

v=${1:-mn_}
# maps
export ${v}dist_x_Vel=circle.speed
export ${v}dist_x_T=t
export ${v}dist_y_Vel=circle.speed
export ${v}dist_y_T=t
export ${v}dist_x_D=circle.x
export ${v}dist_y_D=circle.y
export ${v}dist_x_Dir=circle.x_dir
export ${v}dist_y_Dir=circle.y_dir
export ${v}dir_Circ=circle
export ${v}fall_Squares=squares
export ${v}fall_DeltaT=t
export ${v}drawsq_Squares=squares

cat << EOF

    #![allow(non_snake_case)]

    use macroquad::prelude::*;

    struct Shape {
        size: f32,
        speed: f32,
        x: f32,
        y: f32,
        x_dir: f32,
        y_dir: f32
    }

    #[macroquad::main("EverKeep")]
    async fn main() {
        rand::srand(miniquad::date::now() as u64);
        let vel: f32 = 200.0;

        let mut squares = vec![];
        let mut circle = Shape {
            size: 32.0,
            speed: vel,
            x: screen_width() / 2.0,
            y: screen_height() / 2.0,
            x_dir: 0.0,
            y_dir: 0.0,
        };
        loop {
            // Clear
            clear_background(DARKPURPLE);

            // Update
            let t = get_frame_time();
            ` ./update-falling-squares.sh ${v}fall_ `
            ` ./update-circle-dir.sh ${v}dir_ `
            ` ./distance.sh ${v}dist_x_ `
            ` ./distance.sh ${v}dist_y_ `
            circle.x = clamp(circle.x, 0.0, screen_width());
            circle.y = clamp(circle.y, 0.0, screen_height());

            println!("{x},{y}", x = circle.x, y = circle.y);

            // Draw
            draw_circle(circle.x, circle.y, circle.size / 2.0, YELLOW);
            ` ./draw-squares.sh ${v}drawsq_ `

            next_frame().await
        }
    }

EOF
