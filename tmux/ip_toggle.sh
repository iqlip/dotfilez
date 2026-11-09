#!/usr/bin/env bash
mode=$(tmux show -gqv @ip_mode 2>/dev/null)
if [[ $mode == box ]]; then
  cache="/tmp/htb_active_$UID"
  if [[ -f $cache ]]; then
    read -r name ip < "$cache"
    [[ -n $ip ]] && { printf '#[fg=#9fef00]󰆧 %s' "$ip"; exit 0; }
  fi
  printf '#[fg=#6c7086]󰆧 no box'
else
  ip=$("$HOME/Scripts/localip.sh" 2>/dev/null)
  printf '#[fg=#89b4fa]󰛳 %s' "${ip:-?}"
fi
