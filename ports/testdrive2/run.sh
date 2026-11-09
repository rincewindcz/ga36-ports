#!/bin/sh
# Starts Test Drive II. The game files and the high scores live in data/, the settings in testdrive2.conf.
here=$(dirname "$(readlink -f "$0")")
. "$here/testdrive2.conf"
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
exec "$here/testdrive2-enhanced" --game-dir "$here/data" --scale 2 --res-scale 2 --supersample 1 \
    --frame-rate "$frame_rate" "$@" > "$here/run.log" 2>&1
