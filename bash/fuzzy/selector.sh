#!/usr/bin/env bash
#
# Use a fuzzy-finder for selection

show_help() {
    cat << EOF
Use a fuzzy-finder for selection

USAGE: ${0##*/} [OPTIONS] FILE

OPTIONS:
    -h, --help      Show this help message
    -d, --dmenu     Use dmenu(1)
    -r, --rofi      Use rofi(1)
    -f, --fzf       Use fzf(1) (default)
    -z, --zenity    Use zenity(1)
    -p, --prompt    Prompt message (default: 'Select: ')
EOF
}

selector() {
    set -- '/dev/stdin'
    case "${selector}" in
        dmenu )
            dmenu -i -p "${prompt}" < "${1}"
            ;;
        rofi )
            rofi -dmenu -p "${prompt}" < "${1}"
            ;;
        fzf )
            fzf -i --no-multi --prompt "${prompt}" < "${1}"
            ;;
        zenity )
            zenity --list --title="${prompt:0:-2}" --column="Item" < "${1}"
            ;;
    esac
}

main() {
    local opts selector prompt
    opts="$(getopt \
        --options hdrfzp: \
        --longoptions help,dmenu,rofi,fzf,zenity,prompt: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    selector="fzf"
    prompt="Select: "

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --dmenu )      selector="dmenu";;
            -r | --rofi )       selector="rofi";;
            -f | --fzf )        selector="fzf";;
            -z | --zenity )     selector="zenity";;
            -p | --prompt )     prompt="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require "${selector}" || return 1
    [[ -z "${1}" ]] && set -- '/dev/stdin'
    selector "${1}"
}

main "${@}"
