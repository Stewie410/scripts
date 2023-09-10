#!/usr/bin/env bash
#
# Allow current tape to be written to immediately

show_help() {
    cat << EOF
Allow current tape to be written to immediately

USAGE:  ${0##*/} [OPTIONS] CONFIG

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    local err

    while (( $# > 0 )); do
        command -v "${1}" &>/dev/null && continue
        printf 'Missing required application: %s\n' "${1}" >&2
        (( err++ ))
    done

    return "${err:-0}"
}

get_tape() {
    require 'amtape' || return 1
    amtape "${1}" show |& awk '
        /busy/ {
            exit 1
        }
        /^slot/ {
            print $NF
            exit 0
        }
    '
}

reset_tape() {
    if ! amrmtape "${@}"; then
        printf 'Failed to remove existing label: %s\n' "${2}" >&2
        return 1
    fi

    if ! amlabel -f "${@}"; then
        printf 'Failed to reapply label: %s\n' "${2}" >&2
        return 1
    fi

    return 0
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -z "${1}" ]]; then
        printf 'No configuration specified\n' >&2
        return 1
    fi

    require 'amtape' 'amrmtape' 'amlabel' || return 1

    local label
    label="$(get_tape "${1}")" || return 1

    if [[ -z "${label}" ]]; then
        printf 'Unable to determine current tape label\n' >&2
        return 1
    fi

    reset_tape "${label%-*}" "${label}"
}

main "${@}"
