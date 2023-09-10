#!/usr/bin/env bash
#
# Start dump to tape by configuration name

log() {
    printf '%s|%s|%s\n' "$(date --iso-8601='sec')" "${FUNCNAME[1]^^}" "${1}" | \
        tee --append "${log}"
}

show_help() {
    cat << EOF
Start dump to tape by configuration name

USAGE:  ${0##*/} [OPTIONS] CONFIG

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

start_dump() {
    require 'amdump' || return 1
    amdump "${1}" && return 0
    log "Failed to perform dump: ${1}" >&2
    return 1
}

main() {
    if [[ "${1}" =~ ^-(h|-help)$ ]]; then
        show_help
        return 0
    elif [[ -z "${1}" ]]; then
        log "No configuration specified" >&2
        return 1
    fi

    start_dump "${1}"
}

log="/var/log/amanda/scripts/$(basename "${0%.*}").log"
trap 'unset log' EXIT

main "${@}"
