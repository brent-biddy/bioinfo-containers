# Team Containers

Versioned images for the lab, on Docker Hub under `babiddy755`.

## The images

| Name | For | Contains |
|------|-----|----------|
| `python_cpu` | every step that is not GPU work — object creation, annotation, centroids, reports | the analysis stack; no CUDA |
| `python_gpu` | steps that cluster on a card | `python_cpu`'s environment + RAPIDS; **7.9 GB** |
| `cellpose_gpu` | segmentation with cellpose | `python_cpu`'s environment + torch + cellpose; **6.6 GB** |
| `python_spatial` | **frozen.** What the repos used before these two | the whole stack in one image |

**`cellpose_gpu` bootstraps from `python_cpu`, not `python_gpu`**, even though a segmentation
workflow that also clusters with rapids-singlecell in the same run would rather have both
available at once. Measured, not assumed: the same cellpose+torch overlay on `python_gpu` landed
at 11.02 GB, over GHCR's documented 10 GB per-layer limit; on `python_cpu` it landed at 6.59 GB.
A too-large-to-publish image was never a real alternative to weigh that convenience against.

### Why split, and what it costs

`python_spatial` carries RAPIDS, CUDA, torch and cellpose in one 11 GB image. Checked across the
repos: `merfish_testis` and `xenium_nb` import rapids-singlecell; the oocyte repos and
`xenium_tools` import cellpose; nothing imports both, and nothing imports torch except through
cellpose — though `spatialdata` depends on torch regardless, which is why both images carry the
CPU build. `sammy_r21`, `oir-analysis-*` and `retina` need neither — handing them an 11 GB image
for scanpy work is the thing this fixes. `python_cpu` is **1.4 GB** as a SIF, and builds in four
and a half minutes against twelve.

Two arguments that originally justified splitting have since weakened, and it is worth being
honest about that. "Nobody touches an 11 GB image because rebuilding it is painful" — CI now
does it unattended in twelve minutes. "Every CPU step pays for the GPU stack" — with an
`oras://` SIF there is no conversion, just a download, once per version per shared cacheDir.

What splitting costs is real and was paid here: **a shared spec is not a shared solve.** RAPIDS
pins dask, which caps spatialdata, so the two images can silently carry different versions of
the library that writes and reads the objects passed between steps. Both are pinned to
`python_spatial`'s resolved versions to make that a build failure instead. One image would make
the problem impossible rather than detectable.

`python_spatial` is left exactly as it was, and will be retired once the repos move over.

### `apptainer pull` of `python_gpu` is unreliable, and shrinking it did not fix that

**`ghcr.io` throttles the request for this blob's redirect**, with a sub-second `retry-after`.
Apptainer's ORAS client does not retry, so `apptainer pull` dies on the first `429` — in about
two seconds, with `TOOMANYREQUESTS`. `pullTimeout` is irrelevant: nothing times out, the first
request is refused.

The throttle is on getting *permission to start*, not on the transfer. Once a signed CDN URL is
in hand, 20 ranged requests across the blob returned `206` every time, no token needed. That is
why `scripts/pull-sif.sh` and the fetch-and-resume workaround succeed where `apptainer pull`
fails: they retry until the redirect comes.

**A 10 GB per-layer limit was assumed to be the cause. It is not.** GHCR does document 10 GB per
layer, and an ORAS SIF is one layer, so shrinking the image below it looked like the fix. It was
not — measured within one hour, three trials each, counting attempts to obtain the redirect:

| blob | size | attempts |
|---|---|---|
| `python_cpu-sif:1.0.0` | 1.44 GB | 1, 1, 1 |
| `python_cpu-sif:1.0.1`, freshly published | 1.44 GB | 1, 1, 1 |
| `python_gpu-sif:1.0.0` | 11.50 GB | 32, 21, 3 |
| `python_gpu-sif:1.0.1` | **7.93 GB** | 38, 46, 4 |

7.93 GB is two gigabytes inside the documented limit and throttles indistinguishably from 11.50.
A real `apptainer pull` of it still fails, in about two seconds. The freshly published CPU blob
rules out recency.

