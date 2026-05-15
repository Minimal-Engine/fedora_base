#!/usr/bin/env bash
set -euo pipefail

FEDORA_VER="$(rpm -E %fedora)"

# --- dnf tuning ---
sudo tee -a /etc/dnf/dnf.conf >/dev/null <<'EOF'
fastestmirror=True
max_parallel_downloads=10
EOF

# --- RPM Fusion (free + nonfree) ---
sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

# --- VSCode repo + install ---
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf check-update || true     # returns 100 when updates exist; don't tank the script
sudo dnf install -y code

# --- Vivaldi repo + install (dnf5 syntax) ---
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/archive/vivaldi-fedora.repo
sudo dnf install -y vivaldi-stable

# --- Essential CLI / GUI tools ---
sudo dnf install -y \
  git rclone tldr mpv neovim cmus tmux alacritty vim zsh stow yt-dlp \
  vlc unison gnome-tweaks pass btop gh fastfetch mc

# --- Steam ---
sudo dnf install -y steam

# --- Git config ---
git config --global user.name  "${USER}-${HOSTNAME}"
git config --global user.email "d.rzeszutek@icloud.com"
git config --global core.editor "nvim"

# --- Yubikey toolchain ---
sudo dnf install -y --skip-unavailable \
  wget gnupg2 cryptsetup gnupg2-scdaemon pcsc-lite \
  yubikey-personalization-gui yubikey-manager

# --- Multimedia / codecs / HW accel ---
sudo dnf swap -y --allowerasing ffmpeg-free ffmpeg
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf swap -y mesa-va-drivers    mesa-va-drivers-freeworld
sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

sudo dnf install -y rpmfusion-free-release-tainted libdvdcss
sudo dnf install -y rpmfusion-nonfree-release-tainted
sudo dnf install -y --repo=rpmfusion-nonfree-tainted "*-firmware"

# --- Tailscale ---
curl -fsSL https://tailscale.com/install.sh | sh

# --- Default shell -> zsh ---
sudo chsh -s "$(command -v zsh)" "$USER"

# --- CJK input methods (IBus) ---
sudo dnf install -y ibus ibus-libpinyin ibus-mozc

# Pick up new engines without a logout
ibus restart 2>/dev/null || ibus-daemon -drx

# Register input sources for the current user (overrides existing list!)
gsettings set org.gnome.desktop.input-sources sources \
  "[('xkb','de+nodeadkeys'),('xkb','us'),('ibus','libpinyin'),('ibus','mozc-jp')]"