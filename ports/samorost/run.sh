#!/bin/sh
# Starts Samorost 1 from the game files in data/. The first start converts their
# textures into cache/ (about 250 MB); saves go to save/.
here=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export SDL_VIDEODRIVER=kmsdrm
{
    if [ ! -f "$here/cache/complete" ]; then
        "$here/samorost-convert" "$here/data" "$here/cache" || exit 1
        touch "$here/cache/complete"
    fi
    exec "$here/samorost" --data "$here/data" --cache "$here/cache" --save "$here/save" --fullscreen "$@"
} > "$here/run.log" 2>&1
