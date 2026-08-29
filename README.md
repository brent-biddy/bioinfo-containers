# Team Containers

Versioned images for the lab, on Docker Hub under `babiddy755`.

## The images

| Name | For | Contains |
|------|-----|----------|
| `python_cpu` | every step that is not GPU work — object creation, annotation, centroids, reports | the analysis stack; no CUDA |
| `python_spatial` | **frozen.** What every repo currently uses, including all GPU work | the whole stack in one image |

Two more are designed and live on the `gpu-images` branch: `python_gpu` (`python_cpu` +
RAPIDS) and `cellpose_gpu` (`python_gpu` + torch + cellpose). They are not here yet because
they raise questions this repo has not answered — whether a RAPIDS build fits a hosted runner,
and whether RAPIDS can satisfy the pinned versions at all. Until then `python_spatial` covers
every GPU step, unchanged.

### Why split at all

`python_spatial` carries RAPIDS, CUDA, torch and cellpose in one 11 GB image, so a scanpy bump
rebuilds all of it and every repo pays for stacks it never imports. Checked across the repos:
`merfish_testis` and `xenium_nb` import rapids-singlecell; the oocyte repos and `xenium_tools`
import cellpose; nothing imports both, and nothing imports torch except through cellpose.
`sammy_r21`, `oir-analysis-*` and `retina` need neither.

So the analysis stack is worth having on its own. `python_cpu` is 1.4 GB as a SIF against 11 GB,
and rebuilds in minutes rather than being something you avoid touching.

`python_spatial` is left exactly as it was. Anything needing a GPU still uses it.

### What the images guarantee

An image presents a working environment on its own. A pipeline should never have to set
environment variables to make one function, so each image sets:

- `PATH` — its env first, so `python` is the env's interpreter
- `CONDA_PREFIX` — cupy JIT-compiles kernels and finds the CUDA headers under it, and the
  non-login shell a Nextflow `script:` block uses never sets it
- `JUPYTER_PATH` — its own share directory. Apptainer bind-mounts `$HOME`, so kernelspecs under
  `~/.local/share/jupyter/kernels` are visible inside the container and Quarto will resolve a
  kernel from them, picking an unrelated project's environment and then *succeeding with the
  wrong package versions*. Pointing `JUPYTER_PATH` inward makes the image's own kernels the only
  discoverable ones, so a notebook needs no `jupyter:` pin and is portable between a conda env
  and a container.

## Layout

```
definitions/
  python_cpu/      environment.yml   the CPU image's env, and the base the GPU images extend
                   Apptainer.def
  python_spatial/  frozen
```

There is no `common/` directory: `python_cpu`'s environment file *is* the shared base, so there
is nothing extra to name.

`%files` paths resolve against the working directory — Apptainer has no build-context flag — so
definitions use repo-root-relative paths and are built from the repository root.

## Releasing

Tag `<container>/vX.Y.Z` and push it. CI builds that definition and pushes `:X.Y.Z` and
`:latest` to Docker Hub.

```bash
git tag python_cpu/v1.0.0
git push origin python_cpu/v1.0.0
```

Needs two repository secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (an access token, not
the account password).

Pull requests touching `definitions/` build `python_cpu` without pushing, and check that the
image configures itself — the guarantees above are asserted rather than assumed.

### The GPU images are not here yet

They are designed on the `gpu-images` branch. Two things are unknown: whether a RAPIDS build
fits a hosted runner (~21 GB free, against an 11 GB image), and whether RAPIDS can satisfy the
versions pinned in `python_cpu/environment.yml` at all — RAPIDS pins dask, which caps
spatialdata. Both are worth answering with something already working to compare against.

Until then `python_spatial` covers every GPU step, unchanged.

## Using an image

### Locally

```bash
docker build -f definitions/python_cpu/Dockerfile -t python_cpu:local definitions
docker run --rm -v "$PWD:/work" python_cpu:local python my_script.py
```

### HPC and Nextflow

Pull a ready-made SIF -- no conversion:

```bash
apptainer pull oras://ghcr.io/brent-biddy/python_cpu-sif:1.0.0
apptainer exec python_cpu-sif_1.0.0.sif python my_script.py
```

Nextflow takes the same URI directly:

```groovy
process { container = 'oras://ghcr.io/brent-biddy/python_cpu-sif:1.0.0' }
withLabel: 'gpu' { container = 'docker://babiddy755/python_spatial:1.2.0' }
```

This is the point of publishing SIFs rather than OCI images. With a `docker://` URI Nextflow
pulls the image and converts it to SIF inside the job, which exceeds the 20 minute
`pullTimeout` default on a RAPIDS-sized image and is paid again whenever the cache is cleared.
An `oras://` artifact is already a SIF: Nextflow downloads it into `cacheDir` once and runs it.

Two requirements for this to work:

- **Keep `ociAutoPull` and `ociMode` off** (they are off by default). Both make the runtime
  treat images as OCI and convert them, which is exactly what the SIF avoids.
- **The GHCR packages are public**, so the cluster needs no registry credentials. This
  repository is public, and a package published from it with `GITHUB_TOKEN` inherits that —
  worth confirming on the first release, since a private package would mean placing a token on
  OSCER and rotating it. If one does come out private: **Profile → Packages → `<image>-sif` →
  Package settings → Change visibility.**

The single-layer point matters: `oras://` against a multi-layer Docker image fails with
`ORAS SIF image should have a single layer, found N`. `apptainer push` produces a genuine
single-layer ORAS artifact, which is the supported case.

A pipeline selects between images with a process label, so a step declares what it needs and
each site says how that is satisfied.

## Adding an image

```
definitions/my_image/
  environment.yml     an overlay on python_cpu's, or a standalone env
  Dockerfile
```

Nothing else changes: the release workflow takes the image name from the tag.
