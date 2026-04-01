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
    local GITLAB_HTTPS_PORT="8929"
    local GITLAB_SSH_PORT="2224"
    local SSL_DIR="$GITLAB_HOME/config/ssl"

    # --- Generate self-signed SSL certificate ---
    if [[ -f "$SSL_DIR/gitlab.local.crt" ]]; then
        echo "  SSL certificate already exists, skipping."
    else
        echo "  Generating self-signed SSL certificate..."
        mkdir -p "$SSL_DIR"
        openssl req -x509 -nodes -days 3650 \
            -newkey rsa:2048 \
            -keyout "$SSL_DIR/gitlab.local.key" \
            -out "$SSL_DIR/gitlab.local.crt" \
            -subj "/CN=gitlab.local" \
            -addext "subjectAltName=DNS:gitlab.local,DNS:localhost,IP:127.0.0.1"
        chmod 600 "$SSL_DIR/gitlab.local.key"
        echo "  SSL certificate generated (valid for 10 years)."
    fi

    # --- Configure GitLab for HTTPS ---
    local GITLAB_RB="$GITLAB_HOME/config/gitlab.rb"
    if [[ -f "$GITLAB_RB" ]] && grep -q "external_url.*https" "$GITLAB_RB"; then
        echo "  GitLab HTTPS already configured, skipping."
    else
        echo "  Configuring GitLab for HTTPS..."
        mkdir -p "$GITLAB_HOME/config"
        cat > "$GITLAB_RB" <<RUBY
external_url "https://gitlab.local"
letsencrypt['enable'] = false
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.local.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.local.key"
nginx['redirect_http_to_https'] = true
RUBY
        echo "  GitLab HTTPS configured."
    fi

    if podman container exists gitlab-ce 2>/dev/null; then
        echo "  GitLab CE container already exists, skipping."
    else
        echo "  Creating GitLab data directories..."
        mkdir -p "$GITLAB_HOME"/{config,logs,data}

        echo "  Pulling and starting GitLab CE container..."
        podman run -d \
            --name gitlab-ce \
            --hostname gitlab.local \
            -p "127.0.0.1:${GITLAB_HTTPS_PORT}:443" \
            -p "127.0.0.1:${GITLAB_SSH_PORT}:22" \
            -v "$GITLAB_HOME/config:/etc/gitlab:Z" \
            -v "$GITLAB_HOME/logs:/var/log/gitlab:Z" \
            -v "$GITLAB_HOME/data:/var/opt/gitlab:Z" \
            --shm-size 256m \
            docker.io/gitlab/gitlab-ce:latest

        echo "  GitLab CE container started."
        echo ""
        echo "  Waiting for GitLab to initialize (this may take several minutes)..."
        # Wait for GitLab to be ready before triggering reconfigure
        local retries=0
        while ! podman exec gitlab-ce gitlab-ctl status &>/dev/null; do
            retries=$((retries + 1))
            if [[ $retries -ge 60 ]]; then
                echo "  WARNING: GitLab did not start within 5 minutes. Check 'podman logs gitlab-ce'."
                break
            fi
            sleep 5
        done

        echo "  Applying HTTPS configuration..."
        podman exec gitlab-ce gitlab-ctl reconfigure

        echo "  Access the UI at: https://localhost:${GITLAB_HTTPS_PORT}"
        echo "  SSH clone port:   ${GITLAB_SSH_PORT}"
    fi

    # --- Create a systemd user service for GitLab (manual start only) ---
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
Restart=on-failure
RestartSec=10
ExecStartPre=-/usr/bin/podman stop gitlab-ce
ExecStartPre=-/usr/bin/podman rm gitlab-ce
ExecStart=/usr/bin/podman run --rm \\
    --name gitlab-ce \\
    --hostname gitlab.local \\
    -p 127.0.0.1:${GITLAB_HTTPS_PORT}:443 \\
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
        echo "  GitLab systemd service created (manual start only)."
    fi

    # --- GitLab desktop launcher ---
    local GITLAB_DESKTOP="$HOME/.local/share/applications/gitlab-ce.desktop"
    if [[ -f "$GITLAB_DESKTOP" ]]; then
        echo "  GitLab desktop launcher already exists, skipping."
    else
        echo "  Creating GitLab desktop launcher..."
        mkdir -p "$HOME/.local/share/applications"
        cat > "$GITLAB_DESKTOP" <<EOF
[Desktop Entry]
Name=GitLab CE
Comment=Self-hosted GitLab instance
Exec=bash -c 'systemctl --user start gitlab-ce.service; sleep 5; xdg-open https://localhost:${GITLAB_HTTPS_PORT}'
Icon=gitlab
Terminal=false
Type=Application
Categories=Development;ProjectManagement;
EOF
        echo "  GitLab desktop launcher created."
    fi

    echo ""
    echo "  ── GitLab CE Quick Start ──"
    echo "  1. Wait a few minutes for initialization"
    echo "  2. Open: https://localhost:${GITLAB_HTTPS_PORT}"
    echo "  3. Get the initial root password:"
    echo "     podman exec gitlab-ce cat /etc/gitlab/initial_root_password"
    echo "  4. Login as 'root' with that password, then change it"
    echo "  5. Accept the self-signed certificate warning in your browser"
    echo "  6. Create your first project and push code:"
    echo "     git -c http.sslVerify=false remote add origin https://localhost:${GITLAB_HTTPS_PORT}/root/my-project.git"
    echo "     git -c http.sslVerify=false push -u origin main"
    echo ""
}
