#!/usr/bin/env bash

lcm() {
    _gcd() {
        if (( $1 % $2 == 0 )); then
            printf '%d\n' "${2}"
            return
        fi
        _gcd "${2}" "$(( $1 % $2 ))"
    }

    (( $# > 1 )) || return 1
    local -i g l
    l="${1}"
    shift
    while (( $# > 0 )); do
        g="$(_gcd "${l}" "${1}")"
        l="$(( (l * $1) / g ))"
        shift
    done
    printf '%d\n' "${l}"
    return 0
}
