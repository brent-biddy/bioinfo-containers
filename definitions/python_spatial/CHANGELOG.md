# python_spatial Changelog

## [Unreleased]

## [1.2.0] - 2026-07-06

### Changed
- Bump to Python 3.12 and switch to the `rapids-singlecell-cu12` wheel (0.15.2),
  replacing the unpinned `rapids-singlecell` that had silently capped at 0.13.4
  (its last release with a Python 3.11-compatible wheel).
- CUDA 12.5 -> 12.9; pin cuml/cuvs/cugraph to 26.04 for rapids-singlecell
  compatibility; add conda-forge pytorch-gpu + torchvision for Blackwell sm_120
  support.
- Constrain `scikit-learn>=1.6,<1.7` (conda and pip) to avoid a cuml import
  break from newer scikit-learn pulled in via scanpy.
- Registry: push/pull docs and tooling switched back to Docker Hub
  (`babiddy755/python_spatial`) from GHCR.

### Fixed
- `Apptainer.def`: corrected a non-existent base image tag and added
  `CONDA_OVERRIDE_CUDA=12.9` so micromamba can solve CUDA-gated packages
  without GPU access at build time.
- `Apptainer.def` and `Dockerfile` now point cupy's JIT kernel cache at a
  writable `/tmp` dir instead of the default `~/.cupy`.
- `Dockerfile` now runs the same build-time import smoke test as
  `Apptainer.def`.

### Removed
- CI workflow (manual build + push instead).

## [1.0.0] - 2026-06-29

### Added
- Initial release
- Base: mambaorg/micromamba:1.5.10-cuda12.5.1-ubuntu22.04
- Quarto 1.6.42
- spatialdata, spatialdata-io, spatialdata-plot, squidpy
- rapids-singlecell (CUDA 12.5)
- scanpy, papermill, session-info, ipykernel
- Build-time smoke test for all key imports
- Apptainer.def for native HPC builds
