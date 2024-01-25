#!/usr/bin/env bash
#
# CD, but with bookmarks/aliases

bm() {
    local -A defaults settings config
    local opts bm_path
    opts="$(getopt \
        --options hea:dlc:u: \
        --longoptions help,edit,add:,delete,list,config:,update: \
        --name "${FUNCNAME[0]}" \
        -- "${@}" \
    )"

    _show_help() {
        cat << EOF
CD, but with bookmarks/aliases

USAGE: ${FUNCNAME[1]} [OPTIONS] BOOKMARK

OPTIONS:
    -h, --help          Show this help message
    -e, --edit          Edit the configuration file (\$EDITOR or vi)
    -a, --add PATH      Add PATH as BOOKMARK
    -u, --update PATH   Set BOOKMARK as PATH
    -d, --delete        Remove BOOKMARK from configuration
    -l, --list          List existing bookmarks, filter by BOOKMARK if specified (regex)
    -c, --config PATH   Use PATH as config (default: '${defaults[config]}')
EOF
    }

    _init_defaults() {
        local i

        defaults['config']="${XDG_CONFIG_HOME:-${HOME}/.config}"
        defaults['config']+="/bookmarks/bm.rc"
        defaults['action']="cd"

        for i in "${!defaults[@]}"; do
            settings["${i}"]="${defaults["$i"]}"
        done
    }

    _parse_config() {
        local -a lines
        local i

        mapfile -t lines < "${settings['config']}"

        for i in "${lines[@]}"; do
            config["${i%% = *}"]="${i#* = }"
        done
    }

    _add() {
        if [[ -n "${config["${1}"]}" ]]; then
            printf 'Bookmark is already defined\n' >&2
            return 1
        fi
        printf '%s = %s\n' \
            "${1}" "${settings['path']}" >> "${settings['config']}"
    }

    _remove() {
        if [[ -z "${config["${1}"]}" ]]; then
            printf 'Bookmark is not defined\n' >&2
            return 1
        fi
        sed --in-place "/^${1} = /d" "${settings['config']}"
    }

    _list() {
        sed --quiet "/${1}/p" "${settings['config']}"
    }

    _update() {
        remove "${1}" && add "${1}"
    }

    _edit() {
        "${EDITOR:-$(command -v 'vi')}" "${settings['config']}"
    }

    _init_config() {
        [[ "${settings['config']%/*}" != "${settings['config']}" ]] && \
            mkdir --parents "${settings['config']%/*}"
        touch -a "${settings['config']}"
    }

    _init_defaults

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 1;;
            -d | --delete )     settings['action']="remove";;
            -l | --list )       settings['action']="list";;
            -c | --config )     settings['config']="${2}"; shift;;
            -e | --edit )       settings['action']="edit";;
            -a | --add )
                settings['action']="add"
                settings['path']="${2}"
                shift
                ;;
            -u | --update )
                settings['action']="update"
                settings['path']="${2}"
                shift
                ;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    if ! [[ "${settings['action']}" =~ (list|edit) ]]; then
        if [[ -z "${1}" ]]; then
            printf 'No bookmark specified\n' >&2
            return 1
        fi
    fi

    _init_config
    _parse_config

    if [[ -n "${settings['path']}" ]]; then
        settings['path']="$(realpath "${settings['path']}")" || return 1
        if [[ -f "${settings['path']}" ]]; then
            printf 'Path must be a directory: %s\n' "${settings['path']}" >&2
            return 1
        fi
    fi

    case "${settings['action']}" in
        add )       _add "${*}" || return 1;;
        remove )    _remove "${*}" || return 1;;
        list )      _list "${*:-.*}" || return 1;;
        update )    _update "${*}" || return 1;;
        edit )      _edit || return 1;;
        cd )
            if [[ -z "${config["${*}"]}" ]]; then
                printf 'Bookmark is not defined: %s\n' "${*}" >&2
                return 1
            fi

            cd "${config["${*}"]}" || return 1
            ;;
    esac

    return 0
}
