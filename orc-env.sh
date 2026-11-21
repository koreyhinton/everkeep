#!/bin/bash

# orc paths and library versions, shared by build.sh and test.sh. Source it:
#     . ./orc-env.sh
# It expects orc cloned next to this repo (../orc). Bump a version here when
# moving to a newer orc library; its models.sh fails on any other version.

orc=$(realpath "$(dirname "${BASH_SOURCE[0]}")/../orc")
export NSMAP="${orc}/lib/src/main/bash/com/koreyhinton/nsmap"
export ORC_ANIMATE="${orc}/lib/src/templates/rust/com/koreyhinton/animation"
export ORC_ANIMATE_VERSION="0.1.0"
