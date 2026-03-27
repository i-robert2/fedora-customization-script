#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Fedora Workstation Setup Script
# Customize a fresh Fedora installation — terminal, shell, keybindings & more.
#
# Usage:
#   ./setup.sh              Run all modules
#   ./setup.sh --list       List available modules
#   ./setup.sh --help       Show usage info
#   ./setup.sh mod1 mod2    Run only the specified modules
###############################################################################

# ── Module registry ───────────────────────────────────────────────────────
# Order matters: this is the execution order when running all modules.
ALL_MODULES=(ghostty font keybinding capslock tmux prompt greeting tools rofi power dock windowfx appgrid)

declare -A MODULE_DESC=(
    [ghostty]="Install Ghostty terminal"
    [font]="Install JetBrainsMono Nerd Font + configure Ghostty"
    [keybinding]="Set Ctrl+Shift+Enter shortcut for Ghostty"
    [capslock]="Fix CapsLock sticky/delayed behavior"
    [tmux]="Install and configure tmux + TPM + plugins"
    [prompt]="Customize bash prompt (alien beam)"
    [tools]="Install CLI tools (bat, btop, eza, fd, fastfetch, fzf, gnome-tweaks, htop, jq, ncdu, ripgrep, duf, tldr) + Extension Manager + User Themes"
    [rofi]="Install and configure rofi app launcher + Catppuccin theme"
    [greeting]="UFO landing animation on terminal open"
    [power]="Sleep after 3h, shutdown after 4h of inactivity"
    [dock]="Install Dash to Dock with auto-hide at bottom"
    [windowfx]="Fast zoom animations for window open/close"
    [appgrid]="Organize app grid into category folders"
)

# ── Module: ghostty ───────────────────────────────────────────────────────
mod_ghostty() {
    echo "[ghostty] Installing Ghostty terminal..."

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
}

# ── Module: font ──────────────────────────────────────────────────────────
mod_font() {
    echo "[font] Installing JetBrainsMono Nerd Font..."

    FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
    if ls "$FONT_DIR"/JetBrainsMonoNerd* &>/dev/null 2>&1; then
        echo "  JetBrainsMono Nerd Font already installed, skipping."
    else
        FONT_VERSION="3.3.0"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/JetBrainsMono.zip"
        TMP_ZIP="$(mktemp /tmp/JetBrainsMono-XXXX.zip)"
        echo "  Downloading JetBrainsMono Nerd Font v${FONT_VERSION}..."
        curl -fsSL -o "$TMP_ZIP" "$FONT_URL"
        mkdir -p "$FONT_DIR"
        unzip -qo "$TMP_ZIP" -d "$FONT_DIR"
        rm -f "$TMP_ZIP"
        fc-cache -f "$FONT_DIR"
        echo "  JetBrainsMono Nerd Font installed and font cache updated."
    fi

    # Configure Ghostty to use the Nerd Font
    GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
    GHOSTTY_CONFIG="$GHOSTTY_CONFIG_DIR/config"
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    if [ -f "$GHOSTTY_CONFIG" ] && grep -q 'font-family' "$GHOSTTY_CONFIG"; then
        echo "  Ghostty font already configured, skipping."
    else
        echo 'font-family = "JetBrainsMono Nerd Font"' >> "$GHOSTTY_CONFIG"
        echo "  Ghostty configured to use JetBrainsMono Nerd Font."
    fi

    # Add keybindings for word navigation and line selection
    # First, aggressively remove any old/broken keybind lines
    sed -i '/keybind.*ctrl+left/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*ctrl+right/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*ctrl+shift+left/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*ctrl+shift+right/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*shift+home/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/keybind.*shift+end/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/adjust_selection/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    sed -i '/# Word navigation/d; /# Word selection/d; /# Line selection/d' "$GHOSTTY_CONFIG" 2>/dev/null || true
    # Remove blank lines at end of file
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$GHOSTTY_CONFIG" 2>/dev/null || true

    cat >> "$GHOSTTY_CONFIG" <<'GHOSTTYKEYS'

# Word navigation: Ctrl+Left/Right jumps by word
keybind = ctrl+left=esc:b
keybind = ctrl+right=esc:f

# Line selection: Shift+Home/End selects to start/end of line
keybind = shift+home=adjust_selection:beginning_of_line
keybind = shift+end=adjust_selection:end_of_line
GHOSTTYKEYS
    echo "  Ghostty keybindings configured (word jump, line select)."
}

