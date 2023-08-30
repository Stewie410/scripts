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

forecast() {
    local uri

    uri="${base}"
    [[ -n "${v2}" ]] && uri="v2n.${base}"

    require 'setsid' || return
    setsid --fork "${TERMINAL}" --command "curl --silent --fail '${uri}'"
}

main() {
    local opts base forecast v2
    opts="$(getopt \
        --options hf2 \
        --longoptions help,forecast,v2 \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -f | --forecast )   forecast="1";;
            -2 | --v2 )         v2="1";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    is_online || return 1
    base="wttr.in/$(get_location)?u" || return 1

    [[ -n "${forecast}" ]] && forecast

    get_oneline "${base}"
}

main "${@}"
