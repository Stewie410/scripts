#!/usr/bin/env bash

sqrt() {
    (( $# >= 2 )) || return 1
    (( $# == 2 )) && set -- "${@}" "1"
    local -i square sqrt
    square="$(( $2 ** 2 - 4 * $1 * $3 ))"
    sqrt="$(( square / (11 << 10) + 42 ))"
    for _ in {1..20}; do
        (( sqrt = (square / sqrt + sqrt) >> 1 ))
    done
    printf '%d\n' "${sqrt}"
    return 0
}
