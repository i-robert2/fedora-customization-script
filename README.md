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
| 8 | `tools` | CLI tools + OCR (Tesseract, PaddleOCR) + ExifTool + Extension Manager |
| 9 | `power` | Sleep after 3h, auto-shutdown after 4h idle |
| 10 | `dock` | Dash to Dock — auto-hide, bottom, no Show Apps button |
| 11 | `windowfx` | Pixelate animation on window open/close (280ms) |
| 12 | `wallpaper` | Solid black 4K wallpaper |
| 13 | `userpic` | GitHub profile picture as user avatar (GDM + desktop) |
| 14 | `tiling` | Tiling with gaps, quarter tiles, white borders |
| 15 | `topbar` | Fedora logo menu, Vitals, Weather, centered clock, tray, Super+A App Grid |
| 16 | `appgrid` | Organize app grid into 5 category folders |
| 17 | `apps` | Discord, GIMP, Krita, Drawing, darktable, digiKam, Kdenlive, Jellyfin, Reactive Resume, KVM/QEMU |
| 18 | `gitlab` | GitLab CE — self-hosted via Podman with HTTPS (manual start) |
| 19 | `cicd` | GitLab Runner + SSH deploy key for CI/CD pipelines |
| 20 | `vmops` | SSH helpers + Ansible playbooks for managing KVM/QEMU VMs |
| 21 | `monitoring` | Prometheus + Grafana VM monitoring (Podman, manual start) |
| 22 | `ollama` | Ollama + AI models (Qwen 2.5 Coder, Qwen 2.5, DeepSeek R1, Phi-4, Gemma 4) |
| 23 | `openwebui` | Open WebUI — ChatGPT-like interface for local AI |
| 24 | `searxng` | SearXNG — self-hosted search engine for AI web search |
| 25 | `comfyui` | ComfyUI + AnimateDiff — image & video generation |
| 26 | `tts` | Text-to-speech engines (Piper, Kokoro, F5-TTS) |
| 27 | `continue` | VSCodium + Continue AI coding extension |
| 28 | `tauri` | Rust, Node.js & Tauri 2 dev environment |

---

<details>
<summary><strong>🖥️ Terminal Setup</strong> — Ghostty, prompt, UFO greeting</summary>

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

</details>

<details>
<summary><strong>📟 tmux</strong> — Catppuccin status bar, Vim-style navigation, session management</summary>

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

</details>

<details>
<summary><strong>🔧 CLI Tools</strong> — bat, btop, eza, fd, fzf, ripgrep, and more</summary>

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
| `tesseract` | OCR engine for images |
| `ocrmypdf` | Adds searchable text layer to scanned PDFs |
| `exiftool` | Metadata viewer/stripper for any file type |

Also installs:
- **PaddleOCR** (pip) — highest-accuracy OCR engine (scene text, handwriting, complex layouts)
- **Tesseract English language pack** — required for Tesseract/OCRmyPDF
- **Extension Manager** (Flatpak) — browse/install GNOME extensions
- **User Themes** extension — enables custom shell themes

**OCR usage:**

```bash
# Tesseract — extract text from an image
tesseract image.png output        # creates output.txt
tesseract image.png - | head       # print to stdout

# OCRmyPDF — make a scanned PDF searchable
ocrmypdf scanned.pdf searchable.pdf

# PaddleOCR — best accuracy (especially for photos/scene text)
paddleocr --image_dir image.png --lang en
```

**Metadata stripping:**

```bash
exiftool -all= photo.jpg           # strip all metadata from a file
exiftool -all= *.jpg               # batch strip
exiftool photo.jpg                 # view all metadata
```

**File search with fd + fzf:**

```bash
# fd — fast find replacement (searches current directory recursively)
fd readme                          # find files matching "readme"
fd .sh                             # find all .sh files
fd -t f setup                      # find only files (not directories)
fd -t d config                     # find only directories
fd .conf /etc                      # search in a specific directory
fd --changed-within 1h             # files modified in the last hour

# fzf — interactive fuzzy finder
fzf                                # browse all files interactively
fd | fzf                           # fd + fzf combo (fast fuzzy file search)
fzf --preview 'cat {}'             # preview file contents while searching
history | fzf                      # search command history interactively

# Power combos
nano $(fd -t f | fzf)              # find a file, then open it in nano
cd $(fd -t d | fzf)                # find a directory, then cd into it
nano $(rg -l "TODO" | fzf)         # find files containing "TODO", pick one to edit
```

</details>

<details>
<summary><strong>🎨 Desktop Appearance</strong> — Theme, wallpaper, top bar, dock, tiling, app grid</summary>

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

| Shortcut | Action |
|---|---|
| `Super` | Open Overview (search + workspaces) |
| `Super+A` | Open App Grid (organized folders) |

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

</details>

<details>
<summary><strong>⌨️ Keyboard Fix</strong> — CapsLock</summary>

Fixes the sticky/delayed CapsLock behavior system-wide:

| Setting | Value |
|---|---|
| Slow Keys | Disabled |
| Bounce Keys | Disabled |
| Sticky Keys | Disabled |
| Repeat delay | 250 ms |
| Repeat interval | 30 ms |

Applied to both user session (gsettings) and GDM login screen (dconf).

</details>

<details>
<summary><strong>🔋 Power Management</strong> — Sleep & auto-shutdown</summary>

