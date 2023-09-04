#!/usr/bin/env bash
#
# List and open documents

show_help() {
    cat << EOF
List and open files in specified path or \$PWD, with xdg-open

USAGE: ${0##*/} [OPTIONS] [PATH]

OPTIONS:
    -h, --help          Show this help message
    -d, --dmenu         Select file with dmenu(1)
    -r, --rofi          Select file with rofi(1)
    -f, --fzf           Select file with fzf(1) (default)
    -z, --zenity        Select file with zenity(1)
    -i, --include GLOB  Include GLOB in results
                        Can be used multiple times
    -x, --exclude GLOB  Exclude GLOB in results
                        Can be used multiple times
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

find_files() {
    find "${@}" \
        -mindepth 1 \
        -type f \
        "${include[@]}" \
        "${exclude[@]}" \
        -printf '%p\n'
}

get_file() {
    set -- '/dev/stdin'

    case "${selector}" in
        dmenu )
            require 'dmenu' || return 1
            dmenu -i -p "Open: " < "${1}"
            ;;
        rofi )
            require 'rofi' || return 1
            rofi -dmenu -p "Open: " < "${1}"
            ;;
        fzf )
            require 'fzf' || return 1
            fzf -i --no-multi --prompt "Open: " < "${1}"
            ;;
        zenity )
            require 'zenity' || return 1
            zenity --list --title="Open" --column="File" < "${1}"
            ;;
    esac
}

get_paths() {
    local rp

    while (( $# > 0 )); do
        if ! rp="$(realpath "${1}" 2>/dev/null)"; then
            printf 'Skipping invalid path: %s\n' "${1}" >&2
        elif [[ -d "${rp}" ]]; then
            printf 'Skipping non-directory or non-existent path: %s\n' \
                "${rp}" >&2
        else
            printf '%s\n' "${rp}"
        fi
        shift
    done
}

open() {
    local -a paths
    local item

    mapfile -t paths < <(get_paths "${@}")
    if (( ${#paths[@]} == 0 )); then
        printf 'No valid paths to search\n' >&2
        return 1
    fi

    item="$(find_files "${paths[@]}" | get_file)" || return 1
    [[ -z "${item}" ]] && return 1

    xdg-open "${item}" & disown
}

main() {
    local -a include exclude
    local opts selector
    opts="$(getopt \
        --options hdrfzi:x: \
        --longoptions help,dmenu,rofi,fzf,zenity,include:,exclude: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    selector="fzf"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --dmenu )      selector="dmenu";;
            -r | --rofi )       selector="rofi";;
            -f | --fzf )        selector="fzf";;
            -z | --zenity )     selector="zenity";;
            -i | --include )    include+=("-ipath '${2}'"); shift;;
            -x | --exclude )    exclude+=("! -ipath '${2}'"); shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    (( $# == 0 )) && set -- "${PWD}"

    require 'xdg-open' || return 1
    open "${@}"
}

main "${@}"
