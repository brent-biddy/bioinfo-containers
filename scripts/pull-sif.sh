#!/usr/bin/env bash
# Pull a container image from GHCR and convert it to a Singularity/Apptainer SIF.
# Usage: ./scripts/pull-sif.sh <container> <version> [output-dir]
#
# Example:
#   ./scripts/pull-sif.sh python_spatial 1.0.0
#   ./scripts/pull-sif.sh python_spatial 1.0.0 /scratch/$USER/sif

set -euo pipefail

GHCR_OWNER="${GHCR_OWNER:-}"

usage() {
  echo "Usage: $0 <container> <version> [output-dir]"
  echo "  GHCR_OWNER env var must be set (or export it before running)."
  exit 1
}

[[ $# -lt 2 ]] && usage
[[ -z "$GHCR_OWNER" ]] && { echo "Error: GHCR_OWNER is not set."; usage; }

CONTAINER="$1"
VERSION="$2"
OUTDIR="${3:-$(dirname "$0")/../containers/${CONTAINER}}"

IMAGE="docker://ghcr.io/${GHCR_OWNER}/${CONTAINER}:${VERSION}"
OUTFILE="${OUTDIR}/${CONTAINER}_${VERSION}.sif"

mkdir -p "$OUTDIR"

echo "Pulling ${IMAGE} → ${OUTFILE}"
apptainer pull "$OUTFILE" "$IMAGE"
echo "Done: $OUTFILE"
