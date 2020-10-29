#!/bin/bash

xbps-install -Sy bat exa expect fd fzf moreutils parallel pv zsh || true

chsh -s /bin/zsh ivan
