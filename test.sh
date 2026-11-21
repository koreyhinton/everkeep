#!/bin/bash

# Generates main.rs (build.sh) and the tests, then runs cargo test.
# The tests are generated like main.rs: tests/*.test.sh print tests/*.rs.

cd "$(dirname "$0")" || exit 1

./build.sh || exit 1

orc=$(realpath ../orc/)
export NSMAP="${orc}/lib/src/main/bash/com/koreyhinton/nsmap"
export ORC_ANIMATE="${orc}/lib/src/templates/rust/com/koreyhinton/animation"

set -o pipefail

for f in ./tests/*.test.sh; do
    name=$(basename "$f" .test.sh)
    "$f" > "./tests/${name//-/_}.rs" || exit 1
done

cargo test
