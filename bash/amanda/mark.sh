#!/usr/bin/env bash
#
# Mark an AMANDA tape as read-only or writeable

show_help() {
    cat << EOF
Mark an AMANDA tape as read-only or writeable

USAGE:  ${0##*/} [OPTIONS] LABEL

OPTIONS:
    -h, --help      Show this help message
    -l, --lock      Mark the specified tape as read-only
    -u, --unlock    Mark the specified tape as writeable (default)

LABEL:
    Tape label is expected to follow the format:

        {CONFIG}-{NUMBER}
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

valid_format() {
    [[ "${1}" =~ ^.+-[0-9]+$ ]] && return 0
    printf 'Invalid label format (CONFIG-NUMBER): %s\n' "${1}" >&2
    return 1
}

apply_mark() {
    require 'amadmin' || return 1

    if [[ -n "${lock}" ]]; then
        amadmin "${1%-*}" no-reuse "${1}"
    else
        amadmin "${1%-*}" reuse "${1}"
    fi
}

main() {
    local opts lock
    opts="$(getopt \
        --options hlu \
        --longoptions help,lock,unlock \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -l | --lock )       lock="1";;
            -u | --unlock )     unset lock;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    if [[ -z "${1}" ]]; then
        printf 'No label specified\n' >&2
        return 1
    fi

    valid_format "${1}" || return 1
    apply_mark "${1}"
}

main "${@}"
