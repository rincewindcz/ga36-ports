#!/usr/bin/env bash
# Samorost 1 (Amanita Design) on a native player: an AVM2 interpreter runs the game
# code of the user's Main.swf on native Flash, Starling, timeline and audio layers
# (C++20, SDL3, GLES 2). samorost-convert turns the game's textures into a cache on
# the first start; it needs jxrlib and liblzma from Debian, which goodluckOS lacks.
# The game is not included.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

PLAYER_REPO=https://github.com/rincewindcz/samorost-player.git
PLAYER_COMMIT=e6b3706d25fa3a8a0a868d56ad696261e0272574
src=$SRC_DIR/samorost-player
obj=$BUILD_DIR/samorost/obj
log=$BUILD_DIR/samorost/build.log

cross_sysroot
fetch_commit "$src" "$PLAYER_REPO" "$PLAYER_COMMIT"
cross_pkgconfig
deb_index > /dev/null

stage=$(stage_dir samorost)
game=$stage/ports/samorost
rm -rf "$obj"
cross_cmake "$src" "$obj" > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

llvm-strip -o "$game/samorost" "$obj/samorost"
llvm-strip -o "$game/samorost-convert" "$obj/samorost-convert"
mkdir -p "$game/lib"
for lib in libjpegxr.so.0 libjxrglue.so.0 liblzma.so.5; do
    cp -L "$SYSROOT/usr/lib/arm-linux-gnueabihf/$lib" "$game/lib/"
done
deb_notice libjxr0t64 "$SYSROOT" "$game/lib/licenses"
deb_notice liblzma5 "$SYSROOT" "$game/lib/licenses"
cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$src/third_party/minimp3/LICENSE" "$game/LICENSE-minimp3.txt"

cp "$here/run.sh" "$game/"
cp "$here/samorost.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/samorost.png"
