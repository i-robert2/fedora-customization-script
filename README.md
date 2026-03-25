# 🛸 Fedora Workstation Setup Script

A modular bash script to customize a fresh Fedora Workstation installation with Ghostty terminal, tmux sessions, keyboard fixes, and a personalized shell experience.

## Quick Start

```bash
git clone https://github.com/i-robert2/fedora-customization-script.git
cd fedora-customization-script
chmod +x setup.sh
./setup.sh
```

After it finishes, **log out and back in** so the keyboard shortcut and dconf settings take effect.

### Running Individual Modules

You don't have to run everything. Pick only the modules you need:

```bash
./setup.sh --list              # see available modules
./setup.sh capslock            # just fix CapsLock delay
./setup.sh tmux prompt         # install/configure tmux + customize prompt
./setup.sh ghostty font keybinding  # just the Ghostty-related setup
```

Available modules:

| Module | Description |
|---|---|
| `ghostty` | Install Ghostty terminal |
| `font` | Install JetBrainsMono Nerd Font + configure Ghostty |
| `keybinding` | Set Ctrl+Shift+Enter shortcut for Ghostty |
| `capslock` | Fix CapsLock sticky/delayed behavior |
| `tmux` | Install and configure tmux + TPM + plugins |
| `prompt` | Customize bash prompt (alien beam) |
| `tools` | Install CLI tools (bat, eza, fd, fzf, htop, jq, ncdu, ripgrep, duf, tldr) |
| `rofi` | Install and configure rofi app launcher + Catppuccin theme |

---

## What the Script Does

The script has 6 modules that run in order. Each module is idempotent — you can safely re-run the script without duplicating anything.

### 1. Install Ghostty Terminal

