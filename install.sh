#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing Nothing KDE widgets..."
mkdir -p ~/.local/share/plasma/plasmoids/
cp -r "$DOTFILES_DIR"/widgets/com.jaxparrow07.nothingkdewidgets.* ~/.local/share/plasma/plasmoids/
echo "    Done. Restart plasmashell to load them."

echo "==> Copying assets..."
mkdir -p ~/Pictures
cp "$DOTFILES_DIR/assets/fishing.png" ~/Pictures/
echo "    Done."

echo ""
echo "==> Package lists are in pkglist/"
echo "    To reinstall everything: paru -S --needed - < pkglist/pkgs-explicit.txt"
echo "    AUR packages:            paru -S --needed - < pkglist/pkgs-aur.txt"
echo ""
echo "Done! After adding your panels in KDE, configure the photo widget to point to ~/Pictures/fishing.png"