# ── Module: keybinding ────────────────────────────────────────────────────
mod_keybinding() {
    echo "[keybinding] Configuring Ctrl+Shift+Enter to open Ghostty..."

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
}

# ── Module: capslock ──────────────────────────────────────────────────────
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

# ── Module: tmux ──────────────────────────────────────────────────────────
mod_tmux() {
    echo "[tmux] Installing and configuring tmux..."

    # --- Install tmux + clipboard tools ---
    if command -v tmux &>/dev/null; then
        echo "  tmux is already installed, skipping."
    else
        sudo dnf install -y tmux
        echo "  tmux installed."
    fi

    # xclip is required for tmux-yank to copy to the system clipboard
    if command -v xclip &>/dev/null; then
        echo "  xclip is already installed, skipping."
    else
        sudo dnf install -y xclip
        echo "  xclip installed (needed for clipboard integration)."
    fi

    # --- Write tmux configuration ---
    echo "  Writing tmux configuration..."

    TMUX_CONF="$HOME/.tmux.conf"

    if [ -f "$TMUX_CONF" ]; then
        cp "$TMUX_CONF" "${TMUX_CONF}.bak.$(date +%s)"
        echo "  Existing ~/.tmux.conf backed up."
    fi

    cat > "$TMUX_CONF" <<'TMUXCONF'
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  tmux configuration                                                ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ── Prefix ────────────────────────────────────────────────────────────
# Ctrl+Space as prefix (fast: thumb on Ctrl, thumb/index on Space)
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix

# ── General ───────────────────────────────────────────────────────────
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"   # true-color support
set -g escape-time 0                        # no delay after Escape (vim)
set -g history-limit 50000                  # 50k lines scrollback
set -g focus-events on                      # pass focus events to apps
set -g set-clipboard on                     # OSC 52 clipboard

# ── Numbering ─────────────────────────────────────────────────────────
# Start windows and panes at 1 (matches keyboard layout)
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on                  # re-number when a window closes

# ── Mouse ─────────────────────────────────────────────────────────────
# Click to focus panes/windows, drag to resize, scroll wheel for history
set -g mouse on

# ── Window titles ─────────────────────────────────────────────────────
setw -g automatic-rename on                 # rename to running command
set -g set-titles on
set -g set-titles-string "#S / #W"

# ── Vim-style pane navigation ─────────────────────────────────────────
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# ── Pane resizing (Shift + vim keys, repeatable) ─────────────────────
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# ── Intuitive splits (in same directory) ──────────────────────────────
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# New window also keeps current directory
bind c new-window -c "#{pane_current_path}"

# ── Quick session switching ───────────────────────────────────────────
bind s choose-session                       # prefix + s to list sessions
bind n command-prompt -p "New session:" "new-session -s '%%'"

# ── Direct Alt+key bindings (no prefix needed) ───────────────────────
bind -n M-h select-pane -L                  # Alt+h  navigate left
bind -n M-j select-pane -D                  # Alt+j  navigate down
bind -n M-k select-pane -U                  # Alt+k  navigate up
bind -n M-l select-pane -R                  # Alt+l  navigate right
bind -n M-1 select-window -t 1              # Alt+1  window 1
bind -n M-2 select-window -t 2              # Alt+2  window 2
bind -n M-3 select-window -t 3              # Alt+3  window 3
bind -n M-4 select-window -t 4              # Alt+4  window 4
bind -n M-5 select-window -t 5              # Alt+5  window 5

# ── Vi copy mode ──────────────────────────────────────────────────────
setw -g mode-keys vi
bind -T copy-mode-vi v   send -X begin-selection
bind -T copy-mode-vi y   send -X copy-pipe-and-cancel "xclip -selection clipboard"
bind -T copy-mode-vi C-v send -X rectangle-toggle

# ── Plugins (managed by TPM) ─────────────────────────────────────────
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'    # save/restore sessions
set -g @plugin 'tmux-plugins/tmux-continuum'     # auto-save every 15 min
set -g @plugin 'tmux-plugins/tmux-yank'          # clipboard integration
set -g @plugin 'catppuccin/tmux'                 # catppuccin theme

# ── Plugin settings ───────────────────────────────────────────────────
# Catppuccin Mocha
set -g @catppuccin_flavor "mocha"

# tmux-continuum: auto-save every 15 minutes, auto-restore on tmux start
set -g @continuum-save-interval '15'
set -g @continuum-restore 'on'

# tmux-resurrect: don't capture pane contents (avoids duplicate prompt on restore)
set -g @resurrect-capture-pane-contents 'off'

# ── Initialize TPM (keep at very bottom) ──────────────────────────────
run '~/.tmux/plugins/tpm/tpm'
TMUXCONF

    echo "  ~/.tmux.conf written."

    # --- Install TPM and plugins ---
    echo "  Installing TPM and tmux plugins..."

    TPM_DIR="$HOME/.tmux/plugins/tpm"

    if [ -d "$TPM_DIR" ]; then
        echo "  TPM already installed, pulling latest..."
        git -C "$TPM_DIR" pull --quiet
    else
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
        echo "  TPM cloned."
    fi

    # Install all plugins defined in .tmux.conf headlessly
    "$TPM_DIR/bin/install_plugins"
    echo "  Plugins installed (resurrect, continuum, yank, catppuccin)."

    # --- Session automation: "dev" layout + auto-attach ---
    echo "  Setting up tmux session automation..."

    # Create a helper script that builds a "dev" session layout
    DEV_SCRIPT="$HOME/.local/bin/tmux-dev"
    mkdir -p "$HOME/.local/bin"

    cat > "$DEV_SCRIPT" <<'DEVSCRIPT'
#!/usr/bin/env bash
# tmux-dev — create or attach to a "dev" session with a standard layout.
#
# Layout:
#   Window 1 "editor"  — full-screen, for vim/code
#   Window 2 "server"  — for running a dev server
#   Window 3 "git"     — for git operations
#
# Usage:  tmux-dev [project-directory]

DIR="${1:-$(pwd)}"

SESSION="dev"

# Create the session if it doesn't exist
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session  -d -s "$SESSION" -n "editor" -c "$DIR"
    tmux new-window      -t "$SESSION" -n "server" -c "$DIR"
    tmux new-window      -t "$SESSION" -n "git"    -c "$DIR"
    tmux select-window -t "$SESSION:1"
fi

# If already inside tmux, switch to the session; otherwise attach
if [ -n "$TMUX" ]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach -t "$SESSION"
fi
DEVSCRIPT
    chmod +x "$DEV_SCRIPT"
    echo "  tmux-dev script created at ~/.local/bin/tmux-dev"

    # Auto-attach: only if a tmux session already exists, join it.
    # Otherwise, plain shell (start tmux manually with 'tmux' or 'tmux-dev').
    sed -i '/# ── tmux auto-attach/,/# ── end tmux auto-attach/d' "$HOME/.bashrc" 2>/dev/null || true
    cat >> "$HOME/.bashrc" <<'AUTOATTACH_EOF'

# ── tmux auto-attach ──────────────────────────────────────────────────
# If a tmux session is already running, attach to it. Otherwise, plain shell.
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -t 0 ]; then
    if tmux list-sessions &>/dev/null; then
        exec tmux attach
    fi
