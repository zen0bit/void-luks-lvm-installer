#!/bin/bash

xbps-install -Sy emacs-gtk3 ripgrep vim || true

su - ${USERACCT} <<'EOF'
mkdir -p ~/src
test -d ~/src/diff-so-fancy || git clone https://github.com/so-fancy/diff-so-fancy.git ~/src/diff-so-fancy
ln -sfn ~/src/diff-so-fancy/diff-so-fancy ~/.local/bin/
EOF
