#!/usr/bin/env bash
# Commando (Fallen Angel Industries, 2004) on the Klik player: a Multimedia
# Fusion 1.5 runtime for LOVE 11.5 that runs the original commando.exe. The
# player is packed into commando.love next to the runtime of
# lib/love-runtime.sh; commando.exe, music/ and readme.txt from the freeware
# zip go into game/.
#
# Usage: COMMANDO_DIR=<player checkout> COMMANDO_ZIP=<game zip> build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/love-runtime.sh"

COMMANDO_DIR=${COMMANDO_DIR:-/mnt/ext/r36s/goodluck/commando}
COMMANDO_ZIP=${COMMANDO_ZIP:-$DL_DIR/commando/Commando - Fallen Angel Industries.zip}
ZIP_SHA256=c6a8af793c7084812d32c85f27ec1691a1328156d097b82b50c0d0a445f6da37
[[ -f $COMMANDO_DIR/player/main.lua ]] || { echo "Klik player not found in $COMMANDO_DIR, set COMMANDO_DIR" >&2; exit 1; }
[[ -f $COMMANDO_ZIP ]] || { echo "game zip not found at $COMMANDO_ZIP, set COMMANDO_ZIP" >&2; exit 1; }
echo "$ZIP_SHA256  $COMMANDO_ZIP" | sha256sum -c --quiet

stage=$(stage_dir commando)
game=$stage/ports/commando
love_runtime "$game"
(cd "$COMMANDO_DIR/player" && zip -qrX "$game/commando.love" main.lua conf.lua commando.lua mmf run ext fonts)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
unzip -q "$COMMANDO_ZIP" -d "$work"
mkdir -p "$game/game"
cp -r "$work/commando.exe" "$work/music" "$work/readme.txt" "$game/game/"
cp "$COMMANDO_DIR/player/fonts/LICENSE-Liberation" "$game/lib/licenses/Liberation.txt"

cp "$here/run.sh" "$game/"
cp "$here/commando.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/commando.png"
