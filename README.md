# Podman Container Management Scripts

This project contains a collection of Bash scripts designed to monitor, maintain, and ensure the health of Podman containers. These scripts are particularly useful for automated recovery from host restarts, power failures, or specific Podman-related bugs (like conmon issues).

## Scripts Overview

### 1. `check_all_containers.sh`
The master script that orchestrates the execution of several other monitoring scripts. It is intended to be run periodically (e.g., via a cron job) to ensure all system-critical containers are in their desired states.

### 2. `check_and_start_always_restart.sh`
Scans all containers to identify those configured with the `always` restart policy. If any such container is found to be in a non-running state, the script attempts to start it.

### 3. `check_exited_years_ago.sh`
A recovery script designed to find containers that have been in an "Exited" state for a long duration (detected by the string "years ago" in `podman ps` output). This helps in automatically reviving legacy or forgotten containers after a long downtime.

### 4. `check_podman_conmon_containers_v1.sh`
Addresses potential issues where Podman's `conmon` (container monitor) process might become desynchronized from the container state. It verifies the health of the `conmon` process for running containers and attempts a restart if discrepancies are found.

### 5. `check_postgres_container_ps.sh`
A dedicated monitor for a container named `shared-postgres`. It ensures this specific database container is always up and running, attempting to start it if it's found to be down.

### 6. `finds_available_ports.sh`
A utility script that scans a defined range of ports (default: 8000 to 60000) using `lsof` to identify which TCP ports are currently available and not in a `LISTEN` state.

### 7. `fix_containers_state_podman.sh`
An aggressive health-check script that iterates through all running containers and attempts to execute basic commands (`id`, `uname`, `pwd`) inside them. If a container is unresponsive or the execution fails, the script performs a series of restart/stop/start operations to restore the container to a healthy state.

### 8. `start_container_helper.sh`
A reusable helper script used to verify the health of a specific container by name. If the container is unresponsive to an `exec` command, it attempts to stop and restart it.

## Usage

Most of these scripts can be executed directly:

```bash
chmod +x *.sh
./check_all_containers.sh
```

*Note: Some scripts expect to be located in the `$HOME` directory or require specific environment setups as indicated by the paths used within the scripts.*

## Logging
Several scripts log their activities to specific log files in the user's home directory (e.g., `podman_always_restart_monitor.log`, `podman_container_monitor.log`), making it easier to audit automatic restarts and failures.
