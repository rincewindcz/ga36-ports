#!/bin/sh
# Starts openSEEK with the LOVE runtime bundled next to this script. Settings,
# saves and a data pack converted from the full game go to
# $HOME/.local/share/love/openseek.
here=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export SDL_VIDEODRIVER=kmsdrm
export LOVE_GRAPHICS_USE_OPENGLES=1
exec "$here/love" "$here/openseek.love" "$@" > "$here/run.log" 2>&1
