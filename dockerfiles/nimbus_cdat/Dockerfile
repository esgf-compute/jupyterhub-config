ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN conda install -c conda-forge -c cdat \
      nodejs \
      dask distributed xarray xesmf metpy netcdf4 pydap \
      intake panel \
      graphviz python-graphviz  \
      nb_conda_kernels ipywidgets \
      matplotlib \
      esgf-compute-api esgf-search cdms2 && \
      conda clean -a -y

RUN pip install --no-cache-dir \
      sidecar \
      dask_labextension

RUN jupyter labextension install \
      @jupyter-widgets/jupyterlab-manager \
      @jupyter-widgets/jupyterlab-sidecar \
      dask-labextension
