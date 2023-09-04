#!/usr/bin/env bash
#
# Select a power option with a fuzzy-finder

cleanup() {
    unset log
}

log() {
    printf '%s|%s|%s\n' "$(date --iso-8601=sec)" "${FUNCNAME[1]}" "${1}" | \
        tee --append "${log:-/dev/null}" | \
        cut --fields="2-" --delimiter="|"
}

show_help() {
    cat << EOF
Select a power option with a fuzzy-finder

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -d, --dmenu     Use dmenu(1) to select option
    -r, --rofi      Use rofi(1) to select option
    -f, --fzf       Use fzf(1) to select option (default)
    -z, --zenity    Use zenity(1) to select option
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

get_options() {
    cat << EOF
shutdown
reboot
suspend
hibernate
hybrid-sleep
suspend-then-hibernate
cancel
EOF
}

select_action() {
    case "${selector}" in
        dmenu )
            require 'dmenu' || return 1
            get_options | dmenu -i -p "Select: "
            ;;
        rofi )
            require 'rofi' || return 1
            get_options | rofi -dmenu -p "Select: "
            ;;
        fzf )
            require 'fzf' || return 1
            get_options | fzf -i --no-multi --prompt "Select: "
            ;;
        zenity )
            require 'zenity' || return 1
            get_options | zenity --list --title="Select" --column="Action"
            ;;
    esac
}

main() {
    local opts selector action
    opts="$(getopt \
        --options hdrf \
        --longoptions help,dmenu,rofi,fzf \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    selector="shell"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --dmenu )      selector="dmenu";;
            -r | --rofi )       selector="rofi";;
            -f | --fzf )        selector="fzf";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    if (( EUID != 0 )); then
        printf 'Requires root/sudo\n' >&2
        return 1
    fi

    action="$(select_action)" || return 1
    case "${action,,}" in
        shutdown )      shutdown now;;
        reboot )        shutdown -r now;;
        cancel )        return 0;;
        suspend | hibernate | hybrid-sleep | suspend-then-hibernate )
            require 'systemctl' || return 1
            systemctl "${action,,}"
            ;;
        * )
            printf 'Unknown action: %s\n' "${action}" >&2
            return 1
            ;;
    esac

    return 0
}

main "${@}"
