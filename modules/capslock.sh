# shellcheck shell=bash
mod_capslock() {
    echo "[capslock] Fixing CapsLock sticky behavior (user session + GDM login)..."

    # Current user session (gsettings / dconf)
    gsettings set org.gnome.desktop.a11y.keyboard slowkeys-enable false
    gsettings set org.gnome.desktop.a11y.keyboard bouncekeys-enable false
    gsettings set org.gnome.desktop.a11y.keyboard stickykeys-enable false
    gsettings set org.gnome.desktop.peripherals.keyboard delay 250
    gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
    echo "  User session: accessibility keys disabled, repeat delay 250 ms."

    # System-wide dconf profile (applies to GDM + all users)
    DCONF_PROFILE="/etc/dconf/profile/gdm"
    DCONF_DB_DIR="/etc/dconf/db/gdm.d"
    DCONF_KEYFILE="${DCONF_DB_DIR}/99-capslock-fix"

    # Ensure the GDM dconf profile exists and includes the gdm database
    if [ ! -f "$DCONF_PROFILE" ]; then
        sudo mkdir -p "$(dirname "$DCONF_PROFILE")"
        sudo tee "$DCONF_PROFILE" > /dev/null <<'EOF'
user-db:user
system-db:gdm
EOF
        echo "  Created dconf profile for GDM."
    else
        if ! grep -q 'system-db:gdm' "$DCONF_PROFILE"; then
            echo "system-db:gdm" | sudo tee -a "$DCONF_PROFILE" > /dev/null
            echo "  Appended system-db:gdm to existing GDM dconf profile."
        fi
    fi

    # Write the keyboard settings into the GDM dconf database
    sudo mkdir -p "$DCONF_DB_DIR"
    sudo tee "$DCONF_KEYFILE" > /dev/null <<'EOF'
[org/gnome/desktop/a11y/keyboard]
slowkeys-enable=false
bouncekeys-enable=false
stickykeys-enable=false

[org/gnome/desktop/peripherals/keyboard]
delay=uint32 250
repeat-interval=uint32 30
EOF

    # Rebuild the dconf database so GDM picks up the changes
    sudo dconf update
    echo "  GDM login screen: same keyboard settings applied via dconf."
}