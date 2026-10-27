#!/bin/sh
# Starts Commando (Klik player) with the LOVE runtime bundled next to this script.
here=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export SDL_VIDEODRIVER=kmsdrm
export LOVE_GRAPHICS_USE_OPENGLES=1
exec "$here/love" "$here/commando.love" --exe "$here/game/commando.exe" "$@" > "$here/run.log" 2>&1
