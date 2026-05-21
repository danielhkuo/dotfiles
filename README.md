# dotfiles

Cross-platform setup for **CachyOS** and **macOS**, managed with [chezmoi](https://www.chezmoi.io/).
Same `install.sh`, OS-dispatched on `uname -s`.

---

## Fresh install

### macOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/danielhkuo/dotfiles/main/bootstrap-macos.sh)
```

Walks through:

1. **Xcode Command Line Tools** — if missing, kicks off the installer GUI; re-run the script when it finishes.
2. **Homebrew** — installs to `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel).
3. **GitHub auth** — `gh auth login --git-protocol https`, device flow. A QR code prints to the terminal — scan with your phone, paste the code into the browser, done.
4. **SSH key** — generates `~/.ssh/id_ed25519` and uploads to GitHub.
5. **Clones the repo** to `~/dotfiles`.
6. **Hands off to `install.sh`**, which:
   - Runs `brew bundle install --file=pkglist/Brewfile` — installs all CLI tools, casks, VSCode extensions, go packages, npm packages.
   - `chezmoi init --apply` — applies `dot_*` configs to `$HOME`.
   - `macos/defaults.sh` — applies system preferences (Finder, Dock, keyboard repeat, etc.).
   - Installs the **brew autoupdate LaunchAgent** (see below) and symlinks `brew-autoupdate-networks` into `~/.local/bin/`.
   - Prints the manual post-install checklist.

**Manual steps after `install.sh`:**

