#!/usr/bin/env bash

log() {
    printf '%s|%s|%s\n' "$(date --iso-8601='sec')" "${FUNCNAME[1]}" "${1}" | \
        tee --append "${log:-/dev/null}"
}
