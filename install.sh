#!/bin/bash
# AKM (Agent Kit Manager) — Bootstrap installer
# Copies the CLI binary and shell init script. Run `akm setup` after.
#
# Prerequisites: jq
#
# Usage:
#   git clone https://github.com/<org>/akm ~/akm
#   bash ~/akm/install.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"

# --- Check dependencies ---
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  echo "Install it first:  sudo apt-get install jq  (or brew install jq)" >&2
  exit 1
fi

# --- Install CLI binary ---
mkdir -p "$HOME/.local/bin"
cp "$REPO/bin/akm" "$HOME/.local/bin/akm"
chmod +x "$HOME/.local/bin/akm"
echo "Installed akm to ~/.local/bin/akm"

# Warn if ~/.local/bin is not on PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo ""
  echo "Warning: ~/.local/bin is not on your PATH."
  echo "Add to your shell profile:  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# --- Install shell init script + tools config ---
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/akm"
mkdir -p "$DATA_DIR/shell"
cp "$REPO/shell/akm-init.sh" "$DATA_DIR/shell/akm-init.sh"
cp "$REPO/tools.json" "$DATA_DIR/tools.json"
echo "Installed shell init to $DATA_DIR/shell/akm-init.sh"

# --- Save repo path to config ---
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/akm/config"
if [[ -f "$CONFIG_FILE" ]]; then
  # Update or append AKM_REPO in existing config
  if grep -q '^AKM_REPO=' "$CONFIG_FILE"; then
    sed -i "s|^AKM_REPO=.*|AKM_REPO=\"$REPO\"|" "$CONFIG_FILE"
  else
    echo "AKM_REPO=\"$REPO\"" >> "$CONFIG_FILE"
  fi
else
  mkdir -p "$(dirname "$CONFIG_FILE")"
  echo "AKM_REPO=\"$REPO\"" > "$CONFIG_FILE"
fi

# --- Done ---
echo ""
echo "Run 'akm setup' to configure features and wire shell integration."
