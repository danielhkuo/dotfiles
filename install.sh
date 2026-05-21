#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { echo; echo "==> $*"; }

install_cachyos() {
    local PLASMOIDS=~/.local/share/plasma/plasmoids

    # ── 0. Validate ───────────────────────────────────────────────────────────
    step "Validating packages and widget repos..."
    if ! bash "$DOTFILES_DIR/scripts/validate.sh"; then
        echo
        read -rp "Issues found above. Continue anyway? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    fi

    # ── 1. Packages ───────────────────────────────────────────────────────────
    step "Installing system packages..."
    paru -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist/pkgs-explicit.txt"

    step "Installing AUR packages..."
    paru -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist/pkgs-aur.txt"

    # ── 2. Widgets ────────────────────────────────────────────────────────────
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

    # ── 3. chezmoi (dotfiles) ─────────────────────────────────────────────────
    step "Applying dotfiles via chezmoi..."
    chezmoi init --apply "https://github.com/danielhkuo/dotfiles.git"

    # ── 4. KDE config ─────────────────────────────────────────────────────────
    step "Restoring KDE layout and config..."
    mkdir -p ~/.config
    cp "$DOTFILES_DIR/kde/plasma-org.kde.plasma.desktop-appletsrc" ~/.config/
    cp "$DOTFILES_DIR/kde/plasmarc" ~/.config/
    cp "$DOTFILES_DIR/kde/kdeglobals" ~/.config/
    cp "$DOTFILES_DIR/kde/kwinrc" ~/.config/

    # ── 5. Assets ─────────────────────────────────────────────────────────────
    step "Copying assets..."
    mkdir -p ~/Pictures
    cp "$DOTFILES_DIR/assets/fishing.png" ~/Pictures/

    # ── 6. Services ───────────────────────────────────────────────────────────
    step "Enabling Docker..."
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"

    # ── 7. Restart plasmashell ────────────────────────────────────────────────
    step "Restarting plasmashell to apply layout..."
    systemctl restart --user plasma-plasmashell
    echo "    Done. Your panel and widget layout should be restored."
    echo "    If any widgets are missing, log out and back in."
}

install_macos() {
    # ── 0. Validate ───────────────────────────────────────────────────────────
    step "Validating Brewfile..."
    if ! bash "$DOTFILES_DIR/scripts/validate.sh"; then
        echo
        read -rp "Issues found above. Continue anyway? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    fi

    # ── 1. Packages ───────────────────────────────────────────────────────────
    step "Installing packages from Brewfile (this can take a while — large casks like Flutter are >2 GB)..."
    brew bundle install --file="$DOTFILES_DIR/pkglist/Brewfile" --verbose

    # ── 2. chezmoi (dotfiles) ─────────────────────────────────────────────────
    step "Applying dotfiles via chezmoi..."
    chezmoi init --apply "https://github.com/danielhkuo/dotfiles.git"

    # ── 3. macOS system defaults ──────────────────────────────────────────────
    step "Applying macOS system defaults..."
    bash "$DOTFILES_DIR/macos/defaults.sh"

    # ── 4. brew autoupdate LaunchAgent ────────────────────────────────────────
    step "Installing brew autoupdate LaunchAgent..."
    local agent_label="com.danielkuo.brew-autoupdate"
    local agent_dst="$HOME/Library/LaunchAgents/$agent_label.plist"
    mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs" "$HOME/.config/brew-autoupdate"
    sed -e "s|__HOME__|$HOME|g" \
        -e "s|__SCRIPT__|$DOTFILES_DIR/macos/brew-autoupdate.sh|g" \
        "$DOTFILES_DIR/macos/$agent_label.plist.tmpl" > "$agent_dst"
    launchctl bootout "gui/$UID/$agent_label" 2>/dev/null || true
    launchctl bootstrap "gui/$UID" "$agent_dst"
    if [ ! -f "$HOME/.config/brew-autoupdate/safe-networks" ]; then
        cat > "$HOME/.config/brew-autoupdate/safe-networks" <<'EOF'
# Put one Wi-Fi SSID per line. brew autoupdate only runs when the current
# SSID matches one of these AND the Mac is on AC power.
# Use `brew-autoupdate-networks` to add the current SSID interactively.
EOF
        echo "    Created $HOME/.config/brew-autoupdate/safe-networks."
    fi
    mkdir -p "$HOME/.local/bin"
    ln -sf "$DOTFILES_DIR/macos/brew-autoupdate-networks.sh" \
        "$HOME/.local/bin/brew-autoupdate-networks"

    # ── 5. Post-install reminders ─────────────────────────────────────────────
    step "Post-install — manual steps remaining:"
    cat <<'EOF'
    Karabiner-Elements: open it once and grant Input Monitoring + Accessibility
                        permissions (System Settings → Privacy & Security).
    Tailscale:          launch and sign in.
    Raycast:            launch and sign in (or skip for local-only use).
    Warp:               launch and sign in with GitHub to pull your synced settings.
    Zen Browser:        sign in to Mozilla Sync to restore profile.
    Brave:              sign in / paste sync chain to restore profile.
    Zed / VSCode / Cursor: sign in with GitHub to pull Settings Sync.
    brew autoupdate:    run `brew-autoupdate-networks` to add the current Wi-Fi
                        to the trusted list. Log at ~/Library/Logs/brew-autoupdate.log.
EOF
}

case "$(uname -s)" in
    Linux)  install_cachyos ;;
    Darwin) install_macos ;;
    *)
        echo "Unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
esac