| Event | Action |
|---|---|
| 3 hours idle (AC or battery) | Suspend |
| 4 hours all-sessions idle | Auto shutdown |
| In VM: screen blanking | Disabled |

Auto-shutdown uses a custom systemd timer that checks every 15 minutes via `loginctl`.

</details>

<details>
<summary><strong>📦 Apps & Virtualization</strong> — Image editors, video, media server, VMs, GitLab CE</summary>

### Image Editors

| App | Type | Install |
|---|---|---|
| **Drawing** | Simple Paint-like editor (crop, annotate, arrows) | Flatpak |
| **GIMP** | Full-featured image editor (Photoshop alternative) | dnf |
| **Krita** | Digital painting and illustration | dnf |
| **darktable** | Non-destructive RAW photo editing (Lightroom Develop) | dnf |
| **digiKam** | Photo & video library management (Lightroom Library) — tagging, face detection, albums | dnf |

### Video Editing

| App | Description | Install |
|---|---|---|
| **Kdenlive** | Full video editor — timeline, effects, transitions, proxy editing, 4K | dnf |

### Jellyfin — Self-Hosted Media Server

A self-hosted Netflix/Plex alternative for streaming your local media library. Installed via dnf with **no auto-start** — launch it from the desktop app icon when needed.

```bash
# Or start/stop manually:
sudo systemctl start jellyfin     # start
sudo systemctl stop jellyfin      # stop
# Then open http://localhost:8096
```

**Switching to auto-start on boot:**

If you want Jellyfin always running (e.g., streaming to other devices on your network):

```bash
sudo systemctl enable jellyfin
```

To revert back to manual start:

```bash
sudo systemctl disable jellyfin
```

### Discord

Installed via Flatpak (sandboxed, auto-updated).

### KVM/QEMU + virt-manager

Native Fedora virtualization — near bare-metal VM performance.

```bash
virt-manager     # GUI for managing VMs
virsh list --all # CLI to list all VMs
```

The `libvirtd` service is enabled at boot. Your user is added to the `libvirt` group for passwordless VM management.

### Reactive Resume — Self-Hosted Resume Builder

A free, open-source resume builder running locally via Podman Compose. No auto-start — launch from the desktop icon or CLI.

| Setting | Value |
|---|---|
| URL | `http://localhost:3002` |
| Stack | PostgreSQL + Browserless + SeaweedFS + Reactive Resume |
| Data | `~/reactive-resume/` + Podman volumes |
| First-time | Images are pulled on first start (~1-2 min) |

**Start/stop:**

```bash
reactive-resume start     # start all containers + open browser
reactive-resume stop      # stop all containers
reactive-resume status    # check container status
```

Or click the **Reactive Resume** desktop icon to start and open the browser.

**First-time setup:**

1. Start the app: `reactive-resume start`
2. Open `http://localhost:3002`
3. Create an account (first user is local, no email verification needed)
4. Start building your resume

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
| Auto-start | No (manual start via desktop launcher) |
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
systemctl --user start gitlab-ce    # start (or click the desktop launcher)
systemctl --user stop gitlab-ce     # stop
systemctl --user status gitlab-ce   # check status
systemctl --user restart gitlab-ce  # restart
podman logs -f gitlab-ce            # live logs
```

A desktop launcher is created at `~/.local/share/applications/gitlab-ce.desktop` — click it to start GitLab and open the browser automatically.

**Switching to auto-start on boot:**

If you want GitLab to start automatically when your machine boots (e.g., for a persistent development server):

```bash
systemctl --user enable gitlab-ce.service
loginctl enable-linger $USER
```

To revert back to manual start:

```bash
systemctl --user disable gitlab-ce.service
```

</details>

<details>
<summary><strong>📡 VM Operations</strong> — SSH helpers + Ansible for managing KVM/QEMU VMs</summary>

```bash
./setup.sh vmops
```

Installs **Ansible** and sets up two methods for managing your KVM/QEMU VMs from the host machine: **SSH helper functions** for quick ad-hoc commands, and **Ansible playbooks** for structured operations across many VMs.

### Prerequisites

1. KVM/QEMU VMs created via `virt-manager` (from the `apps` module)
2. SSH deploy key generated (from the `cicd` module)
3. Deploy key copied to each VM:
   ```bash
   ssh-copy-id -i ~/.ssh/gitlab-deploy.pub deploy@VM_IP
   ```
4. VM IPs configured (find with `virsh domifaddr VM_NAME`):
   ```bash
   nano ~/.ssh/config.d/vms.conf       # for SSH helpers
   nano ~/ansible/inventory.ini         # for Ansible
   ```

---

### Method 1: SSH Helpers (quick, 1–5 VMs)

Shell functions loaded into your terminal automatically. Best for quick checks and one-off commands.

#### Single VM

| Command | Description |
|---|---|
| `vm-status vm-web1` | Disk, memory, CPU load, uptime |
| `vm-service vm-web1 nginx` | Check a service status |
| `vm-logs vm-web1 nginx` | Tail service logs (live) |
| `vm-restart vm-web1 nginx` | Restart a service |
| `vm-exec vm-web1 'any command'` | Run any command on a VM |

#### Multiple VMs

| Command | Description |
|---|---|
| `vm-status-all vm-web1 vm-web2 vm-db1` | Check status of multiple VMs |
| `vm-exec-all 'free -m' vm-web1 vm-web2` | Run command on multiple VMs (sequential) |
| `vm-exec-parallel 'free -m' vm-web1 vm-web2 vm-db1` | Run command on multiple VMs (parallel) |

**Example workflow:**

```bash
# Quick health check on your web servers
vm-status vm-web1
vm-status vm-web2

