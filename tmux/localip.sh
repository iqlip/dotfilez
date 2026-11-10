#!/usr/bin/env bash
skip='^(lo|tun|tap|wg|docker|br-|veth|virbr)'

dev=$(ip -4 route show default 2>/dev/null \
  | awk -v skip="$skip" '{for(i=1;i<NF;i++) if($i=="dev" && $(i+1) !~ skip){print $(i+1); exit}}')

if [[ -n $dev ]]; then
  ip=$(ip -4 -br addr show dev "$dev" 2>/dev/null | awk '{sub(/\/.*/,"",$3); print $3; exit}')
fi

if [[ -z $ip ]]; then
  ip=$(ip -4 -br addr show scope global 2>/dev/null \
    | awk -v skip="$skip" '$1 !~ skip {sub(/\/.*/,"",$3); print $3; exit}')
fi

[[ -n $ip ]] && printf '%s\n' "$ip"
