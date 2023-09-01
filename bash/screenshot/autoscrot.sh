#!/usr/bin/env bash
#
# Take a screenshot with scrot, then place in outdir

show_help() {
    cat << EOF
Take a screenshot (PNG) with scrot, then place in outdir

USAGE: ${0##*/} [OPTIONS] [OUTDIR] [SCROT_ARGS]

OPTIONS:
    -h, --help          Show this help message

OUTDIR:
Specify parent directory of all screenshots, by default:

    '${png}'
EOF
}

main() {
    local png
    png="${HOME}/Pictures/Screenshots"

    if [[ "${1}" =~ -(h|-help) ]]; then
        show_help
        return 0
    elif [[ -n "${1}" ]]; then
        png="$(realpath "${1}")" || return 1
        shift
    fi

    if ! command -v 'scrot' &>/dev/null; then
        printf 'Missing required application: scrot\n' >&2
        return 1
    fi

    png+="/$(date --iso-8601)/$(date '+%F-%H-%M-%S').png"
    mkdir --parents "${png%/*}"
    scrot "${@}" -- "${png}"
}

main "${@}"
