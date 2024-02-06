#!/usr/bin/env bash
#
# Make and change directory

mkcd() {
    _show_help() {
        cat << EOF
Make and change directory

USAGE: ${FUNCNAME[1]} [OPTIONS] PATH

OPTIONS:
    -h, --help          Show this help message
    -d, --date DATE     Make and change to DATE's working directory
    -w, --working PATH  Use PATH as working directory parent
                        Default: \$WORKING_DIR or \$HOME/working
EOF
    }

    _fdate() {
        date --date="${1}" --iso-8601
    }

    _resolve() {
        realpath "${1}" && return 0
        printf 'Cannot resolve path: %s\n' "${1}" >&2
        return 1
    }

    local opts date working
    opts="$(getopt \
        --options hd:w: \
        --longoptions help,date:,working: \
        --name "${FUNCNAME[0]}" \
        -- "${@}" \
    )"

    working="${WORKING_DIR:-$HOME/working}"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       _show_help; return 0;;
            -d | --date )       date="$(_fdate "${2}")" || return 1; shift;;
            -w | --working )    working="$(_resolve "${2}")" || return 1; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    [[ -n "${date}" ]] && set -- "${working}/${date}"
    mkdir --parents "${1}" || return 1
    cd "${1}" || return 1
}
