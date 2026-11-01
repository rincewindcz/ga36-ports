#!/usr/bin/env bash
# xrick: Rick Dangerous and Rick Dangerous II on SDL3. The game data is compiled
# into the binary. The patch adds pad input and drops the desktop GL shader chain.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/zpqrtbnk/xrick.git
GAME_COMMIT=b39351355ac7b6d3de7879460ef5c22242fb53dd
src=$SRC_DIR/xrick
log=$BUILD_DIR/xrick/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
apply_patches "$src" "$here"/patches/*.patch

stage=$(stage_dir xrick)
game=$stage/ports/xrick
# sdl3.pc requires the audio backends of Debian's SDL3, which the sysroot lacks.
CC="$CROSS_CC" CXX="$CROSS_CXX" LDFLAGS="$CROSS_LDFLAGS" make -C "$src/xrick" -j"$JOBS" SDL_CFLAGS= SDL_LIBS=-lSDL3 > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

llvm-strip -o "$game/xrick" "$src/build/wsl/xrick"
cp "$src/README.md" "$game/README.md"
cp "$src/xrick/src/audio_engine/LICENSE" "$game/LICENSE-AtariAudio.txt"
cp "$here/run.sh" "$game/"
cp "$here/xrick.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/xrick.png"
