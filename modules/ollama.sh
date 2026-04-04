# shellcheck shell=bash
mod_ollama() {
    echo "[ollama] Installing Ollama + AI models..."

    # --- Install Ollama ---
    if command -v ollama &>/dev/null; then
        echo "  Ollama is already installed, skipping."
    else
        echo "  Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
        echo "  Ollama installed."
    fi

    # Enable and start the Ollama service
    if ! systemctl is-active --quiet ollama; then
        echo "  Enabling ollama service..."
        sudo systemctl enable --now ollama
    fi

    # --- Detect GPU for model selection ---
    local has_nvidia=false
    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        has_nvidia=true
        echo "  NVIDIA GPU detected — models will offload to GPU."
    else
        echo "  No NVIDIA GPU detected — models will run on CPU."
    fi

    # --- Pull models ---
    # Coding model
    if ollama list | grep -q 'qwen2.5-coder:14b'; then
        echo "  qwen2.5-coder:14b already pulled, skipping."
    else
        echo "  Pulling qwen2.5-coder:14b (coding, ~9 GB)..."
        ollama pull qwen2.5-coder:14b
        echo "  qwen2.5-coder:14b ready."
    fi

    # General / text-summary model
    if ollama list | grep -q 'qwen2.5:14b'; then
        echo "  qwen2.5:14b already pulled, skipping."
    else
        echo "  Pulling qwen2.5:14b (text/summary, ~9 GB)..."
        ollama pull qwen2.5:14b
        echo "  qwen2.5:14b ready."
    fi

    # --- Alternative models ---
    # DeepSeek R1 distill — strong at reasoning, debugging, analysis
    if ollama list | grep -q 'deepseek-r1:14b'; then
        echo "  deepseek-r1:14b already pulled, skipping."
    else
        echo "  Pulling deepseek-r1:14b (reasoning/debugging, ~9 GB)..."
        ollama pull deepseek-r1:14b
        echo "  deepseek-r1:14b ready."
    fi

    # Phi-4 — strong at summarization and instruction-following
    if ollama list | grep -q 'phi4:14b'; then
        echo "  phi4:14b already pulled, skipping."
    else
        echo "  Pulling phi4:14b (summarization/instructions, ~9 GB)..."
        ollama pull phi4:14b
        echo "  phi4:14b ready."
    fi

    # --- Google Gemma 4 models (Apache 2.0, multimodal, thinking mode) ---
    # Gemma 4 E4B — 128K context, vision+audio, thinking mode, great all-rounder
    if ollama list | grep -q 'gemma4:e4b'; then
        echo "  gemma4:e4b already pulled, skipping."
    else
        echo "  Pulling gemma4:e4b (multimodal/thinking, ~9.6 GB)..."
        ollama pull gemma4:e4b
        echo "  gemma4:e4b ready."
    fi

    # On NVIDIA: also pull the larger models
    if [[ "$has_nvidia" == true ]]; then
        if ollama list | grep -q 'qwen2.5:32b'; then
            echo "  qwen2.5:32b already pulled, skipping."
        else
            echo "  Pulling qwen2.5:32b (text/summary large, ~20 GB)..."
            ollama pull qwen2.5:32b
            echo "  qwen2.5:32b ready."
        fi

        # Gemma 4 26B MoE — 256K context, vision, thinking, only 3.8B active params
        if ollama list | grep -q 'gemma4:26b'; then
            echo "  gemma4:26b already pulled, skipping."
        else
            echo "  Pulling gemma4:26b (MoE multimodal/reasoning, ~18 GB)..."
            ollama pull gemma4:26b
            echo "  gemma4:26b ready."
        fi

        # Gemma 4 31B Dense — 256K context, vision, highest quality
        if ollama list | grep -q 'gemma4:31b'; then
            echo "  gemma4:31b already pulled, skipping."
        else
            echo "  Pulling gemma4:31b (dense flagship, ~20 GB)..."
            ollama pull gemma4:31b
            echo "  gemma4:31b ready."
        fi
    fi

    echo "  Ollama setup complete. API available at http://localhost:11434"
}
