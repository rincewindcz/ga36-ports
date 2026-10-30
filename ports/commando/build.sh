#!/usr/bin/env bash
# Commando (Fallen Angel Industries, 2004) on the Klik player: a Multimedia
# Fusion 1.5 runtime for LOVE 11.5 that runs the original commando.exe. The
# player is packed into commando.love next to the runtime of
# lib/love-runtime.sh; commando.exe, music/ and readme.txt from the freeware
# zip (Commando 1.0, mirrored on ga36.genserek.net) go into game/.
#
# Usage: COMMANDO_DIR=<player checkout> build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/love-runtime.sh"

COMMANDO_DIR=${COMMANDO_DIR:-/mnt/ext/r36s/goodluck/commando}
ZIP_URL=https://ga36.genserek.net/dl/commando/src/commando-1.0-faind.zip
ZIP_SHA256=c6a8af793c7084812d32c85f27ec1691a1328156d097b82b50c0d0a445f6da37
zip=$DL_DIR/commando-1.0-faind.zip
[[ -f $COMMANDO_DIR/player/main.lua ]] || { echo "Klik player not found in $COMMANDO_DIR, set COMMANDO_DIR" >&2; exit 1; }
fetch_file "$ZIP_URL" "$ZIP_SHA256" "$zip"

stage=$(stage_dir commando)
game=$stage/ports/commando
love_runtime "$game"
(cd "$COMMANDO_DIR/player" && zip -qrX "$game/commando.love" *.lua mmf run ext fonts)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
unzip -q "$zip" -d "$work"
mkdir -p "$game/game"
cp -r "$work/commando.exe" "$work/music" "$work/readme.txt" "$game/game/"
cp "$COMMANDO_DIR/player/fonts/LICENSE-Liberation" "$game/lib/licenses/Liberation.txt"

cp "$here/run.sh" "$game/"
cp "$here/commando.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/commando.png"
