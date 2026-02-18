#!/usr/bin/env bash
# shellcheck shell=bash
# One-command installer for llmshot
# Usage: curl -fsSL https://raw.githubusercontent.com/markabrahams/llmshot/main/install/install.sh | bash
# Or:    curl -fsSL ... | bash -s -- -d /usr/local/bin
# Optional env vars: INSTALL_DIR, LLMSHOT_REPO, LLMSHOT_BRANCH

set -euo pipefail

# ---------------------------
# Config (override with env)
# ---------------------------
GITHUB_USER="markabrahams"
REPO="${LLMSHOT_REPO:-https://github.com/${GITHUB_USER}/llmshot}"
BRANCH="${LLMSHOT_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO#https://github.com/}/${BRANCH}"

# Default install dir: ~/.local/bin for user, /usr/local/bin for root
if [[ -n "${INSTALL_DIR:-}" ]]; then
    DEST_DIR="$INSTALL_DIR"
else
    if [[ "$(id -u)" -eq 0 ]]; then
        DEST_DIR="/usr/local/bin"
    else
        DEST_DIR="${HOME}/.local/bin"
    fi
fi

# ---------------------------
# Parse -d /path
# ---------------------------
while getopts "d:h" opt; do
    case "$opt" in
        d) DEST_DIR="$OPTARG" ;;
        h)
            echo "Usage: $0 [-d INSTALL_DIR]"
            echo "  -d  Install directory (default: ~/.local/bin or /usr/local/bin if root)"
            echo "  -h  This help"
            echo ""
            echo "Env: INSTALL_DIR, LLMSHOT_REPO, LLMSHOT_BRANCH"
            exit 0
            ;;
        *) exit 1 ;;
    esac
done

# ---------------------------
# Download and install
# ---------------------------
mkdir -p "$DEST_DIR"
SCRIPT_URL="${RAW_BASE}/bin/llmshot"
DEST_BIN="${DEST_DIR}/llmshot"

echo "Installing llmshot to ${DEST_BIN}"
if command -v curl &>/dev/null; then
    curl -fsSL "$SCRIPT_URL" -o "$DEST_BIN"
else
    echo "error: curl is required" >&2
    exit 1
fi
chmod +x "$DEST_BIN"

echo "Installed: $DEST_BIN"
if [[ "$DEST_DIR" != *"/.local/bin"* ]] && [[ "$(id -u)" -ne 0 ]]; then
    # User install to custom dir – remind about PATH
    if ! command -v llmshot &>/dev/null; then
        echo "Add to PATH: export PATH=\"${DEST_DIR}:\$PATH\""
    fi
fi
