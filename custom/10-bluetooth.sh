#!/bin/bash

xbps-install -Sy bluez obexfs || true

# Dependencies for compiling https://github.com/EHfive/pulseaudio-modules-bt
xbps-install -Sy pulseaudio-devel sbc-devel fdk-aac fdk-aac-devel \
  ffmpeg-devel libltdl-devel libbluetooth-devel || true

# Build PulseAudio Bluetooth modules (AAC, APTX, APTX-HD, LDAC)
mkdir ~/src
git clone https://github.com/EHfive/pulseaudio-modules-bt.git
cd pulseaudio-modules-bt
git submodule update --init

git clone https://github.com/EHfive/ldacBT.git
cd ldacBT
git submodule update --init
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DINSTALL_LIBDIR=/usr/lib \
    -DLDAC_SOFT_FLOAT=OFF \
    ../
make install
cd ../../

git -C pa/ checkout master
mkdir build && cd build
cmake -DFORCE_LARGEST_PA_VERSION=ON ..
make
make install

# Enable services
ln -sfn /etc/sv/dbus /var/service/
ln -sfn /etc/sv/bluetoothd /var/service/

if [ -n "$USERACCT" ]; then
  usermod -aG bluetooth ${USERACCT}
fi
