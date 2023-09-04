#!/usr/bin/env bash
#
# OpenConnect Helper Script

show_help() {
    cat << EOF
OpenConnect Helper Script

USAGE: ${0##*/} [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -d, --dmenu         Get input with dmenu(1)
    -r, --rofi          Get input with rofi(1)
    -f, --fzf           Get input with fzf(1) & read (default)
    -z, --zentiy        Get input with zenity(1)
    -b, --best          Determine "best" connection (RTT), rather than prompting
    -u, --user USER     Use USER for connections, rather than \$USER
    -c, --config PATH   Read config from PATH
                        (default: ${defaults['config']})
EOF
}

init_defaults() {
    local i

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

parse_config() {
    sed '/^\s*#/d;/^\s*$/d;s/s/^\s*//;s/\s*#.*$//' "${settings['config']}"
}

get_rtt() {
    while (( $# > 0 )); do
        ping -qc 4 "${1}" 2>/dev/null | \
            awk --assign "host=${1}" --field-separator "[ /]" '
                /rtt/ { print $7,host }
            '
        shift
    done
}

get_server() {
    if [[ -n "${settings['auto']}" ]]; then
        get_rtt "${@}" | \
            sort --version-sort | \
            cut --fields="2-" --delimiter=" " | \
            sed 1q
        return
    fi

    case "${settings['selector']}" in
        dmenu )
            printf '%s\n' "${@}" | dmenu -i -p "Server: "
            ;;
        rofi )
            printf '%s\n' "${@}" | rofi -dmenu -p "Server: "
            ;;
        fzf )
            printf '%s\n' "${@}" | fzf -i --no-multi --prompt "Server: "
            ;;
        zenity )
            printf '%s\n' "${@}" | zenity --list --title="Server" --column="FQDN"
            ;;
    esac
}

get_password() {
    case "${settings['selector']}" in
        dmenu )
            password="$(dmenu -p "Password: " <&-)"
            ;;
        rofi )
            password="$(rofi -dmenu -password -p "Password: ")"
            ;;
        fzf )
            read -rsp "Passsword: " password
            ;;
        zenity )
            password="$(zenity --password)"
            ;;
    esac
}

connect() {
    local -a servers
    local server password

    mapfile -t servers < <(parse_config)
    if (( ${#servers[@]} == 0 )); then
        printf 'No servers specified in config: %s\n' \
            "${settings['config']}" >&2
        return 1
    fi

    server="$(get_server "${servers[@]}")" || return 1
    [[ -z "${server}" ]] && return 1
    get_password

    openconnect \
        --user="${settings['user']}" \
        --passwd-on-stdin \
        "${server}" <<< "${password}"
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hdrfzbu:c: \
        --longoptions help,dmenu,rofi,fzf,zenity,best,user:,config: \
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
            -b | --best )       settings['auto']="1";;
            -u | --user )       settings['user']="${2}"; shift;;
            -c | --config )     settings['config']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    if (( EUID != 0 )); then
        printf 'Requires root priviledges\n' >&2
        return 1
    fi

    require 'openconnect' || return 1
    require "${settings['selector']}" || return 1

    settings['config']="$(realpath "${settings['config']}")" || return 1
    mkdir --parents "${settings['config']%/*}"
    touch -a "${settings['config']}"

    connect
}

main "${@}"
