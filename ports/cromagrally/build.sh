#!/usr/bin/env bash
# Cro-Mag Rally: SDL3 game with its OpenGL 1.x calls translated to GLES 2 by
# gl4es (lib/gl4es.sh). The game data comes from the repository.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/gl4es.sh"

GAME_REPO=https://github.com/jorio/CroMagRally.git
GAME_COMMIT=370fc175466d6ced3612afb7b171c958cb6b76e1
src=$SRC_DIR/cromagrally
log=$BUILD_DIR/cromagrally/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
git -C "$src" submodule update -q --init --recursive --depth 1
apply_patches "$src" "$here"/patches/*.patch

stage=$(stage_dir cromagrally)
game=$stage/ports/cromagrally
{
    gl4es_build
    cross_cmake "$src" "$src/build-goodluck" \
        -DOpenGL_GL_PREFERENCE=LEGACY -DOPENGL_gl_LIBRARY="$GL4ES_LIB"
} > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/lib"
llvm-strip -o "$game/CroMagRally" "$src/build-goodluck/CroMagRally"
llvm-strip -o "$game/lib/libGL.so.1" "$GL4ES_LIB"
cp -r "$src/Data" "$game/"
cp "$src/LICENSE.md" "$game/LICENSE.txt"
cp "$GL4ES_SRC/LICENSE" "$game/lib/LICENSE-gl4es.txt"
cp "$here/run.sh" "$game/"
cp "$here/cromagrally.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/cromagrally.png"
