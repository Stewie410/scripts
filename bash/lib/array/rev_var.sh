#!/usr/bin/env bash

rev_var() {
    (( $# )) || return 1
    if shopt -q extdebug &>/dev/null; then
        arr=("${BASH_ARGV[@]}")
        return
    fi
    shopt -s extdebug
    while (( $# > 0 )); do
        # shellcheck disable=SC2178
        local -n arr="${1}"
        rev_var "${arr[@]}"
        shift
    done
    shopt -u extdebug
}
