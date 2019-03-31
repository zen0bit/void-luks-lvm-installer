#!/bin/bash

xbps-install -Sy bzip2-devel libffi-devel liblzma-devel libressl-devel \
  ncurses-devel readline-devel sqlite-devel zlib-devel \
  || true

# Install pyenv, the specified Python version and additional packages
su -w PYTHON_VERSION - ${USERACCT} <<'EOF'
export PYENV_ROOT=$HOME/.pyenv PATH=$PYENV_ROOT/bin:$PATH
test -d $PYENV_ROOT || git clone https://github.com/pyenv/pyenv.git $PYENV_ROOT
pyenv install ${PYTHON_VERSION}
git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv
pyenv global ${PYHON_VERSION}

# Python packages
pip install glances pinboard

# Fix bug in pinboard package
chmod +x $PYENV_ROOT/versions/$PYTHON_VERSION/bin/pinboard
EOF
