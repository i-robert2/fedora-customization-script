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