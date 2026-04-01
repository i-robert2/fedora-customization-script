# shellcheck shell=bash
mod_monitoring() {
    echo "[monitoring] Setting up Prometheus + Grafana (Podman containers)..."

    local MON_DIR="$HOME/monitoring"
    local PROM_DIR="$MON_DIR/prometheus"
    local GRAFANA_DIR="$MON_DIR/grafana"
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # --- Podman (should be pre-installed on Fedora, but ensure it) ---
    if ! command -v podman &>/dev/null; then
        echo "  Installing Podman..."
        sudo dnf install -y podman
    fi

    # --- Create monitoring directories ---
    mkdir -p "$PROM_DIR/data"
    mkdir -p "$GRAFANA_DIR/data"
    mkdir -p "$GRAFANA_DIR/provisioning/datasources"

    # --- Prometheus config ---
    if [[ -f "$PROM_DIR/prometheus.yml" ]]; then
        echo "  Prometheus config already exists, skipping."
    else
        cp "$SCRIPT_DIR/templates/monitoring/prometheus.yml" "$PROM_DIR/prometheus.yml"
        echo "  Prometheus config copied to $PROM_DIR/prometheus.yml"
        echo "  Edit VM targets: nano $PROM_DIR/prometheus.yml"
    fi

    # --- Grafana datasource provisioning ---
    if [[ -f "$GRAFANA_DIR/provisioning/datasources/prometheus.yml" ]]; then
        echo "  Grafana datasource config already exists, skipping."
    else
        cp "$SCRIPT_DIR/templates/monitoring/grafana-datasource.yml" \
           "$GRAFANA_DIR/provisioning/datasources/prometheus.yml"
        echo "  Grafana datasource provisioned (auto-connects to Prometheus)."
    fi

    # --- Prometheus container ---
    if podman container exists prometheus 2>/dev/null; then
        echo "  Prometheus container already exists, skipping."
    else
        echo "  Creating Prometheus container..."
        podman create \
            --name prometheus \
            -p 127.0.0.1:9090:9090 \
            -v "$PROM_DIR/prometheus.yml:/etc/prometheus/prometheus.yml:Z,ro" \
            -v "$PROM_DIR/data:/prometheus:Z" \
            docker.io/prom/prometheus:latest \
            --config.file=/etc/prometheus/prometheus.yml \
            --storage.tsdb.path=/prometheus \
            --storage.tsdb.retention.time=30d \
            --web.enable-lifecycle
        echo "  Prometheus container created."
    fi

    # --- Grafana container ---
    if podman container exists grafana 2>/dev/null; then
        echo "  Grafana container already exists, skipping."
    else
        echo "  Creating Grafana container..."
        podman create \
            --name grafana \
            -p 127.0.0.1:3001:3000 \
            -v "$GRAFANA_DIR/data:/var/lib/grafana:Z" \
            -v "$GRAFANA_DIR/provisioning:/etc/grafana/provisioning:Z,ro" \
            -e GF_SECURITY_ADMIN_USER=admin \
            -e GF_SECURITY_ADMIN_PASSWORD=admin \
            docker.io/grafana/grafana:latest
        echo "  Grafana container created (port 3001 to avoid conflict with Open WebUI)."
    fi

    # --- Systemd user services (manual start only) ---
    local SERVICE_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SERVICE_DIR"

    # Prometheus service
    if [[ -f "$SERVICE_DIR/prometheus.service" ]]; then
        echo "  Prometheus systemd service already exists, skipping."
    else
        cat > "$SERVICE_DIR/prometheus.service" <<EOF
[Unit]
Description=Prometheus (Podman)
After=network-online.target

[Service]
Type=simple
Restart=on-failure
RestartSec=10
ExecStart=/usr/bin/podman start -a prometheus
ExecStop=/usr/bin/podman stop prometheus

[Install]
WantedBy=default.target
EOF
        echo "  Prometheus systemd user service created."
    fi

    # Grafana service
    if [[ -f "$SERVICE_DIR/grafana.service" ]]; then
        echo "  Grafana systemd service already exists, skipping."
    else
        cat > "$SERVICE_DIR/grafana.service" <<EOF
[Unit]
Description=Grafana (Podman)
After=network-online.target prometheus.service

[Service]
Type=simple
Restart=on-failure
RestartSec=10
ExecStart=/usr/bin/podman start -a grafana
ExecStop=/usr/bin/podman stop grafana

[Install]
WantedBy=default.target
EOF
        echo "  Grafana systemd user service created."
    fi

    systemctl --user daemon-reload

    # --- Start/stop convenience script ---
    local MON_SCRIPT="$HOME/.local/bin/monitoring"
    mkdir -p "$HOME/.local/bin"
    cat > "$MON_SCRIPT" <<'SCRIPT'
#!/usr/bin/env bash
case "${1:-}" in
    start)
        echo "Starting Prometheus..."
        systemctl --user start prometheus.service
        echo "Starting Grafana..."
        systemctl --user start grafana.service
        echo "Monitoring started."
        echo "  Prometheus: http://localhost:9090"
        echo "  Grafana:    http://localhost:3001 (admin/admin)"
        ;;
    stop)
        echo "Stopping Grafana..."
        systemctl --user stop grafana.service
        echo "Stopping Prometheus..."
        systemctl --user stop prometheus.service
        echo "Monitoring stopped."
        ;;
    status)
        echo "Prometheus: $(systemctl --user is-active prometheus.service)"
        echo "Grafana:    $(systemctl --user is-active grafana.service)"
        ;;
    *)
        echo "Usage: monitoring {start|stop|status}"
        exit 1
        ;;
