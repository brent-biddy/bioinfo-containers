# Ideas, not yet done

## Build only what changed

The build check builds every image on every PR. It could build only the ones a PR touched.

The naive version is wrong: `python_cpu/environment.yml` is the shared base, so a change to it
must rebuild `python_gpu` too, and `cellpose_gpu` bootstraps from `python_gpu`. The rule is
"what changed, plus everything downstream":

```
python_cpu changed    -> python_cpu, python_gpu, cellpose_gpu
python_gpu changed    -> python_gpu, cellpose_gpu
cellpose_gpu changed  -> cellpose_gpu
```

No third-party action needed. A `detect` job diffs against the base ref and emits a JSON
matrix the build job consumes with `fromJSON`:

```yaml
jobs:
  detect:
    outputs:
      images: ${{ steps.set.outputs.images }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }      # needed to diff against the base commit
      - id: set
        run: |
          BASE=origin/${{ github.base_ref || 'main~1' }}
          CHANGED=$(git diff --name-only "$BASE"...HEAD -- definitions/ | cut -d/ -f2 | sort -u)
          # expand downstream, emit a JSON array
  build:
    needs: detect
    if: needs.detect.outputs.images != '[]'
    strategy:
      matrix:
        image: ${{ fromJSON(needs.detect.outputs.images) }}
```

Worth most once the GPU images are building, since those are the slow ones.

## A lock file, generated in CI

Versions are pinned in `python_cpu/environment.yml`, which fixes direct dependencies but not
transitive ones, and does not speed up the build — the solver still runs.

A lock file would do both: pin everything transitively, and skip the solve entirely by
installing from an explicit list. That matters most for the RAPIDS build.

The reason it is not here already is friction: an earlier attempt (`1e1ab9d`, reverted in
`2578c1c`) required running `conda-lock` locally and committing a generated file alongside
every environment change.

Generating it in CI removes that. On a PR touching `environment.yml`, a job solves it, exports
the result with `micromamba env export --explicit`, and commits `environment.lock` back to the
branch; the build then uses the lock. Needs `contents: write` and does mean CI amends your PR.

## Serve test fixtures and reference files over https

ORAS -- OCI Registry As Storage -- lets a registry hold arbitrary files, not just images. That
is how the SIFs are published here. The same trick works for data: `oras push` a reference
file, `oras pull` it back, versioned and immutable, on the same registry with the same auth.

**But prefer plain https for data.** Nextflow's `file()` stages `http(s)://`, `s3://` and
`gs://` natively; it speaks `oras://` only for *containers*. A reference file behind an ORAS
tag needs a fetch step; one behind an https URL is just an input.

| | Versioned | Nextflow stages it | Citable |
|---|---|---|---|
| ORAS on GHCR | yes | no -- needs a fetch step | no |
| GitHub release asset | yes | yes | no |
| Zenodo | yes | yes | **yes, DOI** |
| committed to the repo | yes | yes | no; bloats git |

### The part that matters most: a test fixture

CI currently proves an image builds and imports. It cannot prove the image *works*, because it
has no data — and that gap is not hypothetical. A python_cpu built on anndata 0.13 passed every
check and then died reading a MERSCOPE directory, because anndata 0.13 dropped an argument
spatialdata-io still passes. Only running a real step caught it, locally, by hand.

A small fixture published as a release asset would let CI run an actual pipeline step against a
new image before it is ever tagged. It wants to be genuinely small — the U2OS test region is
1.3 GB raw, which fits under the 2 GB per-asset limit but is more than a build check should pull
every run. A trimmed subset, a few tens of MB, is the shape.

That also makes a repo self-contained in a stronger sense than committing an environment file
does: it can be cloned and run, by a person or by CI, with no local data.

Reference files split the same way. Small curated ones (the testis centroid CSVs) are fine
committed. Anything atlas-sized belongs behind a URL — and if it is cited in a paper, Zenodo,
because the DOI is the part that actually matters there.

## Prune sha-tagged artifacts

Not currently an issue — nothing publishes per-commit artifacts yet. It becomes one if the
build check ever publishes `sha-<commit>` images for a release job to promote. GHCR has a
retention policy setting, or a cleanup step.
