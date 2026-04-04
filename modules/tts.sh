# shellcheck shell=bash
mod_tts() {
    echo "[tts] Installing local text-to-speech (Piper + Kokoro)..."

    # --- Dependencies ---
    if ! command -v python3 &>/dev/null; then
        echo "  Installing Python 3..."
        sudo dnf install -y python3 python3-pip python3-venv
    fi

    # Ensure Python headers are available (needed for numpy/kokoro compilation)
    if ! rpm -q python3-devel &>/dev/null; then
        echo "  Installing python3-devel (build headers)..."
        sudo dnf install -y python3-devel gcc gcc-c++
    fi

    # --- Install Piper TTS (fast, lightweight, real-time on CPU) ---
    if command -v piper &>/dev/null || pip show piper-tts &>/dev/null 2>&1; then
        echo "  Piper TTS is already installed, skipping."
    else
        echo "  Installing Piper TTS..."
        pip install --user --quiet piper-tts
        echo "  Piper TTS installed."
    fi

    # --- Download a default Piper voice model ---
    local piper_models_dir="$HOME/.local/share/piper-models"
    mkdir -p "$piper_models_dir"

    local voice_file="$piper_models_dir/en_US-lessac-medium.onnx"
    if [[ -f "$voice_file" ]]; then
        echo "  Piper voice model already downloaded."
    else
        echo "  Downloading Piper voice model (en_US-lessac-medium)..."
        curl -fSL -o "$voice_file" \
            "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx"
        curl -fSL -o "${voice_file}.json" \
            "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json"
        echo "  Piper voice model downloaded."
    fi

    # --- Install Kokoro TTS (higher quality, natural-sounding) ---
    if pip show kokoro &>/dev/null 2>&1; then
        echo "  Kokoro TTS is already installed, skipping."
    else
        echo "  Installing Kokoro TTS..."
        pip install --user --quiet kokoro soundfile
        echo "  Kokoro TTS installed."
    fi

    # --- Install F5-TTS on NVIDIA systems (voice cloning) ---
    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        if pip show f5-tts &>/dev/null 2>&1; then
            echo "  F5-TTS is already installed, skipping."
        else
            echo "  Installing F5-TTS (voice cloning, CUDA)..."
            pip install --user --quiet f5-tts
            echo "  F5-TTS installed."
        fi
    fi

    echo "  TTS setup complete."
    echo "  Usage examples:"
    echo "    Piper:  echo 'Hello world' | piper --model $voice_file --output_file out.wav"
    echo "    Kokoro: python3 -c \"import kokoro; ...\""
}
