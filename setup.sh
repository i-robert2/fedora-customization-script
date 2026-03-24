#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Fedora Workstation Setup Script
# Run on a fresh Fedora installation to customize the desktop environment.
###############################################################################

echo "=== Fedora Workstation Setup ==="
echo ""

# ---------------------------------------------------------------------------
# 1. Install Ghostty Terminal
# ---------------------------------------------------------------------------
echo "[1/4] Installing Ghostty terminal..."

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

# ---------------------------------------------------------------------------
# 2. Set Ctrl+Shift+Enter keyboard shortcut to open Ghostty
# ---------------------------------------------------------------------------
echo "[2/4] Configuring Ctrl+Shift+Enter to open Ghostty..."

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

# ---------------------------------------------------------------------------
# 3. Fix CapsLock sticky / delayed toggle-off behavior (system-wide)
# ---------------------------------------------------------------------------
echo "[3/4] Fixing CapsLock sticky behavior (user session + GDM login)..."

# --- 3a. Current user session (gsettings / dconf) ---
gsettings set org.gnome.desktop.a11y.keyboard slowkeys-enable false
gsettings set org.gnome.desktop.a11y.keyboard bouncekeys-enable false
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-enable false
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
echo "  User session: accessibility keys disabled, repeat delay 250 ms."

# --- 3b. System-wide dconf profile (applies to GDM + all users) ---
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

# ---------------------------------------------------------------------------
# 4. Customize bash prompt with green teleport beam
# ---------------------------------------------------------------------------
echo "[4/4] Customizing bash prompt with green beam effect..."

BASHRC_BLOCK='
# ── Green teleport beam prompt ────────────────────────────────────────
_beam_prompt() {
    printf "\r\033[K\033[38;5;46m░▒▓\033[38;5;40m█\033[38;5;46m▓▒░\033[0m"
    sleep 0.06
    printf "\r\033[K"
}

PROMPT_COMMAND="_beam_prompt"
export PS1="🛸 \[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]\$ "
# ── end beam prompt ───────────────────────────────────────────────────
'

# Add to ~/.bashrc if not already present
if grep -qF '_beam_prompt' "$HOME/.bashrc" 2>/dev/null; then
    echo "  Beam prompt already configured, skipping."
else
    # Remove old animation if present from a previous run
    sed -i '/_ufo_animate/d; /# Custom prompt with flying saucer emoji/d; /# ── UFO prompt/,/# ── end UFO prompt/d' "$HOME/.bashrc" 2>/dev/null || true
    sed -i '/🛸.*PS1/d; /PROMPT_COMMAND.*_ufo/d' "$HOME/.bashrc" 2>/dev/null || true
    echo "$BASHRC_BLOCK" >> "$HOME/.bashrc"
    echo "  Green beam prompt added to ~/.bashrc"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "=== Setup complete! ==="
echo "  - Ghostty terminal installed"
echo "  - Ctrl+Shift+Enter opens Ghostty"
echo "  - CapsLock responsiveness improved"
echo "  - Bash prompt: 🛸 green beam + user@host:path$"
echo ""
echo "Log out and back in if the keyboard shortcut doesn't take effect immediately."
