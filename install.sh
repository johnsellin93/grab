#!/usr/bin/env zsh
set -euo pipefail

INSTALL_DIR="$HOME/grab"
REPO_URL="https://github.com/johnsellin93/grab.git"
PATH_EXPORT='export PATH="$HOME/grab:$PATH"'

info() { echo "[grab] $*"; }
ok() { echo "✓ $*"; }
warn() { echo "⚠ $*"; }

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

install_packages() {
    local packages=("$@")

    if (( ${#packages[@]} == 0 )); then
        return
    fi

    if has_cmd apt; then
        sudo apt update
        sudo apt install -y "${packages[@]}"
    elif has_cmd dnf; then
        sudo dnf install -y "${packages[@]}"
    elif has_cmd yum; then
        sudo yum install -y "${packages[@]}"
    elif has_cmd pacman; then
        sudo pacman -Sy --needed "${packages[@]}"
    elif has_cmd zypper; then
        sudo zypper install -y "${packages[@]}"
    elif has_cmd brew; then
        brew install "${packages[@]}"
    else
        warn "No supported package manager found. Please install manually: ${packages[*]}"
        return 1
    fi
}

ensure_required_dependency() {
    local cmd="$1"
    local package="$2"

    if has_cmd "$cmd"; then
        ok "$cmd installed"
        return
    fi

    info "$cmd not found. Installing $package..."
    install_packages "$package"

    if has_cmd "$cmd"; then
        ok "$cmd installed"
    else
        echo "[grab] ERROR: failed to install required dependency: $cmd" >&2
        exit 1
    fi
}

ensure_optional_dependency() {
    local cmd="$1"
    local package="$2"

    if has_cmd "$cmd"; then
        ok "$cmd installed"
        return
    fi

    info "$cmd not found. Attempting optional install..."
    if install_packages "$package"; then
        if has_cmd "$cmd"; then
            ok "$cmd installed"
        else
            warn "$cmd still not found"
        fi
    else
        warn "$cmd not installed; grab will fall back where possible"
    fi
}

info "Checking dependencies..."

ensure_required_dependency rg ripgrep
ensure_optional_dependency tree tree

if has_cmd tmux; then ok "tmux detected"; else warn "tmux not found"; fi
if has_cmd wl-copy; then ok "wl-copy detected"; else warn "wl-copy not found"; fi
if has_cmd xclip; then ok "xclip detected"; else warn "xclip not found"; fi
if has_cmd pbcopy; then ok "pbcopy detected"; else warn "pbcopy not found"; fi

info "Installing grab..."

if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Existing installation found. Updating..."
    git -C "$INSTALL_DIR" pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/grab"

if ! grep -Fxq "$PATH_EXPORT" "$HOME/.zshrc" 2>/dev/null; then
    echo "$PATH_EXPORT" >> "$HOME/.zshrc"
    ok "Added grab to PATH in ~/.zshrc"
else
    ok "PATH already configured"
fi

echo
info "Installation complete."
info "Restart your shell or run:"
echo
echo "    source ~/.zshrc"
echo
info "Verify with:"
echo
echo "    grab --help"
