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

echo "==> Restoring KDE config..."
mkdir -p ~/.config
cp "$DOTFILES_DIR/kde/plasma-org.kde.plasma.desktop-appletsrc" ~/.config/
cp "$DOTFILES_DIR/kde/plasmarc" ~/.config/
cp "$DOTFILES_DIR/kde/kdeglobals" ~/.config/
cp "$DOTFILES_DIR/kde/kwinrc" ~/.config/
echo "    Done. Log out and back in to apply."

echo ""
echo "==> Package lists are in pkglist/"
echo "    To reinstall everything: paru -S --needed - < pkglist/pkgs-explicit.txt"
echo "    AUR packages:            paru -S --needed - < pkglist/pkgs-aur.txt"
echo ""
echo "NOTE: The plasma config references widgets from your old setup (kara, AndromedaLauncher, etc.)"
echo "      You'll need to reinstall those or rebuild your panels from scratch."
echo "      Widget positions for the Nothing widgets on your second monitor are saved as reference."
