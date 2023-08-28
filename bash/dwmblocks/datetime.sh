#!/usr/bin/env bash
#
# Display date-/timestamp
#
# Requires:
#   - notify-send
#   - setsid
#   - calcurse

show_help() {
    cat << EOF
Display date-/timestamp

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    local err

    while (( $# > 0 )); do
        if ! command -v "${1}" &>/dev/null; then
            printf 'Missing required application: %s\n' "${1}" >&2
            (( err++ ))
        fi
        shift
    done

    return "${err:-0}"
}

click_event() {
    case "${1}" in
        1 )
            require 'notify-send' 'calcurse' || return 1
            notify-send "$(date)"
            notify-send "$(calcurse --date 3)"
            ;;
        3 )
            require 'setsid' 'calcurse' || return 1
            setsid --force "${TERMINAL}" --command 'calcurse'
            ;;
    esac
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        usage
        return 1
    fi

    click_event "${BLOCK_BUTTON}"
    date '+%I:%M %p'
}

main "${@}"
