# shellcheck shell=bash
mod_windowfx() {
    echo "[windowfx] Configuring glitch animations for window open/close..."

    local EXT_ID="burn-my-windows@schneegans.github.com"

    # Ensure animations are enabled
    gsettings set org.gnome.desktop.interface enable-animations true

    # Always force-install (gnome-extensions list is unreliable outside a live session)
    local BMW_ZIP
    BMW_ZIP="$(mktemp /tmp/burn-my-windows-XXXX.zip)"
    curl -fsSL -o "$BMW_ZIP" \
        "https://github.com/Schneegans/Burn-My-Windows/releases/latest/download/burn-my-windows@schneegans.github.com.zip"
    gnome-extensions install --force "$BMW_ZIP"
    rm -f "$BMW_ZIP"
    echo "  Burn My Windows installed/updated."

    gnome-extensions enable "$EXT_ID" 2>/dev/null || true
    echo "  Burn My Windows enabled."

    # --- Create a zoom profile (Apparition with no fog = clean zoom) ---
    local PROFILE_DIR="$HOME/.config/burn-my-windows/profiles"
    mkdir -p "$PROFILE_DIR"

    cat > "$PROFILE_DIR/zoom.conf" <<'BMWPROFILE'
[burn-my-windows-profile]
profile-high-priority=true
profile-window-type=0
profile-animation-type=0
pixelate-enable-effect=true
pixelate-animation-time=280
apparition-enable-effect=false
glitch-enable-effect=false
broken-glass-enable-effect=false
doom-enable-effect=false
energize-a-enable-effect=false
energize-b-enable-effect=false
fire-enable-effect=false
glide-enable-effect=false
hexagon-enable-effect=false
incinerate-enable-effect=false
matrix-enable-effect=false
paint-brush-enable-effect=false
pixel-wheel-enable-effect=false
pixel-wipe-enable-effect=false
portal-enable-effect=false
snap-enable-effect=false
trex-enable-effect=false
tv-enable-effect=false
tv-glitch-enable-effect=false
wisps-enable-effect=false
BMWPROFILE

    # Point extension to the zoom profile (must be absolute path)
    dconf write /org/gnome/shell/extensions/burn-my-windows/active-profile \
        "'${PROFILE_DIR}/zoom.conf'"

    echo "  Pixelate animations configured (280ms)."
    echo "  NOTE: Log out & back in to activate."
}