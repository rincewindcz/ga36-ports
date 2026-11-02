#!/usr/bin/env bash
# Butterscotch, a GameMaker runner, set up to run Undertale: SDL2 with GLES 2 and
# miniaudio, no video playback, physics or FMOD. The game data is not included.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

REPO=https://github.com/ButterscotchRunner/Butterscotch.git
COMMIT=c1260061d1eaeb73974c6a2aafe923604414f82f
src=$SRC_DIR/butterscotch
obj=$BUILD_DIR/undertale/obj
log=$BUILD_DIR/undertale/build.log

cross_sysroot
cross_pkgconfig
fetch_commit "$src" "$REPO" "$COMMIT"
apply_patches "$src" "$here"/patches/*.patch

stage=$(stage_dir undertale)
game=$stage/ports/undertale
rm -rf "$obj"
cross_cmake "$src" "$obj" -DPLATFORM=cli -DBACKEND=sdl2 -DAUDIO_BACKEND=miniaudio -DVIDEO_BACKEND=none \
    -DENABLE_WAD17=OFF -DENABLE_LEGACY_GL=OFF -DENABLE_PHYSICS=OFF -DENABLE_FMOD=OFF \
    -DENABLE_VM_TRACING=OFF -DENABLE_VM_GML_PROFILER=OFF -DENABLE_VM_OPCODE_PROFILER=OFF -DENABLE_VM_STUB_LOGS=OFF \
    -DBUTTERSCOTCH_COMMIT_HASH="$COMMIT" > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

llvm-strip -o "$game/butterscotch" "$obj/butterscotch"
cp "$here/run.sh" "$game/"
cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$src/vendor/miniz/LICENSE" "$game/LICENSE-miniz.txt"
cp "$here/LICENSE-bzip2.txt" "$game/"
cp "$here/undertale.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/undertale.png"
