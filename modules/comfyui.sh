# shellcheck shell=bash
mod_comfyui() {
    echo "[comfyui] Installing ComfyUI (image & video generation)..."

    local COMFYUI_DIR="$HOME/comfyui"

    # --- Dependencies ---
    if ! command -v python3 &>/dev/null; then
        echo "  Installing Python 3..."
        sudo dnf install -y python3 python3-pip python3-venv
    fi

    if ! command -v git &>/dev/null; then
        echo "  Installing git..."
        sudo dnf install -y git
    fi

    # --- Clone ComfyUI ---
    if [[ -d "$COMFYUI_DIR" ]]; then
        echo "  ComfyUI directory already exists, pulling latest..."
        git -C "$COMFYUI_DIR" pull --ff-only 2>/dev/null || true
    else
        echo "  Cloning ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    fi

    # --- Create venv and install deps ---
    if [[ ! -d "$COMFYUI_DIR/venv" ]]; then
        echo "  Creating Python virtual environment..."
        python3 -m venv "$COMFYUI_DIR/venv"
    fi

    echo "  Installing ComfyUI Python dependencies..."
    # shellcheck source=/dev/null
    source "$COMFYUI_DIR/venv/bin/activate"

    # Detect GPU and install appropriate PyTorch
    if [[ "$HW_HAS_NVIDIA" == true ]]; then
        echo "  NVIDIA GPU detected — installing PyTorch with CUDA..."
        pip install --quiet --upgrade \
            torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    else
        echo "  No NVIDIA GPU — installing CPU PyTorch..."
        pip install --quiet --upgrade \
            torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    fi

    pip install --quiet --upgrade -r "$COMFYUI_DIR/requirements.txt"
    deactivate

    # --- Install ComfyUI Manager (custom node manager) ---
    local manager_dir="$COMFYUI_DIR/custom_nodes/ComfyUI-Manager"
    if [[ -d "$manager_dir" ]]; then
        echo "  ComfyUI Manager already installed."
    else
        echo "  Installing ComfyUI Manager..."
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$manager_dir"
    fi

    # --- Install AnimateDiff Evolved (video generation) ---
    local animatediff_dir="$COMFYUI_DIR/custom_nodes/ComfyUI-AnimateDiff-Evolved"
    if [[ -d "$animatediff_dir" ]]; then
        echo "  AnimateDiff Evolved already installed."
    else
        echo "  Installing AnimateDiff Evolved (video generation)..."
        git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git "$animatediff_dir"
    fi

    # --- Download SD 1.5 checkpoint (works on both CPU and GPU) ---
    local models_dir="$COMFYUI_DIR/models/checkpoints"
    mkdir -p "$models_dir"
    if [[ -f "$models_dir/v1-5-pruned-emaonly.safetensors" ]]; then
        echo "  SD 1.5 checkpoint already downloaded."
    else
        echo "  Downloading Stable Diffusion 1.5 checkpoint (~4 GB)..."
        curl -fSL -o "$models_dir/v1-5-pruned-emaonly.safetensors" \
            "https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
        echo "  SD 1.5 checkpoint downloaded."
    fi

    # On NVIDIA: also download SDXL for higher quality
    if [[ "$HW_HAS_NVIDIA" == true ]]; then
        if [[ -f "$models_dir/sd_xl_base_1.0.safetensors" ]]; then
            echo "  SDXL checkpoint already downloaded."
        else
            echo "  Downloading SDXL checkpoint (~7 GB)..."
            curl -fSL -o "$models_dir/sd_xl_base_1.0.safetensors" \
                "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
            echo "  SDXL checkpoint downloaded."
        fi
    fi

    # --- Create launcher script ---
    cat > "$COMFYUI_DIR/start.sh" <<'LAUNCHER'
#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
source venv/bin/activate
python main.py --listen 0.0.0.0 --port 8188 "$@"
LAUNCHER
    chmod +x "$COMFYUI_DIR/start.sh"

    echo "  ComfyUI installed at $COMFYUI_DIR"
    echo "  Start with: ~/comfyui/start.sh"
    echo "  Then open http://localhost:8188"
    echo "  Use ComfyUI Manager to install additional models and nodes."
}
