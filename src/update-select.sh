#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} DragStart Units Buildings View Me

cat << EOF

    // a left drag on the map selects this player's units it encloses, or, if
    // it encloses none, their buildings. A press on the HUD starts no drag,
    // so clicking a button keeps the selection.
    if is_mouse_button_pressed(MouseButton::Left) {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        if ${v}mouse_y < screen_height() - HUD_H {
            ${!drag_start} = Some(vec2(${v}mouse_x, ${v}mouse_y));
        }
    }

    if is_mouse_button_released(MouseButton::Left) {
        if let Some(${v}start) = ${!drag_start} {
            let (${v}end_x, ${v}end_y) = mouse_position();
            // the drag in world space
            let ${v}box = Rect::new(
                ${v}start.x.min(${v}end_x) + ${!view}.x,
                ${v}start.y.min(${v}end_y) + ${!view}.y,
                (${v}end_x - ${v}start.x).abs(),
                (${v}end_y - ${v}start.y).abs(),
            );

            let mut ${v}any_unit = false;
            for ${v}unit in ${!units}.iter_mut() {
                let ${v}rect = Rect::new(
                    ${v}unit.pos.x + ${v}unit.hitbox.x,
                    ${v}unit.pos.y + ${v}unit.hitbox.y,
                    ${v}unit.hitbox.w,
                    ${v}unit.hitbox.h,
                );
                ${v}unit.selected = ${v}unit.owner == ${!me}
                    && ${v}box.left() <= ${v}rect.left()
                    && ${v}box.top() <= ${v}rect.top()
                    && ${v}box.right() >= ${v}rect.right()
                    && ${v}box.bottom() >= ${v}rect.bottom();
                ${v}any_unit = ${v}any_unit || ${v}unit.selected;
            }

            // units win: buildings are only selected when no unit is
            for ${v}building in ${!buildings}.iter_mut() {
                let ${v}rect = Rect::new(
                    ${v}building.pos.x + ${v}building.hitbox.x,
                    ${v}building.pos.y + ${v}building.hitbox.y,
                    ${v}building.hitbox.w,
                    ${v}building.hitbox.h,
                );
                ${v}building.selected = !${v}any_unit
                    && ${v}building.owner == ${!me}
                    && ${v}box.left() <= ${v}rect.left()
                    && ${v}box.top() <= ${v}rect.top()
                    && ${v}box.right() >= ${v}rect.right()
                    && ${v}box.bottom() >= ${v}rect.bottom();
            }

            ${!drag_start} = None;
        }
    }

EOF
