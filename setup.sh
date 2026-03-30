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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Module registry ───────────────────────────────────────────────────────
# Order matters: this is the execution order when running all modules.
ALL_MODULES=(ghostty font keybinding capslock tmux prompt greeting tools rofi power dock windowfx wallpaper userpic tiling topbar appgrid apps gitlab)

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
    [windowfx]="Pixelate animations for window open/close"
    [wallpaper]="Solid black 4K wallpaper"
    [userpic]="Set user avatar from GitHub profile"
    [tiling]="Tiling: halves, quarters, no-gap halves/fullscreen + gaps + white borders"
    [topbar]="Fedora logo menu, Vitals, Advanced Weather, tray, clock-right"
    [appgrid]="Organize app grid into category folders"
    [apps]="Install user apps (Discord, KVM/QEMU + virt-manager)"
    [gitlab]="Install GitLab CE (self-hosted, local Podman container)"
)

# ── Source all module files ───────────────────────────────────────────────
for mod in "${ALL_MODULES[@]}"; do
    source "$SCRIPT_DIR/modules/${mod}.sh"
done

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
