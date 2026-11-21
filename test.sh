#!/bin/bash

# Generates main.rs (build.sh) and the tests, then runs cargo test.
# The tests are generated like main.rs: tests/*.test.sh print tests/*.rs.

cd "$(dirname "$0")" || exit 1

./build.sh || exit 1

. ./orc-env.sh

set -o pipefail

for f in ./tests/*.test.sh; do
    name=$(basename "$f" .test.sh)
    "$f" > "./tests/${name//-/_}.rs" || exit 1
done

cargo test
