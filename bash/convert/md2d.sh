#!/usr/bin/env bash

err() {
    printf '\e[0;31mERROR\e[0m: %s\n' "${@}" >&2
}

show_help() {
    cat << EOF
Convert (pandoc) markdown to other formats

USAGE: ${0##*/} [OPTIONS] MARKDOWN [...]

OPTIONS:
    -h, --help          Show this help message
    -c, --config PATH   Same as pandoc(1) '--data-dir'
    -f, --from FMT      Markdown flavor (default: gfm)
    -t, --to FMT        Output format (default: docx)

MARKDOWN FLAVOR:
    php                 PHP Markdown Extra
    mmd                 MultiMarkdown
    pl                  Markdown.pl
    cm                  CommonMark
    cmx                 CommonMark with pandoc extensions
    gfm                 Github Flavored Markdown
    md                  "Plain" markdown

OUTFILE FORMAT:
    doc                 Legacy MSO Word
    docx                MSO Word
    pdf                 PDF
    html                Self-contained HTML
EOF
}

real_path() {
    readlink --canonicalize-missing "${1}" && return 0
    err "Path is not valid: ${1}"
    return 1
}

get_fmt() {
    local fmt
    case "${1}" in
        php )   fmt="markdown_phpextra";;
        mmd )   fmt="markdown_mmd";;
        pl )    fmt="markdown_strict";;
        cm )    fmt="commonmark";;
        cmx )   fmt="commonmark_x";;
        gfm )   fmt="gfm";;
        md )    fmt="md";;
        doc )   fmt="doc";;
        docx )  fmt="docx";;
        pdf )   fmt="pdf";;
        html )  fmt="html";;
        * )
            err "Unknown document format: ${1}"
            return 1
            ;;
    esac
    printf '%s\n' "${fmt}"
    return 0
}

main() {
    local opts config from to err
    config="${XDG_DATA_HOME:-$HOME/.local/share}/pandoc"
    from="gfm"
    to="docx"
    opts="$(getopt \
        --options hc:f:t: \
        --longoptions help,config:,from:,to: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )   show_help; return 0;;
            -c | --config ) config="$(real_path "${2}")" || return 1; shift;;
            -f | --from )   from="$(get_fmt "${2}")"; shift;;
            -t | --to )     to="$(get_fmt "${2}")"; shift;;
            -- )            shift; break;;
            * )             break;;
        esac
        shift
    done

    local -a args
    args=(
        --data-dir="${config}"
        --from="${from}"
        --to="${to}"
    )
    while (( $# > 0 )); do
        pandoc "${args[@]}" --out="${1%.*}.${to}" "${1}" \
            || (( err++ ))
        shift
    done

    (( err == 0 )) && return 0
    return 1
}

main "${@}"
