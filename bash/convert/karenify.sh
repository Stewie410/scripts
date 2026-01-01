#!/usr/bin/env bash

show_help() {
    cat << EOF
kArEnIfY a file

USAGE: ${0##*/} [OPTIONS] FILE [...]
       ${0##*/} [OPTIONS] < FILE

OPTIONS:
    -h, --help      Show this help message
    -i, --invert    Start casing on upper-case
EOF
}

# init, file [...]
karen() {
    local case
    case="${1}"
    shift

    local line
    while (( $# > 0 )); do
        while IFS='' read -r line; do
            if [[ "${line}" != *[[:alpha:]]* ]]; then
                printf '%s\n' "${line}"
                continue
            fi

            local out i char
            out=""
            for (( i = 0; i < ${#line}; i++ )); do
                char="${line:i:1}"
                if [[ "${char}" == [[:alpha:]] ]]; then
                    case "${case}" in
                        0 ) char="${char,}";;
                        1 ) char="${char^}";;
                    esac
                    (( case = !case ))
                fi
                out+="${char}"
            done
            printf '%s\n' "${out}"
        done < "${1}"
        shift
    done
}

main() {
    local first
    first="0"

    case "${1}" in
        -h | --help )   show_help; return 0;;
        -i | --invert ) first="1"; shift;;
    esac

    (( $# == 0 )) && set -- "/dev/stdin"
    karen "${first}" "${@}"
}

main "${@}"
