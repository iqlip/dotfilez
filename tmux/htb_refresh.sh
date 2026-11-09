#!/usr/bin/env bash
cache="/tmp/htb_active_$UID"
tok=$(<"$HOME/.config/htb/token") 2>/dev/null
[[ -z $tok ]] && exit 0
curl -sS --max-time 8 'https://labs.hackthebox.com/api/v4/machine/active' \
  -H "Authorization: Bearer $tok" \
  | jq -r '.info | select(.!=null) | "\(.name) \(.ip)"' > "$cache.tmp" 2>/dev/null
if [[ -s $cache.tmp ]]; then
  mv "$cache.tmp" "$cache"        # box found -> update
else
  rm -f "$cache.tmp" "$cache"     # no box -> clear (shows "no box")
fi
