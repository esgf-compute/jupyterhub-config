FROM jupyter/minimal-notebook:41e066e5caa8

WORKDIR /

COPY condarc condarc

COPY startup.sh startup.sh

WORKDIR /home/jovyan

RUN conda install -y -c cdat/label/nightly -c conda-forge -c cdat -c plotly \
      nb_conda_kernels nodejs ipywidgets esgf-compute-api=devel bokeh jupyterlab-dash=0.1.0a2 \
      cdms2=3.1.2 libcdms=3.1.2 cdtime=3.1.2 libdrs=3.1.2 libdrs_f=3.1.2 dask distributed && \
      pip install --no-cache-dir sidecar nbgitpuller dask_labextension && \
      jupyter labextension install @jupyter-widgets/jupyterlab-manager \
                                   @jupyter-widgets/jupyterlab-sidecar \
                                   @jupyterlab/github \
                                   dask-labextension \
                                   jupyterlab_bokeh \
                                   jupyterlab-dash@0.1.0-alpha.2 && \
      jupyter serverextension enable --py nbgitpuller --sys-prefix && \
      conda clean -a -y
