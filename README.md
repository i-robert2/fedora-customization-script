# 🛸 Fedora Workstation Setup Script

A single bash script to customize a fresh Fedora Workstation installation with Ghostty terminal, tmux sessions, keyboard fixes, and a personalized shell experience.

## Quick Start

```bash
git clone https://github.com/i-robert2/fedora-customization-script.git
cd fedora-customization-script
chmod +x setup.sh
./setup.sh
```

After it finishes, **log out and back in** so the keyboard shortcut and dconf settings take effect.

---

## What the Script Does

The script runs 8 steps in order. Each step is idempotent — you can safely re-run the script without duplicating anything.

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

The tmux prefix (leader key) is changed from the default `Ctrl+B` to **`Ctrl+A`** — it's easier to reach since your pinky stays on Ctrl and index finger hits A on the home row.

> Every tmux command starts with the prefix. For example: `Ctrl+A` then `|` to split vertically.

#### Keybindings

##### Pane Navigation (Vim-style)

| Keys | Action |
|---|---|
| `Ctrl+A h` | Move to pane on the **left** |
| `Ctrl+A j` | Move to pane **below** |
| `Ctrl+A k` | Move to pane **above** |
| `Ctrl+A l` | Move to pane on the **right** |

##### Pane Splitting

| Keys | Action |
|---|---|
| `Ctrl+A \|` | Split vertically (side by side) |
| `Ctrl+A -` | Split horizontally (top/bottom) |

Both open the new pane in **the same directory** you're currently in.

##### Pane Resizing (repeatable)

Hold the prefix, then press Shift + vim key repeatedly:

| Keys | Action |
|---|---|
| `Ctrl+A H` | Resize pane left (5 cells) |
| `Ctrl+A J` | Resize pane down (5 cells) |
| `Ctrl+A K` | Resize pane up (5 cells) |
| `Ctrl+A L` | Resize pane right (5 cells) |

##### Windows

| Keys | Action |
|---|---|
| `Ctrl+A c` | New window (in current directory) |
| `Ctrl+A 1-9` | Switch to window by number |
| `Ctrl+A n` | Next window |
| `Ctrl+A p` | Previous window |

##### Sessions

| Keys | Action |
|---|---|
| `Ctrl+A S` | List all sessions (interactive switcher) |
| `Ctrl+A N` | Create a new named session |
| `Ctrl+A d` | Detach from current session (it keeps running) |

##### Copy Mode (Vim keys)

Enter copy mode with `Ctrl+A [`, then:

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
| `Ctrl+A Ctrl+S` | **Save** current session layout (tmux-resurrect) |
| `Ctrl+A Ctrl+R` | **Restore** last saved session layout |

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

---

## tmux Cheatsheet

All commands use the prefix **`Ctrl+A`** (press `Ctrl+A`, release, then press the key).

### Essential

```
Ctrl+A d          Detach (session keeps running)
Ctrl+A |          Split vertical
Ctrl+A -          Split horizontal
Ctrl+A h/j/k/l   Navigate panes (vim-style)
Ctrl+A c          New window
Ctrl+A 1-9        Switch to window N
Ctrl+A S          List/switch sessions
Ctrl+A N          New named session
```

### Copy & Paste

```
Ctrl+A [          Enter copy mode
  h/j/k/l         Navigate
  v                Start selection
  y                Yank to clipboard
  q                Quit copy mode
Ctrl+A ]          Paste from tmux buffer
```

### Session Management

```
Ctrl+A Ctrl+S     Save session (resurrect)
Ctrl+A Ctrl+R     Restore session (resurrect)
Ctrl+A $          Rename current session
Ctrl+A s          Session list (lowercase)
```

### Windows & Panes

```
Ctrl+A c          New window
Ctrl+A ,          Rename window
Ctrl+A w          Window list
Ctrl+A &          Close window
Ctrl+A x          Close pane
Ctrl+A H/J/K/L   Resize pane (Shift + vim key)
Ctrl+A z          Toggle pane zoom (fullscreen)
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
| `/etc/dconf/db/gdm.d/99-capslock-fix` | GDM keyboard settings |
| `/etc/dconf/profile/gdm` | GDM dconf profile |

---

## Re-running the Script

The script is safe to run multiple times. Each section checks whether its changes are already applied and skips if so. The tmux config (`~/.tmux.conf`) is backed up with a timestamp before overwriting.
