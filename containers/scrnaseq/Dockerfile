FROM mambaorg/micromamba:1.5.10

LABEL org.opencontainers.image.description="Single-cell RNA-seq analysis environment"

COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/env.yml

RUN micromamba install -y -n base -f /tmp/env.yml && \
    micromamba clean --all --yes

SHELL ["/usr/local/bin/_dockerfile_shell.sh"]

WORKDIR /work
