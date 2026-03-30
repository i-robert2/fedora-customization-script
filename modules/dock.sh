mod_dock() {
    echo "[dock] Installing and configuring Dash to Dock..."

    local EXT_ID="dash-to-dock@micxgx.gmail.com"
    local DCONF_PATH="/org/gnome/shell/extensions/dash-to-dock"

    # --- Install from Fedora repos ---
    if gnome-extensions list 2>/dev/null | grep -q "$EXT_ID"; then
        echo "  Dash to Dock already installed, skipping."
    else
        sudo dnf install -y gnome-shell-extension-dash-to-dock
        echo "  Dash to Dock installed."
    fi

    # --- Enable the extension ---
    gnome-extensions enable "$EXT_ID" 2>/dev/null || true
    echo "  Dash to Dock enabled."

    # --- Configure: bottom dock, auto-hide ---
    dconf write "$DCONF_PATH/dock-position" "'BOTTOM'"
    dconf write "$DCONF_PATH/dock-fixed" "false"
    dconf write "$DCONF_PATH/autohide" "true"
    dconf write "$DCONF_PATH/autohide-in-fullscreen" "false"
    dconf write "$DCONF_PATH/dash-max-icon-size" "40"
    dconf write "$DCONF_PATH/show-trash" "false"
    dconf write "$DCONF_PATH/show-mounts" "false"
    dconf write "$DCONF_PATH/show-show-apps-button" "false"

    # In a VM the cursor escapes the screen edge, so cursor-pressure autohide
    # doesn't work. Use intellihide (window-aware) in VMs instead.
    if systemd-detect-virt --quiet 2>/dev/null; then
        dconf write "$DCONF_PATH/intellihide" "true"
        echo "  VM detected — using intellihide (shows when no window covers dock)."
    else
        dconf write "$DCONF_PATH/intellihide" "false"
        echo "  Bare metal — using cursor-pressure autohide."
    fi

    echo "  Dock configured: bottom, auto-hide, no Show Apps button."
}