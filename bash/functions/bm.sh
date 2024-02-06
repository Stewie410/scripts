#!/usr/bin/env bash
#
# CD, but with bookmarks/aliases

bm() {
    _show_help() {
        cat << EOF
CD, but with directory bookmarks/aliases

USAGE: ${FUNCNAME[1]} [OPTIONS] [COMMAND] BOOKMARK

OPTIONS:
    -h, --help              Show this help message
    -c, --config PATH       Use PATH as config (default: ${default_cfg})

COMMANDS:
    [cd, nav]               cd to MARK (default command)
    edit                    Open config file in \$EDITOR (default: editor)
    ls, list, print         Print bookmarks to stdout
    rm, rem, del            Remove MARK
    set, add, update PATH   Set MARK as PATH
EOF
    }

    _defined() {
        [[ -n "${marks["$1"]}" ]] && return 0
        printf 'Mark is not defined: %s\n' "${1}" >&2
        return 1
    }

    _resolve() {
        realpath "${1}" && [[ -e "${1}" ]] && return 0
        printf 'Cannot parse path: %s\n' "${1}" >&2
        return 1
    }

    _parse() {
        local k v
        while read -r k _ v; do
            [[ "${k}" =~ ^\s*(#.+)?$ ]] && continue
            marks["${k}"]="${v% #*}"
        done < "${config}"
    }

    _print() {
        local k
        for k in "${!marks[@]}"; do
            printf '%s = %s\n' "${k}" "${marks["$k"]}"
        done
    }

    local -A marks
    local opts default_cfg config
    opts="$(getopt \
        --options hc: \
        --longoptions help,config: \
        --name "${FUNCNAME[0]}" \
        -- "${@}" \
    )"

    default_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/bookmarks/bm.rc"
    config="${default_cfg}"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       _show_help; return 0;;
            -c | --config )     config="$(_resolve "${2}")" || return 1; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    mkdir --parents "${config%/*}"
    touch -a "${config}"
    [[ -s "${config}" ]] && _parse

    case "${1,,}" in
        edit )
            "${EDITOR:-editor}" "${config}" || return 1
            ;;
        ls | list | print )
            _print
            ;;
        rm | rem | del )
            _defined "${2}" || return 1
            unset "marks[${2}]"
            _print > "${config}"
            ;;
        set | add | update )
            _defined "${3}" || return 1
            marks["${3}"]="$(_resolve "${2}")" || return 1
            _print > "${config}"
            ;;
        * )
            [[ "${1}" =~ ^(cd|nav)$ ]] && set -- "${2}"
            _defined "${1}" || return 1
            cd "${marks["$1"]}" || return 1
            ;;
    esac

    return 0
}
