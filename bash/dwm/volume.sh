#!/usr/bin/env bash
#
# Display volume level
#
# Requires:
#   - pamixer
#   - setsid

show_help() {
    cat << EOF
Display volume level

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

get_volume() {
    pamixer --get-volume-human
}

click_event() {
    case "${1}" in
        1 )
            pamixer --toggle-mute
            ;;
        3 )
            setsid --fork "${TERMINAL}" --command 'pamixer'
            ;;
    esac
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    require 'pamixer' 'setsid' || return 1

    click_event "${BLOCK_BUTTON}"

    get_volume | \
        sed 's/^/ /'
}

main "${@}"
