#!/usr/bin/env bash

show_help() {
    cat << EOF
Git-Clone wrapper

USAGE: ${0##*/} [OPTIONS] SLUG [OUTDIR]

OPTIONS:
    -h, --help          Show this help message
    -g, --github        Pull from ssh://git@github (default)
    -G, --github-http   Pull from http://github.com
    -l, --gitlab        Pull from gitlab
    -s, --suckless      Pull from suckless
    -b, --base-url URL  Pull from custom URL

SLUG:
    Slug should follow the format 'owner/repo'
EOF
}

is_slug() {
    [[ "${1}" == *"/"* ]] || return 1
    [[ "${1}" =~ .+/.+ ]] || return 1
    return 0
}

main() {
    local opts url
    url="git@github.com:"
    opts="$(getopt \
        --options hgGlsb: \
        --longoptions help,github,github-http,gitlab,suckless,base-url: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )           show_help; return 0;;
            -g | --github )         url="git@github.com:";;
            -G | --github-http )    url="https://github.com";;
            -l | --gitlab )         url="https://gitlab.com";;
            -s | --suckless )       url="https://git.suckless.org";;
            -b | --base-url )       url="${2}"; shift;;
            -- )                    shift; break;;
            * )                     break;;
        esac
        shift
    done

    if ! is_slug "${1}"; then
        printf '\e[0;31mERROR\e[0m: Must provide valid USER/REPO slug!\n' >&2
        return 1
    fi

    set -- "${url}/${1}.git" "${@:2}"
    git clone "${@}"
}

main "${@}"
