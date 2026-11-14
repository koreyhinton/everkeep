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
export ${v}go_GameState=game_state

export ${v}bullcoll_sq_rect_Shape=square
export ${v}bullcoll_bull_rect_Shape=bullet

export ${v}drawsc_Score=score
export ${v}drawsc_HighScore=high_score

cat << EOF

    #![allow(non_snake_case)]

    use quad_storage::STORAGE;
    use macroquad::prelude::*;

    const FRAGMENT_SHADER: &str = include_str!("starfield-shader.glsl");

    const VERTEX_SHADER: &str = "#version 100
    attribute vec3 position;
    attribute vec2 texcoord;
    attribute vec4 color0;
    varying float iTime;

    uniform mat4 Model;
    uniform mat4 Projection;
    uniform vec4 _Time;

    void main() {
        gl_Position = Projection * Model * vec4(position, 1);
        iTime = _Time.x;
    }
    ";

    enum GameState {
        MainMenu,
        Playing,
        Paused,
        CrashFrame,
        GameOver,
    }

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
        let mut game_state = GameState::MainMenu;
        let storage = &mut STORAGE.lock().unwrap();

        let mut score: u32 = 0;
        let mut high_score: u32 = storage.get("highscore.dat")
            .map_or(Ok(0), |i| i.parse::<u32>())
            .unwrap_or(0);

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

        let mut direction_modifier: f32 = 0.0;
        let render_target = render_target(320, 150);
        render_target.texture.set_filter(FilterMode::Nearest);
        let material = load_material(
            ShaderSource::Glsl {
                vertex: VERTEX_SHADER,
                fragment: FRAGMENT_SHADER,
            },
            MaterialParams {
                uniforms: vec![
                    UniformDesc::new("iResolution", UniformType::Float2),
                    UniformDesc::new("direction_modifier", UniformType::Float1),
                ],
                ..Default::default()
            },
        )
        .unwrap();

        loop {
            // Clear
            clear_background(BLACK);
            material.set_uniform("iResolution", (screen_width(), screen_height()));
            material.set_uniform("direction_modifier", direction_modifier);
            gl_use_material(&material);
            draw_texture_ex(
                &render_target.texture,
                0.,
                0.,
                WHITE,
                DrawTextureParams {
                    dest_size: Some(vec2(screen_width(), screen_height())),
                    ..Default::default()
                },
            );
            gl_use_default_material();

            // Update Model (also based on Key Presses)
            let t = get_frame_time();

            match game_state {
                GameState::MainMenu => {
                    #[cfg(not(target_arch = "wasm32"))]
                    if is_key_pressed(KeyCode::Escape) {
                        std::process::exit(0);
                    }
                    if is_key_pressed(KeyCode::Space) {
                        // restart the game
                        squares.clear();
                        bullets.clear();
                        circle.x = screen_width() / 2.0;
                        circle.y = screen_height() / 2.0;
                        score = 0;
                        game_state = GameState::Playing;
                    }
                }
                GameState::Playing => 'playing: {
                    if is_key_pressed(KeyCode::Escape) {
                        game_state = GameState::Paused;
                        break 'playing; // pause skips collision til it resumes
                    }
                    ` ./update-falling-squares.sh ${v}fall_ `
                    ` ./update-circle-dir.sh ${v}dir_ `
                    direction_modifier += 0.05 * t * circle.x_dir;
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
                                score += square.size.round() as u32;
                                high_score = high_score.max(score);
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
                GameState::Paused => {
                    if is_key_pressed(KeyCode::Space) {
                        game_state = GameState::Playing;
                    }
                }
                GameState::CrashFrame => {
                    if score == high_score {
                        storage.set("highscore.dat", &high_score.to_string());
                    }
                    game_state = GameState::GameOver
                }
                GameState::GameOver => {
                    if is_key_pressed(KeyCode::Space) {
                        game_state = GameState::MainMenu;
                    }
                }
            }

            // Draw
            match game_state {
                GameState::MainMenu => {
                    let text = "Press space";
                    let text_dimensions = measure_text(text, None, 50, 1.0);
                    draw_text(
                        text,
                        screen_width() / 2.0 - text_dimensions.width / 2.0,
                        screen_height() / 2.0 - text_dimensions.height / 2.0,
                        50.0,
                        WHITE,
                    );
                }
                GameState::Playing => {
                    for bullet in &bullets {
                        draw_circle(bullet.x, bullet.y, bullet.size / 2.0, RED);
                    }
                    draw_circle(circle.x, circle.y, circle.size / 2.0, YELLOW);
                    ` ./draw-squares.sh ${v}drawsq_ `
                }
                GameState::Paused => {
                    let text = "Paused";
                    let text_dimensions = measure_text(text, None, 50, 1.0);
                    draw_text(
                        text,
                        screen_width() / 2.0 - text_dimensions.width / 2.0,
                        screen_height() / 2.0 - text_dimensions.height / 2.0,
                        50.0,
                        WHITE,
                    );
                }
                GameState::CrashFrame => {
                }
                GameState::GameOver => {
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
            }
            ` ./draw-score.sh ${v}drawsc_ `


            next_frame().await
        }
    }

EOF
