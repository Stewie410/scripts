#!/usr/bin/env bash

max() {
    (( $# )) || return 1
    local -i max
    max="${1}"
    while (( $# > 0 )); do
        (( $1 > max )) && max="${1}"
        shift
    done
    printf '%d\n' "${max}"
    return 0
}
