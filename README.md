# Team Containers

Versioned, reproducible Docker images for the lab. Build locally, then push a git tag to release to GitHub Container Registry (GHCR).

## Available containers

| Name | Description | Image |
|------|-------------|-------|
| `python_spatial` | Spatial omics — Python (squidpy, spatialdata, rapids-singlecell) | `ghcr.io/babiddy755/python_spatial` |

## Using a container

### Local (Docker)

```bash
docker build -t python_spatial:local definitions/python_spatial
docker run --rm -v $PWD:/work python_spatial:local python my_script.py
```

### HPC (Apptainer)

Clone the repo, then pull the SIF next to the definition files:

```bash
git clone https://github.com/babiddy755/containers.git
cd containers
export GHCR_OWNER=babiddy755
./scripts/pull-sif.sh python_spatial 1.0.0
```

The SIF lands at `definitions/python_spatial/python_spatial_1.0.0.sif` and is gitignored.

```bash
apptainer exec definitions/python_spatial/python_spatial_1.0.0.sif python my_script.py
```

## Releasing a new version

1. Update `environment.yml` with the new packages or versions.
2. Build and test locally:

```bash
docker build -t python_spatial:local definitions/python_spatial
```

3. Commit and tag to release:

```bash
git add definitions/python_spatial/environment.yml
git commit -m "..."
git tag python_spatial/v1.1.0
git push origin python_spatial/v1.1.0
```

GitHub Actions builds the image and pushes `ghcr.io/babiddy755/python_spatial:1.1.0` and `:latest` to GHCR.

## Adding a new container

```
definitions/
  my-container/
    Dockerfile
    environment.yml
```

Build locally to verify, then commit and tag to release.

## GitHub configuration

No secrets needed — the workflow uses the built-in `GITHUB_TOKEN` to push to GHCR.

To make the packages publicly accessible, go to the package page on GitHub and set visibility to Public.
