#!/usr/bin/env bash
# Run this on a fresh macOS install.
# Everything is automated except the GitHub auth step.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/danielhkuo/dotfiles/main/bootstrap-macos.sh)
set -e

DOTFILES_DIR="$HOME/dotfiles"

step() { echo; echo "==> $*"; }

# ── 1. Xcode Command Line Tools ───────────────────────────────────────────────
step "Ensuring Xcode Command Line Tools are installed..."
if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    echo "  Accept the Xcode CLT installer prompt, then re-run this script."
    exit 0
fi

# ── 2. Homebrew ──────────────────────────────────────────────────────────────
step "Ensuring Homebrew is installed..."
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon: brew installs to /opt/homebrew; add to PATH for this session.
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# ── 3. GitHub CLI ─────────────────────────────────────────────────────────────
step "Ensuring GitHub CLI is installed..."
if ! command -v gh &>/dev/null; then
    brew install gh qrencode
fi

# ── 4. GitHub auth (device flow — scan QR with phone) ────────────────────────
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

# ── 5. SSH key ────────────────────────────────────────────────────────────────
step "Setting up SSH key..."
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -C "$(gh api user --jq '.login')@$(hostname)" -f "$SSH_KEY" -N ""
    gh ssh-key add "${SSH_KEY}.pub" --title "$(hostname)-$(date +%Y-%m)"
    echo "  SSH key generated and added to GitHub."
else
    echo "  SSH key already exists, skipping."
fi

# ── 6. Clone dotfiles ─────────────────────────────────────────────────────────
step "Cloning dotfiles..."
if [ -d "$DOTFILES_DIR" ]; then
    echo "  ~/dotfiles already exists, pulling latest..."
    git -C "$DOTFILES_DIR" pull
else
    gh repo clone danielhkuo/dotfiles "$DOTFILES_DIR"
fi

# ── 7. chezmoi ───────────────────────────────────────────────────────────────
step "Installing chezmoi..."
if ! command -v chezmoi &>/dev/null; then
    brew install chezmoi
fi

# ── 8. Hand off to install.sh ─────────────────────────────────────────────────
step "Bootstrap complete — running install.sh..."
bash "$DOTFILES_DIR/install.sh"
