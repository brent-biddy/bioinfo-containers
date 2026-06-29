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

Each container has two files:
- `environment.yml` — human-editable package spec (edit this)
- `conda-lock.yml` — exact pinned versions used at build time (generated, commit this)

The Dockerfile builds from the lock file, so builds are reproducible regardless of when they run.

**Requires `conda-lock`:** `pip install conda-lock`

1. Update `environment.yml` with the new packages or versions.
2. Regenerate the lock file:

```bash
./scripts/regen-lock.sh python_spatial
```

3. Build and test locally:

```bash
docker build -t python_spatial:local containers/python_spatial
```

4. Commit both files and tag to release:

```bash
git add containers/python_spatial/environment.yml containers/python_spatial/conda-lock.yml
git commit -m "..."
git tag python_spatial/v1.1.0
git push origin python_spatial/v1.1.0
```

GitHub Actions builds from the committed lock file and pushes `babiddy755/python_spatial:1.1.0` and `:latest` to Docker Hub.

## Adding a new container

```
containers/
  my-container/
    Dockerfile
    environment.yml
    conda-lock.yml
```

1. Write `environment.yml` and `Dockerfile`.
2. Run `./scripts/regen-lock.sh my-container` to generate the lock file.
3. Build locally to verify, then commit and tag to release.

## GitHub configuration

Set the following in **Settings → Secrets and variables**:

| Type | Name | Value |
|------|------|-------|
| Secret | `DOCKERHUB_USERNAME` | Docker Hub username |
| Secret | `DOCKERHUB_TOKEN` | Docker Hub access token (not your password) |
| Variable | `DOCKERHUB_ORG` | Docker Hub org or username used in image names |