fi
# ── end tmux auto-attach ─────────────────────────────────────────────
AUTOATTACH_EOF
    echo "  Auto-attach configured (joins existing session if one is running)."
}

# ── Module: prompt ────────────────────────────────────────────────────────
mod_prompt() {
    echo "[prompt] Customizing bash prompt with alien beam effect..."

    BASHRC_BLOCK='
# ── Alien beam prompt ─────────────────────────────────────────────────
_beam_prompt() {
    local g="\033[38;5;46m" d="\033[38;5;40m" r="\033[0m"
    printf "\r\033[K${g}░▒▓${d}█${g}▓▒░${r}"
    sleep 0.06
    printf "\r\033[K"
}

PROMPT_COMMAND="_beam_prompt"
export PS1="\[\e[1;35m\]👾\u\[\e[0m\] \[\e[1;38;5;80m\]🛸\h\[\e[0m\] \[\e[1;38;5;179m\]🗂️\w\[\e[0m\]\n📢\[\e[1;38;5;46m\] \\$ \[\e[0m\]"
# ── end beam prompt ───────────────────────────────────────────────────
'

    # Always replace the prompt block to pick up changes
    sed -i '/# ── .*beam.*prompt/,/# ── end beam prompt/d' "$HOME/.bashrc" 2>/dev/null || true
    sed -i '/_beam_prompt/d; /_ufo_animate/d' "$HOME/.bashrc" 2>/dev/null || true
    sed -i '/🛸.*PS1/d; /PROMPT_COMMAND.*_ufo/d' "$HOME/.bashrc" 2>/dev/null || true
    echo "$BASHRC_BLOCK" >> "$HOME/.bashrc"
    echo "  Alien beam prompt added to ~/.bashrc"
}

