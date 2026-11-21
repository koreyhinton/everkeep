#!/bin/bash

v=${1:-mn_}
# maps
export ${v}res_Resources=resources

export ${v}anim_AnimatedSprite=pawn_sprite
export ${v}dir_Unit=unit
export ${v}dir_Sprite=pawn_sprite
export ${v}dir_DeltaT=t
export ${v}dir_IdleAnimation=idle_animation
export ${v}dir_RunAnimation=run_animation
export ${v}dist_x_Vel=unit.speed
export ${v}dist_x_T=t
export ${v}dist_x_D=unit.pos.x
export ${v}dist_x_Dir=unit.dir.x
export ${v}dist_y_Vel=unit.speed
export ${v}dist_y_T=t
export ${v}dist_y_D=unit.pos.y
export ${v}dist_y_Dir=unit.dir.y

export ${v}new_rect_Pos=new_house.pos
export ${v}new_rect_Hitbox=new_house.hitbox
export ${v}house_rect_Pos=house.pos
export ${v}house_rect_Hitbox=house.hitbox

export ${v}explod_Pos=new_house.pos
export ${v}explod_Explosions=explosions
export ${v}explod_ExplosionTexture=resources.dust_texture

export ${v}ground_GrassTexture=resources.grass_texture
export ${v}back_House=house
export ${v}back_HouseTexture=resources.house_texture
export ${v}front_House=house
export ${v}front_HouseTexture=resources.house_texture
export ${v}drawunit_Unit=unit
export ${v}drawunit_Sprite=pawn_sprite
export ${v}drawunit_IdleTexture=resources.pawn_idle_texture
export ${v}drawunit_RunTexture=resources.pawn_run_texture

export ${v}drawsc_Score=score
export ${v}drawsc_HighScore=high_score

export ${v}uipress_Ui=ui
export ${v}uipress_Houses=houses
export ${v}uipress_Expl=explosions
export ${v}uipress_Unit=unit
export ${v}uipress_Score=score
export ${v}uipress_GameState=game_state

cat << EOF

    #![allow(non_snake_case)]

    use macroquad_particles::{AtlasConfig, Emitter, EmitterConfig};
    use quad_storage::STORAGE;
    use macroquad::experimental::coroutines::{start_coroutine, Coroutine};
    use macroquad::Error;
    use macroquad::ui::{hash, root_ui, widgets::Window, Skin};
    use macroquad::prelude::*;

    // true keeps the loading screen up for at least 2 seconds, to see the spinner
    const FORCE_VISIBLE_LOAD_SCREEN: bool = true;

    // a house's footprint, relative to its bottom-center position
    const HOUSE_HITBOX: Rect = Rect::new(-56.0, -72.0, 112.0, 72.0);

EOF

# between heredocs, not in backticks, so a version mismatch stops the build
${ORC_ANIMATE}/models.sh "${ORC_ANIMATE_VERSION}" || exit 1

