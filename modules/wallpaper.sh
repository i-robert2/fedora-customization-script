# shellcheck shell=bash
mod_wallpaper() {
    echo "[wallpaper] Setting solid black 4K wallpaper..."

    local WALL_DIR="$HOME/.local/share/backgrounds"
    local WALL_FILE="$WALL_DIR/solid-black-4k.png"
    mkdir -p "$WALL_DIR"

    if [ ! -f "$WALL_FILE" ]; then
        # Generate a 3840x2160 solid black PNG
        if command -v convert &>/dev/null; then
            convert -size 3840x2160 xc:black "$WALL_FILE"
        elif command -v magick &>/dev/null; then
            magick -size 3840x2160 xc:black "$WALL_FILE"
        else
            # Fallback: install ImageMagick, generate, then remove if it wasn't installed
            sudo dnf install -y ImageMagick 2>/dev/null
            convert -size 3840x2160 xc:black "$WALL_FILE"
        fi
        echo "  Generated solid black 4K image."
    else
        echo "  Wallpaper already exists, skipping generation."
    fi

    # Set as wallpaper for both light and dark mode
    gsettings set org.gnome.desktop.background picture-uri "file://${WALL_FILE}"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://${WALL_FILE}"
    gsettings set org.gnome.desktop.background picture-options 'stretched'
    gsettings set org.gnome.desktop.background primary-color '#000000'

    echo "  Solid black wallpaper applied."
}