#!/usr/bin/env bash
#
# Get/Set brightness level

show_help() {
    cat << EOF
Get/Set brightness level

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -s, --set NUM           Set brightness percentage to NUM
                            Use +NUM to increase percentage by NUM
                            Use -NUM to decrease percentage by NUM
    -r, --reset             Set brightness to 50%
    -w, --workaround        Fake brightness with gamma percentage
    -n, --notify            Send a desktop notification on change
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

notify() {
    notify-send --urgency="low" "${1}"
}

get_brightness() {
    brightnessctl info | awk '
        /Current/ {
            current = $3
        }
        /Max/ {
            printf "%0.0f", (current / max) * 100
            exit
        }
    '
}

set_brightness() {
    local b
    b="${1//%/}%"
    [[ "${b:0:1}" == "-" ]] && b="${1:1}-"

    if ! brightnessctl --quiet set "${b}" &>/dev/null; then
        [[ -n "${notify}" ]] && notify "Failed to modify brightness"
        printf 'Failed to set brightness\n' >&2
        return 1
    fi

    [[ -n "${notify}" ]] && notify "Brightness: $(get_brightness)"
    return 0
}

get_gamma() {
    xrandr --current --verbose --screen 0 | awk '
        /Brightness/ {
            printf "%0.0f", $NF * 100
        }
    '
}

set_gamma() {
    local g

    g="$(get_current | awk --assign "g=${1//%/}" '
        substr(g, 1, 1) == "+" {
            g = $1 + substr(g, 2)
        }
        substr(g, 1, 1) == "-" {
            g = $1 - substr(g, 2)
        }
        END {
            print g / 100
        }
    ')"

    if ! xrandr --screen 0 --brightness "${g}" &>/dev/null; then
        [[ -n "${notify}" ]] && notify "Failed to modify gamma"
        printf 'Failed to modify gamma\n' >&2
        return 1
    fi

    [[ -n "${notify}" ]] && notify "Gamma: $(get_gamma)"
    return 0
}

main() {
    local opts level gamma notify
    opts="$(getopt \
        --options hrwns:r: \
        --longoptions help,reset,workaround,notify,set: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -s | --set )        level="${2}"; shift;;
            -r | --reset )      level="50";;
            -w | --workaround ) gamma="1";;
            -n | --notify )     notify="1";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    ( [[ -n "${notify}" ]] && ! require 'notify-send' ) && return 1

    if [[ -n "${gamma}" ]]; then
        require 'xrandr' || return 1
        if [[ -n "${level}" ]]; then
            set_gamma "${level}"
            return
        fi
        get_gamma
    fi

    require 'brightnessctl' || return 1
    if [[ -n "${level}" ]]; then
        set_brightness "${level}"
        return
    fi
    get_brightness
}

main "${@}"
