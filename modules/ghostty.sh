mod_ghostty() {
    echo "[ghostty] Installing Ghostty terminal..."

    if command -v ghostty &>/dev/null; then
        echo "  Ghostty is already installed, skipping."
    else
        # Ghostty for Fedora is available via the scottames/ghostty COPR
        # https://ghostty.org/docs/install/binary#fedora
        sudo dnf install -y 'dnf-command(copr)'
        sudo dnf copr enable -y scottames/ghostty
        sudo dnf install -y ghostty
        echo "  Ghostty installed from COPR (scottames/ghostty)."
    fi
}