#!/bin/sh
# Starts xrick. Arguments pass through: -game 2 selects Rick Dangerous II.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
exec "$here/xrick" -fullscreen "$@" > "$here/run.log" 2>&1
