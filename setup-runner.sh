#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# GitHub Actions Self-Hosted Runner — One-time setup for Fedora VM
#
# Run this ON the Fedora VM as your normal user (fedora):
#   chmod +x setup-runner.sh
#   ./setup-runner.sh <RUNNER_TOKEN>
#
# To get the RUNNER_TOKEN:
#   1. Go to https://github.com/i-robert2/fedora-customization-script/settings/actions/runners/new
#   2. Select "Linux" and "x64"
#   3. Copy the token from the "./config.sh --token XXXXX" line
###############################################################################

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <RUNNER_TOKEN>"
    echo ""
    echo "Get your token from:"
    echo "  https://github.com/i-robert2/fedora-customization-script/settings/actions/runners/new"
    exit 1
fi

RUNNER_TOKEN="$1"
RUNNER_DIR="$HOME/actions-runner"
REPO_URL="https://github.com/i-robert2/fedora-customization-script"

# ── 1. Passwordless sudo ─────────────────────────────────────────────────
echo "[1/5] Configuring passwordless sudo for $(whoami)..."
SUDOERS_FILE="/etc/sudoers.d/$(whoami)-nopasswd"
if [ -f "$SUDOERS_FILE" ]; then
    echo "  Already configured, skipping."
else
    echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo "  Passwordless sudo configured."
fi

# ── 2. Install dependencies ──────────────────────────────────────────────
echo "[2/5] Installing runner dependencies..."
sudo dnf install -y curl tar jq libicu dotnet-runtime-8.0 2>/dev/null || \
    sudo dnf install -y curl tar jq libicu
echo "  Dependencies installed."

# ── 3. Download and extract runner ────────────────────────────────────────
echo "[3/5] Setting up GitHub Actions runner..."
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ -f "./config.sh" ]; then
    echo "  Runner already downloaded, skipping extraction."
else
    LATEST_VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//')
    RUNNER_URL="https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/actions-runner-linux-x64-${LATEST_VERSION}.tar.gz"
    echo "  Downloading runner v${LATEST_VERSION}..."
    curl -fsSL -o actions-runner.tar.gz "$RUNNER_URL"
    tar xzf actions-runner.tar.gz
    rm -f actions-runner.tar.gz
    echo "  Runner extracted to $RUNNER_DIR"
fi

# ── 4. Configure runner ──────────────────────────────────────────────────
echo "[4/5] Configuring runner..."
./config.sh \
    --url "$REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "fedora-vm" \
    --labels "self-hosted,fedora" \
    --work "_work" \
    --unattended \
    --replace
echo "  Runner configured as 'fedora-vm' with labels: self-hosted, fedora"

# ── 5. Install and start as a service ─────────────────────────────────────
echo "[5/5] Installing runner as a systemd service..."
sudo ./svc.sh install "$(whoami)"
sudo ./svc.sh start
echo "  Runner service started and will auto-start on boot."

echo ""
echo "=== Runner setup complete! ==="
echo ""
echo "Verify at:"
echo "  https://github.com/i-robert2/fedora-customization-script/settings/actions/runners"
echo ""
echo "The runner should show as 'Idle' (green). Now just push to main and"
echo "the pipeline will lint + deploy automatically."
