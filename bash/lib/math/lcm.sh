#!/usr/bin/env bash

lcm() {
    (( $# > 1 )) || return 1
    declare -f gcd &>/dev/null || source "${BASH_LIB}/math/gcd.sh"
    local -i g l
    l="${1}"
    shift
    while (( $# > 0 )); do
        g="$(gcd "${l}" "${1}")"
        l="$(( (l * $1) / g ))"
        shift
    done
    printf '%d\n' "${l}"
    return 0
}
