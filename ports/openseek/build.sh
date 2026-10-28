#!/usr/bin/env bash
# openSEEK (Seek and Destroy remake) with the LOVE runtime of
# lib/love-runtime.sh. The shareware release (seeksw1.zip, mirrored on
# genserek.net) is converted by the game's tools/build_pack.py into a data
# pack that goes into openseek.love as assets/; LOVE reads the save directory
# first, so a pack converted from the full game there takes over.
#
# Usage: build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/love-runtime.sh"

GAME_REPO=https://github.com/rincewindcz/openseek.git
GAME_COMMIT=45c6460e401cca2491a80b6a588870e5de1c0622
ZIP_URL=https://genserek.net/seek/seeksw1.zip
ZIP_SHA256=5eddf43ef09bc03fd7496ad2749d1081cc23483fa749b4f90cefddfef6874ec3
src=$SRC_DIR/openseek
zip=$DL_DIR/seeksw1.zip
log=$BUILD_DIR/openseek/build.log

fetch_commit "$src" "$GAME_REPO" "$GAME_COMMIT"
fetch_file "$ZIP_URL" "$ZIP_SHA256" "$zip"

stage=$(stage_dir openseek)
game=$stage/ports/openseek
love_runtime "$game"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
python3 "$src/tools/build_pack.py" --download --cache "$DL_DIR" --out "$work/pack/assets" > "$log" 2>&1 || { tail -30 "$log" >&2; exit 1; }
cat "$work/pack/assets.log" >> "$log"
grep -q '"failed": \[\]' "$work/pack/assets/manifest.json" || { echo "pack conversion failed, see $log" >&2; exit 1; }
python3 "$src/tools/build_release.py" --love "$game/openseek.love" >> "$log"
(cd "$work/pack" && zip -qrX "$game/openseek.love" assets)
unzip -p "$zip" LICENSE.DOC > "$game/SHAREWARE-LICENSE.txt"

cp "$src/LICENSE" "$game/LICENSE.txt"
cp "$here/run.sh" "$game/"
cp "$here/openseek.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/openseek.png"
