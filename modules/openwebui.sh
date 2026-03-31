# shellcheck shell=bash
mod_openwebui() {
    echo "[openwebui] Installing Open WebUI (ChatGPT-like interface for local AI)..."

    # --- Ensure Podman is available (Fedora ships it by default) ---
    if ! command -v podman &>/dev/null; then
        echo "  Installing Podman..."
        sudo dnf install -y podman
    fi

    # --- Run Open WebUI container ---
    if podman container exists open-webui 2>/dev/null; then
        echo "  Open WebUI container already exists."
        if ! podman ps --format '{{.Names}}' | grep -q '^open-webui$'; then
            echo "  Starting existing Open WebUI container..."
            podman start open-webui
        else
            echo "  Open WebUI is already running."
        fi
    else
        echo "  Creating Open WebUI container..."
        podman run -d \
            --name open-webui \
            --network slirp4netns:allow_host_loopback=true \
            -p 3000:8080 \
            -e OLLAMA_BASE_URL=http://host.containers.internal:11434 \
            -v open-webui:/app/backend/data \
            --restart unless-stopped \
            ghcr.io/open-webui/open-webui:main
        echo "  Open WebUI container created."
    fi

    # --- Create systemd user service for auto-start ---
    local service_dir="$HOME/.config/systemd/user"
    local service_file="$service_dir/open-webui.service"
    if [[ ! -f "$service_file" ]]; then
        mkdir -p "$service_dir"
        cat > "$service_file" <<EOF
[Unit]
Description=Open WebUI (Podman)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/podman start -a open-webui
ExecStop=/usr/bin/podman stop open-webui
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload
        systemctl --user enable open-webui.service
        echo "  Systemd user service created and enabled."
    else
        echo "  Systemd user service already exists."
    fi

    echo "  Open WebUI available at http://localhost:3000"
    echo "  NOTE: On first visit, create an admin account."
}
