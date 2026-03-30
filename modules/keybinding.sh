# shellcheck shell=bash
mod_keybinding() {
    echo "[keybinding] Configuring Ctrl+Shift+Enter to open Ghostty..."

    CUSTOM_KB_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
    CUSTOM_KB_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    SLOT="custom-ghostty"
    SLOT_PATH="${CUSTOM_KB_BASE}/${SLOT}/"

    # Read existing custom keybindings and append ours if not already present
    EXISTING=$(gsettings get "$CUSTOM_KB_SCHEMA" custom-keybindings)

    if [[ "$EXISTING" == *"${SLOT}"* ]]; then
        echo "  Keybinding slot already exists, updating..."
    else
        if [[ "$EXISTING" == "@as []" ]]; then
            NEW_LIST="['${SLOT_PATH}']"
        else
            # Strip trailing ']' and append our new entry
            NEW_LIST="${EXISTING%]*}, '${SLOT_PATH}']"
        fi
        gsettings set "$CUSTOM_KB_SCHEMA" custom-keybindings "$NEW_LIST"
    fi

    BINDING_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH}"
    gsettings set "$BINDING_SCHEMA" name "Open Ghostty"
    gsettings set "$BINDING_SCHEMA" command "ghostty"
    gsettings set "$BINDING_SCHEMA" binding "<Control><Shift>Return"

    echo "  Ctrl+Shift+Enter -> Ghostty configured."
}