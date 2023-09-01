#!/usr/bin/env bash
#
# Start wsl-vpnkit for DNS & Networking support with VPNs...
# # https://github.com/sakai135/wsl-vpnkit
#
# Intended to be sourced directly from ~/.bashrc

if wsl.exe --list | grep --quiet 'wsl-vpnkit'; then
    wsl.exe --distribution 'wsl-vpnkit' 'service wsl-vpnkit start'
fi
