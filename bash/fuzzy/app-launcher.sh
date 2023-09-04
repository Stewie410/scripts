#!/usr/bin/env bash
#
# Find and open an app from $PATH

show_help() {
    cat << EOF
Find and open an app from \$PATH

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -d, --dmenu     Select app with dmenu_run(1)
    -r, --rofi      Select app with rofi(1)
    -f, --fzf       Select app with fzf(1) (default)
    -z, --zenity    Select app with zenity(1)
EOF
}

get_apps() {
    local -a paths
    mapfile -t paths < <(tr ':' '\n' <<< "${PATH}")
    find "${paths[@]}" \
        -maxdepth 1 \
        -type f \
        -executable \
        ! -iname '*.dll'
}

get_app() {
    set -- '/dev/stin'

    case "${selector}" in
        dmenu )
            if require 'dmenu_run' &>/dev/null; then
                dmenu_run & disown
                return
            fi
            require 'dmenu' || return 1
            dmenu -i -p "Run: " < "${1}"
            ;;
        rofi )
            require 'rofi' || return 1
            rofi -show run & disown
            ;;
        fzf )
            require 'fzf' || return 1
            fzf -i --no-multi --prompt "Run: " < "${1}"
            ;;
        zenity )
            require 'zenity' || return 1
            zenity --list --title="Run" --column="App" < "${1}"
            ;;
    esac
}

run_app() {
    local app
    app="$(get_apps | get_app | tail -1)" || return 1
    [[ -z "${app}" ]] || return 0

    "${app}" & disown
}

main() {
    local opts selector
    opts="$(getopt \
        --options hdrfz \
        --longoptions help,dmenu,rofi,fzf,zenity \
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
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    run_app
}

main "${@}"
