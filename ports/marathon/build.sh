#!/usr/bin/env bash
# Marathon on Aleph One 1.11.1: SDL2 engine with its software renderer (the
# OpenGL renderer needs desktop GL). OpenAL, libsndfile with its codecs, Vorbis
# and Boost.Filesystem come from Debian trixie (absent on goodluckOS). The game
# data is Aleph One's unmodified Marathon release package.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/Aleph-One-Marathon/alephone.git
GAME_COMMIT=fc4c274359088614b58c91af5daa541504cb50cf
DATA_URL=https://github.com/Aleph-One-Marathon/alephone/releases/download/release-20260930/Marathon-20260930-Data.zip
DATA_SHA256=d598daaf7e300df6c7097e603b7d68307c4a2ca66488cbe436cd88d5de23f84e
# library and the Debian package it comes from
BUNDLED_LIBS=(libopenal.so.1:libopenal1 libsndfile.so.1:libsndfile1 libFLAC.so.14:libflac14
              libopus.so.0:libopus0 libmp3lame.so.0:libmp3lame0 libmpg123.so.0:libmpg123-0t64
              libvorbis.so.0:libvorbis0a libvorbisenc.so.2:libvorbisenc2 libogg.so.0:libogg0
              libboost_filesystem.so.1.83.0:libboost-filesystem1.83.0)
src=$SRC_DIR/alephone
obj=$BUILD_DIR/marathon/obj
data=$DL_DIR/Marathon-20260930-Data.zip
log=$BUILD_DIR/marathon/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
fetch_file "$DATA_URL" "$DATA_SHA256" "$data"
apply_patches "$src" "$here"/patches/*.patch
cross_pkgconfig

stage=$(stage_dir marathon)
game=$stage/ports/marathon
mkdir -p "$obj"
{
    [[ -x $src/configure ]] || (cd "$src" && autoreconf -fi)
    # The sysroot has no freetype2, harfbuzz, libtiff or libwebp .pc files that
    # SDL2_ttf.pc and SDL2_image.pc require.
    (cd "$obj" && SDL_TTF_CFLAGS="-I$SYSROOT/usr/include/SDL2" SDL_TTF_LIBS=-lSDL2_ttf \
        SDL_IMAGE_CFLAGS="-I$SYSROOT/usr/include/SDL2" SDL_IMAGE_LIBS=-lSDL2_image \
        "$src/configure" --host=arm-linux-gnueabihf --build=x86_64-pc-linux-gnu \
        CC="$CROSS_CC" CXX="$CROSS_CXX" CFLAGS=-O2 CXXFLAGS=-O2 LDFLAGS="$CROSS_LDFLAGS" \
        --disable-opengl --with-boost="$SYSROOT/usr" --with-boost-libdir="$SYSROOT/usr/lib/arm-linux-gnueabihf" \
        --without-curl --without-zzip --without-miniupnpc --without-matroska --without-vpx --without-ebml \
        --without-vorbis --without-vorbisenc --without-libyuv --without-nfd --without-catch2)
    make -C "$obj" -j"$JOBS"
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/lib/licenses" "$game/share/Plugins"
llvm-strip -o "$game/alephone" "$obj/Source_Files/alephone"
deb_index
for entry in "${BUNDLED_LIBS[@]}"; do
    cp -L "$SYSROOT/usr/lib/arm-linux-gnueabihf/${entry%%:*}" "$game/lib/"
    deb_notice "${entry##*:}" "$SYSROOT" "$game/lib/licenses"
done
cp -r "$src/data/default_theme" "$game/share/Plugins/Default_Theme"
rm "$game/share/Plugins/Default_Theme/Makefile.am" "$game/share/Plugins/Default_Theme/Makefile.in"
cp "$src/COPYING" "$game/LICENSE.txt"
unzip -q "$data" -d "$BUILD_DIR/marathon/data"
mv "$BUILD_DIR/marathon/data/Marathon" "$game/data"
rm -rf "$BUILD_DIR/marathon/data"
cp "$here/run.sh" "$game/"
cp "$here/marathon.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/marathon.png"
