#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Objectives MapName

cat << EOF

    // the quest bubble in the top-right: one row per objective, with a box
    // that's checked (and the text greyed) once this player has done it,
    // under the map's name
    let ${v}size = 22.0;
    let ${v}row_h = 30.0;
    let ${v}pad = 12.0;
    let ${v}box_w = 16.0;
    let mut ${v}text_w = measure_text("Objectives", None, ${v}size as u16, 1.0).width;
    for (_, ${v}label) in OBJECTIVES.iter() {
        ${v}text_w = ${v}text_w.max(measure_text(${v}label, None, ${v}size as u16, 1.0).width);
    }
    let ${v}w = ${v}pad * 3.0 + ${v}box_w + ${v}text_w;
    let ${v}h = ${v}pad * 2.0 + ${v}row_h * (OBJECTIVES.len() + 1) as f32;
    // below the online status line, clear of the screen's right edge
    let ${v}left = screen_width() - ${v}w - 10.0;
    let ${v}top = 64.0;
    // the map's name, right-aligned just above the bubble
    let ${v}name_w = measure_text(${!map_name}, None, 26, 1.0).width;
    draw_text(${!map_name}, ${v}left + ${v}w - ${v}name_w, ${v}top - 10.0, 26.0, WHITE);
    draw_rectangle(${v}left, ${v}top, ${v}w, ${v}h, Color::from_rgba(40, 34, 28, 200));
    draw_rectangle_lines(${v}left, ${v}top, ${v}w, ${v}h, 2.0, Color::from_rgba(255, 210, 80, 255));
    draw_text("Objectives", ${v}left + ${v}pad, ${v}top + ${v}pad + 20.0, ${v}size, Color::from_rgba(255, 210, 80, 255));
    for (${v}i, (${v}bit, ${v}label)) in OBJECTIVES.iter().enumerate() {
        let ${v}done = ${!objectives} & ${v}bit != 0;
        let ${v}y = ${v}top + ${v}pad + ${v}row_h * (${v}i + 1) as f32;
        let ${v}bx = ${v}left + ${v}pad;
        let ${v}by = ${v}y + 6.0;
        draw_rectangle_lines(${v}bx, ${v}by, ${v}box_w, ${v}box_w, 2.0, WHITE);
        if ${v}done {
            // a check mark
            let ${v}green = Color::from_rgba(110, 220, 110, 255);
            draw_line(${v}bx + 3.0, ${v}by + 8.0, ${v}bx + 7.0, ${v}by + 13.0, 3.0, ${v}green);
            draw_line(${v}bx + 7.0, ${v}by + 13.0, ${v}bx + 15.0, ${v}by + 1.0, 3.0, ${v}green);
        }
        let ${v}color = if ${v}done { GRAY } else { WHITE };
        draw_text(${v}label, ${v}bx + ${v}box_w + ${v}pad, ${v}y + 20.0, ${v}size, ${v}color);
    }

EOF
