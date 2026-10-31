#!/usr/bin/env bash
# Blood on NBlood. The player puts the game data into ports/blood/data, which
# is staged empty and which run.sh adds as a search path; the config, saves and
# nblood.pk3 stay next to the binary.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/nblood.sh"

mkdir -p "$BUILD_DIR/blood"
nblood_build blood "$BUILD_DIR/blood/build.log" "$here"/patches/*.patch

stage=$(stage_dir blood)
game=$stage/ports/blood
mkdir -p "$game/data"
cp "$NBLOOD_SRC/nblood" "$NBLOOD_SRC/nblood.pk3" "$game/"
cp "$NBLOOD_SRC/package/common/gpl-2.0.txt" "$game/LICENSE.txt"
cp "$NBLOOD_SRC/package/common/buildlic.txt" "$game/LICENSE-build.txt"
cp "$here/run.sh" "$game/"
cp "$here/blood.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/blood.png"
