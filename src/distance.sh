#!/bin/bash

v=$1
# maps
. ${NSMAP}/bind ${v} Vel T D

cat << EOF

    ${!d} += ${!vel} * ${!t};

EOF
