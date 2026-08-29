# The CPU image: everything the pipelines do that is not GPU work.
#
# Built from definitions/common/environment.yml, the same file the GPU image starts from, so a
# package version cannot differ between the step that clusters on a card and the step that
# annotates on a CPU. Nothing here requires CUDA, which is where the size difference comes
# from -- RAPIDS, CUDA and pytorch are the bulk of the GPU image, not the analysis stack.
#
# Build context is definitions/, not this directory, so the shared environment file is visible:
#
#   docker build -f definitions/python_cpu/Dockerfile -t python_cpu:local definitions
FROM mambaorg/micromamba:1.5.10-jammy

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

COPY --chown=$MAMBA_USER:$MAMBA_USER python_cpu/environment.yml /tmp/environment.yml

USER $MAMBA_USER

RUN micromamba create -y -n python_cpu -f /tmp/environment.yml && \
    /opt/conda/envs/python_cpu/bin/python -m ipykernel install --sys-prefix \
        --name python_cpu --display-name "Python (python_cpu)" && \
    micromamba clean --all --yes

ENV PATH=/opt/conda/envs/python_cpu/bin:/opt/conda/bin:$PATH

# The image presents a working environment on its own; a pipeline should not have to set
# environment variables to make it function.
#
# JUPYTER_PATH is the one that bites hardest. Apptainer bind-mounts $HOME, so kernelspecs under
# ~/.local/share/jupyter/kernels are visible inside the container and Quarto resolves a kernel
# from them -- picking an unrelated project's env, which then succeeds with the wrong package
# versions rather than failing outright. Pointing JUPYTER_PATH at the image's own share
# directory makes the container's kernels the only discoverable ones, so a notebook needs no
# `jupyter:` pin and is portable between a conda env and this image.
ENV JUPYTER_PATH=/opt/conda/envs/python_cpu/share/jupyter
ENV CONDA_PREFIX=/opt/conda/envs/python_cpu

ENV MPLCONFIGDIR=/tmp/matplotlib
ENV NUMBA_CACHE_DIR=/tmp/numba-cache
ENV XDG_CACHE_HOME=/tmp/.cache
ENV PYTHONUNBUFFERED=1
ENV SCIPY_ARRAY_API=1

RUN python -c "import nbformat, papermill, yaml, session_info, spatialdata, spatialdata_io, spatialdata_plot, scanpy, squidpy, geopandas, skimage; print('python runtime ok')" && \
    quarto --version

WORKDIR /work

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bash"]
