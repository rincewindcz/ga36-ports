#!/bin/sh
# Starts Half-Life: run.sh [gles1|gles2|soft] (renderer, default gles1).
# The Half-Life valve/ directory lives in data/, searched as a read-only base
# directory; valve/ next to this script holds the game libraries, the engine
# resources, goodluck.cfg, the config and the saves.
here=$(dirname "$(readlink -f "$0")")
ref=${1:-gles1}
case $ref in
    gles1|gles2|soft) ;;
    *) echo "usage: $0 [gles1|gles2|soft]" >&2; exit 1 ;;
esac
export SDL_VIDEODRIVER=kmsdrm
cd "$here" || exit 1
exec ./xash3d -rodir "$here/data" -ref "$ref" -fullscreen -width 640 -height 480 > "$here/xash3d.log" 2>&1
