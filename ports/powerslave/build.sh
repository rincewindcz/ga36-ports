#!/usr/bin/env bash
# Powerslave (Exhumed) on PCExhumed. The player puts the game data into
# ports/powerslave/data, which is staged empty and which run.sh adds as a search
# path; the config, saves and pcexhumed.pk3 stay next to the binary.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/nblood.sh"

mkdir -p "$BUILD_DIR/powerslave"
nblood_build exhumed "$BUILD_DIR/powerslave/build.log" "$here"/patches/*.patch

stage=$(stage_dir powerslave)
game=$stage/ports/powerslave
mkdir -p "$game/data"
cp "$NBLOOD_SRC/pcexhumed" "$NBLOOD_SRC/pcexhumed.pk3" "$game/"
cp "$NBLOOD_SRC/package/common/gpl-2.0.txt" "$game/LICENSE.txt"
cp "$NBLOOD_SRC/package/common/buildlic.txt" "$game/LICENSE-build.txt"
cp "$here/run.sh" "$game/"
cp "$here/powerslave.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/powerslave.png"
