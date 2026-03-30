# shellcheck shell=bash
mod_gitlab() {
    echo "[gitlab] Installing GitLab CE (self-hosted, local)..."

    # --- Podman (should be pre-installed on Fedora, but ensure it) ---
    if ! command -v podman &>/dev/null; then
        echo "  Installing Podman..."
        sudo dnf install -y podman
    fi

    # --- GitLab CE container ---
    local GITLAB_HOME="$HOME/gitlab"
    local GITLAB_PORT="8929"
    local GITLAB_SSH_PORT="2224"

    if podman container exists gitlab-ce 2>/dev/null; then
        echo "  GitLab CE container already exists, skipping."
    else
        echo "  Creating GitLab data directories..."
        mkdir -p "$GITLAB_HOME"/{config,logs,data}

        echo "  Pulling and starting GitLab CE container..."
        podman run -d \
            --name gitlab-ce \
            --hostname gitlab.local \
            -p "127.0.0.1:${GITLAB_PORT}:80" \
            -p "127.0.0.1:${GITLAB_SSH_PORT}:22" \
            -v "$GITLAB_HOME/config:/etc/gitlab:Z" \
            -v "$GITLAB_HOME/logs:/var/log/gitlab:Z" \
            -v "$GITLAB_HOME/data:/var/opt/gitlab:Z" \
            --shm-size 256m \
            docker.io/gitlab/gitlab-ce:latest

        echo "  GitLab CE container started."
        echo ""
        echo "  NOTE: GitLab takes a few minutes to fully initialize."
        echo "  Access the UI at: http://localhost:${GITLAB_PORT}"
        echo "  SSH clone port:   ${GITLAB_SSH_PORT}"
    fi

    # --- Create a systemd user service so GitLab starts on boot ---
    local SERVICE_DIR="$HOME/.config/systemd/user"
    local SERVICE_FILE="$SERVICE_DIR/gitlab-ce.service"

    if [[ -f "$SERVICE_FILE" ]]; then
        echo "  GitLab systemd service already exists, skipping."
    else
        echo "  Creating systemd user service for GitLab..."
        mkdir -p "$SERVICE_DIR"
        cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=GitLab CE (Podman)
After=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/podman stop gitlab-ce
ExecStartPre=-/usr/bin/podman rm gitlab-ce
ExecStart=/usr/bin/podman run --rm \\
    --name gitlab-ce \\
    --hostname gitlab.local \\
    -p 127.0.0.1:${GITLAB_PORT}:80 \\
    -p 127.0.0.1:${GITLAB_SSH_PORT}:22 \\
    -v ${GITLAB_HOME}/config:/etc/gitlab:Z \\
    -v ${GITLAB_HOME}/logs:/var/log/gitlab:Z \\
    -v ${GITLAB_HOME}/data:/var/opt/gitlab:Z \\
    --shm-size 256m \\
    docker.io/gitlab/gitlab-ce:latest
ExecStop=/usr/bin/podman stop gitlab-ce

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload
        systemctl --user enable gitlab-ce.service
        # Enable lingering so user services start at boot (before login)
        loginctl enable-linger "$USER"
        echo "  GitLab will auto-start on boot."
    fi

    echo ""
    echo "  ── GitLab CE Quick Start ──"
    echo "  1. Wait a few minutes for initialization"
    echo "  2. Open: http://localhost:${GITLAB_PORT}"
    echo "  3. Get the initial root password:"
    echo "     podman exec gitlab-ce cat /etc/gitlab/initial_root_password"
    echo "  4. Login as 'root' with that password, then change it"
    echo "  5. Create your first project and push code:"
    echo "     git remote add origin http://localhost:${GITLAB_PORT}/root/my-project.git"
    echo "     git push -u origin main"
    echo ""
}
