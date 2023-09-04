#!/usr/bin/env bash
#
# Git-Clone wrapper

show_help() {
    cat << EOF
Git-Clone wrapper

USAGE: ${0##*/} [OPTIONS] SLUG [OUTDIR]

OPTIONS:
    -h, --help          Show this help message
    -g, --github        Pull from github (default)
    -l, --gitlab        Pull from gitlab
    -s, --suckless      Pull from suckless
    -b, --base-url URL  Pull from custom URL

SLUG:
    Slug should follow the format 'owner/repo'
EOF
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

is_online() {
    ping -qc 1 '8.8.8.8' | grep --quiet --ignore-case 'unreachable' || return 0
    printf 'Requires an internet connection\n' >&2
    return 1
}

main() {
    local opts base default_base
    opts="$(getopt \
        --options hglsb: \
        --longoptions help,github,gitlab,suckless,base-url: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    default_base='https://github.com'

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -g | --github )     base="${default_base}";;
            -l | --lab )        base='https://gitlab.com';;
            -s | --suckless )   base='https://git.suckless/org';;
            -b | --base-url )   base="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require 'git' || return 1
    is_online || return 1

    if [[ -z "${1}" ]]; then
        printf 'No slug specified\n' >&2
        return 1
    elif [[ "${1}" != */* ]]; then
        printf 'Invalid slug format' >&2
        return 1
    fi

    git clone "${base:-${default_base}}/${1}.git" "${2:-${PWD}/${1##*/}}"
}

main "${@}"
