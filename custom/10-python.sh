#!/bin/bash

xbps-install -Sy bzip2-devel libffi-devel liblzma-devel libressl-devel \
  ncurses-devel readline-devel sqlite-devel zlib-devel \
  || true

# Install pyenv and specified Python version
su -w PYTHON_VERSION - ${USERACCT} <<'EOF'
test -d ~/.pyenv || git clone https://github.com/pyenv/pyenv.git ~/.pyenv
PYENV_ROOT=$HOME/.pyenv PATH=$PYENV_ROOT/bin:$PATH pyenv install ${PYTHON_VERSION}
git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv
EOF