# ── Module: greeting ──────────────────────────────────────────────────────
mod_greeting() {
    echo "[greeting] Installing UFO greeting animation..."

    mkdir -p "$HOME/.local/bin"
    GREETING_SCRIPT="$HOME/.local/bin/ufo-greeting"

    cat > "$GREETING_SCRIPT" <<'UFOSCRIPT'
#!/usr/bin/env bash
# Inline pixel-art UFO greeting — saucer slides across one line, then
# becomes an alien message that stays in scrollback like normal output.

COLS=$(tput cols 2>/dev/null || echo 80)
(( COLS < 40 )) && exit 0

# Colors
G='\e[38;5;46m'
DG='\e[38;5;34m'
GY='\e[38;5;250m'
NV='\e[38;5;19m'
YL='\e[38;5;226m'
W='\e[38;5;255m'
RS='\e[0m'

# Pixel-art UFO in one line using block characters
UFO="${NV}▐${DG}▄${G}████${DG}▄${NV}▌${GY}▟${YL}◆${GY}██████${YL}◆${GY}▙${RS}"
UFO_W=15

MID=$(( (COLS - UFO_W) / 2 ))
(( MID < 0 )) && MID=0

STEPS=10
STEP=$(( MID / STEPS ))
(( STEP < 1 )) && STEP=1

tput civis 2>/dev/null

# Slide UFO from left to center (~0.1 s)
for (( p=0; p<=MID; p+=STEP )); do
    printf '\r\e[2K%*s%b' "$p" "" "$UFO"
    sleep 0.01
done
printf '\r\e[2K%*s%b' "$MID" "" "$UFO"
sleep 0.02

# Replace with centered alien message (stays in scrollback)
MSG="👽 howdy there!"
MSG_W=15
MSG_PAD=$(( (COLS - MSG_W) / 2 ))
(( MSG_PAD < 0 )) && MSG_PAD=0
printf '\r\e[2K'
tput cnorm 2>/dev/null
printf '%*s%b\n' "$MSG_PAD" "" "${G}${MSG}${RS}"
UFOSCRIPT
    chmod +x "$GREETING_SCRIPT"
    echo "  ufo-greeting script created at ~/.local/bin/ufo-greeting"

    # Remove old greeting block from .bashrc
    sed -i '/# ── UFO greeting/,/# ── end UFO greeting/d' "$HOME/.bashrc" 2>/dev/null || true

    # Append new block — simple: play on every new interactive shell
    cat >> "$HOME/.bashrc" <<'GREETING_EOF'

# ── UFO greeting ──────────────────────────────────────────────────────
if [ -t 0 ] && command -v ufo-greeting &>/dev/null; then
    ufo-greeting
fi
# ── end UFO greeting ──────────────────────────────────────────────────
GREETING_EOF
    echo "  UFO greeting added to ~/.bashrc."
}

# ── Module: tools ─────────────────────────────────────────────────────────
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

# ── Module: rofi ──────────────────────────────────────────────────────────
mod_rofi() {
    echo "[rofi] Installing and configuring rofi app launcher..."

    # --- Install rofi ---
    if command -v rofi &>/dev/null; then
        echo "  rofi is already installed, skipping."
    else
        sudo dnf install -y rofi
        echo "  rofi installed."
    fi

    # --- Install Catppuccin Mocha theme ---
    ROFI_THEME_DIR="$HOME/.local/share/rofi/themes"
    ROFI_THEME="$ROFI_THEME_DIR/catppuccin-mocha.rasi"
    ROFI_DEFAULT="$ROFI_THEME_DIR/catppuccin-default.rasi"

    mkdir -p "$ROFI_THEME_DIR"

    if [ -f "$ROFI_THEME" ]; then
        echo "  Catppuccin Mocha palette already installed, skipping."
    else
        curl -fsSL -o "$ROFI_THEME" \
            "https://raw.githubusercontent.com/catppuccin/rofi/main/themes/catppuccin-mocha.rasi"
        echo "  Catppuccin Mocha palette downloaded."
    fi

    if [ -f "$ROFI_DEFAULT" ]; then
        echo "  Catppuccin default theme already installed, skipping."
    else
        curl -fsSL -o "$ROFI_DEFAULT" \
            "https://raw.githubusercontent.com/catppuccin/rofi/main/catppuccin-default.rasi"
        echo "  Catppuccin default theme downloaded."
    fi

    # --- Write rofi config ---
    ROFI_CONFIG_DIR="$HOME/.config/rofi"
    ROFI_CONFIG="$ROFI_CONFIG_DIR/config.rasi"
    mkdir -p "$ROFI_CONFIG_DIR"

    cat > "$ROFI_CONFIG" <<'ROFICONF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    terminal: "ghostty";
    drun-display-format: "{icon} {name}";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    font: "JetBrainsMono Nerd Font 12";
    case-sensitive: false;
}

