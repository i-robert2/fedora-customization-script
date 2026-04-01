# shellcheck shell=bash
mod_vmops() {
    echo "[vmops] Setting up VM operations tools (SSH helpers + Ansible)..."

    # --- Ansible ---
    if command -v ansible &>/dev/null; then
        echo "  Ansible is already installed, skipping."
    else
        echo "  Installing Ansible..."
        sudo dnf install -y ansible
        echo "  Ansible installed."
    fi

    # --- SSH config directory ---
    local SSH_CONFIG_DIR="$HOME/.ssh/config.d"
    mkdir -p "$SSH_CONFIG_DIR"

    # Ensure ~/.ssh/config includes config.d
    if [[ -f "$HOME/.ssh/config" ]] && grep -q "Include.*config.d" "$HOME/.ssh/config"; then
        echo "  SSH config.d include already present, skipping."
    else
        echo "  Adding config.d include to ~/.ssh/config..."
        local existing=""
        [[ -f "$HOME/.ssh/config" ]] && existing=$(cat "$HOME/.ssh/config")
        printf 'Include %s/*.conf\n\n%s' "$SSH_CONFIG_DIR" "$existing" > "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        echo "  SSH config.d include added."
    fi

    # --- SSH config template for VMs ---
    local VM_SSH_CONF="$SSH_CONFIG_DIR/vms.conf"
    if [[ -f "$VM_SSH_CONF" ]]; then
        echo "  VM SSH config already exists at $VM_SSH_CONF, skipping."
    else
        local SCRIPT_DIR
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        cp "$SCRIPT_DIR/templates/ssh-config-vm.conf" "$VM_SSH_CONF"
        chmod 600 "$VM_SSH_CONF"
        echo "  VM SSH config template copied to $VM_SSH_CONF"
        echo "  Edit it with your actual VM IPs: nano $VM_SSH_CONF"
    fi

    # --- VM ops helper functions in bashrc ---
    local HELPERS_SRC
    HELPERS_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/templates/vm-ops-helpers.sh"
    local HELPERS_DEST="$HOME/.local/bin/vm-ops-helpers.sh"

    mkdir -p "$HOME/.local/bin"
    cp "$HELPERS_SRC" "$HELPERS_DEST"
    chmod 644 "$HELPERS_DEST"

    # Add source line to bashrc if not already there
    if grep -q "vm-ops-helpers" "$HOME/.bashrc" 2>/dev/null; then
        echo "  VM ops helpers already sourced in ~/.bashrc, skipping."
    else
        cat >> "$HOME/.bashrc" <<EOF

# ── VM operations helpers ─────────────────────────────────────────────
# SSH helper functions for managing KVM/QEMU VMs
[[ -f "\$HOME/.local/bin/vm-ops-helpers.sh" ]] && source "\$HOME/.local/bin/vm-ops-helpers.sh"
# ── end vm ops ────────────────────────────────────────────────────────
EOF
        echo "  VM ops helper functions added to ~/.bashrc"
    fi

    # --- Ansible templates ---
    local ANSIBLE_DIR="$HOME/ansible"
    if [[ -d "$ANSIBLE_DIR" ]]; then
        echo "  Ansible directory already exists at $ANSIBLE_DIR, skipping."
    else
        local SCRIPT_DIR
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        echo "  Creating Ansible workspace at $ANSIBLE_DIR..."
        mkdir -p "$ANSIBLE_DIR"
        cp "$SCRIPT_DIR/templates/ansible/inventory.ini" "$ANSIBLE_DIR/"
        cp "$SCRIPT_DIR/templates/ansible/check-health.yml" "$ANSIBLE_DIR/"
        cp "$SCRIPT_DIR/templates/ansible/check-service.yml" "$ANSIBLE_DIR/"
        cp "$SCRIPT_DIR/templates/ansible/deploy-app.yml" "$ANSIBLE_DIR/"
        echo "  Ansible templates copied to $ANSIBLE_DIR"
        echo "  Edit inventory.ini with your VM IPs: nano $ANSIBLE_DIR/inventory.ini"
    fi

    echo ""
    echo "  ── VM Operations Quick Start ──"
    echo ""
    echo "  Method 1: SSH helpers (quick, for a few VMs)"
    echo "    vm-status vm-web1                  # check one VM"
    echo "    vm-service vm-web1 nginx           # check a service"
    echo "    vm-logs vm-web1 nginx              # tail service logs"
    echo "    vm-restart vm-web1 nginx           # restart a service"
    echo "    vm-exec vm-web1 'df -h'            # run any command"
    echo "    vm-exec-all 'free -m' vm-web1 vm-web2 vm-db1   # sequential"
    echo "    vm-exec-parallel 'free -m' vm-web1 vm-web2 vm-db1  # parallel"
    echo ""
    echo "  Method 2: Ansible (structured, for many VMs)"
    echo "    cd ~/ansible"
    echo "    ansible-playbook -i inventory.ini check-health.yml"
    echo "    ansible-playbook -i inventory.ini check-health.yml --limit webservers"
    echo "    ansible-playbook -i inventory.ini check-service.yml -e 'service_name=nginx'"
    echo "    ansible-playbook -i inventory.ini deploy-app.yml \\"
    echo "      -e 'src_path=~/myproject deploy_path=/opt/myapp'"
    echo ""
    echo "  Setup:"
    echo "    1. Edit VM IPs: nano ~/.ssh/config.d/vms.conf"
    echo "    2. Edit Ansible inventory: nano ~/ansible/inventory.ini"
    echo "    3. Copy deploy key to VMs: ssh-copy-id -i ~/.ssh/gitlab-deploy.pub deploy@VM_IP"
    echo ""
}
