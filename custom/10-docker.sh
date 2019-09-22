#!/bin/bash

xbps-install -Sy buildah cri-o docker docker-compose podman skopeo || true

# Enable service
ln -sfn /etc/sv/docker /etc/runit/runsvdir/default/
