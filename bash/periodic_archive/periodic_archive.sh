#!/usr/bin/env bash
#
# Create full or incremental archives

show_help() {
    cat << EOF
Create full or incremental archives

USAGE: ${0##*/} [OPTIONS] SOURCE DESTINATION

OPTIONS:
    -h, --help              Show this help message
    -i, --incremental       Create an incremental archive
    -f, --full              Create a full archive (default)
    -e, --excludes PATH     Specify path to excludes file
                            (default: DESTINATION/excludes)
EOF
}

valid_path() {
    local p

    if [[ -z "${2}" ]]; then
        printf 'No %s specified\n' "${1}" >&2
        return 1
    fi

    if ! p="$(realpath "${2}" 2>/dev/null)"; then
        printf 'Invalid %s path format: %s\n' "${@}" >&2
        return 1
    fi

    printf '%s\n' "${p}"
    return 0
}

incremental_archive() {
    _archive() {
        tar \
            --create \
            --gzip \
            --verbose \
            --file="${tgz}" \
            --level="1" \
            --listed-incremental="${snar}" \
            --exclude-from="${excludes}" \
            --directory="${1}" \
            .
    }

    local tgz snar
    tgz="${2}/$(date --iso-8601).tgz"
    snar="${2}/snar"

    if [[ -s "${tgz}" ]]; then
        printf 'Destination file already exists: %s\n' "${tgz}" >&2
        return 1
    fi

    if ! _archive "${1}"; then
        printf 'Failed to create full archive: %s -> %s\n' "${1}" "${tgz}" >&2
        return 1
    fi

    return 0
}

full_archive() {
    _archive() {
        tar \
            --create \
            --gzip \
            --verbose \
            --file="${tgz}" \
            --exclude-from="${excludes}" \
            --directory="${1}" \
            .
    }

    local tgz
    tgz="${2}/$(date --iso-8601).tgz"

    if [[ -s "${tgz}" ]]; then
        printf 'Destination file already exists: %s\n' "${tgz}" >&2
        return 1
    fi

    if ! _archive "${1}"; then
        printf 'Failed to create full archive: %s -> %s\n' "${1}" "${tgz}" >&2
        return 1
    fi

    return 0
}

main() {
    local opts inc src dst excludes
    opts="$(getopt \
        --options hife: \
        --longoptions help,incremental,full,excludes: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )           show_help; return 0;;
            -i | --incremental )    inc="1";;
            -f | --full )           unset inc;;
            -e | --excludes )       excludes="${2}"; shift;;
            -- )                    shift; break;;
            * )                     break;;
        esac
        shift
    done

    if (( EUID != 0 )); then
        printf '%s requires root priviledges\n' "${0##*/}" >&2
        return 1
    fi

    src="$(valid_path "${1}")" || return 1
    if ! [[ -d "${src}" ]]; then
        printf 'Cannot locate source path: %s\n' "${src}" >&2
        return 1
    fi

    dst="$(valid_path "${2}")" || return 1
    if [[ -f "${dst}" ]]; then
        printf 'Destination cannot be a file: %s\n' "${dst}" >&2
        return 1
    fi
    mkdir --parents "${dst}"

    [[ -z "${excludes}" ]] && excludes="${dst}/excludes"
    valid_path "${excludes}" >/dev/null || return 1
    excludes="$(realpath "${excludes}")"
    mkdir --parents "${excludes%/*}"
    touch -a "${excludes}"

    if [[ -n "${inc}" ]]; then
        incremental_archive "${src}" "${dst}" && return 0
    else
        full_archive "${src}" "${dst}" && return 0
    fi

    return 1
}

main "${@}"
