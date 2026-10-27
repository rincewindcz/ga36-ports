#!/bin/sh
# Starts Lugaru. Data/ lives next to this script; lib/ holds gl4es
# (libGL.so.1), which runs the game's OpenGL 1.x calls on Mesa lima GLES 2,
# and the Debian libraries goodluckOS lacks. Settings and saves go to
# $HOME/.config/lugaru and $HOME/.local/share/lugaru.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LIBGL_ES=2
export LIBGL_GLES=/usr/lib/libGLESv2.so.2
export LIBGL_EGL=/usr/lib/libEGL.so.1
cd "$here" || exit 1
exec ./lugaru "$@" > "$here/run.log" 2>&1
