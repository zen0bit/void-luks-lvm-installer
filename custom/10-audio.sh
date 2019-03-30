#!/bin/bash

xbps-install -Sy alsa-utils || true

usermod -aG audio ${USERACCT}
