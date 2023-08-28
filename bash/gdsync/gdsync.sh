#!/usr/bin/env bash
#
# Synchronize Google Drive if out of date
#
# Requires:
#   - rclone

show_help() {
    cat << EOF
Synchronize Google Drive if out of date

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -f, --force         Assume yes for interaction prompts
    -r, --repo NAME     Use NAME as repository name (default: ${defaults['repo']})
    -p, --path PATH     Compare local PATH to repository (default: ${defaults['path']})
EOF
}

init_defaults() {
    local i

    defaults['repo']="GDrive"
    defaults['path']="${HOME}/GDrive"

    for i in "${!defaults[@]}"; do
        settings["${i}"]="${defaults["$i"]}"
    done
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

confirm() {
    local reply
    read -rn 1 -i 'n' -p "${1}? (y/N): " reply
    [[ "${reply,,}" == "y" ]]
}

is_online() {
    ping -c 1 '8.8.8.8' |& \
        grep --quiet --ignore-case 'unreachable'
}

is_different() {
    rclone check "${settings['repo']}:" "${settings['path']}" |& \
        grep --quiet ' ERROR :'
}

gsync() {
    rclone --quiet 'sync' "${settings['repo']}:" "${settings['path']}"
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hfr:p: \
        --longoptions help,force,repo:,path: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    init_defaults

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -f | --force )      settings['force']="1";;
            -r | --repo )       settings['repo']="${2}"; shift;;
            -p | --path )       settings['path']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    require 'rclone' || return 1

    if ! is_online; then
        printf 'Must be connected to the internet\n' >&2
        return 1
    fi

    if ! [[ -d "${settings['path']}" ]]; then
        if (( settings['force'] == 0 )); then
            confirm "Creating missing directory '${settings['path']}'" || \
                return 1
        fi
        mkdir --parents "${settings['path']}"
    fi

    is_different || return 0
    gsync
}

main "${@}"
