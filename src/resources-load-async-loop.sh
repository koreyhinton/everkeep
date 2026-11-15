#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Resources

cat << EOF

    let ${v}ResCo = ResourceCoroutines {
        pawn_idle_co: start_coroutine(load_texture("Units/Blue Units/Pawn/Pawn_Idle.png")),
        pawn_run_co: start_coroutine(load_texture("Units/Blue Units/Pawn/Pawn_Run.png")),
        house_co: start_coroutine(load_texture("Buildings/Blue Buildings/House1.png")),
        grass_co: start_coroutine(load_texture("Terrain/Tileset/Tilemap_color1.png")),
        dust_co: start_coroutine(load_texture("Particle FX/Dust_01.png")),
    };

    let ${v}load_start = get_time();
    loop {
        if (!FORCE_VISIBLE_LOAD_SCREEN || get_time() - ${v}load_start >= 2.0)
            && ${v}ResCo.pawn_idle_co.is_done()
            && ${v}ResCo.pawn_run_co.is_done()
            && ${v}ResCo.house_co.is_done()
            && ${v}ResCo.grass_co.is_done()
            && ${v}ResCo.dust_co.is_done()
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

    // Tiny Swords has no font, and its UI panels are 9-slice pieces with gaps,
    // so the menu uses plain colors from its palette and macroquad's default font
    let ${v}paper = Color::from_rgba(239, 225, 197, 255);
    let ${v}ink = Color::from_rgba(60, 50, 40, 255);
    let ${v}teal = Color::from_rgba(70, 145, 155, 255);
    let ${v}window_style = root_ui()
        .style_builder()
        .color(${v}paper)
        .build();
    let ${v}button_style = root_ui()
        .style_builder()
        .color(${v}teal)
        .color_hovered(Color::from_rgba(90, 170, 180, 255))
        .color_clicked(Color::from_rgba(45, 105, 115, 255))
        .margin(RectOffset::new(24.0, 24.0, 10.0, 10.0))
        .text_color(WHITE)
        .font_size(48)
        .build();
    let ${v}label_style = root_ui()
        .style_builder()
        .text_color(${v}ink)
        .font_size(40)
        .build();

    let ${!resources} = Resources {
        pawn_idle_texture: ${v}ResCo.pawn_idle_co.retrieve().unwrap()?,
        pawn_run_texture: ${v}ResCo.pawn_run_co.retrieve().unwrap()?,
        house_texture: ${v}ResCo.house_co.retrieve().unwrap()?,
        grass_texture: ${v}ResCo.grass_co.retrieve().unwrap()?,
        dust_texture: ${v}ResCo.dust_co.retrieve().unwrap()?,
        ui_skin: Skin {
            window_style: ${v}window_style,
            button_style: ${v}button_style,
            label_style: ${v}label_style,
            ..root_ui().default_skin()
        },
    };

    ${!resources}.pawn_idle_texture.set_filter(FilterMode::Nearest);
    ${!resources}.pawn_run_texture.set_filter(FilterMode::Nearest);
    ${!resources}.house_texture.set_filter(FilterMode::Nearest);
    ${!resources}.grass_texture.set_filter(FilterMode::Nearest);
    ${!resources}.dust_texture.set_filter(FilterMode::Nearest);

    // no build_textures_atlas(): with these large sprite sheets it stopped the
    // macroquad UI menu from drawing, and this game draws few enough sprites without it

EOF
