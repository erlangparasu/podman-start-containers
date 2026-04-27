#!/bin/bash
# ErlangParasu 2025

set -e
container_name="$1"
set +e

podman exec -t "${container_name}" sh -c 'set -e; id; pwd'
exit_code="${?}"

if [ ${exit_code} -eq 0 ]; then
	echo "ok."
else
	echo "error."
	echo "try to start the container ${container_name}."
	podman stop "${container_name}"
	podman stop "${container_name}"
	podman stop "${container_name}"
	podman start "${container_name}"
	podman start "${container_name}"
	podman start "${container_name}"
fi

# eof
