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
ALL_MODULES=(ghostty font keybinding capslock tmux prompt greeting tools rofi dock)

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
    tmux attach 2>/dev/null || tmux new-session -s main
fi
# ── end tmux auto-attach ─────────────────────────────────────────────
'

    if grep -qF 'tmux auto-attach' "$HOME/.bashrc" 2>/dev/null; then
        echo "  Auto-attach already configured, skipping."
    else
        echo "$AUTOATTACH_BLOCK" >> "$HOME/.bashrc"
        echo "  Auto-attach added to ~/.bashrc (attaches to last session or creates 'main')."
    fi
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
# Pixel-art UFO greeting — colored block characters for a retro pixel look.
# A saucer flies in, beams down an alien who says howdy.
# Skips if not interactive, inside tmux, or terminal too small.

[[ ! -t 1 ]] && exit 0
[[ -n "$TMUX" ]] && exit 0

COLS=$(tput cols 2>/dev/null || echo 80)
ROWS=$(tput lines 2>/dev/null || echo 24)
[[ $COLS -lt 60 || $ROWS -lt 22 ]] && exit 0

# ── Color palette (256-color) ─────────────────────────────────────────
# Index: 0=transparent  1=dk_green  2=bright_green  3=white  4=purple
#        5=orange       6=lt_grey   7=dk_grey       8=navy   9=yellow
PAL=(0 22 46 255 141 208 249 240 17 226)

# ── Sprite data ───────────────────────────────────────────────────────
# Each character = one pixel rendered as "██".  '0' = transparent (2 spaces).

UFO=(
    "000002220000000"
    "000022322200000"
    "000122222400000"
    "001222222450000"
    "086666666666800"
    "869666666696800"
    "086666666668000"
    "008877777880000"
    "000008888000000"
)
UFO_W=15
UFO_H=9

ALIEN=(
    "000222000"
    "002222200"
    "022323220"
    "022222220"
    "002222200"
    "000222000"
    "002222200"
    "002020200"
    "000202000"
    "002200220"
)
ALIEN_W=9
ALIEN_H=10

