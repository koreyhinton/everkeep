#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Text Confirmed Started EndReason

cat << EOF

    // one message from the lockstep server (Text: Option<String>, from orc
    // ws read.sh): "start" gives this player's index and the shared seed,
    // "turn" both players' commands for a turn, and "end" why the match ended
    if let Some(${v}text) = ${!text}.as_ref() {
        match serde_json::from_str::<ServerMsg>(${v}text) {
            Err(${v}e) => {
                warn!("bad message from server: {}", ${v}e);
            }
            Ok(${v}msg) => {
                if ${v}msg.kind == "start" {
                    ${!started} = Some((${v}msg.player, ${v}msg.seed));
                }
                if ${v}msg.kind == "turn" {
                    // skip a command this version doesn't know, not the turn
                    let mut ${v}all: [Vec<Command>; 2] = [vec![], vec![]];
                    for (${v}player, ${v}cmds) in ${v}msg.all.iter().enumerate() {
                        for ${v}cmd in ${v}cmds.iter().flatten() {
                            if let Ok(${v}cmd) = serde_json::from_value::<Command>(${v}cmd.clone()) {
                                ${v}all[${v}player].push(${v}cmd);
                            }
                        }
                    }
                    ${!confirmed}.insert(${v}msg.turn, ${v}all);
                }
                if ${v}msg.kind == "end" {
                    ${!end_reason} = Some(${v}msg.reason);
                }
            }
        }
    }

EOF
