#!/usr/bin/env bash
#
# Search & Read the offline ArchWiki

show_help() {
    cat << EOF
Search & Read the offline ArchWiki

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -d, --dmenu             Use dmenu(1) to get article
    -r, --rofi              Use rofi(1) to get article
    -f, --fzf               Use fzf(1) to get article
    -z, --zenity            Use zenity(1) to get article
    -w, --browser BRWOSER   Open article with BROWSER
                            (default: \$BROWSER or xdg-open(1))
    -p, --path PATH         Search PATH for wiki articles
                            (default: ${defaults['root']})
EOF
}

init_defaults() {
    local i

    defaults['root']='/usr/share/doc/arch-wiki/html/en'
    defaults['selector']='fzf'
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

articles() {
    find "${settings['root']}" -type f -iname '*.html' -printf '%P\n'
}

get_article() {
    case "${settings['selector']}" in
        dmenu )
            require 'dmenu' || return 1
            articles | dmenu -i -p "Wiki: "
            ;;
        rofi )
            require 'rofi' || return 1
            articles | rofi -dmenu -p "Wiki: "
            ;;
        fzf )
            require 'fzf' || return 1
            articles | fzf -i --no-multi --prompt "Wiki: "
            ;;
        zenity )
            require 'zenity' || return 1
            articles | zenity --list --title="Wiki" --column="Article"
            ;;
    esac
}

open() {
    local article

    article="$(get_article)" || return 1
    [[ -z "${article}" ]] || return 1

    "${settings['browser']}" "${settings['root']}/${article}" & disown
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hdrfzw:p: \
        --longoptions help,dmenu,rofi,fzf,zenity,browser:,path: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    init_defaults

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --dmenu )      settings['selector']="dmenu";;
            -r | --rofi )       settings['selector']="rofi";;
            -f | --fzf )        settings['selector']="fzf";;
            -z | --zenity )     settings['selector']="zenity";;
            -w | --browser )    settings['browser']="${2}"; shift;;
            -p | --path )       settings['root']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require "${settings['browser']}" || return 1

    settings['root']="$(realpath "${settings['root']}")"
    if [[ -z "${settings['root']}" ]] || ! [[ -d "${settings['root']}" ]]; then
        printf 'Cannot locate path to wiki articles\n' >&2
        return 1
    fi

    open
}

main "${@}"
