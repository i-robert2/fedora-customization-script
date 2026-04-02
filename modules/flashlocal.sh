# shellcheck shell=bash
mod_flashlocal() {
    echo "[flashlocal] Building FlashLocal desktop app..."

    local REPO_URL="https://github.com/i-robert2/Flash-Local.git"
    local APP_DIR="$HOME/Apps/FlashLocal"
    local DESKTOP_FILE="$HOME/.local/share/applications/flashlocal.desktop"

    # --- Ensure Tauri dependencies are available ---
    if ! command -v rustc &>/dev/null; then
        echo "  Error: Rust not found. Run the 'tauri' module first."
        return 1
    fi
    if ! command -v node &>/dev/null; then
        echo "  Error: Node.js not found. Run the 'tauri' module first."
        return 1
    fi

    # --- Clone or update the repo ---
    if [[ -d "$APP_DIR/.git" ]]; then
        echo "  Repo already cloned, pulling latest..."
        git -C "$APP_DIR" pull --ff-only || true
    else
        echo "  Cloning FlashLocal..."
        mkdir -p "$(dirname "$APP_DIR")"
        git clone "$REPO_URL" "$APP_DIR"
    fi

    # --- Install npm dependencies ---
    echo "  Installing npm dependencies..."
    cd "$APP_DIR"
    npm install

    # --- Source cargo env in case it was just installed ---
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

    # --- Build the Tauri desktop app ---
    echo "  Building Tauri desktop app (this may take a few minutes)..."
    npx tauri build

    # --- Install the RPM if available ---
    local RPM_FILE
    RPM_FILE=$(find "$APP_DIR/src-tauri/target/release/bundle/rpm" -name '*.rpm' -print -quit 2>/dev/null || true)

    if [[ -n "$RPM_FILE" && -f "$RPM_FILE" ]]; then
        echo "  Installing FlashLocal RPM..."
        sudo dnf install -y "$RPM_FILE"
        echo "  FlashLocal installed via RPM (available in app grid)."
    else
        # Fallback: use AppImage + manual desktop entry
        local APPIMAGE_FILE
        APPIMAGE_FILE=$(find "$APP_DIR/src-tauri/target/release/bundle/appimage" -name '*.AppImage' -print -quit 2>/dev/null || true)

        if [[ -n "$APPIMAGE_FILE" && -f "$APPIMAGE_FILE" ]]; then
            local INSTALL_DIR="$HOME/.local/bin"
            mkdir -p "$INSTALL_DIR"
            cp "$APPIMAGE_FILE" "$INSTALL_DIR/FlashLocal.AppImage"
            chmod +x "$INSTALL_DIR/FlashLocal.AppImage"

            # Create desktop entry
            mkdir -p "$(dirname "$DESKTOP_FILE")"
            cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=FlashLocal
Comment=Offline-first spaced repetition flashcards
Exec=$INSTALL_DIR/FlashLocal.AppImage
Icon=flashlocal
Terminal=false
Type=Application
Categories=Education;
StartupWMClass=FlashLocal
EOF
            echo "  FlashLocal AppImage installed at $INSTALL_DIR/FlashLocal.AppImage"
            echo "  Desktop entry created."
        else
            echo "  Warning: No RPM or AppImage found in build output."
            echo "  You can run it with: cd $APP_DIR && npx tauri dev"
        fi
    fi

    echo "  FlashLocal desktop app ready."
}
