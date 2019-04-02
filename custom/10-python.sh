#!/bin/bash

xbps-install -Sy bzip2-devel libffi-devel liblzma-devel libressl-devel \
  ncurses-devel readline-devel sqlite-devel zlib-devel \
  || true

# Install pyenv, the specified Python version and additional packages
su -w PYTHON_VERSION - ${USERACCT} bash -c '
PYENV_ROOT=$HOME/.pyenv PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init -)"
test -d $PYENV_ROOT || git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT
pyenv install --skip-existing ${PYTHON_VERSION}
test -d $HOME/.pyenv/plugins/pyenv-virtualenv || git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv
pyenv global ${PYHON_VERSION}

# Python packages
pip install glances pinboard s-tui

# Fix bug in pinboard package
chmod +x $(pyenv which pinboard)
'
