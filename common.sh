#!/bin/bash

verbose=0

DIE() {
    echo "ERROR: $*" >&2
    exit 1
}

LOG() {
    local level=$1
    shift

    if [[ $verbose -gt $level ]]; then
        echo "${0##*/}: $*" >&2
    fi
}

set -eu
