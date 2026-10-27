#!/usr/bin/env bash
# Lugaru: SDL2 game with its OpenGL 1.x calls translated to GLES 2 by gl4es
# (lib/gl4es.sh), gamepad input and handheld defaults patched in. OpenAL,
# Vorbis, jsoncpp and libjpeg 6.2 come from Debian trixie (absent or another
# soname on goodluckOS). The game data (CC-BY-SA) comes from the repository.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/gl4es.sh"

GAME_REPO=https://github.com/WolfireGames/lugaru.git
GAME_COMMIT=6a58b62858d9c3c3630abf00bf43075f65a09d38
# library and the Debian package it comes from
BUNDLED_LIBS=(libopenal.so.1:libopenal1 libvorbisfile.so.3:libvorbisfile3 libvorbis.so.0:libvorbis0a
              libogg.so.0:libogg0 libjsoncpp.so.26:libjsoncpp26 libjpeg.so.62:libjpeg62-turbo)
src=$SRC_DIR/lugaru
log=$BUILD_DIR/lugaru/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
apply_patches "$src" "$here"/patches/*.patch
cross_pkgconfig

stage=$(stage_dir lugaru)
game=$stage/ports/lugaru
{
    gl4es_build
    cross_cmake "$src" "$src/build-goodluck" -DOPENGL_gl_LIBRARY="$GL4ES_LIB"
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/lib/licenses"
llvm-strip -o "$game/lugaru" "$src/build-goodluck/lugaru"
llvm-strip -o "$game/lib/libGL.so.1" "$GL4ES_LIB"
deb_index
for entry in "${BUNDLED_LIBS[@]}"; do
    cp -L "$SYSROOT/usr/lib/arm-linux-gnueabihf/${entry%%:*}" "$game/lib/"
    deb_notice "${entry##*:}" "$SYSROOT" "$game/lib/licenses"
done
cp "$GL4ES_SRC/LICENSE" "$game/lib/licenses/gl4es.txt"
cp -r "$src/Data" "$game/"
cp "$src/COPYING.txt" "$game/LICENSE.txt"
cp "$src/CONTENT-LICENSE.txt" "$game/"
cp "$here/run.sh" "$game/"
cp "$here/lugaru.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/lugaru.png"
