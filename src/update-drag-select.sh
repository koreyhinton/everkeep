#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} DragStart Unit Houses

cat << EOF

    if is_mouse_button_pressed(MouseButton::Left) {
        let (${v}mouse_x, ${v}mouse_y) = mouse_position();
        ${!drag_start} = Some(vec2(${v}mouse_x, ${v}mouse_y));
    }

    // a release with no drag start (such as the menu's Play click) does nothing
    if is_mouse_button_released(MouseButton::Left) {
        if let Some(${v}start) = ${!drag_start} {
            let (${v}end_x, ${v}end_y) = mouse_position();
            let ${v}box = Rect::new(
                ${v}start.x.min(${v}end_x),
                ${v}start.y.min(${v}end_y),
                (${v}end_x - ${v}start.x).abs(),
                (${v}end_y - ${v}start.y).abs(),
            );

            // the unit wins: houses are only selected when no unit is
            ${!unit}.selected = false;
            let ${v}unit_rect = Rect::new(
                ${!unit}.pos.x + ${!unit}.hitbox.x,
                ${!unit}.pos.y + ${!unit}.hitbox.y,
                ${!unit}.hitbox.w,
                ${!unit}.hitbox.h,
            );
            if ${v}box.left() <= ${v}unit_rect.left()
                && ${v}box.top() <= ${v}unit_rect.top()
                && ${v}box.right() >= ${v}unit_rect.right()
                && ${v}box.bottom() >= ${v}unit_rect.bottom()
            {
                ${!unit}.selected = true;
            }

            for ${v}house in ${!houses}.iter_mut() {
                ${v}house.selected = false;
                if ${!unit}.selected {
                    continue;
                }
                let ${v}house_rect = Rect::new(
                    ${v}house.pos.x + ${v}house.hitbox.x,
                    ${v}house.pos.y + ${v}house.hitbox.y,
                    ${v}house.hitbox.w,
                    ${v}house.hitbox.h,
                );
                if ${v}box.left() <= ${v}house_rect.left()
                    && ${v}box.top() <= ${v}house_rect.top()
                    && ${v}box.right() >= ${v}house_rect.right()
                    && ${v}box.bottom() >= ${v}house_rect.bottom()
                {
                    ${v}house.selected = true;
                }
            }

            ${!drag_start} = None;
        }
    }

EOF
