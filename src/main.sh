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
export ${v}dir_Ship=ship_sprite
export ${v}dir_Circ=circle
export ${v}fall_Squares=squares
export ${v}fall_DeltaT=t
export ${v}drawsq_Squares=squares
export ${v}bulls_Circ=circle
export ${v}bulls_Bullets=bullets
export ${v}bulls_DeltaT=t
export ${v}bulls_Squares=squares
export ${v}bulls_ShootSound=sound_laser

export ${v}circ_rect_Shape=circle
export ${v}sq_rect_Shape=sq
export ${v}go_SquareRect=${v}sq_rect_Rect
export ${v}go_CircRect=${v}circ_rect_Rect
export ${v}go_GameState=game_state

export ${v}bullcoll_sq_rect_Shape=square
export ${v}bullcoll_bull_rect_Shape=bullet

export ${v}drawsc_Score=score
export ${v}drawsc_HighScore=high_score

export ${v}explod_Square=square
export ${v}explod_Explosions=explosions
export ${v}explod_ExplosionTexture=explosion_texture

cat << EOF

    #![allow(non_snake_case)]

    use macroquad_particles::{AtlasConfig, Emitter, EmitterConfig};
    use quad_storage::STORAGE;
    use macroquad::experimental::animation::{AnimatedSprite, Animation};
    use macroquad::audio::{load_sound, play_sound, play_sound_once, PlaySoundParams};
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
        let mut explosions: Vec<(Emitter, Vec2)> = vec![];
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

        set_pc_assets_folder("assets");
        let ship_texture: Texture2D = load_texture("ship.png").await
            .expect("Couldn't load file");
        ship_texture.set_filter(FilterMode::Nearest);
        let enemy_small_texture: Texture2D = load_texture("enemy-small.png")
            .await
            .expect("Couldn't load file");
        enemy_small_texture.set_filter(FilterMode::Nearest);
        let mut enemy_small_sprite = AnimatedSprite::new(
            17,
            16,
            &[Animation {
                name: "enemy_small".to_string(),
                row: 0,
                frames: 2, // column count
                fps: 12,
            }],
            true,
        );
        let bullet_texture: Texture2D = load_texture("laser-bolts.png")
            .await
            .expect("Couldn't load file");
        bullet_texture.set_filter(FilterMode::Nearest);
        let mut bullet_sprite = AnimatedSprite::new(
            16,
            16,
            &[
                Animation {
                    name: "bullet".to_string(),
                    row: 0,
                    frames: 2,
                    fps: 12,
                },
                Animation {
                    name: "bolt".to_string(),
                    row: 1,
                    frames: 2,
                    fps: 12,
                },
            ],
            true,
        );
        bullet_sprite.set_animation(1);
        let mut ship_sprite = AnimatedSprite::new(
            16,
            24,
            &[
                Animation {
                    name: "idle".to_string(),
                    row: 0,
                    frames: 2,
                    fps: 12,
                },
                Animation {
                    name: "left".to_string(),
                    row: 2,
                    frames: 2,
                    fps: 12,
                },
                Animation {
                    name: "right".to_string(),
                    row: 4,
                    frames: 2,
                    fps: 12,
                },
            ],
            true,
        );
        let explosion_texture: Texture2D = load_texture("explosion.png")
            .await
            .expect("Couldn't load file");
        explosion_texture.set_filter(FilterMode::Nearest);
        build_textures_atlas();

        let theme_music = load_sound("8bit-spaceshooter.ogg").await.unwrap();
        let sound_explosion = load_sound("explosion.wav").await.unwrap();
        let sound_laser = load_sound("laser.wav").await.unwrap();

        play_sound(
            &theme_music,
            PlaySoundParams {
                looped: true,
                volume: 1.,
            },
        );

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
                        explosions.clear();
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
                    ship_sprite.update();
                    enemy_small_sprite.update();
                    bullet_sprite.update();
                    for square in squares.iter_mut() {
                        ` ./get-rect.sh ${v}bullcoll_sq_rect_ `
                        for bullet in bullets.iter_mut() {
                            ` ./get-rect.sh ${v}bullcoll_bull_rect_ `
                            if ${v}bullcoll_bull_rect_Rect.overlaps(&${v}bullcoll_sq_rect_Rect) {
                                bullet.collided = true;
                                square.collided = true;
                                score += square.size.round() as u32;
                                high_score = high_score.max(score);
                                ` ./update-explosions.sh ${v}explod_ `
                                play_sound_once(&sound_explosion);
                            }
                        }
                    }
                    explosions.retain(|(explosion, _)| explosion.config.emitting);
    
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
                    let bullet_frame = bullet_sprite.frame();
                    for bullet in &bullets {
                        draw_texture_ex(
                            &bullet_texture,
                            bullet.x - bullet.size / 2.0,
                            bullet.y - bullet.size / 2.0,
                            WHITE,
                            DrawTextureParams {
                                dest_size: Some(vec2(bullet.size, bullet.size)),
                                source: Some(bullet_frame.source_rect),
                                ..Default::default()
                            },
                        );
                    }
                    let ship_frame = ship_sprite.frame();
                    draw_texture_ex(
                        &ship_texture,
                        circle.x - ship_frame.dest_size.x,
                        circle.y - ship_frame.dest_size.y,
                        WHITE,
                        DrawTextureParams {
                            dest_size: Some(ship_frame.dest_size * 2.0),
                            source: Some(ship_frame.source_rect),
                            ..Default::default()
                        },
                    );
                    let ${v}drawsq_EnemyFrame = enemy_small_sprite.frame();
                    ` ./draw-squares.sh ${v}drawsq_ `
                    for (explosion, coords) in explosions.iter_mut() {
                        explosion.draw(*coords);
                    }
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
