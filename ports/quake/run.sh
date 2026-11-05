#!/bin/sh
# Starts Quake on QuakeSpasm. data/ is the Quake base directory; data/id1
# holds the game data, the config and the saves. The first start extracts the
# shareware id1/pak0.pak from the bundled quake106.zip unless a pak0.pak of
# the full version is already there. lib/ holds gl4es (libGL.so.1), which runs
# the engine's OpenGL 1.x calls on Mesa lima GLES 2, Tremor and Ogg.
here=$(dirname "$(readlink -f "$0")")
data=$here/data
log=$here/run.log
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LIBGL_ES=2
export LIBGL_GLES=/usr/lib/libGLESv2.so.2
export LIBGL_EGL=/usr/lib/libEGL.so.1
cd "$here" || exit 1

if [ ! -f "$data/id1/pak0.pak" ]; then
    tmp=$data/.shareware
    rm -rf "$tmp"
    mkdir -p "$tmp"
    if unzip -p shareware/quake106.zip resource.1 > "$tmp/resource.1" &&
        bin/lha -xqw="$tmp" "$tmp/resource.1" id1/pak0.pak; then
        mv "$tmp/id1/pak0.pak" "$data/id1/pak0.pak"
    fi
    rm -rf "$tmp"
fi

# goodluck.cfg seeds the pad layout; the engine rewrites config.cfg on quit.
[ -f "$data/id1/config.cfg" ] || cp "$data/id1/goodluck.cfg" "$data/id1/config.cfg"
# gl4es cannot convert the GL_UNSIGNED_INT_8_8_8_8_REV lightmap uploads; the
# GLSL alias model path costs a fifth of the frame rate under gl4es.
exec ./quakespasm -basedir "$data" -heapsize 131072 -fullscreen -width 640 -height 480 -nopackedpixels \
    -noglslalias "$@" > "$log" 2>&1
