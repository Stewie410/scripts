#!/usr/bin/env bash

# calcuate greatest common denominator
# @usage: math.gcd NUMBER NUMBER [...]
math.gcd() {
    local -i a b c
    a="${1}"
    shift

    while (( $# > 0 )); do
        b="${1}"
        until (( a % b == 0 )); do
            c="${a}"
            a="${b}"
            (( b = c % b ))
        done
    done

    printf '%d\n' "${b}"
}

# calculate lowest common multiple
# @usage: math.lcm NUMBER NUMBER [...]
math.lcm() {
    local -i g l
    l="${1}"
    shift

    while (( $# > 0 )); do
        g="$(math.gcd "${l}" "${1}")"
        (( l = (l * ${1}) / g ))
        shift
    done

    printf '%d\n' "${l}"
}

# get highest value from list of numbers
# @usage: math.max NUMBER [...]
math.max() {
    local -i m
    m="${1}"
    shift

    while (( $# > 0 )); do
        (( m = ${1} > m ? ${1} : m ))
        shift
    done

    printf '%d\n' "${m}"
}

# get lowest value from list of numbers
# @usage: math.min NUMBER [...]
math.min() {
    local -i m
    m="${1}"
    shift

    while (( $# > 0 )); do
        (( m = ${1} < m ? ${1} : m ))
        shift
    done

    printf '%d\n' "${m}"
}
