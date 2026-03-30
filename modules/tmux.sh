# shellcheck shell=bash
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