#!/usr/bin/env bash
#
# Search the web for a give query

show_help() {
    cat << EOF
Search the web for a give query

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -d, --dmenu             Use dmenu(1) to get query
    -r, --rofi              Use rofi(1) to get query
    -s, --shell             Use read to get query (default)
    -z, --zenity            Use zenity(1) to get query
    -w, --browser BROWSER   Open query with BROWSER
                            (default: \$BROWSER or xdg-open(1))
    -D, --ddg               Search DuckDuckGo (default)
    -g, --google            Search Google
    -a, --archive           Search Archive.org
EOF
}

init_defaults() {
    local i

    defaults['browser']="${BROWSER:-xdg-open}"
    defaults['selector']="shell"

    for i in "${!defaults[@]}"; do
        settings["${i}"]="${defaults["$i"]}"
    done
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

encode() {
    "${0%/*}/convert/urlencode.sh" <<< "${1}"
}

get_query() {
    case "${settings['selector']}" in
        dmenu )
            require 'dmenu' || return 1
            printf '\n' | dmenu -p "Search: "
            ;;
        rofi )
            require 'rofi' || return 1
            printf '\n' | rofi -dmenu -p "Search: "
            ;;
        shell )
            read -rp "Search: "
            printf '%s\n' "${REPLY}"
            unset REPLY
            ;;
        zenity )
            require 'zenity' || return 1
            printf '\n' | zenity --list --title="Search" --column="Query"
            ;;
    esac
}

search_query() {
    local query uri

    query="$(get_query)" || return 1
    [[ -z "${query}" ]] && return 1

    uri="${settings['engine']}$(encode "${query}")" || return 1
    "${settings['browser']}" "${uri}" & disown
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hdrszw:Dgaw \
        --longoptions help,dmenu,rofi,shell,zenity,browser: \
        --longoptions ddg,google,archive \
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
            -s | --shell )      settings['selector']="shell";;
            -z | --zenity )     settings['selector']="zenity";;
            -D | --ddg )        settings['engine']='duckduckgo.com/?q=';;
            -g | --google )     settings['engine']='www.google.come/search?q=';;
            -a | --archive )    settings['engine']='archive.org/search?query=';;
            -w | --browser )    settings['browser']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require "${settings['browser']}" || return 1
    search_query
}

main "${@}"