# Check if nginx is running everywhere
vm-exec-parallel 'systemctl is-active nginx' vm-web1 vm-web2 vm-web3

# Restart a misbehaving service
vm-restart vm-web2 nginx

# Tail logs to debug an issue
vm-logs vm-web2 nginx
```

---

### Method 2: Ansible (structured, 5+ VMs)

Playbook-based operations with parallel execution, error handling, and formatted output. Best when managing many VMs or running the same checks regularly.

All playbooks are in `~/ansible/`. Edit `inventory.ini` first with your VM IPs.

#### Health Check — All VMs

```bash
cd ~/ansible

# Check all VMs
ansible-playbook -i inventory.ini check-health.yml

# Check only webservers
ansible-playbook -i inventory.ini check-health.yml --limit webservers

# Check all 5 VMs in parallel (default is 5 at a time)
ansible-playbook -i inventory.ini check-health.yml -f 5
```

Outputs per-VM summary: OS, CPUs, uptime, load, disk, memory.

#### Service Management

```bash
# Check nginx status on all webservers
ansible-playbook -i inventory.ini check-service.yml \
  -e "service_name=nginx" --limit webservers

# Restart postgres on all database servers
ansible-playbook -i inventory.ini check-service.yml \
  -e "service_name=postgresql service_action=restarted" --limit databases
```

#### Deploy Application

```bash
# Deploy project files to webservers and restart the service
ansible-playbook -i inventory.ini deploy-app.yml \
  -e "src_path=~/myproject deploy_path=/opt/myapp restart_service=myapp" \
  --limit webservers
```

#### Ad-hoc Commands

```bash
# Run any command on all VMs
ansible all -i inventory.ini -m command -a "uptime"

# Run on a specific group
ansible databases -i inventory.ini -m command -a "pg_isready"

# Copy a file to all VMs
ansible all -i inventory.ini -m copy -a "src=./config.yml dest=/opt/myapp/config.yml"
```

---

### When to Use Which

| Scenario | Use |
|---|---|
| Quick check on 1–3 VMs | SSH helpers (`vm-status`, `vm-exec`) |
| Same command on 5+ VMs | Ansible ad-hoc (`ansible all -m command -a ...`) |
| Structured health check | Ansible playbook (`check-health.yml`) |
| Service restart across fleet | Ansible playbook (`check-service.yml`) |
| Deploy code to multiple VMs | Ansible playbook (`deploy-app.yml`) |
| Tail logs in real-time | SSH helper (`vm-logs`) |

### Files

| File | Location | Purpose |
|---|---|---|
| `vms.conf` | `~/.ssh/config.d/vms.conf` | SSH config with VM hostnames/IPs |
| `vm-ops-helpers.sh` | `~/.local/bin/vm-ops-helpers.sh` | SSH helper functions (sourced in bashrc) |
| `inventory.ini` | `~/ansible/inventory.ini` | Ansible inventory (VM groups + IPs) |
| `check-health.yml` | `~/ansible/check-health.yml` | Health check playbook |
| `check-service.yml` | `~/ansible/check-service.yml` | Service check/restart playbook |
| `deploy-app.yml` | `~/ansible/deploy-app.yml` | Application deployment playbook |

</details>

<details>
<summary><strong>📊 Monitoring</strong> — Prometheus + Grafana for KVM/QEMU VMs</summary>

```bash
./setup.sh monitoring
```

Sets up **Prometheus** and **Grafana** as Podman containers on the host, plus an Ansible playbook to deploy **node_exporter** to your VMs. No auto-start — launch manually when needed.

### Architecture

```
┌──────────────┖  ┌──────────────┖  ┌──────────────┖
│  VM-web1     │  │  VM-web2     │  │  VM-db1      │
│  node_exporter│  │  node_exporter│  │  node_exporter│
│  :9100       │  │  :9100       │  │  :9100       │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                    │                    │
       └────────────┬───────┴────────────┘
                    │ scrapes :9100 every 15s
            ┌───────┴───────┖
            │  Prometheus   │  stores time-series metrics
            │  :9090        │  30-day retention
            └───────┬───────┘
                    │
            ┌───────┴───────┖
            │   Grafana     │  dashboards + graphs
            │   :3001       │  login: admin / admin
            └───────────────┘
```

### Setup

#### Step 1 — Install the monitoring module

```bash
./setup.sh monitoring
```

This creates Prometheus and Grafana containers (not started), systemd services, a convenience script, and a desktop launcher.

#### Step 2 — Configure Prometheus targets

Edit `~/monitoring/prometheus/prometheus.yml` with your VM IPs:

```bash
nano ~/monitoring/prometheus/prometheus.yml
```

#### Step 3 — Install node_exporter on VMs

Uses the Ansible playbook to install node_exporter on all VMs:

```bash
cd ~/ansible
ansible-playbook -i inventory.ini install-node-exporter.yml
```

This downloads, installs, and starts node_exporter as a systemd service on each VM.

#### Step 4 — Start monitoring

```bash
monitoring start
# or click the Grafana desktop icon
```

#### Step 5 — Set up Grafana dashboard

1. Open `http://localhost:3001` (login: `admin` / `admin`)
2. Prometheus is auto-configured as a datasource
3. Go to **Dashboards → Import → enter ID `1860`** → Load
4. Select the **Prometheus** datasource → Import

