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

    impl Shape {
        fn collides_with(&self, other: &Self) -> bool {
            self.rect().overlaps(&other.rect())
        }
        fn rect(&self) -> Rect {
            Rect {
                x: self.x - self.size / 2.0,
                y: self.y - self.size / 2.0,
                w: self.size,
                h: self.size,
            }
        }
    }

    #[macroquad::main("EverKeep")]
    async fn main() {
        rand::srand(miniquad::date::now() as u64);
        let vel: f32 = 200.0;
        let mut gameover = false;

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
            if !gameover {
                ` ./update-falling-squares.sh ${v}fall_ `
                ` ./update-circle-dir.sh ${v}dir_ `
                ` ./distance.sh ${v}dist_x_ `
                ` ./distance.sh ${v}dist_y_ `
                circle.x = clamp(circle.x, 0.0, screen_width());
                circle.y = clamp(circle.y, 0.0, screen_height());

                println!("{x},{y}", x = circle.x, y = circle.y);

                if squares.iter().any(|square| circle.collides_with(square)) {
                    gameover = true;
                }
            }

            if gameover && is_key_pressed(KeyCode::Space) {
                squares.clear();
                circle.x = screen_width() / 2.0;
                circle.y = screen_height() / 2.0;
                gameover = false;
            }

            // Draw
            draw_circle(circle.x, circle.y, circle.size / 2.0, YELLOW);
            ` ./draw-squares.sh ${v}drawsq_ `
            if gameover {
                let text = "GAME OVER!";
                let text_dimensions = measure_text(text, None, 50, 1.0);
                draw_text(
                    text,
                    screen_width() / 2.0 - text_dimensions.width / 2.0,
                    screen_height() / 2.0,
                    50.0,
                    RED,
                );
            }

            next_frame().await
        }
    }

EOF
