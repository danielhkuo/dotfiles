#!/usr/bin/env bash
# Run this on a fresh CachyOS install.
# Everything is automated except the GitHub auth step.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/danielhkuo/dotfiles/main/bootstrap.sh)
set -e

DOTFILES_DIR="$HOME/dotfiles"

step() { echo; echo "==> $*"; }

# ── 1. System update ──────────────────────────────────────────────────────────
step "Updating system..."
sudo pacman -Syu --noconfirm

# ── 2. GitHub CLI ─────────────────────────────────────────────────────────────
step "Ensuring GitHub CLI is installed..."
if ! command -v gh &>/dev/null; then
    sudo pacman -S --noconfirm github-cli
fi

# ── 3. GitHub auth (device flow — scan QR with phone) ────────────────────────
step "Checking GitHub authentication..."
if ! gh auth status &>/dev/null; then
    echo "  Scan this QR code with your phone, then enter the code shown below:"
    echo
    if command -v qrencode &>/dev/null; then
        qrencode -t UTF8 "https://github.com/login/device"
    else
        echo "  https://github.com/login/device"
    fi
    echo
    gh auth login --git-protocol https
fi

# ── 4. SSH key ────────────────────────────────────────────────────────────────
step "Setting up SSH key..."
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -C "$(gh api user --jq '.login')@$(hostname)" -f "$SSH_KEY" -N ""
    gh ssh-key add "${SSH_KEY}.pub" --title "$(hostname)-$(date +%Y-%m)"
    echo "  SSH key generated and added to GitHub."
else
    echo "  SSH key already exists, skipping."
fi

# ── 5. Clone dotfiles ─────────────────────────────────────────────────────────
step "Cloning dotfiles..."
if [ -d "$DOTFILES_DIR" ]; then
    echo "  ~/dotfiles already exists, pulling latest..."
    git -C "$DOTFILES_DIR" pull
else
    gh repo clone danielhkuo/dotfiles "$DOTFILES_DIR"
fi

# ── 6. chezmoi ───────────────────────────────────────────────────────────────
step "Installing chezmoi..."
if ! command -v chezmoi &>/dev/null; then
    paru -S --noconfirm chezmoi
fi

# ── 7. Hand off to install.sh ─────────────────────────────────────────────────
step "Bootstrap complete — running install.sh..."
bash "$DOTFILES_DIR/install.sh"
