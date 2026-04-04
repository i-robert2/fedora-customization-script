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
    # Kokoro's dependencies (thinc/blis/spacy) don't build on Python 3.14 + GCC 15,
    # so we install it in a venv with Python 3.12 (same approach as PaddleOCR).
    local kokoro_venv="$HOME/.local/share/kokoro-venv"
    if [[ -x "$kokoro_venv/bin/python" ]] && "$kokoro_venv/bin/python" -c "import kokoro" &>/dev/null 2>&1; then
        echo "  Kokoro TTS is already installed, skipping."
    else
        echo "  Installing Kokoro TTS..."
        local py_bin=""
        for candidate in python3.12 python3.11 python3.10; do
            if command -v "$candidate" &>/dev/null; then
                py_bin="$candidate"
                break
            fi
        done

        if [[ -z "$py_bin" ]]; then
            echo "  System Python is too new for Kokoro. Installing Python 3.12..."
            sudo dnf install -y python3.12 2>/dev/null || true
            if command -v python3.12 &>/dev/null; then
                py_bin="python3.12"
            else
                echo "  ⚠ Could not install Python 3.12. Skipping Kokoro."
                echo "    (Kokoro dependencies do not yet support your Python/GCC version)"
            fi
        fi

        if [[ -n "$py_bin" ]]; then
            echo "  Using $py_bin for Kokoro virtualenv..."
            "$py_bin" -m venv "$kokoro_venv"
            "$kokoro_venv/bin/pip" install --upgrade pip

            # Install CPU-only PyTorch first to avoid downloading ~1 GB of unused CUDA libraries.
            # On NVIDIA systems, install the CUDA version instead.
            if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
                "$kokoro_venv/bin/pip" install torch --index-url https://download.pytorch.org/whl/cu124
            else
                "$kokoro_venv/bin/pip" install torch --index-url https://download.pytorch.org/whl/cpu
            fi

            if "$kokoro_venv/bin/pip" install kokoro soundfile; then
                # Create a wrapper so kokoro is importable from a simple script
                mkdir -p "$HOME/.local/bin"
                cat > "$HOME/.local/bin/kokoro-tts" <<'WRAPPER'
#!/usr/bin/env bash
exec "$HOME/.local/share/kokoro-venv/bin/python" -c "
import sys
from kokoro import KPipeline
pipeline = KPipeline(lang_code='a')
for audio, _ in pipeline(sys.stdin.read(), voice='af_heart'):
    import soundfile as sf
    sf.write(sys.argv[1] if len(sys.argv) > 1 else 'kokoro-out.wav', audio, 24000)
    break
print('Saved to', sys.argv[1] if len(sys.argv) > 1 else 'kokoro-out.wav')
" "$@"
WRAPPER
                chmod +x "$HOME/.local/bin/kokoro-tts"
                echo "  Kokoro TTS installed (venv: $kokoro_venv)."
            else
                echo "  ⚠ Kokoro TTS installation failed. Skipping."
                rm -rf "$kokoro_venv"
            fi
        fi
    fi

    # --- Install F5-TTS on NVIDIA systems (voice cloning) ---
    # F5-TTS has similar dependency issues on Python 3.14, so use the Kokoro venv if available.
    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        if [[ -x "$kokoro_venv/bin/python" ]] && "$kokoro_venv/bin/python" -c "import f5_tts" &>/dev/null 2>&1; then
            echo "  F5-TTS is already installed, skipping."
        elif [[ -x "$kokoro_venv/bin/pip" ]]; then
            echo "  Installing F5-TTS (voice cloning, CUDA)..."
            if "$kokoro_venv/bin/pip" install f5-tts; then
                echo "  F5-TTS installed (in Kokoro venv)."
            else
                echo "  ⚠ F5-TTS installation failed. Skipping."
            fi
        else
            echo "  ⚠ Skipping F5-TTS — Kokoro venv not available."
        fi
    fi

    echo "  TTS setup complete."
    echo "  Usage examples:"
    echo "    Piper:  echo 'Hello world' | piper --model $voice_file --output_file out.wav"
    echo "    Kokoro: echo 'Hello world' | kokoro-tts out.wav"
}
