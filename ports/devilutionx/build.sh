#!/usr/bin/env bash
# DevilutionX (Diablo): SDL2 game with built-in game controller support,
# 640x480 native. Built without networking; bzip2, libfmt, SDL_audiolib,
# SDL_image and simpleini are vendored and linked statically. fmt 10.0
# (vendored) fails its consteval format string checks with clang, so
# FMT_CONSTEVAL is defined empty. The player puts spawn.mpq (shareware) or
# diabdat.mpq (retail) into ports/devilutionx/data, which is staged empty.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/diasurgical/DevilutionX.git
GAME_COMMIT=7223eeac9e8274fbf665b4de86fda26d3b22c52f
src=$SRC_DIR/devilutionx
log=$BUILD_DIR/devilutionx/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
cross_pkgconfig

stage=$(stage_dir devilutionx)
game=$stage/ports/devilutionx
cross_cmake "$src" "$src/build-goodluck" -DBUILD_TESTING=OFF -DNONET=ON -DPREFILL_PLAYER_NAME=ON -DBUILD_ASSETS_MPQ=OFF \
    -DCMAKE_CXX_FLAGS="$CROSS_FLAGS -DFMT_CONSTEVAL=" -DDISCORD_INTEGRATION=OFF -DDEVILUTIONX_SYSTEM_BZIP2=OFF \
    -DDEVILUTIONX_SYSTEM_LIBFMT=OFF -DDEVILUTIONX_SYSTEM_SDL_AUDIOLIB=OFF -DDEVILUTIONX_SYSTEM_SDL_IMAGE=OFF \
    -DDEVILUTIONX_SYSTEM_SIMPLEINI=OFF > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/data"
llvm-strip -o "$game/devilutionx" "$src/build-goodluck/devilutionx"
cp -r "$src/build-goodluck/assets" "$game/"
cp "$src/LICENSE.md" "$game/LICENSE.txt"
cp "$here/run.sh" "$game/"
cp "$here/devilutionx.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/devilutionx.png"
