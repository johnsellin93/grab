#!/usr/bin/env zsh
set -euo pipefail

INSTALL_DIR="$HOME/grab"
REPO_URL="https://github.com/johnsellin93/grab.git"

echo "[grab] Installing..."

if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "[grab] Existing installation found. Updating..."
    git -C "$INSTALL_DIR" pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/grab"

PATH_EXPORT='export PATH="$HOME/grab:$PATH"'

if ! grep -Fxq "$PATH_EXPORT" "$HOME/.zshrc" 2>/dev/null; then
    echo "$PATH_EXPORT" >> "$HOME/.zshrc"
    echo "[grab] Added grab to PATH in ~/.zshrc"
fi

echo
echo "[grab] Installation complete."
echo "[grab] Restart your shell or run:"
echo
echo "    source ~/.zshrc"
echo
echo "[grab] Verify with:"
echo
echo "    grab --help"
