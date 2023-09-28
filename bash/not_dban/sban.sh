#!/usr/bin/env bash
#
# DBAN, kinda

show_help() {
    cat << EOF
DBAN, kinda

USAGE: ${0##*/} [OPTIONS] DEVICE [...]

OPTIONS:
    -h, --help          Show this help message
    -r, --rounds NUM    Specify number of rounds (default: ${def_rounds})
EOF
}

is_valid_int() {
    if [[ "${1}" =~ [^0-9\-] ]]; then
        printf 'Not a number: %s\n' "${1}" >&2
        return 1
    elif (( $1 < 1 )); then
        printf 'Must be at least 1: %d\n' "${1}" >&2
        return 1
    fi
    return 0
}

write_device() {
    dd if="${1}" of="${2}" bs='4M' conv='noerror' status='progress'
}

zero_device() {
    write_device '/dev/zero' "${1}"
}

urand_device() {
    write_device '/dev/urandom' "${1}"
}

main() {
    local opts def_rounds rounds i
    opts="$(getopt \
        --options hr: \
        --longoptions help,rounds: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    def_rounds="1"
    rounds="${def_rounds}"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -r | --rounds )
                is_valid_int "${2}"
                rounds="${2}"
                shift
                ;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    if (( EUID != 0 )); then
        printf 'Requires root priviledges\n' >&2
        return 1
    fi

    if [[ -z "${1}" ]]; then
        printf 'No device(s) specified\n' >&2
        return 1
    fi

    while (( $# > 0 )); do
        if ! [[ -b "${1}" ]]; then
            printf 'Invalid block device: %s\n' "${1}" >&2
            shift
            continue
        fi

        for (( i = 1; i <= rounds; i++ )); do
            printf '%s: %d\n' "${1}" "${i}"
            zero_device "${1}"
            urand_device "${1}"
        done

        printf '%s: Final zero\n' "${1}"
        zero_device "${1}"
        printf '%9s\n' "-" | tr " " '-'
        shift
    done
}

main "${@}"
