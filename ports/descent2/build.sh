#!/usr/bin/env bash
# Descent 2 on D2X-Rebirth (lib/dxx.sh), OpenGL ES 1 renderer. PhysicsFS comes
# from Debian trixie (absent on goodluckOS). The player puts the game data
# (full version or the free demo) into ports/descent2/data, which is staged
# with the screen mode seed only.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/dxx.sh"

# library and the Debian package it comes from
BUNDLED_LIBS=(libphysfs.so.1:libphysfs1)

mkdir -p "$BUILD_DIR/descent2"
dxx_build d2x-rebirth "$BUILD_DIR/descent2/build.log"

stage=$(stage_dir descent2)
game=$stage/ports/descent2
mkdir -p "$game/lib/licenses" "$game/data"
llvm-strip -o "$game/d2x-rebirth" "$DXX_SRC/build-goodluck/d2x-rebirth/d2x-rebirth"
deb_index
for entry in "${BUNDLED_LIBS[@]}"; do
    cp -L "$SYSROOT/usr/lib/arm-linux-gnueabihf/${entry%%:*}" "$game/lib/"
    deb_notice "${entry##*:}" "$SYSROOT" "$game/lib/licenses"
done
cp "$DXX_SRC/COPYING.txt" "$game/LICENSE.txt"
cp "$DXX_SRC/GPL-3.txt" "$game/GPL-3.txt"
cp "$here/descent.cfg" "$game/goodluck.cfg"
cp "$here/run.sh" "$game/"
cp "$here/descent2.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/descent2.png"