cat << EOF

    enum GameState {
        MainMenu,
        Playing,
        Paused,
    }

    struct Unit {
        pos: Vec2, // feet
        target: Vec2,
        dir: Vec2,
        speed: f32,
        flip: bool,
    }

    struct Building {
        pos: Vec2, // bottom-center
        hitbox: Rect,
    }

    struct Resources {
        pawn_idle_texture: Texture2D,
        pawn_run_texture: Texture2D,
        house_texture: Texture2D,
        grass_texture: Texture2D,
        dust_texture: Texture2D,
        ui_skin: Skin,
    }

    struct ResourceCoroutines {
        pawn_idle_co: Coroutine<Result<Texture2D, Error>>,
        pawn_run_co: Coroutine<Result<Texture2D, Error>>,
        house_co: Coroutine<Result<Texture2D, Error>>,
        grass_co: Coroutine<Result<Texture2D, Error>>,
        dust_co: Coroutine<Result<Texture2D, Error>>,
    }

    #[macroquad::main("EverKeep")]
    async fn main() -> Result<(), macroquad::Error> {
        rand::srand(miniquad::date::now() as u64);
        let mut game_state = GameState::MainMenu;
        let storage = &mut STORAGE.lock().unwrap();

        // score is the number of houses built
        let mut score: u32 = 0;
        let mut high_score: u32 = storage.get("houses_high_score")
            .map_or(Ok(0), |i| i.parse::<u32>())
            .unwrap_or(0);

        let mut houses: Vec<Building> = vec![];
        let mut explosions: Vec<(Emitter, Vec2)> = vec![];
        let mut unit = Unit {
            pos: vec2(screen_width() / 2.0, screen_height() / 2.0),
            target: vec2(screen_width() / 2.0, screen_height() / 2.0),
            dir: Vec2::ZERO,
            speed: 200.0,
            flip: false,
        };

        set_pc_assets_folder("assets");

        ` ./resources-load-async-loop.sh ${v}res_ `

        let idle_animation = Animation {
            id: "idle".to_string(),
            row: 0,
            frames: 8,
            fps: 10.0,
        };

        let run_animation = Animation {
            id: "run".to_string(),
            row: 0,
            frames: 6,
            fps: 10.0,
        };

        let mut pawn_sprite = AnimatedSprite {
            w: 192.0,
            h: 192.0,
            frame: 0,
            frame_time: 0.0,
            animation: &idle_animation,
            last_animation_id: String::new(),
            paint_frame: None,
        };

        root_ui().push_skin(&resources.ui_skin);
        let window_size = vec2(370.0, 320.0);

        loop {
            // Clear
            clear_background(BLACK);
            ` ./draw-ground.sh ${v}ground_ `

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
                        houses.clear();
                        explosions.clear();
                        unit.pos = vec2(screen_width() / 2.0, screen_height() / 2.0);
                        unit.target = unit.pos;
                        score = 0;
                        game_state = GameState::Playing;
                    }
                }
                GameState::Playing => 'playing: {
                    if is_key_pressed(KeyCode::Escape) {
                        game_state = GameState::Paused;
                        break 'playing; // pause skips the update til it resumes
                    }
                    ` ./update-unit-dir.sh ${v}dir_ `
                    ` ./distance.sh ${v}dist_x_ `
                    ` ./distance.sh ${v}dist_y_ `

                    pawn_sprite.frame_time += t;
                    ` ${ORC_ANIMATE}/snippets/macroquad/animate-sprite.sh ${v}anim_ `

                    // place a house just behind the unit, if the spot is free
                    if is_key_pressed(KeyCode::Space) {
                        let new_house = Building {
                            pos: unit.pos - vec2(0.0, 8.0),
                            hitbox: HOUSE_HITBOX,
                        };
                        ` ./get-rect.sh ${v}new_rect_ `
                        let mut blocked = false;
                        for house in &houses {
                            ` ./get-rect.sh ${v}house_rect_ `
                            if ${v}house_rect_Rect.overlaps(&${v}new_rect_Rect) {
                                blocked = true;
                                break;
                            }
                        }
                        if !blocked {
                            ` ./update-explosions.sh ${v}explod_ `
                            houses.push(new_house);
                            score += 1;
                            if score > high_score {
                                high_score = score;
                                storage.set("houses_high_score", &high_score.to_string());
                            }
                        }
                    }
                    explosions.retain(|(explosion, _)| explosion.config.emitting);
                }
                GameState::Paused => {
                    if is_key_pressed(KeyCode::Space) {
                        game_state = GameState::Playing;
                    }
                    if is_key_pressed(KeyCode::Escape) {
                        game_state = GameState::MainMenu;
                    }
                }
            }

            // Draw
            match game_state {
                GameState::MainMenu => {
                    let mut ui = root_ui();
                    let window = Window::new(
                        hash!(),
                        vec2(
                            screen_width() / 2.0 - window_size.x / 2.0,
                            screen_height() / 2.0 - window_size.y / 2.0,
                        ),
                        window_size,
                    )
                    .titlebar(false)
                    .begin(&mut *ui);
                    ` ./draw-ui.sh ${v}uipress_ `
                    window.end(&mut *ui);
                }
                GameState::Playing | GameState::Paused => {
                    // draw back to front: houses above the unit, the unit, houses below it
                    for house in &houses {
                        if house.pos.y <= unit.pos.y {
                            ` ./draw-house.sh ${v}back_ `
                        }
                    }
                    ` ./draw-unit.sh ${v}drawunit_ `
                    for house in &houses {
                        if house.pos.y > unit.pos.y {
                            ` ./draw-house.sh ${v}front_ `
                        }
                    }
                    for (explosion, coords) in explosions.iter_mut() {
                        explosion.draw(*coords);
                    }
                }
            }
            if let GameState::Paused = game_state {
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
            ` ./draw-score.sh ${v}drawsc_ `

            next_frame().await
        }
    }

EOF