@theme "catppuccin-default"
ROFICONF
    echo "  ~/.config/rofi/config.rasi written."

    # --- Set Super+D keybinding to launch rofi ---
    CUSTOM_KB_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
    CUSTOM_KB_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    SLOT="custom-rofi"
    SLOT_PATH="${CUSTOM_KB_BASE}/${SLOT}/"

    EXISTING=$(gsettings get "$CUSTOM_KB_SCHEMA" custom-keybindings)

    if [[ "$EXISTING" == *"${SLOT}"* ]]; then
        echo "  Keybinding slot already exists, updating..."
    else
        if [[ "$EXISTING" == "@as []" ]]; then
            NEW_LIST="['${SLOT_PATH}']"
        else
            NEW_LIST="${EXISTING%]*}, '${SLOT_PATH}']"
        fi
        gsettings set "$CUSTOM_KB_SCHEMA" custom-keybindings "$NEW_LIST"
    fi

    BINDING_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH}"
    gsettings set "$BINDING_SCHEMA" name "Rofi App Launcher"
    gsettings set "$BINDING_SCHEMA" command "rofi -show drun"
    gsettings set "$BINDING_SCHEMA" binding "<Super>d"

    echo "  Super+D -> rofi -show drun configured."
}

# ── Module: power ─────────────────────────────────────────────────────────
mod_power() {
    echo "[power] Configuring sleep after 3 hours, shutdown after 4 hours of inactivity..."

    # --- Disable screen blanking only inside a VM (prevents screen going black after 5 min) ---
    if systemd-detect-virt --quiet 2>/dev/null; then
        gsettings set org.gnome.desktop.session idle-delay 0
        echo "  VM detected — screen blanking disabled (idle-delay set to 0)."
    else
        echo "  Bare metal — keeping default screen blanking (saves battery)."
    fi

    # --- Sleep after 3 hours (10800 seconds) on AC and battery ---
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 10800
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 10800
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
    echo "  Sleep after 3 hours of inactivity configured (AC + battery)."

    # --- Shutdown after 4 hours of inactivity via systemd timer ---
    # systemd-logind IdleAction isn't available on all Fedora configs,
    # so we use a small systemd timer + service that checks idle time.
    SHUTDOWN_SERVICE="/etc/systemd/system/auto-shutdown-idle.service"
    SHUTDOWN_TIMER="/etc/systemd/system/auto-shutdown-idle.timer"
    SHUTDOWN_SCRIPT="/usr/local/bin/auto-shutdown-idle"

    # Script: checks if system has been idle ≥ 4 hours before shutting down
    sudo tee "$SHUTDOWN_SCRIPT" > /dev/null <<'IDLESH'
#!/usr/bin/env bash
# Shut down if all user sessions have been idle for ≥ 4 hours (14400 seconds).

IDLE_THRESHOLD=14400

# Get the minimum idle hint duration across all sessions
MIN_IDLE=$IDLE_THRESHOLD
while IFS= read -r session; do
    idle_since=$(loginctl show-session "$session" -p IdleSinceHint --value 2>/dev/null)
    if [[ -z "$idle_since" || "$idle_since" == "0" ]]; then
        # Session is active (not idle)
        exit 0
    fi
    idle_us=$idle_since
    now_us=$(date +%s%6N)
    elapsed_s=$(( (now_us - idle_us) / 1000000 ))
    (( elapsed_s < MIN_IDLE )) && MIN_IDLE=$elapsed_s
done < <(loginctl list-sessions --no-legend | awk '{print $1}')

if (( MIN_IDLE >= IDLE_THRESHOLD )); then
    systemctl poweroff
fi
IDLESH
    sudo chmod +x "$SHUTDOWN_SCRIPT"
    echo "  auto-shutdown-idle script created."

    # Service unit
    sudo tee "$SHUTDOWN_SERVICE" > /dev/null <<'SVCEOF'
[Unit]
Description=Auto shutdown after 4 hours of inactivity

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-shutdown-idle
SVCEOF

    # Timer: check every 15 minutes
    sudo tee "$SHUTDOWN_TIMER" > /dev/null <<'TMREOF'
[Unit]
Description=Check idle time for auto shutdown

[Timer]
OnBootSec=1h
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
TMREOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now auto-shutdown-idle.timer
    echo "  auto-shutdown-idle timer enabled (checks every 15 min, shuts down after 4h idle)."
}

