#!/usr/bin/env bash
# Gates of Skeldal (Brány Skeldalu): Ondřej Novák's SDL2 port, 640x480 native.
# Upstream builds with gcc and -Werror; the clang warnings it lacks are kept as
# warnings. file_to_base64 runs at build time under qemu-arm. The game data is
# not redistributable: the player puts it into ports/skeldal/data (skeldal.ini
# sets it as the root), which is staged empty. The repository's fixed
# BILA_VEZ.MAP is copied over the original one by run.sh.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

GAME_REPO=https://github.com/ondra-novak/gates_of_skeldal.git
GAME_COMMIT=ecf8f5c62cde4e6c4df98c68f3bfb25ab8894d9c
WNOERROR="-Wno-error=unused-but-set-global -Wno-error=unused-variable"
src=$SRC_DIR/skeldal
log=$BUILD_DIR/skeldal/build.log

cross_sysroot
fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
cross_pkgconfig

stage=$(stage_dir skeldal)
game=$stage/ports/skeldal
cross_cmake "$src" "$src/build-goodluck" -DCMAKE_C_FLAGS="$CROSS_FLAGS $WNOERROR" -DCMAKE_CXX_FLAGS="$CROSS_FLAGS $WNOERROR" \
    -DCMAKE_CROSSCOMPILING_EMULATOR="qemu-arm;-L;$SYSROOT" > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

mkdir -p "$game/data"
llvm-strip -o "$game/skeldal" "$src/build-goodluck/bin/skeldal_bin"
cp "$src/data/maps/BILA_VEZ.MAP" "$game/"
cp -r "$src/lang" "$game/"
cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$here/run.sh" "$here/skeldal.ini" "$game/"
cp "$here/skeldal.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/skeldal.png"
