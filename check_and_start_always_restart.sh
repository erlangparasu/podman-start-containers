#!/bin/bash
# ErlangParasu 2025

set +e
set -x

# Define the path for the log file in the user's home directory
LOG_FILE="$HOME/podman_always_restart_monitor.log"

echo "$(date '+%Y-%m-%d %H:%M:%S'): --- Starting scan for containers with 'always' restart policy ---" >> "$LOG_FILE"

# Get all container IDs from podman ps --all, reverse them, and then process each ID
# We use tail -n +2 to skip the header line from podman ps
# We use awk '{print $1}' to extract just the container ID
podman ps --all | tac | awk '{print $1}' | while IFS= read -r container_id; do
    # Skip empty lines or if container_id is not a valid ID format (e.g., if parsing went wrong)
    if [ -z "$container_id" ]; then
        continue
    fi

    # Use podman inspect to get the restart policy
    # .HostConfig.RestartPolicy.Name will give 'always', 'on-failure', 'no', etc.
    # 2>/dev/null suppresses errors if a container ID somehow becomes invalid
    restart_policy=$(podman inspect --format "{{.HostConfig.RestartPolicy.Name}}" "$container_id" 2>/dev/null)

    if [ -z "$restart_policy" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING: Could not inspect policy for container ID '$container_id'. It might not exist or there's an issue." >> "$LOG_FILE"
        continue
    fi

    # Check if the restart policy is 'always'
    if [ "$restart_policy" == "always" ]; then
        # Check if the container is currently running
        # .State.Running will be 'true' or 'false'
        is_running=$(podman inspect --format "{{.State.Running}}" "$container_id" 2>/dev/null)

        if [ "$is_running" == "true" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S'): Container '$container_id' has 'always' restart policy and is already running. Policy: '$restart_policy'." >> "$LOG_FILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S'): Container '$container_id' has 'always' restart policy but is NOT running (Status: '$is_running'). Attempting to start..." >> "$LOG_FILE"
            podman restart "$container_id" >> "$LOG_FILE" 2>&1
	    sleep 2s
            podman start "$container_id" >> "$LOG_FILE" 2>&1
	    sleep 2s
            podman start "$container_id" >> "$LOG_FILE" 2>&1
	    sleep 2s
            if [ $? -eq 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S'): Container '$container_id' started successfully." >> "$LOG_FILE"
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR: Failed to start container '$container_id'. Check Podman logs." >> "$LOG_FILE"
            fi
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Container '$container_id' does not have 'always' restart policy. Policy: '$restart_policy'." >> "$LOG_FILE"
    fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S'): --- Scan complete ---" >> "$LOG_FILE"

# eof
