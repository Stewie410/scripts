#!/usr/bin/env bash
#
# Select & open configuration files

show_help() {
    cat << EOF
Select & open configuration files

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --dmenu         Select file with dmenu(1)
    -r, --rofi          Select file with rofi(1)
    -f, --fzf           Select file with fzf(1) (default)
    -z, --zenity        Select file with zenity(1)
    -c, --config PATH   Read PATH for config files
                        (default: ${defaults['config']})
    -e, --editor EDITOR Use EDITOR to open files
                        (default: \$EDITOR or xdg-open)
EOF
}

init_defaults() {
    local i

    defaults['editor']="${EDITOR:-xdg-open}"
    defaults['config']="${XDG_CONFIG_HOME:-${HOME}/.config}"
    defaults['config']+="/$(basename "${0%.*}")/config"
    defaults['selector']="fzf"

    for i in "${!defaults[@]}"; do
        settings["${i}"]="${defaults["$i"]}"
    done
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

get_list() {
    sed '/^\s*#/d;/^\s*$/d;s/\s*#.*$//' "${settings['config']}"
}

get_config() {
    set -- '/dev/stdin'

    case "${settings['selector']}" in
        dmenu )
            require 'dmenu' || return 1
            dmenu -i -p "Edit: " < "${1}"
            ;;
        rofi )
            require 'rofi' || return 1
            rofi -dmenu -p "Edit: " < "${1}"
            ;;
        fzf )
            require 'fzf' || return 1
            fzf -i --no-multi --prompt "Edit: " < "${1}"
            ;;
        zenity )
            require 'zenity' || return 1
            zenity --list --title="Edit" --column="Config" < "${1}"
            ;;
    esac
}

open() {
    local item

    item="$(get_list | get_config)" || return 1
    [[ -z "${item}" ]] && return 1

    item="$(realpath "${item}")" || return 1

    "${settings['editor']}" "${item}"
}

main() {
    local opts
    opts="$(getopt \
        --options hdrfzc:e: \
        --longoptions help,dmenu,rofi,fzf,zenity,config:,editor: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --dmenu )      settings['selector']="dmenu";;
            -r | --rofi )       settings['selector']="rofi";;
            -f | --fzf )        settings['selector']="fzf";;
            -z | --zenity )     settings['selector']="zenity";;
            -c | --config )     settings['config']="${2}"; shift;;
            -e | --editor )     settings['editor']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require "${settings['editor']}" || return 1

    settings['config']="$(realpath "${settings['config']}")" || return 1
    mkdir --parents "${settings['config']%/*}"
    touch -a "${settings['config']}"

    open
}

main "${@}"