esac
SCRIPT
    chmod +x "$MON_SCRIPT"
    echo "  Convenience script created: monitoring {start|stop|status}"

    # --- Grafana desktop launcher ---
    local GRAFANA_DESKTOP="$HOME/.local/share/applications/grafana.desktop"
    if [[ -f "$GRAFANA_DESKTOP" ]]; then
        echo "  Grafana desktop launcher already exists, skipping."
    else
        echo "  Creating Grafana desktop launcher..."
        mkdir -p "$HOME/.local/share/applications"
        cat > "$GRAFANA_DESKTOP" <<'EOF'
[Desktop Entry]
Name=Grafana
Comment=Monitoring dashboards (Prometheus + Grafana)
Exec=bash -c 'systemctl --user start prometheus.service; systemctl --user start grafana.service; sleep 3; xdg-open http://localhost:3001'
Icon=grafana
Terminal=false
Type=Application
Categories=System;Monitor;
EOF
        echo "  Grafana desktop launcher created."
    fi

    # --- Copy node_exporter playbook to Ansible workspace ---
    local ANSIBLE_DIR="$HOME/ansible"
    if [[ -d "$ANSIBLE_DIR" ]] && [[ ! -f "$ANSIBLE_DIR/install-node-exporter.yml" ]]; then
        cp "$SCRIPT_DIR/templates/ansible/install-node-exporter.yml" "$ANSIBLE_DIR/"
        echo "  node_exporter Ansible playbook copied to $ANSIBLE_DIR/"
    fi

    echo ""
    echo "  ── Monitoring Quick Start ──"
    echo ""
    echo "  Step 1: Edit Prometheus targets with your VM IPs:"
    echo "    nano $PROM_DIR/prometheus.yml"
    echo ""
    echo "  Step 2: Install node_exporter on VMs:"
    echo "    cd ~/ansible"
    echo "    ansible-playbook -i inventory.ini install-node-exporter.yml"
    echo ""
    echo "  Step 3: Start monitoring:"
    echo "    monitoring start            # or click the Grafana desktop icon"
    echo ""
    echo "  Step 4: Open Grafana:"
    echo "    http://localhost:3001       (login: admin / admin)"
    echo "    Import dashboard #1860 for a Node Exporter Full dashboard"
    echo ""
    echo "  Management:"
    echo "    monitoring start            # start Prometheus + Grafana"
    echo "    monitoring stop             # stop both"
    echo "    monitoring status           # check if running"
    echo ""
}