# ── Module: dock ──────────────────────────────────────────────────────────
mod_dock() {
    echo "[dock] Installing and configuring Dash to Dock..."

    local EXT_ID="dash-to-dock@micxgx.gmail.com"
    local DCONF_PATH="/org/gnome/shell/extensions/dash-to-dock"

    # --- Install from Fedora repos ---
    if gnome-extensions list 2>/dev/null | grep -q "$EXT_ID"; then
        echo "  Dash to Dock already installed, skipping."
    else
        sudo dnf install -y gnome-shell-extension-dash-to-dock
        echo "  Dash to Dock installed."
    fi

    # --- Enable the extension ---
    gnome-extensions enable "$EXT_ID" 2>/dev/null || true
    echo "  Dash to Dock enabled."

    # --- Configure: bottom dock, auto-hide ---
    dconf write "$DCONF_PATH/dock-position" "'BOTTOM'"
    dconf write "$DCONF_PATH/dock-fixed" "false"
    dconf write "$DCONF_PATH/autohide" "true"
    dconf write "$DCONF_PATH/autohide-in-fullscreen" "false"
    dconf write "$DCONF_PATH/dash-max-icon-size" "40"
    dconf write "$DCONF_PATH/show-trash" "false"
    dconf write "$DCONF_PATH/show-mounts" "false"

    # In a VM the cursor escapes the screen edge, so cursor-pressure autohide
    # doesn't work. Use intellihide (window-aware) in VMs instead.
    if systemd-detect-virt --quiet 2>/dev/null; then
        dconf write "$DCONF_PATH/intellihide" "true"
        echo "  VM detected — using intellihide (shows when no window covers dock)."
    else
        dconf write "$DCONF_PATH/intellihide" "false"
        echo "  Bare metal — using cursor-pressure autohide."
    fi

    echo "  Dock configured: bottom, auto-hide."
}

# ── Module: windowfx ──────────────────────────────────────────────────────
mod_windowfx() {
    echo "[windowfx] Configuring fast zoom animations for window open/close..."

    local EXT_ID="burn-my-windows@schneegans.github.com"

    # Ensure animations are enabled
    gsettings set org.gnome.desktop.interface enable-animations true

    # --- Install Burn My Windows from GitHub ---
    if gnome-extensions list 2>/dev/null | grep -q "$EXT_ID"; then
        echo "  Burn My Windows already installed, skipping."
    else
        local BMW_ZIP
        BMW_ZIP="$(mktemp /tmp/burn-my-windows-XXXX.zip)"
        curl -fsSL -o "$BMW_ZIP" \
            "https://github.com/Schneegans/Burn-My-Windows/releases/latest/download/burn-my-windows@schneegans.github.com.zip"
        gnome-extensions install --force "$BMW_ZIP"
        rm -f "$BMW_ZIP"
        echo "  Burn My Windows installed from GitHub."
    fi

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
apparition-enable-effect=true
apparition-animation-time=150
apparition-randomness=0.0
apparition-shake-intensity=0.0
broken-glass-enable-effect=false
doom-enable-effect=false
energize-a-enable-effect=false
energize-b-enable-effect=false
fire-enable-effect=false
glide-enable-effect=false
glitch-enable-effect=false
hexagon-enable-effect=false
incinerate-enable-effect=false
matrix-enable-effect=false
paint-brush-enable-effect=false
pixelate-enable-effect=false
pixel-wheel-enable-effect=false
pixel-wipe-enable-effect=false
portal-enable-effect=false
snap-enable-effect=false
trex-enable-effect=false
tv-enable-effect=false
tv-glitch-enable-effect=false
wisps-enable-effect=false
BMWPROFILE

    # Point extension to the zoom profile
    dconf write /org/gnome/shell/extensions/burn-my-windows/active-profile \
        "'$PROFILE_DIR/zoom.conf'"

    echo "  Fast zoom animations configured (150ms)."
    echo "  NOTE: Log out & back in to activate."
}

