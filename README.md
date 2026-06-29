# Team Containers

Versioned Docker images for the lab. Build and push locally to GitHub Container Registry (GHCR).

## Available containers

| Name | Description | Image |
|------|-------------|-------|
| `python_spatial` | Spatial omics — Python (squidpy, spatialdata, rapids-singlecell) | `ghcr.io/babiddy755/python_spatial` |

## Using a container

### Local (Docker)

Build the image:

```bash
docker build -t python_spatial:local definitions/python_spatial
```

Run a script:

```bash
docker run --rm -v $PWD:/work python_spatial:local python my_script.py
```

Convert to a local SIF for Apptainer testing:

```bash
apptainer build definitions/python_spatial/python_spatial_local.sif docker-daemon://python_spatial:local
```

### HPC (Apptainer)

Clone the repo, then pull the SIF next to the definition files:

```bash
git clone https://github.com/brent-biddy/bioinfo-containers.git
cd bioinfo-containers
export GHCR_OWNER=babiddy755
./scripts/pull-sif.sh python_spatial 1.2.0
```

The SIF lands at `definitions/python_spatial/python_spatial_1.2.0.sif` and is gitignored.

```bash
apptainer exec definitions/python_spatial/python_spatial_1.2.0.sif python my_script.py
```

## Releasing a new version

1. Update `environment.yml` with the new packages or versions.
2. Build and test locally:

```bash
docker build -t python_spatial:local definitions/python_spatial
```

3. Tag, push to GHCR, and commit:

```bash
docker tag python_spatial:local ghcr.io/babiddy755/python_spatial:1.2.0
docker tag python_spatial:local ghcr.io/babiddy755/python_spatial:latest
docker push ghcr.io/babiddy755/python_spatial:1.2.0
docker push ghcr.io/babiddy755/python_spatial:latest
git add definitions/python_spatial/environment.yml
git commit -m "..."
git tag python_spatial/v1.2.0
git push origin main python_spatial/v1.2.0
```

First time only — authenticate with GHCR:

```bash
echo <your-github-token> | docker login ghcr.io -u babiddy755 --password-stdin
```

## Adding a new container

```
definitions/
  my-container/
    Dockerfile
    environment.yml
```

Build locally, push to GHCR, then commit and tag.
