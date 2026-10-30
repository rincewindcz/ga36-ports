#!/bin/sh
# Starts Gravity Defied. Records and settings go to $HOME/.GravityDefied.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
cd "$here" || exit 1
exec ./GravityDefied levels.mrg "$@" > "$here/run.log" 2>&1
