# Team Containers

Versioned, reproducible Docker images for the lab. CI builds and tests on every PR; a git tag triggers a push to Docker Hub.

## Available containers

| Name | Description | Docker Hub |
|------|-------------|------------|
| `python_spatial` | Spatial omics — Python (squidpy, spatialdata, rapids-singlecell) | `ORG/python_spatial` |

## Using an image

**Docker:**
```bash
docker pull ORG/python_spatial:1.0.0
docker run --rm -v $PWD:/work ORG/python_spatial:1.0.0 python my_script.py
```

**Apptainer/Singularity (HPC):**
```bash
export DOCKERHUB_ORG=ORG
./scripts/pull-sif.sh python_spatial 1.0.0 /scratch/$USER/sif

apptainer exec /scratch/$USER/sif/python_spatial_1.0.0.sif python my_script.py
```

## Releasing a new version

1. Update `environment.yml` with pinned versions.
2. Update `CHANGELOG.md`.
3. Open a PR — CI will build the image to confirm it works.
4. After merge, tag the commit:

```bash
git tag python_spatial/v1.1.0
git push origin python_spatial/v1.1.0
```

The `release` workflow builds the image and pushes `ORG/python_spatial:1.1.0` and `:latest` to Docker Hub.

## Adding a new container

```
containers/
  my-tool/
    Dockerfile
    environment.yml   # fully pinned conda environment
    CHANGELOG.md
```

The CI workflow auto-detects any `containers/*` directory that changes in a PR — no workflow edits needed.

## GitHub configuration

Set the following in **Settings → Secrets and variables**:

| Type | Name | Value |
|------|------|-------|
| Secret | `DOCKERHUB_USERNAME` | Docker Hub username |
| Secret | `DOCKERHUB_TOKEN` | Docker Hub access token (not your password) |
| Variable | `DOCKERHUB_ORG` | Docker Hub org or username used in image names |
