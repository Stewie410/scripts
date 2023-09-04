#!/usr/bin/env bash
#
# Toggle the TapToClick functionality of the touchpad

show_help() {
    cat << EOF
Toggle the TapToClick functionality of the touchpad

USAGE: ${0##*/} [OPTIONS] [DEVICE] [PROPERTY]

OPTIONS:
    -h, --help          Show this help message
    -t, --toggle        Toggle tap-to-click (default)
    -e, --enable        Enable tap-to-click
    -d, --disable       Disable tap-to-click
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

has_xinput() {
    xinput &>/dev/null && return 0
    printf 'No X server/input detected\n' >&2
    return 1
}

get_device() {
    xinput --list --sort | awk '
        /Touchpad/ {
            print substr($6, 4)
        }
    '
}

get_property() {
    xinput --list-props "${1}" | awk '
        /Tapping Enabled \(/ {
            print substr($4, 2, 3)
        }
    '
}

get_state() {
    xinput --list-props "${1}" | awk --assign "id=${2}" '
        match($4, id) {
            print $NF
        }
    '
}

main() {
    local opts action device property state
    opts="$(getopt \
        --options hted \
        --longoptions help,toggle,enable,disable \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -t | --toggle )     action="toggle";;
            -e | --enable )     action="enable";;
            -d | --disable )    action="disable";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require 'xinput' || return 1
    has_xinput || return 1

    if [[ -z "${device:=${1:-$(get_device)}}" ]]; then
        printf 'Cannot determine the touchpad device\n' >&2
        return 1
    fi

    if [[ -z "${property:=${2:-$(get_property "${device}")}}" ]]; then
        printf 'Cannot determine tap-to-click property for device: %s\n' \
            "${device}" >&2
        return 1
    fi
    state="$(get_state "${device}" "${property}")"

    case "${action:-toggle}" in
        toggle )
            state="$(get_state "${device}" "${property}")"
            xinput --set-prop "${device}" "${property}" "$((1 - state))" || \
                return 1
            ;;
        enable )
            xinput --set-prop "${device}" "${property}" '1' || \
                return 1
            ;;
        disable )
            xinput --set-prop "${device}" "${property}" '0' || \
                return 1
            ;;
    esac

    return 0
}
