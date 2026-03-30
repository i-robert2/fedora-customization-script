# shellcheck shell=bash
mod_rofi() {
    echo "[rofi] Installing and configuring rofi app launcher..."

    # --- Install rofi ---
    if command -v rofi &>/dev/null; then
        echo "  rofi is already installed, skipping."
    else
        sudo dnf install -y rofi
        echo "  rofi installed."
    fi

    # --- Install Catppuccin Mocha theme ---
    ROFI_THEME_DIR="$HOME/.local/share/rofi/themes"
    ROFI_THEME="$ROFI_THEME_DIR/catppuccin-mocha.rasi"
    ROFI_DEFAULT="$ROFI_THEME_DIR/catppuccin-default.rasi"

    mkdir -p "$ROFI_THEME_DIR"

    if [ -f "$ROFI_THEME" ]; then
        echo "  Catppuccin Mocha palette already installed, skipping."
    else
        curl -fsSL -o "$ROFI_THEME" \
            "https://raw.githubusercontent.com/catppuccin/rofi/main/themes/catppuccin-mocha.rasi"
        echo "  Catppuccin Mocha palette downloaded."
    fi

    if [ -f "$ROFI_DEFAULT" ]; then
        echo "  Catppuccin default theme already installed, skipping."
    else
        curl -fsSL -o "$ROFI_DEFAULT" \
            "https://raw.githubusercontent.com/catppuccin/rofi/main/catppuccin-default.rasi"
        echo "  Catppuccin default theme downloaded."
    fi

    # --- Write rofi config ---
    ROFI_CONFIG_DIR="$HOME/.config/rofi"
    ROFI_CONFIG="$ROFI_CONFIG_DIR/config.rasi"
    mkdir -p "$ROFI_CONFIG_DIR"

    cat > "$ROFI_CONFIG" <<'ROFICONF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    terminal: "ghostty";
    drun-display-format: "{icon} {name}";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    font: "JetBrainsMono Nerd Font 12";
    case-sensitive: false;
}

@theme "catppuccin-default"
ROFICONF
    echo "  ~/.config/rofi/config.rasi written."

    # --- Set Super+D keybinding to launch rofi ---
    CUSTOM_KB_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
    CUSTOM_KB_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    SLOT="custom-rofi"
    SLOT_PATH="${CUSTOM_KB_BASE}/${SLOT}/"

    EXISTING=$(gsettings get "$CUSTOM_KB_SCHEMA" custom-keybindings)

    if [[ "$EXISTING" == *"${SLOT}"* ]]; then
        echo "  Keybinding slot already exists, updating..."
    else
        if [[ "$EXISTING" == "@as []" ]]; then
            NEW_LIST="['${SLOT_PATH}']"
        else
            NEW_LIST="${EXISTING%]*}, '${SLOT_PATH}']"
        fi
        gsettings set "$CUSTOM_KB_SCHEMA" custom-keybindings "$NEW_LIST"
    fi

    BINDING_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH}"
    gsettings set "$BINDING_SCHEMA" name "Rofi App Launcher"
    gsettings set "$BINDING_SCHEMA" command "rofi -show drun"
    gsettings set "$BINDING_SCHEMA" binding "<Super>d"

    echo "  Super+D -> rofi -show drun configured."
}