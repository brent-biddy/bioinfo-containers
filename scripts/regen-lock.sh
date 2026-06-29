#!/usr/bin/env bash
# Regenerate the conda-lock.yml for a container.
# Requires conda-lock: pip install conda-lock
#
# Usage: ./scripts/regen-lock.sh <container>
# Example: ./scripts/regen-lock.sh python_spatial

set -euo pipefail

[[ $# -lt 1 ]] && { echo "Usage: $0 <container>"; exit 1; }

CONTAINER="$1"
DIR="containers/${CONTAINER}"

[[ ! -f "${DIR}/environment.yml" ]] && { echo "Error: ${DIR}/environment.yml not found"; exit 1; }

conda-lock lock \
    -p linux-64 \
    -f "${DIR}/environment.yml" \
    --lockfile "${DIR}/conda-lock.yml"

echo "Done: ${DIR}/conda-lock.yml"
echo "Review the changes, then commit and tag to release."