**The mechanism is not identified, and this section deliberately stops short of naming one.**
Two things argue against the documented request-rate limiter. GHCR's rate-limit errors carry an
`allowed: N/minute` clause (`retry-after: 3.2ms, allowed: 2000/minute`); ours carries none, just
`retry-after: 45.467376ms`. And the widely reported case of this error — `ghcr.io/aquasecurity`,
community discussion #139074 — is scoped to a package namespace and independent of blob size.

That fits this data as well as size does: `python_gpu-sif` is throttled and `python_cpu-sif` is
not, both under one account, and a brand-new blob in the throttled package is refused while a
brand-new blob in the healthy one is not. Which points at the package rather than the bytes.

**Confirmed on OSCER, from a machine that had never pulled either package.** One had been doing
all the testing, so self-inflicted throttling was a live possibility. It is ruled out — both
pulls run within a minute of each other, same host, same network, same account:

```
apptainer pull oras://...python_cpu-sif:1.0.1   1.3 GiB   ok, 50s at 53 MiB/s
apptainer pull oras://...python_gpu-sif:1.0.1   7.9 GB    TOOMANYREQUESTS in 0.79s
```

So it is not the client, not the IP, not the cluster's network, and not testing load. It is the
artifact, server-side, on first contact.

**The practical consequence: `container = 'oras://...python_gpu-sif'` does not work on OSCER.**
Not intermittently — every time, in under a second, before anything is downloaded. Any workflow
that relies on Nextflow autopulling this image will fail to start. Getting it onto a cluster
needs either a client that retries the redirect, or the SIF pre-staged somewhere durable.

So: the image is smaller because carrying a CUDA deep learning stack nothing imports was waste,
not because a size threshold was crossed. **Do not treat any particular size as safe**, and do
not expect shrinking an image to fix a pull.

Two further measurements narrow what this is. It is **per-blob, not per-package**: in the same
package, same token, same seconds, the 2-byte config blob returns `307` ten times out of ten
while the 7.93 GB layer returns `429` nine times out of ten. And **authentication makes no
difference** — an anonymous registry token and one minted from GitHub credentials both give
9/10 `429`, which is why `apptainer registry login` never helped. The `307` itself points at
Azure Blob Storage with a SAS token, so a blob GET is GitHub *minting a signed URL* rather than
serving bytes; admission control on minting those for expensive blobs would fit every
observation, though that is a hypothesis and not confirmed.

**Candidate fix: Quay.io.** Red Hat states unlimited storage and serving for public repositories,
and that it does not restrict anonymous pulls — rate limiting only at tens of requests per second
per IP, explicitly not pull-rate limiting for images. That is the opposite shape to a per-blob
refusal on first contact. Untested here: GHCR's documented limits did not describe this failure
either, so this stays a candidate until the real artifact is pushed there and pulled from OSCER.
The cost is a CI robot credential, and with it the property that the only secret is
`GITHUB_TOKEN`.

**Retested 2026-09-03 — clean on both a fresh network and OSCER itself.** The full 7.93 GB
`python_gpu-sif:1.0.1` pulled without a single retry from an unrelated machine on an unrelated
network (2m58s, 48.8 MiB/s), then from OSCER itself (4m2s, digest verified, no `TOOMANYREQUESTS`
at all). The earlier failure was measured as "server-side, on first contact" and reproduced
reliably across days of testing; it did not reproduce here on the same artifact, same registry,
same client. That rules out nothing about *why* it happened, but it does mean it was not a
permanent property of this artifact — something transient on GHCR/Azure's side, not the account,
the client, or OSCER's network. Quay.io stays recorded as a candidate but is no longer needed to
unblock anything: `container = 'oras://...python_gpu-sif'` works on OSCER as of this date.

Two levers for size that look promising and are not:

- **stripping static archives.** All `*.a` in the env total 0.15 GB across 94 files. Not a lever.
- **limiting CUDA architectures.** RAPIDS ships seven (`sm_70` through `sm_120`), and the image
  must serve OSCER's H100 and L40S cards as well as a Blackwell laptop, so at most three could
  go. They are prebuilt binaries, `nvprune` refuses shared libraries (*"not relocatable"*), and
  honouring `CMAKE_CUDA_ARCHITECTURES` would mean building RAPIDS from source.

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
