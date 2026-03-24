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
# 2. Set Ctrl+Shift+Enter keyboard shortcut to open Ghostty
# ---------------------------------------------------------------------------
echo "[2/8] Configuring Ctrl+Shift+Enter to open Ghostty..."

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
# 3. Fix CapsLock sticky / delayed toggle-off behavior (system-wide)
# ---------------------------------------------------------------------------
echo "[3/8] Fixing CapsLock sticky behavior (user session + GDM login)..."

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
# 4. Install tmux + clipboard tools
# ---------------------------------------------------------------------------
echo "[4/8] Installing tmux and clipboard tools..."

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
# 5. Configure tmux (~/.tmux.conf)
# ---------------------------------------------------------------------------
echo "[5/8] Writing tmux configuration..."

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
# Change prefix from Ctrl+B to Ctrl+A (easier to reach)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

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
bind S choose-session                       # prefix + S to list sessions
bind N command-prompt -p "New session:" "new-session -s '%%'"

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
# 6. Install TPM (Tmux Plugin Manager) and plugins
# ---------------------------------------------------------------------------
echo "[6/8] Installing TPM and tmux plugins..."

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
# 7. Session automation — "dev" layout + auto-attach
# ---------------------------------------------------------------------------
echo "[7/8] Setting up tmux session automation..."

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
# 8. Customize bash prompt with green teleport beam
# ---------------------------------------------------------------------------
echo "[8/8] Customizing bash prompt with green beam effect..."

BASHRC_BLOCK='
# ── Green teleport beam prompt ────────────────────────────────────────
_beam_prompt() {
    printf "\r\033[K\033[38;5;46m░▒▓\033[38;5;40m█\033[38;5;46m▓▒░\033[0m"
    sleep 0.06
    printf "\r\033[K"
}

PROMPT_COMMAND="_beam_prompt"
export PS1="🛸 \[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]\$ "
# ── end beam prompt ───────────────────────────────────────────────────
'

# Add to ~/.bashrc if not already present
if grep -qF '_beam_prompt' "$HOME/.bashrc" 2>/dev/null; then
    echo "  Beam prompt already configured, skipping."
else
    # Remove old animation if present from a previous run
    sed -i '/_ufo_animate/d; /# Custom prompt with flying saucer emoji/d; /# ── UFO prompt/,/# ── end UFO prompt/d' "$HOME/.bashrc" 2>/dev/null || true
    sed -i '/🛸.*PS1/d; /PROMPT_COMMAND.*_ufo/d' "$HOME/.bashrc" 2>/dev/null || true
    echo "$BASHRC_BLOCK" >> "$HOME/.bashrc"
    echo "  Green beam prompt added to ~/.bashrc"
fi

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
echo "  - Bash prompt: 🛸 green beam + user@host:path$"
echo ""
echo "Quick start:"
echo "  1. Log out & back in (for keyboard shortcut + dconf)"
echo "  2. Open Ghostty with Ctrl+Shift+Enter"
echo "  3. tmux starts automatically — you're in a session"
echo "  4. Run 'tmux-dev ~/myproject' for a dev layout"
echo ""
echo "tmux cheatsheet (prefix = Ctrl+A):"
echo "  Ctrl+A |    split vertical      Ctrl+A -    split horizontal"
echo "  Ctrl+A h/j/k/l  navigate panes  Ctrl+A H/J/K/L  resize panes"
echo "  Ctrl+A c    new window           Ctrl+A S    switch session"
echo "  Ctrl+A d    detach               Ctrl+A N    new session"
