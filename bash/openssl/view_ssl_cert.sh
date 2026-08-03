#!/usr/bin/env bash

show_help() {
    cat << EOF
View certificate for a given HOST[:PORT]
USAGE: ${0##*/} HOST[:PORT] [...]
EOF
}

get() {
    local host port
    host="${1%:*}"
    port="443"
    [[ "${1}" == *":"* ]] && port="${1##*:}"

    (
        set -eo pipefail
        openssl s_client -connect "${host}:${port}" < /dev/null \
            | openssl x509 -text
    )
}

main() {
    if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
        show_help
        return 0
    elif (($# == 0)); then
        printf 'Must specify at least one HOST[:PORT]!\n' >&2
        return 1
    fi

    local err
    while (($# > 0)); do
        get "${1}" || err="1"
        shift
    done

    return "${err:-0}"
}

main "${@}"
