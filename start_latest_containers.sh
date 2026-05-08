#!/usr/bin/env bash
set -euo pipefail

# Use podman by default, fallback to docker if needed
readonly CLI=$(command -v podman || command -v docker || echo "podman")

declare -A seen_combo
declare -A start_targets
declare -A delete_targets

echo "Scanning for container port collisions..."

# 1. Fetch containers formatted and chronologically sorted (newest first).
# Format: <CreatedAt>|<ID>|<Name>|<Ports>
while IFS='|' read -r ccreated cid cname cports; do
    # Skip containers with no exposed ports
    [[ -z "$cports" ]] && continue

    # Extract base name by stripping the trailing hyphen and alphanumeric hash
    if [[ "$cname" =~ ^(.*)-[a-fA-F0-9]+$ ]]; then
        base_name="${BASH_REMATCH[1]}"
    else
        base_name="$cname"
    fi

    # Extract exposed host ports safely using regex
    host_ports=$(echo "$cports" | grep -oE ':[0-9]+->' | tr -d ':->' | sort -u || true)

    if [[ -n "$host_ports" ]]; then
        is_older_duplicate=false

        for port in $host_ports; do
            # Create a unique collision key based exclusively on Exposed Port + Base Container Name
            combo_key="${port}_${base_name}"

            if [[ -n "${seen_combo[$combo_key]:-}" ]]; then
                # Combination already claimed by a previously parsed (newer) container
                is_older_duplicate=true
                break
            else
                # First time seeing this combination; register the newest container
                seen_combo[$combo_key]="$cid"
            fi
        done

        # Route the container to the appropriate execution queue
        if [[ "$is_older_duplicate" == true ]]; then
            delete_targets["$cid"]=1
        else
            start_targets["$cid"]=1
        fi
    fi
done < <($CLI ps -a --format '{{.CreatedAt}}|{{.ID}}|{{.Names}}|{{.Ports}}' | sort -r)

# -----------------------------------------------------------------------------
# Execution Phase (Purely Port/Name Based)
# -----------------------------------------------------------------------------

# 2. Force stop and remove older overlapping containers
if [[ ${#delete_targets[@]} -gt 0 ]]; then
    echo "Cleaning up older overlapping containers..."
    for cid in "${!delete_targets[@]}"; do
        echo " -> Force removing older container: $cid"
        $CLI rm -f "$cid"
    done
else
    echo " -> No older conflicting containers found."
fi

# 3. Unconditionally start the newest containers
if [[ ${#start_targets[@]} -gt 0 ]]; then
    echo "Ensuring newest containers are active..."
    for cid in "${!start_targets[@]}"; do
        echo " -> Starting newest container: $cid"
        # Issuing start directly; if already natively running, the daemon handles it safely
        $CLI start "$cid" >/dev/null || echo "    [Warning] Failed to start $cid"
    done
else
    echo " -> No targets to start."
fi

echo "Operation complete."
