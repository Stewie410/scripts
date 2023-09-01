#!/usr/bin/env bash
#
# Encode a file as a URL; or decode to a plain string

show_help() {
    cat << EOF
Encode file as URL data, or decode to plain string

USAGE: ${0##*/} [OPTIONS] [FILE [...]]

OPTIONS:
    -h, --help      Show this help message
    -d, --decode    Decode FILE rather than encode
EOF
}

encode() {
    curl \
        --get \
        --silent \
        --output '/dev/null' \
        --write-out '%{url_effective}' \
        --data-urlencode @- \
        "" | \
    cut --characters="3-"
}

decode() {
    local url
    while read -r url; do
        url="${url//+/ }"
        printf '%b\n' "${url//%/\\x}"
    done
}

main() {
    local opts decode
    opts="$(getopt \
        --options hd \
        --longoptions help,decode \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --decode )     decode="1";;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    (( $# == 0 )) && set -- '/dev/stdin'

    case "${decode:-0}" in
        0 )
            while (( $# > 0 )); do
                encode < "${1}"
                shift
            done
            ;;
        1 )
            while (( $# > 0 )); do
                decode < "${1}"
                shift
            done
            ;;
    esac

    return 0
}

main "${@}"
