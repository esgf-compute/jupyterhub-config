FROM jupyter/minimal-notebook:ea01ec4d9f57

RUN conda install -c conda-forge -y nodejs xeus-python=0.8.0 ptvsd ipyleaflet && \
      pip install jupyter-lsp jupyterlab-git && \
      jupyter serverextension enable --py jupyterlab_git && \
      jupyter labextension install @krassowski/jupyterlab-lsp @jupyterlab/debugger @jupyterlab/git jupyterlab-drawio jupyter-leaflet @jupyterlab/github && \
      pip install python-language-server[all] && \
      conda clean -a -y 
