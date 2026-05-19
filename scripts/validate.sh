#!/usr/bin/env bash
# Pre-install validation: warns about packages/widget repos that no longer exist.
# Does not exit on failure — just reports so install.sh can decide what to skip.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

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

if [ "$ERRORS" -gt 0 ]; then
    echo
    echo "  $ERRORS issue(s) found. Review warnings above before running install.sh."
    echo "  Remove deprecated entries from pkglist/ or update widget URLs in install.sh."
    exit 1
else
    echo "  All packages and widget repos look good."
fi
