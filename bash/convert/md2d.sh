#!/usr/bin/env bash
#
# Convert markdown to other document formats

show_help() {
    cat << EOF
Convert markdown to other document formats

USAGE: ${0##*/} [OPTIONS] MD [OUTDIR]

OPTIONS:
    -h, --help                  Show this help message
    -r, --reference-path PATH   Specify path to reference file(s)
                                (default: ${defaults['refs']})
    -R, --no-reference          Do not use a reference file
    -f, --from MD_TYPE          Specify MD's markdown type (default: ${defaults['from']})
    -t, --to DOC_FORMAT         Specify format to convert to (default: ${defaults['to']})

SUPPORTED MD_TYPE:
    php                         PHP Markdown Extra
    mmd                         MultiMarkdown
    pl                          Markdown.pl
    cm                          CommonMark
    cmx                         CommonMark with pandoc extensions
    gfm                         Github flavored markdown (default)
    md                          "Plain" markdown

SUPPORTED DOC_FORMAT:
    docx                        Modern MSO Word (default)
    doc                         Legacy MSO Word
    pdf                         PDF
    html                        Single HTML file
EOF
}

init_defaults() {
    local i

    defaults['refs']="${XDG_CONFIG_HOME:-${HOME}/.config}/$(basename "${0%.*}")"
    defaults['from']="gfm"
    defaults['to']="docx"
    defaults['root']="${PWD}"

    for i in "${!defaults[@]}"; do
        settings["${i}"]="${defaults["$i"]}"
    done
}

require() {
    command -v "${1}" &>/dev/null && return 0
    printf 'Missing required application: %s\n' "${1}" >&2
    return 1
}

get_formats() {
    case "${settings['from'],,}" in
        php )   settings['from']='markdown_phpextra';;
        mmd )   settings['from']='markdown_mmd';;
        pl )    settings['from']='markdown_strict';;
        cm )    settings['from']='commonmark';;
        cmx )   settings['from']='commonmark_x';;
        gfm )   settings['from']='gfm';;
        md )    settings['from']='md';;
        * )
            printf 'Unknown markdown format: %s\n' "${settings['from']}" >&2
            return 1
            ;;
    esac

    case "${settings['to'],,}" in
        doc )   settings['to']='doc';;
        docx )  settings['to']='docx';;
        html )  settings['to']='html';;
        pdf )   settings['to']='pdf';;
        * )
            printf 'Unknown document format: %s\n' "${settings['to']}" >&2
            return 1
            ;;
    esac

    return 0
}

get_outfile() {
    local root

    if ! settings['outfile']="$(realpath "${settings['root']}" 2>/dev/null)"; then
        printf 'Cannot locate output directory: %s\n' "${settings['root']}" >&2
        return 1
    fi

    settings['outfile']+="/$(basename "${1%.*}").${settings['to']}"

    if [[ -s "${settings['outfile']}" ]]; then
        printf 'Output file already exists: %s\n' "${settings['outfile']}" >&2
        return 1
    fi

    return 0
}

get_reference() {
    [[ -z "${settings['refs']}" ]] && return 0
    settings['reference']="$(realpath "${settings['refs']}" 2>/dev/null)"
    if [[ -z "${settings['reference']}" ]]; then
        printf 'Cannot locate references root: %s\n' "${settings['refs']}" >&2
        return 1
    fi
    settings['reference']+="/reference.${settings['to']}"
    return 0
}

convmd() {
    local -a args

    args=(
        "--from=${settings['from']}"
        "--to=${settings['to']}"
        "--out=\"${settings['outfile']}/\""
    )

    [[ -n "${settings['reference']}" ]] && \
        args+=( "--reference-doc\"${settings['reference']}\"" )

    eval set -- "${args[@]}" "${1}"
    pandoc "${@}"
}

main() {
    local -A defaults settings
    local opts
    opts="$(getopt \
        --options hr:Rf:t: \
        --longoptions help,reference-path:,no-reference,from:,to: \
        --name "${0##*/}" \
        -- "${@}" \
    )"

    eval set -- "${opts}"
    while true; do
        case "${1}" in
            -h | --help )           show_help; return 0;;
            -r | --reference-path ) settings['refs']="${2}"; shift;;
            -R | --no-reference )   unset settings['refs'];;
            -f | --from )           settings['from']="${2}"; shift;;
            -t | --to )             settings['to']="${2}"; shift;;
            -- )                    shift; break;;
            * )                     break;;
        esac
        shift
    done

    require 'pandoc' || return 1

    if [[ -z "${1}" ]]; then
        printf 'No markdown file specified\n' >&2
        return 1
    elif ! [[ -s ${1} ]]; then
        printf 'Markdown file does not exist or is empty\n' >&2
        return 1
    fi

    [[ -n "${2}" ]] && settings['root']="${2}"

    get_formats || return 1
    get_outfile "${1}" || return 1
    get_reference || return 1

    convmd "${1}"
}

main "${@}"