This gives you the **Node Exporter Full** dashboard with CPU, RAM, disk, network graphs for all VMs.

### Management

```bash
monitoring start     # start Prometheus + Grafana
monitoring stop      # stop both
monitoring status    # check if running
```

Or use systemd directly:

```bash
systemctl --user start prometheus.service
systemctl --user start grafana.service
systemctl --user stop prometheus.service
systemctl --user stop grafana.service
```

To enable auto-start on boot (when ready for production):

```bash
systemctl --user enable prometheus.service grafana.service
loginctl enable-linger $USER
```

`enable-linger` ensures user services start at boot before you log in — without it, the services only start after your first login.

To revert back to manual start:

```bash
systemctl --user disable prometheus.service grafana.service
```

### Endpoints

| Service | URL | Purpose |
|---|---|---|
| Prometheus | `http://localhost:9090` | Metric queries, targets status, alerts |
| Grafana | `http://localhost:3001` | Dashboards and graphs |
| node_exporter (per VM) | `http://VM_IP:9100/metrics` | Raw metrics endpoint |

### Files

| File | Location | Purpose |
|---|---|---|
| `prometheus.yml` | `~/monitoring/prometheus/prometheus.yml` | Prometheus scrape config (VM targets) |
| `grafana-datasource.yml` | `~/monitoring/grafana/provisioning/datasources/` | Auto-configures Prometheus in Grafana |
| `install-node-exporter.yml` | `~/ansible/install-node-exporter.yml` | Ansible playbook to deploy node_exporter |
| `monitoring` | `~/.local/bin/monitoring` | Start/stop/status convenience script |

</details>

<details>
<summary><strong>🔄 CI/CD</strong> — GitHub Actions + GitLab CI/CD deploy to KVM/QEMU VMs</summary>

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

</details>

---

<details>
<summary><strong>🤖 Local AI Setup</strong> — Ollama, Open WebUI, SearXNG, ComfyUI, TTS, Continue</summary>

Six modules that set up a fully offline AI stack for coding, text, image/video generation, voice synthesis, and web search. All modules auto-detect hardware — on NVIDIA systems they install CUDA-accelerated versions and pull larger models (including Gemma 4 26B MoE and 31B Dense).

### Hardware Support

| Component | Laptop — Ryzen 7 8845HS / Radeon 780M / 32 GB DDR5 | PC — i9-12900KS / RTX 3060 12 GB / 32 GB DDR5 |
|---|---|---|
| LLM inference (14B) | CPU, ~12-18 tok/s | CUDA GPU, ~35-45 tok/s |
| LLM inference (26B–32B) | CPU, ~4-8 tok/s (usable but slow) | Partial GPU offload, ~10-22 tok/s |
| Image generation | CPU, SD 1.5 (~90 sec/image) | CUDA, SDXL (~10 sec/image) |
| Video generation | CPU, AnimateDiff (~20 min/clip) | CUDA, AnimateDiff (~2 min/clip) |
| TTS | Piper + Kokoro (real-time) | Piper + Kokoro + F5-TTS (real-time) |

#### Laptop — Model Capabilities (CPU inference, 32 GB RAM)

The Radeon 780M is an integrated GPU sharing system RAM — Ollama runs models on CPU. The 8845HS (8-core/16-thread Zen 4) with fast DDR5 is one of the better CPUs for local inference. ~28-29 GB available after OS overhead.

| Model | Size | RAM Used | Speed | Daily use? |
|---|---|---|---|---|
| `qwen2.5-coder:14b` | 9 GB | 9/29 GB | ~12-18 tok/s | ✅ Primary coding model |
| `gemma4:e4b` | 9.6 GB | 9.6/29 GB | ~12-18 tok/s | ✅ Best all-rounder (128K ctx, vision, thinking) |
| `qwen2.5:14b` | 9 GB | 9/29 GB | ~12-18 tok/s | ✅ Solid for general text |
| `deepseek-r1:14b` | 9 GB | 9/29 GB | ~12-18 tok/s | ✅ Best for step-by-step reasoning |
| `phi4:14b` | 9 GB | 9/29 GB | ~12-18 tok/s | ✅ Good for summarization |
| `gemma4:26b` | 18 GB | 18/29 GB | ~5-8 tok/s | ⚠️ Works but sluggish — close other apps |
| `gemma4:31b` | 20 GB | 20/29 GB | ~4-6 tok/s | ⚠️ Usable but slow — not for daily use |

You can load two 9 GB models simultaneously (e.g., Qwen Coder for autocomplete + Gemma E4B for chat). Disk needed: ~46 GB for the 5 pulled models.

#### PC — Model Capabilities (RTX 3060 12 GB VRAM + 32 GB RAM)

Models ≤12 GB fit entirely in VRAM for maximum speed. Larger models use partial GPU offload (12 GB VRAM + rest in system RAM).

