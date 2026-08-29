#!/usr/bin/env bash
# Pull a container image from Docker Hub and convert it to a Singularity/Apptainer SIF.
# Usage: ./scripts/pull-sif.sh <container> <version> [output-dir]
#
# Example:
#   ./scripts/pull-sif.sh python_spatial 1.0.0
#   ./scripts/pull-sif.sh python_spatial 1.0.0 /scratch/$USER/sif

set -euo pipefail

DOCKERHUB_OWNER="${DOCKERHUB_OWNER:-}"

usage() {
  echo "Usage: $0 <container> <version> [output-dir]"
  echo "  DOCKERHUB_OWNER env var must be set (or export it before running)."
  exit 1
}

[[ $# -lt 2 ]] && usage
[[ -z "$DOCKERHUB_OWNER" ]] && { echo "Error: DOCKERHUB_OWNER is not set."; usage; }

CONTAINER="$1"
VERSION="$2"
OUTDIR="${3:-$(dirname "$0")/../definitions/${CONTAINER}}"

IMAGE="docker://${DOCKERHUB_OWNER}/${CONTAINER}:${VERSION}"
OUTFILE="${OUTDIR}/${CONTAINER}_${VERSION}.sif"

mkdir -p "$OUTDIR"

echo "Pulling ${IMAGE} → ${OUTFILE}"
apptainer pull "$OUTFILE" "$IMAGE"
echo "Done: $OUTFILE"
