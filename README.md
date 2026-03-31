# 🛸 Fedora Workstation Setup Script

A modular, idempotent bash script that transforms a fresh Fedora Workstation into a dark, minimal, sci-fi–themed development environment — with tiling, auto-hiding dock, custom terminal, CI/CD, and self-hosted GitLab.

Every module can be run independently or all at once. Safe to re-run — nothing gets duplicated.

<!-- Add a screenshot of your desktop here -->
<!-- ![Desktop Overview](screenshots/desktop.png) -->

---

## Quick Start

```bash
git clone https://github.com/i-robert2/fedora-customization-script.git
cd fedora-customization-script
chmod +x setup.sh
./setup.sh
```

After it finishes, **log out and back in** so keybindings, window animations, and dconf settings take effect.

### Running Individual Modules

```bash
./setup.sh --list              # see available modules
./setup.sh capslock            # just fix CapsLock delay
./setup.sh tmux prompt         # install/configure tmux + customize prompt
./setup.sh ghostty font keybinding  # just the Ghostty-related setup
```

---

## Modules

| # | Module | Description |
|---|---|---|
| 1 | `ghostty` | Install [Ghostty](https://ghostty.org/) terminal from COPR |
| 2 | `font` | Install JetBrainsMono Nerd Font + configure Ghostty |
| 3 | `keybinding` | `Ctrl+Shift+Enter` → open Ghostty |
| 4 | `capslock` | Fix CapsLock sticky/delayed behavior (desktop + GDM) |
| 5 | `tmux` | Install tmux + TPM + plugins + dev session script |
| 6 | `prompt` | Alien beam bash prompt with emoji + colors |
| 7 | `greeting` | UFO pixel-art landing animation on terminal open |
| 8 | `tools` | 14 CLI tools + Extension Manager + User Themes extension |
| 9 | `rofi` | Rofi app launcher + Catppuccin Mocha theme (`Super+D`) |
| 10 | `power` | Sleep after 3h, auto-shutdown after 4h idle |
| 11 | `dock` | Dash to Dock — auto-hide, bottom, no Show Apps button |
| 12 | `windowfx` | Pixelate animation on window open/close (280ms) |
| 13 | `wallpaper` | Solid black 4K wallpaper |
| 14 | `userpic` | GitHub profile picture as user avatar (GDM + desktop) |
| 15 | `tiling` | Tiling with gaps, quarter tiles, white borders |
| 16 | `topbar` | Fedora logo menu, Vitals, Weather, centered clock, tray |
| 17 | `appgrid` | Organize app grid into 5 category folders |
| 18 | `apps` | Discord (Flatpak) + KVM/QEMU + virt-manager |
| 19 | `gitlab` | GitLab CE — self-hosted via Podman with HTTPS |
| 20 | `cicd` | GitLab Runner + SSH deploy key for CI/CD pipelines |

---

## Terminal Setup

### Ghostty + Font

Installs [Ghostty](https://ghostty.org/) from the [scottames/ghostty COPR](https://copr.fedorainfracloud.org/coprs/scottames/ghostty/) and configures it with **JetBrainsMono Nerd Font** (v3.3.0).

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+Enter` | Open Ghostty (GNOME keybinding) |
| `Ctrl+Left/Right` | Jump by word |
| `Shift+Home/End` | Select to start/end of line |

### Bash Prompt — Alien Beam

<!-- Add a screenshot of your terminal prompt here -->
<!-- ![Bash Prompt](screenshots/prompt.png) -->

A custom PS1 prompt with a brief green teleport beam animation (`░▒▓█▓▒░`, ~60ms) before each command:

```
👾 username  🛸 hostname  🗂️ ~/current/path
📢 $
```

| Element | Color |
|---|---|
| `👾 username` | Bold magenta |
| `🛸 hostname` | Bold cyan |
| `🗂️ path` | Bold gold |
| `📢 $` | Bold green |

### UFO Greeting

<!-- Add a screenshot or GIF of the greeting animation here -->
<!-- ![UFO Greeting](screenshots/greeting.gif) -->

On every new terminal, a pixel-art UFO slides across the screen and lands with a `👽 howdy there!` message. Built with Unicode block characters and ANSI color codes.

---

## tmux

<!-- Add a screenshot of your tmux setup here -->
<!-- ![tmux](screenshots/tmux.png) -->

Full tmux configuration with **Catppuccin Mocha** status bar, Vim-style navigation, and automatic session management.

### Prefix Key: `Ctrl+Space`

Every tmux command starts with `Ctrl+Space`. Press it, release, then press the command key.

### Keybindings

#### Pane Navigation (Vim-style)

| Keys | Action |
|---|---|
| `Ctrl+Space h` | Move to pane left |
| `Ctrl+Space j` | Move to pane below |
| `Ctrl+Space k` | Move to pane above |
| `Ctrl+Space l` | Move to pane right |

#### Direct Shortcuts (no prefix needed)

| Keys | Action |
|---|---|
| `Alt+h/j/k/l` | Navigate panes directly |
| `Alt+1` through `Alt+5` | Switch to window 1–5 |

#### Pane Splitting

| Keys | Action |
|---|---|
| `Ctrl+Space \|` | Split vertically (side by side) |
| `Ctrl+Space -` | Split horizontally (top/bottom) |

Both open the new pane in the same directory.

#### Pane Resizing (repeatable)

| Keys | Action |
|---|---|
| `Ctrl+Space H/J/K/L` | Resize pane ±5 cells (Shift + vim key) |

#### Windows & Sessions

| Keys | Action |
|---|---|
| `Ctrl+Space c` | New window (same directory) |
| `Ctrl+Space 1-9` | Switch to window by number |
| `Ctrl+Space s` | List sessions (interactive) |
| `Ctrl+Space n` | Create new named session |
| `Ctrl+Space d` | Detach from session |

#### Copy Mode (Vim keys)

Enter with `Ctrl+Space [`:

| Keys | Action |
|---|---|
| `v` | Start selection |
| `Ctrl+V` | Rectangle selection |
| `y` | Yank to system clipboard |
| `q` | Exit copy mode |

#### Session Save/Restore

| Keys | Action |
|---|---|
| `Ctrl+Space Ctrl+s` | Save session layout (tmux-resurrect) |
| `Ctrl+Space Ctrl+r` | Restore last saved layout |

Sessions auto-save every 15 minutes and auto-restore on tmux start (tmux-continuum).

### Plugins

| Plugin | Purpose |
|---|---|
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Save/restore sessions across restarts |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-save (15 min) + auto-restore |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank) | Copy to system clipboard via xclip |
| [catppuccin/tmux](https://github.com/catppuccin/tmux) | Catppuccin Mocha status bar theme |

### `tmux-dev` Script

```bash
tmux-dev              # uses current directory
tmux-dev ~/myproject  # uses specified directory
```

Creates a session with 3 windows: **editor**, **server**, **git**. Reattaches if the session already exists.

### Auto-Attach

A `~/.bashrc` hook auto-attaches to your last tmux session when opening Ghostty. No need to type `tmux` — just open the terminal.

### Settings

| Setting | Value |
|---|---|
| Escape delay | 0 ms |
| Scrollback | 50,000 lines |
| True color | Enabled |
| Mouse | Full support (click, drag, scroll) |
| Window numbering | Starts at 1 |

---

## CLI Tools

Installed via `dnf`:

| Tool | Description |
|---|---|
| `bat` | `cat` with syntax highlighting |
| `btop` | Resource monitor |
| `eza` | Modern `ls` replacement |
| `fastfetch` | System info (neofetch replacement) |
| `fd` | Fast `find` alternative |
| `fzf` | Fuzzy finder |
| `gnome-tweaks` | GNOME customization GUI |
| `htop` | Interactive process viewer |
| `jq` | JSON processor |
| `ncdu` | Disk usage analyzer |
| `ripgrep` | Fast recursive grep |
| `duf` | Disk usage (`df` replacement) |
| `tldr` | Simplified man pages |

Also installs:
- **Extension Manager** (Flatpak) — browse/install GNOME extensions
- **User Themes** extension — enables custom shell themes

---

## Desktop Appearance

### Theme & Wallpaper

<!-- Add a screenshot of the desktop here -->
<!-- ![Desktop](screenshots/desktop-full.png) -->

- **GTK Theme:** Adwaita-dark
- **Color scheme:** `prefer-dark`
- **Wallpaper:** Solid black 4K (3840×2160), generated via ImageMagick
- **User avatar:** Pulled from GitHub profile → visible on GDM login + system menu

### Window Effects

- **Open/close animation:** Pixelate effect (280ms) via Burn My Windows extension
- **Active window border:** White glow (`rgba(255,255,255,0.5)` box-shadow)
- **Inactive window border:** Subtle (`rgba(255,255,255,0.06)`)

### Top Bar Layout

<!-- Add a screenshot of the top bar here -->
<!-- ![Top Bar](screenshots/topbar.png) -->

```
[🔵 Fedora ▾]  [CPU 12% | RAM 4.2G | ↑ 1.2MB/s]  ...  [☁ 18°C]  [Tue Mar 31 10:30]  [🔋 tray]
```

| Position | Element |
|---|---|
| Left | Fedora logo menu (replaces Activities) |
| Left | Vitals — CPU, RAM, network, storage, GPU, temp |
| Center | Advanced Weather (left of clock) |
| Center | Clock with date + weekday |
| Right | AppIndicator tray |
| Right | System indicators |

- Top bar is **semi-transparent** (`rgba(40,40,40,0.7)`)
- Activities button is hidden
- 3 static workspaces

### Dock

<!-- Add a screenshot of the dock here -->
<!-- ![Dock](screenshots/dock.png) -->

- **Position:** Bottom, auto-hide
- **Icon size:** 40px
- **Hidden:** Show Apps button, trash, mounted drives
- **VM mode:** Uses intellihide (shows when no window covers dock area)

### Tiling & Gaps

<!-- Add a screenshot of tiled windows here -->
<!-- ![Tiling](screenshots/tiling.png) -->

Powered by Tiling Assistant with **12px symmetric gaps** on all sides.

| Shortcut | Tile Position |
|---|---|
| `Super+Left/Right/Up/Down` | Half-screen tiles + directional focus |
| `Super+U` | Quarter — top-left |
| `Super+I` | Quarter — top-right |
| `Super+J` | Quarter — bottom-left |
| `Super+K` | Quarter — bottom-right |
| `Super+Y` | Maximize (with gaps) |
| `Super+N` | Left half, no gaps |
| `Super+M` | Right half, no gaps |
| `Super+B` | True fullscreen, no gaps |
| `Super+Escape` | Restore window |

### App Grid

5 category folders:

| Folder | Contents |
|---|---|
| **Dev** | VS Code, Ghostty, Terminal, htop, btop |
| **Office** | LibreOffice suite, Calendar, Maps, Weather, Contacts |
| **Media** | Videos, Music, Photos, Screenshot tools |
| **System** | Settings, System Monitor, Disks, Tweaks, Logs |
| **Accessories** | Text Editor, Calculator, Files, Archive Manager |

### Rofi Launcher

<!-- Add a screenshot of rofi here -->
<!-- ![Rofi](screenshots/rofi.png) -->

| Setting | Value |
|---|---|
| Shortcut | `Super+D` |
| Theme | Catppuccin Mocha |
| Font | JetBrainsMono Nerd Font 12 |
| Modes | drun, run, window |

---

## Keyboard Fix — CapsLock

Fixes the sticky/delayed CapsLock behavior system-wide:

| Setting | Value |
|---|---|
| Slow Keys | Disabled |
| Bounce Keys | Disabled |
| Sticky Keys | Disabled |
| Repeat delay | 250 ms |
| Repeat interval | 30 ms |

Applied to both user session (gsettings) and GDM login screen (dconf).

---

## Power Management

| Event | Action |
|---|---|
| 3 hours idle (AC or battery) | Suspend |
| 4 hours all-sessions idle | Auto shutdown |
| In VM: screen blanking | Disabled |

Auto-shutdown uses a custom systemd timer that checks every 15 minutes via `loginctl`.

---

## Apps & Virtualization

### Discord

Installed via Flatpak (sandboxed, auto-updated).

### KVM/QEMU + virt-manager

Native Fedora virtualization — near bare-metal VM performance.

```bash
virt-manager     # GUI for managing VMs
virsh list --all # CLI to list all VMs
```

The `libvirtd` service is enabled at boot. Your user is added to the `libvirt` group for passwordless VM management.

### GitLab CE (Self-Hosted)

<!-- Add a screenshot of the GitLab UI here -->
<!-- ![GitLab](screenshots/gitlab.png) -->

A full GitLab instance running locally as a rootless Podman container with HTTPS.

| Setting | Value |
|---|---|
| URL | `https://localhost:8929` |
| SSH port | `2224` |
| Data | `~/gitlab/{config,logs,data}` |
| SSL | Self-signed (10-year validity) |
| Auto-start | Yes (systemd user service + lingering) |
| Network | Localhost only (`127.0.0.1`) — not exposed to LAN/internet |

**First-time setup:**

```bash
# Get the initial root password
podman exec gitlab-ce cat /etc/gitlab/initial_root_password

# Open https://localhost:8929, login as "root", change password
# Then create a project and push:
git -c http.sslVerify=false remote add origin https://localhost:8929/root/my-project.git
git -c http.sslVerify=false push -u origin main
```

**Management:**

```bash
systemctl --user status gitlab-ce   # check status
systemctl --user restart gitlab-ce  # restart
podman logs -f gitlab-ce            # live logs
```

---

## CI/CD — Automatic Deployment

### GitHub Actions (this repo)

This repo uses GitHub Actions with a **self-hosted runner** on the Fedora VM. On every push to `main`:

1. **ShellCheck** lints all scripts (`--severity=error`)
2. **Deploy** runs only the changed modules on the VM

```
push to main → ShellCheck lint → detect changed modules → run setup.sh <changed modules>
```

Only the modules whose files changed in the commit are re-run. If `setup.sh` itself changes, all modules run.

### GitLab CI/CD — Deploy to KVM/QEMU VMs

The `cicd` module sets up a complete local CI/CD pipeline for deploying code from your self-hosted GitLab to KVM/QEMU VMs.

#### Architecture

```
┌──────────────────────────────────────────────────┐
│  Fedora Host (bare metal)                        │
│                                                  │
│  ┌──────────┐    ┌───────────────┐               │
│  │ GitLab   │───▶│ GitLab Runner │               │
│  │ CE       │    │ (shell exec)  │               │
│  └──────────┘    └───────┬───────┘               │
│                          │ SSH                    │
│                  ┌───────▼───────┐               │
│                  │  KVM/QEMU VM  │               │
│                  │  (your app)   │               │
│                  └───────────────┘               │
└──────────────────────────────────────────────────┘
```

#### Step 1 — Install the modules

```bash
./setup.sh gitlab cicd
```

This installs:
- **GitLab CE** — local git server at `https://localhost:8929`
- **GitLab Runner** — listens for pipeline jobs
- **SSH deploy key** — at `~/.ssh/gitlab-deploy` (passwordless deploys to VMs)

#### Step 2 — Log into GitLab

```bash
# Get the initial root password
podman exec gitlab-ce cat /etc/gitlab/initial_root_password
```

Open `https://localhost:8929`, accept the self-signed certificate warning, log in as `root`, and change the password.

#### Step 3 — Register the Runner

1. In GitLab UI: **Admin → CI/CD → Runners → New instance runner**
2. Copy the runner token
3. Run:

```bash
sudo gitlab-runner register \
  --url https://gitlab.local \
  --token YOUR_TOKEN \
  --executor shell \
  --tls-ca-file ~/gitlab/config/ssl/gitlab.local.crt
```

4. Start the runner:

```bash
sudo gitlab-runner start
```

#### Step 4 — Create a KVM/QEMU VM

Open `virt-manager` and create a VM (AlmaLinux 9 minimal recommended). Once it boots, note its IP:

```bash
virsh domifaddr YOUR_VM_NAME
```

#### Step 5 — Copy the deploy key to the VM

```bash
ssh-copy-id -i ~/.ssh/gitlab-deploy.pub deploy@VM_IP
```

(Replace `VM_IP` with the actual IP from step 4. Create a `deploy` user on the VM first if needed.)

#### Step 6 — Add the pipeline to your project

Copy the template from this repo into your GitLab project:

```bash
cp templates/gitlab-ci-deploy.yml /path/to/your-project/.gitlab-ci.yml
```

Edit `.gitlab-ci.yml` and set:
- `VM_IP` — your VM's IP address
- `VM_USER` — the user on the VM (default: `deploy`)
- `DEPLOY_PATH` — where the code goes on the VM (default: `/opt/myapp`)

#### Step 7 — Push and deploy

```bash
cd /path/to/your-project
git add .gitlab-ci.yml
git commit -m "ci: add deploy pipeline"
git -c http.sslVerify=false push origin main
```

The pipeline will automatically:
1. Run tests (if configured)
2. `rsync` your project files to the VM via SSH
3. Execute any post-deploy commands (restart service, etc.)

Check pipeline status in GitLab UI under **CI/CD → Pipelines**.

#### Pipeline template

The sample pipeline at [templates/gitlab-ci-deploy.yml](templates/gitlab-ci-deploy.yml) includes:
- A **test** stage (add your own test commands)
- A **deploy** stage that syncs files to the VM and runs post-deploy commands
- Commented examples for restarting systemd services or Podman containers

---

## Adding Screenshots

To add your own screenshots, create a `screenshots/` directory and capture:

| File | What to capture |
|---|---|
| `desktop.png` | Full desktop with a few tiled windows |
| `prompt.png` | Terminal showing the alien beam prompt |
| `greeting.gif` | GIF of the UFO landing animation |
| `tmux.png` | tmux with splits and Catppuccin status bar |
| `topbar.png` | Top bar showing logo, vitals, weather, clock |
| `dock.png` | Dock visible at the bottom |
| `tiling.png` | 2-4 windows tiled with gaps and white borders |
| `rofi.png` | Rofi launcher open with Catppuccin theme |
| `gitlab.png` | GitLab CE login or project page |

Then uncomment the `![...](screenshots/...)` lines in this README.

You can capture a GIF with:
```bash
# Install peek (GIF recorder)
flatpak install flathub com.uploadedlobster.peek
```

---

## License

See [LICENSE](LICENSE).

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

---

## Project Structure

```
setup.sh                        # Main orchestrator — sources modules, parses args
modules/
  ghostty.sh                    # Install Ghostty terminal
  font.sh                       # JetBrainsMono Nerd Font + Ghostty config
  keybinding.sh                 # Ctrl+Shift+Enter → Ghostty
  capslock.sh                   # Fix CapsLock sticky behavior
  tmux.sh                       # tmux + TPM + plugins + dev layout
  prompt.sh                     # Alien beam bash prompt
  greeting.sh                   # UFO landing animation
  tools.sh                      # CLI tools + Extension Manager + User Themes
  rofi.sh                       # Rofi app launcher + Catppuccin theme
  power.sh                      # Sleep/shutdown on inactivity
  dock.sh                       # Dash to Dock (auto-hide, bottom)
  windowfx.sh                   # Pixelate open/close animations
  wallpaper.sh                  # Solid black 4K wallpaper
  userpic.sh                    # GitHub avatar as user pic
  tiling.sh                     # Tiling Assistant + gaps + borders
  topbar.sh                     # Fedora logo, Vitals, weather, tray
  appgrid.sh                    # App grid category folders
  apps.sh                       # User apps (Discord, etc.)
setup-runner.sh                 # One-time GitHub Actions runner setup
.github/workflows/deploy.yml   # CI/CD pipeline
```

Each module is a standalone `.sh` file containing a single `mod_<name>()` function. The main `setup.sh` sources all modules and runs them in order (or only the ones you specify).

---

## CI/CD Pipeline

The repository includes a GitHub Actions workflow that **automatically lints and deploys** changes to a Fedora VM when you push to `main`.

### How It Works

1. **Lint** — Runs `shellcheck` on `setup.sh` and all `modules/*.sh` files (on GitHub-hosted Ubuntu runner)
2. **Deploy** — Checks out the code on your self-hosted Fedora runner and runs only the changed modules

The pipeline detects which `modules/*.sh` files changed in the commit and passes only those module names to `./setup.sh`. If `setup.sh` itself changed, it runs all modules as a safety fallback.

### Setting It Up on Your Own Fork

1. **Fork this repository** on GitHub

2. **Set up a Fedora VM** (VirtualBox, QEMU, bare metal — anything with a graphical session)

3. **Register a self-hosted runner** on the VM:
   ```bash
   # On the Fedora VM:
   git clone https://github.com/<your-username>/fedora-customization-script.git
   cd fedora-customization-script
   chmod +x setup-runner.sh

   # Get your runner token from:
   #   https://github.com/<your-username>/fedora-customization-script/settings/actions/runners/new
   # Select "Linux" + "x64", copy the token from the config.sh line
   ./setup-runner.sh <YOUR_RUNNER_TOKEN>
   ```

4. **Verify** the runner shows as "Idle" (green) at:
   `https://github.com/<your-username>/fedora-customization-script/settings/actions/runners`

5. **Push a change** — the pipeline runs automatically:
   - Edit a module (e.g. `modules/tiling.sh`)
   - `git add modules/tiling.sh && git commit -m "tweak tiling" && git push`
   - Only the `tiling` module runs on the VM (not all 18)

### Requirements

- The Fedora VM must have a **graphical session** running (GNOME) — many modules use `gsettings` and `dconf`
- The runner service starts automatically on boot (configured by `setup-runner.sh`)
- The VM user needs **passwordless sudo** (also configured by `setup-runner.sh`)