Installs [Ghostty](https://ghostty.org/) from the community-maintained [scottames/ghostty COPR](https://copr.fedorainfracloud.org/coprs/scottames/ghostty/) repository.

### 2. Keyboard Shortcut — Open Ghostty

Registers a GNOME custom keybinding:

| Shortcut | Action |
|---|---|
| `Ctrl + Shift + Enter` | Open Ghostty terminal |

### 3. Fix CapsLock Sticky Behavior (System-Wide)

Fixes the issue where CapsLock "hangs on" and the next character you type is still capitalized after you've already toggled CapsLock off.

**What it changes:**

| Setting | Value | Default |
|---|---|---|
| Slow Keys | Disabled | Disabled |
| Bounce Keys | Disabled | Disabled |
| Sticky Keys | Disabled | Disabled |
| Keyboard repeat delay | 250 ms | 500 ms |
| Keyboard repeat interval | 30 ms | Default |

**Applied in two places:**
- **User session** — via `gsettings` (your desktop)
- **GDM login screen** — via a system-wide dconf profile at `/etc/dconf/db/gdm.d/99-capslock-fix` (so the fix works when typing your password at login too)

### 4. Install tmux + Clipboard Tools

Installs:
- **tmux** — terminal multiplexer for persistent sessions, splits, and windows
- **xclip** — bridges tmux's copy buffer with the system clipboard

### 5. Configure tmux (`~/.tmux.conf`)

A full tmux configuration with the features below. If a `~/.tmux.conf` already exists, it is backed up before overwriting.

#### Prefix Key

The tmux prefix (leader key) is changed from the default `Ctrl+B` to **`Ctrl+Space`** — it's fast and ergonomic (thumb on Ctrl, thumb/index on Space).

> Every tmux command starts with the prefix. For example: `Ctrl+Space` then `|` to split vertically. Press `Ctrl+Space`, release, then press the command key.

#### Keybindings

All command keys are **lowercase** — no Shift needed.

##### Pane Navigation (Vim-style)

| Keys | Action |
|---|---|
| `Ctrl+Space h` | Move to pane on the **left** |
| `Ctrl+Space j` | Move to pane **below** |
| `Ctrl+Space k` | Move to pane **above** |
| `Ctrl+Space l` | Move to pane on the **right** |

##### Pane Splitting

| Keys | Action |
|---|---|
| `Ctrl+Space \|` | Split vertically (side by side) |
| `Ctrl+Space -` | Split horizontally (top/bottom) |

Both open the new pane in **the same directory** you're currently in.

##### Pane Resizing (repeatable)

Hold the prefix, then press Shift + vim key repeatedly:

| Keys | Action |
|---|---|
| `Ctrl+Space H` | Resize pane left (5 cells) |
| `Ctrl+Space J` | Resize pane down (5 cells) |
| `Ctrl+Space K` | Resize pane up (5 cells) |
| `Ctrl+Space L` | Resize pane right (5 cells) |

> Resizing is the only action that uses Shift (capital H/J/K/L) since lowercase h/j/k/l are used for navigation.

##### Windows

| Keys | Action |
|---|---|
| `Ctrl+Space c` | New window (in current directory) |
| `Ctrl+Space 1-9` | Switch to window by number |

##### Sessions

| Keys | Action |
|---|---|
| `Ctrl+Space s` | List all sessions (interactive switcher) |
| `Ctrl+Space n` | Create a new named session |
| `Ctrl+Space d` | Detach from current session (it keeps running) |

##### Direct Shortcuts (no prefix needed)

These skip the prefix entirely — single chord, instant action:

| Keys | Action |
|---|---|
| `Alt+h` | Navigate pane left |
| `Alt+j` | Navigate pane down |
| `Alt+k` | Navigate pane up |
| `Alt+l` | Navigate pane right |
| `Alt+1` through `Alt+5` | Switch to window 1–5 |

##### Copy Mode (Vim keys)

Enter copy mode with `Ctrl+Space [`, then:

| Keys | Action |
|---|---|
| `h/j/k/l` | Navigate |
| `v` | Start selection |
| `Ctrl+V` | Rectangle (block) selection |
| `y` | Yank selection to **system clipboard** |
| `q` | Exit copy mode |

##### Session Save/Restore (via plugins)

| Keys | Action |
|---|---|
| `Ctrl+Space Ctrl+s` | **Save** current session layout (tmux-resurrect) |
| `Ctrl+Space Ctrl+r` | **Restore** last saved session layout |

#### Appearance

- **Catppuccin Mocha** theme on the tmux status bar (dark pastel palette)
- Window numbering starts at **1** (not 0)
- Windows auto-rename to the currently running command
- Windows renumber automatically when one is closed

#### Mouse Support

Everything works with the mouse:
- **Click** a pane to focus it
- **Click** a window name in the status bar to switch
- **Drag** pane borders to resize
- **Scroll wheel** to browse scrollback history

#### Other Settings

| Setting | Value | Why |
|---|---|---|
| Escape delay | 0 ms | Default is 500ms — makes Vim feel laggy |
| Scrollback history | 50,000 lines | Default is 2,000 |
| True color | Enabled | Needed for themes/Vim colors |
| Focus events | Enabled | Apps like Vim can react to focus changes |

### 6. Install TPM and Plugins

[TPM (Tmux Plugin Manager)](https://github.com/tmux-plugins/tpm) is cloned to `~/.tmux/plugins/tpm` and all plugins are installed automatically.

**Installed plugins:**

| Plugin | What it does |
|---|---|
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Save and restore session layouts across tmux restarts/reboots |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-saves sessions every 15 minutes; auto-restores on tmux start |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank) | Copies selections to system clipboard (via xclip) |
| [catppuccin/tmux](https://github.com/catppuccin/tmux) | Catppuccin Mocha color theme for the status bar |

### 7. Session Automation

#### `tmux-dev` Script

A helper script installed at `~/.local/bin/tmux-dev` that creates a pre-defined development session:

```bash
tmux-dev              # uses current directory
tmux-dev ~/myproject  # uses specified directory
```

**Layout created:**

| Window | Name | Purpose |
|---|---|---|
| 1 | editor | For vim / your code editor |
| 2 | server | For running a dev server |
| 3 | git | For git operations |

If the `dev` session already exists, it reattaches instead of creating a duplicate.

#### Auto-Attach on Ghostty Launch

A block is added to `~/.bashrc` so that every time you open Ghostty, bash automatically attaches to your last tmux session. If no session exists, it creates one called `main`.

This means you **never have to manually type `tmux`** — just open Ghostty and you're in a session.

### 8. Custom Bash Prompt

A green teleport beam animation followed by a themed prompt:

```
🛸 user@hostname:~/current/path$
```

**How it works:**
- Before each new prompt, a brief green `░▒▓█▓▒░` flash appears for ~60ms (barely visible, just a subtle shimmer)
- The prompt shows: 🛸 emoji + green username + blue hostname + yellow path

The beam and prompt colors are bash-level — they are unaffected by the Catppuccin tmux theme (which only styles the status bar).

### 9. CLI Tools

Installs a curated set of modern command-line tools in a single `dnf install`:

| Tool | Package | What it does |
|---|---|---|
| `bat` | bat | `cat` with syntax highlighting and line numbers |
| `eza` | eza | Modern `ls` replacement — icons, git status, `--tree` |
| `fd` | fd-find | Fast, user-friendly `find` alternative |
| `fzf` | fzf | Fuzzy finder for files, history, and more |
| `htop` | htop | Interactive process viewer (replaces `top`) |
| `jq` | jq | Command-line JSON processor |
| `ncdu` | ncdu | Interactive disk usage analyzer |
| `rg` | ripgrep | Blazing-fast recursive grep |
| `duf` | duf | Disk usage overview (`df` replacement) |
| `tldr` | tldr | Simplified, community-driven man pages |

> **Tip:** `eza --tree` replaces the `tree` command and adds icons + git status when you have a Nerd Font installed.

### 10. Rofi App Launcher

Installs [rofi](https://github.com/davatorium/rofi) — a fast, keyboard-driven application launcher with native Wayland support (v2.0.0+).

**What it configures:**

| Setting | Value |
|---|---|
| Modi | drun (apps), run (commands), window (switcher) |
| Font | JetBrainsMono Nerd Font 12 |
| Theme | Catppuccin Mocha |
| Show icons | Enabled |
| Terminal | Ghostty |
| Keybinding | **Super+D** → `rofi -show drun` |

The Catppuccin Mocha theme is downloaded from the [catppuccin/rofi](https://github.com/catppuccin/rofi) repository and stored at `~/.local/share/rofi/themes/catppuccin-mocha.rasi`.

---

## tmux Cheatsheet

All commands use the prefix **`Ctrl+Space`** (press `Ctrl+Space`, release, then press the key).

### Essential

```
Ctrl+Space d          Detach (session keeps running)
Ctrl+Space |          Split vertical
Ctrl+Space -          Split horizontal
Ctrl+Space h/j/k/l   Navigate panes (vim-style)
Ctrl+Space c          New window
Ctrl+Space 1-9        Switch to window N
Ctrl+Space s          List/switch sessions
Ctrl+Space n          New named session
```

### Direct Shortcuts (no prefix)

```
Alt+h/j/k/l    Navigate panes
Alt+1-5        Switch to window 1–5
```

### Copy & Paste

```
Ctrl+Space [          Enter copy mode
  h/j/k/l         Navigate
  v                Start selection
  y                Yank to clipboard
  q                Quit copy mode
Ctrl+Space ]          Paste from tmux buffer
```

### Session Management

```
Ctrl+Space Ctrl+s     Save session (resurrect)
Ctrl+Space Ctrl+r     Restore session (resurrect)
Ctrl+Space $          Rename current session
```

### Windows & Panes

```
Ctrl+Space c          New window
Ctrl+Space ,          Rename window
Ctrl+Space w          Window list
Ctrl+Space &          Close window
Ctrl+Space x          Close pane
Ctrl+Space H/J/K/L   Resize pane (Shift + vim key)
Ctrl+Space z          Toggle pane zoom (fullscreen)
```

### From the Command Line

```bash
tmux ls                      # List sessions
tmux attach -t <name>        # Attach to session
tmux new -s <name>           # New named session
tmux kill-session -t <name>  # Kill session
tmux-dev [directory]         # Dev layout (3 windows)
```

---

## File Locations

| File | Purpose |
|---|---|
| `~/.tmux.conf` | tmux configuration |
| `~/.tmux/plugins/` | TPM and installed plugins |
| `~/.local/bin/tmux-dev` | Dev session layout script |
| `~/.bashrc` | Prompt customization + tmux auto-attach |
| `~/.config/rofi/config.rasi` | Rofi configuration |
| `~/.local/share/rofi/themes/catppuccin-mocha.rasi` | Rofi Catppuccin theme |
| `/etc/dconf/db/gdm.d/99-capslock-fix` | GDM keyboard settings |
| `/etc/dconf/profile/gdm` | GDM dconf profile |

---

## Re-running the Script

The script is safe to run multiple times. Each module checks whether its changes are already applied and skips if so. The tmux config (`~/.tmux.conf`) is backed up with a timestamp before overwriting.

You can re-run individual modules too:

```bash
./setup.sh tmux      # re-run just tmux setup
./setup.sh prompt    # re-apply the bash prompt
```
