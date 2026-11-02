#!/bin/sh
# Starts Undertale. data.win, the music and the saves live in data/.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
exec "$here/butterscotch" "$here/data/data.win" --fullscreen "$@" > "$here/run.log" 2>&1
