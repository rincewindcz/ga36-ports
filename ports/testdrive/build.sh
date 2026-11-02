#!/usr/bin/env bash
# Test Drive Enhanced: the 1987 game on SDL3 with a software road renderer. The
# patches make that renderer affordable on two Cortex-A7 cores and add pad
# controls. The game data is not included.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

REPO=https://github.com/kylofon/testdrive-enhanced.git
COMMIT=fdb7972b5d75578a8849a15d8aef7201b208827e
src=$SRC_DIR/testdrive-enhanced
obj=$BUILD_DIR/testdrive/obj
log=$BUILD_DIR/testdrive/build.log

cross_sysroot
fetch_commit "$src" "$REPO" "$COMMIT"
apply_patches "$src" "$here"/patches/*.patch

stage=$(stage_dir testdrive)
game=$stage/ports/testdrive
rm -rf "$obj"
cross_cmake "$src" "$obj" -DTDE_LAUNCHER=OFF > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

llvm-strip -o "$game/testdrive-enhanced" "$obj/testdrive-enhanced"
cp "$here/run.sh" "$here/testdrive.conf" "$game/"
cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$src/licenses/amiga-topaz/license.txt" "$game/LICENSE-amiga-topaz.txt"
cp "$here/testdrive.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/testdrive.png"
