#!/usr/bin/env bash
# Gravity Defied: the C++ and SDL2 rewrite of the 2004 J2ME game. The upstream
# window is already 640x480; the patch adds pad input. libSDL2_ttf comes from
# goodluckOS, so its Debian packages are only needed to build against.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/rgimad/gravity_defied_cpp.git
GAME_COMMIT=91bd283959b96a7ea07e1c4c0040460334c85458
src=$SRC_DIR/gravitydefied
log=$BUILD_DIR/gravitydefied/build.log

cross_sysroot
if [[ ! -f $SYSROOT/usr/include/SDL2/SDL_ttf.h ]]; then
    deb_index
    deb_fetch libsdl2-ttf-dev "$SYSROOT"
    deb_fetch libsdl2-ttf-2.0-0 "$SYSROOT"
fi
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
apply_patches "$src" "$here"/patches/*.patch
cross_pkgconfig

stage=$(stage_dir gravitydefied)
game=$stage/ports/gravitydefied
cross_cmake "$src" "$BUILD_DIR/gravitydefied/obj" > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

llvm-strip -o "$game/GravityDefied" "$BUILD_DIR/gravitydefied/obj/GravityDefied"
cp "$src/assets/levels.mrg" "$game/"
cp "$src/LICENSE.md" "$game/LICENSE.txt"
cp "$here/run.sh" "$game/"
cp "$here/gravitydefied.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/gravitydefied.png"
