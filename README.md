# Team Containers

Versioned, reproducible Docker images for the lab. Build and test locally, then push a git tag to release to Docker Hub.

## Available containers

| Name | Description | Docker Hub |
|------|-------------|------------|
| `python_spatial` | Spatial omics — Python (squidpy, spatialdata, rapids-singlecell) | `babiddy755/python_spatial` |

## Using an image

**Docker:**
```bash
docker pull babiddy755/python_spatial:1.0.0
docker run --rm -v $PWD:/work babiddy755/python_spatial:1.0.0 python my_script.py
```

**Apptainer/Singularity (HPC):**
```bash
export DOCKERHUB_ORG=babiddy755
./scripts/pull-sif.sh python_spatial 1.0.0 /scratch/$USER/sif

apptainer exec /scratch/$USER/sif/python_spatial_1.0.0.sif python my_script.py
```

## Releasing a new version

1. Update `environment.yml` with the new packages or versions.
2. Build locally:

```bash
docker build -t python_spatial:local containers/python_spatial
```

3. Update `CHANGELOG.md` and commit.
4. Tag and push to trigger the Docker Hub release:

```bash
git tag python_spatial/v1.1.0
git push origin python_spatial/v1.1.0
```

GitHub Actions builds the image and pushes `babiddy755/python_spatial:1.1.0` and `:latest` to Docker Hub.

## Adding a new container

```
containers/
  my-container/
    Dockerfile
    environment.yml
    CHANGELOG.md
```

Build locally to verify, then tag to release.

## GitHub configuration

Set the following in **Settings → Secrets and variables**:

| Type | Name | Value |
|------|------|-------|
| Secret | `DOCKERHUB_USERNAME` | Docker Hub username |
| Secret | `DOCKERHUB_TOKEN` | Docker Hub access token (not your password) |
| Variable | `DOCKERHUB_ORG` | Docker Hub org or username used in image names |
