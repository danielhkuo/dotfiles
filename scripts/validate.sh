#!/usr/bin/env bash
# Pre-install validation: warns about packages/widget repos that no longer exist.
# Does not exit on failure — just reports so install.sh can decide what to skip.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

validate_cachyos() {
    echo "==> Validating packages..."
    while IFS= read -r pkg; do
        if ! paru -Si "$pkg" &>/dev/null 2>&1; then
            echo "    WARN: '$pkg' not found in repos (renamed or removed)"
            ERRORS=$((ERRORS + 1))
        fi
    done < "$DOTFILES_DIR/pkglist/pkgs-explicit.txt"
    while IFS= read -r pkg; do
        if ! paru -Si "$pkg" &>/dev/null 2>&1; then
            echo "    WARN: '$pkg' not found in AUR (renamed or removed)"
            ERRORS=$((ERRORS + 1))
        fi
    done < "$DOTFILES_DIR/pkglist/pkgs-aur.txt"

    echo "==> Validating widget repositories..."
    declare -A WIDGET_REPOS=(
        ["org.dhruv8sh.kara"]="https://github.com/dhruv8sh/kara"
        ["com.github.antroids.application-title-bar"]="https://github.com/antroids/application-title-bar"
        ["KdeControlStation"]="https://github.com/EliverLara/kde-control-station"
        ["AndromedaLauncher"]="https://github.com/EliverLara/AndromedaLauncher"
    )
    for widget in "${!WIDGET_REPOS[@]}"; do
        url="${WIDGET_REPOS[$widget]}"
        if ! curl -sf --max-time 10 --head "$url" > /dev/null; then
            echo "    WARN: '$widget' repo unreachable: $url"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

validate_macos() {
    echo "==> Validating Brewfile..."
    if ! command -v brew &>/dev/null; then
        echo "    WARN: Homebrew not installed — run bootstrap-macos.sh first."
        ERRORS=$((ERRORS + 1))
        return
    fi
    if ! brew bundle check --file="$DOTFILES_DIR/pkglist/Brewfile" &>/dev/null; then
        echo "    Note: Brewfile has unsatisfied entries — install.sh will install them."
    fi
}

case "$(uname -s)" in
    Linux)  validate_cachyos ;;
    Darwin) validate_macos ;;
    *)
        echo "Unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
esac

if [ "$ERRORS" -gt 0 ]; then
    echo
    echo "  $ERRORS issue(s) found. Review warnings above before running install.sh."
    exit 1
else
    echo "  All checks passed."
fi
