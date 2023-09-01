#!/usr/bin/env bash
#
# Make and change directory

mkcd() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hd:w: \
        --longoptions help,date:,working: \
        --name "${FUNCNAME[0]}" \
        -- "${@}" \
    )"

    _show_help() {
        cat << EOF
Make and change directory

USAGE: ${FUNCNAME[1]} [OPTIONS] DIR [SUBDIR [...]]

OPTIONS:
    -h, --help          Show this help message
    -d, --date DATE     Make and change to DATE's working directory
                        See date(1) for valid formats
    -w, --working PATH  Use PATH as working directory parent
                        (default: ${defaults['working']})
EOF
    }

    _is_valid_format() {
        date --date="${1}" &>/dev/null
    }

    defaults['working']="${WORKING_DIR:-${HOME}/working}"
    settings['working']="${defaults['working']}"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -d | --date )       settings['date']="${2}"; shift;;
            -w | --working )    settings['working']="${2}"; shift;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    settings['working']="$(realpath "${settings['working']}")" || return 1

    if [[ -n "${settings['date']}" ]]; then
        if ! _is_valid_format "${settings['date']}"; then
            printf 'Invalid date format: %s\n' "${settings['date']}" >&2
            return 1
        fi
        settings['working']+="/$(date --date="${settings['date']}" --iso-8601)"
        set -- "${settings['working']}"
    fi

    while (( $# > 0 )); do
        mkdir --parents "${1}"
        cd "${1}" || return 1
        shift
    done

    return 0
}

mdot() {
    mkcd --date 'today'
}

mdoy() {
    mkcd --date 'yesterday'
}

mdod() {
    mkcd --date "${1}"
}
