#!/usr/bin/env bash

show_help() {
    cat <<EOF
Generate psuedo-random password with bitwarden-cli

USAGE: ${0##*/} [OPTIONS] [BW_OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --default       Alias for '-ulns --length 25'

EOF

    bw help generate
}

main() {
    if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
        show_help
        return 0
    elif [[ "${1}" == "-d" || "${1}" == "--default" ]]; then
        set -- --upercase --lowercase --special --length 12 "${@}"
    fi

    bw generate "${@}"
}

main "${@}"
