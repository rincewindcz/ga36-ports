#!/bin/sh
# Starts Gates of Skeldal. The game data lives in data/, lang/ and
# skeldal.ini next to this script. The repository's fixed BILA_VEZ.MAP
# replaces the original one. Saves go to $HOME/.local/share/Skeldal.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
cd "$here" || exit 1
[ -d data/MAPS ] && cp -f BILA_VEZ.MAP data/MAPS/
exec ./skeldal -f "$here/skeldal.ini" "$@" > "$here/run.log" 2>&1
