#!/usr/bin/env bash
#
# Convert a PEM certificate to CRT

show_help() {
    cat << EOF
Convert a PEM certificate to CRT

USAGE: ${0##*/} [OPTIONS] PEM [CRT]

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

convpem() {
    openssl x509 \
        -outform 'der' \
        -in "${1}" \
        -out "${2:-${1%.*}.crt}"
}

main() {
    if [[ -z "${1}" ]]; then
        printf 'No PEM file specified\n' >&2
        return 1
    elif [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif ! [[ -s "${1}" ]]; then
        printf 'PEM file is empty or does not exist\n' >&2
        return 1
    fi

    require 'openssl' || return 1

    convpem "${@}"
}

main "${@}"
