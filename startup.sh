#! /bin/bash

if [[ ! -e "${HOME}/.condarc" ]];
then
  cp /condarc ${HOME}/.condarc

  [[ -e "${HOME}/getting_started.ipynb" ]] && rm ${HOME}/getting_started.ipynb

  wget https://raw.githubusercontent.com/esgf-nimbus/getting_started/master/getting_started.ipynb
fi
