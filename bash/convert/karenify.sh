#!/usr/bin/env bash
#
# kArEnIfY a file

show_help() {
    cat << EOF
kArEnIfY a file

USAGE: ${0##*/} [OPTIONS] FILE

OPTIONS:
    -h, --help      Show this help message
    -i, --invert    Start casing on upper-case
EOF
}

recase() {
    local i line new char last

    while IFS='' read -r line; do
        unset new

        if ! [[ "${line,,}" =~ [a-z] ]]; then
            printf '%s\n' "${line}"
            continue
        fi

        for ((i = 0; i < ${#line}; i++)); do
            char="${line:$i:1}"
            if [[ "${char}" =~ [a-zA-Z] ]]; then
                if [[ -z "${last}" ]]; then
                    char="${char,,}"
                    [[ -n "${invert}" ]] && char="${char^^}"
                else
                    char="${char,,}"
                    [[ "${last}" =~ [a-z] ]] && char="${char^^}"
                fi
                last="${char}"
            fi
            new+="${char}"
        done

        printf '%s\n' "${new}"
    done < "${1}"
}

main() {
    local invert
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ "${1}" =~ -(i|-invert) ]]; then
        invert="1"
        shift
    fi

    [[ -z "${1}" ]] && set -- '/dev/stdin'

    recase "${1}"
}

main "${@}"
