# VM Operations — SSH helper functions
#
# Source this file in ~/.bashrc:
#   source ~/vm-ops-helpers.sh
#
# These functions use the SSH config from ~/.ssh/config.d/vms.conf
# so you can refer to VMs by name (vm-web1, vm-db1, etc.)

# ── Single VM commands ──────────────────────────────────────────────

# Quick status: disk, memory, CPU load, uptime
vm-status() {
    local host="${1:?Usage: vm-status <host>}"
    echo "=== $host ==="
    ssh "$host" "
        echo '── Uptime ──'
        uptime
        echo ''
        echo '── Memory ──'
        free -m | head -2
        echo ''
        echo '── Disk ──'
        df -h / | tail -1
        echo ''
        echo '── CPU Load ──'
        cat /proc/loadavg
    "
}

# Check a specific service
vm-service() {
    local host="${1:?Usage: vm-service <host> <service>}"
    local service="${2:?Usage: vm-service <host> <service>}"
    ssh "$host" "systemctl status $service --no-pager -l"
}

# Tail logs for a service
vm-logs() {
    local host="${1:?Usage: vm-logs <host> <service>}"
    local service="${2:?Usage: vm-logs <host> <service>}"
    ssh "$host" "journalctl -u $service -f --no-pager"
}

# Restart a service
vm-restart() {
    local host="${1:?Usage: vm-restart <host> <service>}"
    local service="${2:?Usage: vm-restart <host> <service>}"
    ssh "$host" "sudo systemctl restart $service && systemctl status $service --no-pager"
}

# Run an arbitrary command
vm-exec() {
    local host="${1:?Usage: vm-exec <host> <command...>}"
    shift
    ssh "$host" "$@"
}

# ── Multi-VM commands (SSH loop) ────────────────────────────────────
# For quick checks on a few VMs without Ansible

# Check status of all VMs listed in SSH config
vm-status-all() {
    local hosts=("$@")
    if [[ ${#hosts[@]} -eq 0 ]]; then
        echo "Usage: vm-status-all <host1> <host2> ..."
        echo "Example: vm-status-all vm-web1 vm-web2 vm-db1"
        return 1
    fi
    for host in "${hosts[@]}"; do
        vm-status "$host"
        echo ""
    done
}

# Run the same command on multiple VMs (sequential)
vm-exec-all() {
    local cmd="${1:?Usage: vm-exec-all '<command>' <host1> <host2> ...}"
    shift
    local hosts=("$@")
    if [[ ${#hosts[@]} -eq 0 ]]; then
        echo "Usage: vm-exec-all '<command>' <host1> <host2> ..."
        return 1
    fi
    for host in "${hosts[@]}"; do
        echo "=== $host ==="
        ssh "$host" "$cmd"
        echo ""
    done
}

# Run the same command on multiple VMs (parallel)
vm-exec-parallel() {
    local cmd="${1:?Usage: vm-exec-parallel '<command>' <host1> <host2> ...}"
    shift
    local hosts=("$@")
    if [[ ${#hosts[@]} -eq 0 ]]; then
        echo "Usage: vm-exec-parallel '<command>' <host1> <host2> ..."
        return 1
    fi

    local tmpdir
    tmpdir=$(mktemp -d)

    for host in "${hosts[@]}"; do
        (ssh "$host" "$cmd" > "$tmpdir/$host.out" 2>&1) &
    done
    wait

    for host in "${hosts[@]}"; do
        echo "=== $host ==="
        cat "$tmpdir/$host.out"
        echo ""
    done
    rm -rf "$tmpdir"
}
