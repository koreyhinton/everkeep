#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Resources

cat << EOF

    let ${v}ResCo = ResourceCoroutines {
        ship_co: start_coroutine(load_texture("ship.png")),
        bullet_co: start_coroutine(load_texture("laser-bolts.png")),
        explosion_co: start_coroutine(load_texture("explosion.png")),
        enemy_small_co: start_coroutine(load_texture("enemy-small.png")),
        theme_music_co: start_coroutine(load_sound("8bit-spaceshooter.ogg")),
        sound_explosion_co: start_coroutine(load_sound("explosion.wav")),
        sound_laser_co: start_coroutine(load_sound("laser.wav")),
        window_background_co: start_coroutine(load_image("window_background.png")),
        button_background_co: start_coroutine(load_image("button_background.png")),
        button_clicked_background_co: start_coroutine(load_image(
            "button_clicked_background.png"
        )),
        font_co: start_coroutine(load_file("atari_games.ttf")),
    };

    let ${v}load_start = get_time();
    loop {
        if (!FORCE_VISIBLE_LOAD_SCREEN || get_time() - ${v}load_start >= 2.0)
            && ${v}ResCo.ship_co.is_done()
            && ${v}ResCo.bullet_co.is_done()
            && ${v}ResCo.explosion_co.is_done()
            && ${v}ResCo.enemy_small_co.is_done()
            && ${v}ResCo.theme_music_co.is_done()
            && ${v}ResCo.sound_explosion_co.is_done()
            && ${v}ResCo.sound_laser_co.is_done()
            && ${v}ResCo.window_background_co.is_done()
            && ${v}ResCo.button_background_co.is_done()
            && ${v}ResCo.button_clicked_background_co.is_done()
            && ${v}ResCo.font_co.is_done()
        {
            break;
        }

        clear_background(BLACK);
        let ${v}cx = screen_width() / 2.0;
        let ${v}cy = screen_height() / 2.0;
        let ${v}p = ((get_time() % 1.6) / 1.6) as f32; // 0..1 over 1.6 s
        let (${v}start, ${v}arc) = if ${v}p < 0.5 {
            (0.0, ${v}p * 2.0 * 360.0) // filling: front edge sweeps
        } else {
            let ${v}e = (${v}p - 0.5) * 2.0 * 360.0;
            (${v}e, 360.0 - ${v}e) // emptying: back edge chases
        };
        draw_circle(${v}cx, ${v}cy, 24.0, Color::new(1.0, 1.0, 1.0, 0.15)); // faint track
        draw_arc(${v}cx, ${v}cy, 64, 0.0, -90.0 + ${v}start, 24.0, ${v}arc, WHITE);
        next_frame().await;
    }

    let ${v}window_background = ${v}ResCo.window_background_co.retrieve().unwrap()?;
    let ${v}button_background = ${v}ResCo.button_background_co.retrieve().unwrap()?;
    let ${v}button_clicked_background =
        ${v}ResCo.button_clicked_background_co.retrieve().unwrap()?;
    let ${v}font = ${v}ResCo.font_co.retrieve().unwrap()?;

    let ${v}window_style = root_ui()
        .style_builder()
        .background(${v}window_background)
        .background_margin(RectOffset::new(32.0, 76.0, 44.0, 20.0))
        .margin(RectOffset::new(0.0, -40.0, 0.0, 0.0))
        .build();
    let ${v}button_style = root_ui()
        .style_builder()
        .background(${v}button_background)
        .background_clicked(${v}button_clicked_background)
        .background_margin(RectOffset::new(16.0, 16.0, 16.0, 16.0))
        .margin(RectOffset::new(16.0, 0.0, -8.0, -8.0))
        .font(&${v}font)?
        .text_color(WHITE)
        .font_size(64)
        .build();
    let ${v}label_style = root_ui()
        .style_builder()
        .font(&${v}font)?
        .text_color(WHITE)
        .font_size(28)
        .build();

    let ${!resources} = Resources {
        ship_texture: ${v}ResCo.ship_co.retrieve().unwrap()?,
        bullet_texture: ${v}ResCo.bullet_co.retrieve().unwrap()?,
        explosion_texture: ${v}ResCo.explosion_co.retrieve().unwrap()?,
        enemy_small_texture: ${v}ResCo.enemy_small_co.retrieve().unwrap()?,
        theme_music: ${v}ResCo.theme_music_co.retrieve().unwrap()?,
        sound_explosion: ${v}ResCo.sound_explosion_co.retrieve().unwrap()?,
        sound_laser: ${v}ResCo.sound_laser_co.retrieve().unwrap()?,
        ui_skin: Skin {
            window_style: ${v}window_style,
            button_style: ${v}button_style,
            label_style: ${v}label_style,
            ..root_ui().default_skin()
        },
    };

    ${!resources}.ship_texture.set_filter(FilterMode::Nearest);
    ${!resources}.bullet_texture.set_filter(FilterMode::Nearest);
    ${!resources}.explosion_texture.set_filter(FilterMode::Nearest);
    ${!resources}.enemy_small_texture.set_filter(FilterMode::Nearest);

    build_textures_atlas();

EOF
