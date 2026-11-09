#!/usr/bin/env bash
#===================== iqlip tmux setup =====================#
set -e

# typewriter effect
typeit() { local s=$1 i; for ((i=0; i<${#s}; i++)); do printf '%s' "${s:$i:1}"; sleep 0.03; done; echo; }

# run from the script's own folder, wherever it's called from
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

typeit "[+] Installing requirements..."
sudo apt update
sudo apt install -y tmux xclip curl jq git unzip fontconfig

typeit "[+] Setting up iqlip tmux config..."
cp "$DIR/iqlip_tmux.conf" ~/.tmux.conf
mkdir -p ~/Scripts
for s in vpnIP_VM.sh localip.sh htb_name.sh htb_refresh.sh ip_toggle.sh; do
  cp "$DIR/$s" ~/Scripts/
  chmod +x ~/Scripts/"$s"
done

typeit "[+] Adding TPM (tmux plugin manager)..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
  echo "    TPM already present, skipping."
fi

typeit "[+] Preparing HTB token file..."
mkdir -p ~/.config/htb
if [ ! -s ~/.config/htb/token ]; then
  touch ~/.config/htb/token
  chmod 600 ~/.config/htb/token
  echo "    Created ~/.config/htb/token (empty) — paste your HTB App Token into it."
else
  echo "    Token file already set, skipping."
fi

typeit "[+] Installing Hack Nerd Font..."
if ! fc-list | grep -qi "Hack Nerd Font"; then
  mkdir -p ~/.local/share/fonts/HackNerdFont
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/Hack.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
  unzip -o "$tmp/Hack.zip" -d ~/.local/share/fonts/HackNerdFont >/dev/null
  rm -rf "$tmp"
  fc-cache -f >/dev/null
  echo "    Hack Nerd Font installed."
else
  echo "    Hack Nerd Font already present, skipping."
fi

typeit "[-] D0ne!"
echo
echo "─────────────────────────────────────────────"
echo " Next steps:"
echo "  1. Set your terminal font to 'Hack Nerd Font'"
echo "  2. Paste your HTB App Token into ~/.config/htb/token"
echo "  3. Open tmux, press Ctrl+a then Shift+I to install plugins"
echo "  4. Open a new terminal for everything to apply"
echo "─────────────────────────────────────────────"
