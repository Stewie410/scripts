#!/usr/bin/env bash
#
# Get a cheat-sheet for a command

show_help() {
    cat << EOF
Get a cheat-sheet for a command

USAGE: ${0##*/} [OPTIONS] COMMAND [...]

OPTIONS:
    -h, --help      Show this help message
EOF
}

is_offline() {
    ping -c 1 '8.8.8.8' |& \
        grep --quiet --ignore-case 'unreachable'
}

encode() {
    "${0%/*}/convert/urlencode.sh" <<< "${1}"
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -z "${1}" ]]; then
        printf 'No command specified\n' >&2
        return 1
    fi

    if is_offline; then
        printf 'Requires an internet connection\n' >&2
        return 1
    fi

    while (( $# > 0 )); do
        curl --silent --fail "cheat.sh/$(encode "${1}")"
        shift
    done

    return 0
}

main "${@}"