# ── Rendering ─────────────────────────────────────────────────────────
draw_sprite() {
    local -n _spr=$1
    local br=$2 bc=$3 r=0
    for row_data in "${_spr[@]}"; do
        local line=""
        for (( i=0; i<${#row_data}; i++ )); do
            local px=${row_data:$i:1}
            if [[ $px == "0" ]]; then
                line+="  "
            else
                line+="\e[38;5;${PAL[$px]}m██"
            fi
        done
        line+="\e[0m"
        tput cup $((br + r)) $bc
        printf '%b' "$line"
        ((r++))
    done
}

clear_rows() {
    local row=$1 count=$2
    for (( r=0; r<count; r++ )); do
        tput cup $((row + r)) 0
        printf "%${COLS}s" ""
    done
}

# ── Animation ─────────────────────────────────────────────────────────
MID=$(( (COLS - UFO_W * 2) / 2 ))
[[ $MID -lt 0 ]] && MID=0
UFO_ROW=2

tput civis
tput clear

# Phase 1: UFO slides from left to center
for (( col=0; col<=MID; col+=2 )); do
    clear_rows $UFO_ROW $UFO_H
    draw_sprite UFO $UFO_ROW $col
    sleep 0.015
done
draw_sprite UFO $UFO_ROW $MID
sleep 0.3

# Phase 2: Tractor beam extends down
BEAM_COL=$(( MID + UFO_W - 3 ))
BEAM_TOP=$((UFO_ROW + UFO_H))
BEAM_LEN=6
BEAM_BOT=$((BEAM_TOP + BEAM_LEN - 1))

for (( row=BEAM_TOP; row<=BEAM_BOT; row++ )); do
    tput cup $row $BEAM_COL
    printf '%b' "\e[38;5;226m░░▓▓░░\e[0m"
    sleep 0.04
done
sleep 0.2

# Phase 3: Alien descends through beam
ALIEN_COL=$(( MID + (UFO_W - ALIEN_W) ))
ALIEN_LAND=$((BEAM_BOT + 1))

for (( arow=BEAM_TOP; arow<=ALIEN_LAND; arow++ )); do
    if [[ $arow -gt $BEAM_TOP ]]; then
        for (( r=0; r<ALIEN_H; r++ )); do
            cr=$((arow - 1 + r))
            tput cup $cr $ALIEN_COL
            printf "%$((ALIEN_W * 2))s" ""
            if [[ $cr -ge $BEAM_TOP && $cr -le $BEAM_BOT ]]; then
                tput cup $cr $BEAM_COL
                printf '%b' "\e[38;5;226m░░▓▓░░\e[0m"
            fi
        done
    fi
    draw_sprite ALIEN $arow $ALIEN_COL
    sleep 0.05
done
sleep 0.3

# Phase 4: Beam fades
for (( row=BEAM_TOP; row<=BEAM_BOT; row++ )); do
    tput cup $row $BEAM_COL
    printf "      "
done

# Phase 5: Speech bubble
B_ROW=$((ALIEN_LAND + 2))
B_COL=$((ALIEN_COL + ALIEN_W * 2 + 2))
(( B_COL + 24 > COLS )) && B_COL=$((ALIEN_COL - 24))

W=$'\e[38;5;255m'
G=$'\e[38;5;46m'
RS=$'\e[0m'

tput cup $B_ROW         $B_COL; printf '%s' "${W}╭───────────────────╮${RS}"
tput cup $((B_ROW + 1)) $B_COL; printf '%s' "${W}│ ${G}howdy there! 👋${W}  │${RS}"
tput cup $((B_ROW + 2)) $B_COL; printf '%s' "${W}╰───────────────────╯${RS}"
tput cup $((B_ROW + 3)) $B_COL; printf '%s' "${W}╱${RS}"

sleep 1.8

tput clear
tput cnorm
UFOSCRIPT
    chmod +x "$GREETING_SCRIPT"
    echo "  ufo-greeting script created at ~/.local/bin/ufo-greeting"

    # Add to .bashrc — runs before tmux auto-attach, only outside tmux
    GREETING_BLOCK='
# ── UFO greeting ──────────────────────────────────────────────────────
if [ -z "$TMUX" ] && [ -t 0 ] && command -v ufo-greeting &>/dev/null; then
    ufo-greeting
fi
# ── end UFO greeting ──────────────────────────────────────────────────
'

    # Remove old block if present, then add fresh
    sed -i '/# ── UFO greeting/,/# ── end UFO greeting/d' "$HOME/.bashrc" 2>/dev/null || true

    # Insert before tmux auto-attach so animation plays first
    if grep -qF 'tmux auto-attach' "$HOME/.bashrc"; then
        sed -i "/# ── tmux auto-attach/i\\$GREETING_BLOCK" "$HOME/.bashrc"
    else
        echo "$GREETING_BLOCK" >> "$HOME/.bashrc"
    fi
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

    if [ -f "$ROFI_THEME" ]; then
        echo "  Catppuccin Mocha theme already installed, skipping."
    else
        mkdir -p "$ROFI_THEME_DIR"
        curl -fsSL -o "$ROFI_THEME" \
            "https://raw.githubusercontent.com/catppuccin/rofi/main/basic/.local/share/rofi/themes/catppuccin-mocha.rasi"
        echo "  Catppuccin Mocha theme downloaded."
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

@theme "catppuccin-mocha"
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

    # --- Enable the extension ---
    EXT_UUID="dash-to-dock@micxgx.gmail.com"
    if gnome-extensions list --enabled 2>/dev/null | grep -qF "$EXT_UUID"; then
        echo "  Extension already enabled."
    else
        gnome-extensions enable "$EXT_UUID" 2>/dev/null || true
        echo "  Extension enabled (may require a session restart to take effect)."
    fi

    # --- Configure via dconf/gsettings ---
    DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"

    # Position at the bottom of the screen
    gsettings set "$DOCK_SCHEMA" dock-position 'BOTTOM'

    # Auto-hide: dock slides away when a window overlaps it
    gsettings set "$DOCK_SCHEMA" dock-fixed false
    gsettings set "$DOCK_SCHEMA" autohide true
    gsettings set "$DOCK_SCHEMA" intellihide true
    gsettings set "$DOCK_SCHEMA" intellihide-mode 'ALL_WINDOWS'

    # Show the dock when the mouse hits the bottom edge
    gsettings set "$DOCK_SCHEMA" autohide-in-fullscreen false

    # Animation speed (ms) — snappy reveal/hide
    gsettings set "$DOCK_SCHEMA" animation-time 0.2
    gsettings set "$DOCK_SCHEMA" hide-delay 0.2
    gsettings set "$DOCK_SCHEMA" show-delay 0.0

    # Icon size (48 px default, adjust to taste)
    gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48

    # Extend the dock across the full bottom edge
    gsettings set "$DOCK_SCHEMA" extend-height false

    echo "  Dock configured: auto-hiding bottom dock, reveals on mouse hover."
    echo "  NOTE: Log out and back in (or press Alt+F2 → r → Enter) to activate."
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
