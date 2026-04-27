#!/bin/bash
# ErlangParasu 2025

# This script finds available TCP/UDP port numbers for listening within a specified range.
# It checks ports from 8000 to 60000 to see if they are currently in a LISTEN state.
# This version uses 'lsof' to check port availability.

# Define the start and end of the port range
START_PORT=8000
END_PORT=60000

echo "Searching for available ports between $START_PORT and $END_PORT (not in LISTEN state)..."
echo "This might take a while, depending on the range and system load."
echo "Note: 'lsof' requires root privileges or appropriate sudoers setup to see all listening ports."

# Loop through each port in the specified range
for (( port=$START_PORT; port<=$END_PORT; port++ ))
do
    # Check if the port is in LISTEN state using 'lsof' command.
    # -i :$port: List files opened on the specified internet address/port.
    # -s TCP:LISTEN: Select TCP sockets that are in LISTEN state.
    # 2>/dev/null: Suppress error messages from lsof (e.g., permission denied).
    # grep -q ":$port": Filter for lines containing the current port number and operate quietly.
    # This command returns 0 (success) if the port is found in LISTEN state, and 1 (failure) otherwise.
    lsof -i TCP:"$port" -s TCP:LISTEN 2>/dev/null | grep -q ":$port (LISTEN)"

    # $? holds the exit status of the last executed command.
    # If the exit status is not 0 (meaning grep did not find the port in LISTEN state), then the port is available.
    if [ $? -ne 0 ]; then
        echo "Port $port is AVAILABLE for LISTEN."
    fi
done

echo "Search complete."
