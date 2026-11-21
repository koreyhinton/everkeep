#!/bin/bash

cd "$(dirname "$0")" || exit 1

orc=$(realpath ../orc/)
nsmap="${orc}/lib/src/main/bash/com/koreyhinton/nsmap"
export NSMAP="$nsmap"
export ORC_ANIMATE="${orc}/lib/src/templates/rust/com/koreyhinton/animation"
# A missing snippet fails inside main.sh's backticks without stopping the build.

set -o pipefail

cd ./src
# Write to a temp file so a failed format doesn't wipe the last good main.rs.
./main.sh | rustfmt --edition 2024 > ./main.rs.tmp && mv ./main.rs.tmp ./main.rs
cd - 1>/dev/null
