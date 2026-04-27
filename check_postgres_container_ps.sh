#!/bin/bash
# ErlangParasu 2025

set -e
set -x

# Define the container name
CONTAINER_NAME="shared-postgres"
LOG_FILE="$HOME/podman_container_monitor.log"

touch $LOG_FILE

# Check if the container is running using podman ps --all
# We're looking for the container name and the "Up" status
# The output format for podman ps --all for a running container is like:
# CONTAINER ID  IMAGE      COMMAND   CREATED       STATUS      PORTS       NAMES
# 49f233847773  ...        ...       ...           Up X time   ...         shared-postgres
# For an exited container:
# CONTAINER ID  IMAGE      COMMAND   CREATED       STATUS          PORTS       NAMES
# 49f233847773  ...        ...       ...           Exited (0) ...  ...         shared-postgres

# Use awk to reliably check the status field for the specific container name.
# This avoids issues if the name or ID appears in other fields.
# We look for the container name (in the last column usually) AND 'Up' in the status column.
if ! podman ps --all --format "{{.ID}}\t{{.Names}}\t{{.Status}}" | awk -v name="$CONTAINER_NAME" '($2 == name && $3 ~ /^Up/) { found_running = 1; exit } END { if (found_running) exit 0; else exit 1 }'; then
    echo "$(date): Container '$CONTAINER_NAME' is not running or not found. Attempting to start it..." >> "$LOG_FILE"
    set +e
    podman start "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    sleep 2s
    podman start "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    sleep 2s
    podman start "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    sleep 2s
    set -e
    if [ $? -eq 0 ]; then
        echo "$(date): Container '$CONTAINER_NAME' started successfully." >> "$LOG_FILE"
    else
        echo "$(date): Error starting container '$CONTAINER_NAME'. Check Podman logs." >> "$LOG_FILE"
    fi
else
    echo "$(date): Container '$CONTAINER_NAME' is already running." >> "$LOG_FILE"
fi

# eof
