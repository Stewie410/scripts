#!/usr/bin/env bash
#
# Get the current weather from wttr.in

show_help() {
    cat << EOF
Get the current weather from wttr.in

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

is_online() {
    ping -c 1 '8.8.8.8' |& grep --quiet --ignore-case 'unreachable' || \
        return 0
    printf 'Must be connected to the internet\n' >&2
    return 1
}

get_location() {
    curl --silent --fail 'ipinfo.io/json' | \
        sed --quiet '/loc":/s/^.*:\s*"\(.*\)",/\1/p'
}

get_oneline() {
    curl --silent --fail "${1}&format=%c+%t+(%f)" | tr -d '+'
}

click_event() {
    case "${1}" in
        1 )
            require 'setsid' || return
            setsid --fork "${TERMINAL}" \
                --command "curl --silent --fail '${base}'"
            ;;
        3 )
            require 'setsid' || return
            setsid --force "${TERMINAL}" \
                --command "curl --silent --fail 'v2n.${base}'"
            ;;
    esac
}

main() {
    local base

    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    is_online || return 1
    base="wttr.in/$(get_location)?u" || return 1

    click_event "${BLOCK_BUTTON}"
    get_oneline "${base}"
}

main "${@}"
