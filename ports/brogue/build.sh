#!/usr/bin/env bash
# Brogue CE. patches/0001 adds the compact view for 640x480 (the 80 columns
# right of the sidebar at 8x14 pixel cells, the sidebar as a panel over the
# map, a health bar), gamepad input and arrow key navigation in menus.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/tmewett/BrogueCE.git
GAME_COMMIT=1ba4240b7a928ddf0ffb772717bf1d433cd63804
src=$SRC_DIR/brogue
log=$BUILD_DIR/brogue/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
apply_patches "$src" "$here"/patches/*.patch
cross_pkgconfig

stage=$(stage_dir brogue)
game=$stage/ports/brogue
make -C "$src" -j"$JOBS" CC="$CROSS_CC" LDFLAGS="$CROSS_LDFLAGS" SDL_CONFIG="pkg-config sdl2" \
    RELEASE=YES DATADIR=. > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

llvm-strip -o "$game/brogue" "$src/bin/brogue"
cp -r "$src/bin/assets" "$game/"
cp "$src/bin/keymap.txt" "$game/"
cp "$src/LICENSE.txt" "$game/"
cp "$here/run.sh" "$game/"
cp "$here/brogue.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/brogue.png"
