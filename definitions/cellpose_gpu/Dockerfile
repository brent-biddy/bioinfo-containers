# Segmentation: the analysis image plus cellpose.
#
# Built FROM python_gpu rather than from python_cpu, because a segmentation workflow reads and
# writes the same objects the analysis steps do -- it loads with spatialdata and may cluster
# with rapids-singlecell in the same run. Splitting them would mean choosing between two images
# inside one pipeline.
#
# The base tag is pinned deliberately: a cellpose_gpu image is only meaningful against a known
# analysis stack, and segmentation output has to be reproducible. Bump it when you mean to.
#
#   docker build -f definitions/cellpose_gpu/Dockerfile -t cellpose_gpu:local definitions
ARG BASE_IMAGE=python_gpu:local
FROM ${BASE_IMAGE}

COPY --chown=$MAMBA_USER:$MAMBA_USER cellpose_gpu/environment.yml /tmp/cellpose.yml

USER $MAMBA_USER

# Installed into the existing env rather than a new one, so there is a single interpreter and
# `python` means the same thing here as it does in the base image.
RUN CONDA_OVERRIDE_CUDA=12.9 micromamba install -y -n python_gpu -f /tmp/cellpose.yml && \
    micromamba clean --all --yes

RUN python -c "import cellpose, torch, spatialdata, rapids_singlecell; \
print('cellpose', cellpose.version); print('cuda build:', torch.version.cuda)"

WORKDIR /work
