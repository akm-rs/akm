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

# --- Install shell init script ---
SHELL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/akm/shell"
mkdir -p "$SHELL_DIR"
cp "$REPO/shell/akm-init.sh" "$SHELL_DIR/akm-init.sh"
echo "Installed shell init to $SHELL_DIR/akm-init.sh"

# --- Done ---
echo ""
echo "Run 'akm setup' to configure features and wire shell integration."
