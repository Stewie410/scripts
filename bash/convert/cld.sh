#!/usr/bin/env bash
#
# Compile a LaTeX document to PDF

show_help() {
    cat << EOF
Compile a LaTeX document to PDF

USAGE: ${0##*/} [OPTIONS] FILE [...]

OPTIONS:
    -h, --help      Show this help message
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

main() {
    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -z "${1}" ]]; then
        printf 'No LaTeX file specified\n' >&2
        return 1
    fi

    require 'latexmk' || return 1

    while (( $# > 0 )); do
        latexmk -f -xelatex -synctex -interaction='nonstopmode' "${1%.*}"
        shift
    done

    return 0
}

main "${@}"
