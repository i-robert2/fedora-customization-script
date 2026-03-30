# shellcheck shell=bash
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

STEPS=10
STEP=$(( MID / STEPS ))
(( STEP < 1 )) && STEP=1

tput civis 2>/dev/null

# Slide UFO from left to center (~0.1 s)
for (( p=0; p<=MID; p+=STEP )); do
    printf '\r\e[2K%*s%b' "$p" "" "$UFO"
    sleep 0.01
done
printf '\r\e[2K%*s%b' "$MID" "" "$UFO"
sleep 0.02

# Replace with centered alien message (stays in scrollback)
MSG="👽 howdy there!"
MSG_W=15
MSG_PAD=$(( (COLS - MSG_W) / 2 ))
(( MSG_PAD < 0 )) && MSG_PAD=0
printf '\r\e[2K'
tput cnorm 2>/dev/null
printf '%*s%b\n' "$MSG_PAD" "" "${G}${MSG}${RS}"
UFOSCRIPT
    chmod +x "$GREETING_SCRIPT"
    echo "  ufo-greeting script created at ~/.local/bin/ufo-greeting"

    # Remove old greeting block from .bashrc
    sed -i '/# ── UFO greeting/,/# ── end UFO greeting/d' "$HOME/.bashrc" 2>/dev/null || true

    # Append new block — simple: play on every new interactive shell
    cat >> "$HOME/.bashrc" <<'GREETING_EOF'

# ── UFO greeting ──────────────────────────────────────────────────────
if [ -t 0 ] && command -v ufo-greeting &>/dev/null; then
    ufo-greeting
fi
# ── end UFO greeting ──────────────────────────────────────────────────
GREETING_EOF
    echo "  UFO greeting added to ~/.bashrc."
}