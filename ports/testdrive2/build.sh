#!/usr/bin/env bash
# Test Drive II Enhanced: the 1989 game on SDL3 with a software road renderer. The patches make that
# renderer affordable on two Cortex-A7 cores and add pad controls. The game data is not included.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"

REPO=https://github.com/kylofon/testdrive2-enhanced.git
COMMIT=3467613011b9aceaaa3355c8128e049ca76c729b
src=$SRC_DIR/testdrive2-enhanced
obj=$BUILD_DIR/testdrive2/obj
log=$BUILD_DIR/testdrive2/build.log

cross_sysroot
fetch_commit "$src" "$REPO" "$COMMIT"
apply_patches "$src" "$here"/patches/*.patch

stage=$(stage_dir testdrive2)
game=$stage/ports/testdrive2
rm -rf "$obj"
cross_cmake "$src" "$obj" > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }

llvm-strip -o "$game/testdrive2-enhanced" "$obj/testdrive2-enhanced"
cp "$here/run.sh" "$here/testdrive2.conf" "$game/"
cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$here/testdrive2.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/testdrive2.png"
