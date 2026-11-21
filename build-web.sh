#!/bin/bash

# Builds the browser version next to index.html: everkeep.wasm, and orc ws's
# browser plugin (orc_ws.js), which multiplayer uses for its websocket.
# Serve this folder with:  python3 -m http.server

cd "$(dirname "$0")" || exit 1

. ./orc-env.sh

./build.sh || exit 1
cargo build --release --target wasm32-unknown-unknown || exit 1
cp target/wasm32-unknown-unknown/release/everkeep.wasm . || exit 1
cp "${ORC_WS}/js/orc_ws.js" . || exit 1

echo "Built everkeep.wasm. Serve it with: python3 -m http.server"
