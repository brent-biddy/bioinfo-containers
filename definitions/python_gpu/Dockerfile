# The GPU image: the analysis stack plus RAPIDS, for steps that cluster on a card.
#
# Built from definitions/python_cpu/environment.yml plus this directory's overlay, so the
# analysis packages are the same file the CPU image uses and cannot drift between them.
#
# Replaces python_spatial, which is frozen and will be retired once the repos move over.
#
#   docker build -f definitions/python_gpu/Dockerfile -t python_gpu:local definitions
FROM mambaorg/micromamba:1.5.10-jammy-cuda-12.5.1

ARG QUARTO_VERSION=1.6.42

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gdebi-core \
        git \
        procps \
        tini && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /tmp/quarto.deb \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" && \
    gdebi -n /tmp/quarto.deb && \
    rm -f /tmp/quarto.deb

# Both halves: the shared analysis stack, and the CUDA packages layered on top of it.
COPY --chown=$MAMBA_USER:$MAMBA_USER python_cpu/environment.yml /tmp/base.yml
COPY --chown=$MAMBA_USER:$MAMBA_USER python_gpu/environment.yml /tmp/overlay.yml

USER $MAMBA_USER

# -n overrides the name in each file, so one env holds both and `python` means one interpreter.
# CONDA_OVERRIDE_CUDA lets the solver pick CUDA builds without a driver present at build time.
RUN CONDA_OVERRIDE_CUDA=12.9 micromamba create -y -n python_gpu -f /tmp/base.yml && \
    CONDA_OVERRIDE_CUDA=12.9 micromamba install -y -n python_gpu -f /tmp/overlay.yml && \
    /opt/conda/envs/python_gpu/bin/python -m ipykernel install --sys-prefix \
        --name python_gpu --display-name "Python (python_gpu)" && \
    micromamba clean --all --yes

ENV PATH=/opt/conda/envs/python_gpu/bin:/opt/conda/bin:$PATH

# The image presents a working environment on its own; a pipeline should not have to set
# environment variables to make it function.
#
# JUPYTER_PATH is the one that bites hardest. Apptainer bind-mounts $HOME, so kernelspecs under
# ~/.local/share/jupyter/kernels are visible inside the container and Quarto resolves a kernel
# from them -- picking an unrelated project's env, which then succeeds with the wrong package
# versions rather than failing outright. Pointing it at the image's own share directory makes
# the container's kernels the only discoverable ones, so a notebook needs no `jupyter:` pin.
#
# CONDA_PREFIX because cupy JIT-compiles kernels and finds the CUDA headers under it, and the
# non-login shell a Nextflow `script:` block uses never sets it.
ENV JUPYTER_PATH=/opt/conda/envs/python_gpu/share/jupyter
ENV CONDA_PREFIX=/opt/conda/envs/python_gpu

ENV MPLCONFIGDIR=/tmp/matplotlib
ENV NUMBA_CACHE_DIR=/tmp/numba-cache
ENV XDG_CACHE_HOME=/tmp/.cache
# cupy's JIT kernel cache defaults to ~/.cupy, which does not respect XDG_CACHE_HOME and is not
# guaranteed writable for whatever user runs it.
ENV CUPY_CACHE_DIR=/tmp/cupy-cache
ENV PYTHONUNBUFFERED=1
ENV SCIPY_ARRAY_API=1

RUN mkdir -p /tmp/cupy-cache && \
    python -c "import nbformat, papermill, yaml, session_info, spatialdata, spatialdata_io, spatialdata_plot, scanpy, squidpy, rapids_singlecell; print('python runtime ok')" && \
    quarto --version

WORKDIR /work

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bash"]
