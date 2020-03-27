FROM jupyter/minimal-notebook:ad3574d3c5c7

RUN conda install -c conda-forge -c cdat \
      nodejs \
      dask distributed xarray xesmf intake metpy netcdf4 pydap graphviz python-graphviz  \
      nb_conda_kernels ipywidgets \
      matplotlib \
      esgf-compute-api esgf-search cdms2 && \
      conda clean -a -y

RUN pip install --no-cache-dir sidecar dask_labextension

RUN jupyter labextension install \
      @jupyter-widgets/jupyterlab-manager @jupyter-widgets/jupyterlab-sidecar dask-labextension
