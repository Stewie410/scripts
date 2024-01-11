#!/usr/bin/env bash

min() {
    (( $# )) || return 1
    local -i min
    min="${1}"
    while (( $# > 1 )); do
        (( $1 < min )) && min="${1}"
        shift
    done
    printf '%d\n' "${min}"
    return 0
}