- **karabiner-elements**: open it once, grant *Input Monitoring* + *Accessibility* in System Settings → Privacy & Security. The packaged installer also needs interactive sudo, so install it from a terminal: `brew install --cask karabiner-elements`.
- **Tailscale**: launch, sign in.
- **Raycast**: launch, sign in (or skip for local-only).
- **Warp**: launch, sign in with GitHub to pull synced terminal settings.
- **Zen Browser**: sign in to Mozilla Sync to restore bookmarks/extensions/history.
- **Brave**: paste sync chain to restore profile.
- **Zed / VS Code / Cursor**: sign in with GitHub to pull editor Settings Sync.
- **brew autoupdate**: run `brew-autoupdate-networks` to add the current Wi-Fi to your trust list (one keystroke). See [autoupdate](#brew-autoupdate-macos) below.

---

### CachyOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/danielhkuo/dotfiles/main/bootstrap-cachyos.sh)
```

Same flow, Linux-flavored:

1. `pacman -Syu` system update.
2. Installs `github-cli`, runs device-flow auth with a QR code.
3. SSH key gen + upload.
4. Clones repo to `~/dotfiles`.
5. Installs `chezmoi` via `paru`.
6. `install.sh` runs the Linux branch:
   - `scripts/validate.sh` — checks every package in `pkglist/` still exists in repos.
   - `paru -S --needed --noconfirm - < pkgs-explicit.txt` then `< pkgs-aur.txt`.
   - Installs bundled KDE widgets via `kpackagetool6`.
   - Clones the four GitHub-hosted KDE widgets (kara, application-title-bar, kde-control-station, AndromedaLauncher).
   - `chezmoi init --apply`.
   - Copies `kde/*` configs into `~/.config/`.
   - Drops the wallpaper into `~/Pictures/`.
   - Enables docker + adds you to the docker group.
   - Restarts `plasmashell`.

---

## What's tracked vs. what isn't

**Tracked (synced across machines via this repo):**

- Shell-level configs: `dot_gitconfig`, `dot_config/gh`, `dot_config/micro`
- OS-conditional configs: `dot_config/topgrade.toml` (Linux), `dot_config/karabiner/karabiner.json` (macOS)
- Package lists: `pkglist/pkgs-explicit.txt` + `pkgs-aur.txt` (CachyOS), `pkglist/Brewfile` (macOS)
- Install machinery: `bootstrap-*.sh`, `install.sh`, `scripts/`, `macos/`
- KDE layout files (`kde/`) and bundled Plasma widgets (`widgets/`)

**Deliberately NOT tracked, by design:**

- **Browser data** (Zen, Brave) — handled by Mozilla Sync and Brave Sync chains. Profiles are huge, binary, and contain credentials; the wrong tool for dotfiles.
- **Editor settings** (Zed, VS Code, Cursor) — synced via each editor's GitHub-account Settings Sync.
- **Terminal settings** (Warp) — Warp's own cloud sync.
- **App Store / direct-download apps** — these don't fit Brewfile and are inherently per-machine.
- **`brew-autoupdate` SSID allowlist** (`~/.config/brew-autoupdate/safe-networks`) — kept local-only so home/office SSIDs don't end up in a public repo.

---

## Day-to-day

### Both platforms

```bash
chezmoi diff        # see pending config drift
chezmoi apply       # apply changes
chezmoi re-add      # capture local edits back into the repo
```

### CachyOS

`topgrade` is the entrypoint. Its config (`dot_config/topgrade.toml`) ends with a custom command that invokes `scripts/sync.sh` — after upgrading the system, that script dumps the live package lists with `pacman -Qqen` / `-Qqem`, captures KDE panel layout, re-adds chezmoi-managed files, and pushes if anything changed.

### macOS — brew autoupdate

A LaunchAgent (`com.danielkuo.brew-autoupdate`) fires daily at 14:00. The wrapper:

1. Bails if not on AC power.
2. Reads `~/.config/brew-autoupdate/safe-networks` (your allowlist). Bails if the current SSID isn't listed.
3. Runs `brew update && brew upgrade && brew upgrade --cask --greedy && brew cleanup -s`.
4. Calls `scripts/sync.sh`, which `brew bundle dump`s the Brewfile, re-adds chezmoi files, and pushes if there's drift.

Log: `~/Library/Logs/brew-autoupdate.log`.

Manually trigger (identical to the scheduled run): `launchctl kickstart -k gui/$UID/com.danielkuo.brew-autoupdate`.

**Managing the SSID allowlist:**

```bash
brew-autoupdate-networks            # interactive: shows current SSID, prompts to add
brew-autoupdate-networks -l         # list trusted networks
brew-autoupdate-networks -r         # remove (fzf picker)
brew-autoupdate-networks -s "name"  # add a specific SSID
```

**Cask sudo caveat:** casks that install kernel components (Karabiner, Google Drive, MacTeX, MS Edge, etc.) need an interactive password and will fail silently in the unattended run. Install those manually from a terminal once.

---

## Layout

```
.
├── bootstrap-cachyos.sh   # one-shot bootstrap, CachyOS
├── bootstrap-macos.sh     # one-shot bootstrap, macOS
├── install.sh             # OS-dispatched installer (run after bootstrap)
├── dot_gitconfig          # ~/.gitconfig
├── dot_config/
│   ├── gh/                # GitHub CLI
│   ├── micro/             # micro editor
│   ├── topgrade.toml      # Linux-only (chezmoi-ignored on darwin)
│   └── karabiner/         # macOS-only (chezmoi-ignored on linux)
├── pkglist/
│   ├── pkgs-explicit.txt  # CachyOS: official-repo packages
│   ├── pkgs-aur.txt       # CachyOS: AUR packages
│   └── Brewfile           # macOS: brew + cask + vscode + go + npm
├── macos/                 # macOS-only install assets
│   ├── defaults.sh
│   ├── brew-autoupdate.sh
│   ├── brew-autoupdate-networks.sh
│   └── com.danielkuo.brew-autoupdate.plist.tmpl
├── kde/                   # CachyOS-only KDE config files
├── widgets/               # Bundled Plasma widgets
└── scripts/
    ├── sync.sh            # OS-dispatched: dumps live state + commits + pushes
    └── validate.sh        # OS-dispatched: sanity-check before install
```
