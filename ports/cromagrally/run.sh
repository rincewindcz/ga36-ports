#!/bin/sh
# Starts Cro-Mag Rally. Data/ lives next to this script; lib/ holds gl4es
# (libGL.so.1), which runs the game's OpenGL 1.x calls on Mesa lima GLES 2.
# Settings and saves go to $HOME/.config.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export LD_LIBRARY_PATH="$here/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LIBGL_ES=2
export LIBGL_GLES=/usr/lib/libGLESv2.so.2
export LIBGL_EGL=/usr/lib/libEGL.so.1
cd "$here" || exit 1
exec ./CroMagRally "$@" > "$here/run.log" 2>&1
