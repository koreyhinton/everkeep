#!/bin/bash

v=${1:-mn_}
# maps
export ${v}res_Resources=resources

export ${v}reset_World=world
export ${v}reset_Players=1
export ${v}reset_Seed=miniquad::date::now\(\).to_bits\(\)
export ${v}mpreset_World=world
export ${v}mpreset_Players=2
export ${v}mpreset_Seed=seed

export ${v}layout_BuildButton=build_button
export ${v}layout_TrainButton=train_button
export ${v}hud_Buildings=world.buildings
export ${v}hud_Gold=world.gold[world.me]
export ${v}hud_Placing=world.placing
export ${v}hud_Outbox=world.outbox
export ${v}hud_Me=world.me
export ${v}hud_BuildButton=build_button
export ${v}hud_TrainButton=train_button
export ${v}place_Placing=world.placing
export ${v}place_Outbox=world.outbox
export ${v}place_View=world.view
export ${v}select_DragStart=world.drag_start
export ${v}select_Units=world.units
export ${v}select_Buildings=world.buildings
export ${v}select_View=world.view
export ${v}select_Me=world.me
export ${v}orders_Units=world.units
export ${v}orders_View=world.view
export ${v}orders_Outbox=world.outbox
export ${v}orders_Me=world.me

export ${v}apply_Commands=turn_cmds[player]
export ${v}apply_Player=player
export ${v}apply_Units=world.units
export ${v}apply_Buildings=world.buildings
export ${v}apply_Gold=world.gold
export ${v}apply_NextId=world.next_id
export ${v}units_Units=world.units
export ${v}units_DeltaT=TICK_SECS
export ${v}scroll_Units=world.units
export ${v}scroll_View=world.view
export ${v}scroll_Me=world.me
export ${v}anim_AnimatedSprite=pawn_sprite
export ${v}frame_Unit=unit
export ${v}frame_Sprite=pawn_sprite

export ${v}srv_Server=server
export ${v}join_Url=join_url
export ${v}poll_Post=join_post
export ${v}conn_Url=ws_url
export ${v}rd_Ws=ws
export ${v}rd_Text=net_text
export ${v}recv_Text=net_text
export ${v}recv_Confirmed=confirmed
export ${v}recv_Started=started
export ${v}recv_EndReason=end_reason
export ${v}prime_Commands=no_cmds
export ${v}prime_NextSend=next_send
export ${v}prime_TurnMsg=turn_msg
export ${v}psend_Ws=ws
export ${v}psend_Text=turn_msg
export ${v}msg_Commands=world.outbox
export ${v}msg_NextSend=next_send
export ${v}msg_TurnMsg=turn_msg
export ${v}send_Ws=ws
export ${v}send_Text=turn_msg
export ${v}sum_World=world
export ${v}sum_Checksum=checksum
export ${v}status_Me=world.me
export ${v}status_Turn=turn
export ${v}status_Checksum=checksum
export ${v}status_StalledSince=stalled_since

export ${v}ground_GrassTexture=resources.grass_texture
export ${v}ground_View=world.view
export ${v}world_Units=world.units
export ${v}world_Buildings=world.buildings
export ${v}world_View=world.view
export ${v}world_HallTextures=resources.hall_textures
export ${v}world_PawnTextures=resources.pawn_textures
export ${v}ghost_Placing=world.placing
export ${v}ghost_HallTexture=resources.hall_textures[world.me]
export ${v}dragbox_DragStart=world.drag_start
export ${v}minimap_Units=world.units
export ${v}minimap_Buildings=world.buildings
export ${v}minimap_View=world.view
export ${v}drawhud_Units=world.units
export ${v}drawhud_Buildings=world.buildings
export ${v}drawhud_Gold=world.gold[world.me]
export ${v}drawhud_Placing=world.placing
export ${v}drawhud_Me=world.me
export ${v}drawhud_BuildButton=build_button
export ${v}drawhud_TrainButton=train_button

export ${v}uipress_Ui=ui
export ${v}uipress_GameState=game_state
export ${v}uipress_Server=server
export ${v}uipress_JoinSent=join_sent

