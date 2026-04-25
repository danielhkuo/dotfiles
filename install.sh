#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing Nothing KDE widgets and catwalk (from repo)..."
mkdir -p ~/.local/share/plasma/plasmoids/
cp -r "$DOTFILES_DIR"/widgets/* ~/.local/share/plasma/plasmoids/
echo "    Done."

echo "==> Cloning panel widgets from GitHub..."
PLASMOIDS=~/.local/share/plasma/plasmoids
git clone --depth=1 https://github.com/dhruv8sh/kara "$PLASMOIDS/org.dhruv8sh.kara"
git clone --depth=1 https://github.com/antroids/application-title-bar "$PLASMOIDS/com.github.antroids.application-title-bar"
git clone --depth=1 --branch plasma6 https://github.com/EliverLara/kde-control-station "$PLASMOIDS/KdeControlStation"
git clone --depth=1 https://github.com/EliverLara/AndromedaLauncher "$PLASMOIDS/AndromedaLauncher"
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
