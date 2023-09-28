#!/usr/bin/env bash
#
# Retrieve a cheat-sheet of one or more commands

show_help() {
    cat << EOF
Retrieve a cheat-sheet of one or more commands

USAGE: ${0##*/} [OPTIONS] COMMAND [...]

OPTIONS:
    -h, --help      Show this help message
EOF
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -z "${1}" ]]; then
        printf 'No command(s) specified\n' >&2
        return 1
    fi

    while (( $# > 0 )); do
        curl --silent --fail "cheat.sh/${1}"
        shift
    done
}

main "${@}"
