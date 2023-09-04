#!/usr/bin/env bash
#
# Open QuteBrowser bookmarks, quickmarks or history items in browser

show_help() {
    cat << EOF
Open QuteBrowser bookmarks, quickmarks or history items in browser

USAGE: ${0##*/} [OPTIONS] SOURCE

SOURCE:
    b, bm, book, bookmark       Select item from bookmarks file
    q, qm, quick, quickmark     Select item from quickmarks file
    h, hs, hist, history        Select item from history file

OPTIONS:
    -h, --help                  Show this help message
    -d, --dmenu                 Select item with dmenu(1)
    -r, --rofi                  Select item with rofi(1)
    -f, --fzf                   Select item with fzf(1) (default)
    -z, --zenity                Select item with zenity(1)
    -w, --browser BROWSER       Open item in BROWSER
                                (default: \$BROWSER or xdg-open)
    -B, --bookmark-path PATH    Read bookmarks from PATH
                                (default: ${defaults['bm-path']})
    -Q, --quickmark-path PATH   Read quickmarks from PATH
                                (default: ${defaults['qm-path']})
    -Y, --history-path PATH     Read history from PATH
                                (default: ${defaults['hf-path']})
EOF
}

init_defaults() {
    local i

    defaults['qm-path']="${XDG_CONFIG_HOME:-${HOME}/.config}"
    defaults['qm-path']+="/qutebrowser/quickmarks"
    defaults['bm-path']="${defaults['qm-path']%/*}/bookmarks/urls"
    defaults['hf-path']="${XDG_DATA_HOME:-${HOME}/.local/share}"
    defaults['hf-path']+="/qutebrowser/history.sqlite"
    defaults['selector']="fzf"
    defaults['browser']="${BROWSER:-xdg-open}"

    for i in "${!defaults[@]}"; do
        settings["${i}"]="${defaults["$i"]}"
    done
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

get_item() {
    set -- '/dev/stdin'

    case "${settings['selector']}" in
        dmenu )
            require 'dmenu' || return 1
            dmenu -i -p "Select: " < "${1}"
            ;;
        rofi )
            require 'rofi' || return 1
            rofi -dmenu -p "Select: " < "${1}"
            ;;
        fzf )
            require 'fzf' || return 1
            fzf -i --no-multi --prompt "Select: " < "${1}"
            ;;
        zenity )
            require 'zenity' || return 1
            zenity --list --title="Select" --column="Item" < "${1}"
            ;;
    esac
}

test_file() {
    [[ -n "${2}" && -s "${2}" ]] && return 0
    printf '%s file does not exist or is empty: %s\n' \
        "${1}" "${2:-${3}}" >&2
    return 1
}

open() {
    local item source

    case "${settings['source']}" in
        bm )
            source="$(realpath "${settings['bm-path']}" 2>/dev/null)"
            test_file "Bookmarks" "${source}" "${settings['bm-path']}" || \
                return 1
            item="$(get_item < "${source}")" || return 1
            ;;
        qm )
            source="$(realpath "${settings['qm-path']}" 2>/dev/null)"
            test_file "Quickmarks" "${source}" "${settings['bm-path']}" || \
                return 1
            item="$(sed --quiet 's|.*\(https\?://.*\)|\1|p' "${source}" | \
                get_item \
            )" || return 1
            ;;
        hf )
            require 'sqlite' || return 1
            source="$(realpath "${settings['hf-path']}" 2>/dev/null)"
            test_file "History" "${source}" "${settings['hf-path']}" || \
                return 1
            item="$(sqlite "${source}" 'select url,title,atime from History' | \
                awk --field-separator "|" '{print $1}' | \
                tac | \
                get_item \
            )" || return 1
            ;;
    esac

    [[ -z "${item}" ]] && return 1

    "${settings['browser']}" "${item}" & disown
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hdrfzw:B:Q:Y: \
        --longoptions help,dmenu,rofi,fzf,zenity,browser: \
        --longoptions bookmark-path:,quickmark-path:,history-path: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )                   show_help; return 0;;
            -d | --dmenu )                  settings['selector']="dmenu";;
            -r | --rofi )                   settings['selector']="rofi";;
            -f | --fzf )                    settings['selector']="fzf";;
            -z | --zenity )                 settings['selector']="zenity";;
            -w | --browser )                settings['browser']="${2}"; shift;;
            -B | --bookmark-path )          settings['bm-path']="${2}"; shift;;
            -Q | --quickmark-path )         settings['qm-path']="${2}"; shift;;
            -Y | --history-path )           settings['hf-path']="${2}"; shift;;
            -- )                            shift; break;;
            * )                             break;;
        esac
        shift
    done

    case "${1,,}" in
        b | bm | book | bookmark )      settings['source']="bm";;
        q | qm | quick | quickmark )    settings['source']="qm";;
        h | hs | hist | history )       settings['source']="hf";;
        * )
            printf 'No source selected\n' >&2
            return 1
            ;;
    esac

    require "${settings['browser']}" || return 1
    open
}

main "${@}"
