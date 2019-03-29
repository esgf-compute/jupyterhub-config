FROM jupyter/minimal-notebook:41e066e5caa8

WORKDIR /

COPY condarc condarc

COPY startup.sh startup.sh

WORKDIR /home/jovyan

RUN conda install -y -c conda-forge -c cdat nb_conda_kernels nodejs ipywidgets && \
      pip install --no-cache-dir sidecar nbgitpuller && \
      jupyter labextension install @jupyter-widgets/jupyterlab-manager \
                                   @jupyter-widgets/jupyterlab-sidecar \
                                   @jupyterlab/github  && \
      jupyter serverextension enable --py nbgitpuller --sys-prefix && \
      conda clean -a -y
