#!/usr/bin/env bash
# Pull a Docker image from Docker Hub and convert it to a Singularity/Apptainer SIF.
# Usage: ./scripts/pull-sif.sh <container> <version> [output-dir]
#
# Example:
#   ./scripts/pull-sif.sh scrnaseq 1.0.0
#   ./scripts/pull-sif.sh spatial  1.2.0 /scratch/$USER/sif

set -euo pipefail

DOCKERHUB_ORG="${DOCKERHUB_ORG:-}"

usage() {
  echo "Usage: $0 <container> <version> [output-dir]"
  echo "  DOCKERHUB_ORG env var must be set (or export it before running)."
  exit 1
}

[[ $# -lt 2 ]] && usage
[[ -z "$DOCKERHUB_ORG" ]] && { echo "Error: DOCKERHUB_ORG is not set."; usage; }

CONTAINER="$1"
VERSION="$2"
OUTDIR="${3:-.}"

IMAGE="docker://${DOCKERHUB_ORG}/${CONTAINER}:${VERSION}"
OUTFILE="${OUTDIR}/${CONTAINER}_${VERSION}.sif"

mkdir -p "$OUTDIR"

echo "Pulling ${IMAGE} → ${OUTFILE}"
apptainer pull "$OUTFILE" "$IMAGE"
echo "Done: $OUTFILE"
