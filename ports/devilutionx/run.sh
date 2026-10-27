#!/bin/sh
# Starts DevilutionX. assets/ lives next to this script, the game data
# (spawn.mpq or diabdat.mpq, hellfire.mpq) in data/. Settings and saves go to
# $HOME/.local/share/diasurgical/devilution.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
cd "$here" || exit 1
exec ./devilutionx --data-dir "$here/data" "$@" > "$here/run.log" 2>&1
