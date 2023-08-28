#!/usr/bin/env bash
#
# Display network/radio status icons
#
# Requires:
#   - Font Awesome
#   - systemctl
#       - bluetooth.service
#   - setsid
#   - bluetoothctl
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

is_bt_enabled() {
    systemctl --quiet is-active bluetooth &>/dev/null
}

get_devices() {
    ip route | awk '
        /scope/ {
            print $3
        }
    '
}

get_device_icons() {
    get_devices | sed '
        s/^e.*//I
        s/^w.*//I
        s/^t.*//I
    '
    is_bt_enabled && printf '\n'
}

click_event() {
    case "${1}" in
        1 )
            require 'sedsid' 'nmtui' || return
            setsid --force "${TERMINAL}" --command 'nmtui'
            ;;
        2 )
            require 'systemctl' || return
            if is_bt_enabled; then
                systemctl stop bluetooth
                return
            fi
            systemctl start bluetooth
            ;;
        3 )
            require 'setsid' 'bluetoothctl' || return
            setsid --fork "${TERMINA}" --command 'bluetoothctl'
            ;;
    esac
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    fi

    require 'systemctl' 'setsid' 'bluetoothctl' 'ip' || return

    click_event "${BLOCK_BUTTON}" || return
    get_device_icons | \
        paste --serial --delimiter=" " | \
        tr -d '\n'
}

main "${@}"