cat << EOF

    #![allow(non_snake_case)]

    use macroquad::experimental::coroutines::{start_coroutine, Coroutine};
    use macroquad::Error;
    use macroquad::ui::{hash, root_ui, widgets::Window, Skin};
    use macroquad::prelude::*;
    use std::collections::BTreeMap;

    // true keeps the loading screen up for at least 2 seconds, to see the spinner
    const FORCE_VISIBLE_LOAD_SCREEN: bool = true;

EOF

# the game's constants and types (World, Unit, Building, Command, ...)
./models.sh

# between heredocs, not in backticks, so a version mismatch stops the build
${ORC_ANIMATE}/models.sh "${ORC_ANIMATE_VERSION}" || exit 1
${ORC_WS}/models.sh "${ORC_WS_VERSION}" || exit 1

cat << EOF

    enum GameState {
        MainMenu,
        Starting,   // a new offline game
        Joining,    // waiting for the server's reply to POST /match
        Connecting, // websocket open, waiting for the match to start
        Playing,
        Paused,
        Ended, // the match ended; ended_reason says why
    }

    struct Resources {
        pawn_textures: [[Texture2D; 2]; 2],
        hall_textures: [Texture2D; 2],
        grass_texture: Texture2D,
        ui_skin: Skin,
    }

    struct ResourceCoroutines {
        blue_idle_co: Coroutine<Result<Texture2D, Error>>,
        blue_run_co: Coroutine<Result<Texture2D, Error>>,
        red_idle_co: Coroutine<Result<Texture2D, Error>>,
        red_run_co: Coroutine<Result<Texture2D, Error>>,
        blue_hall_co: Coroutine<Result<Texture2D, Error>>,
        red_hall_co: Coroutine<Result<Texture2D, Error>>,
        grass_co: Coroutine<Result<Texture2D, Error>>,
    }

    #[macroquad::main("EverKeep")]
    async fn main() -> Result<(), macroquad::Error> {
        let mut game_state = GameState::MainMenu;

        let mut world = World {
            units: vec![],
            buildings: vec![],
            gold: [START_GOLD; 2],
            me: 0,
            placing: None,
            drag_start: None,
            view: Vec2::ZERO,
            next_id: 0,
            outbox: vec![],
        };

        // lockstep: offline games run the same turns, confirmed locally
        let mut online = false;
        let mut tick: u32 = 0;
        let mut turn: u32 = 0;
        let mut acc: f32 = 0.0; // real time not yet simulated
        let mut next_send: u32 = 0; // the next turn to send commands for
        let mut confirmed: BTreeMap<u32, [Vec<Command>; 2]> = BTreeMap::new();
        let mut stalled_since: Option<f64> = None;
        let mut ended_reason = String::new();

        // the lockstep server, if there is one (--server URL on desktop)
        ` ${ORC_WS}/snippets/default-server.sh ${v}srv_ `
        let mut join_sent = false;
        let mut join_post = WsPost { id: -1, done: false, body: Err(String::new()) };
        let mut ws = WsClient {
            #[cfg(not(target_arch = "wasm32"))]
            socket: None,
            state: 2,
            close_reason: String::new(),
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

        // one sprite per unit, in step with world.units (units are never removed)
        let mut pawn_sprites: Vec<AnimatedSprite> = vec![];

        root_ui().push_skin(&resources.ui_skin);
        let window_size = vec2(370.0, 360.0);

        loop {
            let t = get_frame_time();
            ` ./hud-layout.sh ${v}layout_ `

            // Update
            match game_state {
                GameState::MainMenu => {
                    #[cfg(not(target_arch = "wasm32"))]
                    if is_key_pressed(KeyCode::Escape) {
                        std::process::exit(0);
                    }
                    if is_key_pressed(KeyCode::Space) {
                        game_state = GameState::Starting;
                    }
                }
                GameState::Starting => {
                    world.me = 0;
                    ` ./world-reset.sh ${v}reset_ `
                    pawn_sprites.clear();
                    online = false;
                    tick = 0;
                    turn = 0;
                    acc = 0.0;
                    next_send = 0;
                    confirmed.clear();
                    stalled_since = None;
                    game_state = GameState::Playing;
                }
                GameState::Joining => {
                    if !join_sent {
                        let join_url = format!("{}/match", server.clone().unwrap_or_default());
                        ` ${ORC_WS}/snippets/post.sh ${v}join_ `
                        join_post = ${v}join_Post;
                        join_sent = true;
                    }
                    ` ${ORC_WS}/snippets/post-poll.sh ${v}poll_ `
                    if join_post.done {
                        let joined: Result<MatchResp, String> = match &join_post.body {
                            Ok(body) => serde_json::from_str(body).map_err(|e| format!("bad /match reply: {e}")),
                            Err(e) => Err(format!("couldn't join a match: {e}")),
                        };
                        match joined {
                            Ok(joined) => {
                                info!("joined match {} as player {}", joined.match_id, joined.player);
                                let ws_url = format!(
                                    "{}/ws?match={}&player={}",
                                    server.clone().unwrap_or_default(),
                                    joined.match_id,
                                    joined.player
                                );
                                ` ${ORC_WS}/snippets/connect.sh ${v}conn_ `
                                ws = ${v}conn_Ws;
                                // turns can arrive along with "start", so clear them now
                                confirmed.clear();
                                game_state = GameState::Connecting;
                            }
                            Err(reason) => {
                                ended_reason = reason;
                                game_state = GameState::Ended;
                            }
                        }
                    }
                }
                GameState::Ended => {
                    if is_key_pressed(KeyCode::Space) || is_key_pressed(KeyCode::Escape) {
                        game_state = GameState::MainMenu;
                    }
                }
                GameState::Connecting => {}
                GameState::Playing => 'playing: {
                    if is_key_pressed(KeyCode::Escape) {
                        game_state = GameState::Paused;
                        break 'playing; // pause skips this player's input til it resumes
                    }
                    // input only queues orders in world.outbox; the sim applies them on a turn
                    ` ./update-hud.sh ${v}hud_ `
                    ` ./update-placement.sh ${v}place_ `
                    ` ./update-select.sh ${v}select_ `
                    ` ./update-orders.sh ${v}orders_ `
                }
                GameState::Paused => {
                    if is_key_pressed(KeyCode::Space) {
                        game_state = GameState::Playing;
                    }
                    if is_key_pressed(KeyCode::Escape) {
                        // leaving an online match closes the connection
                        #[cfg(not(target_arch = "wasm32"))]
                        {
                            ws.socket = None;
                        }
                        ws.state = 2;
                        online = false;
                        game_state = GameState::MainMenu;
                    }
                }
            }

            // Network: read everything the server sent since the last frame
            let net_active = matches!(game_state, GameState::Connecting)
                || (online && matches!(game_state, GameState::Playing | GameState::Paused));
            if net_active {
                let mut started: Option<(usize, i64)> = None;
                let mut end_reason: Option<String> = None;
                let mut reading = true;
                while reading {
                    ` ${ORC_WS}/snippets/read.sh ${v}rd_ `
                    ` ./net-recv.sh ${v}recv_ `
                    reading = net_text.is_some();
                }
                if let Some((player, seed)) = started {
                    // the match starts: both players build the same world from the seed
                    info!("match started, player {} seed {}", player, seed);
                    world.me = player.min(1);
                    ` ./world-reset.sh ${v}mpreset_ `
                    pawn_sprites.clear();
                    online = true;
                    tick = 0;
                    turn = 0;
                    acc = 0.0;
                    next_send = 0;
                    stalled_since = None;
                    // turns 0..INPUT_DELAY can't hold orders, but the server still
                    // needs them from both players before it releases them
                    let no_cmds: Vec<Command> = vec![];
                    let mut priming = next_send < INPUT_DELAY;
                    while priming {
                        ` ./net-turn-msg.sh ${v}prime_ `
                        ` ${ORC_WS}/snippets/send.sh ${v}psend_ `
                        priming = next_send < INPUT_DELAY;
                    }
                    game_state = GameState::Playing;
                }
                if let Some(reason) = end_reason {
                    ended_reason = format!("The match ended: {reason}");
                    online = false;
                    game_state = GameState::Ended;
                } else if ws.state == 2 {
                    ended_reason = ws.close_reason.clone();
                    online = false;
                    game_state = GameState::Ended;
                }
            }

            // Sim: fixed TICK_SECS steps. At each turn (every TICKS_PER_TURN
            // ticks) apply both players' confirmed orders; online, wait (stall)
            // until the server has sent them.
            let sim_running = matches!(game_state, GameState::Playing)
                || (online && matches!(game_state, GameState::Paused));
            if sim_running {
                acc += t.min(0.25);
                let mut stalled = false;
                let mut ticking = acc >= TICK_SECS;
                while ticking {
                    let at_turn = tick % TICKS_PER_TURN == 0;
                    let turn_now = tick / TICKS_PER_TURN;
                    if at_turn && online && next_send == turn_now + INPUT_DELAY {
                        // this player's orders, to run INPUT_DELAY turns from now
                        ` ./net-turn-msg.sh ${v}msg_ `
                        world.outbox.clear();
                        ` ${ORC_WS}/snippets/send.sh ${v}send_ `
                    }
                    if at_turn && !online {
                        // offline loopback: this player's orders are confirmed at once
                        confirmed.insert(turn_now, [std::mem::take(&mut world.outbox), vec![]]);
                    }
                    if at_turn {
                        match confirmed.remove(&turn_now) {
                            Some(turn_cmds) => {
                                for player in 0..2usize {
                                    ` ./apply-commands.sh ${v}apply_ `
                                }
                                turn = turn_now;
                                if online && turn % 50 == 0 {
                                    ` ./world-checksum.sh ${v}sum_ `
                                    info!("turn {} checksum {:08x}", turn, checksum);
                                }
                            }
                            None => stalled = true,
                        }
                    }
                    if !stalled {
                        ` ./update-units.sh ${v}units_ `
                        tick += 1;
                        acc -= TICK_SECS;
                    }
                    if stalled {
                        acc = acc.min(TICK_SECS);
                    }
                    ticking = !stalled && acc >= TICK_SECS;
                }
                stalled_since = match (stalled, stalled_since) {
                    (true, None) => Some(get_time()),
                    (true, since) => since,
                    (false, _) => None,
                };

                ` ./update-scroll.sh ${v}scroll_ `

                // animate each unit's sprite: run while walking, idle otherwise
                while pawn_sprites.len() < world.units.len() {
                    pawn_sprites.push(AnimatedSprite {
                        w: 192.0,
                        h: 192.0,
                        frame: 0,
                        frame_time: 0.0,
                        animation: &idle_animation,
                        last_animation_id: String::new(),
                        paint_frame: None,
                    });
                }
                for (unit, pawn_sprite) in world.units.iter_mut().zip(pawn_sprites.iter_mut()) {
                    pawn_sprite.animation = if unit.running { &run_animation } else { &idle_animation };
                    pawn_sprite.frame_time += t;
                    ` ${ORC_ANIMATE}/snippets/macroquad/animate-sprite.sh ${v}anim_ `
                    ` ./update-unit-frame.sh ${v}frame_ `
                }
            }

            // Draw
            clear_background(BLACK);
            match game_state {
                GameState::MainMenu => {
                    ` ./draw-ground.sh ${v}ground_ `
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
                    ` ./draw-ground.sh ${v}ground_ `
                    ` ./draw-world.sh ${v}world_ `
                    ` ./draw-placement.sh ${v}ghost_ `
                    ` ./draw-drag-box.sh ${v}dragbox_ `
                    ` ./draw-hud.sh ${v}drawhud_ `
                    ` ./draw-minimap.sh ${v}minimap_ `
                    if online {
                        ` ./world-checksum.sh ${v}sum_ `
                        ` ./draw-net-status.sh ${v}status_ `
                    }
                }
                GameState::Starting | GameState::Joining | GameState::Connecting | GameState::Ended => {
                    let text = match game_state {
                        GameState::Joining => "Joining a match...".to_string(),
                        GameState::Connecting => "Waiting for another player...".to_string(),
                        GameState::Ended => format!("{ended_reason} (Space for the menu)"),
                        _ => String::new(),
                    };
                    let text_dimensions = measure_text(text.as_str(), None, 30, 1.0);
                    draw_text(
                        text.as_str(),
                        screen_width() / 2.0 - text_dimensions.width / 2.0,
                        screen_height() / 2.0,
                        30.0,
                        WHITE,
                    );
                }
            }
            if let GameState::Paused = game_state {
                let text = if online { "Paused (Escape leaves the match)" } else { "Paused" };
                let text_dimensions = measure_text(text, None, 50, 1.0);
                draw_text(
                    text,
                    screen_width() / 2.0 - text_dimensions.width / 2.0,
                    screen_height() / 2.0 - text_dimensions.height / 2.0,
                    50.0,
                    WHITE,
                );
            }

            next_frame().await
        }
    }

EOF
