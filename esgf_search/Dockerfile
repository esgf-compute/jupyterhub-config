FROM continuumio/miniconda3:4.7.12 as build

COPY esgf_search/ esgf_search/

WORKDIR esgf_search/

RUN conda install -y conda-build anaconda-client && \
      conda build -c conda-forge .

FROM build as publish

ARG CONDA_USERNAME
ENV CONDA_USERNAME $CONDA_USERNAME
ARG CONDA_PASSWORD
ENV CONDA_PASSWORD $CONDA_PASSWORD

RUN anaconda config --set ssl_verify false && \
      anaconda login --username ${CONDA_USERNAME} --password ${CONDA_PASSWORD} && \
      anaconda upload -u cdat --skip $(conda build -c conda-forge . --output)
