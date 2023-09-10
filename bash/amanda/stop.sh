#!/usr/bin/env bash
#
# Stop a currently running AMANDA dump

show_help() {
    cat << EOF
Stop a currently running AMANDA dump

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

is_running() {
    ps aux |& awk --assign "cfg=${1}" '
        /(am(anda(driv|tap)er|dump)|dumper)/ && match($0, cfg) {
            exit 0
        }
        END {
            exit 1
        }
    '
}

stop_dump() {
    require 'amcleanup' || return 1
    amcleanup -k "${1}"
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -z "${1}" ]]; then
        printf 'No configuration specified\n' >&2
        return 1
    fi

    is_running "${1}" || return 1
    stop_dump "${1}"
}

main "${@}"
