# shellcheck shell=bash
mod_tauri() {
    echo "[tauri] Installing Rust, Node.js & Tauri 2 system dependencies..."

    # --- Tauri 2 system libraries (Fedora) ---
    local -a TAURI_DEPS=(
        webkit2gtk4.1-devel      # WebView for Tauri 2
        openssl-devel            # TLS / crypto
        curl                     # HTTP client
        wget                     # file downloads
        file                     # libmagic (MIME detection)
        libappindicator-gtk3-devel  # system tray support
        librsvg2-devel           # SVG rendering (icons)
        patchelf                 # patch ELF binaries (AppImage)
        gtk3-devel               # GTK3 headers
        glib2-devel              # GLib headers
        cairo-devel              # 2D graphics
        pango-devel              # text layout
        gdk-pixbuf2-devel        # image loading
        atk-devel                # accessibility
        libsoup3-devel           # HTTP library (WebKitGTK dep)
        javascriptcoregtk4.1-devel  # JS engine (WebKitGTK dep)
    )

    local to_install=()
    for pkg in "${TAURI_DEPS[@]}"; do
        if rpm -q "${pkg%-devel}" &>/dev/null || rpm -q "$pkg" &>/dev/null; then
            echo "  $pkg already installed, skipping."
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo "  All Tauri system dependencies already installed."
    else
        echo "  Installing: ${to_install[*]}"
        sudo dnf install -y "${to_install[@]}"
        echo "  Tauri system dependencies installed."
    fi

    # --- Rust (via rustup) ---
    if command -v rustc &>/dev/null; then
        echo "  Rust is already installed ($(rustc --version)), skipping."
    else
        echo "  Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
        echo "  Rust installed ($(rustc --version))."
    fi

    # --- Node.js + npm ---
    if command -v node &>/dev/null; then
        echo "  Node.js is already installed ($(node --version)), skipping."
    else
        echo "  Installing Node.js + npm..."
        sudo dnf install -y nodejs npm
        echo "  Node.js installed ($(node --version))."
    fi

    # --- Tauri CLI (installed globally via cargo) ---
    if command -v cargo-tauri &>/dev/null || cargo install --list 2>/dev/null | grep -q 'tauri-cli'; then
        echo "  Tauri CLI is already installed, skipping."
    else
        echo "  Installing Tauri CLI via cargo..."
        cargo install tauri-cli
        echo "  Tauri CLI installed."
    fi

    echo "  Tauri dev environment ready."
    echo "  To build: cd <project> && npm install && npm run tauri dev"
}
