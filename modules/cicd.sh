# shellcheck shell=bash
mod_cicd() {
    echo "[cicd] Setting up GitLab Runner + deploy pipeline..."

    local GITLAB_HOME="$HOME/gitlab"
    local SSL_DIR="$GITLAB_HOME/config/ssl"

    # --- GitLab Runner (shell executor, native install) ---
    if command -v gitlab-runner &>/dev/null; then
        echo "  GitLab Runner already installed, skipping."
    else
        echo "  Installing GitLab Runner..."
        curl -fsSL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
        sudo dnf install -y gitlab-runner
        echo "  GitLab Runner installed."
    fi

    # --- SSH deploy key for pipeline → VM deployments ---
    local DEPLOY_KEY="$HOME/.ssh/gitlab-deploy"
    if [[ -f "$DEPLOY_KEY" ]]; then
        echo "  Deploy SSH key already exists, skipping."
    else
        echo "  Generating SSH deploy key for CI/CD..."
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -f "$DEPLOY_KEY" -N "" -C "gitlab-deploy"
        chmod 600 "$DEPLOY_KEY"
        chmod 644 "$DEPLOY_KEY.pub"
        echo "  Deploy key generated at: $DEPLOY_KEY"
    fi

    echo ""
    echo "  ── GitLab Runner Setup ──"
    echo "  1. In GitLab UI: Admin > CI/CD > Runners > New instance runner"
    echo "  2. Copy the runner token, then run:"
    echo "     sudo gitlab-runner register \\"
    echo "       --url https://gitlab.local \\"
    echo "       --token YOUR_TOKEN \\"
    echo "       --executor shell \\"
    echo "       --tls-ca-file $SSL_DIR/gitlab.local.crt"
    echo "  3. Start the runner:"
    echo "     sudo gitlab-runner start"
    echo ""
    echo "  ── Deploy to VM Setup ──"
    echo "  1. Create a KVM/QEMU VM (virt-manager or virsh)"
    echo "  2. Copy the deploy key to the VM:"
    echo "     ssh-copy-id -i $DEPLOY_KEY.pub deploy@VM_IP"
    echo "  3. Add a .gitlab-ci.yml to your project (see templates/gitlab-ci-deploy.yml)"
    echo "  4. Push code — the pipeline will auto-deploy to the VM"
    echo ""
}
