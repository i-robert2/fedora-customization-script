# shellcheck shell=bash
mod_searxng() {
    echo "[searxng] Installing SearXNG (self-hosted meta search engine for AI web search)..."

    # --- Ensure Podman is available ---
    if ! command -v podman &>/dev/null; then
        echo "  Installing Podman..."
        sudo dnf install -y podman
    fi

    # --- Run SearXNG container ---
    if podman container exists searxng 2>/dev/null; then
        echo "  SearXNG container already exists."
        if ! podman ps --format '{{.Names}}' | grep -q '^searxng$'; then
            echo "  Starting existing SearXNG container..."
            podman start searxng
        else
            echo "  SearXNG is already running."
        fi
    else
        echo "  Creating SearXNG container..."
        podman run -d \
            --name searxng \
            -p 8888:8080 \
            -e SEARXNG_BASE_URL=http://localhost:8888/ \
            -v searxng-data:/etc/searxng \
            --restart unless-stopped \
            docker.io/searxng/searxng:latest
        echo "  SearXNG container created."
    fi

    # --- Create systemd user service for auto-start ---
    local service_dir="$HOME/.config/systemd/user"
    local service_file="$service_dir/searxng.service"
    if [[ ! -f "$service_file" ]]; then
        mkdir -p "$service_dir"
        cat > "$service_file" <<EOF
[Unit]
Description=SearXNG Meta Search Engine (Podman)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/podman start -a searxng
ExecStop=/usr/bin/podman stop searxng
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload
        systemctl --user enable searxng.service
        echo "  Systemd user service created and enabled."
    else
        echo "  Systemd user service already exists."
    fi

    echo "  SearXNG available at http://localhost:8888"
    echo "  NOTE: In Open WebUI, go to Admin → Settings → Web Search →"
    echo "        Enable → SearXNG → http://localhost:8888"
}
