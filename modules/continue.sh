# shellcheck shell=bash
mod_continue() {
    echo "[continue] Installing Continue AI coding assistant for VSCodium..."

    # --- Install VSCodium if not present ---
    if ! command -v codium &>/dev/null; then
        echo "  VSCodium not found. Installing via COPR..."
        sudo dnf install -y 'dnf-command(copr)'
        sudo dnf copr enable -y zeno/vscodium
        sudo dnf install -y codium
        echo "  VSCodium installed."
    else
        echo "  VSCodium is already installed."
    fi

    # --- Install Continue extension ---
    if codium --list-extensions 2>/dev/null | grep -qi 'continue.continue'; then
        echo "  Continue extension is already installed, skipping."
    else
        echo "  Installing Continue extension..."
        codium --install-extension Continue.continue
        echo "  Continue extension installed."
    fi

    # --- Write Continue config pointing to local Ollama ---
    local config_dir="$HOME/.config/continue"
    local config_file="$config_dir/config.json"
    if [[ -f "$config_file" ]]; then
        echo "  Continue config already exists, skipping overwrite."
    else
        mkdir -p "$config_dir"
        cat > "$config_file" <<'CONFIG'
{
  "models": [
    {
      "title": "Qwen 2.5 Coder 14B (local)",
      "provider": "ollama",
      "model": "qwen2.5-coder:14b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "Gemma 4 E4B (multimodal/thinking)",
      "provider": "ollama",
      "model": "gemma4:e4b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "Qwen 2.5 14B (local)",
      "provider": "ollama",
      "model": "qwen2.5:14b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "DeepSeek R1 14B (reasoning)",
      "provider": "ollama",
      "model": "deepseek-r1:14b",
      "apiBase": "http://localhost:11434"
    },
    {
      "title": "Phi-4 14B (summarization)",
      "provider": "ollama",
      "model": "phi4:14b",
      "apiBase": "http://localhost:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Qwen 2.5 Coder 14B (autocomplete)",
    "provider": "ollama",
    "model": "qwen2.5-coder:14b",
    "apiBase": "http://localhost:11434"
  }
}
CONFIG
        echo "  Continue config written to $config_file"
    fi

    echo "  Continue setup complete."
    echo "  Open VSCodium and use Ctrl+L to chat, Ctrl+I for inline edits."
    echo "  Make sure Ollama is running (systemctl status ollama)."
}
