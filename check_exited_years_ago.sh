#!/bin/bash
# ErlangParasu 2025

set +e
set -x

# Define the path for the log file using the user's home directory
LOG_FILE="$HOME/podman_aged_container_restart.log"

echo "$(date '+%Y-%m-%d %H:%M:%S'): --- Starting scan for aged and exited containers (no format) ---" >> "$LOG_FILE"

# Get the full output of podman ps --all
# We'll process this line by line to find the relevant containers.
podman ps --all | while IFS= read -r line; do
    # Skip the header line
    if [[ "$line" =~ ^"CONTAINER ID" ]]; then
        continue
    fi

    # Check if the line contains "Exited" and "years ago"
    # This is a very broad match and relies on these strings being unique enough.
    if [[ "$line" =~ "Exited" ]] && [[ "$line" =~ "years ago" ]]; then
        # If we find such a line, we need to extract the Container ID.
        # The container ID is always the first word on the line.
        container_id=$(echo "$line" | awk '{print $1}')
        container_name=$(echo "$line" | awk '{print $NF}') # Last field is usually name

        # Add a check to ensure we actually got an ID (not an empty string or error)
        if [ -z "$container_id" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING: Could not extract container ID from line: $line" >> "$LOG_FILE"
            continue
        fi

        echo "$(date '+%Y-%m-%d %H:%M:%S'): Found aged and exited container: '$container_name' ($container_id) based on line: '$line'." >> "$LOG_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Attempting to start container '$container_name' ($container_id)..." >> "$LOG_FILE"
        podman restart "$container_id" >> "$LOG_FILE" 2>&1
	sleep 2s
        podman start "$container_id" >> "$LOG_FILE" 2>&1
	sleep 2s
        podman start "$container_id" >> "$LOG_FILE" 2>&1
	sleep 2s
        if [ $? -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S'): Container '$container_name' ($container_id) started successfully." >> "$LOG_FILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S'): Error starting container '$container_name' ($container_id). Check Podman logs for details." >> "$LOG_FILE"
        fi
    fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S'): --- Scan complete ---" >> "$LOG_FILE"

# eof
