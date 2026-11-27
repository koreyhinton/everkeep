#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} World Checksum

cat << EOF

    // FNV-1a hash of the sim state (not selection or view). Every player's
    // should match on the same turn; if they differ, the game has desynced.
    let mut ${!checksum}: u32 = 0x811c9dc5;
    let mut ${v}words: Vec<u32> = vec![
        ${!world}.gold[0],
        ${!world}.gold[1],
        ${!world}.next_id,
        ${!world}.objectives[0],
        ${!world}.objectives[1],
    ];
    for ${v}unit in ${!world}.units.iter() {
        ${v}words.extend([
            ${v}unit.id,
            ${v}unit.owner as u32,
            ${v}unit.pos.x.to_bits(),
            ${v}unit.pos.y.to_bits(),
            ${v}unit.target.x.to_bits(),
            ${v}unit.target.y.to_bits(),
            ${v}unit.path.len() as u32,
        ]);
        for ${v}point in ${v}unit.path.iter() {
            ${v}words.extend([${v}point.x.to_bits(), ${v}point.y.to_bits()]);
        }
    }
    for ${v}building in ${!world}.buildings.iter() {
        ${v}words.extend([
            ${v}building.id,
            ${v}building.owner as u32,
            ${v}building.pos.x.to_bits(),
            ${v}building.pos.y.to_bits(),
        ]);
    }
    for ${v}word in ${v}words {
        for ${v}byte in ${v}word.to_le_bytes() {
            ${!checksum} = (${!checksum} ^ ${v}byte as u32).wrapping_mul(0x01000193);
        }
    }

EOF
