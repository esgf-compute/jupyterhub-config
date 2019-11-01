FROM jupyter/minimal-notebook:1386e2046833

RUN conda install -c conda-forge -c cdat \
      nodejs dask distributed \
      nb_conda_kernels ipywidgets \
      matplotlib \
      esgf-compute-api cdms2 && \
      conda clean -a -y

RUN pip install --no-cache-dir sidecar dask_labextension

RUN jupyter labextension install \
      @jupyter-widgets/jupyterlab-manager @jupyter-widgets/jupyterlab-sidecar dask-labextension
