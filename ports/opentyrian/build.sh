#!/usr/bin/env bash
# OpenTyrian. Default joystick assignments are taken from the SDL game
# controller mapping (the GA36-MB d-pad is buttons, not a hat). The Tyrian 2.1
# data is freeware but may not be redistributed: the user downloads it into
# ports/opentyrian/data, which is staged empty.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/opentyrian/opentyrian.git
GAME_COMMIT=5a9d8daa2811347bec3a0c42f8da87682378f3cb
src=$SRC_DIR/opentyrian
log=$BUILD_DIR/opentyrian/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
apply_patches "$src" "$here"/patches/*.patch
cross_pkgconfig

stage=$(stage_dir opentyrian)
game=$stage/ports/opentyrian
make -C "$src" -j"$JOBS" CC="$CROSS_CC" LDFLAGS="$CROSS_LDFLAGS" WITH_NETWORK=false \
    VCS_IDREV="echo v2.1.20260913" > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/data"
llvm-strip -o "$game/opentyrian" "$src/opentyrian"
cp "$src/COPYING" "$game/LICENSE.txt"
cp "$here/run.sh" "$game/"
cp "$here/opentyrian.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/opentyrian.png"
