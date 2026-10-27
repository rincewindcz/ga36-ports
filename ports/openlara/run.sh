#!/bin/sh
# Starts OpenLara. Tomb Raider data (DATA/, FMV/, audio/) lives next to this
# script; settings and saves go to $HOME/.openlara.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
cd "$here" || exit 1
exec ./OpenLara "$@" > "$here/run.log" 2>&1
