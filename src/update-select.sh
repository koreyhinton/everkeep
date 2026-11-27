#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} DragStart Units Buildings View Me

cat << EOF

    // A left click or drag on the map selects this player's units and
    // buildings; units win, so buildings are only selected when no unit is.
    // - A drag selects everything it touches: units by hitbox, buildings by
    //   their picture.
    // - A click (moving less than DRAG_THRESHOLD) selects the one thing under
    //   the mouse, the one drawn in front (lowest feet), or nothing.
    // A press on the HUD starts neither, so clicking a button keeps the
    // selection.
    if is_mouse_button_pressed(MouseButton::Left) {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        if ${v}mouse_y < screen_height() - HUD_H {
            ${!drag_start} = Some(vec2(${v}mouse_x, ${v}mouse_y));
        }
    }

    if is_mouse_button_released(MouseButton::Left) {
        if let Some(${v}start) = ${!drag_start} {
            let (${v}end_x, ${v}end_y) = mouse_position();
            let ${v}click = vec2(${v}end_x, ${v}end_y).distance(${v}start) < DRAG_THRESHOLD;
            // the drag, and the click's point, in world space
            let ${v}box = Rect::new(
                ${v}start.x.min(${v}end_x) + ${!view}.x,
                ${v}start.y.min(${v}end_y) + ${!view}.y,
                (${v}end_x - ${v}start.x).abs(),
                (${v}end_y - ${v}start.y).abs(),
            );
            let ${v}point = vec2(${v}end_x, ${v}end_y) + ${!view};

            // a click: the unit, else the building, under the point that's
            // drawn in front (on equal feet, the later one draws on top)
            let mut ${v}clicked_unit: Option<u32> = None;
            let mut ${v}clicked_building: Option<u32> = None;
            let mut ${v}front = f32::MIN;
            for ${v}unit in ${!units}.iter() {
                let ${v}rect = Rect::new(
                    ${v}unit.pos.x + ${v}unit.hitbox.x,
                    ${v}unit.pos.y + ${v}unit.hitbox.y,
                    ${v}unit.hitbox.w,
                    ${v}unit.hitbox.h,
                );
                if ${v}unit.owner == ${!me} && ${v}rect.contains(${v}point) && ${v}unit.pos.y >= ${v}front {
                    ${v}clicked_unit = Some(${v}unit.id);
                    ${v}front = ${v}unit.pos.y;
                }
            }
            ${v}front = f32::MIN;
            for ${v}building in ${!buildings}.iter() {
                let ${v}picture = Rect::new(
                    ${v}building.pos.x + HALL_TEXTURE_OFFSET.x,
                    ${v}building.pos.y + HALL_TEXTURE_OFFSET.y,
                    HALL_TEXTURE_SIZE.x,
                    HALL_TEXTURE_SIZE.y,
                );
                if ${v}building.owner == ${!me} && ${v}picture.contains(${v}point) && ${v}building.pos.y >= ${v}front {
                    ${v}clicked_building = Some(${v}building.id);
                    ${v}front = ${v}building.pos.y;
                }
            }

            let mut ${v}any_unit = false;
            for ${v}unit in ${!units}.iter_mut() {
                let ${v}rect = Rect::new(
                    ${v}unit.pos.x + ${v}unit.hitbox.x,
                    ${v}unit.pos.y + ${v}unit.hitbox.y,
                    ${v}unit.hitbox.w,
                    ${v}unit.hitbox.h,
                );
                let ${v}hit = if ${v}click {
                    ${v}clicked_unit == Some(${v}unit.id)
                } else {
                    ${v}box.overlaps(&${v}rect)
                };
                ${v}unit.selected = ${v}unit.owner == ${!me} && ${v}hit;
                ${v}any_unit = ${v}any_unit || ${v}unit.selected;
            }

            for ${v}building in ${!buildings}.iter_mut() {
                let ${v}picture = Rect::new(
                    ${v}building.pos.x + HALL_TEXTURE_OFFSET.x,
                    ${v}building.pos.y + HALL_TEXTURE_OFFSET.y,
                    HALL_TEXTURE_SIZE.x,
                    HALL_TEXTURE_SIZE.y,
                );
                let ${v}hit = if ${v}click {
                    ${v}clicked_building == Some(${v}building.id)
                } else {
                    ${v}box.overlaps(&${v}picture)
                };
                ${v}building.selected = !${v}any_unit && ${v}building.owner == ${!me} && ${v}hit;
            }

            ${!drag_start} = None;
        }
    }

EOF
