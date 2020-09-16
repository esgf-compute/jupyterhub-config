ARG BASE_CONTAINER
FROM $BASE_CONTAINER

COPY esgf_search/ esgf_search/

WORKDIR esgf_search/

RUN conda install -y conda-build anaconda-client && \
      conda build -c conda-forge .

ARG CONDA_TOKEN
ENV CONDA_TOKEN $CONDA_TOKEN

RUN anaconda config --set ssl_verify false && \
      anaconda -t ${CONDA_TOKEN} upload -u cdat --skip-existing $(conda build -c conda-forge . --output)
