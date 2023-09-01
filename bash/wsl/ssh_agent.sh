#!/usr/bin/env bash
#
# Forward SSH Auth requests to Windows, Keychain or warn
#
# Intended to be sourced directly from ~/.bashrc

require() {
    command -v "${1}" &>/dev/null
}

if require 'socat' && require 'npiperelay.exe'; then
    if ! pgrep --full 'npiperelay\.exe.*openssh-ssh-agent' &>/dev/null; then
        [[ -S "${SSH_AUTH_SOCK}" ]] && rm --force "${SSH_AUTH_SOCK}"
        listen="UNIX-LISTEN:${SSH_AUTH_SOCK},fork"
        relay="EXEC:'npiperelay.exe -ei -s //./pipe/openssh-ssh-agent',nofork"
        ( setsid socat "${listen}" "${relay}" & disown ) &>/dev/null
        unset listen relay
    fi
elif require 'keychain'; then
    eval "$(keychain --eval --agents 'ssh' "${SSH_HOME}/id_rsa")"
else
    printf 'Failed to configure ssh-agent\n' >&2
fi

unset -f require
