#!/usr/bin/env bash

rev() {
    if shopt -q extdebug &>/dev/null; then
        printf '%s\n' "${BASH_ARGV[@]}"
        return
    fi
    shopt -s extdebug
    rev "${@}"
    shopt -u extdebug
}
