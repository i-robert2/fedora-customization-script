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
}