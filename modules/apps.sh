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