#!/usr/bin/env bash
# tmux cheat sheet — shown in a popup (prefix + h).
# To add a keybind: add one line in the "CONTENT" block below.
#   key  L|R  "<key>"  "<what it does>"     -> needs Ctrl+a first   (key: max 3 chars)
#   sub  L|R  "<key>"  "<what it does>"     -> key used inside a mode (no prefix)
#   raw  L|R  "<keys>" "<what it does>"     -> works without Ctrl+a
#   head L|R  "<colour>" "<TITLE>"          -> section title
# L / R = left or right column. Keep text plain ASCII so columns stay aligned.

# ---- colours (Catppuccin Mocha) -----------------------------
c() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
R=$'\033[0m'; B=$'\033[1m'
pink=$(c 243 139 168);  green=$(c 166 227 161); blue=$(c 137 180 250)
yellow=$(c 249 226 175); mauve=$(c 203 166 247); peach=$(c 250 179 135)
teal=$(c 148 226 213);  text=$(c 205 214 244);  dim=$(c 108 112 134)
htb=$(c 159 239 0)
keybg=$'\033[48;2;49;50;68m'

# ---- row builders (every row is exactly 42 columns wide) ----
LEFT=(); RIGHT=()
put()  { if [[ $1 == L ]]; then LEFT+=("$2"); else RIGHT+=("$2"); fi; }
# centre text $1 in a field of width $2
mid()  { local s=$1 w=$2 l; l=$(( (w - ${#s}) / 2 )); printf '%*s%s%*s' "$l" '' "$s" "$(( w - ${#s} - l ))" ''; }
head() { put "$1" "${!2}${B}▌ $(printf '%-40s' "$3")${R}"; }
key()  { put "$1" "${pink}Ctrl+a${R} ${keybg}${text}${B}$(mid "$2" 5)${R} ${text}$(printf '%-29s' "$3")${R}"; }
sub()  { put "$1" "       ${keybg}${yellow}${B}$(mid "$2" 5)${R} ${text}$(printf '%-29s' "$3")${R}"; }
raw()  { put "$1" "${yellow}${B}$(printf '%-22s' "$2")${R}  ${text}$(printf '%-18s' "$3")${R}"; }
gap()  { put "$1" "$(printf '%-42s' '')"; }

# ======================= CONTENT =============================
head L pink   "WINDOWS"
key  L "c"   "New window"
key  L ","   "Rename window"
key  L "&"   "Close window"
key  L "1-9" "Go to window number"
key  L "w"   "List all windows"
gap  L
head L green  "SESSION"
key  L "d"   "Leave tmux (keeps running)"
key  L "\$"  "Rename session"
key  L "s"   "Switch session"
gap  L
head L yellow "SCROLL + COPY"
key  L "["   "Enter scroll / copy mode"
sub  L "v"   "Start selecting"
sub  L "y"   "Copy and exit"
sub  L "/"   "Search down (popup)"
sub  L "?"   "Search up (popup)"
sub  L "n"   "Next match (N = previous)"
sub  L "q"   "Exit scroll mode"
key  L "]"   "Paste"

head R blue   "PANES"
key  R "|"   "Split left / right"
key  R "-"   "Split top / bottom"
key  R "x"   "Close pane"
key  R "z"   "Full screen pane (toggle)"
key  R "q"   "Show pane numbers"
key  R "Spc" "Change layout (Space key)"
gap  R
head R htb    "HTB + CONFIG"
key  R "F"   "Refresh HTB box name"
key  R "r"   "Reload config"
key  R "h"   "This cheat sheet"
gap  R
head R mauve  "NO PREFIX NEEDED"
raw  R "Shift+Left/Right"      "Prev / next window"
raw  R "Alt+Arrows"            "Move between panes"
raw  R "Ctrl+Shift+Left/Right" "Move window"
raw  R "Mouse wheel"           "Scroll up"
raw  R "Mouse drag"            "Select and copy"
raw  R "Click the IP"          "My IP / box IP"
# =============================================================

# ---- draw ---------------------------------------------------
blank=$(printf '%-42s' '')
rows=${#LEFT[@]}; (( ${#RIGHT[@]} > rows )) && rows=${#RIGHT[@]}

printf '\033[?25l\n'
printf '  %sprefix%s = %s%sCtrl+a%s   %spress it, let go, then press the key%s\n\n' \
  "$dim" "$R" "$pink" "$B" "$R" "$dim" "$R"
for ((i = 0; i < rows; i++)); do
  printf '  %s %s│%s %s\n' "${LEFT[i]:-$blank}" "$dim" "$R" "${RIGHT[i]:-$blank}"
done
printf '\n  %sshell:%s %stmux ls%s %s·%s %stmux attach%s' \
  "$dim" "$R" "$teal" "$R" "$dim" "$R" "$teal" "$R"
printf '%s                                 press any key to close%s' "$dim" "$R"

# wait for one key, then the popup closes
read -rsn1 _ 2>/dev/null
printf '\033[?25h'
