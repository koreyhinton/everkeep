#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Units Buildings Me Explored Light

cat << EOF

    // This player's fog of war, every frame (local: never part of the sim).
    // Each of this player's units (from its feet) and buildings (from its
    // footprint) lights the fog cells around it: fully within SIGHT_RANGE,
    // less FOG_FADE / 2, fading to none at SIGHT_RANGE + FOG_FADE / 2. Light
    // (a Vec<f32>, declared by the caller) is refilled with each cell's
    // light, 0 to 1. A lit cell becomes
    // Explored for good. A rival building in sight (within SIGHT_RANGE of a
    // unit or building, as update-objectives.sh measures it) becomes seen,
    // and stays drawn from then on.
    ${!light}.clear();
    ${!light}.resize(FOG_W * FOG_H, 0.0);
    let mut ${v}eyes: Vec<Rect> = vec![];
    for ${v}unit in ${!units}.iter() {
        if ${v}unit.owner == ${!me} {
            ${v}eyes.push(Rect::new(${v}unit.pos.x, ${v}unit.pos.y, 0.0, 0.0));
        }
    }
    for ${v}building in ${!buildings}.iter() {
        if ${v}building.owner == ${!me} {
            ${v}eyes.push(Rect::new(
                ${v}building.pos.x + ${v}building.hitbox.x,
                ${v}building.pos.y + ${v}building.hitbox.y,
                ${v}building.hitbox.w,
                ${v}building.hitbox.h,
            ));
        }
    }
    let ${v}reach = SIGHT_RANGE + FOG_FADE / 2.0;
    for ${v}eye in ${v}eyes.iter() {
        let ${v}x0 = ((${v}eye.x - ${v}reach) / FOG_CELL).floor().max(0.0) as usize;
        let ${v}y0 = ((${v}eye.y - ${v}reach) / FOG_CELL).floor().max(0.0) as usize;
        let ${v}x1 = (((${v}eye.right() + ${v}reach) / FOG_CELL).ceil().max(0.0) as usize).min(FOG_W);
        let ${v}y1 = (((${v}eye.bottom() + ${v}reach) / FOG_CELL).ceil().max(0.0) as usize).min(FOG_H);
        for ${v}cy in ${v}y0..${v}y1 {
            for ${v}cx in ${v}x0..${v}x1 {
                let ${v}center = vec2((${v}cx as f32 + 0.5) * FOG_CELL, (${v}cy as f32 + 0.5) * FOG_CELL);
                let ${v}near = ${v}center.clamp(${v}eye.point(), ${v}eye.point() + ${v}eye.size());
                let ${v}lit = ((${v}reach - ${v}center.distance(${v}near)) / FOG_FADE).clamp(0.0, 1.0);
                let ${v}i = ${v}cy * FOG_W + ${v}cx;
                ${!light}[${v}i] = ${!light}[${v}i].max(${v}lit);
            }
        }
    }
    for (${v}cell, ${v}lit) in ${!explored}.iter_mut().zip(${!light}.iter()) {
        *${v}cell = *${v}cell || *${v}lit > 0.0;
    }
    for ${v}building in ${!buildings}.iter_mut() {
        let ${v}rect = Rect::new(
            ${v}building.pos.x + ${v}building.hitbox.x,
            ${v}building.pos.y + ${v}building.hitbox.y,
            ${v}building.hitbox.w,
            ${v}building.hitbox.h,
        );
        // the gap between the eye's rect and the building's, 0 if they touch
        let ${v}in_sight = ${v}eyes.iter().any(|eye| {
            let dx = (eye.x - ${v}rect.right()).max(${v}rect.x - eye.right()).max(0.0);
            let dy = (eye.y - ${v}rect.bottom()).max(${v}rect.y - eye.bottom()).max(0.0);
            vec2(dx, dy).length() <= SIGHT_RANGE
        });
        ${v}building.seen = ${v}building.seen || ${v}building.owner == ${!me} || ${v}in_sight;
    }

EOF
