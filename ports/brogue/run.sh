#!/bin/sh
# Starts Brogue CE in the compact view with graphical tiles. Saves, recordings
# and high scores are written next to this script.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
cd "$here" || exit 1
exec ./brogue --compact --full-screen --graphics "$@" > "$here/run.log" 2>&1
