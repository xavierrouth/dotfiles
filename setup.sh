#!/usr/bin/env bash
# setup.sh — Install fish, tmux, broot and apply dotfiles from
# https://github.com/xavierrouth/dotfiles.git
# Targets: Ubuntu (Debian-based) containers / systems

set -euo pipefail

DOTFILES_REPO="https://github.com/xavierrouth/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
section() { echo -e "\n${GREEN}══ $* ══${NC}"; }

# ─── Prerequisites ────────────────────────────────────────────────────────────
section "Updating apt and installing prerequisites"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
    curl \
    git \
    wget \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    xclip \
    xsel

# ─── Fish shell ───────────────────────────────────────────────────────────────
section "Installing fish shell"
if ! command -v fish &>/dev/null; then
    add-apt-repository -y ppa:fish-shell/release-3
    apt-get update -qq
    apt-get install -y -qq fish
    info "fish installed: $(fish --version)"
else
    info "fish already installed: $(fish --version)"
fi

# ─── Tmux ─────────────────────────────────────────────────────────────────────
section "Installing tmux"
apt-get install -y -qq tmux
info "tmux installed: $(tmux -V)"

# ─── Broot ────────────────────────────────────────────────────────────────────
section "Installing broot"
if ! command -v broot &>/dev/null; then
    BROOT_VERSION=$(curl -s https://api.github.com/repos/Canop/broot/releases/latest \
        | grep '"tag_name"' | head -1 | cut -d'"' -f4)
    BROOT_URL="https://github.com/Canop/broot/releases/download/${BROOT_VERSION}/broot_${BROOT_VERSION#v}.zip"
    BROOT_TMP=$(mktemp -d)
    curl -fsSL "$BROOT_URL" -o "$BROOT_TMP/broot.zip"
    unzip -q "$BROOT_TMP/broot.zip" -d "$BROOT_TMP"
    # The zip contains binaries per architecture; pick the right one
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  BROOT_BIN="$BROOT_TMP/build/x86_64-unknown-linux-musl/broot" ;;
        aarch64) BROOT_BIN="$BROOT_TMP/build/aarch64-unknown-linux-musl/broot" ;;
        *)        warn "Unknown arch $ARCH; skipping broot"; BROOT_BIN="" ;;
    esac
    if [[ -n "$BROOT_BIN" && -f "$BROOT_BIN" ]]; then
        install -m 755 "$BROOT_BIN" /usr/local/bin/broot
        info "broot installed: $(broot --version)"
    fi
    rm -rf "$BROOT_TMP"
else
    info "broot already installed: $(broot --version)"
fi

# ─── Clone dotfiles ───────────────────────────────────────────────────────────
section "Cloning dotfiles"
if [[ -d "$DOTFILES_DIR" ]]; then
    info "Dotfiles already cloned — pulling latest"
    git -C "$DOTFILES_DIR" pull --ff-only
else
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    info "Cloned to $DOTFILES_DIR"
fi

# ─── Helper: safe symlink (backs up existing file) ───────────────────────────
link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "Backing up existing $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    info "Linked $dst → $src"
}

# ─── Apply dotfiles ───────────────────────────────────────────────────────────
section "Linking config files"

# tmux
link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# git
link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# fish
link "$DOTFILES_DIR/.config/fish/config.fish"        "$HOME/.config/fish/config.fish"
link "$DOTFILES_DIR/.config/fish/functions"           "$HOME/.config/fish/functions"

# broot
if [[ -d "$DOTFILES_DIR/.config/broot" ]]; then
    link "$DOTFILES_DIR/.config/broot" "$HOME/.config/broot"
fi

# ─── TPM (Tmux Plugin Manager) ───────────────────────────────────────────────
section "Installing TPM (Tmux Plugin Manager)"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    info "TPM installed"
else
    info "TPM already present — updating"
    git -C "$TPM_DIR" pull --ff-only
fi

# Install tmux plugins headlessly
if command -v tmux &>/dev/null; then
    info "Installing tmux plugins via TPM..."
    tmux new-session -d -s __install 2>/dev/null || true
    "$TPM_DIR/bin/install_plugins" || warn "TPM plugin install had errors (check manually)"
    tmux kill-session -t __install 2>/dev/null || true
fi

# ─── Broot shell integration ─────────────────────────────────────────────────
section "Configuring broot shell integration"
if command -v broot &>/dev/null; then
    # broot --install writes the br function; run it non-interactively
    broot --install --no-style 2>/dev/null || warn "broot --install skipped (may need a TTY; run manually)"
fi

# ─── Set fish as default shell ────────────────────────────────────────────────
section "Setting fish as default shell"
FISH_PATH=$(command -v fish)
if ! grep -qxF "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" >> /etc/shells
fi
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" != "$FISH_PATH" ]]; then
    chsh -s "$FISH_PATH" "$USER"
    info "Default shell set to fish ($FISH_PATH)"
else
    info "fish is already the default shell"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
section "Setup complete"
echo ""
echo "  Start a new shell or run:  exec fish"
echo "  Inside tmux, press:        prefix + I   to install plugins"
echo ""
