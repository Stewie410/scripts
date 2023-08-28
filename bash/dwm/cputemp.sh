#!/usr/bin/env bash
#
# Average CPU Core temperature
#
# Requires:
#   - Font Awesome
#   - sensors (lm-sensors)

show_help() {
    cat << EOF
Average CPU Core temperature

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        usage
        return 0
    fi

    require 'sensors' || return 1

    sensors --no-adapter | awk '
        /^Core/ {
            cores++
            sum += $3
        }
        END {
            printf " %0.0f°C", sum / cores
        }
    '
}

main "${@}"
