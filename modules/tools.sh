# shellcheck shell=bash
mod_tools() {
    echo "[tools] Installing CLI tools..."

    local -A TOOLS=(
        [bat]="bat"           # cat with syntax highlighting
        [btop]="btop"         # resource monitor (CPU, RAM, disk, network)
        [eza]="eza"           # modern ls replacement (--tree, icons, git)
        [fastfetch]="fastfetch" # system info display (neofetch replacement)
        [fd]="fd-find"        # fast find alternative
        [fzf]="fzf"           # fuzzy finder
        [gnome-tweaks]="gnome-tweaks" # GNOME desktop customization tool
        [htop]="htop"         # interactive process viewer
        [jq]="jq"             # JSON processor
        [ncdu]="ncdu"         # disk usage analyzer
        [rg]="ripgrep"        # fast recursive grep
        [duf]="duf"           # disk usage (df replacement)
        [tldr]="tldr"         # simplified man pages
        [tesseract]="tesseract" # OCR engine for images
        [ocrmypdf]="ocrmypdf"   # adds searchable text layer to scanned PDFs
        [exiftool]="perl-Image-ExifTool" # metadata viewer/stripper for files
    )

    local to_install=()
    for cmd in "${!TOOLS[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            echo "  ${TOOLS[$cmd]} is already installed, skipping."
        else
            to_install+=("${TOOLS[$cmd]}")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo "  All CLI tools already installed."
    else
        echo "  Installing: ${to_install[*]}"
        sudo dnf install -y "${to_install[@]}"
        echo "  CLI tools installed."
    fi

    # --- Tesseract language pack ---
    if rpm -q tesseract-langpack-eng &>/dev/null; then
        echo "  Tesseract English language pack already installed, skipping."
    else
        echo "  Installing Tesseract English language pack..."
        sudo dnf install -y tesseract-langpack-eng
        echo "  Tesseract English language pack installed."
    fi

    # --- PaddleOCR (best accuracy OCR engine, needs Python ≤ 3.12) ---
    local PADDLE_VENV="$HOME/.local/share/paddleocr-venv"
    if [[ -x "$PADDLE_VENV/bin/python" ]] && "$PADDLE_VENV/bin/python" -c "import paddleocr" &>/dev/null 2>&1; then
        echo "  PaddleOCR is already installed, skipping."
    else
        echo "  Installing PaddleOCR..."
        # PaddlePaddle requires Python ≤ 3.12 — find a compatible version
        local py_bin=""
        for candidate in python3.12 python3.11 python3.10; do
            if command -v "$candidate" &>/dev/null; then
                py_bin="$candidate"
                break
            fi
        done

        if [[ -z "$py_bin" ]]; then
            echo "  System Python is too new for PaddlePaddle. Installing Python 3.12..."
            sudo dnf install -y python3.12 2>/dev/null || true
            if command -v python3.12 &>/dev/null; then
                py_bin="python3.12"
            else
                echo "  ⚠ Could not install Python 3.12. Skipping PaddleOCR."
                echo "    (PaddlePaddle does not yet support your Python version)"
            fi
        fi

        if [[ -n "$py_bin" ]]; then
            echo "  Using $py_bin for PaddleOCR virtualenv..."
            "$py_bin" -m venv "$PADDLE_VENV"
            "$PADDLE_VENV/bin/pip" install --upgrade pip
            if "$PADDLE_VENV/bin/pip" install paddlepaddle paddleocr; then
                # Create a wrapper so 'paddleocr' is on PATH
                mkdir -p "$HOME/.local/bin"
                cat > "$HOME/.local/bin/paddleocr" <<'WRAPPER'
#!/usr/bin/env bash
exec "$HOME/.local/share/paddleocr-venv/bin/paddleocr" "$@"
WRAPPER
                chmod +x "$HOME/.local/bin/paddleocr"
                echo "  PaddleOCR installed (venv: $PADDLE_VENV)."
            else
                echo "  ⚠ PaddleOCR installation failed. Skipping."
                rm -rf "$PADDLE_VENV"
            fi
        fi
    fi

    # --- Extension Manager (Flatpak) ---
    if flatpak info com.mattjakeman.ExtensionManager &>/dev/null 2>&1; then
        echo "  Extension Manager is already installed, skipping."
    else
        echo "  Installing Extension Manager via Flatpak..."
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --user -y flathub com.mattjakeman.ExtensionManager
        echo "  Extension Manager installed."
    fi

    # --- GNOME User Themes extension ---
    if gnome-extensions list | grep -q 'user-theme@gnome-shell-extensions.gcampax.github.com'; then
        echo "  GNOME User Themes extension already installed, skipping."
    else
        sudo dnf install -y gnome-shell-extension-user-theme
        echo "  GNOME User Themes extension installed."
    fi
    gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
    echo "  GNOME User Themes extension enabled."
}