| Model | Size | Fits in 12 GB VRAM? | Speed | Daily use? |
|---|---|---|---|---|
| `qwen2.5-coder:14b` | 9 GB | ✅ Fully on GPU | ~35-45 tok/s | ✅ Blazing fast |
| `gemma4:e4b` | 9.6 GB | ✅ Fully on GPU | ~30-40 tok/s | ✅ Blazing fast |
| `qwen2.5:14b` | 9 GB | ✅ Fully on GPU | ~35-45 tok/s | ✅ Blazing fast |
| `deepseek-r1:14b` | 9 GB | ✅ Fully on GPU | ~35-45 tok/s | ✅ Blazing fast |
| `phi4:14b` | 9 GB | ✅ Fully on GPU | ~35-45 tok/s | ✅ Blazing fast |
| `gemma4:26b` | 18 GB | ⚡ Partial (12+6) | ~15-22 tok/s | ✅ Good — MoE = only 3.8B active params |
| `gemma4:31b` | 20 GB | ⚡ Partial (12+8) | ~10-15 tok/s | ✅ Noticeably slower but highest quality |
| `qwen2.5:32b` | 20 GB | ⚡ Partial (12+8) | ~10-15 tok/s | ✅ Solid, but Gemma 31B beats it on benchmarks |

The 26B MoE is the best "stretch" model — its architecture means partial offload works better than dense models. Disk needed: ~104 GB for all 8 models.

#### Future Upgrade Guide

**PC — upgrade priority:**

| Priority | Upgrade | Why | Impact |
|---|---|---|---|
| 🥇 1st | **GPU → 16 GB VRAM** (e.g., RTX 4070 Ti Super, RTX 5070 Ti) | 12 GB VRAM is the main bottleneck — 26B/31B/32B models spill into system RAM, halving speed | 26B–31B models: **2-3x faster**. ComfyUI SDXL: faster renders. 14B models: unchanged. |
| 🥈 2nd | **RAM → 64 GB DDR5** | When large models partially offload, they eat system RAM. 64 GB lets you run a 31B model + ComfyUI + containers simultaneously without swapping | Multi-model + multi-app workflows without slowdowns |
| 🏆 Dream | **GPU → 32 GB VRAM** (e.g., RTX 5090) | Every model fits entirely in VRAM. `gemma4:31b` (20 GB) runs at full GPU speed | Maximum speed on everything. No offloading ever. |

The i9-12900KS CPU is not a bottleneck — don't touch it.

**Laptop — upgrade priority:**

| Priority | Upgrade | Why | Impact |
|---|---|---|---|
| 🥇 1st | **RAM → 64 GB DDR5** (if user-upgradeable) | More RAM = run 26B–31B models comfortably + keep browser/apps open | 26B models go from "close everything" to comfortable |
| 🥈 Optional | **eGPU enclosure + desktop GPU** (Thunderbolt 4) | GPU inference on the laptop at ~70% of desktop GPU speed | 14B models: ~15 → ~25-30 tok/s. Expensive (~$300 enclosure + GPU). |

The 8845HS CPU is already top-tier for CPU inference — not upgradeable internally.

**When to upgrade:**

| Trigger | Action |
|---|---|
| Always waiting on 26B/31B responses on PC | GPU → 16 GB VRAM |
| Can't run Ollama + ComfyUI + containers simultaneously on PC | RAM → 64 GB |
| Want 26B+ models comfortably on laptop | RAM → 64 GB |
| New model generation drops (Gemma 5, Qwen 3, etc.) with 40-50B sweet spots | GPU upgrade becomes more urgent |

### Prerequisites

On **NVIDIA systems**, install the proprietary drivers before running the AI modules so that GPU detection works:

```bash
sudo dnf install -y akmod-nvidia
sudo reboot
```

On **AMD systems**, no extra drivers are needed — Fedora includes full support out of the box.

### Quick Start — Install All AI Modules

```bash
./setup.sh ollama openwebui searxng comfyui tts continue
```

Or run them individually as described below.

---

<details>
<summary><strong>21. Ollama — LLM Runtime + Models</strong></summary>

```bash
./setup.sh ollama
```

