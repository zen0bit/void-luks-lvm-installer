#!/bin/bash

xbps-install -Sy emacs-gtk3 ripgrep vim || true

su - ${USERACCT} <<'EOF'
mkdir -p ~/src
git clone https://github.com/so-fancy/diff-so-fancy.git ~/src/diff-so-fancy
ln -s ~/src/diff-so-fancy/diff-so-fancy ~/.local/bin/
EOF
