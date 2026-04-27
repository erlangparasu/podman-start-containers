#!/bin/bash
# ErlangParasu 2025

set +e
set +x

echo "info: fixing containers state ---------------------------------"

function try_check() {
  echo "info: try check. --------------------------------------------"
  podman ps -q | while IFS= read -r line; do
    echo "info: processing line: $line"
    container_id="$line"
    podman exec -t "$container_id" sh -c 'set -e; set -x; id; uname -a; pwd;'
    exit_code="$?"
    echo "info: exit_code: $exit_code"
    if [[ $exit_code -eq 0 ]]; then
      echo "ok: -"
    else
      echo "error: --------------------------------------------------"
      echo "info: retry starting. -----------------------------------"
      podman restart "$container_id"
      podman restart "$container_id"
      podman restart "$container_id"
      podman start "$container_id"
      podman start "$container_id"
      podman start "$container_id"
      podman stop "$container_id"
      podman stop "$container_id"
      podman stop "$container_id"
      podman kill "$container_id"
      podman kill "$container_id"
      podman kill "$container_id"
      podman start "$container_id"
      podman start "$container_id"
      podman start "$container_id"
      podman ps | grep "$container_id" | grep "Up "
    fi
done
}

try_check "1"
try_check "2"
try_check "3"

echo "info: fixing containers state. finish. ------------------------"

# eof
