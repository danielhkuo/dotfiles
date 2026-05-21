#!/usr/bin/env bash
# Syncs everything back to the dotfiles repo after a topgrade run.
# Called automatically by topgrade as a custom command.
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
    Linux)
        # Package lists from live install
        pacman -Qqen > "$DOTFILES_DIR/pkglist/pkgs-explicit.txt"
        pacman -Qqem > "$DOTFILES_DIR/pkglist/pkgs-aur.txt"

        # KDE plasma layout (panels + desktop widget positions)
        cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc "$DOTFILES_DIR/kde/"
        ;;
    Darwin)
        # Brewfile from live install
        brew bundle dump --force --file="$DOTFILES_DIR/pkglist/Brewfile"
        ;;
    *)
        echo "Unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
esac

# chezmoi-managed dotfiles (gitconfig, gh config, micro, topgrade, karabiner, etc.)
chezmoi re-add

# Commit and push only if something actually changed
if git -C "$DOTFILES_DIR" diff --quiet && git -C "$DOTFILES_DIR" diff --cached --quiet; then
    echo "Dotfiles already up to date."
    exit 0
fi

git -C "$DOTFILES_DIR" add -A
git -C "$DOTFILES_DIR" commit -m "Auto-sync dotfiles ($(date +%Y-%m-%d))"
git -C "$DOTFILES_DIR" push
