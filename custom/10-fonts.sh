#!/bin/bash

FONTDIR=/usr/share/fonts/TTF
mkdir -p "$FONTDIR"
TEMPDIR=$(mktemp -d)
cd "$TEMPDIR"

wget --no-verbose \
  https://github.com/be5invis/Iosevka/releases/download/v2.2.0/iosevka-term-ss08-2.2.0.zip \
  https://github.com/zavoloklom/material-design-iconic-font/releases/download/2.2.0/material-design-iconic-font.zip \
  https://github.com/AppleDesignResources/SanFranciscoFont/archive/master.zip \
  https://github.com/CartoDB/cartodb/blob/master/app/assets/fonts/helvetica.ttf \
  https://github.com/meloncholy/mt-stats-viewer/blob/master/public/fonts/segoe-ui/segoeui.ttf

for f in $(ls *.zip); do
  unzip "$f"
done

cp -r ttf $FONTDIR/iosevka
cp -r SanFranciscoFont-master $FONTDIR/SanFrancisco
cp fonts/*.ttf helvetica.ttf segoeui.ttf $FONTDIR/

# Since we're installing a font here, `fc-cache` will be run
# automatically, otherwise we'd need to run it manually.
xbps-install -Sy fonts-roboto-ttf google-fonts-ttf gucharmap || true
