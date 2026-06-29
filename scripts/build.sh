#!/usr/bin/env bash
# Build a container image locally.
# Usage: ./scripts/build.sh <container> [--no-cache]
#
# Example:
#   ./scripts/build.sh python_spatial
#   ./scripts/build.sh python_spatial --no-cache

set -euo pipefail

usage() {
  echo "Usage: $0 <container> [--no-cache]"
  exit 1
}

[[ $# -lt 1 ]] && usage

CONTAINER="$1"
NO_CACHE=""
[[ "${2:-}" == "--no-cache" ]] && NO_CACHE="--no-cache"

CONTEXT="$(dirname "$0")/../containers/${CONTAINER}"

[[ ! -d "$CONTEXT" ]] && { echo "Error: containers/${CONTAINER} not found."; exit 1; }

echo "Building ${CONTAINER}..."
docker build $NO_CACHE -t "${CONTAINER}:local" "$CONTEXT"
echo "Done: ${CONTAINER}:local"
