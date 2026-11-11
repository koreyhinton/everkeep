#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Vel T D Dir

cat << EOF

    ${!d} += ${!dir} * (${!vel} * ${!t});

EOF
