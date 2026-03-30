mod_tiling() {
    echo "[tiling] Configuring tiling: halves, quarters, gaps + borders..."

    # ── 1. Tiling Assistant extension ─────────────────────────────────────
    local TILE_ID="tiling-assistant@leleat-on-github"

    if gnome-extensions list 2>/dev/null | grep -q "$TILE_ID"; then
        echo "  Tiling Assistant already installed."
    else
        # Try dnf package first (most reliable on Fedora)
        if sudo dnf install -y gnome-shell-extension-tiling-assistant 2>/dev/null; then
            echo "  Tiling Assistant installed via dnf."
        else
            # Fallback: download from GitHub releases
            local TILE_ZIP
            TILE_ZIP="$(mktemp /tmp/tiling-assistant-XXXX.zip)"
            curl -fsSL -o "$TILE_ZIP" \
                "https://github.com/Leleat/Tiling-Assistant/releases/latest/download/tiling-assistant@leleat-on-github.zip" \
                2>/dev/null || true
            if [ -s "$TILE_ZIP" ]; then
                gnome-extensions install --force "$TILE_ZIP"
                echo "  Tiling Assistant installed from GitHub."
            else
                echo "  ERROR: Could not install Tiling Assistant."
                echo "  Install manually: open Extension Manager → Browse → search 'Tiling Assistant' → Install"
            fi
            rm -f "$TILE_ZIP"
        fi
    fi

    gnome-extensions enable "$TILE_ID" 2>/dev/null || true

    # ── 2. Symmetric gaps (windows float — never touch screen edges) ─────
    local TILE_PATH="/org/gnome/shell/extensions/tiling-assistant"
    local GAP=12
    dconf write "$TILE_PATH/window-gap"         "$GAP"
    dconf write "$TILE_PATH/single-screen-gap"  "$GAP"
    dconf write "$TILE_PATH/screen-top-gap"     "$GAP"
    dconf write "$TILE_PATH/screen-bottom-gap"  "$GAP"
    dconf write "$TILE_PATH/screen-left-gap"    "$GAP"
    dconf write "$TILE_PATH/screen-right-gap"   "$GAP"
    dconf write "$TILE_PATH/maximize-with-gap"  "true"
    dconf write "$TILE_PATH/enable-tiling-popup" "true"
    echo "  Symmetric ${GAP}px gaps configured (windows never touch edges)."

    # Ensure GNOME's native drag-to-edge tiling is on
    gsettings set org.gnome.mutter edge-tiling true

    # ── 3. Tiling keybindings ───────────────────────────────────────────
    # Unbind GNOME's native Super+Up/Down maximize/restore so TA can use them
    gsettings set org.gnome.desktop.wm.keybindings maximize "[]"
    gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]"
    # Unbind GNOME's native Super+Left/Right tiling so TA handles it with gaps
    gsettings set org.gnome.mutter.keybindings toggle-tiled-left "[]"
    gsettings set org.gnome.mutter.keybindings toggle-tiled-right "[]"
    # Restore Alt+Tab to default (may have been modified)
    gsettings reset org.gnome.desktop.wm.keybindings switch-windows
    gsettings reset org.gnome.desktop.wm.keybindings switch-windows-backward

    # Halves with gaps (Super + Arrow) — set below with focus nav bindings

    # Quarter tiling (Super + U/I/J/K — laid out like a 2×2 grid)
    #         U = top-left      I = top-right
    #         J = bottom-left   K = bottom-right
    dconf write "$TILE_PATH/tile-topleft-quarter"     "['<Super>u']"
    dconf write "$TILE_PATH/tile-topright-quarter"    "['<Super>i']"
    dconf write "$TILE_PATH/tile-bottomleft-quarter"  "['<Super>j']"
    dconf write "$TILE_PATH/tile-bottomright-quarter" "['<Super>k']"

    # Maximize (with gaps) / restore
    dconf write "$TILE_PATH/tile-maximize"  "['<Super>y']"
    dconf write "$TILE_PATH/restore-window" "['<Super>Escape']"

    # No-gap tiling (ignores Tiling Assistant gaps)
    #   Super+N = left half (no gaps)    Super+M = right half (no gaps)
    #   Super+B = true fullscreen (no gaps)
    dconf write "$TILE_PATH/tile-left-half-ignore-ta"  "['<Super>n']"
    dconf write "$TILE_PATH/tile-right-half-ignore-ta" "['<Super>m']"
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>b']"

    # Unbind GNOME's native Super+N minimize (conflicts with no-gap left half)
    gsettings set org.gnome.desktop.wm.keybindings minimize "[]"

    # Focus navigation: Super+Arrow tiles if floating, focuses neighbor if tiled
    dconf write "$TILE_PATH/dynamic-keybinding-behavior" "1"
    dconf write "$TILE_PATH/tile-left-half"   "['<Super>Left']"
    dconf write "$TILE_PATH/tile-right-half"  "['<Super>Right']"
    dconf write "$TILE_PATH/tile-top-half"    "['<Super>Up']"
    dconf write "$TILE_PATH/tile-bottom-half" "['<Super>Down']"

    echo "  Tiling keybindings configured:"
    echo "    Halves (gaps):    Super+Left / Right / Up / Down"
    echo "    Quarters (gaps):  Super+U / I / J / K"
    echo "    Maximize (gaps):  Super+Y  |  Restore: Super+Escape"
    echo "    No-gap halves:    Super+N (left) / Super+M (right)"
    echo "    No-gap fullscreen: Super+B"
    echo "    Focus navigation: Super+Arrow (focuses neighbor when already tiled)"

    # ── 4. Ensure min/max/close buttons + dark theme ──
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    echo "  Window buttons + dark theme configured."

    # ── 5. Transparent top bar using Just Perfection (Fedora repos — reliable) ──
    local JP_ID="just-perfection-desktop@just-perfection"
    if ! gnome-extensions list 2>/dev/null | grep -q "$JP_ID"; then
        sudo dnf install -y gnome-shell-extension-just-perfection 2>/dev/null || true
    fi
    gnome-extensions enable "$JP_ID" 2>/dev/null || true

    local JP_PATH="/org/gnome/shell/extensions/just-perfection"
    dconf write "$JP_PATH/panel-in-overview" "true"
    echo "  Top bar configured via Just Perfection."

    # ── 6. White active window border via GNOME Shell theme override ──
    local THEME_DIR="$HOME/.local/share/themes/WhiteBorder/gnome-shell"
    mkdir -p "$THEME_DIR"

    cat > "$THEME_DIR/gnome-shell.css" <<'SHELLCSS'
