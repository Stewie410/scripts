#!/usr/bin/env bash

# determine if array contains value
# @usage: array.contains ARRAY_NAME VALUE
array.contains() {
    local -n _arr="${1}"
    local i

    for i in "${_arr[@]}"; do
        [[ "${i}" == "${2}" ]] && return 0
    done

    return 1
}

# change all elements within range with static value
# @usage: array.fill ARRAY_NAME VALUE [START [END]]
array.fill() {
    local -n _arr="${1}"
    local i

    for (( i = ${3:-0}; i < ${4:-${#_arr[@]}}; i++ )); do
        _arr[i]="${2}"
    done
}

# get all indicies of specified value
# @usage: array.index_of ARRAY_NAME VALUE
array.index_of() {
    local -n _arr="${1}"
    local i

    for (( i = 0; i < ${#_arr[@]}; i++ )); do
        [[ "${_arr[i]}" == "${2}" ]] \
            && printf '%s\n' "${i}"
    done
}

# get first index of specified value
# @usage: array.first_index_of ARRAY_NAME VALUE
array.first_index_of() {
    local -a _idx
    mapfile -t _idx < <(array.index_of "${@}")
    (( ${#_idx[@]} > 0 )) || return 1
    printf '%s\n' "${_idx[0]}"
}

# get last index of specified value
# @usage: array.last_index_of ARRAY_NAME VALUE
array.last_index_of() {
    local -a _idx
    mapfile -t _idx < <(array.index_of "${@}")
    (( ${#_idx[@]} > 0 )) || return 1
    printf '%s\n' "${_idx[-1]}"
    return 0
}

# join array as string
# @usage: array.join ARRAY_NAME [DELIMITER]
array.join() {
    local -n _arr="${1}"
    local i d _str
    d="${2}"
    (( $# == 1 )) && d=","

    _str="${_arr[0]}"
    for (( i = 1; i < ${#_arr[@]}; i++ )); do
        _str+="${d}${_arr[i]}"
    done

    printf '%s\n' "${_str}"
}

# remove & return last element of array
# @usage: array.pop ARRAY_NAME
array.pop() {
    local -n _arr="${1}"
    printf '%s\n' "${_arr[-1]}"
    unset '_arr[-1]'
}

# reverse array elements
# @usage: array.rev ARRAY_NAME
array.reverse() {
    local -n _arr="${1}"
    local dbg

    shopt -q extdebug &>/dev/null && dbg="1"
    shopt -s extdebug
    set -- "${_arr[@]}"
    mapfile -t _arr < <(printf '%s\n' "${BASH_ARGV[@]}")
    (( dbg == 1 )) && shopt -u extdebug
    return 0
}

# remove & return first element of array
# @usage: array.shift ARRAY_NAME
array.shift() {
    local -n _arr="${1}"
    printf '%s\n' "${_arr[0]}"
    set -- "${_arr[@]}"
    shift
    _arr=( "${@}" )
}

# return a range from array
# @usage: array.slice ARRAY_NAME [START [END]]
array.slice() {
    local -n _arr="${1}"
    local i

    for (( i = ${2:-0}; i < ${3:-${#_arr[@]}}; i++ )); do
        printf '%s\n' "${_arr[i]}"
    done
}

# add value to beginning of array
# @usage: array.unshift ARRAY_NAME VALUE
array.unshift() {
    local -n _arr="${1}"
    _arr=( "${2}" "${_arr[@]}" )
}
