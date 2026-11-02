#!/usr/bin/env bash
# Balatro on LOVE 11.5: the runtime of lib/love-runtime.sh and a patch layer that
# runs the user's own game file. layer/portmaster/ holds the Lua modules of
# PortMaster's Balatro port (release 2026-08-19_1404), unchanged except for ASCII
# dashes. The game is not included, and nothing of it is written to the console's
# storage.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/love-runtime.sh"

stage=$(stage_dir balatro)
game=$stage/ports/balatro
love_runtime "$game"
# The game file and the saves live in love/game, the save directory of LOVE.
mv "$game/love" "$game/love-11.5"
(cd "$here/layer" && zip -qrX "$game/balatro.love" conf.lua main.lua ga36 portmaster)

cp "$here/run.sh" "$game/"
cp "$here/LICENSE-PortMaster.txt" "$here/LICENSE-Nunito.txt" "$game/"
cp "$here/balatro.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/balatro.png"
