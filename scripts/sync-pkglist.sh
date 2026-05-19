#!/usr/bin/env bash
# Regenerates pkglist from current install and commits if anything changed.
# Run automatically by topgrade after each upgrade.
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pacman -Qqen > "$DOTFILES_DIR/pkglist/pkgs-explicit.txt"
pacman -Qqem > "$DOTFILES_DIR/pkglist/pkgs-aur.txt"

if git -C "$DOTFILES_DIR" diff --quiet pkglist/; then
    exit 0
fi

git -C "$DOTFILES_DIR" add pkglist/
git -C "$DOTFILES_DIR" commit -m "Auto-sync package list ($(date +%Y-%m-%d))"
git -C "$DOTFILES_DIR" push