/* Import the default Adwaita theme */
@import url("resource:///org/gnome/shell/theme/gnome-shell.css");

/* Semi-transparent grey top bar */
#panel {
    background-color: rgba(40, 40, 40, 0.7) !important;
}

/* White border on focused windows */
.window-clone .window-caption {
    color: white;
}
SHELLCSS

    # Apply the user theme (User Themes extension is already installed by tools module)
    gsettings set org.gnome.shell.extensions.user-theme name 'WhiteBorder'
    echo "  GNOME Shell theme override applied."

    # Also set GTK CSS for CSD window borders
    local GTK4_CSS="$HOME/.config/gtk-4.0/gtk.css"
    mkdir -p "$(dirname "$GTK4_CSS")"
    cat > "$GTK4_CSS" <<'GTKCSS'
/* White glow on focused windows via shadow (no border trace artifacts) */
window.csd {
    box-shadow: 0 0 0 2px rgba(255,255,255,0.5);
}
window.csd:backdrop {
    box-shadow: 0 0 0 1px rgba(255,255,255,0.06);
}
GTKCSS

    local GTK3_CSS="$HOME/.config/gtk-3.0/gtk.css"
    mkdir -p "$(dirname "$GTK3_CSS")"
    cat > "$GTK3_CSS" <<'GTK3CSS'
/* White glow on focused windows via shadow (no border trace artifacts) */
decoration {
    box-shadow: 0 0 0 2px rgba(255,255,255,0.5);
}
decoration:backdrop {
    box-shadow: 0 0 0 1px rgba(255,255,255,0.06);
}
GTK3CSS

    echo "  White active window border configured."
    echo "  NOTE: Log out & back in to activate."
}