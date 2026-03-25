#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Fedora Workstation Setup Script
# Run on a fresh Fedora installation to customize the desktop environment.
#
# Usage:
#   ./setup.sh              Run all modules
#   ./setup.sh --list       List available modules
#   ./setup.sh --help       Show usage info
#   ./setup.sh mod1 mod2    Run only the specified modules
###############################################################################

# ── Module registry ───────────────────────────────────────────────────────
# Order matters: this is the execution order when running all modules.
ALL_MODULES=(ghostty font keybinding capslock tmux prompt greeting tools rofi dock power)

declare -A MODULE_DESC=(
    [ghostty]="Install Ghostty terminal"
    [font]="Install JetBrainsMono Nerd Font + configure Ghostty"
    [keybinding]="Set Ctrl+Shift+Enter shortcut for Ghostty"
    [capslock]="Fix CapsLock sticky/delayed behavior"
    [tmux]="Install and configure tmux + TPM + plugins"
    [prompt]="Customize bash prompt (alien beam)"
    [tools]="Install CLI tools (bat, eza, fd, fzf, htop, jq, ncdu, ripgrep, duf, tldr)"
    [rofi]="Install and configure rofi app launcher + Catppuccin theme"
    [dock]="Auto-hiding bottom dock (Dash to Dock extension)"
    [greeting]="UFO landing animation on terminal open"
    [power]="Sleep after 3h, shutdown after 4h of inactivity"
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

    # Auto-attach: when Ghostty opens bash, attach to the last tmux session
    # (or create a default one). Only runs in interactive non-tmux shells.
    AUTOATTACH_BLOCK='
# ── tmux auto-attach ──────────────────────────────────────────────────
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -t 0 ]; then
    # Each Ghostty window gets its own tmux session (main, main-1, main-2, …)
    _n=0
    _sess="main"
    while tmux has-session -t "$_sess" 2>/dev/null; do
        # Session exists — check if another client is already attached
        _attached=$(tmux list-clients -t "$_sess" 2>/dev/null | wc -l)
        if [ "$_attached" -eq 0 ]; then
            break  # unattached session found, reuse it
        fi
        _n=$((_n + 1))
        _sess="main-$_n"
    done
    tmux new-session -A -s "$_sess"
    _TMUX_RETURNED=1
    unset _n _sess _attached
fi
# ── end tmux auto-attach ─────────────────────────────────────────────
'

    # Always update the auto-attach block to pick up changes
    sed -i '/# ── tmux auto-attach/,/# ── end tmux auto-attach/d' "$HOME/.bashrc" 2>/dev/null || true
    echo "$AUTOATTACH_BLOCK" >> "$HOME/.bashrc"
    echo "  Auto-attach configured (tmux new-session -A -s main)."
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

STEPS=15
STEP=$(( MID / STEPS ))
(( STEP < 1 )) && STEP=1

tput civis 2>/dev/null

# Slide UFO from left to center (~1.2 s)
for (( p=0; p<=MID; p+=STEP )); do
    printf '\r\e[2K%*s%b' "$p" "" "$UFO"
    sleep 0.08
done
printf '\r\e[2K%*s%b' "$MID" "" "$UFO"
sleep 0.15

# Replace with alien message (stays in scrollback)
printf '\r\e[2K'
tput cnorm 2>/dev/null
printf ' %b\n' "${G}👾${W} howdy there!${RS}"
UFOSCRIPT
    chmod +x "$GREETING_SCRIPT"
    echo "  ufo-greeting script created at ~/.local/bin/ufo-greeting"

    # Remove old greeting block from .bashrc
    sed -i '/# ── UFO greeting/,/# ── end UFO greeting/d' "$HOME/.bashrc" 2>/dev/null || true

    # Append new block — runs OUTSIDE tmux, only on fresh terminal open
    cat >> "$HOME/.bashrc" <<'GREETING_EOF'

# ── UFO greeting ──────────────────────────────────────────────────────
if [ -z "$TMUX" ] && [ -z "$_TMUX_RETURNED" ] && [ -t 0 ] && command -v ufo-greeting &>/dev/null; then
    ufo-greeting
