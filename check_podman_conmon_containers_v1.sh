#!/bin/bash
# ErlangParasu 2025

check_runtime() {
    local CUSTOM_COMMAND="$1"

    # Start command in background
    bash -c "$CUSTOM_COMMAND" &
    local CMD_PID=$!

    echo "Started '$CUSTOM_COMMAND' with PID $CMD_PID"
    sleep 4

    if ps -p $CMD_PID > /dev/null; then
        echo "Command is still running after 10 seconds."
        kill -9 $CMD_PID
        return 0
    else
        echo "Command finished before 10 seconds."
        return 1
    fi
}

# Function to check if a specific ps command returns a non-empty string
# Arguments:
#   $1: The unique ID string to search for in the ps output.
# Returns 0 if output is non-empty, 1 if output is empty.
check_conmon_command_output() {
  # Check if an argument was provided
  if [ -z "$1" ]; then
    echo "Error: No unique ID provided. Usage: check_conmon_command_output <unique_id>"
    return 2 # Indicate an error due to missing argument
  fi

  local unique_id="$1"

  # Execute the command and capture its output
  # 'set +e' temporarily disables exit on error, so the script doesn't exit if grep finds nothing
  # '2>/dev/null' redirects stderr to /dev/null to suppress any error messages from ps/grep
  local output=$(ps auxww | grep "/conmon" | grep "api-version" | grep "/containers" | grep "/storage" | grep "/conmon.pid" | grep "${unique_id}" 2>/dev/null)

  # Check if the captured output is not empty
  if [ -n "$output" ]; then
    echo "Command output is NOT empty for ID: ${unique_id}"
    # Optionally, print the output for debugging
    # echo "Output: $output"
    #return 0 # Success: output is non-empty

    if check_runtime "podman logs --tail 3 -f ${unique_id}"; then
      echo "logs watch success."
      return 0
    else
      echo "logs watch failed."
      return 1
    fi
  else
    echo "Command output IS empty for ID: ${unique_id}"
    return 1 # Failure: output is empty
  fi
}

# --- How to use the function ---

# Call the function with the desired unique ID
# Example:
# check_conmon_command_output "f5f1f1b51780ab71eb237a3baf2ac485faaac4e1e965edf2fb567ba1b20e48d1"

# Check the exit status of the function
# if check_conmon_command_output "f5f1f1b51780ab71eb237a3baf2ac485faaac4e1e965edf2fb567ba1b20e48d1"; then
#   echo "The command found the string."
# else
#   echo "The command did not find the string."
# fi

# --- Example: Loop through podman container IDs and call the function ---

echo "--- Checking running containers with check_conmon_command_output ---"

# Get all container IDs and names from podman ps --all, skipping the header line
# Using --format "{{.ID}}\t{{.Names}}" to get both ID and Name, separated by a tab.
# 'tail -n +2' is used to skip the header.
podman ps --format "{{.ID}}\t{{.Names}}" | tac | while IFS=$'\t' read -r id name; do
  echo "Processing container ID: $id (Name: $name)"
  if check_conmon_command_output "$id"; then
    echo "  -> Conmon process found for this container ID."
  else
    echo "  -> No conmon process found for this container ID or command output was empty. <<<<<<<<<<<<"
    set +e
    podman start "$id"
    podman start "$id"
    podman start "$id"
    podman stop "$id"
    podman stop "$id"
    podman stop "$id"
    podman start "$id"
    podman start "$id"
    podman start "$id"
    set -e
    echo "  -> Container tried to restart. <<<<<<<<<<<<"
  fi
  echo "" # Add a newline for better readability between checks
done

echo "--- Finished checking containers ---"

# eof
