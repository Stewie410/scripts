#!/usr/bin/env bash

# standard logging function
# usage: util.log MESSAGE
util.log() {
    printf '%s|%s|%s\n' \
        "$(date --iso-8601='sec')" "${FUNCNAME[1]:-${0##*/}}" "${1}" \
        | tee --append "${log:-/dev/null}"
}

# require command in $PATH
# usage: util.require COMMAND
util.require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Cannot locate required application: %s\n' "${1}" >&2
    return 1
}
