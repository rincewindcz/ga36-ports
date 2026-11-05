#!/usr/bin/env bash
# Quake on QuakeSpasm: SDL2 engine with its OpenGL 1.x calls translated to
# GLES 2 by gl4es (lib/gl4es.sh). Tremor and Ogg come from Debian trixie for
# Ogg music of the full versions. The unmodified shareware quake106.zip is
# shipped as a whole, as its licence requires; run.sh extracts id1/pak0.pak
# from its LHA archive resource.1 with lhasa on the first start.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/gl4es.sh"

GAME_REPO=https://github.com/sezero/quakespasm.git
GAME_COMMIT=e8795a79273f2823661727265d0617106e282bea
LHASA_REPO=https://github.com/fragglet/lhasa.git
LHASA_COMMIT=75ed83559f23e9538e0045c62f53f77ab03d03d6
SHAREWARE_URL=https://ftp.gwdg.de/pub/misc/ftp.idsoftware.com/idstuff/quake/quake106.zip
SHAREWARE_SHA256=ec6c9d34b1ae0252ac0066045b6611a7919c2a0d78a3a66d9387a8f597553239
# library and the Debian package it comes from
BUNDLED_LIBS=(libvorbisidec.so.1:libvorbisidec1 libogg.so.0:libogg0)
src=$SRC_DIR/quakespasm
lhasa=$SRC_DIR/lhasa
shareware=$DL_DIR/quake106.zip
log=$BUILD_DIR/quake/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
fetch_commit "$lhasa" "$LHASA_REPO" "$LHASA_COMMIT"
fetch_file "$SHAREWARE_URL" "$SHAREWARE_SHA256" "$shareware"
apply_patches "$src" "$here"/patches/*.patch
cross_pkgconfig

stage=$(stage_dir quake)
game=$stage/ports/quake
mkdir -p "$BUILD_DIR/quake/lhasa"
{
    gl4es_build
    make -C "$src/Quake" clean
    make -C "$src/Quake" -j"$JOBS" USE_SDL2=1 CC="$CROSS_CC" LDFLAGS="$CROSS_LDFLAGS" CPUFLAGS=-DUSE_GL4ES \
        SDL_CFLAGS="$(pkg-config --cflags sdl2)" SDL_LIBS="$(pkg-config --libs sdl2)" \
        COMMON_LIBS="$GL4ES_LIB -lm" USE_CODEC_MP3=0 VORBISLIB=tremor

    printf '#define PACKAGE_NAME "lhasa"\n#define PACKAGE_VERSION "%s"\n' "$LHASA_COMMIT" \
        > "$BUILD_DIR/quake/lhasa/config.h"
    mapfile -t lhasa_srcs < <(sed -n '/^SRC =/,/^$/p' "$lhasa/lib/Makefile.am" | grep -o '[a-z0-9_]*\.c' |
        sed "s|^|$lhasa/lib/|")
    $CROSS_CC -O2 $CROSS_LDFLAGS -I"$BUILD_DIR/quake/lhasa" -I"$lhasa" -I"$lhasa/lib" -I"$lhasa/lib/public" \
        -o "$BUILD_DIR/quake/lhasa/lha" "${lhasa_srcs[@]}" "$lhasa"/src/*.c
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/lib/licenses" "$game/bin" "$game/data/id1" "$game/shareware"
llvm-strip -o "$game/quakespasm" "$src/Quake/quakespasm"
llvm-strip -o "$game/bin/lha" "$BUILD_DIR/quake/lhasa/lha"
llvm-strip -o "$game/lib/libGL.so.1" "$GL4ES_LIB"
deb_index
for entry in "${BUNDLED_LIBS[@]}"; do
    cp -L "$SYSROOT/usr/lib/arm-linux-gnueabihf/${entry%%:*}" "$game/lib/"
    deb_notice "${entry##*:}" "$SYSROOT" "$game/lib/licenses"
done
cp "$GL4ES_SRC/LICENSE" "$game/lib/licenses/gl4es.txt"
cp "$lhasa/COPYING.md" "$game/lib/licenses/lhasa.txt"
cp "$here/icon.png.license" "$game/lib/licenses/icon.txt"
cp "$src/LICENSE.txt" "$game/LICENSE.txt"
cp "$src/Quake/quakespasm.pak" "$game/data/"
cp "$here/goodluck.cfg" "$game/data/id1/"
cp "$shareware" "$game/shareware/"
unzip -p "$shareware" resource.1 > "$BUILD_DIR/quake/resource.1"
7z e -so "$BUILD_DIR/quake/resource.1" SLICNSE.TXT > "$game/shareware/SLICNSE.TXT" 2> /dev/null
cp "$here/run.sh" "$game/"
cp "$here/quake.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/quake.png"
