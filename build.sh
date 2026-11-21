#!/bin/bash

cd "$(dirname "$0")" || exit 1

. ./orc-env.sh
# A missing snippet fails inside main.sh's backticks without stopping the build.

set -o pipefail

cd ./src
# Write to a temp file so a failed format doesn't wipe the last good main.rs.
# Exit 1 if main.sh or rustfmt fails (such as an orc version mismatch).
./main.sh | rustfmt --edition 2024 > ./main.rs.tmp && mv ./main.rs.tmp ./main.rs || exit 1
cd - 1>/dev/null
