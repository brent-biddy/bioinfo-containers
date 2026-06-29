#!/usr/bin/env bash
# Run the smoke test against a locally built container image.
# Usage: ./scripts/test.sh <container>
#
# Example:
#   ./scripts/test.sh python_spatial

set -euo pipefail

usage() {
  echo "Usage: $0 <container>"
  exit 1
}

[[ $# -lt 1 ]] && usage

CONTAINER="$1"
IMAGE="${CONTAINER}:local"

if ! docker image inspect "$IMAGE" &>/dev/null; then
  echo "Error: image ${IMAGE} not found. Run ./scripts/build.sh ${CONTAINER} first."
  exit 1
fi

echo "Testing ${IMAGE}..."
docker run --rm "$IMAGE" python - <<'PY'
import nbformat
import papermill
import yaml
import session_info
import spatialdata
import spatialdata_io
import spatialdata_plot
import scanpy
import squidpy
import rapids_singlecell
print("python runtime ok")
PY
echo "Test passed: ${IMAGE}"
