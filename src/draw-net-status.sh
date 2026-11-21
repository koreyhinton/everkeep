#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Me Turn Checksum StalledSince

cat << EOF

    // online: who this player is, the turn, and the sim's checksum (both
    // players' should match), and a note while waiting on the other player
    let ${v}color = if ${!me} == 0 { "blue" } else { "red" };
    draw_text(
        format!("Player {} ({})   turn {}   checksum {:08x}", ${!me}, ${v}color, ${!turn}, ${!checksum}).as_str(),
        10.0,
        24.0,
        22.0,
        WHITE,
    );
    if let Some(${v}since) = ${!stalled_since} {
        if get_time() - ${v}since > 0.5 {
            draw_text("Waiting for the other player...", 10.0, 50.0, 22.0, YELLOW);
        }
    }

EOF
