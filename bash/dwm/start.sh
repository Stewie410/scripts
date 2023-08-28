#!/usr/bin/env bash
#
# Start dwm & other apps
#
# Requires:
#   - dwm
#
# Optional:
#   - hsetroot
#   - nitrogen
#   - picom
#   - unclutter
#   - polkit-gnome-authentication-agent-1
#   - xautolock
#   - dunst
#   - kdwconnect
#   - dwmblocks

require() {
    local err

    while (( $# > 0 )); do
        if ! command -v "${1}" &>/dev/null; then
            printf 'Missing required application: %s\n' "${1}" >&2
            (( err++ ))
        fi
        shift
    done

    return "${err:-0}"
}

# autostart
require 'hsetroot' && { hsetroot -solid '#000000'; }
require 'nitrogen' && { nitrogen --restore &>/dev/null; }
require 'picom' && { picom &>/dev/null & disown; }
require 'unclutter' && { unclutter --jitter 50 &>/dev/null & disown; }
require 'kdeconnect' && { kdeconnect &>/dev/null & disown; }
require 'polkit-gnome-authentication-agent-1' && {
    polkit-gnome-authentication-agent-1 &>/dev/null & disown;
}
require 'xautolock' 'dm-tool' && {
    xautolock -time -detectsleep -locker 'dm-tool lock' &>/dev/null & disown;
}
require 'dunst' && {
    dunst --config "${XDG_CONFIG_HOME}/dunst/dunstrc" &>/dev/null & disown;
}

# wm
require 'dwmblocks' && dwmblocks &
exec "$(command -v 'dwm')" >/dev/null
