#!/usr/bin/env bash
# Runs `brew update && upgrade && cleanup`, but only when:
#   1. on AC power
#   2. connected to a Wi-Fi SSID in the safe-networks allowlist
# Triggered by the matching LaunchAgent (see com.danielkuo.brew-autoupdate.plist).
set -u
LC_ALL=C

ALLOWLIST="$HOME/.config/brew-autoupdate/safe-networks"
LOCK="/tmp/brew-autoupdate.lock"

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

# Pick up Homebrew's PATH (LaunchAgents don't inherit the user shell env)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
else
    log "brew not found; aborting"
    exit 0
fi

on_ac_power() {
    pmset -g batt 2>/dev/null | grep -q "AC Power"
}

wifi_interface() {
    networksetup -listallhardwareports 2>/dev/null \
        | awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}'
}

current_ssid() {
    local iface="$1"
    [ -n "$iface" ] || return 1
    # Try ipconfig first (no Location Services permission required on Sonoma+)
    local ssid
    ssid="$(ipconfig getsummary "$iface" 2>/dev/null \
        | awk -F ' SSID : ' '/ SSID : / {print $2; exit}')"
    if [ -z "$ssid" ]; then
        ssid="$(networksetup -getairportnetwork "$iface" 2>/dev/null \
            | sed -n 's/^Current Wi-Fi Network: //p')"
    fi
    [ -n "$ssid" ] && printf '%s' "$ssid"
}

on_safe_network() {
    [ -f "$ALLOWLIST" ] || { log "no allowlist at $ALLOWLIST; skipping"; return 1; }
    local iface ssid
    iface="$(wifi_interface)"
    ssid="$(current_ssid "$iface")" || return 1
    [ -n "$ssid" ] || { log "not on Wi-Fi"; return 1; }
    if grep -Fxq "$ssid" "$ALLOWLIST"; then
        log "on safe network ($ssid)"
        return 0
    fi
    log "current SSID ($ssid) not in allowlist"
    return 1
}

# Bail unless conditions are right
on_ac_power || { log "not on AC power; skipping"; exit 0; }
on_safe_network || exit 0

# Single-instance lock (mkdir is atomic on POSIX)
if ! mkdir "$LOCK" 2>/dev/null; then
    log "another run already in progress ($LOCK); skipping"
    exit 0
fi
trap 'rmdir "$LOCK"' EXIT

log "starting brew update/upgrade/cleanup"
brew update
brew upgrade
brew upgrade --cask --greedy
brew cleanup -s
log "done"
