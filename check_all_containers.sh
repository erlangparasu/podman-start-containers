#!/bin/bash
# ErlangParasu 2025

set +e
set -x

# restart container
cd $HOME && $HOME/check_containers_state_podman.sh
echo "Finished at: $(date)" >> "$HOME/check_containers_state_podman.log"

# NOTE: auto start shared-postgres container
cd $HOME && $HOME/check_postgres_container_ps.sh

# NOTE: auto start power loss container
cd $HOME && $HOME/check_exited_years_ago.sh

# NOTE: auto start the restart policy always
cd $HOME && $HOME/check_and_start_always_restart.sh

# NOTE: fix podman conmon bug
cd $HOME && $HOME/check_podman_conmon_containers_v1.sh

# NOTE: ensure containers always running
cd $HOME && $HOME/start-container-helper.sh "my-app-demo"

# eof
