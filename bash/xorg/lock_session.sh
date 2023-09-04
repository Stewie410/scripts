#!/usr/bin/env bash
#
# Lock the X session (dm-tool)

if ! command -v 'dm-tool' &>/dev/null; then
    printf 'Missing required application: dm-tool\n' >&2
    return 1
fi

XDG_SEAT_PATH='/org/freedesktop/Displaymanager/Seat0' \
    dm-tool lock
