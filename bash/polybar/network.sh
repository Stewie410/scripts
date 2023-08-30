#!/usr/bin/env bash
#
# Display network/radio status icons
#
# Requires:
#   - systemctl -> bluetooth.service
#   - ip

show_help() {
    cat << EOF
Display network/radio status icons

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

bt_exist() {
    systemctl list-unit-files bluetooth.service &>/dev/null
}

is_bt_enabled() {
    bt_exists || return 1
    systemctl --quiet is-active bluetooth &>/dev/null
}

get_devices() {
    ip route | awk '/scope/ && !seen[$3]++ { print $3 }'
}

get_icons() {
    sed '
        s/^e.*/󰛳/I
        s/^w.*/󰖩/I
        s/^t.*/󱠾/I
    '
    is_bt_enabled && printf '\n'
}

toggle_bt() {
    if is_bt_enabled; then
        systemctl stop bluetooth
    else
        systemctl start bluetooth
    fi
}

main() {
    local opts toggle
    opts="$(getopt \
        --options hb \
        --longoptions help,bluetooth \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -b | --bluetooth )  toggle="1";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require 'systemctl' 'ip' || return 1

    [[ -n "${toggle}" ]] && toggle_bt

    get_devices | \
        get_icons | \
        paste --serial --delimiter=" " | \
        tr --delete '\n'
}

main "${@}"
