#!/bin/sh
# Starts Balatro from the user's game file in love/game, which is also where the
# saves go: LOVE only mounts archives from its save directory.
here=$(dirname "$(readlink -f "$0")")
mkdir -p "$here/love/game"
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_DATA_HOME=$here
export SDL_VIDEODRIVER=kmsdrm
export LOVE_GRAPHICS_USE_OPENGLES=1
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
exec "$here/love-11.5" "$here/balatro.love" "$@" > "$here/run.log" 2>&1
