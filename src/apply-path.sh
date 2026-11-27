#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Unit Cells Found Grid

cat << EOF

    // A sim step: give a unit the path find-path found for it (Cells, from
    // its cell toward its target's). Cells become waypoints at their
    // centers. If the target was reached, the last one is the target itself;
    // if not (it's in the trees or under a hall), the target becomes the
    // nearest reachable cell's center. Then the path is straightened: from
    // each point it heads for the farthest later one it can walk to in a
    // straight line without crossing a blocked cell, so units cut across
    // open ground instead of stepping through cell centers.
    let mut ${v}points: Vec<Vec2> = ${!cells}
        .iter()
        .map(|cell| vec2((cell.0 as f32 + 0.5) * CELL, (cell.1 as f32 + 0.5) * CELL))
        .collect();
    if ${!found} && !${v}points.is_empty() {
        ${v}points.pop();
        ${v}points.push(${!unit}.target);
    }
    if !${!found} {
        ${!unit}.target = ${v}points.last().copied().unwrap_or(${!unit}.pos);
    }

    let mut ${v}path: Vec<Vec2> = vec![];
    let mut ${v}from = ${!unit}.pos;
    let mut ${v}next = 0;
    while ${v}next < ${v}points.len() {
        // the farthest point after next with a clear line from 'from'
        let mut ${v}far = ${v}next;
        let mut ${v}try = ${v}next + 1;
        let mut ${v}scanning = true;
        while ${v}scanning && ${v}try < ${v}points.len() {
            // check the line every quarter cell
            let ${v}to = ${v}points[${v}try];
            let ${v}steps = ((${v}to - ${v}from).length() / (CELL / 4.0)).ceil().max(1.0) as usize;
            let mut ${v}clear = true;
            for ${v}s in 0..=${v}steps {
                let ${v}p = ${v}from + (${v}to - ${v}from) * (${v}s as f32 / ${v}steps as f32);
                let ${v}cx = (${v}p.x / CELL).floor();
                let ${v}cy = (${v}p.y / CELL).floor();
                let ${v}inside = ${v}cx >= 0.0
                    && ${v}cy >= 0.0
                    && (${v}cx as usize) < ${!grid}.w
                    && (${v}cy as usize) < ${!grid}.h;
                ${v}clear = ${v}clear
                    && ${v}inside
                    && !${!grid}.blocked[${v}cy as usize * ${!grid}.w + ${v}cx as usize];
            }
            if ${v}clear {
                ${v}far = ${v}try;
                ${v}try += 1;
            } else {
                ${v}scanning = false;
            }
        }
        ${v}path.push(${v}points[${v}far]);
        ${v}from = ${v}points[${v}far];
        ${v}next = ${v}far + 1;
    }
    // the last point is the target: the path is the waypoints before it
    ${v}path.pop();
    ${!unit}.path = ${v}path;
    ${!unit}.repath = false;

EOF
