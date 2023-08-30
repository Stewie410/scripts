#!/usr/bin/env bash
#
# Get i3wm layout icon
#
# Requires:
#   - i3-msg
#   - jq

show_help() {
    cat << EOF
Get i3wm layout icon

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

get_focused() {
    i3-msg -t get_tree | jq --raw-output '
        recurse(.nodes[])
            | select(.nodes[].focused == true)
            | .layout
    '
}

get_icon() {
    local layout icon
    layout="$(get_focused)"

    case "${layout,,}" in
        splith )    icon="";;
        splitv )    icon="󰹹";;
        stack* )    icon="";;
        tabbed )    icon="󰓩";;
        * )         icon="?";;
    esac

    printf '%s\n' "${icon}"
}

main() {
    local icon

    if [[ "${1}" =~ -(h|-help) ]]; then
        show_usage
        return 0
    fi

    require 'i3-msg' 'jq' || return 1
    get_icon
}

main "${@}"
