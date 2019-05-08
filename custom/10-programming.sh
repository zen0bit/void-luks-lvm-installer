#!/bin/bash

xbps-install -Sy emacs-gtk3 qemu ripgrep vim || true


if [ -n "$USERACCT" ]; then
  # For qemu
  usermod -aG kvm ${USERACCT}
  su - ${USERACCT} <<'EOF'
mkdir -p ~/src
test -d ~/src/diff-so-fancy || git clone https://github.com/so-fancy/diff-so-fancy.git ~/src/diff-so-fancy
mkdir -p ~/.local/bin && ln -sfn ~/src/diff-so-fancy/diff-so-fancy ~/.local/bin/
EOF
fi
