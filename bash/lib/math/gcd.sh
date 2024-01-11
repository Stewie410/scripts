#!/usr/bin/env bash

gcd() {
    (( $# > 1 )) || return 1
    local -i a b c
    a="${1}"
    shift
    while (( $# > 0 )); do
        b="${1}"
        until (( a % b == 0 )); do
            (( c = a, a = b, b = c % b ))
        done
        shift
    done
    printf '%d\n' "${b}"
    return 0
}
