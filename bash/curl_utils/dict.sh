#!/usr/bin/env bash
#
# Get a dictionary definition, sorta

show_help() {
    cat << EOF
Get a dictionary definition, sorta

USAGE: ${0##*/} [OPTIONS] WORD

OPTIONS:
    -h, --help      Show this help message
EOF
}

is_offline() {
    ping -c 1 '8.8.8.8' |& \
        grep --quiet --ignore-case 'unreachable'
}

encode() {
    "${PWD}/curl_encode.sh" <<< "${1}"
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -z "${1}" ]]; then
        printf 'No word(s) specified\n' >&2
        return 1
    fi

    if is_offline; then
        printf 'Requires an internet connection\n' >&2
        return 1
    fi

    while (( $# > 0 )); do
        curl --silent --fail "dict://dict.org/d:$(encode "${1}")"
        shift
    done

    return 0
}

main "${@}"
