#!/usr/bin/env bash
#
# Display currently-playing song information from Spotify
#
# Requires:
#   - spotify
#   - playerctl

show_help() {
    cat << EOF
Display currently-playing song information from Spotify

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

is_spotify_running() {
    pidof 'spotify' &>/dev/null
}

sp_cmd() {
    playerctl --player='spotify' "${@}"
}

get_info() {
    printf '\n'

    if ! is_spotify_running; then
        printf 'closed\n'
        return
    fi

    sp_cmd status --format '{{ lc(status) }}'
    sp_cmd metadata --format '{{ title }} - {{ artist }}'
}

fmt_info() {
    sed '
        s/^playing$//I
        s/^paused$//I
        s/^stopped$//I
        s/^closed$//I
        s/^advertisement - Ad.*$/ Ad/I
    '
}

click_event() {
    case "${1}" in
        1 )
            is_spotify_running || return
            sp_cmd play-pause
            ;;
    esac
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    require 'spotify' 'playerctl' || return 1

    if ! is_spotify_running; then
        printf ' '
        return 1
    fi

    click_event "${BLOCK_BUTTON}"
    printf ' %s %s' "$(sp_status)" "$(sp_info)"

    get_info | \
        fmt_info | \
        paste --serial --delimiters=" " | \
        tr --delete '\n'
}

main "${@}"
