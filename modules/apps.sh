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

    # --- Jellyfin (dnf — no auto-start, manual launch via desktop shortcut) ---
    if rpm -q jellyfin &>/dev/null; then
        echo "  Jellyfin is already installed, skipping."
    else
        echo "  Installing Jellyfin..."
        sudo dnf install -y jellyfin jellyfin-web jellyfin-server
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
}