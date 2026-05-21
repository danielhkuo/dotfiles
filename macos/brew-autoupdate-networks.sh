#!/usr/bin/env bash
# Manage the brew-autoupdate Wi-Fi SSID allowlist.
# Usage:
#   brew-autoupdate-networks            # interactive: show status + add current SSID
#   brew-autoupdate-networks -l         # list allowed networks
#   brew-autoupdate-networks -r         # remove a network (fzf if available)
#   brew-autoupdate-networks -s "name"  # add a specific SSID
set -uo pipefail
LC_ALL=C

ALLOWLIST="$HOME/.config/brew-autoupdate/safe-networks"

ensure_allowlist() {
    mkdir -p "$(dirname "$ALLOWLIST")"
    [ -f "$ALLOWLIST" ] || touch "$ALLOWLIST"
}

allowed_ssids() {
    # Strip comments and blank lines.
    grep -v '^[[:space:]]*#' "$ALLOWLIST" 2>/dev/null \
        | grep -v '^[[:space:]]*$' || true
}

wifi_interface() {
    networksetup -listallhardwareports 2>/dev/null \
        | awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}'
}

current_ssid() {
    local iface ssid
    iface="$(wifi_interface)"
    [ -n "$iface" ] || return 1
    ssid="$(ipconfig getsummary "$iface" 2>/dev/null \
        | awk -F ' SSID : ' '/ SSID : / {print $2; exit}')"
    if [ -z "$ssid" ]; then
        ssid="$(networksetup -getairportnetwork "$iface" 2>/dev/null \
            | sed -n 's/^Current Wi-Fi Network: //p')"
    fi
    [ -n "$ssid" ] && printf '%s' "$ssid"
}

cmd_list() {
    local list
    list="$(allowed_ssids)"
    echo "Allowed networks:"
    if [ -z "$list" ]; then
        echo "  (none)"
    else
        echo "$list" | sed 's/^/  - /'
    fi
}

cmd_add() {
    local ssid="${1:-}"
    if [ -z "$ssid" ]; then
        echo "Empty SSID; aborting." >&2
        return 1
    fi
    if grep -Fxq "$ssid" "$ALLOWLIST" 2>/dev/null; then
        echo "'$ssid' is already in the allowlist."
        return 0
    fi
    printf '%s\n' "$ssid" >> "$ALLOWLIST"
    echo "Added '$ssid'."
}

cmd_remove() {
    local list pick
    list="$(allowed_ssids)"
    if [ -z "$list" ]; then
        echo "Allowlist is empty; nothing to remove."
        return 0
    fi
    if command -v fzf &>/dev/null; then
        pick="$(echo "$list" | fzf --prompt='Remove SSID> ' --height=10 --reverse)" || return 0
    else
        echo "Pick a number to remove:"
        local i=1
        while IFS= read -r ssid; do
            echo "  [$i] $ssid"
            i=$((i+1))
        done <<< "$list"
        read -rp "> " idx
        pick="$(echo "$list" | sed -n "${idx}p")"
    fi
    [ -n "$pick" ] || return 0
    local tmp
    tmp="$(mktemp)"
    awk -v target="$pick" '$0 != target' "$ALLOWLIST" > "$tmp"
    mv "$tmp" "$ALLOWLIST"
    echo "Removed '$pick'."
}

cmd_interactive() {
    local cur
    cur="$(current_ssid)" || true
    echo "Current SSID: ${cur:-<not on Wi-Fi>}"
    cmd_list
    echo
    if [ -z "$cur" ]; then
        echo "Not on Wi-Fi; nothing to add."
        return 0
    fi
    if grep -Fxq "$cur" "$ALLOWLIST" 2>/dev/null; then
        echo "'$cur' is already trusted."
        return 0
    fi
    read -rp "Add '$cur' to allowlist? [Y/n] " ans
    case "$ans" in
        ""|y|Y|yes|YES) cmd_add "$cur" ;;
        *) echo "Aborted." ;;
    esac
}

ensure_allowlist

case "${1:-}" in
    -l|--list)    cmd_list ;;
    -r|--remove)  cmd_remove ;;
    -s|--ssid)    shift; cmd_add "${1:-}" ;;
    -h|--help)
        cat <<'EOF'
brew-autoupdate-networks — manage the brew-autoupdate Wi-Fi SSID allowlist
Usage:
  brew-autoupdate-networks            interactive: show status + add current SSID
  brew-autoupdate-networks -l         list allowed networks
  brew-autoupdate-networks -r         remove a network (uses fzf if available)
  brew-autoupdate-networks -s "name"  add a specific SSID
EOF
        ;;
    "")           cmd_interactive ;;
    *)            echo "Unknown option: $1" >&2; exit 1 ;;
esac
