#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units Buildings Gold Placing Me BuildButton TrainButton

cat << EOF

    // the HUD strip: gold, what's selected, and the buttons (a button's
    // label sits inside its rect, so clicking the label clicks the button)
    let ${v}top = screen_height() - HUD_H;
    draw_rectangle(0.0, ${v}top, screen_width(), HUD_H, Color::from_rgba(40, 34, 28, 235));
    // right of the minimap
    let ${v}left = 8.0 + (HUD_H - 16.0) * WORLD_W / WORLD_H + 20.0;
    draw_text(
        format!("Gold: {}", ${!gold}).as_str(),
        ${v}left,
        ${v}top + 34.0,
        30.0,
        Color::from_rgba(255, 210, 80, 255),
    );

    let ${v}pawns = ${!units}.iter().filter(|unit| unit.selected && unit.owner == ${!me}).count();
    let ${v}hall = ${!buildings}
        .iter()
        .any(|building| building.selected && building.owner == ${!me} && building.kind == BuildingKind::MainHall);
    let ${v}summary = if ${v}pawns == 1 {
        "1 Pawn".to_string()
    } else if ${v}pawns > 1 {
        format!("{} Pawns", ${v}pawns)
    } else if ${v}hall {
        "Main Hall".to_string()
    } else {
        "Nothing selected".to_string()
    };
    draw_text(${v}summary.as_str(), ${v}left, ${v}top + 66.0, 26.0, WHITE);
    if ${!placing}.is_some() {
        draw_text("Click to place the hall, right-click to cancel", ${v}left, ${v}top + 96.0, 20.0, LIGHTGRAY);
    }

    // buttons: (rect, label, shown, can afford)
    let ${v}buttons = [
        (${!build_button}, "Build Main Hall", true, ${!gold} >= HALL_COST && ${!placing}.is_none()),
        (${!train_button}, "Train Pawn", ${v}hall, ${!gold} >= PAWN_COST),
    ];
    for (${v}rect, ${v}label, ${v}shown, ${v}enabled) in ${v}buttons {
        if ${v}shown {
            let ${v}color = if ${v}enabled {
                Color::from_rgba(70, 145, 155, 255)
            } else {
                Color::from_rgba(90, 90, 90, 255)
            };
            draw_rectangle(${v}rect.x, ${v}rect.y, ${v}rect.w, ${v}rect.h, ${v}color);
            let ${v}dims = measure_text(${v}label, None, 26, 1.0);
            draw_text(
                ${v}label,
                ${v}rect.x + (${v}rect.w - ${v}dims.width) / 2.0,
                ${v}rect.y + (${v}rect.h - ${v}dims.height) / 2.0 + ${v}dims.offset_y,
                26.0,
                WHITE,
            );
        }
    }

EOF
