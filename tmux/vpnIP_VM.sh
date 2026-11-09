#!/usr/bin/env bash
# VPN status for tmux status bar.
# Connected    -> green shield + tun IP   󰦝 10.10.14.5
# Disconnected -> dim red shield          󰦞 off
iface="${1:-tun0}"
ip=$(ip -4 -br addr show "$iface" 2>/dev/null | awk '{sub(/\/.*/,"",$3); print $3}')
if [[ -n $ip ]]; then
    printf '#[fg=#a6e3a1]󰦝 %s' "$ip"
else
    printf '#[fg=#f38ba8]󰦞 off'
fi
