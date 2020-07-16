FROM jupyter/minimal-notebook:ea01ec4d9f57

RUN conda install -c conda-forge -y nodejs xeus-python=0.8.0 ptvsd ipyleaflet
      
RUN pip install jupyter-lsp jupyterlab-git

RUN jupyter serverextension enable --py jupyterlab_git
      
RUN jupyter labextension install @krassowski/jupyterlab-lsp @jupyterlab/debugger @jupyterlab/git jupyterlab-drawio jupyter-leaflet @jupyterlab/github
      
RUN pip install python-language-server[all]