# ── Module: appgrid ───────────────────────────────────────────────────────
mod_appgrid() {
    echo "[appgrid] Organizing app grid into category folders..."

    FOLDER_SCHEMA="org.gnome.desktop.app-folders"
    FOLDER_CHILD="org.gnome.desktop.app-folders.folder"
    FOLDER_PATH="/org/gnome/desktop/app-folders/folders"

    # Enable app folders
    # Order matters: an app goes into the first folder that matches.
    # Explicit 'apps' entries always win over 'categories' matching.
    gsettings set "$FOLDER_SCHEMA" folder-children \
        "['Dev', 'Office', 'Media', 'System', 'Accessories']"

    # ── Dev ────────────────────────────────────────────────────────────
    # Explicit list only — terminals and dev tools have System category,
    # so we pin them here before the System folder can grab them.
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Dev/" name 'Dev'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Dev/" apps \
        "['com.visualstudio.code.desktop', \
          'code.desktop', \
          'com.ghostty.ghostty.desktop', \
          'com.mitchellh.ghostty.desktop', \
          'ghostty.desktop', \
          'org.gnome.Terminal.desktop', \
          'htop.desktop', \
          'btop.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Dev/" categories \
        "['Development', 'IDE']"
    echo "  Dev folder created."

    # ── Office ─────────────────────────────────────────────────────────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Office/" name 'Office'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Office/" apps \
        "['org.libreoffice.LibreOffice.writer.desktop', \
          'org.libreoffice.LibreOffice.calc.desktop', \
          'org.libreoffice.LibreOffice.impress.desktop', \
          'libreoffice-writer.desktop', \
          'libreoffice-calc.desktop', \
          'libreoffice-impress.desktop', \
          'org.gnome.Contacts.desktop', \
          'org.gnome.Maps.desktop', \
          'org.gnome.Weather.desktop', \
          'org.gnome.Calendar.desktop', \
          'org.gnome.Clocks.desktop', \
          'org.gnome.clocks.desktop', \
          'org.gnome.Evince.desktop', \
          'evince.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Office/" categories \
        "['Office', 'Calendar', 'ContactManagement']"
    echo "  Office folder created."

    # ── Media ──────────────────────────────────────────────────────────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" name 'Media'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" apps \
        "['org.gnome.Totem.desktop', \
          'totem.desktop', \
          'org.gnome.Videos.desktop', \
          'org.gnome.Snapshot.desktop', \
          'org.gnome.Cheese.desktop', \
          'org.fedoraproject.MediaWriter.desktop', \
          'org.gnome.Characters.desktop', \
          'org.gnome.Music.desktop', \
          'org.gnome.Rhythmbox3.desktop', \
          'rhythmbox.desktop', \
          'org.gnome.Loupe.desktop', \
          'org.gnome.eog.desktop', \
          'eog.desktop', \
          'simple-scan.desktop', \
          'org.gnome.SimpleScan.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" categories \
        "['Audio', 'Video', 'AudioVideo', 'Graphics', 'Photography', 'Scanning']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Media/" excluded-apps \
        "['org.gnome.Font-viewer.desktop', \
          'org.gnome.font-viewer.desktop']"
    echo "  Media folder created."

    # ── System ─────────────────────────────────────────────────────────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" name 'System'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" apps \
        "['org.gnome.Settings.desktop', \
          'gnome-system-monitor.desktop', \
          'org.gnome.SystemMonitor.desktop', \
          'org.gnome.DiskUtility.desktop', \
          'org.gnome.Boxes.desktop', \
          'org.gnome.Connections.desktop', \
          'org.gnome.Logs.desktop', \
          'org.gnome.Tour.desktop', \
          'yelp.desktop', \
          'org.gnome.Yelp.desktop', \
          'org.gnome.tweaks.desktop', \
          'com.mattjakeman.ExtensionManager.desktop', \
          'org.gnome.baobab.desktop', \
          'org.freedesktop.MalcontentControl.desktop', \
          'malcontent-control.desktop', \
          'gnome-abrt.desktop', \
          'abrt-applet.desktop', \
          'org.gnome.Font-viewer.desktop', \
          'org.gnome.font-viewer.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" categories \
        "['System', 'Security', 'Monitor', 'Settings', 'HardwareSettings', \
          'PackageManager', 'Network', 'Documentation', 'TerminalEmulator']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/System/" excluded-apps \
        "['com.visualstudio.code.desktop', \
          'code.desktop', \
          'com.ghostty.ghostty.desktop', \
          'com.mitchellh.ghostty.desktop', \
          'ghostty.desktop', \
          'org.gnome.Terminal.desktop', \
          'htop.desktop', \
          'btop.desktop', \
          'org.gnome.Nautilus.desktop']"
    echo "  System folder created."

    # ── Accessories (catch-all — broad Utility category goes last) ────
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Accessories/" name 'Accessories'
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Accessories/" apps \
        "['org.gnome.TextEditor.desktop', \
          'org.gnome.Calculator.desktop', \
          'org.gnome.FileRoller.desktop', \
          'org.gnome.Nautilus.desktop', \
          'rofi.desktop', \
          'rofi-theme-selector.desktop']"
    gsettings set "$FOLDER_CHILD:$FOLDER_PATH/Accessories/" categories \
        "['Utility', 'TextEditor', 'Archiving', 'Calculator', 'Compression', \
          'FileManager', 'FileTools', 'Core', 'Clock', 'GNOME']"
    echo "  Accessories folder created."

    # Reset the cached grid layout so GNOME rebuilds it from the new folders.
    # Without this, the old two-page layout persists even after folder changes.
    gsettings reset org.gnome.shell app-picker-layout

    echo "  App grid organized into folders (layout reset — may need Alt+F2 → r or re-login)."
}

