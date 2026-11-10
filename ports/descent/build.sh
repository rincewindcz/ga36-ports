#!/usr/bin/env bash
# Descent on D1X-Rebirth (lib/dxx.sh), OpenGL ES 1 renderer. PhysicsFS comes
# from Debian trixie (absent on goodluckOS). The unmodified shareware archive
# desc14sw.tar.gz is shipped as a whole, as its licence requires; run.sh
# unpacks descent.hog and descent.pig into data/ on the first start.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/dxx.sh"

SHAREWARE_URL=https://icculus.org/d2x/data/desc14sw.tar.gz
SHAREWARE_SHA256=8b65eda01d03401d7a2dc71976528fbb7e0b07a93ce8ee0a9f1d9103623ae249
# library and the Debian package it comes from
BUNDLED_LIBS=(libphysfs.so.1:libphysfs1)
shareware=$DL_DIR/desc14sw.tar.gz

mkdir -p "$BUILD_DIR/descent"
fetch_file "$SHAREWARE_URL" "$SHAREWARE_SHA256" "$shareware"
dxx_build d1x-rebirth "$BUILD_DIR/descent/build.log"

stage=$(stage_dir descent)
game=$stage/ports/descent
mkdir -p "$game/lib/licenses" "$game/data" "$game/shareware"
llvm-strip -o "$game/d1x-rebirth" "$DXX_SRC/build-goodluck/d1x-rebirth/d1x-rebirth"
deb_index
for entry in "${BUNDLED_LIBS[@]}"; do
    cp -L "$SYSROOT/usr/lib/arm-linux-gnueabihf/${entry%%:*}" "$game/lib/"
    deb_notice "${entry##*:}" "$SYSROOT" "$game/lib/licenses"
done
cp "$DXX_SRC/COPYING.txt" "$game/LICENSE.txt"
cp "$DXX_SRC/GPL-3.txt" "$game/GPL-3.txt"
cp "$shareware" "$game/shareware/"
tar -xzOf "$shareware" desc14sw/readme.txt > "$game/shareware/README.TXT"
cp "$here/descent.cfg" "$game/goodluck.cfg"
cp "$here/run.sh" "$game/"
cp "$here/descent.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/descent.png"
