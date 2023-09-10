#!/usr/bin/env bash
#
# Apply AMANDA label to tape

show_help() {
    cat << EOF
Apply AMANDA label to tape

USAGE:  ${0##*/} [OPTIONS] CONFIG

OPTIONS:
    -h, --help          Show this help message
    -n, --number INT    Specify the number to use in the tape label, instead of
                        generating one
    -p, --padd INT      Ensure label number is at least INT digits long by
                        prepending zeroes (default: ${default_pad})
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

is_valid_int() {
    if ! [[ "${2}" =~ ^-?[0-9]+$ ]]; then
        printf '%s is not an integer: %s\n' "${1}" "${2}" >&2
        return 1
    elif [[ -n "${3}" ]] && (( ${2} < ${3} )); then
        printf '%s must be at least %s: %s\n' "${1}" "${3}" "${2}" >&2
        return 1
    fi
    return 0
}

tape_exists() {
    grep --quiet --fixed-strings "${1}-${number}" "/etc/amanda/${1}/tapelist"
}

get_number() {
    awk --assign 'num=-1' '
        {
            current = gensub(/^[^-]*?-([0-9]+).*$/, "\\1", 1, $2)
            if (current > num)
                num = current
        }
        END {
            print num + 1
        }
    ' "/etc/amanda/${1}/tapelist"
}

apply_label() {
    require 'amlabel' || return 1
    amlabel -f "${1}" "${1}-${number}"
}

main() {
    local opts number pad default_pad
    opts="$(getopt \
        --options hn:p: \
        --longoptions help,number:,pad: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -n | --number )
                is_valid_int 'Number' "${2}" '0' || return 1
                number="${2}"
                shift
                ;;
            -p | --pad )
                is_valid_int 'Pad' "${2}" '1' || return 1
                pad="${2}"
                shift
                ;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    if [[ -z "${1}" ]]; then
        printf 'No configuration specified\n' >&2
        return 1
    fi

    [[ -z "${number}" ]] && number="$(get_number "${1}")"

    while (( ${#number} < pad )); do
        number="0${number}"
    done

    if tape_exists "${1}"; then
        printf 'Tape already exists in tapelist: %s-%s\n' \
            "${1}" "${number}" >&2
        return 1
    fi

    apply_label "${1}"
}

main "${@}"
