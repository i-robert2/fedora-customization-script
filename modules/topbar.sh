# shellcheck shell=bash
mod_topbar() {
    echo "[topbar] Configuring top bar (Fedora logo, Vitals, weather, tray, clock right)..."

    # Helper: install a GNOME extension from extensions.gnome.org by UUID.
    # Prints a warning if the install fails (instead of silently swallowing).
    _install_ego_ext() {
        local UUID="$1"
        local GNOME_VER
        GNOME_VER=$(gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1)

        local DL_URL
        DL_URL=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${UUID}&shell_version=${GNOME_VER}" 2>/dev/null \
            | jq -r '.download_url // empty' 2>/dev/null)

        if [[ -n "$DL_URL" ]]; then
            local TMP_ZIP
            TMP_ZIP="$(mktemp /tmp/ext-XXXX.zip)"
            curl -fsSL -o "$TMP_ZIP" "https://extensions.gnome.org${DL_URL}" 2>/dev/null
            if [ -s "$TMP_ZIP" ]; then
                gnome-extensions install --force "$TMP_ZIP"
                rm -f "$TMP_ZIP"
                echo "    OK (EGO): $UUID"
                return 0
            fi
            rm -f "$TMP_ZIP"
        fi
        echo "    WARNING: EGO install failed for $UUID (GNOME $GNOME_VER)"
        return 1
    }

    # Helper: install extension — try dnf package first, then EGO fallback.
    _install_ext() {
        local DNF_PKG="$1"
        local UUID="$2"

        if gnome-extensions list 2>/dev/null | grep -q "$UUID"; then
            echo "  $UUID already installed."
            gnome-extensions enable "$UUID" 2>/dev/null || true
            return 0
        fi

        if [[ -n "$DNF_PKG" ]]; then
            sudo dnf install -y "$DNF_PKG" 2>/dev/null && {
                echo "    OK (dnf): $DNF_PKG"
                gnome-extensions enable "$UUID" 2>/dev/null || true
                return 0
            }
        fi

        _install_ego_ext "$UUID" && {
            gnome-extensions enable "$UUID" 2>/dev/null || true
            return 0
        }

        echo "  WARNING: Could not install $UUID. Install manually from Extension Manager."
        return 1
    }

    # ── 1. Fedora logo menu (replaces Activities with distro logo + dropdown) ──
    echo "  Installing Logo Menu..."
    _install_ext "" "logomenu@aryan_k"
    local LOGO_PATH="/org/gnome/shell/extensions/Logo-menu"
    dconf write "$LOGO_PATH/menu-button-icon-image" "1"           # 1 = Fedora logo
    dconf write "$LOGO_PATH/menu-button-icon-size" "22"
    dconf write "$LOGO_PATH/menu-button-terminal" "'ghostty'"
    dconf write "$LOGO_PATH/hide-icon-shadow" "true"
    echo "  Fedora logo menu configured (replaces Activities button)."

    # ── 2. Install Vitals (system monitors on top bar) ──
    echo "  Installing Vitals..."
    _install_ext "gnome-shell-extension-vitals" "Vitals@CoreCoding.com"

    # ── 3. Weather on the top bar (Advanced Weather Companion) ──
    echo "  Installing Advanced Weather Companion..."
    _install_ext "" "advanced-weather@sanjai.com"
    gnome-extensions enable "advanced-weather@sanjai.com" 2>/dev/null || true
    echo "  Advanced Weather Companion installed."

    # ── 4. AppIndicator + background apps tray ──
    echo "  Installing AppIndicator (tray icons)..."
    _install_ext "gnome-shell-extension-appindicator" "appindicatorsupport@rgcjonas.gmail.com"
    local AI_PATH="/org/gnome/shell/extensions/appindicator"
    dconf write "$AI_PATH/tray-pos" "'right'" 2>/dev/null || true
    echo "  AppIndicator configured (right side)."

    # ── 5. Clock in center via Just Perfection ──
    local JP_ID="just-perfection-desktop@just-perfection"
    gnome-extensions enable "$JP_ID" 2>/dev/null || true
    local JP_PATH="/org/gnome/shell/extensions/just-perfection"
    dconf write "$JP_PATH/clock-menu-position" "0"     # 0=center, 1=right, 2=left
    dconf write "$JP_PATH/clock-menu-position-offset" "0"
    dconf write "$JP_PATH/activities-button" "false"   # hide Activities (Logo Menu replaces it)
    dconf write "$JP_PATH/workspace-switcher" "false"  # hide native right-side workspace thumbnails (extension handles left side)
    echo "  Clock centered, Activities button hidden, native workspace switcher hidden."

    # ── 5b. Weather in center, to the left of the clock ──
    local AW_PATH="/org/gnome/shell/extensions/advanced-weather"
    dconf write "$AW_PATH/panel-position" "'center'" 2>/dev/null || true
    dconf write "$AW_PATH/panel-position-index" "0" 2>/dev/null || true
    dconf write "$AW_PATH/location-mode" "'manual'" 2>/dev/null || true
    dconf write "$AW_PATH/show-temperature-text" "true" 2>/dev/null || true
    dconf write "$AW_PATH/show-location-indicator" "false" 2>/dev/null || true
    dconf write "$AW_PATH/icon-size" "16" 2>/dev/null || true
    dconf write "$AW_PATH/text-size" "13" 2>/dev/null || true
    echo "  Weather positioned: center, left of clock."

    # ── 6. Vitals on the left side ──
    local VIT_PATH="/org/gnome/shell/extensions/vitals"
    dconf write "$VIT_PATH/position-in-panel" "0" 2>/dev/null || true
    dconf write "$VIT_PATH/use-higher-precision" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/alphabetize" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/use-fixed-widths" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/hide-zeros" "false" 2>/dev/null || true
    dconf write "$VIT_PATH/hide-icons" "false" 2>/dev/null || true
    dconf write "$VIT_PATH/menu-centered" "false" 2>/dev/null || true
    dconf write "$VIT_PATH/update-time" "5" 2>/dev/null || true
    dconf write "$VIT_PATH/show-temperature" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/show-voltage" "false" 2>/dev/null || true
    dconf write "$VIT_PATH/show-fan" "false" 2>/dev/null || true
    dconf write "$VIT_PATH/show-memory" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/show-cpu" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/show-system" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/show-network" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/show-storage" "true" 2>/dev/null || true
    dconf write "$VIT_PATH/show-battery" "false" 2>/dev/null || true
    dconf write "$VIT_PATH/show-gpu" "true" 2>/dev/null || true
    echo "  Vitals configured (left, higher precision, fixed widths)."

    # ── 7. GNOME settings ──
    gsettings set org.gnome.desktop.interface clock-show-date true
    gsettings set org.gnome.desktop.interface clock-show-weekday true
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 3
    echo "  Clock, battery %, 3 workspaces configured."

    # ── 8. Disable Dash to Panel if previously installed (conflicts with Dash to Dock) ──
    gnome-extensions disable "dash-to-panel@jderose9.github.com" 2>/dev/null || true

    # ── 9. Enable all extensions ──
    local EXTS_TO_ENABLE=(
        "logomenu@aryan_k"
        "appindicatorsupport@rgcjonas.gmail.com"
        "Vitals@CoreCoding.com"
        "advanced-weather@sanjai.com"
        "just-perfection-desktop@just-perfection"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "burn-my-windows@schneegans.github.com"
    )
    for ext in "${EXTS_TO_ENABLE[@]}"; do
        gnome-extensions enable "$ext" 2>/dev/null || true
    done

    # Disable conflicting extensions
    gnome-extensions disable "window-list@gnome-shell-extensions.gcampax.github.com" 2>/dev/null || true

    echo ""
    echo "  Top bar configured."
    echo "  Layout: [Fedora ▾] [Vitals] ... [██ ▒ ▒] [weather] [tray] [indicators] [clock]"
    echo "  NOTE: Log out & back in to activate."
}