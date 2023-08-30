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
    -t, --toggle    Toggle playback
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

toggle() {
    is_spotify_running || return
    sp_cmd play-pause
}

main() {
    local opts toggle
    opts="$(getopt \
        --options ht \
        --longoptions help,toggle \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -t | --toggle )     toggle="1";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require 'spotify' 'playerctl' || return 1

    [[ -n "${toggle}" ]] && toggle

    get_info | \
        fmt_info | \
        paste --serial --delimiters=" " | \
        tr --delete '\n'
}

main "${@}"
