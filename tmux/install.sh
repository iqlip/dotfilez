#!/usr/bin/env bash
# ============================================================
#  iqlip tmux — installer
#  Installs the tmux config, status-bar scripts and font.
#  Safe to run again at any time.
# ============================================================
set -euo pipefail

# ---- settings ----------------------------------------------
CONF_SRC="iqlip_tmux.conf"
CONF_DST="$HOME/.tmux.conf"
SCRIPT_DIR="$HOME/Scripts"
SCRIPTS=(vpnIP_VM.sh localip.sh htb_name.sh htb_refresh.sh ip_toggle.sh tmux_cheatsheet.sh)
PACKAGES=(tmux xclip curl jq unzip fontconfig iproute2)
TOKEN_FILE="$HOME/.config/htb/token"
FONT_NAME="Hack Nerd Font"
FONT_DIR="$HOME/.local/share/fonts/HackNerdFont"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
MIN_TMUX="3.4"

SKIP_PACKAGES=0
SKIP_FONT=0

# ---- output helpers ----------------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; RED=''; GREEN=''; YELLOW=''; BLUE=''; RESET=''
fi

step() { printf '\n%s==>%s %s%s%s\n' "$BLUE" "$RESET" "$BOLD" "$1" "$RESET"; }
ok()   { printf '    %s[ok]%s   %s\n' "$GREEN" "$RESET" "$1"; }
skip() { printf '    %s[skip]%s %s\n' "$DIM" "$RESET" "$1"; }
warn() { printf '    %s[warn]%s %s\n' "$YELLOW" "$RESET" "$1"; }
die()  { printf '\n%s[error]%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: ./install.sh [options]

Options:
  --skip-packages   do not install packages (apt or pacman)
  --skip-font       do not install $FONT_NAME
  -h, --help        show this help

Installs:
  $CONF_SRC  ->  $CONF_DST   (existing file is overwritten)
  status-bar scripts  ->  $SCRIPT_DIR/
EOF
}

# ---- arguments ---------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --skip-packages) SKIP_PACKAGES=1 ;;
    --skip-font)     SKIP_FONT=1 ;;
    -h|--help)       usage; exit 0 ;;
    *)               usage >&2; die "Unknown option: $arg" ;;
  esac
done

trap 'die "Install stopped at line $LINENO. Nothing after that step was done."' ERR

# ---- pre-flight checks -------------------------------------
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
  die "Run this as your normal user, not root. It asks for sudo only when needed."
fi

missing_files=()
for f in "$CONF_SRC" "${SCRIPTS[@]}"; do
  if [[ ! -f "$SRC/$f" ]]; then missing_files+=("$f"); fi
done
if (( ${#missing_files[@]} > 0 )); then
  die "Missing files next to install.sh: ${missing_files[*]}"
fi

printf '%siqlip tmux installer%s\n' "$BOLD" "$RESET"
printf '%ssource: %s%s\n' "$DIM" "$SRC" "$RESET"

# ---- 1. packages -------------------------------------------
step "Packages"
if (( SKIP_PACKAGES )); then
  skip "skipped (--skip-packages)"
elif command -v apt-get >/dev/null 2>&1; then
  # Debian, Ubuntu, Kali
  to_install=()
  for p in "${PACKAGES[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then to_install+=("$p"); fi
  done
  if (( ${#to_install[@]} == 0 )); then
    skip "all packages already installed"
  else
    printf '    installing with apt: %s\n' "${to_install[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${to_install[@]}"
    ok "packages installed"
  fi
elif command -v pacman >/dev/null 2>&1; then
  # Arch, Manjaro, EndeavourOS
  to_install=()
  for p in "${PACKAGES[@]}"; do
    if ! pacman -Qi "$p" >/dev/null 2>&1; then to_install+=("$p"); fi
  done
  if (( ${#to_install[@]} == 0 )); then
    skip "all packages already installed"
  else
    printf '    installing with pacman: %s\n' "${to_install[*]}"
    if ! sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
      die "pacman could not install the packages. Update the system first (sudo pacman -Syu), then run this again."
    fi
    ok "packages installed"
  fi
else
  warn "no supported package manager (apt, pacman). Install these yourself: ${PACKAGES[*]}"
fi

# ---- 2. tmux config ----------------------------------------
step "tmux config"
install -m 644 "$SRC/$CONF_SRC" "$CONF_DST"
ok "$CONF_DST"

# ---- 3. scripts --------------------------------------------
step "Status-bar scripts"
mkdir -p "$SCRIPT_DIR"
for s in "${SCRIPTS[@]}"; do
  install -m 755 "$SRC/$s" "$SCRIPT_DIR/$s"
  ok "$SCRIPT_DIR/$s"
done

# ---- 4. HTB token file -------------------------------------
step "HTB token file"
mkdir -p "$(dirname "$TOKEN_FILE")"
chmod 700 "$(dirname "$TOKEN_FILE")"
if [[ -s "$TOKEN_FILE" ]]; then
  chmod 600 "$TOKEN_FILE"
  skip "token already set"
  token_needed=0
else
  touch "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  ok "created empty $TOKEN_FILE"
  token_needed=1
fi

# ---- 5. font -----------------------------------------------
step "$FONT_NAME"
font_installed=0
if (( SKIP_FONT )); then
  skip "skipped (--skip-font)"
elif command -v fc-list >/dev/null 2>&1 && grep -qi "$FONT_NAME" <<<"$(fc-list 2>/dev/null)"; then
  skip "already installed"
else
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/font.zip" "$FONT_URL" \
     && mkdir -p "$FONT_DIR" \
     && unzip -oq "$tmp/font.zip" -d "$FONT_DIR"; then
    fc-cache -f >/dev/null 2>&1 || true
    ok "installed to $FONT_DIR"
    font_installed=1
  else
    warn "font download failed. Icons will show as boxes until it is installed."
  fi
  rm -rf "$tmp"
fi

# ---- 6. tmux version + live reload -------------------------
step "tmux"
if command -v tmux >/dev/null 2>&1; then
  ver="$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -n1 || true)"
  if [[ -z "$ver" ]]; then
    warn "could not read the tmux version"
  elif [[ "$(printf '%s\n%s\n' "$MIN_TMUX" "$ver" | sort -V | head -n1)" != "$MIN_TMUX" ]]; then
    warn "tmux $ver found. This config needs $MIN_TMUX or newer (clickable IP, popups)."
  else
    ok "tmux $ver"
  fi
  if tmux info >/dev/null 2>&1; then
    if tmux source-file "$CONF_DST" 2>/dev/null; then
      ok "running tmux reloaded with the new config"
    else
      warn "could not reload the running tmux. Press Ctrl+a then r inside it."
    fi
  else
    skip "tmux is not running, nothing to reload"
  fi
else
  warn "tmux is not installed"
fi

# ---- summary -----------------------------------------------
trap - ERR
printf '\n%s%sDone.%s\n' "$GREEN" "$BOLD" "$RESET"

printf '\n%sNext steps%s\n' "$BOLD" "$RESET"
n=1
if (( font_installed )); then
  printf "  %d. Set your terminal font to '%s'.\n" "$n" "$FONT_NAME"; n=$((n + 1))
fi
if (( token_needed )); then
  printf '  %d. Paste your HTB App Token into %s\n' "$n" "$TOKEN_FILE"; n=$((n + 1))
fi
printf '  %d. Start tmux. Press Ctrl+a then h for the cheat sheet.\n' "$n"
