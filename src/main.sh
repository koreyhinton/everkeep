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
export ${v}bulls_Circ=circle
export ${v}bulls_Bullets=bullets
export ${v}bulls_DeltaT=t
export ${v}bulls_Squares=squares

export ${v}circ_rect_Shape=circle
export ${v}sq_rect_Shape=sq
export ${v}go_SquareRect=${v}sq_rect_Rect
export ${v}go_CircRect=${v}circ_rect_Rect
export ${v}go_GameOver=gameover

export ${v}bullcoll_sq_rect_Shape=square
export ${v}bullcoll_bull_rect_Shape=bullet

cat << EOF

    #![allow(non_snake_case)]

    use macroquad::prelude::*;

    struct Shape {
        size: f32,
        speed: f32,
        x: f32,
        y: f32,
        x_dir: f32,
        y_dir: f32,
        collided: bool,
    }

    #[macroquad::main("EverKeep")]
    async fn main() {
        rand::srand(miniquad::date::now() as u64);
        let vel: f32 = 200.0;
        let mut gameover = false;

        let mut squares = vec![];
        let mut bullets: Vec<Shape> = vec![];
        let mut circle = Shape {
            size: 32.0,
            speed: vel,
            x: screen_width() / 2.0,
            y: screen_height() / 2.0,
            x_dir: 0.0,
            y_dir: 0.0,
            collided: false,
        };
        loop {
            // Clear
            clear_background(DARKPURPLE);

            // Update Model (also based on Key Presses)
            let t = get_frame_time();
            if !gameover {
                ` ./update-falling-squares.sh ${v}fall_ `
                ` ./update-circle-dir.sh ${v}dir_ `
                ` ./distance.sh ${v}dist_x_ `
                ` ./distance.sh ${v}dist_y_ `
                circle.x = clamp(circle.x, 0.0, screen_width());
                circle.y = clamp(circle.y, 0.0, screen_height());
                ` ./update-bullets-and-squares.sh ${v}bulls_ `
                for square in squares.iter_mut() {
                    ` ./get-rect.sh ${v}bullcoll_sq_rect_ `
                    for bullet in bullets.iter_mut() {
                        ` ./get-rect.sh ${v}bullcoll_bull_rect_ `
                        if ${v}bullcoll_bull_rect_Rect.overlaps(&${v}bullcoll_sq_rect_Rect) {
                            bullet.collided = true;
                            square.collided = true;
                        }
                    }
                }

                println!("{x},{y}", x = circle.x, y = circle.y);

                ` ./get-rect.sh ${v}circ_rect_ `
                for sq in &squares {
                    ` ./get-rect.sh ${v}sq_rect_ `
                    ` ./update-game-over-collision.sh ${v}go_ `
                }
            }

            if gameover && is_key_pressed(KeyCode::Space) {
                squares.clear();
                bullets.clear();
                circle.x = screen_width() / 2.0;
                circle.y = screen_height() / 2.0;
                gameover = false;
            }

            // Draw
            for bullet in &bullets {
                draw_circle(bullet.x, bullet.y, bullet.size / 2.0, RED);
            }
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
