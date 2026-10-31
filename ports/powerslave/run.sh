#!/bin/sh
# Starts Powerslave. The game data lives in data/; config, saves and
# pcexhumed.pk3 are in the working directory.
here=$(dirname "$(readlink -f "$0")")
export SDL_VIDEODRIVER=kmsdrm
# The kmsdrm window never gets keyboard focus here, and SDL drops pad events without it.
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
cd "$here" || exit 1
exec ./pcexhumed -usecwd -nosetup -j data > "$here/run.log" 2>&1
