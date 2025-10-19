#!/usr/bin/env bash
#
# Rename all EML files current or given path to human-readable format

show_help() {
    cat << EOF
Rename all EML files current or given path to human-readable format

USAGE: ${0##*/} [OPTIONS] [PATH]

OPTIONS:
    -h, --help              Show this help message
    -l, --max-length NUM    Maximum filename length (default: ${defaults['length']})
EOF
}

init_defaults() {
    defaults['length']="250"
    settings['length']="${defaults['length']}"
}

is_valid_int() {
    if [[ "${1}" =~ [^0-9\-\.] ]]; then
        printf 'Not a number: %s\n' "${1}" >&2
        return 1
    elif (( $1 <= 0 )); then
        printf 'Number must be at least 1: %d\n' "${1}" >&2
        return 1
    fi
    return 0
}

get_header() {
    awk --assign "field=^${1}: " '
        match($0, field) {
            print gensub(field, "", 1, $0)
            exit
        }
    ' "${2}"
}

get_date() {
    get_header 'Date' "${1}" | \
        xargs -I {} date --date="{}" --iso-8601="sec" | \
        tr ':' '-'
}

get_subject() {
    get_header 'Subject' "${1}" | \
        tr --delete '\r\n\0/\\|()<>,.{}'
}

get_filname() {
    local f len
    f="$(get_date "${1}")_$(get_subject "${1}")"
    len="$(( settings['length'] - 4 ))"
    printf '%s\n' "${f:0:$len}.eml"
}

rename_eml() {
    local -A hashes
    local -a files
    local i eml err hash

    mapfile -td $'\0' files < <( \
        find "${1}" -maxdepth 1 -type f -iname '*.eml' -print0 2>/dev/null \
    )

    for (( i = 0; i <= ${#files[@]}; i++ )); do
        eml="${files[$i]}"

        hash="$(sha256sum < "${eml}")"
        if [[ -z "${settings['keep']}" && -n "${hashes["$hash"]}" ]]; then
            rm --force "${eml}"
            continue
        else
            hashes["${hash}"]="1"
        fi

        mv --force "${eml}" "$(get_filename "${eml}")" || (( err++ ))
    done

    [[ -n "${err}" ]] && return 1
    return 0
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hl: \
        --longoptions help,max-length: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    init_defaults

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )       show_help; return 0;;
            -l | --max-length )
                is_valid_int "${2}" || return 1
                settings['length']="${2}"
                shift
                ;;
            -- )                shift; break;;
            * )                 break;;
        esac
        shift
    done

    settings['path']="$(realpath "${1:-${PWD}}" 2>/dev/null)"
    if [[ -z "${settings['path']}" ]]; then
        printf 'Invalid path: %s\n' "${1}" >&2
        return 1
    elif ! [[ -d "${settings['path']}" ]]; then
        printf 'Cannot locate path: %s\n' "${settings['path']}" >&2
        return 1
    fi

    rename_eml "${settings['path']}"
}

main "${@}"
