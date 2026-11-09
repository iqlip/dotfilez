#!/usr/bin/env bash
cache="/tmp/htb_active_$UID"; ttl=600

if ! ip -4 addr show tun0 2>/dev/null | grep -q 'inet '; then
  rm -f "$cache"           
  exit 0
fi

tok=$(<"$HOME/.config/htb/token") 2>/dev/null
if [[ -n $tok ]]; then
  age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
  if [[ ! -f $cache || $age -gt $ttl ]]; then
    ( curl -sS --max-time 5 'https://labs.hackthebox.com/api/v4/machine/active' \
        -H "Authorization: Bearer $tok" \
        | jq -r '.info | select(.!=null) | "\(.name) \(.ip)"' > "$cache.tmp" \
        && mv "$cache.tmp" "$cache" ) >/dev/null 2>&1 &
  fi
fi
[[ -f $cache ]] || exit 0
read -r name ip < "$cache"
[[ -n $name ]] && printf '#[fg=#9fef00]󰆧 %s' "$name"