fi
# ── end UFO greeting ──────────────────────────────────────────────────
GREETING_EOF
    echo "  UFO greeting added to ~/.bashrc (runs before tmux auto-attach)."
}

# ── Module: tools ─────────────────────────────────────────────────────────
mod_tools() {
    echo "[tools] Installing CLI tools..."

    local -A TOOLS=(
        [bat]="bat"           # cat with syntax highlighting
        [eza]="eza"           # modern ls replacement (--tree, icons, git)
        [fd]="fd-find"        # fast find alternative
        [fzf]="fzf"           # fuzzy finder
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

# ── Module: dock ──────────────────────────────────────────────────────────
mod_dock() {
    echo "[dock] Configuring auto-hiding bottom dock (Dash to Dock)..."

    # --- Install Dash to Dock GNOME extension ---
    if dnf list installed gnome-shell-extension-dash-to-dock &>/dev/null 2>&1; then
        echo "  Dash to Dock extension already installed, skipping."
    else
        sudo dnf install -y gnome-shell-extension-dash-to-dock
        echo "  Dash to Dock extension installed."
    fi

    # --- Enable the extension via dconf (reliable, doesn't need Shell running) ---
    EXT_UUID="dash-to-dock@micxgx.gmail.com"
    gnome-extensions enable "$EXT_UUID" 2>/dev/null || true

    # Also enable directly in dconf to ensure it persists
    CURRENT_EXTS=$(dconf read /org/gnome/shell/enabled-extensions 2>/dev/null)
    if [[ -z "$CURRENT_EXTS" || "$CURRENT_EXTS" == "@as []" ]]; then
        dconf write /org/gnome/shell/enabled-extensions "['$EXT_UUID']"
    elif [[ "$CURRENT_EXTS" != *"$EXT_UUID"* ]]; then
        NEW_EXTS="${CURRENT_EXTS%]*}, '$EXT_UUID']"
        dconf write /org/gnome/shell/enabled-extensions "$NEW_EXTS"
    fi
    # Disable the GNOME "extension-disable" override so user extensions load
    dconf write /org/gnome/shell/disable-user-extensions "false"
    echo "  Extension enabled (via dconf)."

    # --- Configure via dconf (works even before GNOME loads the schema) ---
    DCONF_PATH="/org/gnome/shell/extensions/dash-to-dock"

    # Position at the bottom of the screen
    dconf write "$DCONF_PATH/dock-position" "'BOTTOM'"

    # Auto-hide: dock slides away when not in use
    dconf write "$DCONF_PATH/dock-fixed" "false"
    dconf write "$DCONF_PATH/autohide" "true"
    dconf write "$DCONF_PATH/intellihide" "true"
    dconf write "$DCONF_PATH/intellihide-mode" "'ALL_WINDOWS'"

    # Don't show in fullscreen
    dconf write "$DCONF_PATH/autohide-in-fullscreen" "false"

    # Animation speed — snappy reveal/hide
    dconf write "$DCONF_PATH/animation-time" "0.2"
    dconf write "$DCONF_PATH/hide-delay" "0.2"
    dconf write "$DCONF_PATH/show-delay" "0.0"

    # Icon size (48 px)
    dconf write "$DCONF_PATH/dash-max-icon-size" "48"

    # Don't extend dock across full width
    dconf write "$DCONF_PATH/extend-height" "false"

    echo "  Dock configured: auto-hiding bottom dock, reveals on mouse hover."

    # --- Restart GNOME Shell to pick up the extension + settings ---
    if [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
        echo "  Restarting GNOME Shell (X11)..."
        busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting…")' 2>/dev/null || true
    else
        echo "  NOTE: On Wayland, log out and back in for the dock to appear."
    fi
}

# ── Module: power ─────────────────────────────────────────────────────────
mod_power() {
    echo "[power] Configuring sleep after 3 hours, shutdown after 4 hours of inactivity..."

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
}

main "$@"
