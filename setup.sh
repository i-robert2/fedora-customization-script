#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Fedora Workstation Setup Script
# Run on a fresh Fedora installation to customize the desktop environment.
###############################################################################

echo "=== Fedora Workstation Setup ==="
echo ""

# ---------------------------------------------------------------------------
# 1. Install Ghostty Terminal
# ---------------------------------------------------------------------------
echo "[1/8] Installing Ghostty terminal..."

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

# ---------------------------------------------------------------------------
# 2. Install JetBrainsMono Nerd Font (needed for Powerline arrows)
# ---------------------------------------------------------------------------
echo "[2/9] Installing JetBrainsMono Nerd Font..."

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

# ---------------------------------------------------------------------------
# 3. Set Ctrl+Shift+Enter keyboard shortcut to open Ghostty
# ---------------------------------------------------------------------------
echo "[3/9] Configuring Ctrl+Shift+Enter to open Ghostty..."

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

# ---------------------------------------------------------------------------
# 4. Fix CapsLock sticky / delayed toggle-off behavior (system-wide)
# ---------------------------------------------------------------------------
echo "[4/9] Fixing CapsLock sticky behavior (user session + GDM login)..."

# --- 3a. Current user session (gsettings / dconf) ---
gsettings set org.gnome.desktop.a11y.keyboard slowkeys-enable false
gsettings set org.gnome.desktop.a11y.keyboard bouncekeys-enable false
gsettings set org.gnome.desktop.a11y.keyboard stickykeys-enable false
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
echo "  User session: accessibility keys disabled, repeat delay 250 ms."

# --- 3b. System-wide dconf profile (applies to GDM + all users) ---
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

# ---------------------------------------------------------------------------
# 5. Install tmux + clipboard tools
# ---------------------------------------------------------------------------
echo "[5/9] Installing tmux and clipboard tools..."

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

# ---------------------------------------------------------------------------
# 6. Configure tmux (~/.tmux.conf)
# ---------------------------------------------------------------------------
echo "[6/9] Writing tmux configuration..."

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

# tmux-resurrect: capture pane contents
set -g @resurrect-capture-pane-contents 'on'

# ── Initialize TPM (keep at very bottom) ──────────────────────────────
run '~/.tmux/plugins/tpm/tpm'
TMUXCONF

echo "  ~/.tmux.conf written."

# ---------------------------------------------------------------------------
# 7. Install TPM (Tmux Plugin Manager) and plugins
# ---------------------------------------------------------------------------
echo "[7/9] Installing TPM and tmux plugins..."

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

# ---------------------------------------------------------------------------
# 8. Session automation — "dev" layout + auto-attach
# ---------------------------------------------------------------------------
echo "[8/9] Setting up tmux session automation..."

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

# ---------------------------------------------------------------------------
# 9. Customize bash prompt with alien beam
# ---------------------------------------------------------------------------
echo "[9/9] Customizing bash prompt with alien beam effect..."

BASHRC_BLOCK='
# ── Alien beam prompt ─────────────────────────────────────────────────
_beam_prompt() {
    local pw=$(( ${#USER} + ${#HOSTNAME} + ${#PWD} + 12 ))
    local seg=$(( pw / 7 ))
    (( seg < 1 )) && seg=1
    local cseg=$(( pw - seg * 6 ))
    local s1="" s2="" s3="" cm="" i
    for ((i=0; i<seg; i++)); do s1+="░"; s2+="▒"; s3+="▓"; done
    for ((i=0; i<cseg; i++)); do cm+="█"; done
    printf "\r\033[K\033[38;5;46m${s1}${s2}${s3}\033[38;5;40m${cm}\033[38;5;46m${s3}${s2}${s1}\033[0m"
    sleep 0.06
    printf "\r\033[K"
}

PROMPT_COMMAND="_beam_prompt"
export PS1="\[\e[1;35m\]👾\u\[\e[0m\] \[\e[1;38;5;80m\]🛸\h\[\e[0m\] \[\e[1;38;5;179m\]🗂️\w\[\e[0m\]\n\[\e[31m\]🚩\[\e[1;38;5;46m\] \\$ \[\e[0m\]"
# ── end beam prompt ───────────────────────────────────────────────────
'

# Always replace the prompt block to pick up changes
sed -i '/# ── .*beam.*prompt/,/# ── end beam prompt/d' "$HOME/.bashrc" 2>/dev/null || true
sed -i '/_beam_prompt/d; /_ufo_animate/d' "$HOME/.bashrc" 2>/dev/null || true
sed -i '/🛸.*PS1/d; /PROMPT_COMMAND.*_ufo/d' "$HOME/.bashrc" 2>/dev/null || true
echo "$BASHRC_BLOCK" >> "$HOME/.bashrc"
echo "  Alien beam prompt added to ~/.bashrc"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "=== Setup complete! ==="
echo "  - Ghostty terminal installed"
echo "  - Ctrl+Shift+Enter opens Ghostty"
echo "  - CapsLock responsiveness improved (user + GDM)"
echo "  - tmux installed + configured (~/.tmux.conf)"
echo "  - TPM + plugins: resurrect, continuum, yank, catppuccin mocha"
echo "  - tmux-dev script at ~/.local/bin/tmux-dev"
echo "  - tmux auto-attach on Ghostty launch"
echo "  - JetBrainsMono Nerd Font installed + Ghostty configured"
echo "  - Bash prompt: Powerline alien beam style"
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
