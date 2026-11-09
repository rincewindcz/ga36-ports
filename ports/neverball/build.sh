#!/usr/bin/env bash
# Neverball: SDL2 game with its OpenGL 1.x calls translated to GLES 2 by gl4es
# (lib/gl4es.sh), as in the upstream web build. The levels are compiled from
# .map to .sol by a host build of mapc. Vorbisfile, Vorbis, Ogg and libjpeg
# come from Debian trixie; goodluckOS has no Vorbis and a different libjpeg.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/gl4es.sh"

GAME_REPO=https://github.com/Neverball/neverball.git
GAME_COMMIT=9e7e477a792e3a2dbe2a928c632a9b5b520ddbc3
GAME_VERSION="1.7.0-alpha.3 (9e7e477a)"
# library and the Debian package it comes from
BUNDLED_LIBS=(libvorbisfile.so.3:libvorbisfile3 libvorbis.so.0:libvorbis0a libogg.so.0:libogg0
              libjpeg.so.62:libjpeg62-turbo)
src=$SRC_DIR/neverball
log=$BUILD_DIR/neverball/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
apply_patches "$src" "$here"/patches/*.patch
# A shallow checkout has no tags for scripts/version.sh.
echo "$GAME_VERSION" > "$src/neverball-version.txt"

stage=$(stage_dir neverball)
game=$stage/ports/neverball
{
    gl4es_build
    make -C "$src" clean
    make -C "$src" -j"$JOBS" BUILD=release ENABLE_FETCH=0 mapc
    make -C "$src" -j"$JOBS" BUILD=release ENABLE_FETCH=0 sols locales
    find "$src/share" -name '*.[od]' -delete

    cross_pkgconfig
    make -C "$src" -j"$JOBS" BUILD=release ENABLE_FETCH=0 CC="$CROSS_CC" LDFLAGS="$CROSS_LDFLAGS" \
        CPPFLAGS="-DNDEBUG -DUSE_GL4ES" \
        SDL_CPPFLAGS="$(pkg-config --cflags sdl2)" SDL_LIBS="$(pkg-config --libs sdl2)" \
        PNG_CPPFLAGS="$(pkg-config --cflags libpng)" PNG_LIBS="$(pkg-config --libs libpng)" \
        JPEG_CPPFLAGS="$(pkg-config --cflags libjpeg)" JPEG_LIBS="$(pkg-config --libs libjpeg)" \
        OGL_LIBS="$GL4ES_LIB" neverball
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/lib/licenses"
llvm-strip -o "$game/neverball" "$src/neverball"
llvm-strip -o "$game/lib/libGL.so.1" "$GL4ES_LIB"
deb_index
for entry in "${BUNDLED_LIBS[@]}"; do
    cp -L "$SYSROOT/usr/lib/arm-linux-gnueabihf/${entry%%:*}" "$game/lib/"
    deb_notice "${entry##*:}" "$SYSROOT" "$game/lib/licenses"
done
cp "$GL4ES_SRC/LICENSE" "$game/lib/licenses/gl4es.txt"
(cd "$src" && find data -name '*.map' -prune -o -type f -print | cpio -pdm --quiet "$game")
cp -r "$src/locale" "$game/"
cp -r "$src/doc/legal" "$game/legal"
cp "$src/LICENSE.md" "$game/LICENSE.md"
cp "$here/neverballrc" "$here/run.sh" "$game/"
cp "$here/neverball.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/neverball.png"
