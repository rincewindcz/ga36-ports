#!/usr/bin/env bash
# R U NUTS ??? with the LOVE runtime of lib/love-runtime.sh. The game's
# main.lua is packed as runuts_main.lua under the port layer (main.lua,
# conf.lua); the game sources are not modified.
#
# Usage: RUNUTS_DIR=<game checkout> build.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../lib/cross.sh"
. "$GA36_ROOT/lib/love-runtime.sh"

RUNUTS_DIR=${RUNUTS_DIR:-$HOME/Programming/runuts}
[[ -f $RUNUTS_DIR/main.lua ]] || { echo "R U NUTS checkout not found in $RUNUTS_DIR, set RUNUTS_DIR" >&2; exit 1; }

stage=$(stage_dir runuts)
game=$stage/ports/runuts
love_runtime "$game"

pack=$(mktemp -d)
trap 'rm -rf "$pack"' EXIT
git -C "$RUNUTS_DIR" ls-files -z -- '*.lua' '*.json' 'assets' 'themes' |
    (cd "$RUNUTS_DIR" && xargs -0 cp --parents -t "$pack")
cp -rL "$RUNUTS_DIR/krabice" "$pack/krabice"
mv "$pack/main.lua" "$pack/runuts_main.lua"
cp "$here/main.lua" "$here/conf.lua" "$pack/"
(cd "$pack" && zip -qrX "$game/runuts.love" .)

cp "$here/run.sh" "$game/"
cp "$here/runuts.puppy" "$stage/.local/share/applications/"
cp "$here/icon.png" "$stage/.local/share/icons/runuts.png"
