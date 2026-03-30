mod_font() {
    echo "[font] Installing JetBrainsMono Nerd Font..."

    FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
    if ls "$FONT_DIR"/JetBrainsMonoNerd* &>/dev/null 2>&1; then
        echo "  JetBrainsMono Nerd Font already installed, skipping."
    else
        FONT_VERSION="3.3.0"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/JetBrainsMono.zip"
        TMP_ZIP="$(mktemp /tmp/JetBrainsMono-XXXX.zip)"
        echo "  Downloading JetBrainsMono Nerd Font v${FONT_VERSION}..."
        curl -fsSL -o "$TMP_ZIP" "$FONT_URL"
        mkdir -p "$FONT_DIR"
        unzip -qo "$TMP_ZIP" -d "$FONT_DIR"
        rm -f "$TMP_ZIP"
        fc-cache -f "$FONT_DIR"
        echo "  JetBrainsMono Nerd Font installed and font cache updated."
    fi

    # Configure Ghostty to use the Nerd Font
    GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
    GHOSTTY_CONFIG="$GHOSTTY_CONFIG_DIR/config"
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    if [ -f "$GHOSTTY_CONFIG" ] && grep -q 'font-family' "$GHOSTTY_CONFIG"; then
        echo "  Ghostty font already configured, skipping."
    else
        echo 'font-family = "JetBrainsMono Nerd Font"' >> "$GHOSTTY_CONFIG"
        echo "  Ghostty configured to use JetBrainsMono Nerd Font."
    fi

    # Add keybindings for word navigation and line selection
    # First, aggressively remove any old/broken keybind lines
    sed -i '/keybind.*ctrl+left/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*ctrl+right/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*ctrl+shift+left/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*ctrl+shift+right/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*shift+home/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*shift+end/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/adjust_selection/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/# Word navigation/d; /# Word selection/d; /# Line selection/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    # Remove blank lines at end of file
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$GHOSTTY_CONFIG" 2>/dev/null || true

    cat >> "$GHOSTTY_CONFIG" <<'GHOSTTYKEYS'

# Word navigation: Ctrl+Left/Right jumps by word
keybind = ctrl+left=esc:b
keybind = ctrl+right=esc:f

# Line selection: Shift+Home/End selects to start/end of line
keybind = shift+home=adjust_selection:beginning_of_line
keybind = shift+end=adjust_selection:end_of_line
GHOSTTYKEYS
    echo "  Ghostty keybindings configured (word jump, line select)."
}