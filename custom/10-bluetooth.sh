#!/bin/bash

xbps-install -Sy bluez obexfs || true

# Dependencies for compiling https://github.com/EHfive/pulseaudio-modules-bt
xbps-install -Sy pulseaudio-devel sbc-devel fdk-aac fdk-aac-devel \
  ffmpeg-devel libltdl-devel libbluetooth-devel || true

export CLONEPATH="$HOME/src"

if [ -n "$USERACCT" ]; then
  usermod -aG bluetooth ${USERACCT}
  CLONEPATH="/home/${USERACCT}/src"
fi

export BTMODPATH="$CLONEPATH/pulseaudio-modules-bt"

# Build PulseAudio Bluetooth modules (AAC, APTX, APTX-HD, LDAC)
su -w CLONEPATH,BTMODPATH - "${USERACCT-root}" bash -c '
test -d $BTMODPATH && exit 0
mkdir -p $CLONEPATH && cd $_

git clone https://github.com/EHfive/pulseaudio-modules-bt.git
cd pulseaudio-modules-bt
git submodule update --init

git clone https://github.com/EHfive/ldacBT.git
cd ldacBT
git submodule update --init
mkdir -p build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DINSTALL_LIBDIR=/usr/lib \
    -DLDAC_SOFT_FLOAT=OFF \
    ../
'

(cd "$BTMODPATH/build" && make install)

su -w CLONEPATH,BTMODPATH - "${USERACCT-root}" bash -c '
cd "$BTMODPATH"
git -C pa/ checkout master
mkdir -p build && cd build
cmake -DFORCE_LARGEST_PA_VERSION=ON ..
make
'

(cd "$BTMODPATH/build" && make install)

# Enable services
ln -sfn /etc/sv/dbus /etc/runit/runsvdir/default/
ln -sfn /etc/sv/bluetoothd /etc/runit/runsvdir/default/
