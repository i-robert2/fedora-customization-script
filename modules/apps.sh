# shellcheck shell=bash
mod_apps() {
    echo "[apps] Installing user applications..."

    # --- Discord (Flatpak — official, sandboxed, auto-updated) ---
    if flatpak info com.discordapp.Discord &>/dev/null 2>&1; then
        echo "  Discord is already installed, skipping."
    else
        echo "  Installing Discord via Flatpak..."
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --user -y flathub com.discordapp.Discord
        echo "  Discord installed."
    fi

    # --- Tor Browser (Flatpak — sandboxed, auto-updated) ---
    if flatpak info com.github.nickvergessen.TorBrowser &>/dev/null 2>&1 || flatpak info org.torproject.torbrowser-launcher &>/dev/null 2>&1; then
        echo "  Tor Browser is already installed, skipping."
    else
        echo "  Installing Tor Browser via Flatpak..."
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --user -y flathub org.torproject.torbrowser-launcher
        echo "  Tor Browser installed."
    fi

    # --- GIMP (dnf) ---
    if command -v gimp &>/dev/null; then
        echo "  GIMP is already installed, skipping."
    else
        echo "  Installing GIMP..."
        sudo dnf install -y gimp
        echo "  GIMP installed."
    fi

    # --- Krita (dnf) ---
    if command -v krita &>/dev/null; then
        echo "  Krita is already installed, skipping."
    else
        echo "  Installing Krita..."
        sudo dnf install -y krita
        echo "  Krita installed."
    fi

    # --- Drawing (Flatpak) ---
    if flatpak info com.github.maoschanz.drawing &>/dev/null 2>&1; then
        echo "  Drawing is already installed, skipping."
    else
        echo "  Installing Drawing via Flatpak..."
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --user -y flathub com.github.maoschanz.drawing
        echo "  Drawing installed."
    fi

    # --- darktable (dnf) ---
    if command -v darktable &>/dev/null; then
        echo "  darktable is already installed, skipping."
    else
        echo "  Installing darktable..."
        sudo dnf install -y darktable
        echo "  darktable installed."
    fi

    # --- digiKam (dnf) ---
    if command -v digikam &>/dev/null; then
        echo "  digiKam is already installed, skipping."
    else
        echo "  Installing digiKam..."
        sudo dnf install -y digikam
        echo "  digiKam installed."
    fi

    # --- Kdenlive (dnf) ---
    if command -v kdenlive &>/dev/null; then
        echo "  Kdenlive is already installed, skipping."
    else
        echo "  Installing Kdenlive..."
        sudo dnf install -y kdenlive
        echo "  Kdenlive installed."
    fi

    # --- VLC (dnf — needs RPM Fusion for full codec support) ---
    if command -v vlc &>/dev/null; then
        echo "  VLC is already installed, skipping."
    else
        echo "  Installing VLC..."
        # RPM Fusion is set up by the Jellyfin block below if not already present
        if ! rpm -q rpmfusion-free-release &>/dev/null; then
            sudo dnf install -y \
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        fi
        sudo dnf install -y vlc
        echo "  VLC installed."
    fi

    # --- Google Chrome (official repo) ---
    if command -v google-chrome-stable &>/dev/null; then
        echo "  Google Chrome is already installed, skipping."
    else
        echo "  Installing Google Chrome..."
        sudo dnf install -y fedora-workstation-repositories 2>/dev/null || true
        sudo dnf config-manager setopt google-chrome.enabled=1 2>/dev/null || true
        # Fallback: add repo manually if fedora-workstation-repositories didn't work
        if ! dnf repolist | grep -q google-chrome; then
            sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<'REPO'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
REPO
        fi
        sudo dnf install -y google-chrome-stable
        echo "  Google Chrome installed."
    fi

    # --- Thunderbird (dnf) ---
    if command -v thunderbird &>/dev/null; then
        echo "  Thunderbird is already installed, skipping."
    else
        echo "  Installing Thunderbird..."
        sudo dnf install -y thunderbird
        echo "  Thunderbird installed."
    fi

    # --- Audacity (dnf) ---
    if command -v audacity &>/dev/null; then
        echo "  Audacity is already installed, skipping."
    else
        echo "  Installing Audacity..."
        sudo dnf install -y audacity
        echo "  Audacity installed."
    fi

    # --- qBittorrent (dnf) ---
    if command -v qbittorrent &>/dev/null; then
        echo "  qBittorrent is already installed, skipping."
    else
        echo "  Installing qBittorrent..."
        sudo dnf install -y qbittorrent
        echo "  qBittorrent installed."
    fi

    # --- Flatseal (Flatpak — manage Flatpak app permissions) ---
    if flatpak info com.github.tchx84.Flatseal &>/dev/null 2>&1; then
        echo "  Flatseal is already installed, skipping."
    else
        echo "  Installing Flatseal via Flatpak..."
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --user -y flathub com.github.tchx84.Flatseal
        echo "  Flatseal installed."
    fi

    # --- Signal (Flatpak — sandboxed, auto-updated) ---
    if flatpak info org.signal.Signal &>/dev/null 2>&1; then
        echo "  Signal is already installed, skipping."
    else
        echo "  Installing Signal via Flatpak..."
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --user -y flathub org.signal.Signal
        echo "  Signal installed."
    fi

    # --- Docker (official repo) ---
    if command -v docker &>/dev/null; then
        echo "  Docker is already installed, skipping."
    else
        echo "  Installing Docker..."
        sudo dnf -y install dnf-plugins-core
        sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<'REPO'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
REPO
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable --now docker
        # Add current user to docker group for rootless usage
        if ! groups "$USER" | grep -q docker; then
            sudo usermod -aG docker "$USER"
            echo "  NOTE: Log out and back in for Docker group membership to take effect."
        fi
        echo "  Docker installed."
    fi

    # --- Jellyfin (via RPM Fusion — no auto-start, manual launch via desktop shortcut) ---
    if rpm -q jellyfin &>/dev/null; then
        echo "  Jellyfin is already installed, skipping."
    else
        echo "  Installing Jellyfin..."
        # Remove stale Jellyfin repo if left over from a previous install attempt
        sudo rm -f /etc/yum.repos.d/jellyfin.repo
        # Enable RPM Fusion repos if not already present (required for Jellyfin on Fedora)
        if ! rpm -q rpmfusion-free-release &>/dev/null; then
            sudo dnf install -y \
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        fi
        # RPM Fusion ffmpeg replaces Fedora's ffmpeg-free; --allowerasing allows the swap
        sudo dnf install -y --allowerasing jellyfin
        # Ensure it does NOT start on boot
        sudo systemctl disable jellyfin 2>/dev/null || true
        echo "  Jellyfin installed (manual start only)."
    fi

    # --- Jellyfin desktop launcher ---
    local JELLYFIN_DESKTOP="$HOME/.local/share/applications/jellyfin.desktop"
    if [[ -f "$JELLYFIN_DESKTOP" ]]; then
        echo "  Jellyfin desktop launcher already exists, skipping."
    else
        echo "  Creating Jellyfin desktop launcher..."
        mkdir -p "$HOME/.local/share/applications"
        cat > "$JELLYFIN_DESKTOP" <<'EOF'
[Desktop Entry]
Name=Jellyfin
Comment=Self-hosted media server
Exec=bash -c 'sudo systemctl start jellyfin; sleep 2; xdg-open http://localhost:8096'
Icon=jellyfin
Terminal=false
Type=Application
Categories=AudioVideo;Video;Player;
EOF
        echo "  Jellyfin desktop launcher created."
    fi

    # --- KVM/QEMU + virt-manager (native Fedora virtualization) ---
    if command -v virsh &>/dev/null; then
        echo "  KVM/QEMU is already installed, skipping."
    else
        echo "  Installing KVM/QEMU + virt-manager..."
        sudo dnf install -y @virtualization
        echo "  KVM/QEMU + virt-manager installed."
    fi

    # Enable and start libvirtd if not already active
    if ! systemctl is-active --quiet libvirtd; then
        echo "  Enabling libvirtd service..."
        sudo systemctl enable --now libvirtd
    fi

    # Add current user to libvirt group for passwordless VM management
    if ! groups "$USER" | grep -q libvirt; then
        echo "  Adding $USER to libvirt group..."
        sudo usermod -aG libvirt "$USER"
        echo "  NOTE: Log out and back in for group membership to take effect."
    fi

    # --- Reactive Resume (self-hosted, Podman Compose) ---
    if ! command -v podman-compose &>/dev/null; then
        echo "  Installing podman-compose..."
        sudo dnf install -y podman-compose
    fi

    local RR_DIR="$HOME/reactive-resume"
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if [[ -f "$RR_DIR/compose.yml" ]]; then
        echo "  Reactive Resume compose file already exists, skipping."
    else
        echo "  Setting up Reactive Resume..."
        mkdir -p "$RR_DIR"
        cp "$SCRIPT_DIR/templates/reactive-resume-compose.yml" "$RR_DIR/compose.yml"

        # Generate a random secret for auth
        local AUTH_SECRET
        AUTH_SECRET=$(openssl rand -hex 32)
        sed -i "s/change-me-to-a-secure-secret-key-in-production/$AUTH_SECRET/" "$RR_DIR/compose.yml"

        echo "  Reactive Resume configured at $RR_DIR"
    fi

    # --- Reactive Resume start/stop script ---
    local RR_SCRIPT="$HOME/.local/bin/reactive-resume"
    mkdir -p "$HOME/.local/bin"
    cat > "$RR_SCRIPT" <<'SCRIPT'
#!/usr/bin/env bash
RR_DIR="$HOME/reactive-resume"
case "${1:-}" in
    start)
        echo "Starting Reactive Resume..."
        podman-compose -f "$RR_DIR/compose.yml" up -d
        echo "Reactive Resume starting at http://localhost:3002"
        echo "  (may take 30-60 seconds on first run to pull images)"
        ;;
    stop)
        echo "Stopping Reactive Resume..."
        podman-compose -f "$RR_DIR/compose.yml" down
        echo "Reactive Resume stopped."
        ;;
    status)
        podman-compose -f "$RR_DIR/compose.yml" ps
        ;;
    *)
        echo "Usage: reactive-resume {start|stop|status}"
        exit 1
        ;;
esac
SCRIPT
    chmod +x "$RR_SCRIPT"

    # --- Reactive Resume desktop launcher ---
    local RR_DESKTOP="$HOME/.local/share/applications/reactive-resume.desktop"
    if [[ -f "$RR_DESKTOP" ]]; then
        echo "  Reactive Resume desktop launcher already exists, skipping."
    else
        echo "  Creating Reactive Resume desktop launcher..."
        mkdir -p "$HOME/.local/share/applications"
        cat > "$RR_DESKTOP" <<'EOF'
[Desktop Entry]
Name=Reactive Resume
Comment=Self-hosted resume builder
Exec=bash -c '$HOME/.local/bin/reactive-resume start; sleep 5; xdg-open http://localhost:3002'
Icon=accessories-text-editor
Terminal=false
Type=Application
Categories=Office;
EOF
        echo "  Reactive Resume desktop launcher created."
    fi
}