Installs [Ollama](https://ollama.com/) and pulls quantized LLM models for local inference.

| What it does | Details |
|---|---|
| Installs Ollama | Via official install script |
| Enables service | `systemctl enable --now ollama` |
| Pulls coding model | `qwen2.5-coder:14b` (~9 GB) |
| Pulls general model | `qwen2.5:14b` (~9 GB) |
| Pulls reasoning model | `deepseek-r1:14b` (~9 GB) |
| Pulls summarization model | `phi4:14b` (~9 GB) |
| Pulls multimodal model | `gemma4:e4b` (~9.6 GB) |
| Pulls MoE model (NVIDIA only) | `gemma4:26b` (~18 GB) |
| Pulls dense flagship (NVIDIA only) | `gemma4:31b` (~20 GB) |
| Pulls large model (NVIDIA only) | `qwen2.5:32b` (~20 GB) |
| API endpoint | `http://localhost:11434` |

#### Model Ranking — Which Model to Use

All models run fully offline via Ollama. No data leaves your machine. Gemma 4 models are licensed under Apache 2.0; others have their own permissive open licenses.

**Tier 1 — Best in class (pick one per task)**

| Rank | Model | Size | Best for | Why pick this one |
|---|---|---|---|---|
| 🥇 | `gemma4:31b` | 20 GB | **Everything** (NVIDIA only) | Highest benchmarks across the board — MMLU Pro 85%, AIME 89%, 256K context, vision, thinking mode. The best local model if your GPU can fit it. |
| 🥇 | `qwen2.5-coder:14b` | 9 GB | **Code** (all systems) | Purpose-built for coding — autocomplete, refactoring, generation. HumanEval ~80%. No other 14B model matches it for code. |
| 🥇 | `gemma4:26b` | 18 GB | **Reasoning + multimodal** (NVIDIA) | MoE with only 3.8B active params = fast despite 26B total. 256K context, vision, thinking mode. GPQA 82%, LiveCodeBench 77%. |

**Tier 2 — Strong alternatives**

| Rank | Model | Size | Best for | Why pick this one |
|---|---|---|---|---|
| 🥈 | `gemma4:e4b` | 9.6 GB | **General + vision + audio** (all systems) | Best all-rounder at this size — 128K context, image+audio input, thinking mode. Replaces separate models for text, vision, and summarization. |
| 🥈 | `deepseek-r1:14b` | 9 GB | **Chain-of-thought reasoning** (all systems) | Specialized reasoning model — shows step-by-step thinking. Better than Gemma E4B for pure logic puzzles and debugging on CPU-only systems. |

**Tier 3 — Solid options**

| Rank | Model | Size | Best for | Why pick this one |
|---|---|---|---|---|
| 🥉 | `qwen2.5:14b` | 9 GB | **General text** (all systems) | Reliable for chat, translation, writing. Slightly higher MMLU than Gemma E4B (~79 vs ~69) but lacks vision/audio and has shorter context (32K). |
| 🥉 | `phi4:14b` | 9 GB | **Instruction following** (all systems) | Good at following detailed instructions and summarizing. If Gemma E4B's 128K context isn't enough reason to switch, Phi-4 is still solid. |
| 🥉 | `qwen2.5:32b` | 20 GB | **Large text** (NVIDIA only) | Strong general-purpose 32B. However, Gemma 4 31B matches or beats it on every benchmark at the same size. |

**Quick decision guide:**

| Your hardware | Your task | Use this model |
|---|---|---|
| Any | Writing code, autocomplete | `qwen2.5-coder:14b` |
| Any | General chat, vision, summarization | `gemma4:e4b` |
| Any | Hard debugging, step-by-step reasoning | `deepseek-r1:14b` |
| NVIDIA GPU | Best overall quality | `gemma4:31b` |
| NVIDIA GPU | Fast reasoning + vision | `gemma4:26b` (MoE — fast inference) |

**Usage:**

```bash
ollama run qwen2.5-coder:14b    # coding
ollama run gemma4:e4b            # general chat, vision, thinking
ollama run deepseek-r1:14b       # hard reasoning / debugging
ollama run gemma4:26b            # fast reasoning + vision (NVIDIA)
ollama run gemma4:31b            # highest quality (NVIDIA)
ollama run qwen2.5:14b           # general text (alternative)
ollama run phi4:14b              # summarization (alternative)
ollama list                      # see all downloaded models
ollama ps                        # see currently loaded models
```

**Management:**

```bash
systemctl status ollama         # check service status
systemctl restart ollama        # restart
ollama pull <model>             # download additional models
ollama rm <model>               # delete a model
```

</details>

<details>
<summary><strong>22. Open WebUI — Chat Interface</strong></summary>

```bash
./setup.sh openwebui
```

Runs [Open WebUI](https://github.com/open-webui/open-webui) in a Podman container — a ChatGPT-like web interface for your local Ollama models.

| What it does | Details |
|---|---|
| Runs Podman container | `open-webui` on port 3000 |
| Connects to Ollama | Via `host.containers.internal:11434` |
| Systemd user service | Auto-starts on login |
| Data volume | `open-webui` (Podman volume) |
| URL | `http://localhost:3000` |

**First-time setup:**

1. Open `http://localhost:3000` in your browser
2. Create an admin account (first user becomes admin)
3. Select a model from the dropdown and start chatting

**Features:**
- Upload documents for RAG (summarize/query PDFs, text files)
- Multiple conversation threads with history
- Model switching mid-conversation
- Web search integration (see SearXNG below)

**Management:**

```bash
systemctl --user status open-webui    # check status
systemctl --user restart open-webui   # restart
podman logs -f open-webui             # live logs
```

</details>

<details>
<summary><strong>23. SearXNG — AI Web Search</strong></summary>

```bash
./setup.sh searxng
```

Runs [SearXNG](https://github.com/searxng/searxng) in a Podman container — a privacy-respecting meta search engine that aggregates results from Google, Bing, DuckDuckGo, and more.

| What it does | Details |
|---|---|
| Runs Podman container | `searxng` on port 8888 |
| Systemd user service | Auto-starts on login |
| Data volume | `searxng-data` (Podman volume) |
| URL | `http://localhost:8888` |

**Connecting to Open WebUI:**

1. Open `http://localhost:3000` (Open WebUI)
2. Go to **Admin → Settings → Web Search**
3. Enable web search
4. Select **SearXNG** as the provider
5. Set the URL to `http://localhost:8888`

Now when you ask questions in Open WebUI, the AI can search the internet and synthesize results — like a local Perplexity.

**Management:**

```bash
systemctl --user status searxng       # check status
systemctl --user restart searxng      # restart
podman logs -f searxng                # live logs
```

</details>

<details>
<summary><strong>24. ComfyUI — Image & Video Generation</strong></summary>

```bash
./setup.sh comfyui
```

Clones [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with a Python virtual environment, custom nodes for video generation, and pre-downloaded model checkpoints.

| What it does | Details |
|---|---|
| Clones ComfyUI | To `~/comfyui` |
| Creates Python venv | With PyTorch (CUDA or CPU) |
| Installs ComfyUI Manager | Browse/install nodes from the UI |
| Installs AnimateDiff Evolved | For video generation |
| Downloads SD 1.5 | ~4 GB (both systems) |
| Downloads SDXL (NVIDIA only) | ~7 GB (higher quality) |
| Creates launcher script | `~/comfyui/start.sh` |
| URL | `http://localhost:8188` |

**Usage:**

```bash
~/comfyui/start.sh              # start ComfyUI
# Then open http://localhost:8188 in your browser
```

**Image generation:**
1. Open ComfyUI in the browser
2. The default workflow generates images with SD 1.5
3. Type a prompt, click "Queue Prompt"
4. On NVIDIA, switch to the SDXL checkpoint for higher quality

**Video generation (AnimateDiff):**
1. In ComfyUI, load an AnimateDiff workflow (available in ComfyUI Manager examples)
2. AnimateDiff extends SD 1.5/SDXL to produce short animated clips (2-3 seconds)
3. Expect ~2 min per clip on NVIDIA, ~15-20 min on CPU

**Installing additional models:**
Use ComfyUI Manager (the puzzle piece icon in the UI) to browse and install additional checkpoints, LoRAs, and custom nodes.

</details>

<details>
<summary><strong>25. TTS — Text-to-Speech</strong></summary>

```bash
./setup.sh tts
```

Installs multiple TTS engines for local voice synthesis.

| Engine | Speed | Quality | Notes |
|---|---|---|---|
| **Piper** | Real-time | Good | Lightweight, many voices/languages |
| **Kokoro** | Real-time | Very good | Natural-sounding, expressive |
| **F5-TTS** (NVIDIA only) | Real-time | Excellent | Voice cloning from a 15-sec sample |

**Usage — Piper:**

```bash
echo 'Hello world' | piper \
  --model ~/.local/share/piper-models/en_US-lessac-medium.onnx \
  --output_file speech.wav

# Play it
aplay speech.wav
```

**Usage — Kokoro:**

```python
import kokoro
# See kokoro documentation for API usage
```

**Usage — F5-TTS (NVIDIA only, voice cloning):**

```bash
# Provide a 15-second voice sample and text to clone
f5-tts --ref-audio sample.wav --ref-text "Hello" --gen-text "Your text here" --output out.wav
```

**Integrating with Open WebUI:**
Open WebUI supports TTS — go to **Settings → Audio** to configure a local TTS engine for the AI to read responses aloud.

</details>

<details>
<summary><strong>26. Continue — AI Coding Assistant</strong></summary>

```bash
./setup.sh continue
```

Installs [VSCodium](https://vscodium.com/) and the [Continue](https://continue.dev/) extension, pre-configured to use your local Ollama models.

| What it does | Details |
|---|---|
| Installs VSCodium | Via COPR (`zeno/vscodium`) |
| Installs Continue extension | From Open VSX Registry |
| Writes config | `~/.config/continue/config.json` |
| Chat models | Qwen 2.5 Coder 14B, Gemma 4 E4B, Qwen 2.5 14B, DeepSeek R1 14B, Phi-4 14B |
| Autocomplete model | `qwen2.5-coder:14b` (local) |

**Switching models in Continue:**

All four models are pre-configured. In the Continue chat panel (`Ctrl+L`), click the model name at the top to switch between:

| Model in dropdown | When to use |
|---|---|
| Qwen 2.5 Coder 14B | Default — writing and editing code |
| Gemma 4 E4B | Image/code questions, large file context (128K), thinking mode |
| Qwen 2.5 14B | General questions about your project |
| DeepSeek R1 14B | Complex bugs, reasoning through logic |
| Phi-4 14B | Summarizing code, explaining large files |

**Keyboard shortcuts:**

| Shortcut | Action |
|---|---|
| `Ctrl+L` | Open Continue chat panel |
| `Ctrl+I` | Inline edit (select code first) |
| `Tab` | Accept autocomplete suggestion |

**First-time setup:**

1. Make sure Ollama is running (`systemctl status ollama`)
2. Open VSCodium (`codium`)
3. Continue will detect the local config and connect to Ollama automatically
4. Press `Ctrl+L` to start chatting about your code

**Changing models:**

Edit `~/.config/continue/config.json` to add or switch models. Any model available in Ollama can be used:

```bash
ollama pull codellama:13b   # pull a new model
# Then add it to config.json
```

</details>

<details>
<summary><strong>29. Tauri — Rust, Node.js & Tauri 2 Dev Environment</strong></summary>

```bash
./setup.sh tauri
```

Installs everything needed to build [Tauri 2](https://v2.tauri.app/) desktop apps on Fedora.

| What it does | Details |
|---|---|
| Tauri system deps | `webkit2gtk4.1-devel`, `openssl-devel`, `gtk3-devel`, `libsoup3-devel`, `javascriptcoregtk4.1-devel` + more |
| Rust toolchain | Via [rustup](https://rustup.rs/) (rustc + cargo) |
| Node.js + npm | Via dnf (for frontend build) |
| Tauri CLI | `cargo install tauri-cli` |

**After install:**

```bash
cd ~/your-project
npm install
npm run tauri dev      # run in dev mode
npm run tauri build    # produce a release binary
```

</details>

### AI Modules — Ports

| Service | Port | URL |
|---|---|---|
| Ollama API | 11434 | `http://localhost:11434` |
| Open WebUI | 3000 | `http://localhost:3000` |
| SearXNG | 8888 | `http://localhost:8888` |
| ComfyUI | 8188 | `http://localhost:8188` |

### AI Modules — File Locations

| File / Directory | Purpose |
|---|---|
| `~/comfyui/` | ComfyUI installation + models |
| `~/comfyui/start.sh` | ComfyUI launcher script |
| `~/comfyui/models/checkpoints/` | SD 1.5, SDXL model files |
| `~/.config/continue/config.json` | Continue extension config |
| `~/.local/share/piper-models/` | Piper voice model files |
| `~/.config/systemd/user/open-webui.service` | Open WebUI auto-start service |
| `~/.config/systemd/user/searxng.service` | SearXNG auto-start service |

### Browser AI Alternative — DeepSeek (Free, Unlimited)

The local AI setup covers most daily needs, but for complex coding problems where a larger model helps, [DeepSeek](https://chat.deepseek.com/) is the best free browser-based option — unlimited messages with no daily caps.

> **Privacy note:** All cloud AI services (ChatGPT, Copilot, Gemini, DeepSeek) send your data to external servers. If privacy is a concern, use the local Ollama setup for sensitive code and reserve browser AI for general questions, learning, and personal projects.

**How to use it:**

1. Go to [chat.deepseek.com](https://chat.deepseek.com/) and create a free account
2. Select **DeepThink (R1)** mode for complex reasoning, debugging, and algorithm problems
3. Use the default mode for quick code questions and general chat

**Tips for coding with DeepSeek:**

- Paste your code and error messages directly — it handles large snippets well
- Use **DeepThink** for hard problems — it shows step-by-step reasoning before answering
- Ask it to explain *why* something works, not just *what* to write — you'll learn more
- For multi-file context, describe the project structure before pasting code

**Recommended workflow:**

| Problem complexity | Tool |
|---|---|
| Quick autocomplete / inline edits | VSCodium + Continue + Ollama (local) |
| Moderate questions about your code | Open WebUI + Ollama (local) — try `gemma4:e4b` for image/screenshot questions |
| Complex bugs, architecture, algorithms | `gemma4:31b` or `gemma4:26b` locally (NVIDIA), or DeepSeek in browser (free, unlimited) |

</details>

---

<details>
<summary><strong>📸 Adding Screenshots</strong></summary>

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
| `rofi.png` | *(removed — rofi replaced by GNOME built-in search)* |
| `gitlab.png` | GitLab CE login or project page |

Then uncomment the `![...](screenshots/...)` lines in this README.

You can capture a GIF with:
```bash
# Install peek (GIF recorder)
flatpak install flathub com.uploadedlobster.peek
```

</details>

---

## License

See [LICENSE](LICENSE).

<details>
<summary><strong>📋 tmux Cheatsheet</strong></summary>

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

</details>

<details>
<summary><strong>📂 File Locations</strong></summary>

| File | Purpose |
|---|---|
| `~/.tmux.conf` | tmux configuration |
| `~/.tmux/plugins/` | TPM and installed plugins |
| `~/.local/bin/tmux-dev` | Dev session layout script |
| `~/.bashrc` | Prompt customization + tmux auto-attach |
| `/etc/dconf/db/gdm.d/99-capslock-fix` | GDM keyboard settings |
| `/etc/dconf/profile/gdm` | GDM dconf profile |

</details>

<details>
<summary><strong>🔁 Re-running the Script</strong></summary>

The script is safe to run multiple times. Each module checks whether its changes are already applied and skips if so. The tmux config (`~/.tmux.conf`) is backed up with a timestamp before overwriting.

You can re-run individual modules too:

```bash
./setup.sh tmux      # re-run just tmux setup
./setup.sh prompt    # re-apply the bash prompt
```

</details>

<details>
<summary><strong>🗂️ Project Structure</strong></summary>

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
  power.sh                      # Sleep/shutdown on inactivity
  dock.sh                       # Dash to Dock (auto-hide, bottom)
  windowfx.sh                   # Pixelate open/close animations
  wallpaper.sh                  # Solid black 4K wallpaper
  userpic.sh                    # GitHub avatar as user pic
  tiling.sh                     # Tiling Assistant + gaps + borders
  topbar.sh                     # Fedora logo, Vitals, weather, tray
  appgrid.sh                    # App grid category folders
  apps.sh                       # User apps (Discord, etc.)
  ollama.sh                     # Ollama + AI models
  openwebui.sh                  # Open WebUI (Podman container)
  searxng.sh                    # SearXNG search engine (Podman container)
  comfyui.sh                    # ComfyUI + AnimateDiff (image/video)
  tts.sh                        # Text-to-speech (Piper, Kokoro, F5-TTS)
  continue.sh                   # VSCodium + Continue AI extension
  tauri.sh                      # Rust, Node.js & Tauri 2 dev environment
setup-runner.sh                 # One-time GitHub Actions runner setup
.github/workflows/deploy.yml   # CI/CD pipeline
```

Each module is a standalone `.sh` file containing a single `mod_<name>()` function. The main `setup.sh` sources all modules and runs them in order (or only the ones you specify).

</details>

<details>
<summary><strong>⚙️ CI/CD Pipeline</strong> — GitHub Actions + self-hosted runner</summary>

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

</details>
