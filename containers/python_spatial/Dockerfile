FROM mambaorg/micromamba:1.5.10-cuda12.5.1-ubuntu22.04

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

COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml

USER $MAMBA_USER

RUN micromamba create -y -n python_spatial -f /tmp/environment.yml && \
    /opt/conda/envs/python_spatial/bin/python -m ipykernel install --sys-prefix --name python_spatial --display-name "Python (python_spatial)" && \
    micromamba clean --all --yes

ENV PATH=/opt/conda/envs/python_spatial/bin:/opt/conda/bin:$PATH
ENV MPLCONFIGDIR=/tmp/matplotlib
ENV NUMBA_CACHE_DIR=/tmp/numba-cache
ENV XDG_CACHE_HOME=/tmp/.cache
ENV PYTHONUNBUFFERED=1

RUN python - <<'PY'
import nbformat
import papermill
import yaml
import session_info
import spatialdata
import spatialdata_io
import spatialdata_plot
import scanpy
import squidpy
import rapids_singlecell
print("python runtime ok")
PY

WORKDIR /work

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bash"]