# ── Helper functions ──────────────────────────────────────────────────────
show_help() {
    cat <<'HELP'
Fedora Workstation Setup Script

Usage:
  ./setup.sh                Run all modules (in order)
  ./setup.sh <mod> [mod…]   Run only the specified modules
  ./setup.sh --list         List available modules
  ./setup.sh --help         Show this help message

Examples:
  ./setup.sh capslock tmux   Fix CapsLock + install/configure tmux
  ./setup.sh prompt          Just customize the bash prompt
HELP
}

show_list() {
    echo "Available modules:"
    for mod in "${ALL_MODULES[@]}"; do
        printf "  %-12s %s\n" "$mod" "${MODULE_DESC[$mod]}"
    done
}

run_module() {
    local mod="$1"
    if [[ -z "${MODULE_DESC[$mod]+x}" ]]; then
        echo "Error: unknown module '$mod'." >&2
        echo "Run './setup.sh --list' to see available modules." >&2
        exit 1
    fi
    "mod_$mod"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────
main() {
    echo "=== Fedora Workstation Setup ==="
    echo ""

    if [[ $# -eq 0 ]]; then
        # No arguments: run everything
        for mod in "${ALL_MODULES[@]}"; do
            run_module "$mod"
        done
    else
        case "$1" in
            --help|-h)
                show_help
                return 0
                ;;
            --list|-l)
                show_list
                return 0
                ;;
            --*)
                echo "Error: unknown option '$1'." >&2
                show_help >&2
                return 1
                ;;
            *)
                # Run only the requested modules
                for mod in "$@"; do
                    run_module "$mod"
                done
                ;;
        esac
    fi

    echo "=== Setup complete! ==="

    # Only show quick-start tips when running all modules
    if [[ $# -eq 0 ]]; then
        echo ""
        echo "Quick start:"
        echo "  1. Log out & back in (for keyboard shortcut + dconf)"
        echo "  2. Open Ghostty with Ctrl+Shift+Enter"
        echo "  3. tmux starts automatically — you're in a session"
        echo "  4. Run 'tmux-dev ~/myproject' for a dev layout"
        echo ""
        echo "tmux cheatsheet (prefix = Ctrl+Space):"
        echo "  Ctrl+Space |    split vertical    Ctrl+Space -    split horizontal"
        echo "  Ctrl+Space h/j/k/l  navigate      Ctrl+Space H/J/K/L  resize"
        echo "  Ctrl+Space c    new window         Ctrl+Space s    switch session"
        echo "  Ctrl+Space d    detach             Ctrl+Space n    new session"
        echo ""
        echo "Direct shortcuts (no prefix):"
        echo "  Alt+h/j/k/l    navigate panes     Alt+1-5    switch window"
    fi
}

main "$@"
