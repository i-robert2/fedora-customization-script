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