#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOIDS=~/.local/share/plasma/plasmoids

step() { echo; echo "==> $*"; }

# ── 0. Validate ───────────────────────────────────────────────────────────────
step "Validating packages and widget repos..."
if ! bash "$DOTFILES_DIR/scripts/validate.sh"; then
    echo
    read -rp "Issues found above. Continue anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi

# ── 1. Packages ───────────────────────────────────────────────────────────────
step "Installing system packages..."
paru -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist/pkgs-explicit.txt"

step "Installing AUR packages..."
paru -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist/pkgs-aur.txt"

# ── 2. Widgets ────────────────────────────────────────────────────────────────
step "Installing bundled widgets (Nothing KDE, catwalk)..."
mkdir -p "$PLASMOIDS"
for widget_dir in "$DOTFILES_DIR"/widgets/*/; do
    widget_id="$(basename "$widget_dir")"
    if [ -d "$PLASMOIDS/$widget_id" ]; then
        echo "    Skipping $widget_id (already installed)"
    else
        kpackagetool6 --type Plasma/Applet --install "$widget_dir"
        echo "    Installed $widget_id"
    fi
done

step "Cloning and installing GitHub widgets..."
clone_widget() {
    local url="$1" dest="$2" branch="${3:-}"
    if [ -d "$dest" ]; then
        echo "    Skipping $(basename "$dest") (already installed)"
        return
    fi
    if [ -n "$branch" ]; then
        git clone --depth=1 --branch "$branch" "$url" "$dest"
    else
        git clone --depth=1 "$url" "$dest"
    fi
    echo "    Cloned $(basename "$dest")"
}

clone_widget "https://github.com/dhruv8sh/kara"                    "$PLASMOIDS/org.dhruv8sh.kara"
clone_widget "https://github.com/antroids/application-title-bar"   "$PLASMOIDS/com.github.antroids.application-title-bar"
clone_widget "https://github.com/EliverLara/kde-control-station"   "$PLASMOIDS/KdeControlStation" "plasma6"
clone_widget "https://github.com/EliverLara/AndromedaLauncher"     "$PLASMOIDS/AndromedaLauncher"

# ── 3. chezmoi (dotfiles) ─────────────────────────────────────────────────────
step "Applying dotfiles via chezmoi..."
chezmoi init --apply "https://github.com/danielhkuo/dotfiles.git"

# ── 4. KDE config ─────────────────────────────────────────────────────────────
step "Restoring KDE layout and config..."
mkdir -p ~/.config
cp "$DOTFILES_DIR/kde/plasma-org.kde.plasma.desktop-appletsrc" ~/.config/
cp "$DOTFILES_DIR/kde/plasmarc" ~/.config/
cp "$DOTFILES_DIR/kde/kdeglobals" ~/.config/
cp "$DOTFILES_DIR/kde/kwinrc" ~/.config/

# ── 5. Assets ─────────────────────────────────────────────────────────────────
step "Copying assets..."
mkdir -p ~/Pictures
cp "$DOTFILES_DIR/assets/fishing.png" ~/Pictures/

# ── 6. Services ───────────────────────────────────────────────────────────────
step "Enabling Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

# ── 7. Restart plasmashell ────────────────────────────────────────────────────
step "Restarting plasmashell to apply layout..."
systemctl restart --user plasma-plasmashell
echo "    Done. Your panel and widget layout should be restored."
echo "    If any widgets are missing, log out and back in."
