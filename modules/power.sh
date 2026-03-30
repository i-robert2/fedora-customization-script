# shellcheck shell=bash
mod_power() {
    echo "[power] Configuring sleep after 3 hours, shutdown after 4 hours of inactivity..."

    # --- Disable screen blanking only inside a VM (prevents screen going black after 5 min) ---
    if systemd-detect-virt --quiet 2>/dev/null; then
        gsettings set org.gnome.desktop.session idle-delay 0
        echo "  VM detected — screen blanking disabled (idle-delay set to 0)."
    else
        echo "  Bare metal — keeping default screen blanking (saves battery)."
    fi

    # --- Sleep after 3 hours (10800 seconds) on AC and battery ---
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 10800
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 10800
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
    echo "  Sleep after 3 hours of inactivity configured (AC + battery)."

    # --- Shutdown after 4 hours of inactivity via systemd timer ---
    # systemd-logind IdleAction isn't available on all Fedora configs,
    # so we use a small systemd timer + service that checks idle time.
    SHUTDOWN_SERVICE="/etc/systemd/system/auto-shutdown-idle.service"
    SHUTDOWN_TIMER="/etc/systemd/system/auto-shutdown-idle.timer"
    SHUTDOWN_SCRIPT="/usr/local/bin/auto-shutdown-idle"

    # Script: checks if system has been idle ≥ 4 hours before shutting down
    sudo tee "$SHUTDOWN_SCRIPT" > /dev/null <<'IDLESH'
#!/usr/bin/env bash
# Shut down if all user sessions have been idle for ≥ 4 hours (14400 seconds).

IDLE_THRESHOLD=14400

# Get the minimum idle hint duration across all sessions
MIN_IDLE=$IDLE_THRESHOLD
while IFS= read -r session; do
    idle_since=$(loginctl show-session "$session" -p IdleSinceHint --value 2>/dev/null)
    if [[ -z "$idle_since" || "$idle_since" == "0" ]]; then
        # Session is active (not idle)
        exit 0
    fi
    idle_us=$idle_since
    now_us=$(date +%s%6N)
    elapsed_s=$(( (now_us - idle_us) / 1000000 ))
    (( elapsed_s < MIN_IDLE )) && MIN_IDLE=$elapsed_s
done < <(loginctl list-sessions --no-legend | awk '{print $1}')

if (( MIN_IDLE >= IDLE_THRESHOLD )); then
    systemctl poweroff
fi
IDLESH
    sudo chmod +x "$SHUTDOWN_SCRIPT"
    echo "  auto-shutdown-idle script created."

    # Service unit
    sudo tee "$SHUTDOWN_SERVICE" > /dev/null <<'SVCEOF'
[Unit]
Description=Auto shutdown after 4 hours of inactivity

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-shutdown-idle
SVCEOF

    # Timer: check every 15 minutes
    sudo tee "$SHUTDOWN_TIMER" > /dev/null <<'TMREOF'
[Unit]
Description=Check idle time for auto shutdown

[Timer]
OnBootSec=1h
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
TMREOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now auto-shutdown-idle.timer
    echo "  auto-shutdown-idle timer enabled (checks every 15 min, shuts down after 4h idle)."
}