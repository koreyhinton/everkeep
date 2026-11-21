#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Commands NextSend TurnMsg

cat << EOF

    // this player's commands for turn NextSend, as the lockstep server's
    // "cmds" message. The server needs one every turn, even with no commands.
    let ${!turn_msg} = serde_json::to_string(&CmdsMsg {
        kind: "cmds",
        turn: ${!next_send},
        cmds: &${!commands},
    })
    .unwrap_or_default();
    ${!next_send} += 1;

EOF
